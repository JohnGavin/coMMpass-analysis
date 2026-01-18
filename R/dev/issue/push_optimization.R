library(gert)
library(logger)

log_info("Pushing environment optimizations...")
git_add("default.R")
git_add("default_dev.nix")
git_add("R/functions/data_access.R")

if (nrow(git_status()) > 0) {
  git_commit("Optimize environment: Remove texlive/awscli, simplify dependencies")
  git_push()
  log_success("Pushed optimizations.")
} else {
  log_info("No changes to push.")
}
