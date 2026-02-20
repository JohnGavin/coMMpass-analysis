# tests/testthat/test-survival-analysis.R
# Tests for real survival analysis functions

# Helper: create mock clinical data with survival fields
mock_clinical_data <- function(n = 50) {
  set.seed(42)
  is_dead <- sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.4, 0.6))
  data.frame(
    submitter_id = paste0("MMRF_", sprintf("%04d", seq_len(n))),
    vital_status = ifelse(is_dead, "Dead", "Alive"),
    days_to_death = ifelse(is_dead, round(abs(rnorm(n, 800, 300))), NA_real_),
    days_to_last_follow_up = ifelse(!is_dead, round(abs(rnorm(n, 1200, 400))), NA_real_),
    age_at_diagnosis = round(rnorm(n, 65 * 365.25, 10 * 365.25)),
    gender = sample(c("male", "female"), n, replace = TRUE),
    iss_stage = sample(c("Stage I", "Stage II", "Stage III", NA), n,
                       replace = TRUE, prob = c(0.3, 0.3, 0.3, 0.1)),
    stringsAsFactors = FALSE
  )
}

test_that("prepare_survival_data creates valid survival data", {
  clin <- mock_clinical_data(50)
  result <- prepare_survival_data(clin)

  expect_s3_class(result, "data.frame")
  expect_true(all(c("patient_id", "time_days", "status") %in% names(result)))
  expect_true(all(result$time_days > 0))
  expect_true(all(result$status %in% c(0, 1)))
  expect_true(nrow(result) > 0 && nrow(result) <= 50)
})

test_that("prepare_survival_data rejects empty input", {
  expect_error(prepare_survival_data(NULL), "non-empty data frame")
  expect_error(prepare_survival_data(data.frame()), "non-empty data frame")
})

test_that("prepare_survival_data handles age conversion", {
  clin <- mock_clinical_data(20)
  result <- prepare_survival_data(clin)

  expect_true("age_years" %in% names(result))
  # Ages should be reasonable years, not days
  expect_true(all(result$age_years[!is.na(result$age_years)] > 10))
  expect_true(all(result$age_years[!is.na(result$age_years)] < 120))
})

test_that("prepare_survival_data merges cytogenetic data", {
  clin <- mock_clinical_data(20)
  # Create mock cytogenetic data as data frame (bypassing file)
  cyto <- data.frame(
    patient_id = clin$submitter_id,
    risk_group = sample(c("high", "standard"), 20, replace = TRUE),
    t_4_14 = sample(c("positive", "negative", NA), 20, replace = TRUE),
    t_14_16 = sample(c("positive", "negative", NA), 20, replace = TRUE),
    del_17p = sample(c("positive", "negative", NA), 20, replace = TRUE),
    gain_1q = sample(c("positive", "negative", NA), 20, replace = TRUE),
    stringsAsFactors = FALSE
  )
  result <- prepare_survival_data(clin, cyto_file = cyto)

  expect_true("risk_group" %in% names(result))
  expect_true("t_4_14" %in% names(result))
  expect_true("t_14_16" %in% names(result))
})

test_that("run_kaplan_meier fits overall curve", {
  skip_if_not_installed("survival")
  clin <- mock_clinical_data(50)
  surv_data <- prepare_survival_data(clin)

  result <- run_kaplan_meier(surv_data, strata = NULL)

  expect_type(result, "list")
  expect_s3_class(result$fit, "survfit")
  expect_true(is.na(result$logrank_p))
  expect_true("median_survival" %in% names(result))
})

test_that("run_kaplan_meier stratifies by group", {
  skip_if_not_installed("survival")
  clin <- mock_clinical_data(100)
  surv_data <- prepare_survival_data(clin)

  # Only run if we have ISS data
  if (sum(!is.na(surv_data$iss_stage)) >= 5) {
    result <- run_kaplan_meier(surv_data, strata = "iss_stage")

    expect_s3_class(result$fit, "survfit")
    expect_false(is.na(result$logrank_p))
    expect_true(result$logrank_p >= 0 && result$logrank_p <= 1)
    expect_equal(result$strata, "iss_stage")
  }
})

test_that("run_kaplan_meier rejects missing strata column", {
  skip_if_not_installed("survival")
  clin <- mock_clinical_data(20)
  surv_data <- prepare_survival_data(clin)

  expect_error(run_kaplan_meier(surv_data, strata = "nonexistent"),
               "not found")
})

test_that("run_cox_regression fits model with HR and CI", {
  skip_if_not_installed("survival")
  clin <- mock_clinical_data(100)
  surv_data <- prepare_survival_data(clin)

  result <- run_cox_regression(surv_data, covariates = c("age_years", "gender"))

  expect_type(result, "list")
  expect_s3_class(result$model, "coxph")
  expect_s3_class(result$hazard_ratios, "data.frame")
  expect_true(all(c("HR", "HR_lower", "HR_upper", "p_value") %in%
                    names(result$hazard_ratios)))
  expect_true(result$concordance > 0 && result$concordance < 1)
  expect_true(result$n > 0)
  expect_true(result$n_events > 0)
})

test_that("run_cox_regression includes PH test", {
  skip_if_not_installed("survival")
  clin <- mock_clinical_data(100)
  surv_data <- prepare_survival_data(clin)

  result <- run_cox_regression(surv_data, covariates = c("age_years"))

  expect_true("ph_test" %in% names(result))
  # ph_test may be NULL if model doesn't support it, but field should exist
})

test_that("run_cox_regression drops unavailable covariates gracefully", {
  skip_if_not_installed("survival")
  clin <- mock_clinical_data(50)
  surv_data <- prepare_survival_data(clin)

  result <- run_cox_regression(
    surv_data,
    covariates = c("age_years", "nonexistent_column")
  )

  expect_equal(result$covariates_used, "age_years")
})

test_that("run_cox_regression rejects all-unavailable covariates", {
  skip_if_not_installed("survival")
  clin <- mock_clinical_data(20)
  surv_data <- prepare_survival_data(clin)

  expect_error(
    run_cox_regression(surv_data, covariates = c("foo", "bar")),
    "None of the requested covariates"
  )
})
