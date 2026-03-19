# R/15_clinical_normalisation.R
# Clinical-informed normalisation for biomarkers (SCOPE method)

#' Clinical reference ranges for myeloma biomarkers
#'
#' Returns a data frame of clinical reference ranges used for
#' clinical-informed normalisation. Based on standard laboratory ranges
#' for multiple myeloma-relevant biomarkers.
#'
#' @return Data frame with columns: biomarker, low, high, unit
#' @export
clinical_reference_ranges <- function() {
  data.frame(
    biomarker = c("creatinine", "albumin", "hemoglobin", "calcium",
                  "ldh", "b2m", "platelets", "flc_kappa", "flc_lambda"),
    low = c(0.6, 3.5, 12.0, 8.5, 120, 0.8, 150, 3.3, 5.7),
    high = c(1.2, 5.0, 17.5, 10.5, 250, 2.2, 400, 19.4, 26.3),
    unit = c("mg/dL", "g/dL", "g/dL", "mg/dL", "U/L", "mg/L",
             "10^3/uL", "mg/L", "mg/L"),
    stringsAsFactors = FALSE
  )
}


#' Clinical-informed normalisation
#'
#' Normalises biomarker values using clinical reference ranges instead of
#' statistical z-scoring. The SCOPE method (Hussain et al. 2024) maps values
#' to a clinically meaningful scale where the normal range is well-separated
#' and extreme values are compressed.
#'
#' Step 1: `x* = 4 * (x - ref_low) / (ref_high - ref_low) - 2`
#' Step 2: `x† = 7 / (1 + exp(-0.25 * x* - 3.5))`
#'
#' @param x Numeric vector of biomarker values
#' @param ref_low Lower bound of clinical reference range
#' @param ref_high Upper bound of clinical reference range
#' @param method One of `"clinical"` (SCOPE method) or `"zscore"` (standard)
#' @return Numeric vector of normalised values
#' @references Hussain et al. (2024). Joint AI-driven event prediction and
#'   longitudinal modeling in newly diagnosed and relapsed multiple myeloma.
#'   npj Digital Medicine, 7, 199.
#' @export
normalize_clinical <- function(x, ref_low, ref_high,
                                method = c("clinical", "zscore")) {
  method <- match.arg(method)

  if (method == "zscore") {
    mu <- mean(x, na.rm = TRUE)
    s <- stats::sd(x, na.rm = TRUE)
    if (is.na(s) || s == 0) return(rep(0, length(x)))
    return((x - mu) / s)
  }

  # SCOPE clinical normalisation
  x_star <- 4 * (x - ref_low) / (ref_high - ref_low) - 2
  7 / (1 + exp(-0.25 * x_star - 3.5))
}


#' Normalise all biomarkers in a clinical data frame
#'
#' Applies clinical-informed normalisation to all biomarker columns found
#' in the data, using reference ranges from [clinical_reference_ranges()].
#'
#' @param clinical_df Data frame of clinical data
#' @param method `"clinical"` or `"zscore"`
#' @param suffix Suffix for normalised column names (default `"_norm"`)
#' @return Data frame with additional normalised columns
#' @export
normalize_biomarkers <- function(clinical_df, method = "clinical",
                                  suffix = "_norm") {
  refs <- clinical_reference_ranges()

  # Map clinical column names to reference ranges
  col_map <- list(
    creatinine = c("creatinine", "serum_creatinine"),
    albumin = c("albumin", "serum_albumin"),
    hemoglobin = c("hemoglobin", "hb", "hgb"),
    calcium = c("calcium", "serum_calcium"),
    ldh = c("ldh", "lactate_dehydrogenase"),
    b2m = c("b2m", "beta_2_microglobulin", "beta2_microglobulin"),
    platelets = c("platelets", "platelet_count"),
    flc_kappa = c("flc_kappa", "kappa_free_light_chain"),
    flc_lambda = c("flc_lambda", "lambda_free_light_chain")
  )

  normalised <- list()
  for (biomarker in refs$biomarker) {
    # Find matching column
    possible_cols <- col_map[[biomarker]]
    matched <- intersect(tolower(names(clinical_df)), possible_cols)
    if (length(matched) == 0) next

    col <- names(clinical_df)[tolower(names(clinical_df)) == matched[1]]
    vals <- as.numeric(clinical_df[[col]])
    if (all(is.na(vals))) next

    ref <- refs[refs$biomarker == biomarker, ]
    norm_vals <- normalize_clinical(vals, ref$low, ref$high, method = method)
    new_col <- paste0(biomarker, suffix)
    clinical_df[[new_col]] <- norm_vals
    normalised <- c(normalised, biomarker)
  }

  if (length(normalised) > 0) {
    logger::log_info("Normalised {length(normalised)} biomarkers ({method}): {paste(normalised, collapse = ', ')}")
  }

  clinical_df
}
