# Install the package locally using Nix-provided dependencies
# R CMD INSTALL uses existing libs - no CRAN fetch
lib_dir <- file.path(tempdir(), "R-lib")
dir.create(lib_dir, showWarnings = FALSE, recursive = TRUE)
.libPaths(c(lib_dir, .libPaths()))

install_cmd <- sprintf(
  "R CMD INSTALL --no-multiarch --with-keep.source --library=%s .",
  shQuote(lib_dir)
)
result <- system(install_cmd)
if (result != 0) stop("Package installation failed")

# Pass the current project path to the vignette
Sys.setenv(TAR_PROJECT = getwd())
Sys.setenv(HOME = Sys.getenv("HOME", "/tmp"))  # Fix /homeless-shelter warning

# Clean docs/ directory to avoid read-only file permission errors
# (Nix store copies are read-only and pkgdown can't overwrite them)
if (dir.exists("docs")) {
  system("chmod -R u+w docs/")
  unlink("docs", recursive = TRUE)
}

# Build the site
pkgdown::build_site()