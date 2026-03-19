# _targets.R
# Main orchestrator for CoMMpass analysis pipeline
# Sources modular plans from R/tar_plans/
library(targets)
library(tarchetypes)
library(crew)

# Set global options
tar_option_set(
  packages = c(
    "survival",  # survminer removed - not available in nixpkgs
    "tidyverse", "logger"
    # Bioconductor packages (TCGAbiolinks, DESeq2, edgeR, limma, etc.)
    # declared per-target in plan files to avoid blocking non-Bioc targets
  ),
  format = "rds",  # Fast serialization
  memory = "transient",  # Free memory after use
  garbage_collection = TRUE,
  controller = crew_controller_local(
    workers = 4,  # Parallel workers
    seconds_idle = 60
  )
)

# Source analysis functions (excluding R/dev/ and R/tar_plans/)
for (file in list.files("R", pattern = "\\.(R|r)$", full.names = TRUE)) {
  if (!grepl("R/(dev|tar_plans)/", file)) {
    source(file)
  }
}

# Source visualization helper functions from R/viz/
for (file in list.files("R/viz", pattern = "\\.(R|r)$", full.names = TRUE)) {
  source(file)
}

# Source modular target plans from R/tar_plans/
plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$", full.names = TRUE)
for (plan_file in plan_files) {
  source(plan_file)
}

# Combine all plans into main pipeline
c(
  plan_nix_sync,       # DESCRIPTION -> Nix drift detection
  plan_skill_drift,    # Skill <-> R source drift detection
  plan_data_acquisition,
  plan_data_cleaning,  # Clean and integrate data
  plan_cytogenetic,    # Cytogenetic marker extraction from clinical data
  plan_eda,            # Exploratory data analysis summaries
  plan_doc_examples,   # Code-as-targets for vignette display blocks
  plan_vignette_outputs, # Pre-computed vignette display objects
  plan_quality_control,
  plan_differential_expression,
  plan_de_visualization,   # VST, PCA, volcano/MA/heatmap data
  plan_survival_analysis,
  plan_survival_shiny,     # Pre-computed survival for Shiny module
  plan_pathway_analysis,
  plan_gene_annotation,    # Ensembl -> symbol, enrichment viz data
  plan_cytogenetic_viz,    # Oncoprint and co-occurrence visualization
  plan_gene_correlations,  # Gene-gene correlation analysis
  plan_treatment,          # Treatment/regimen data cleaning
  plan_normalisation,   # Clinical-informed biomarker normalisation
  plan_missingness,     # Missingness pattern analysis
  plan_bayesian,        # Bayesian survival models (brms)
  plan_causal,          # Causal DAG analysis (dagitty/ggdag)
  plan_api,             # Static JSON API generation (Phase 1)
  plan_pkgctx,          # Auto-generate .ctx.yaml API context files
  plan_dag_validation,  # Cross-layer dependency validation
  plan_telemetry        # Git changelog, GitHub activity, codebase metrics
)