# R/tar_plans/plan_data_cleaning.R
# Data cleaning and preprocessing pipeline plan

#' Clean Clinical Data
#'
#' Standardizes clinical data column names and formats
#' @param clinical_raw Raw clinical data frame
#' @return Cleaned clinical data frame
#' @description clean_clinical_data
#' @export
clean_clinical_data <- function(clinical_raw) {
  if (is.null(clinical_raw) || nrow(clinical_raw) == 0) {
    return(clinical_raw)
  }

  clinical <- clinical_raw

  # Fix duplicate column names
  names(clinical) <- make.unique(names(clinical))

  # Standardize column names to lowercase with underscores
  names(clinical) <- tolower(names(clinical))
  names(clinical) <- gsub("\\.", "_", names(clinical))
  names(clinical) <- gsub("__+", "_", names(clinical))

  # Convert age from days to years if present
  if ("age_at_diagnosis" %in% names(clinical)) {
    clinical$age_at_diagnosis_years <- round(clinical$age_at_diagnosis / 365.25, 1)
  }

  # Standardize categorical variables
  if ("gender" %in% names(clinical)) {
    clinical$gender <- tolower(clinical$gender)
    clinical$gender[clinical$gender %in% c("m", "male")] <- "male"
    clinical$gender[clinical$gender %in% c("f", "female")] <- "female"
  }

  if ("vital_status" %in% names(clinical)) {
    clinical$vital_status <- tolower(clinical$vital_status)
  }

  # Add data quality flags
  clinical$n_missing <- rowSums(is.na(clinical))
  clinical$percent_missing <- round(100 * clinical$n_missing / ncol(clinical), 1)

  # Order columns with key variables first
  key_cols <- c("submitter_id", "project", "gender", "age_at_diagnosis_years",
                "vital_status", "race", "ethnicity")
  key_cols <- intersect(key_cols, names(clinical))
  other_cols <- setdiff(names(clinical), key_cols)
  clinical <- clinical[, c(key_cols, other_cols)]

  return(clinical)
}

#' Clean Expression Data
#'
#' Standardizes expression data format and adds metadata
#' @param expr_raw Raw expression data (matrix or data frame)
#' @return Cleaned expression matrix with gene names as rownames
#' @description clean_expression_data
#' @export
clean_expression_data <- function(expr_raw) {
  if (is.null(expr_raw)) {
    return(expr_raw)
  }

  # Convert to matrix if needed
  if (!is.matrix(expr_raw)) {
    expr <- as.matrix(expr_raw)
  } else {
    expr <- expr_raw
  }

  # Ensure numeric
  storage.mode(expr) <- "numeric"

  # Remove genes with zero expression across all samples
  zero_genes <- rowSums(expr) == 0
  if (any(zero_genes)) {
    message("Removing ", sum(zero_genes), " genes with zero expression across all samples")
    expr <- expr[!zero_genes, ]
  }

  # Remove samples with very low counts
  sample_counts <- colSums(expr)
  low_samples <- sample_counts < 10000
  if (any(low_samples)) {
    message("Removing ", sum(low_samples), " samples with < 10,000 total counts")
    expr <- expr[, !low_samples]
  }

  # Add gene and sample metadata as attributes
  attr(expr, "n_genes") <- nrow(expr)
  attr(expr, "n_samples") <- ncol(expr)
  attr(expr, "total_counts") <- sum(expr)
  attr(expr, "median_counts_per_sample") <- median(colSums(expr))
  attr(expr, "percent_zeros") <- 100 * mean(expr == 0)

  return(expr)
}

