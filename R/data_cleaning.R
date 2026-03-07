# R/data_cleaning.R
# Data cleaning and preprocessing functions

#' Clean Clinical Data
#'
#' Standardizes clinical data column names and formats
#' @param clinical_raw Raw clinical data frame
#' @return Cleaned clinical data frame
#' @family data-cleaning
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
    clinical$age_at_diagnosis_years <- round(as.numeric(clinical$age_at_diagnosis) / 365.25, 1)
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

  # Standardize heavy chain isotype
  if ("heavy_chain" %in% names(clinical)) {
    hc <- tolower(clinical$heavy_chain)
    hc[hc %in% c("igg", "ig g")] <- "IgG"
    hc[hc %in% c("iga", "ig a")] <- "IgA"
    hc[hc %in% c("igd", "ig d")] <- "IgD"
    hc[hc %in% c("ige", "ig e")] <- "IgE"
    hc[hc %in% c("igm", "ig m")] <- "IgM"
    hc[hc %in% c("light chain only", "light chain", "lco")] <- "Light chain only"
    clinical$heavy_chain <- hc
  }

  # Standardize light chain type
  if ("light_chain" %in% names(clinical)) {
    lc <- tolower(clinical$light_chain)
    lc[lc %in% c("kappa", "k")] <- "Kappa"
    lc[lc %in% c("lambda", "l")] <- "Lambda"
    clinical$light_chain <- lc
  }

  # Validate ECOG performance status
  if ("ecog_status" %in% names(clinical)) {
    clinical$ecog_status <- suppressWarnings(as.integer(clinical$ecog_status))
    out_of_range <- !is.na(clinical$ecog_status) &
      (clinical$ecog_status < 0L | clinical$ecog_status > 4L)
    if (any(out_of_range)) {
      warning(sum(out_of_range), " ECOG values outside 0-4 range, setting to NA")
      clinical$ecog_status[out_of_range] <- NA_integer_
    }
  }

  # --- Numeric biomarker validation (#63) ---
  # GDC column name aliases -> canonical names
  gdc_aliases <- c(
    serum_beta_2_microglobulin = "b2m",
    beta_2_microglobulin = "b2m",
    serum_albumin = "albumin",
    serum_free_kappa = "flc_kappa",
    serum_free_lambda = "flc_lambda",
    lactate_dehydrogenase = "ldh"
  )
  for (alias in names(gdc_aliases)) {
    canon <- gdc_aliases[alias]
    if (alias %in% names(clinical) && !canon %in% names(clinical)) {
      names(clinical)[names(clinical) == alias] <- canon
    }
  }

  # Derive FLC ratio if kappa and lambda present
  if (all(c("flc_kappa", "flc_lambda") %in% names(clinical))) {
    lambda <- as.numeric(clinical$flc_lambda)
    clinical$flc_ratio <- ifelse(
      !is.na(lambda) & lambda > 0,
      round(as.numeric(clinical$flc_kappa) / lambda, 2),
      NA_real_
    )
  }

  # Range validation for numeric biomarkers
  biomarker_ranges <- list(
    b2m = c(0, 50),           # mg/L
    albumin = c(1, 6),        # g/dL
    flc_kappa = c(0, 10000),  # mg/L
    flc_lambda = c(0, 10000), # mg/L
    flc_ratio = c(0, 1000),   # ratio
    ldh = c(0, 5000),         # U/L
    hemoglobin = c(2, 25),    # g/dL
    creatinine = c(0, 30),    # mg/dL
    calcium = c(5, 20),       # mg/dL
    platelets = c(0, 1500)    # 10^9/L
  )
  for (col in names(biomarker_ranges)) {
    if (col %in% names(clinical)) {
      clinical[[col]] <- suppressWarnings(as.numeric(clinical[[col]]))
      rng <- biomarker_ranges[[col]]
      out <- !is.na(clinical[[col]]) &
        (clinical[[col]] < rng[1] | clinical[[col]] > rng[2])
      if (any(out)) {
        clinical[[col]][out] <- NA_real_
      }
    }
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
#' @family data-cleaning
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
    expr <- expr[!zero_genes, , drop = FALSE]
  }

  # If all genes removed, return early
  if (nrow(expr) == 0) {
    attr(expr, "n_genes") <- 0L
    attr(expr, "n_samples") <- ncol(expr)
    attr(expr, "total_counts") <- 0
    attr(expr, "median_counts_per_sample") <- NA_real_
    attr(expr, "percent_zeros") <- 100
    return(expr)
  }

  # Remove samples with very low counts
  sample_counts <- colSums(expr)
  low_samples <- sample_counts < 10000
  if (any(low_samples)) {
    message("Removing ", sum(low_samples), " samples with < 10,000 total counts")
    expr <- expr[, !low_samples, drop = FALSE]
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
#' @family data-cleaning
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
