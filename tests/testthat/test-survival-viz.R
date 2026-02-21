# tests/testthat/test-survival-viz.R
# Tests for survival visualization functions

# Helper: create mock survival data
mock_surv_data <- function(n = 30) {
  set.seed(42)
  data.frame(
    patient_id = paste0("P", seq_len(n)),
    time_days = abs(rnorm(n, 1000, 500)),
    status = sample(0:1, n, replace = TRUE, prob = c(0.6, 0.4)),
    age_years = round(rnorm(n, 65, 10), 1),
    gender = sample(c("male", "female"), n, replace = TRUE),
    iss_stage = sample(c("I", "II", "III"), n, replace = TRUE),
    risk_group = sample(c("high", "standard"), n, replace = TRUE,
                         prob = c(0.3, 0.7)),
    t_4_14 = sample(c("positive", "negative"), n, replace = TRUE,
                     prob = c(0.15, 0.85)),
    t_11_14 = sample(c("positive", "negative"), n, replace = TRUE,
                      prob = c(0.2, 0.8)),
    t_14_16 = sample(c("positive", "negative"), n, replace = TRUE,
                      prob = c(0.05, 0.95)),
    del_17p = sample(c("positive", "negative"), n, replace = TRUE,
                      prob = c(0.1, 0.9)),
    gain_1q = sample(c("positive", "negative"), n, replace = TRUE,
                      prob = c(0.3, 0.7)),
    stringsAsFactors = FALSE
  )
}

# --- plot_km ---

test_that("plot_km creates ggplot for overall KM", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data()
  km <- run_kaplan_meier(surv, strata = NULL)
  p <- plot_km(km)
  expect_s3_class(p, "ggplot")
})

test_that("plot_km creates ggplot for stratified KM", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(50)
  km <- run_kaplan_meier(surv, strata = "risk_group")
  p <- plot_km(km, title = "KM by Risk Group")
  expect_s3_class(p, "ggplot")
})

test_that("plot_km handles NULL input", {
  p <- plot_km(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_km handles NULL fit", {
  p <- plot_km(list(fit = NULL, logrank_p = NA_real_))
  expect_s3_class(p, "ggplot")
})

test_that("plot_km accepts custom time_breaks", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data()
  km <- run_kaplan_meier(surv)
  p <- plot_km(km, time_breaks = seq(0, 2000, by = 365))
  expect_s3_class(p, "ggplot")
})

# --- plot_forest ---

test_that("plot_forest creates ggplot", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(50)
  cox <- run_cox_regression(surv, covariates = c("age_years", "gender"))
  p <- plot_forest(cox)
  expect_s3_class(p, "ggplot")
})

test_that("plot_forest handles NULL input", {
  p <- plot_forest(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_forest handles empty HR table", {
  p <- plot_forest(list(hazard_ratios = data.frame()))
  expect_s3_class(p, "ggplot")
})

# --- run_km_by_markers ---

test_that("run_km_by_markers returns named list", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(50)
  results <- run_km_by_markers(surv)
  expect_type(results, "list")
  expect_true(length(results) > 0)
})

test_that("run_km_by_markers skips rare markers", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(20)
  # Make t_14_16 have only 1 positive
  surv$t_14_16 <- c("positive", rep("negative", 19))
  results <- run_km_by_markers(surv, markers = c("t_14_16"))
  expect_true(!is.null(results$t_14_16$note))
})

test_that("run_km_by_markers handles NULL input", {
  results <- run_km_by_markers(NULL)
  expect_type(results, "list")
  expect_equal(length(results), 0)
})

test_that("run_km_by_markers handles empty data", {
  results <- run_km_by_markers(data.frame())
  expect_type(results, "list")
  expect_equal(length(results), 0)
})
