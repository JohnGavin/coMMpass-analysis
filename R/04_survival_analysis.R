# R/04_survival_analysis.R
# Survival analysis functions for CoMMpass clinical data

#' Prepare survival data from clinical and cytogenetic data
#'
#' Constructs a data frame suitable for survival analysis from GDC clinical
#' data. Uses `days_to_death` for deceased patients and
#' `days_to_last_follow_up` for censored (alive) patients. Merges with
#' cytogenetic risk groups when available.
#'
#' @param clinical_data Cleaned clinical data frame (from clean_clinical_data)
#' @param cyto_file Path to cytogenetic parquet file (from extract_cytogenetic_data),
#'   or NULL to skip cytogenetic integration
#' @return Data frame with columns: patient_id, time_days, status (0=censored,
#'   1=dead), age_years, gender, iss_stage, risk_group, plus individual
#'   cytogenetic markers
#' @export
prepare_survival_data <- function(clinical_data, cyto_file = NULL) {
  if (is.null(clinical_data) || !is.data.frame(clinical_data) ||
      nrow(clinical_data) == 0) {
    cli::cli_abort(c(
      "x" = "clinical_data must be a non-empty data frame",
      "i" = "Run clean_clinical_data() first"
    ))
  }

  logger::log_info("Preparing survival data from {nrow(clinical_data)} patients")

  clin <- clinical_data
  names(clin) <- tolower(names(clin))

  # Find patient ID column
  id_col <- intersect(c("submitter_id", "patient_id", "bcr_patient_barcode"),
                       names(clin))
  if (length(id_col) == 0) {
    cli::cli_abort("No patient ID column found in clinical data")
  }

  surv <- data.frame(
    patient_id = clin[[id_col[1]]],
    stringsAsFactors = FALSE
  )

  # Construct survival time and event indicator
  has_death <- "days_to_death" %in% names(clin)
  has_follow <- "days_to_last_follow_up" %in% names(clin)
  has_vital <- "vital_status" %in% names(clin)

  if (!has_vital) {
    cli::cli_abort(c(
      "x" = "vital_status column required but not found",
      "i" = "Available columns: {paste(head(names(clin), 20), collapse = ', ')}"
    ))
  }

  vital <- tolower(clin$vital_status)
  is_dead <- vital %in% c("dead", "deceased", "1")

  # Event indicator: 1 = dead, 0 = censored (alive)
  surv$status <- as.integer(is_dead)

  # Time: days_to_death for dead, days_to_last_follow_up for alive
  surv$time_days <- NA_real_
  if (has_death) {
    surv$time_days[is_dead] <- as.numeric(clin$days_to_death[is_dead])
  }
  if (has_follow) {
    surv$time_days[!is_dead] <- as.numeric(clin$days_to_last_follow_up[!is_dead])
  }

  # Remove patients without valid survival time
  valid <- !is.na(surv$time_days) & surv$time_days > 0
  n_removed <- sum(!valid)
  if (n_removed > 0) {
    logger::log_info("Removing {n_removed} patients with missing/invalid survival time")
  }
  surv <- surv[valid, ]

  if (nrow(surv) == 0) {
    cli::cli_abort(c(
      "x" = "No patients with valid survival time after filtering",
      "i" = "Check days_to_death and days_to_last_follow_up columns"
    ))
  }

  # Add covariates
  clin_valid <- clin[valid, ]

  # Age (GDC stores in days)
  if ("age_at_diagnosis" %in% names(clin_valid)) {
    age_raw <- as.numeric(clin_valid$age_at_diagnosis)
    surv$age_years <- ifelse(
      max(age_raw, na.rm = TRUE) > 120,
      round(age_raw / 365.25, 1),
      age_raw
    )
  } else if ("age_at_diagnosis_years" %in% names(clin_valid)) {
    surv$age_years <- as.numeric(clin_valid$age_at_diagnosis_years)
  }

  # Gender
  if ("gender" %in% names(clin_valid)) {
    surv$gender <- tolower(clin_valid$gender)
  }

  # Merge cytogenetic data if available
  if (!is.null(cyto_file)) {
    cyto <- NULL
    if (is.character(cyto_file) && file.exists(cyto_file)) {
      if (grepl("\\.parquet$", cyto_file)) {
        cyto <- tryCatch(arrow::read_parquet(cyto_file), error = function(e) NULL)
      } else if (grepl("\\.rds$", cyto_file)) {
        cyto <- tryCatch(readRDS(cyto_file), error = function(e) NULL)
      }
    } else if (is.data.frame(cyto_file)) {
      cyto <- cyto_file
    }

    if (!is.null(cyto) && is.data.frame(cyto)) {
      cyto_cols <- intersect(
        c("patient_id", "iss_stage", "risk_group",
          "t_4_14", "t_11_14", "t_14_16", "t_14_20",
          "del_17p", "del_1p", "gain_1q"),
        names(cyto)
      )
      if ("patient_id" %in% cyto_cols) {
        surv <- merge(surv, cyto[, cyto_cols, drop = FALSE],
                      by = "patient_id", all.x = TRUE)
        logger::log_info("Merged cytogenetic data for {sum(!is.na(surv$risk_group))} patients")
      }
    }
  }

  # ISS stage from clinical data if not already from cytogenetic
  if (!"iss_stage" %in% names(surv) || all(is.na(surv$iss_stage))) {
    iss_col <- grep("^iss", names(clin_valid), value = TRUE)
    if (length(iss_col) > 0) {
      surv$iss_stage <- clin_valid[[iss_col[1]]]
    }
  }

  # Clean ISS stage values
  if ("iss_stage" %in% names(surv)) {
    surv$iss_stage[surv$iss_stage %in% c("", "Not Reported", "not reported")] <- NA
  }

  logger::log_info(
    "Survival data prepared: {nrow(surv)} patients, ",
    "{sum(surv$status == 1)} events, ",
    "{sum(surv$status == 0)} censored"
  )

  surv
}

