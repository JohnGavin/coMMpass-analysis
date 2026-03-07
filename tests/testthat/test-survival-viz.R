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

# --- run_km_by_expression ---

# Helper: create mock expression matrix matching survival data
mock_expr_matrix <- function(patient_ids, n_genes = 50) {
  set.seed(42)
  mat <- matrix(rnorm(n_genes * length(patient_ids), mean = 10, sd = 2),
                nrow = n_genes, ncol = length(patient_ids))
  rownames(mat) <- paste0("GENE", seq_len(n_genes))
  colnames(mat) <- patient_ids
  mat
}

test_that("run_km_by_expression median split returns KM result", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(40)
  mat <- mock_expr_matrix(surv$patient_id)
  result <- run_km_by_expression(surv, mat, "GENE1", split = "median")
  expect_type(result, "list")
  expect_false(is.null(result$fit))
  expect_equal(result$gene, "GENE1")
  expect_equal(result$split_method, "median")
})

test_that("run_km_by_expression top_bottom_20 works", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(50)
  mat <- mock_expr_matrix(surv$patient_id)
  result <- run_km_by_expression(surv, mat, "GENE1", split = "top_bottom_20")
  expect_type(result, "list")
  expect_equal(result$split_method, "top_bottom_20")
})

test_that("run_km_by_expression tertile split works", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(60)
  mat <- mock_expr_matrix(surv$patient_id)
  result <- run_km_by_expression(surv, mat, "GENE1", split = "tertile")
  expect_type(result, "list")
  expect_equal(result$split_method, "tertile")
})

test_that("run_km_by_expression quartile split works", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(60)
  mat <- mock_expr_matrix(surv$patient_id)
  result <- run_km_by_expression(surv, mat, "GENE1", split = "quartile")
  expect_type(result, "list")
  expect_equal(result$split_method, "quartile")
})

test_that("run_km_by_expression handles missing gene", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data()
  mat <- mock_expr_matrix(surv$patient_id)
  result <- run_km_by_expression(surv, mat, "MISSING_GENE")
  expect_true(is.null(result$fit))
  expect_true(!is.null(result$note))
})

test_that("run_km_by_expression handles NULL input", {
  result <- run_km_by_expression(NULL, NULL, "GENE1")
  expect_true(is.null(result$fit))
})

test_that("run_km_by_expression handles no matching patients", {
  skip_if_not_installed("survival")
  surv <- mock_surv_data(10)
  mat <- mock_expr_matrix(paste0("OTHER_", 1:10))
  result <- run_km_by_expression(surv, mat, "GENE1")
  expect_true(is.null(result$fit))
})
