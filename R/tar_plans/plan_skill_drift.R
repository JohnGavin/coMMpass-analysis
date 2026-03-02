# plan_skill_drift.R
# Detect drift between R source files and the gdc-genomics Claude skill
#
# When R source files change but the skill reference docs haven't been
# updated, this target warns that the skill may be stale.
#
# Targets:
#   skill_source_files   - tracks R files that feed the gdc-genomics skill
#   skill_drift_check    - compares source hashes to detect drift

plan_skill_drift <- list(
  # Track the R source files that feed the gdc-genomics skill
  targets::tar_target(
    skill_source_files,
    c(
      "R/data_dictionary.R",
      "R/01_data_acquisition.R",
      "R/data_access.R",
      "R/03_differential_expression.R",
      "R/05_pathway_analysis.R",
      "R/01b_cytogenetic_data.R",
      "R/04_survival_analysis.R"
    ),
    format = "file"
  ),

  # Hash source + skill files; warn when source changed but skill hasn't

  targets::tar_target(
    skill_drift_check,
    {
      # Hash R source files
      source_hash <- digest::digest(
        lapply(skill_source_files, readLines, warn = FALSE),
        algo = "xxhash64"
      )

      # Hash skill reference files
      skill_dir <- path.expand("~/.claude/skills/gdc-genomics/references")
      skill_files <- list.files(skill_dir, full.names = TRUE, pattern = "\\.md$")

      if (length(skill_files) == 0) {
        cli::cli_warn(c(
          "!" = "gdc-genomics skill not found at {skill_dir}",
          "i" = "Skill drift detection requires the skill to be installed."
        ))
        return(list(drifted = NA, source_hash = source_hash))
      }

      skill_hash <- digest::digest(
        lapply(sort(skill_files), readLines, warn = FALSE),
        algo = "xxhash64"
      )

      # Compare to stored baseline
      baseline_file <- "_targets/user/skill_drift_baseline.rds"
      if (file.exists(baseline_file)) {
        baseline <- readRDS(baseline_file)
        # Drift = source changed but skill files are the same
        drifted <- (baseline$source_hash != source_hash) &&
          (baseline$skill_hash == skill_hash)
        if (drifted) {
          cli::cli_warn(c(
            "!" = "gdc-genomics skill may be stale!",
            "i" = "R source files changed since skill was last synced.",
            "i" = "Review ~/.claude/skills/gdc-genomics/references/ and update."
          ))
        }
        # If skill hash changed, this is a "re-sync" — reset baseline
        if (baseline$skill_hash != skill_hash) {
          drifted <- FALSE
        }
      } else {
        drifted <- FALSE
      }

      result <- list(
        drifted = drifted,
        source_hash = source_hash,
        skill_hash = skill_hash,
        timestamp = Sys.time()
      )

      # Store baseline for next comparison
      dir.create(dirname(baseline_file), recursive = TRUE, showWarnings = FALSE)
      saveRDS(result, baseline_file)

      result
    }
  )
)
