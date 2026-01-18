# Load the package without installing (uses Nix-provided dependencies)
# devtools::load_all() loads the package for development without CRAN fetch
devtools::load_all(".")

# Pass the current project path to the vignette
Sys.setenv(TAR_PROJECT = getwd())
Sys.setenv(HOME = Sys.getenv("HOME", "/tmp"))  # Fix /homeless-shelter warning

# Build the site
pkgdown::build_site()