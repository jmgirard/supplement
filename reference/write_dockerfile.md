# Write a Dockerfile from renv.lock

`write_dockerfile()` reads `renv.lock` in a site set up with renv and
writes a `Dockerfile` and a `.dockerignore` into the same folder. The
image that Docker builds from them holds the R version and the R
packages that `renv.lock` records, and the Quarto version that you give.
You can then render a report in the image with the site folder mounted,
so that its code runs with those versions on another machine that runs
Docker with Linux containers on an amd64 processor, or on arm64 for R
4.1.0 or later, the platforms of the Rocker images. `renv.lock` must
record R 4.0.0 or later, because older `rocker/r-ver` images lack the
Rocker scripts that the build runs. The Dockerfile was built and run
with `rocker/r-ver:4.6.1` on arm64 (Docker 29.9.1, 2026-10-22); older
images and amd64 were not built. supplement never runs Docker itself.

## Usage

``` r
write_dockerfile(path = ".", quarto, digest = NULL, overwrite = FALSE)
```

## Arguments

- path:

  The site folder that holds `renv.lock`.

- quarto:

  The Quarto version to install, as three whole numbers joined by `.`,
  such as `"1.10.19"`. `quarto --version` in a terminal prints the
  version that you render with.

- digest:

  `NULL`, or the digest of the base image, `"sha256:"` and 64 lowercase
  hex digits. With a digest, the `FROM` line names the image by its tag
  and the digest, so the build uses that image even after the tag moves.

- overwrite:

  If `TRUE`, replace an existing `Dockerfile` and `.dockerignore`.

## Value

The paths of the written `Dockerfile` and `.dockerignore`, invisibly.

## Details

