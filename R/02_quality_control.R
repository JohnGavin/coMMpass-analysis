# R/02_quality_control.R
# Quality control and normalization functions

#' Calculate QC metrics for RNA-seq data
calculate_qc_metrics <- function(se_data) {
  library(SummarizedExperiment)
  library(logger)
  
  log_info("Calculating QC metrics...")
  
  counts <- assay(se_data, "counts")
  
  metrics <- data.frame(
    sample = colnames(counts),
    total_counts = colSums(counts),
    detected_genes = colSums(counts > 0),
    median_count = apply(counts, 2, median),
    mad_count = apply(counts, 2, mad)
  )
  
  # Add library size factors
  metrics$size_factor <- metrics$total_counts / median(metrics$total_counts)
  
  # Flag potential outliers
  metrics$is_outlier <- 
    metrics$total_counts < quantile(metrics$total_counts, 0.05) |
    metrics$detected_genes < quantile(metrics$detected_genes, 0.05)
  
  log_info("QC metrics calculated for {nrow(metrics)} samples")
  log_info("{sum(metrics$is_outlier)} potential outliers detected")
  
  return(metrics)
}

#' Filter low-quality samples and genes
filter_low_quality <- function(se_data, min_counts = 10, min_samples = 3) {
  library(SummarizedExperiment)
  library(logger)
  
  counts <- assay(se_data, "counts")
  
  # Filter genes
  keep_genes <- rowSums(counts >= min_counts) >= min_samples
  log_info("Keeping {sum(keep_genes)}/{length(keep_genes)} genes")
  
  # Filter samples (using QC metrics)
  qc_metrics <- calculate_qc_metrics(se_data)
  keep_samples <- !qc_metrics$is_outlier
  log_info("Keeping {sum(keep_samples)}/{length(keep_samples)} samples")
  
  # Apply filters
  filtered_se <- se_data[keep_genes, keep_samples]
  
  return(filtered_se)
}

#' Normalize RNA-seq data
normalize_rnaseq <- function(se_data, method = "TMM") {
  library(edgeR)
  library(logger)
  
  log_info("Normalizing data using {method} method...")
  
  counts <- assay(se_data, "counts")
  
  # Create DGEList object
  dge <- DGEList(counts = counts)
  
  # Calculate normalization factors
  dge <- calcNormFactors(dge, method = method)
  
  # Calculate normalized counts
  norm_counts <- cpm(dge, log = TRUE, prior.count = 1)
  
  # Add to SummarizedExperiment
  assay(se_data, "logCPM") <- norm_counts
  
  log_info("Normalization complete")
  return(se_data)
}
