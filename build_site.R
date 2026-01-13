# Set up a local library for the package itself
dir.create("R-lib", showWarnings = FALSE)
.libPaths(c("R-lib", .libPaths()))

# Install the package *without* upgrading dependencies
remotes::install_local(".", dependencies = FALSE, force = TRUE, lib = "R-lib")

# Pass the current project path to the vignette
Sys.setenv(TAR_PROJECT = getwd())

# Build the site
pkgdown::build_site()