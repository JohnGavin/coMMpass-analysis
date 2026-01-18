library(gert)
library(usethis)
library(logger)

log_info("Starting Git operations via gert...")

# Files to manage
old_workflows <- c(
  ".github/workflows/ci-env.yaml",
  ".github/workflows/analysis.yaml",
  ".github/workflows/website.yaml",
  ".github/workflows/reproduce.yaml"
)

new_workflows <- c(
  ".github/workflows/01-env.yaml",
  ".github/workflows/02-data.yaml",
  ".github/workflows/03-analysis.yaml",
  ".github/workflows/04-website.yaml"
)

# 1. Remove old workflows
existing_old <- old_workflows[file.exists(old_workflows)]
if (length(existing_old) > 0) {
  log_info("Removing old workflows: {paste(existing_old, collapse=', ')}")
  # git_rm removes from disk and index
  git_rm(existing_old)
} else {
  log_info("No old workflow files found to remove.")
}

# 2. Add new workflows
# Check if files exist first
missing_new <- new_workflows[!file.exists(new_workflows)]
if (length(missing_new) > 0) {
  stop(paste("Missing new workflow files:", paste(missing_new, collapse=", ")))
}

log_info("Adding new workflows...")
git_add(new_workflows)

# 3. Commit
if (nrow(git_status()) > 0) {
  log_info("Committing changes...")
  git_commit("Refactor: Split pipeline into 4 sequential workflows")
} else {
  log_info("Nothing to commit.")
}

# 4. Push
log_info("Pushing to remote...")
# gert uses libgit2 and should pick up credentials (e.g. GITHUB_PAT or ssh agent)
git_push()

log_success("Git operations completed successfully.")
