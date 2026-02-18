# Package index

## Data Access

Functions for retrieving CoMMpass data from GDC and AWS S3

- [`query_commpass_rna()`](https://JohnGavin.github.io/coMMpass-analysis/reference/query_commpass_rna.md)
  : Query GDC for CoMMpass RNA-seq Metadata
- [`get_commpass_clinical()`](https://JohnGavin.github.io/coMMpass-analysis/reference/get_commpass_clinical.md)
  : Query GDC for CoMMpass Clinical Data
- [`list_s3_commpass()`](https://JohnGavin.github.io/coMMpass-analysis/reference/list_s3_commpass.md)
  : List AWS S3 CoMMpass Bucket Contents
- [`download_s3_subset()`](https://JohnGavin.github.io/coMMpass-analysis/reference/download_s3_subset.md)
  : Download a Sample of RNA-seq Files from S3
- [`download_gdc_rnaseq()`](https://JohnGavin.github.io/coMMpass-analysis/reference/download_gdc_rnaseq.md)
  : Download RNA-seq data from GDC
- [`download_clinical_data()`](https://JohnGavin.github.io/coMMpass-analysis/reference/download_clinical_data.md)
  : Download clinical data from GDC
- [`download_aws_data()`](https://JohnGavin.github.io/coMMpass-analysis/reference/download_aws_data.md)
  : Download data from AWS S3 open access bucket
- [`acquire_commpass_data()`](https://JohnGavin.github.io/coMMpass-analysis/reference/acquire_commpass_data.md)
  : Main data acquisition function
- [`save_rnaseq_parquet()`](https://JohnGavin.github.io/coMMpass-analysis/reference/save_rnaseq_parquet.md)
  : Save SummarizedExperiment as parquet files

## Data Dictionary

Variable documentation and metadata

- [`get_commpass_data_dictionary()`](https://JohnGavin.github.io/coMMpass-analysis/reference/get_commpass_data_dictionary.md)
  : Get CoMMpass Data Dictionary
- [`get_variable_docs()`](https://JohnGavin.github.io/coMMpass-analysis/reference/get_variable_docs.md)
  : Get Extended Documentation for a Variable

## Data Cleaning

Clean and integrate clinical and expression data

- [`clean_clinical_data()`](https://JohnGavin.github.io/coMMpass-analysis/reference/clean_clinical_data.md)
  : Clean Clinical Data
- [`clean_expression_data()`](https://JohnGavin.github.io/coMMpass-analysis/reference/clean_expression_data.md)
  : Clean Expression Data
- [`integrate_clinical_expression()`](https://JohnGavin.github.io/coMMpass-analysis/reference/integrate_clinical_expression.md)
  : Create Integrated Dataset

## Data Querying

DuckDB-backed parquet querying

- [`query_commpass_parquet()`](https://JohnGavin.github.io/coMMpass-analysis/reference/query_commpass_parquet.md)
  : Query CoMMpass Parquet Files
- [`get_commpass_tbl()`](https://JohnGavin.github.io/coMMpass-analysis/reference/get_commpass_tbl.md)
  : Get Lazy DuckDB Table for CoMMpass Data
- [`resolve_parquet_path()`](https://JohnGavin.github.io/coMMpass-analysis/reference/resolve_parquet_path.md)
  : Resolve Parquet File Path

## Quality Control

QC metrics and filtering

- [`calculate_qc_metrics()`](https://JohnGavin.github.io/coMMpass-analysis/reference/calculate_qc_metrics.md)
  : Calculate QC metrics for RNA-seq data
- [`filter_low_quality()`](https://JohnGavin.github.io/coMMpass-analysis/reference/filter_low_quality.md)
  : Filter low-quality samples and genes
- [`normalize_rnaseq()`](https://JohnGavin.github.io/coMMpass-analysis/reference/normalize_rnaseq.md)
  : Normalize RNA-seq data

## Differential Expression

DE analysis with DESeq2, edgeR, and limma

- [`run_deseq2()`](https://JohnGavin.github.io/coMMpass-analysis/reference/run_deseq2.md)
  : Run DESeq2 differential expression analysis
- [`run_edger()`](https://JohnGavin.github.io/coMMpass-analysis/reference/run_edger.md)
  : Run edgeR differential expression analysis
- [`run_limma()`](https://JohnGavin.github.io/coMMpass-analysis/reference/run_limma.md)
  : Run limma differential expression analysis
- [`find_consensus_genes()`](https://JohnGavin.github.io/coMMpass-analysis/reference/find_consensus_genes.md)
  : Find consensus DE genes across methods
- [`render_de_report()`](https://JohnGavin.github.io/coMMpass-analysis/reference/render_de_report.md)
  : Render DE analysis report

## Survival Analysis

Kaplan-Meier and Cox regression

- [`prepare_survival_data()`](https://JohnGavin.github.io/coMMpass-analysis/reference/prepare_survival_data.md)
  : Prepare survival data
- [`run_kaplan_meier()`](https://JohnGavin.github.io/coMMpass-analysis/reference/run_kaplan_meier.md)
  : Run Kaplan-Meier analysis
- [`run_cox_regression()`](https://JohnGavin.github.io/coMMpass-analysis/reference/run_cox_regression.md)
  : Run Cox proportional hazards regression
- [`render_survival_report()`](https://JohnGavin.github.io/coMMpass-analysis/reference/render_survival_report.md)
  : Render survival analysis report

## Pathway Analysis

GSEA and pathway enrichment

- [`run_gsea()`](https://JohnGavin.github.io/coMMpass-analysis/reference/run_gsea.md)
  : Run Gene Set Enrichment Analysis
- [`run_pathway_analysis()`](https://JohnGavin.github.io/coMMpass-analysis/reference/run_pathway_analysis.md)
  : Run pathway enrichment analysis
- [`generate_summary_report()`](https://JohnGavin.github.io/coMMpass-analysis/reference/generate_summary_report.md)
  : Generate summary report

## Utilities

Helper functions for formatting and summaries

- [`format_file_size()`](https://JohnGavin.github.io/coMMpass-analysis/reference/format_file_size.md)
  : Format File Size in Human-Readable Format
- [`format_with_commas()`](https://JohnGavin.github.io/coMMpass-analysis/reference/format_with_commas.md)
  : Format Number with Thousands Separator
- [`create_summary_table()`](https://JohnGavin.github.io/coMMpass-analysis/reference/create_summary_table.md)
  : Create Summary Statistics Table
- [`setup_logging()`](https://JohnGavin.github.io/coMMpass-analysis/reference/setup_logging.md)
  : Setup logging
- [`create_project_dirs()`](https://JohnGavin.github.io/coMMpass-analysis/reference/create_project_dirs.md)
  : Create project directories
- [`check_dependencies()`](https://JohnGavin.github.io/coMMpass-analysis/reference/check_dependencies.md)
  : Check package dependencies
- [`save_timestamped()`](https://JohnGavin.github.io/coMMpass-analysis/reference/save_timestamped.md)
  : Save results with timestamp
- [`summarize_data()`](https://JohnGavin.github.io/coMMpass-analysis/reference/summarize_data.md)
  : Generate summary statistics
