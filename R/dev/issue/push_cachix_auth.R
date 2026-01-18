library(gert)
library(logger)

log_info("Pushing Cachix auth and multi-cache configuration...")
git_add(".github/workflows/01-env.yaml")
git_add(".github/workflows/02-data.yaml")
git_add(".github/workflows/03-analysis.yaml")
git_add(".github/workflows/04-website.yaml")

if (nrow(git_status()) > 0) {
  git_commit("Enable johngavin Cachix push/pull and rstats-on-nix pull")
  git_push()
  log_success("Pushed.")
} else {
  log_info("No changes to push.")
}
