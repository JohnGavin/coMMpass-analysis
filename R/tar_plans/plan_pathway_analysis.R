# R/tar_plans/plan_pathway_analysis.R
# Pathway and enrichment analysis targets

plan_pathway_analysis <- list(
  # Pathway enrichment
  tar_target(
    pathway_enrichment,
    run_pathway_analysis(
      consensus_de_genes,
      method = "clusterProfiler"
    )
  ),

  # GSEA
  tar_target(
    gsea_results,
    run_gsea(
      normalized_data,
      clinical_data
    )
  ),

  # Summary report
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