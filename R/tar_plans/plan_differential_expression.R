# R/tar_plans/plan_differential_expression.R
# Differential expression analysis targets

plan_differential_expression <- list(
  # DESeq2 analysis
  tar_target(
    deseq2_results,
    run_deseq2(
      normalized_data,
      clinical_data,
      design_formula = ~ condition
    )
  ),

  # edgeR analysis
  tar_target(
    edger_results,
    run_edger(
      normalized_data,
      clinical_data,
      design_formula = ~ condition
    )
  ),

  # limma-voom analysis
  tar_target(
    limma_results,
    run_limma(
      normalized_data,
      clinical_data,
      design_formula = ~ condition
    )
  ),

  # Consensus DE genes
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