# R/13_missingness_analysis.R
# Missingness pattern analysis for CoMMpass clinical data

#' Compute missingness profile for clinical data
#'
#' Analyzes patterns of missing data across clinical variables, grouped
#' by variable category (demographic, staging, biomarker, FISH, outcome).
#'
#' @param clinical_df Data frame of clinical data
#' @return List with components: `per_variable` (missing counts/pct per var),
#'   `per_patient` (missing count per patient), `co_missing` (pairwise
#'   co-missingness matrix), `n_patients`, `n_variables`.
#' @export
compute_missingness_profile <- function(clinical_df) {
  if (is.null(clinical_df) || nrow(clinical_df) == 0) return(NULL)

  n <- nrow(clinical_df)
  p <- ncol(clinical_df)

  # Per-variable missingness
  per_var <- data.frame(
    variable = names(clinical_df),
    n_missing = vapply(clinical_df, function(x) sum(is.na(x)), integer(1)),
    pct_missing = vapply(clinical_df, function(x) round(100 * mean(is.na(x)), 1), numeric(1)),
    stringsAsFactors = FALSE
  )
  per_var <- per_var[order(-per_var$pct_missing), ]

  # Categorize variables
  per_var$category <- categorize_clinical_var(per_var$variable)

  # Per-patient missingness
  patient_missing <- rowSums(is.na(clinical_df))
  per_patient <- data.frame(
    n_missing = as.integer(patient_missing),
    pct_missing = round(100 * patient_missing / p, 1)
  )

  # Co-missingness: pairwise proportion of shared missingness
  # Only for variables with > 5% missing
  high_miss_vars <- per_var$variable[per_var$pct_missing > 5]
  co_missing <- NULL
  if (length(high_miss_vars) >= 2) {
    miss_mat <- is.na(clinical_df[, high_miss_vars, drop = FALSE])
    co_missing <- cor(miss_mat + 0L, use = "pairwise.complete.obs")
  }

  list(
    per_variable = per_var,
    per_patient = per_patient,
    co_missing = co_missing,
    high_miss_vars = high_miss_vars,
    n_patients = n,
    n_variables = p
  )
}


#' Categorize clinical variable names
#'
#' Maps variable names to categories for grouped missingness analysis.
#'
#' @param var_names Character vector of variable names
#' @return Character vector of categories
#' @keywords internal
categorize_clinical_var <- function(var_names) {
  cats <- rep("other", length(var_names))
  cats[grepl("age|gender|race|ethnicity|ecog", var_names, ignore.case = TRUE)] <- "demographic"
  cats[grepl("iss|stage|figo|ann_arbor", var_names, ignore.case = TRUE)] <- "staging"
  cats[grepl("b2m|albumin|ldh|hemoglobin|creatinine|calcium|platelet|flc|kappa|lambda", var_names, ignore.case = TRUE)] <- "biomarker"
  cats[grepl("t_4_14|t_11_14|t_14|del_17|del_1|gain_1|risk_group", var_names, ignore.case = TRUE)] <- "FISH"
  cats[grepl("vital|death|follow_up|days_to|status|survival", var_names, ignore.case = TRUE)] <- "outcome"
  cats[grepl("treatment|therap|regimen|response|sct", var_names, ignore.case = TRUE)] <- "treatment"
  cats
}


#' Test whether missingness predicts survival
#'
#' Fits a Cox model: Surv(time, status) ~ is_missing_X for each variable
#' with significant missingness. Tests whether patients with missing data
#' have different survival than those with complete data.
#'
#' @param survival_data Data frame with time_days and status columns
#' @param clinical_df Data frame of clinical data (same patients)
#' @param min_missing_pct Minimum missingness percentage to test (default 5)
#' @return Data frame with variable, HR, CI, p-value, interpretation
#' @export
test_missingness_vs_outcome <- function(survival_data, clinical_df,
                                         min_missing_pct = 5) {
  if (is.null(survival_data) || is.null(clinical_df)) return(NULL)
  if (!requireNamespace("survival", quietly = TRUE)) return(NULL)

  # Match patients
  common <- intersect(survival_data$patient_id,
                       clinical_df$submitter_id %||% clinical_df$patient_id)
  if (length(common) < 20) return(NULL)

  sd <- survival_data[survival_data$patient_id %in% common, ]

  results <- list()
  for (col in names(clinical_df)) {
    pct_miss <- 100 * mean(is.na(clinical_df[[col]]))
    if (pct_miss < min_missing_pct || pct_miss > 95) next

    # Create binary: is this variable missing for each patient?
    id_col <- if ("submitter_id" %in% names(clinical_df)) "submitter_id" else "patient_id"
    miss_flag <- is.na(clinical_df[[col]])
    names(miss_flag) <- clinical_df[[id_col]]
    sd$is_missing <- miss_flag[sd$patient_id]

    if (sum(sd$is_missing, na.rm = TRUE) < 5 ||
        sum(!sd$is_missing, na.rm = TRUE) < 5) next

    fit <- tryCatch({
      survival::coxph(survival::Surv(time_days, status) ~ is_missing,
                      data = sd)
    }, error = function(e) NULL)

    if (is.null(fit)) next

    s <- summary(fit)
    hr <- s$coefficients[1, "exp(coef)"]
    ci_lo <- s$conf.int[1, "lower .95"]
    ci_hi <- s$conf.int[1, "upper .95"]
    pval <- s$coefficients[1, "Pr(>|z|)"]

    interp <- if (pval < 0.05 && hr > 1) {
      "Missing → worse survival (MNAR: sicker patients not tested?)"
    } else if (pval < 0.05 && hr < 1) {
      "Missing → better survival (MNAR: low-risk patients not tested?)"
    } else {
      "No association (consistent with MCAR)"
    }

    results[[length(results) + 1]] <- data.frame(
      Variable = col, HR = round(hr, 2),
      CI = paste0("[", round(ci_lo, 2), "-", round(ci_hi, 2), "]"),
      p_value = signif(pval, 3), Pct_Missing = round(pct_miss, 1),
      Interpretation = interp, stringsAsFactors = FALSE
    )
  }

  if (length(results) == 0) return(NULL)
  df <- do.call(rbind, results)
  df[order(df$p_value), ]
}
