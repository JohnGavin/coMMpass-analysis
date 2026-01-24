# R/generate_example_data.R
# Generate example data for testing the CoMMpass pipeline
# This creates realistic but synthetic data that exercises all pipeline features

library(tidyverse)

set.seed(42)  # For reproducibility

#' Generate synthetic RNA-seq count matrix
#' @param n_genes Number of genes (default: 100)
#' @param n_samples Number of samples (default: 30)
#' @param n_de_genes Number of differentially expressed genes (default: 30)
generate_counts_matrix <- function(n_genes = 100, n_samples = 30, n_de_genes = 30) {
  cat("Generating RNA-seq count matrix...\n")

  # Sample names
  sample_ids <- paste0("MMRF_", sprintf("%04d", 1:n_samples))

  # Gene names (use real gene symbols for realism)
  gene_symbols <- c(
    # Myeloma-relevant genes
    "CCND1", "CCND2", "CCND3", "MYC", "FGFR3", "MMSET", "MAF", "MAFB",
    "IRF4", "PRDM1", "XBP1", "CD138", "CD38", "BCMA", "SLAMF7",
    # Immune genes
    "CD3D", "CD4", "CD8A", "CD8B", "FOXP3", "CTLA4", "PDCD1", "LAG3",
    "HAVCR2", "TIGIT", "CD28", "ICOS", "IL2", "IFNG", "TNF",
    # Housekeeping genes
    "GAPDH", "ACTB", "B2M", "HPRT1", "RPL13A", "YWHAZ", "SDHA",
    # Additional genes to reach n_genes
    paste0("GENE", seq_len(n_genes - 42))
  )[1:n_genes]

  # Generate base expression levels (log-normal distribution)
  base_expression <- matrix(
    rnbinom(n_genes * n_samples, mu = 100, size = 10),
    nrow = n_genes,
    ncol = n_samples,
    dimnames = list(gene_symbols, sample_ids)
  )

  # Add biological variation
  # Assume first half are responders, second half non-responders
  responder_status <- c(rep("responder", n_samples/2),
                       rep("non_responder", n_samples - n_samples/2))

  # Add differential expression for some genes
  de_genes_idx <- sample(1:n_genes, n_de_genes)
  for (i in de_genes_idx) {
    fold_change <- runif(1, 1.5, 4)  # 1.5-4x fold change
    if (runif(1) > 0.5) fold_change <- 1/fold_change  # Down-regulation

    # Apply fold change to non-responders
    base_expression[i, responder_status == "non_responder"] <-
      round(base_expression[i, responder_status == "non_responder"] * fold_change)
  }

  # Ensure non-negative values
  base_expression[base_expression < 0] <- 0

  return(base_expression)
}

#' Generate clinical data with survival information
#' @param n_samples Number of samples
generate_clinical_data <- function(n_samples = 30) {
  cat("Generating clinical data...\n")

  sample_ids <- paste0("MMRF_", sprintf("%04d", 1:n_samples))

  # Treatment response (affects survival)
  responder_status <- c(rep("responder", n_samples/2),
                       rep("non_responder", n_samples - n_samples/2))

  clinical_data <- data.frame(
    patient_id = sample_ids,
    age = round(rnorm(n_samples, mean = 65, sd = 10)),
    sex = sample(c("M", "F"), n_samples, replace = TRUE, prob = c(0.6, 0.4)),
    race = sample(c("White", "Black", "Asian", "Other"), n_samples,
                 replace = TRUE, prob = c(0.7, 0.15, 0.1, 0.05)),

    # ISS stage (International Staging System)
    iss_stage = sample(c("I", "II", "III"), n_samples,
                      replace = TRUE, prob = c(0.3, 0.4, 0.3)),

    # Cytogenetics
    cytogenetics_risk = sample(c("standard", "high"), n_samples,
                             replace = TRUE, prob = c(0.6, 0.4)),

    # Treatment
    treatment = sample(c("VRd", "KRd", "DRd", "DVd"), n_samples, replace = TRUE),
    treatment_response = responder_status,

    # M-protein levels
    m_protein_baseline = round(runif(n_samples, 0.5, 8), 2),

    # Survival data
    os_time = NA,  # Will be filled based on response
    os_status = NA,
    pfs_time = NA,
    pfs_status = NA,

    # Risk group for stratification
    risk_group = NA
  )

  # Generate survival times based on response and stage
  for (i in 1:n_samples) {
    # Base survival time depends on response
    if (clinical_data$treatment_response[i] == "responder") {
      base_os <- runif(1, 1000, 2000)  # 1000-2000 days
      base_pfs <- runif(1, 500, 1200)
    } else {
      base_os <- runif(1, 300, 1000)   # 300-1000 days
      base_pfs <- runif(1, 100, 500)
    }

    # Modify by stage
    stage_factor <- switch(clinical_data$iss_stage[i],
                          "I" = 1.2,
                          "II" = 1.0,
                          "III" = 0.7)

    clinical_data$os_time[i] <- round(base_os * stage_factor)
    clinical_data$pfs_time[i] <- round(base_pfs * stage_factor)

    # Censoring (some patients still alive/progression-free)
    clinical_data$os_status[i] <- sample(0:1, 1, prob = c(0.3, 0.7))
    clinical_data$pfs_status[i] <- sample(0:1, 1, prob = c(0.2, 0.8))

    # Assign risk group based on multiple factors
    risk_score <- 0
    if (clinical_data$iss_stage[i] == "III") risk_score <- risk_score + 2
    if (clinical_data$iss_stage[i] == "II") risk_score <- risk_score + 1
    if (clinical_data$cytogenetics_risk[i] == "high") risk_score <- risk_score + 2
    if (clinical_data$age[i] > 70) risk_score <- risk_score + 1

    clinical_data$risk_group[i] <- ifelse(risk_score <= 1, "low",
                                         ifelse(risk_score <= 3, "intermediate", "high"))
  }

  # Ensure age is reasonable
  clinical_data$age[clinical_data$age < 40] <- 40
  clinical_data$age[clinical_data$age > 90] <- 90

  # Add a condition column for differential expression
  clinical_data$condition <- clinical_data$treatment_response

  return(clinical_data)
}

