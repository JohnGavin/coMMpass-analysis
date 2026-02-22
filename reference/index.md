# Package index

## Package Documentation

Package overview and metadata

- [`coMMpass`](https://johngavin.github.io/coMMpass/reference/coMMpass-package.md)
  [`coMMpass-package`](https://johngavin.github.io/coMMpass/reference/coMMpass-package.md)
  : coMMpass: MMRF CoMMpass Data Analysis Pipeline

## Data Access

Functions for retrieving CoMMpass data from GDC and AWS S3

- [`query_commpass_rna()`](https://johngavin.github.io/coMMpass/reference/query_commpass_rna.md)
  : Query GDC for CoMMpass RNA-seq Metadata
- [`get_commpass_clinical()`](https://johngavin.github.io/coMMpass/reference/get_commpass_clinical.md)
  : Query GDC for CoMMpass Clinical Data
- [`list_s3_commpass()`](https://johngavin.github.io/coMMpass/reference/list_s3_commpass.md)
  : List AWS S3 CoMMpass Bucket Contents
- [`download_s3_subset()`](https://johngavin.github.io/coMMpass/reference/download_s3_subset.md)
  : Download a Sample of RNA-seq Files from S3
- [`download_gdc_rnaseq()`](https://johngavin.github.io/coMMpass/reference/download_gdc_rnaseq.md)
  : Download RNA-seq data from GDC
- [`download_clinical_data()`](https://johngavin.github.io/coMMpass/reference/download_clinical_data.md)
  : Download clinical data from GDC
- [`download_aws_data()`](https://johngavin.github.io/coMMpass/reference/download_aws_data.md)
  : Download data from AWS S3 open access bucket
- [`acquire_commpass_data()`](https://johngavin.github.io/coMMpass/reference/acquire_commpass_data.md)
  : Main data acquisition function
- [`save_rnaseq_parquet()`](https://johngavin.github.io/coMMpass/reference/save_rnaseq_parquet.md)
  : Save SummarizedExperiment as parquet files

## Data Dictionary

Variable documentation and metadata

- [`get_commpass_data_dictionary()`](https://johngavin.github.io/coMMpass/reference/get_commpass_data_dictionary.md)
  : Get CoMMpass Data Dictionary
- [`get_variable_docs()`](https://johngavin.github.io/coMMpass/reference/get_variable_docs.md)
  : Get Extended Documentation for a Variable

## Data Cleaning

Clean and integrate clinical and expression data

- [`clean_clinical_data()`](https://johngavin.github.io/coMMpass/reference/clean_clinical_data.md)
  : Clean Clinical Data
- [`clean_expression_data()`](https://johngavin.github.io/coMMpass/reference/clean_expression_data.md)
  : Clean Expression Data
- [`integrate_clinical_expression()`](https://johngavin.github.io/coMMpass/reference/integrate_clinical_expression.md)
  : Create Integrated Dataset

## Data Parsing

Parse and extract data from CoMMpass files

- [`parse_commpass_barcodes()`](https://johngavin.github.io/coMMpass/reference/parse_commpass_barcodes.md)
  : Parse CoMMpass sample barcodes
- [`parse_cytogenetic_status()`](https://johngavin.github.io/coMMpass/reference/parse_cytogenetic_status.md)
  : Parse cytogenetic status values to standardized categories
- [`extract_counts()`](https://johngavin.github.io/coMMpass/reference/extract_counts.md)
  : Extract counts matrix from SummarizedExperiment
- [`extract_cytogenetic_data()`](https://johngavin.github.io/coMMpass/reference/extract_cytogenetic_data.md)
  : Extract cytogenetic markers from clinical data

## Data Querying

DuckDB-backed parquet querying

- [`query_commpass_parquet()`](https://johngavin.github.io/coMMpass/reference/query_commpass_parquet.md)
  : Query CoMMpass Parquet Files
- [`get_commpass_tbl()`](https://johngavin.github.io/coMMpass/reference/get_commpass_tbl.md)
  : Get Lazy DuckDB Table for CoMMpass Data
- [`resolve_parquet_path()`](https://johngavin.github.io/coMMpass/reference/resolve_parquet_path.md)
  : Resolve Parquet File Path

## Quality Control

QC metrics and filtering

- [`calculate_qc_metrics()`](https://johngavin.github.io/coMMpass/reference/calculate_qc_metrics.md)
  : Calculate QC metrics for RNA-seq data
- [`filter_low_quality()`](https://johngavin.github.io/coMMpass/reference/filter_low_quality.md)
  : Filter low-quality samples and genes
- [`normalize_rnaseq()`](https://johngavin.github.io/coMMpass/reference/normalize_rnaseq.md)
  : Normalize RNA-seq data

## Differential Expression

DE analysis with DESeq2, edgeR, and limma

- [`run_deseq2()`](https://johngavin.github.io/coMMpass/reference/run_deseq2.md)
  : Run DESeq2 differential expression analysis
- [`run_deseq2_paired()`](https://johngavin.github.io/coMMpass/reference/run_deseq2_paired.md)
  : Run paired longitudinal DESeq2 analysis
- [`run_edger()`](https://johngavin.github.io/coMMpass/reference/run_edger.md)
  : Run edgeR differential expression analysis
- [`run_limma()`](https://johngavin.github.io/coMMpass/reference/run_limma.md)
  : Run limma differential expression analysis
- [`find_consensus_genes()`](https://johngavin.github.io/coMMpass/reference/find_consensus_genes.md)
  : Find consensus DE genes across methods
- [`render_de_report()`](https://johngavin.github.io/coMMpass/reference/render_de_report.md)
  : Render DE analysis report
- [`placeholder_results()`](https://johngavin.github.io/coMMpass/reference/placeholder_results.md)
  : Create placeholder results when real analysis cannot run

## Cytogenetic Analysis

Risk classification and cytogenetic data processing

- [`classify_cytogenetic_risk()`](https://johngavin.github.io/coMMpass/reference/classify_cytogenetic_risk.md)
  : Classify cytogenetic risk group
- [`summarize_cytogenetics()`](https://johngavin.github.io/coMMpass/reference/summarize_cytogenetics.md)
  : Summarize cytogenetic alteration frequencies

## Survival Analysis

Kaplan-Meier and Cox regression

- [`prepare_survival_data()`](https://johngavin.github.io/coMMpass/reference/prepare_survival_data.md)
  : Prepare survival data from clinical and cytogenetic data
- [`prepare_coldata()`](https://johngavin.github.io/coMMpass/reference/prepare_coldata.md)
  : Prepare colData for DESeq2
- [`build_paired_coldata()`](https://johngavin.github.io/coMMpass/reference/build_paired_coldata.md)
  : Build paired sample metadata
- [`run_kaplan_meier()`](https://johngavin.github.io/coMMpass/reference/run_kaplan_meier.md)
  : Run Kaplan-Meier analysis
- [`run_cox_regression()`](https://johngavin.github.io/coMMpass/reference/run_cox_regression.md)
  : Run Cox proportional hazards regression
- [`plot_km()`](https://johngavin.github.io/coMMpass/reference/plot_km.md)
  : Plot Kaplan-Meier curve
- [`plot_forest()`](https://johngavin.github.io/coMMpass/reference/plot_forest.md)
  : Plot forest plot of Cox hazard ratios
- [`run_km_by_markers()`](https://johngavin.github.io/coMMpass/reference/run_km_by_markers.md)
  : Run KM analysis for each individual cytogenetic marker

## DE Visualization

Volcano, MA, PCA, and heatmap plots for DE results

- [`plot_volcano()`](https://johngavin.github.io/coMMpass/reference/plot_volcano.md)
  : Volcano plot of DE results
- [`plot_ma()`](https://johngavin.github.io/coMMpass/reference/plot_ma.md)
  : MA plot of DE results
- [`plot_pca()`](https://johngavin.github.io/coMMpass/reference/plot_pca.md)
  : PCA plot
- [`plot_heatmap_de()`](https://johngavin.github.io/coMMpass/reference/plot_heatmap_de.md)
  : Heatmap of top DE genes
- [`run_vst()`](https://johngavin.github.io/coMMpass/reference/run_vst.md)
  : Run variance stabilizing transformation
- [`compute_pca()`](https://johngavin.github.io/coMMpass/reference/compute_pca.md)
  : Compute PCA from transformed expression data
- [`summarize_de_methods()`](https://johngavin.github.io/coMMpass/reference/summarize_de_methods.md)
  : Summarize DE results across methods

## Gene Annotation

Ensembl to gene symbol mapping and enrichment visualization

- [`annotate_genes()`](https://johngavin.github.io/coMMpass/reference/annotate_genes.md)
  : Annotate Ensembl gene IDs with symbols and descriptions
- [`annotate_de_results()`](https://johngavin.github.io/coMMpass/reference/annotate_de_results.md)
  : Add gene symbol column to DE results table
- [`annotate_via_msigdbr()`](https://johngavin.github.io/coMMpass/reference/annotate_via_msigdbr.md)
  : Annotate genes using msigdbr mapping table
- [`annotate_via_orgdb()`](https://johngavin.github.io/coMMpass/reference/annotate_via_orgdb.md)
  : Annotate genes using org.Hs.eg.db
- [`find_expr_col()`](https://johngavin.github.io/coMMpass/reference/find_expr_col.md)
  : Find the mean expression column name
- [`find_lfc_col()`](https://johngavin.github.io/coMMpass/reference/find_lfc_col.md)
  : Find the log fold-change column name
- [`find_padj_col()`](https://johngavin.github.io/coMMpass/reference/find_padj_col.md)
  : Find the adjusted p-value column name
- [`plot_enrichment_dotplot()`](https://johngavin.github.io/coMMpass/reference/plot_enrichment_dotplot.md)
  : Dot plot of enrichment results
- [`plot_enrichment_barplot()`](https://johngavin.github.io/coMMpass/reference/plot_enrichment_barplot.md)
  : Bar plot of enrichment results
- [`plot_gsea_running_score()`](https://johngavin.github.io/coMMpass/reference/plot_gsea_running_score.md)
  : GSEA running enrichment score plot

## Cytogenetic Visualization

Oncoprint and co-occurrence analysis for cytogenetic markers

- [`plot_cytogenetic_oncoprint()`](https://johngavin.github.io/coMMpass/reference/plot_cytogenetic_oncoprint.md)
  : Plot cytogenetic oncoprint
- [`calculate_cooccurrence()`](https://johngavin.github.io/coMMpass/reference/calculate_cooccurrence.md)
  : Calculate pairwise co-occurrence of cytogenetic alterations
- [`plot_cooccurrence_heatmap()`](https://johngavin.github.io/coMMpass/reference/plot_cooccurrence_heatmap.md)
  : Plot co-occurrence heatmap of cytogenetic alterations

## Pathway Analysis

GSEA and pathway enrichment

- [`run_gsea()`](https://johngavin.github.io/coMMpass/reference/run_gsea.md)
  : Run Gene Set Enrichment Analysis (GSEA)
- [`run_ora()`](https://johngavin.github.io/coMMpass/reference/run_ora.md)
  : Run Over-Representation Analysis (ORA)
- [`run_pathway_analysis()`](https://johngavin.github.io/coMMpass/reference/run_pathway_analysis.md)
  : Run pathway enrichment analysis
- [`build_gene_ranks()`](https://johngavin.github.io/coMMpass/reference/build_gene_ranks.md)
  : Build ranked gene vector from DE results
- [`get_msigdb_gene_sets()`](https://johngavin.github.io/coMMpass/reference/get_msigdb_gene_sets.md)
  : Get gene set collections from MSigDB
- [`generate_summary_report()`](https://johngavin.github.io/coMMpass/reference/generate_summary_report.md)
  : Generate summary report

## Utilities

Helper functions for formatting and summaries

- [`format_file_size()`](https://johngavin.github.io/coMMpass/reference/format_file_size.md)
  : Format File Size in Human-Readable Format
- [`format_with_commas()`](https://johngavin.github.io/coMMpass/reference/format_with_commas.md)
  : Format Number with Thousands Separator
- [`create_summary_table()`](https://johngavin.github.io/coMMpass/reference/create_summary_table.md)
  : Create Summary Statistics Table
- [`setup_logging()`](https://johngavin.github.io/coMMpass/reference/setup_logging.md)
  : Setup logging
- [`create_project_dirs()`](https://johngavin.github.io/coMMpass/reference/create_project_dirs.md)
  : Create project directories
- [`check_dependencies()`](https://johngavin.github.io/coMMpass/reference/check_dependencies.md)
  : Check package dependencies
- [`save_timestamped()`](https://johngavin.github.io/coMMpass/reference/save_timestamped.md)
  : Save results with timestamp
- [`summarize_data()`](https://johngavin.github.io/coMMpass/reference/summarize_data.md)
  : Generate summary statistics
- [`get_description_deps()`](https://johngavin.github.io/coMMpass/reference/get_description_deps.md)
  : Extract Package Dependencies from DESCRIPTION