The `Dockerfile` starts from the Rocker image `rocker/r-ver` with the R
version in `renv.lock`, and installs Quarto with Rocker's
`install_quarto.sh`. It copies `renv.lock` into the image. It downloads
the renv version that `renv.lock` records from the CRAN archive of Posit
Package Manager (`p3m.dev`), installs it into a temporary library, uses
it to install the Ubuntu packages that
[`renv::sysreqs()`](https://rstudio.github.io/renv/reference/sysreqs.html)
lists for the packages in `renv.lock`, and runs
[`renv::restore()`](https://rstudio.github.io/renv/reference/restore.html).
renv reads those packages from `renv.lock` from version 1.3.1 on, so
`renv.lock` must record renv 1.3.1 or later. The packages, renv
included, go into a library in the image under `/opt/renv/library`,
which `RENV_PATHS_LIBRARY` names. renv's package cache is off, so the
library holds the packages and not links into a cache. When the site
folder is mounted at `/site`, the site's `renv/activate.R` loads renv
from that library, with no download.

The `.dockerignore` holds the two lines `*` and `!renv.lock`, so of the
site's files only `renv.lock` can be copied into the image. The image
holds no other site file and no data. Both files are written with LF
line endings on every system.

## Build and render

In a terminal, in the site folder, build the image and give it a name:

    docker build -t my-supplement .

Then render one report in it with the site folder mounted at `/site`. On
macOS and Linux:

    docker run --rm --network none --user "$(id -u):$(id -g)" -e HOME=/tmp \
      -v "$PWD":/site my-supplement quarto render analyses/example.qmd

`--network none` shows that the render needs nothing from the network.
`--user` runs the render as you. On Linux it makes you the owner of the
files that the render writes into the site folder; Docker Desktop on
macOS does that without it. `HOME=/tmp` gives that user a home folder in
the container.

## Versions that can change

An image tag such as `rocker/r-ver:4.6.1` can be moved to a newer image,
so without `digest`, a later build can get newer system libraries. To
pin the base image, read the digest of its multi-platform index:

    docker buildx imagetools inspect rocker/r-ver:4.6.1

and pass the `Digest:` value, such as `"sha256:bafb..."`, as `digest`.
The build also installs Ubuntu packages for the R packages. These come
from Ubuntu's package archive at build time, so they can be newer in a
later build even with `digest`.

To keep the built image itself, write it to a file that you can archive:

    docker save -o my-supplement.tar my-supplement

`docker load -i my-supplement.tar` reads it back. Commit the
`Dockerfile` and the `.dockerignore`: the Zenodo archive of a GitHub
release then holds them, but not the image.

## Errors

The function checks the arguments, `renv.lock`, and both target paths
before it writes a file, so after any error but a failed write the site
folder is as it was. It writes `.dockerignore` first, then the
`Dockerfile`. A failed write, an open that fails included, can leave
`.dockerignore` written, and either file empty or cut short. A file that
cannot be opened for writing gives R's own error. The other errors have
the class `supplement_error` and one of these classes:

- `supplement_error_argument`: `path` is not a single non-missing,
  non-empty string, or it is not a folder. `quarto` is missing or is not
  one string of three whole numbers joined by `.`, each `0` or without a
  leading zero. `digest` is not `NULL` or one string of `sha256:` and 64
  lowercase hex digits. `overwrite` is not `TRUE` or `FALSE`.

- `supplement_error_no_file`: the folder has no `renv.lock`, or
  `renv.lock` is a folder.

- `supplement_error_lockfile`: `renv.lock` is not a JSON object, has no
  `R` object with a `Version`, or has no `renv` entry with a `Version`
  under `Packages`, or one of the two versions is not one string of
  three whole numbers joined by `.`. A development version such as
  `1.1.5.9000` is such an error, because the build installs released
  versions. An R version older than 4.0.0 or a renv version older than
  1.3.1 is also this error. So is a key that the function reads, given
  twice in the same object: `R` or `Packages` at the top level,
  `Version` in `R`, `renv` in `Packages`, or `Version` in that `renv`
  entry. This check comes before the version checks.

- `supplement_error_file_exists`: `Dockerfile` or `.dockerignore` exists
  and `overwrite` is `FALSE`. A folder at either path is this error even
  when `overwrite` is `TRUE`. So is a link, also a link to a missing
  file, because a write would follow it.

- `supplement_error_write`: a file was opened, but writing it gave an
  error or a warning, or the file then has another size than the text.

## See also

The parts "Recording R packages with renv" and "Running reports in a
container" of the template guide, `GUIDE.md`.

## Examples

``` r
site <- file.path(tempdir(), "my-supplement")
dir.create(site)
writeLines(
  '{"R": {"Version": "4.6.1"}, "Packages": {"renv": {"Version": "1.3.1"}}}',
  file.path(site, "renv.lock")
)
write_dockerfile(site, quarto = "1.10.19")
readLines(file.path(site, "Dockerfile"))
#>  [1] "# Written by supplement::write_dockerfile() from renv.lock. See"                                                                                                     
#>  [2] "# ?supplement::write_dockerfile for how to build the image and render in it."                                                                                        
#>  [3] "FROM rocker/r-ver:4.6.1"                                                                                                                                             
#>  [4] ""                                                                                                                                                                    
#>  [5] "# renv installs the packages into a library under /opt/renv/library, with"                                                                                           
#>  [6] "# its package cache off, and the site's renv/activate.R finds them there."                                                                                           
#>  [7] "ENV RENV_PATHS_LIBRARY=/opt/renv/library \\"                                                                                                                         
#>  [8] "    RENV_CONFIG_CACHE_ENABLED=FALSE"                                                                                                                                 
#>  [9] ""                                                                                                                                                                    
#> [10] "RUN /rocker_scripts/install_quarto.sh 1.10.19"                                                                                                                       
#> [11] ""                                                                                                                                                                    
#> [12] "# A temporary copy of renv 1.3.1 installs the system packages that the R"                                                                                            
#> [13] "# packages need, then restores renv.lock, renv itself included."                                                                                                     
#> [14] "WORKDIR /opt/renv"                                                                                                                                                   
#> [15] "COPY renv.lock renv.lock"                                                                                                                                            
#> [16] "RUN apt-get update \\"                                                                                                                                               
#> [17] "    && export DEBIAN_FRONTEND=noninteractive R_LIBS=/tmp/renv/library RENV_PATHS_ROOT=/tmp/renv/root \\"                                                             
#> [18] "    && mkdir -p \"$R_LIBS\" \\"                                                                                                                                      
#> [19] "    && Rscript -e 'install.packages(\"https://p3m.dev/cran/latest/src/contrib/Archive/renv/renv_1.3.1.tar.gz\", repos = NULL, type = \"source\"); library(renv)' \\" 
#> [20] "    && Rscript -e 'writeLines(as.character(unique(unlist(lapply(renv::sysreqs(report = FALSE, check = FALSE), `[[`, \"packages\")))), \"/tmp/renv/sysreqs.txt\")' \\"
#> [21] "    && xargs -r apt-get install -y --no-install-recommends < /tmp/renv/sysreqs.txt \\"                                                                               
#> [22] "    && Rscript -e 'renv::restore(library = renv::paths$library(), prompt = FALSE)' \\"                                                                               
#> [23] "    && rm -rf /tmp/renv /var/lib/apt/lists/*"                                                                                                                        
#> [24] ""                                                                                                                                                                    
#> [25] "WORKDIR /site"                                                                                                                                                       
unlink(site, recursive = TRUE)
```