#' Create Integrated Dataset
#'
#' Combines clinical and expression data with consistent sample IDs
#' @param clinical_clean Cleaned clinical data
#' @param expr_clean Cleaned expression data
#' @return List with matched clinical and expression data
#' @description integrate_clinical_expression
#' @export
integrate_clinical_expression <- function(clinical_clean, expr_clean) {
  if (is.null(clinical_clean) || is.null(expr_clean)) {
    return(list(
      clinical = clinical_clean,
      expression = expr_clean,
      matched_samples = character(0)
    ))
  }

  # Find matching samples
  clinical_ids <- clinical_clean$submitter_id
  expr_ids <- colnames(expr_clean)

  # Try to match IDs (accounting for different naming conventions)
  matched_ids <- intersect(clinical_ids, expr_ids)

  if (length(matched_ids) == 0) {
    warning("No matching sample IDs found between clinical and expression data")
    return(list(
      clinical = clinical_clean,
      expression = expr_clean,
      matched_samples = character(0)
    ))
  }

  # Subset to matched samples
  clinical_matched <- clinical_clean[clinical_clean$submitter_id %in% matched_ids, ]
  expr_matched <- expr_clean[, colnames(expr_clean) %in% matched_ids]

  # Ensure same order
  clinical_matched <- clinical_matched[order(clinical_matched$submitter_id), ]
  expr_matched <- expr_matched[, order(colnames(expr_matched))]

  message("Matched ", length(matched_ids), " samples between clinical and expression data")

  return(list(
    clinical = clinical_matched,
    expression = expr_matched,
    matched_samples = matched_ids,
    n_matched = length(matched_ids),
    n_clinical_only = length(setdiff(clinical_ids, matched_ids)),
    n_expression_only = length(setdiff(expr_ids, matched_ids))
  ))
}

#' Data Cleaning Plan
#'
#' Returns a list of targets for data cleaning
plan_data_cleaning <- list(
  # Clean clinical data
  tar_target(
    clinical_data_clean,
    {
      # Load clinical data from the saved files
      clinical_file <- file.path(clinical_data, "clinical_data.rds")
      if (file.exists(clinical_file)) {
        clinical_raw <- readRDS(clinical_file)
        clean_clinical_data(clinical_raw)
      } else {
        # Fallback to CSV if RDS doesn't exist
        clinical_csv <- file.path(clinical_data, "clinical_data.csv")
        if (file.exists(clinical_csv)) {
          clinical_raw <- read.csv(clinical_csv, stringsAsFactors = FALSE)
          clean_clinical_data(clinical_raw)
        } else {
          warning("No clinical data file found")
          NULL
        }
      }
    },
    packages = c("dplyr")
  ),

  # Clean expression data
  tar_target(
    expression_data_clean,
    {
      # Load expression data from saved file
      if (!is.null(raw_rnaseq) && file.exists(raw_rnaseq)) {
        se_data <- readRDS(raw_rnaseq)
        # Extract counts matrix from SummarizedExperiment
        if (inherits(se_data, "SummarizedExperiment")) {
          expr_matrix <- SummarizedExperiment::assay(se_data, "counts")
          clean_expression_data(expr_matrix)
        } else {
          NULL
        }
      } else {
        NULL
      }
    },
    packages = c("SummarizedExperiment")
  ),

  # Create integrated dataset
  tar_target(
    integrated_data,
    integrate_clinical_expression(clinical_data_clean, expression_data_clean)
  ),

  # Generate data quality report
  tar_target(
    data_quality_report,
    {
      report <- list(
        clinical = if (!is.null(clinical_data_clean)) {
          list(
            n_patients = nrow(clinical_data_clean),
            n_variables = ncol(clinical_data_clean),
            completeness = mean(!is.na(clinical_data_clean)),
            key_variables = intersect(
              c("submitter_id", "gender", "age_at_diagnosis_years", "vital_status"),
              names(clinical_data_clean)
            )
          )
        } else NULL,
        expression = if (!is.null(expression_data_clean)) {
          list(
            n_genes = attr(expression_data_clean, "n_genes"),
            n_samples = attr(expression_data_clean, "n_samples"),
            percent_zeros = attr(expression_data_clean, "percent_zeros")
          )
        } else NULL,
        integration = if (!is.null(integrated_data)) {
          list(
            n_matched = integrated_data$n_matched,
            n_clinical_only = integrated_data$n_clinical_only,
            n_expression_only = integrated_data$n_expression_only
          )
        } else NULL
      )
      report
    }
  )
)
