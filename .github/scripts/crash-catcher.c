/* R-CMD-check.yaml builds this file on Windows, and
   tests/testthat/helper-test-log.R loads it in each test process. When an
   access violation or another fatal exception reaches the process, the
   handler writes a minidump of the process to the folder that
   catcher_start() names, before any other handler runs, and then lets the
   exception go on. Windows Error Reporting wrote no dump for a planted
   crash of a test process (M080), so the process writes its own.
   Microsoft advises writing a dump from another process, since
   MiniDumpWriteDump can deadlock in the crashing one, so the workflow sets
   a job timeout. A stack overflow is not caught, since the handler would
   run on the exhausted stack, and heap corruption is left out, since
   writing a dump then is the likeliest deadlock. */
#include <windows.h>
#include <dbghelp.h>
#include <stdio.h>
#include <string.h>

#define MAX_DUMPS 3

static char folder[MAX_PATH];
static volatile LONG written = 0;

static int is_fatal(DWORD code)
{
    return code == EXCEPTION_ACCESS_VIOLATION ||
        code == EXCEPTION_ILLEGAL_INSTRUCTION ||
        code == EXCEPTION_INT_DIVIDE_BY_ZERO ||
        code == EXCEPTION_PRIV_INSTRUCTION ||
        code == EXCEPTION_IN_PAGE_ERROR;
}

static LONG CALLBACK on_exception(PEXCEPTION_POINTERS info)
{
    char program[MAX_PATH], path[MAX_PATH], *base;
    LONG n;
    HANDLE file;
    MINIDUMP_EXCEPTION_INFORMATION exception;

    if (!is_fatal(info->ExceptionRecord->ExceptionCode)) return EXCEPTION_CONTINUE_SEARCH;
    n = InterlockedIncrement(&written);
    if (n > MAX_DUMPS) return EXCEPTION_CONTINUE_SEARCH;
    if (GetModuleFileNameA(NULL, program, MAX_PATH) == 0) strcpy(program, "unknown");
    base = strrchr(program, '\\');
    base = base ? base + 1 : program;
    /* read-dumps.py reads the program and process id from this name. */
    snprintf(path, MAX_PATH, "%s\\%s.%lu.%ld.dmp", folder, base, GetCurrentProcessId(), n);
    file = CreateFileA(path, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
    if (file == INVALID_HANDLE_VALUE) return EXCEPTION_CONTINUE_SEARCH;
    exception.ThreadId = GetCurrentThreadId();
    exception.ExceptionPointers = info;
    exception.ClientPointers = FALSE;
    MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), file, MiniDumpNormal, &exception, NULL, NULL);
    CloseHandle(file);
    return EXCEPTION_CONTINUE_SEARCH;
}

/* Called through .C() with the dump folder. */
void catcher_start(char **dir)
{
    strncpy(folder, dir[0], MAX_PATH - 1);
    folder[MAX_PATH - 1] = '\0';
    AddVectoredExceptionHandler(1, on_exception);
}
