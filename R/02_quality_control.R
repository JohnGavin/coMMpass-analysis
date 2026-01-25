# R/02_quality_control.R
# Quality control and normalization functions

#' Calculate QC metrics for RNA-seq data
calculate_qc_metrics <- function(se_data) {
  library(logger)

  log_info("Calculating QC metrics...")

  # Handle both SummarizedExperiment and list structures
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    counts <- se_data$assays$counts
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    counts <- assay(se_data, "counts")
  } else {
    counts <- se_data
  }

  metrics <- data.frame(
    sample = colnames(counts),
    total_counts = colSums(counts),
    detected_genes = colSums(counts > 0),
    median_count = apply(counts, 2, median),
    mad_count = apply(counts, 2, mad)
  )

  # Add library size factors
  metrics$size_factor <- metrics$total_counts / median(metrics$total_counts)

  # Calculate percentage of mitochondrial genes (if available)
  mt_genes <- grepl("^MT-", rownames(counts))
  if (any(mt_genes)) {
    metrics$pct_mt <- colSums(counts[mt_genes, ]) / metrics$total_counts * 100
  } else {
    metrics$pct_mt <- 0
  }

  # Flag potential outliers using MAD-based approach
  is_outlier_mad <- function(x, nmads = 3) {
    M <- median(x, na.rm = TRUE)
    MAD <- mad(x, na.rm = TRUE)
    x < (M - nmads * MAD) | x > (M + nmads * MAD)
  }

  metrics$is_outlier <-
    is_outlier_mad(log10(metrics$total_counts)) |
    is_outlier_mad(metrics$detected_genes) |
    (metrics$pct_mt > 10)  # High mitochondrial content

  log_info("QC metrics calculated for {nrow(metrics)} samples")
  log_info("{sum(metrics$is_outlier)} potential outliers detected")

  return(metrics)
}

#' Filter low-quality samples and genes
filter_low_quality <- function(se_data, min_counts = 10, min_samples = 3) {
  library(logger)

  # Handle both SummarizedExperiment and list structures
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    counts <- se_data$assays$counts
    col_data <- se_data$colData
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    counts <- assay(se_data, "counts")
    col_data <- colData(se_data)
  } else {
    counts <- se_data
    col_data <- NULL
  }

  # Filter genes - require minimum counts in minimum samples
  keep_genes <- rowSums(counts >= min_counts) >= min_samples
  log_info("Keeping {sum(keep_genes)}/{length(keep_genes)} genes")

  # Filter samples (using QC metrics)
  qc_metrics <- calculate_qc_metrics(se_data)
  keep_samples <- !qc_metrics$is_outlier
  log_info("Keeping {sum(keep_samples)}/{length(keep_samples)} samples")

  # Apply filters
  filtered_counts <- counts[keep_genes, keep_samples]

  # Return in same format as input
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    filtered_se <- list(
      assays = list(counts = filtered_counts),
      colData = if (!is.null(col_data)) col_data[keep_samples, ] else NULL,
      metadata = c(
        se_data$metadata,
        list(
          n_genes_filtered = sum(!keep_genes),
          n_samples_filtered = sum(!keep_samples)
        )
      )
    )
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    filtered_se <- se_data[keep_genes, keep_samples]
  } else {
    filtered_se <- filtered_counts
  }

  return(filtered_se)
}

#' Normalize RNA-seq data
normalize_rnaseq <- function(se_data, method = "TMM") {
  library(edgeR)
  library(logger)

  log_info("Normalizing data using {method} method...")

  # Handle both SummarizedExperiment and list structures
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    counts <- se_data$assays$counts
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    counts <- assay(se_data, "counts")
  } else {
    counts <- se_data
  }

  # Create DGEList object
  dge <- DGEList(counts = counts)

  # Calculate normalization factors
  dge <- calcNormFactors(dge, method = method)

  # Calculate normalized counts (log CPM)
  norm_counts <- cpm(dge, log = TRUE, prior.count = 1)

  # Calculate RPKM if gene lengths available (for now, use CPM)
  rpkm <- rpkm(dge, log = TRUE)

  # Return in same format as input with normalized data
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    se_data$assays$logCPM <- norm_counts
    se_data$assays$logRPKM <- rpkm
    se_data$metadata$normalization <- list(
      method = method,
      norm_factors = dge$samples$norm.factors
    )
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    assay(se_data, "logCPM") <- norm_counts
    assay(se_data, "logRPKM") <- rpkm
    metadata(se_data)$normalization <- list(
      method = method,
      norm_factors = dge$samples$norm.factors
    )
  } else {
    # Return list if simple matrix input
    se_data <- list(
      counts = counts,
      logCPM = norm_counts,
      logRPKM = rpkm,
      norm_factors = dge$samples$norm.factors
    )
  }

  log_info("Normalization complete")
  return(se_data)
}
