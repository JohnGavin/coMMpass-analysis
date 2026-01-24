# _targets.R
# Reproducible pipeline for CoMMpass analysis
library(targets)
library(tarchetypes)
library(crew)

# Set options
tar_option_set(
  packages = c(
    "TCGAbiolinks", "GenomicDataCommons", "SummarizedExperiment",
    "DESeq2", "edgeR", "limma",
    "survival", "survminer",
    "tidyverse", "logger"
  ),
  format = "rds",  # Fast serialization
  memory = "transient",  # Free memory after use
  garbage_collection = TRUE,
  controller = crew_controller_local(
    workers = 4,  # Parallel workers
    seconds_idle = 60
  )
)

# Source only package files, not dev files
pkg_files <- setdiff(
  list.files("R", pattern = "\\.R$", full.names = TRUE, recursive = TRUE),
  list.files("R/dev", pattern = "\\.R$", full.names = TRUE, recursive = TRUE)
)
tar_source(files = pkg_files)

# Define pipeline
list(
  # Configuration targets
  tar_target(
    config,
    list(
      project_id = "MMRF-COMMPASS",
      sample_limit = 10,  # Start small for testing
      data_dir = "data",
      results_dir = "results",
      seed = 42
    )
  ),

  # Data acquisition
  tar_target(
    raw_rnaseq,
    download_gdc_rnaseq(
      project_id = config$project_id,
      data_dir = file.path(config$data_dir, "raw", "gdc"),
      sample_limit = config$sample_limit
    ),
    cue = tar_cue(mode = "never")  # Don't re-download
  ),

  tar_target(
    clinical_data,
    download_clinical_data(
      project_id = config$project_id,
      data_dir = file.path(config$data_dir, "raw", "clinical")
    ),
    cue = tar_cue(mode = "never")
  ),

  # Quality control
  tar_target(
    qc_metrics,
    calculate_qc_metrics(raw_rnaseq)
  ),

  tar_target(
    filtered_data,
    filter_low_quality(
      raw_rnaseq,
      min_counts = 10,
      min_samples = 3
    )
  ),

  tar_target(
    normalized_data,
    normalize_rnaseq(filtered_data)
  ),

  # Differential expression
  tar_target(
    deseq2_results,
    run_deseq2(
      normalized_data,
      clinical_data,
      design_formula = ~ condition
    )
  ),

  tar_target(
    edger_results,
    run_edger(
      normalized_data,
      clinical_data,
      design_formula = ~ condition
    )
  ),

  tar_target(
    limma_results,
    run_limma(
      normalized_data,
      clinical_data,
      design_formula = ~ condition
    )
  ),

  tar_target(
    consensus_de_genes,
    find_consensus_genes(
      list(
        deseq2 = deseq2_results,
        edger = edger_results,
        limma = limma_results
      ),
      padj_threshold = 0.05,
      lfc_threshold = 1
    )
  ),

  # Survival analysis
  tar_target(
    survival_data,
    prepare_survival_data(
      clinical_data,
      normalized_data
    )
  ),

  tar_target(
    km_analysis,
    run_kaplan_meier(
      survival_data,
      group_by = "risk_group"
    )
  ),

  tar_target(
    cox_model,
    run_cox_regression(
      survival_data,
      covariates = c("age", "stage", "gene_signature")
    )
  ),

  # Pathway analysis
  tar_target(
    pathway_enrichment,
    run_pathway_analysis(
      consensus_de_genes,
      method = "clusterProfiler"
    )
  ),

  tar_target(
    gsea_results,
    run_gsea(
      normalized_data,
      clinical_data
    )
  ),

  # Reports
  tar_target(
    de_report,
    render_de_report(
      consensus_de_genes,
      output_dir = config$results_dir
    ),
    format = "file"
  ),

  tar_target(
    survival_report,
    render_survival_report(
      km_analysis,
      cox_model,
      output_dir = config$results_dir
    ),
    format = "file"
  ),

  tar_target(
    summary_report,
    generate_summary_report(
      qc_metrics = qc_metrics,
      de_genes = consensus_de_genes,
      survival = list(km_analysis, cox_model),
      pathways = pathway_enrichment,
      output_dir = config$results_dir
    ),
    format = "file"
  )
)