#' Run Kaplan-Meier analysis
#'
#' Fits a Kaplan-Meier survival curve, optionally stratified by a grouping
#' variable. Returns the survfit object, log-rank test, and summary statistics.
#'
#' @param surv_data Data frame from [prepare_survival_data()] with columns
#'   `time_days` and `status`
#' @param strata Column name to stratify by (e.g. "risk_group", "iss_stage",
#'   "gender"), or NULL for overall curve
#' @return List with components:
#'   - `fit`: survfit object
#'   - `logrank`: survdiff result (NULL if no strata)
#'   - `logrank_p`: log-rank p-value (NA if no strata)
#'   - `median_survival`: named vector of median survival times
#'   - `n_per_group`: sample sizes per stratum
#'   - `strata`: the stratification variable used
#' @export
run_kaplan_meier <- function(surv_data, strata = NULL) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg survival} required but not installed")
  }

  # Validate input
  required_cols <- c("time_days", "status")
  missing <- setdiff(required_cols, names(surv_data))
  if (length(missing) > 0) {
    cli::cli_abort("Missing required columns: {paste(missing, collapse = ', ')}")
  }

  if (!is.null(strata)) {
    if (!strata %in% names(surv_data)) {
      cli::cli_abort("Stratification variable '{strata}' not found in data")
    }
    # Remove rows with NA in strata
    valid <- !is.na(surv_data[[strata]])
    if (sum(valid) == 0) {
      cli::cli_abort("All values of '{strata}' are NA")
    }
    surv_data <- surv_data[valid, ]
    n_levels <- length(unique(surv_data[[strata]]))
    logger::log_info("KM analysis stratified by {strata} ({n_levels} groups)")
    formula <- stats::as.formula(
      paste("survival::Surv(time_days, status) ~", strata)
    )
  } else {
    logger::log_info("KM analysis: overall survival curve")
    formula <- survival::Surv(time_days, status) ~ 1
  }

  # Fit KM curve
  fit <- survival::survfit(formula, data = surv_data)

  # Log-rank test (only if stratified)
  logrank <- NULL
  logrank_p <- NA_real_
  if (!is.null(strata) && n_levels >= 2) {
    logrank <- survival::survdiff(formula, data = surv_data)
    logrank_p <- stats::pchisq(logrank$chisq, df = n_levels - 1, lower.tail = FALSE)
  }

  # Extract median survival per group
  surv_summary <- summary(fit)$table
  if (is.null(dim(surv_summary))) {
    # Single group: summary$table is a named vector
    median_surv <- c(overall = unname(surv_summary["median"]))
    n_per_group <- c(overall = unname(surv_summary["records"]))
  } else {
    median_surv <- surv_summary[, "median"]
    n_per_group <- surv_summary[, "records"]
  }

  logger::log_info(
    "KM complete: median survival = {paste(round(median_surv, 0), collapse = '/')}"
  )
  if (!is.na(logrank_p)) {
    logger::log_info("Log-rank p = {signif(logrank_p, 3)}")
  }

  list(
    fit = fit,
    logrank = logrank,
    logrank_p = logrank_p,
    median_survival = median_surv,
    n_per_group = n_per_group,
    strata = strata,
    formula = formula,
    data = surv_data
  )
}