#' Generate sample metadata
#' @param n_samples Number of samples
generate_metadata <- function(n_samples = 30) {
  cat("Generating sample metadata...\n")

  sample_ids <- paste0("MMRF_", sprintf("%04d", 1:n_samples))

  metadata <- data.frame(
    sample_id = sample_ids,
    sample_type = "Bone Marrow",
    collection_date = seq(as.Date("2020-01-01"),
                         by = "month",
                         length.out = n_samples),
    rna_quality = round(runif(n_samples, 7, 10), 1),  # RIN scores
    library_size = round(runif(n_samples, 10e6, 50e6)),
    batch = sample(paste0("Batch", 1:3), n_samples, replace = TRUE),
    sequencing_platform = "Illumina NovaSeq",
    read_length = 150,
    paired_end = TRUE
  )

  return(metadata)
}

#' Create mock SummarizedExperiment-like object
#' @param counts Count matrix
#' @param clinical Clinical data
#' @param metadata Sample metadata
create_summarized_experiment <- function(counts, clinical, metadata) {
  cat("Creating data object...\n")

  # Ensure sample order matches
  common_samples <- intersect(colnames(counts), clinical$patient_id)
  counts <- counts[, common_samples]
  clinical <- clinical[match(common_samples, clinical$patient_id), ]
  metadata <- metadata[match(common_samples, metadata$sample_id), ]

  # Create a list structure similar to SummarizedExperiment
  # This can be converted to actual SE when package is available
  se_like <- list(
    assays = list(counts = counts),
    colData = cbind(clinical, metadata[, -1]),  # Exclude duplicate sample_id
    metadata = list(
      created = Sys.Date(),
      description = "Example data for CoMMpass pipeline testing",
      n_samples = ncol(counts),
      n_genes = nrow(counts)
    )
  )

  class(se_like) <- c("MockSummarizedExperiment", "list")
  return(se_like)
}

#' Main function to generate all example data
#' @param output_dir Directory to save the data
generate_example_data <- function(output_dir = "data/example") {
  cat("\n=== Generating CoMMpass Example Data ===\n\n")

  # Create output directory
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  # Generate data components
  counts <- generate_counts_matrix(n_genes = 100, n_samples = 30, n_de_genes = 30)
  clinical <- generate_clinical_data(n_samples = 30)
  metadata <- generate_metadata(n_samples = 30)

  # Create data object (mock SummarizedExperiment)
  se <- create_summarized_experiment(counts, clinical, metadata)

  # Save individual components
  saveRDS(counts, file.path(output_dir, "counts_matrix.rds"))
  saveRDS(clinical, file.path(output_dir, "clinical_data.rds"))
  saveRDS(metadata, file.path(output_dir, "metadata.rds"))
  saveRDS(se, file.path(output_dir, "example_data.rds"))

  # Save as CSV for inspection
  write.csv(counts, file.path(output_dir, "counts_matrix.csv"))
  write.csv(clinical, file.path(output_dir, "clinical_data.csv"), row.names = FALSE)
  write.csv(metadata, file.path(output_dir, "metadata.csv"), row.names = FALSE)

  # Create summary statistics
  summary_stats <- list(
    n_samples = ncol(counts),
    n_genes = nrow(counts),
    n_de_genes = 30,
    median_counts = median(counts),
    sparsity = mean(counts == 0),
    survival_stats = list(
      median_os = median(clinical$os_time),
      median_pfs = median(clinical$pfs_time),
      event_rate_os = mean(clinical$os_status),
      event_rate_pfs = mean(clinical$pfs_status)
    ),
    risk_groups = table(clinical$risk_group),
    treatment_response = table(clinical$treatment_response)
  )

  saveRDS(summary_stats, file.path(output_dir, "summary_stats.rds"))

  cat("\n✅ Example data generated successfully!\n")
  cat("\nFiles created in", output_dir, ":\n")
  cat("  - counts_matrix.rds (100 genes × 30 samples)\n")
  cat("  - clinical_data.rds (30 patients with survival)\n")
  cat("  - metadata.rds (sample annotations)\n")
  cat("  - example_data.rds (all data combined)\n")
  cat("  - CSV files for manual inspection\n")

  cat("\nData characteristics:\n")
  cat("  - Samples:", summary_stats$n_samples, "\n")
  cat("  - Genes:", summary_stats$n_genes, "\n")
  cat("  - Median survival (OS):", summary_stats$survival_stats$median_os, "days\n")
  cat("  - Risk groups:", paste(names(summary_stats$risk_groups),
                                summary_stats$risk_groups, collapse = ", "), "\n")

  return(invisible(se))
}

# Run if called directly
if (!interactive()) {
  generate_example_data()
}