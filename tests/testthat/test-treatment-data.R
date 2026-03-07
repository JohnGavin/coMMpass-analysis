# tests/testthat/test-treatment-data.R
# Tests for treatment data cleaning functions (#64)

# --- Helper: create mock raw treatment data ---
mock_treatment_raw <- function(n = 5) {
  data.frame(
    public_id = rep(sprintf("MMRF_%04d", seq_len(n)), each = 2),
    line = rep(1:2, n),
    trtshnm = sample(c("VRd", "Rd", "Kd"), 2 * n, replace = TRUE),
    bestrespassess = sample(
      c("CR", "VGPR", "PR", "SD", "PD"), 2 * n, replace = TRUE
    ),
    sct_flag = sample(c("Yes", "No"), 2 * n, replace = TRUE),
    trtstdy = rep(c(0L, 180L), n),
    stringsAsFactors = FALSE
  )
}


# --- clean_treatment_data() ---

test_that("clean_treatment_data returns expected columns", {
  raw <- mock_treatment_raw()
  result <- clean_treatment_data(raw)

  expected_cols <- c(
    "patient_id", "treatment_line", "regimen_name", "regimen_class",
    "best_response", "stem_cell_transplant", "treatment_start_days"
  )
  for (col in expected_cols) {
    expect_true(col %in% names(result), info = paste("Missing column:", col))
  }
})

test_that("clean_treatment_data handles NULL input", {
  result <- clean_treatment_data(NULL)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("clean_treatment_data handles empty data frame", {
  empty <- data.frame(
    public_id = character(), line = integer(),
    trtshnm = character(), bestrespassess = character(),
    stringsAsFactors = FALSE
  )
  result <- clean_treatment_data(empty)
  expect_equal(nrow(result), 0)
})

test_that("clean_treatment_data maps patient ID columns", {
  raw <- mock_treatment_raw(3)
  result <- clean_treatment_data(raw)
  expect_equal(nrow(result), 6)
  expect_true(all(!is.na(result$patient_id)))
})

test_that("best_response is ordered factor", {
  raw <- mock_treatment_raw(3)
  result <- clean_treatment_data(raw)
  expect_s3_class(result$best_response, "factor")
  expect_true(is.ordered(result$best_response))
  expect_equal(levels(result$best_response),
    c("sCR", "CR", "VGPR", "PR", "MR", "SD", "PD"))
})

test_that("stem_cell_transplant is logical", {
  raw <- mock_treatment_raw(3)
  result <- clean_treatment_data(raw)
  expect_type(result$stem_cell_transplant, "logical")
})

test_that("treatment_start_days is integer", {
  raw <- mock_treatment_raw(3)
  result <- clean_treatment_data(raw)
  expect_type(result$treatment_start_days, "integer")
})

test_that("clean_treatment_data errors on missing ID column", {
  bad <- data.frame(x = 1:3, y = 4:6)
  expect_error(clean_treatment_data(bad), "No patient ID column")
})


# --- standardize_regimen() ---

test_that("standardize_regimen maps verbose names", {
  input <- c(
    "BORTEZOMIB + LENALIDOMIDE + DEXAMETHASONE",
    "LENALIDOMIDE + DEXAMETHASONE",
    "BORTEZOMIB + DEXAMETHASONE"
  )
  result <- standardize_regimen(input)
  expect_equal(result, c("VRd", "Rd", "Vd"))
})

test_that("standardize_regimen handles NULL", {
  expect_equal(standardize_regimen(NULL), NA_character_)
})

test_that("standardize_regimen normalizes abbreviated input", {
  expect_equal(standardize_regimen("VRD"), "VRd")
  expect_equal(standardize_regimen("rd"), "Rd")
  expect_equal(standardize_regimen("KRD"), "KRd")
})


# --- classify_regimen() ---

test_that("classify_regimen assigns expected classes", {
  regimens <- c("VRd", "Rd", "DaraVd", "Mel", "Xyz")
  result <- classify_regimen(regimens)
  expect_equal(result[5], "Other")
  expect_true(result[3] == "mAb-based")
  expect_true(result[4] == "Alkylator-based")
})


# --- standardize_response() ---

test_that("standardize_response maps full names", {
  input <- c("Complete Response", "Partial Response", "Progressive Disease")
  result <- standardize_response(input)
  expect_equal(as.character(result), c("CR", "PR", "PD"))
  expect_true(is.ordered(result))
})

test_that("standardize_response handles NULL", {
  result <- standardize_response(NULL)
  expect_s3_class(result, "factor")
  expect_true(is.ordered(result))
})


# --- summarize_treatment() ---

test_that("summarize_treatment creates one row per patient", {
  raw <- mock_treatment_raw(5)
  cleaned <- clean_treatment_data(raw)
  summary <- summarize_treatment(cleaned)

  expect_s3_class(summary, "data.frame")
  expect_equal(nrow(summary), 5)
  expect_true("n_lines" %in% names(summary))
  expect_true("first_regimen" %in% names(summary))
  expect_true("had_transplant" %in% names(summary))
})

test_that("summarize_treatment handles NULL input", {
  result <- summarize_treatment(NULL)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
})

test_that("summarize_treatment handles empty data frame", {
  empty <- data.frame(
    patient_id = character(), treatment_line = integer(),
    regimen_name = character(), regimen_class = character(),
    best_response = character(), stem_cell_transplant = logical(),
    treatment_start_days = integer(), stringsAsFactors = FALSE
  )
  result <- summarize_treatment(empty)
  expect_equal(nrow(result), 0)
})


# --- Integration with example_data() ---

test_that("example_data() includes treatment data", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  expect_true("treatment" %in% names(d))
  expect_s3_class(d$treatment, "data.frame")
  expect_true(nrow(d$treatment) > 0)

  # All expected columns present
  expected_cols <- c(
    "patient_id", "treatment_line", "regimen_name", "regimen_class",
    "best_response", "stem_cell_transplant", "treatment_start_days"
  )
  for (col in expected_cols) {
    expect_true(col %in% names(d$treatment), info = paste("Missing:", col))
  }
})
