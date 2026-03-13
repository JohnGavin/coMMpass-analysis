# R/tar_plans/plan_differential_expression.R
# Differential expression analysis targets

plan_differential_expression <- list(
  # DESeq2 analysis - unpaired with apeglm shrinkage
  tar_target(
    deseq2_results,
    run_deseq2(
      normalized_data,
      clinical_data_clean,
      design_formula = ~ condition,
      shrink_lfc = TRUE,
      paired = FALSE
    ),
    packages = c("DESeq2", "SummarizedExperiment")
  ),

  # DESeq2 analysis - paired longitudinal (within-patient)
  tar_target(
    deseq2_paired_results,
    run_deseq2(
      normalized_data,
      clinical_data_clean,
      shrink_lfc = TRUE,
      paired = TRUE
    ),
    packages = c("DESeq2", "SummarizedExperiment")
  ),

  # edgeR analysis
  tar_target(
    edger_results,
    run_edger(
      normalized_data,
      clinical_data_clean,
      design_formula = ~ condition
    ),
    packages = c("edgeR", "SummarizedExperiment")
  ),

  # limma-voom analysis
  tar_target(
    limma_results,
    run_limma(
      normalized_data,
      clinical_data_clean,
      design_formula = ~ condition
    ),
    packages = c("limma", "edgeR", "SummarizedExperiment")
  ),

  # Consensus DE genes (unpaired methods)
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

  # DE report
  tar_target(
    de_report,
    render_de_report(
      consensus_de_genes,
      output_dir = config$results_dir
    ),
    format = "file"
  )
)
