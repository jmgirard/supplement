# crash-catcher.c writes a minidump of each test process that crashes into
# the folder that R-CMD-check.yaml names. This script prints, for each
# dump, the program, its process id, the exception code, and the module
# that holds the fault address, with the nearest exported function when the
# module file is still on disk. With a log folder, it also prints the last
# test that the crashed process started, from <pid>.log there.
#
# Usage: python read-dumps.py <dump folder> [<log folder>]
#
# The minidump and PE layouts are from Microsoft's documentation of
# minidumpapiset.h and of the PE format. Only the standard library is used.

import os
import re
import struct
import sys

MODULE_LIST_STREAM = 4
EXCEPTION_STREAM = 6
THREAD_LIST_STREAM = 3

EXCEPTION_NAMES = {
    0xC0000005: "access violation",
    0xC00000FD: "stack overflow",
    0xC0000409: "stack buffer overrun",
    0xC000001D: "illegal instruction",
    0xC0000094: "integer division by zero",
    0x80000003: "breakpoint",
    0xC0000374: "heap corruption",
}


def u32(data, at):
    return struct.unpack_from("<I", data, at)[0]


def u64(data, at):
    return struct.unpack_from("<Q", data, at)[0]


def streams(data):
    if data[:4] != b"MDMP":
        raise ValueError("not a minidump")
    count, rva = u32(data, 8), u32(data, 12)
    found = {}
    for i in range(count):
        kind, size, at = struct.unpack_from("<III", data, rva + 12 * i)
        found.setdefault(kind, (at, size))
    return found


def module_list(data, at):
    modules = []
    for i in range(u32(data, at)):
        base = at + 4 + 108 * i
        start, size = u64(data, base), u32(data, base + 8)
        name_at = u32(data, base + 20)
        length = u32(data, name_at)
        name = data[name_at + 4:name_at + 4 + length].decode("utf-16-le", "replace")
        modules.append((start, size, name))
    return modules


def module_of(modules, address):
    for start, size, name in modules:
        if start <= address < start + size:
            return start, name
    return None


def exports(path):
    """Map each exported function's offset in the image to its name."""
    with open(path, "rb") as f:
        pe = f.read()
    head = u32(pe, 0x3C)
    if pe[head:head + 4] != b"PE\0\0":
        return {}
    n_sections = struct.unpack_from("<H", pe, head + 6)[0]
    optional = head + 24
    optional_size = struct.unpack_from("<H", pe, head + 20)[0]
    magic = struct.unpack_from("<H", pe, optional)[0]
    directories = optional + (112 if magic == 0x20B else 96)
    export_rva, export_size = struct.unpack_from("<II", pe, directories)
    if export_rva == 0:
        return {}
    sections = []
    for i in range(n_sections):
        at = optional + optional_size + 40 * i
        vsize, va, raw_size, raw_at = struct.unpack_from("<IIII", pe, at + 8)
        sections.append((va, max(vsize, raw_size), raw_at))

    def offset(rva):
        for va, size, raw_at in sections:
            if va <= rva < va + size:
                return rva - va + raw_at
        raise ValueError("address outside every section")

    d = offset(export_rva)
    n_names = u32(pe, d + 24)
    functions, names, ordinals = (offset(u32(pe, d + k)) for k in (28, 32, 36))
    found = {}
    for i in range(n_names):
        name_at = offset(u32(pe, names + 4 * i))
        name = pe[name_at:pe.index(b"\0", name_at)].decode("ascii", "replace")
        ordinal = struct.unpack_from("<H", pe, ordinals + 2 * i)[0]
        rva = u32(pe, functions + 4 * ordinal)
        # An address inside the export table is a forward to another DLL.
        if not export_rva <= rva < export_rva + export_size:
            found[rva] = name
    return found


def describe(modules, address, cache):
    hit = module_of(modules, address)
    if hit is None:
        return "0x%x, which no loaded module holds" % address
    start, name = hit
    rel = address - start
    text = "%s+0x%x" % (os.path.basename(name), rel)
    if name not in cache:
        try:
            cache[name] = exports(name) if os.path.isfile(name) else {}
        except (OSError, ValueError, struct.error):
            cache[name] = {}
    below = [rva for rva in cache[name] if rva <= rel]
    if below:
        rva = max(below)
        text += " (nearest export %s+0x%x)" % (cache[name][rva], rel - rva)
    return text


