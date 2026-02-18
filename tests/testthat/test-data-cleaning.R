# tests/testthat/test-data-cleaning.R
# Tests for R/tar_plans/plan_data_cleaning.R exported functions

test_that("clean_clinical_data handles NULL input", {
  expect_null(clean_clinical_data(NULL))
})

test_that("clean_clinical_data handles empty data frame", {
  result <- clean_clinical_data(data.frame())
  expect_equal(nrow(result), 0)
})

test_that("clean_clinical_data converts age from days to years", {
  df <- data.frame(
    submitter_id = "MMRF_0001",
    age_at_diagnosis = 25000  # ~68.4 years
  )
  result <- clean_clinical_data(df)
  expect_true("age_at_diagnosis_years" %in% names(result))
  expect_equal(result$age_at_diagnosis_years, round(25000 / 365.25, 1))
})

test_that("clean_clinical_data standardizes gender values", {
  df <- data.frame(
    submitter_id = c("P1", "P2", "P3"),
    gender = c("Male", "FEMALE", "not reported")
  )
  result <- clean_clinical_data(df)
  expect_true(all(result$gender %in% c("male", "female", "not reported")))
})

test_that("clean_clinical_data lowercases vital_status", {
  df <- data.frame(
    submitter_id = "P1",
    vital_status = "Alive"
  )
  result <- clean_clinical_data(df)
  expect_equal(result$vital_status, "alive")
})

test_that("clean_clinical_data adds missing data quality flags", {
  df <- data.frame(
    submitter_id = "P1",
    age_at_diagnosis = NA_real_,
    gender = "male"
  )
  result <- clean_clinical_data(df)
  expect_true("n_missing" %in% names(result))
  expect_true("percent_missing" %in% names(result))
  expect_gt(result$n_missing, 0)
})

test_that("clean_clinical_data handles duplicate column names", {
  df <- data.frame(a = 1, b = 2, check.names = FALSE)
  names(df) <- c("col", "col")
  result <- clean_clinical_data(df)
  expect_true(length(unique(names(result))) == length(names(result)))
})

test_that("clean_clinical_data reorders columns with key vars first", {
  df <- data.frame(
    extra_col = 1,
    gender = "male",
    submitter_id = "P1"
  )
  result <- clean_clinical_data(df)
  expect_equal(names(result)[1], "submitter_id")
})

test_that("clean_expression_data handles NULL input", {
  expect_null(clean_expression_data(NULL))
})

test_that("clean_expression_data removes zero-expression genes", {
  mat <- matrix(c(0, 0, 0, 1, 2, 3), nrow = 2, byrow = TRUE)
  rownames(mat) <- c("gene_zero", "gene_expressed")
  colnames(mat) <- c("s1", "s2", "s3")
  result <- clean_expression_data(mat)
  expect_equal(nrow(result), 1)
})

test_that("clean_expression_data removes low-count samples", {
  # Create matrix where one sample has < 10000 total counts
  mat <- matrix(100, nrow = 100, ncol = 3)
  mat[, 3] <- 1  # Third sample has only 100 total counts
  colnames(mat) <- c("s1", "s2", "s3")
  rownames(mat) <- paste0("gene", seq_len(100))
  result <- clean_expression_data(mat)
  expect_lt(ncol(result), 3)
})

test_that("clean_expression_data sets attributes", {
  mat <- matrix(100, nrow = 50, ncol = 3)
  colnames(mat) <- c("s1", "s2", "s3")
  rownames(mat) <- paste0("gene", 1:50)
  result <- clean_expression_data(mat)
  expect_equal(attr(result, "n_genes"), nrow(result))
  expect_equal(attr(result, "n_samples"), ncol(result))
  expect_type(attr(result, "percent_zeros"), "double")
})

test_that("clean_expression_data converts data frame to matrix", {
  df <- data.frame(s1 = c(100, 200), s2 = c(300, 400))
  rownames(df) <- c("gene1", "gene2")
  result <- clean_expression_data(df)
  expect_true(is.matrix(result))
})

test_that("integrate_clinical_expression handles NULL inputs", {
  result <- integrate_clinical_expression(NULL, NULL)
  expect_type(result, "list")
  expect_equal(length(result$matched_samples), 0)
})

test_that("integrate_clinical_expression handles no matching IDs", {
  clinical <- data.frame(submitter_id = c("A", "B"))
  expr <- matrix(1:6, nrow = 2, ncol = 3)
  colnames(expr) <- c("X", "Y", "Z")
  result <- suppressWarnings(integrate_clinical_expression(clinical, expr))
  expect_equal(length(result$matched_samples), 0)
})

test_that("integrate_clinical_expression matches correctly", {
  clinical <- data.frame(
    submitter_id = c("S1", "S2", "S3"),
    age = c(60, 70, 80)
  )
  expr <- matrix(1:6, nrow = 2, ncol = 3)
  colnames(expr) <- c("S2", "S1", "S4")
  rownames(expr) <- c("gene1", "gene2")
  result <- integrate_clinical_expression(clinical, expr)
  expect_equal(sort(result$matched_samples), c("S1", "S2"))
  expect_equal(result$n_matched, 2)
  expect_equal(result$n_clinical_only, 1)  # S3
  expect_equal(result$n_expression_only, 1)  # S4
})