#' Run Cox proportional hazards regression
#'
#' Fits a Cox PH model with specified covariates. Returns the model object,
#' hazard ratios with confidence intervals, and concordance index.
#'
#' @param surv_data Data frame from [prepare_survival_data()]
#' @param covariates Character vector of covariate column names
#' @return List with components:
#'   - `model`: coxph object
#'   - `hazard_ratios`: data frame with HR, CI, p-values
#'   - `concordance`: C-index
#'   - `n`: number of patients in model
#'   - `n_events`: number of events
#'   - `ph_test`: cox.zph result for PH assumption
#' @export
run_cox_regression <- function(surv_data,
                               covariates = c("age_years", "gender")) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg survival} required but not installed")
  }

  # Filter to available covariates
  available <- intersect(covariates, names(surv_data))
  if (length(available) == 0) {
    cli::cli_abort(c(
      "x" = "None of the requested covariates found in data",
      "i" = "Requested: {paste(covariates, collapse = ', ')}",
      "i" = "Available: {paste(names(surv_data), collapse = ', ')}"
    ))
  }

  if (length(available) < length(covariates)) {
    dropped <- setdiff(covariates, available)
    logger::log_info("Dropping unavailable covariates: {paste(dropped, collapse = ', ')}")
  }

  # Build formula
  rhs <- paste(available, collapse = " + ")
  formula <- stats::as.formula(
    paste("survival::Surv(time_days, status) ~", rhs)
  )

  logger::log_info("Cox regression: {deparse(formula)}")

  # Remove rows with NA in any covariate
  complete <- stats::complete.cases(surv_data[, c("time_days", "status", available)])
  if (sum(complete) < 10) {
    cli::cli_abort(c(
      "x" = "Only {sum(complete)} complete cases (need >= 10)",
      "i" = "Check for missing values in covariates"
    ))
  }
  surv_complete <- surv_data[complete, ]

  # Fit Cox model
  model <- survival::coxph(formula, data = surv_complete)

  # Extract hazard ratios
  coef_summary <- summary(model)$coefficients
  conf_int <- summary(model)$conf.int

  hr_df <- data.frame(
    variable = rownames(coef_summary),
    HR = round(exp(coef_summary[, "coef"]), 3),
    HR_lower = round(conf_int[, "lower .95"], 3),
    HR_upper = round(conf_int[, "upper .95"], 3),
    p_value = signif(coef_summary[, "Pr(>|z|)"], 3),
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  # Concordance
  concordance <- summary(model)$concordance[1]

  # PH assumption test
  ph_test <- tryCatch(
    survival::cox.zph(model),
    error = function(e) {
      logger::log_info("cox.zph() failed: {conditionMessage(e)}")
      NULL
    }
  )

  logger::log_info(
    "Cox model: {nrow(surv_complete)} patients, {sum(surv_complete$status)} events, ",
    "C-index = {round(concordance, 3)}"
  )

  list(
    model = model,
    hazard_ratios = hr_df,
    concordance = concordance,
    n = nrow(surv_complete),
    n_events = sum(surv_complete$status),
    covariates_used = available,
    ph_test = ph_test,
    formula = formula,
    data = surv_complete
  )
}
