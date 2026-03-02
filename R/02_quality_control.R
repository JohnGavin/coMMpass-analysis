# R/02_quality_control.R
# Quality control and normalization functions

#' Calculate QC metrics for RNA-seq data
#'
#' @param se_data A SummarizedExperiment object with a "counts" assay
#' @return A data frame with QC metrics per sample
#' @family quality-control
#' @export

calculate_qc_metrics <- function(se_data) {
  logger::log_info("Calculating QC metrics...")

  counts <- get_counts_assay(se_data)

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

  logger::log_info("QC metrics calculated for {nrow(metrics)} samples")
  logger::log_info("{sum(metrics$is_outlier)} potential outliers detected")

  return(metrics)
}

#' Filter low-quality samples and genes
#'
#' @param se_data A SummarizedExperiment object
#' @param min_counts Minimum count threshold per gene
#' @param min_samples Minimum samples with counts above threshold
#' @return Filtered SummarizedExperiment
filter_low_quality <- function(se_data, min_counts = 10, min_samples = 3) {
  counts <- get_counts_assay(se_data)

  # Filter genes
  keep_genes <- rowSums(counts >= min_counts) >= min_samples
  logger::log_info("Keeping {sum(keep_genes)}/{length(keep_genes)} genes")

  # Filter samples (using QC metrics)
  qc_metrics <- calculate_qc_metrics(se_data)
  keep_samples <- !qc_metrics$is_outlier
  logger::log_info("Keeping {sum(keep_samples)}/{length(keep_samples)} samples")

  # Apply filters
  filtered_se <- se_data[keep_genes, keep_samples]

  return(filtered_se)
}

#' Normalize RNA-seq data
#'
#' @param se_data A SummarizedExperiment object with a "counts" assay
#' @param method Normalization method (default: "TMM")
#' @return SummarizedExperiment with added "logCPM" assay
normalize_rnaseq <- function(se_data, method = "TMM") {
  logger::log_info("Normalizing data using {method} method...")

  counts <- get_counts_assay(se_data)

  # Create DGEList object
  dge <- edgeR::DGEList(counts = counts)

  # Calculate normalization factors
  dge <- edgeR::calcNormFactors(dge, method = method)

  # Calculate normalized counts
  norm_counts <- edgeR::cpm(dge, log = TRUE, prior.count = 1)

  # Add to SummarizedExperiment
  SummarizedExperiment::`assay<-`(se_data, "logCPM", value = norm_counts)

  logger::log_info("Normalization complete")
  return(se_data)
}
