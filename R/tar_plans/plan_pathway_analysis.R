# R/tar_plans/plan_pathway_analysis.R
# Pathway and enrichment analysis targets using fgsea and msigdbr

plan_pathway_analysis <- list(

  # GSEA on DESeq2 results using Hallmark gene sets
  tar_target(
    gsea_hallmark,
    {
      de_table <- deseq2_results$results_table
      if (is.null(de_table) || nrow(de_table) == 0) {
        list(n_gene_sets = 0L, n_significant = 0L,
             top_gene_sets = data.frame(), results = data.frame(),
             note = "No DE results available for GSEA")
      } else {
        run_gsea(
          de_table,
          gene_sets = "hallmark",
          gene_id_type = "ensembl_gene"
        )
      }
    },
    packages = c("fgsea")
  ),

  # GSEA on DESeq2 results using KEGG pathways
  tar_target(
    gsea_kegg,
    {
      de_table <- deseq2_results$results_table
      if (is.null(de_table) || nrow(de_table) == 0) {
        list(n_gene_sets = 0L, n_significant = 0L,
             top_gene_sets = data.frame(), results = data.frame(),
             note = "No DE results available for GSEA")
      } else {
        run_gsea(
          de_table,
          gene_sets = "kegg",
          gene_id_type = "ensembl_gene"
        )
      }
    },
    packages = c("fgsea")
  ),

  # ORA on consensus DE genes using Hallmark gene sets
  tar_target(
    ora_hallmark,
    {
      sig <- consensus_de_genes$consensus_genes
      if (is.null(sig) || length(sig) < 5) {
        list(n_pathways_enriched = 0L, n_pathways_tested = 0L,
             top_pathways = data.frame(), results = data.frame(),
             note = "Too few consensus DE genes for ORA")
      } else {
        universe <- rownames(deseq2_results$results_table)
        if (is.null(universe)) universe <- sig
        run_ora(
          sig_genes = sig,
          universe = universe,
          gene_sets = "hallmark",
          gene_id_type = "ensembl_gene"
        )
      }
    }
  ),

  # Summary report (updated references)
  tar_target(
    summary_report,
    generate_summary_report(
      qc_metrics = qc_metrics,
      de_genes = consensus_de_genes,
      survival = list(km_overall = km_overall, cox_basic = cox_basic),
      pathways = ora_hallmark,
      output_dir = config$results_dir
    ),
    format = "file"
  )
)