def stack_scan(data, found, thread_id, context_at, modules, cache, limit=12):
    """Values on the crashed thread's stack that point into a module.

    This is a scan, not a stack walk, so some lines can be stale values."""
    if THREAD_LIST_STREAM not in found or context_at == 0:
        return []
    at = found[THREAD_LIST_STREAM][0]
    for i in range(u32(data, at)):
        base = at + 4 + 48 * i
        if u32(data, base) != thread_id:
            continue
        stack_start = u64(data, base + 24)
        stack_size, stack_at = u32(data, base + 32), u32(data, base + 36)
        rsp = u64(data, context_at + 0x98)
        lines = []
        first = max(0, rsp - stack_start)
        for off in range(first - first % 8, stack_size - 7, 8):
            value = u64(data, stack_at + off)
            if module_of(modules, value) is not None:
                lines.append(describe(modules, value, cache))
                if len(lines) == limit:
                    break
        return lines
    return []


def last_log_line(log_dir, pid):
    if not log_dir:
        return None
    path = os.path.join(log_dir, "%s.log" % pid)
    if not os.path.isfile(path):
        return None
    with open(path, encoding="utf-8", errors="replace") as f:
        lines = [line.rstrip("\n") for line in f if line.strip()]
    return lines[-1] if lines else None


def report(path, log_dir):
    # crash-catcher.c names a dump <program>.<pid>.<n>.dmp.
    match = re.match(r"^(.*?)\.(\d+)(?:\.\d+)?\.dmp$", os.path.basename(path))
    program, pid = (match.group(1), match.group(2)) if match else (os.path.basename(path), "unknown")
    print("Crash dump %s: program %s, process id %s" % (os.path.basename(path), program, pid))
    with open(path, "rb") as f:
        data = f.read()
    found = streams(data)
    if EXCEPTION_STREAM not in found:
        print("  The dump holds no exception record.")
        return
    at = found[EXCEPTION_STREAM][0]
    thread_id = u32(data, at)
    code = u32(data, at + 8)
    address = u64(data, at + 24)
    n_params = u32(data, at + 32)
    params = [u64(data, at + 40 + 8 * i) for i in range(min(n_params, 15))]
    context_at = u32(data, at + 164)
    modules = module_list(data, found[MODULE_LIST_STREAM][0]) if MODULE_LIST_STREAM in found else []
    cache = {}
    name = EXCEPTION_NAMES.get(code, "see ntstatus.h")
    print("  Exception code: 0x%08X (%s)" % (code, name))
    print("  Fault address: %s" % describe(modules, address, cache))
    if code == 0xC0000005 and len(params) >= 2:
        verb = {0: "read", 1: "write", 8: "execute"}.get(params[0], "access")
        print("  The fault was a %s at 0x%x." % (verb, params[1]))
    scan = stack_scan(data, found, thread_id, context_at, modules, cache)
    if scan:
        print("  Stack values that point into a module (a scan, not a stack walk):")
        for line in scan:
            print("    " + line)
    line = last_log_line(log_dir, pid)
    if line is None:
        print("  No test log matches process id %s." % pid)
    else:
        print("  Last test that this process started: %s" % line)


def main():
    if len(sys.argv) < 2:
        sys.exit("Usage: python read-dumps.py <dump folder> [<log folder>]")
    dump_dir = sys.argv[1]
    log_dir = sys.argv[2] if len(sys.argv) > 2 else None
    names = sorted(n for n in os.listdir(dump_dir) if n.lower().endswith(".dmp")) if os.path.isdir(dump_dir) else []
    if not names:
        print("No crash dump in %s." % dump_dir)
        return
    for name in names:
        try:
            report(os.path.join(dump_dir, name), log_dir)
        except (OSError, ValueError, struct.error, IndexError) as e:
            print("Crash dump %s could not be read: %s" % (name, e))


if __name__ == "__main__":
    main()
