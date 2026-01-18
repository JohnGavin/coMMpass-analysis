library(gert)
library(logger)

log_info("Pushing final fixes...")
git_add("vignettes/01_data_acquisition.Rmd")
git_add("_pkgdown.yml")

if (nrow(git_status()) > 0) {
  git_commit("Fix vignette syntax and pkgdown config")
  git_push()
  log_success("Pushed.")
} else {
  log_info("No changes to push.")
}
