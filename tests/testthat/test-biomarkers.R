# tests/testthat/test-biomarkers.R
# Tests for biomarker columns in clinical data (#63)

test_that("example clinical data has biomarker columns", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  clin <- d$clinical

  biomarker_cols <- c(
    "b2m", "albumin", "flc_kappa", "flc_lambda",
    "hemoglobin", "creatinine", "calcium", "platelets"
  )
  for (col in biomarker_cols) {
    expect_true(col %in% names(clin), info = paste("Missing column:", col))
  }
})

test_that("biomarker values are in plausible ranges", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  clin <- d$clinical

  # B2M: 0.5-50 mg/L
  expect_true(all(clin$b2m >= 0.5 & clin$b2m <= 50, na.rm = TRUE))
  # Albumin: 1-6 g/dL
  expect_true(all(clin$albumin >= 1 & clin$albumin <= 6, na.rm = TRUE))
  # Hemoglobin: 2-25 g/dL
  expect_true(all(clin$hemoglobin >= 2 & clin$hemoglobin <= 25, na.rm = TRUE))
  # Platelets: 0-1500
  expect_true(all(clin$platelets >= 0 & clin$platelets <= 1500, na.rm = TRUE))
})

test_that("clean_clinical_data derives FLC ratio", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  cleaned <- clean_clinical_data(d$clinical)

  expect_true("flc_ratio" %in% names(cleaned))
  # FLC ratio should be kappa/lambda
  expected <- round(d$clinical$flc_kappa / d$clinical$flc_lambda, 2)
  actual <- cleaned$flc_ratio
  # Allow for rounding and NA differences
  non_na <- !is.na(expected) & !is.na(actual)
  expect_equal(actual[non_na], expected[non_na])
})

test_that("clean_clinical_data validates biomarker ranges", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  # Create data with out-of-range values
  bad_clin <- data.frame(
    submitter_id = "MMRF_0001",
    b2m = 999,           # way too high
    albumin = 0.1,       # below minimum
    hemoglobin = 11,     # normal
    stringsAsFactors = FALSE
  )
  result <- clean_clinical_data(bad_clin)

  # Out-of-range should be NA

  expect_true(is.na(result$b2m))
  expect_true(is.na(result$albumin))
  # In-range should be preserved
  expect_equal(result$hemoglobin, 11)
})

test_that("clean_clinical_data maps GDC aliases", {
  gdc_data <- data.frame(
    submitter_id = "MMRF_0001",
    serum_beta_2_microglobulin = 3.5,
    serum_albumin = 4.0,
    stringsAsFactors = FALSE
  )
  result <- clean_clinical_data(gdc_data)

  expect_true("b2m" %in% names(result))
  expect_true("albumin" %in% names(result))
  expect_equal(result$b2m, 3.5)
  expect_equal(result$albumin, 4.0)
})
