# R/dev/issue/fix_targets_structure.R
# Fix script for issue #2: Restructure targets pipeline to follow project conventions
# Created: 2026-01-24
# Issue: Targets plans were incorrectly placed in root instead of R/tar_plans/

# Context: This script documents the fix applied to restructure the targets
# pipeline to follow the project convention of modular plans in R/tar_plans/

# PROBLEM:
# - Initial implementation placed all targets in monolithic _targets.R in root
# - Project convention requires modular plans in R/tar_plans/ folder
# - This violates reproducibility principle by not following project structure

# SOLUTION:
# 1. Created R/tar_plans/ directory
# 2. Split pipeline into modular plans:
#    - plan_data_acquisition.R
#    - plan_quality_control.R
#    - plan_differential_expression.R
#    - plan_survival_analysis.R
#    - plan_pathway_analysis.R
# 3. Updated _targets.R to source from R/tar_plans/

# FILES CREATED:
cat("Files created in R/tar_plans/:\n")
tar_plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$", full.names = TRUE)
for (file in tar_plan_files) {
  cat("  -", file, "\n")
}

# FILES MODIFIED:
cat("\nFiles modified:\n")
cat("  - _targets.R (restructured to source from R/tar_plans/)\n")

# TESTING PERFORMED:
cat("\nTesting performed:\n")
cat("  - tar_validate() passed\n")
cat("  - tar_manifest() shows 18 targets\n")
cat("  - Note: tar_make() requires coMMpass-specific Nix environment\n")

# LESSONS LEARNED:
cat("\nLessons learned:\n")
cat("  1. Always follow project-specific conventions over tool defaults\n")
cat("  2. R/tar_plans/ enables modular, reusable pipeline components\n")
cat("  3. Test in project-specific Nix environment, not global\n")
cat("  4. CI workflows need to trigger on R file changes, not just .nix\n")

# RECOMMENDATION FOR CLAUDE.md UPDATE:
cat("\n=== Suggested CLAUDE.md clarification ===\n")
cat("## Targets Pipeline Structure (MANDATORY)\n")
cat("**NEVER place pipeline targets directly in _targets.R**\n")
cat("Instead:\n")
cat("1. Create modular plans in R/tar_plans/plan_*.R\n")
cat("2. Each plan should return a list of tar_target() objects\n")
cat("3. _targets.R should only:\n")
cat("   - Set tar_option_set()\n")
cat("   - Source functions from R/ (excluding R/dev/ and R/tar_plans/)\n")
cat("   - Source and combine plans from R/tar_plans/\n")
cat("4. This ensures modularity and reusability\n")