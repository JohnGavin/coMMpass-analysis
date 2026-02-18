# tests/testthat/test-adversarial.R
# Adversarial QA: edge cases, type attacks, and boundary conditions
# for all exported functions

# --- format_file_size adversarial ---

test_that("format_file_size: negative values return string without warning", {
  expect_no_warning(result <- format_file_size(-1024))
  expect_type(result, "character")
  expect_equal(result, "-1024")
})

test_that("format_file_size: Inf and -Inf handled without warning", {
  expect_no_warning(result <- format_file_size(Inf))
  expect_type(result, "character")
  expect_no_warning(result2 <- format_file_size(-Inf))
  expect_type(result2, "character")
})

test_that("format_file_size: NaN handled", {
  expect_no_warning(result <- format_file_size(NaN))
  expect_type(result, "character")
})

test_that("format_file_size: empty vector returns empty", {
  result <- format_file_size(numeric(0))
  expect_length(result, 0)
})

test_that("format_file_size: very large digits parameter", {
  result <- format_file_size(1536, digits = 20)
  expect_type(result, "character")
})

# --- format_with_commas adversarial ---

test_that("format_with_commas: NA handled", {
  result <- format_with_commas(NA_real_)
  expect_type(result, "character")
})

test_that("format_with_commas: Inf handled", {
  result <- format_with_commas(Inf)
  expect_type(result, "character")
})

test_that("format_with_commas: empty vector", {
  result <- format_with_commas(numeric(0))
  expect_length(result, 0)
})

# --- create_summary_table adversarial ---

test_that("create_summary_table: single-row data frame", {
  df <- data.frame(x = 42)
  result <- create_summary_table(df)
  expect_equal(nrow(result), 1)
  expect_equal(result$Mean, 42)
})

test_that("create_summary_table: all-same values", {
  df <- data.frame(x = rep(5, 100))
  result <- create_summary_table(df)
  expect_equal(result$SD, 0)
  expect_equal(result$Min, result$Max)
})

test_that("create_summary_table: extreme values", {
  df <- data.frame(x = c(.Machine$double.xmin, .Machine$double.xmax))
  result <- create_summary_table(df)
  expect_equal(nrow(result), 1)
})

# --- get_commpass_data_dictionary adversarial ---

test_that("data dictionary: repeated calls return identical results", {
  dd1 <- get_commpass_data_dictionary()
  dd2 <- get_commpass_data_dictionary()
  expect_identical(dd1, dd2)
})

test_that("data dictionary: all GDC links are valid URLs", {
  dd <- get_commpass_data_dictionary()
  links <- dd$gdc_link[!is.na(dd$gdc_link)]
  expect_true(all(grepl("^https://", links)))
})

# --- get_variable_docs adversarial ---

test_that("get_variable_docs: empty string errors", {
  expect_error(get_variable_docs(""))
})

test_that("get_variable_docs: SQL injection attempt doesn't crash", {
  expect_error(
    get_variable_docs("'; DROP TABLE --"),
    "not found"
  )
})

test_that("get_variable_docs: very long variable name", {
  expect_error(
    get_variable_docs(paste0(rep("x", 1000), collapse = "")),
    "not found"
  )
})

# --- clean_clinical_data adversarial ---

test_that("clean_clinical_data: data frame with only NA columns", {
  df <- data.frame(
    submitter_id = NA_character_,
    gender = NA_character_,
    age_at_diagnosis = NA_real_
  )
  result <- clean_clinical_data(df)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)
  # percent_missing reflects added columns (age_years, n_missing, percent_missing)
  # so won't be 100% - just verify it's high

  expect_gt(result$percent_missing, 50)
})

test_that("clean_clinical_data: special characters in column names", {
  df <- data.frame(a = 1, b = 2, check.names = FALSE)
  names(df) <- c("Column.Name", "Another.Col")
  result <- clean_clinical_data(df)
  # Dots should be replaced with underscores, names lowercased
  expect_true(all(!grepl("\\.", names(result)[!names(result) %in% c("n_missing", "percent_missing")])))
  expect_true(all(names(result) == tolower(names(result))))
})

test_that("clean_clinical_data: age_at_diagnosis with zeros", {
  df <- data.frame(submitter_id = "P1", age_at_diagnosis = 0)
  result <- clean_clinical_data(df)
  expect_equal(result$age_at_diagnosis_years, 0)
})

# --- clean_expression_data adversarial ---

test_that("clean_expression_data: single gene, single sample", {
  mat <- matrix(100, nrow = 1, ncol = 1,
                dimnames = list("gene1", "sample1"))
  result <- clean_expression_data(mat)
  expect_true(is.matrix(result))
})

test_that("clean_expression_data: all zeros should return empty matrix", {
  mat <- matrix(0, nrow = 5, ncol = 3,
                dimnames = list(paste0("g", 1:5), paste0("s", 1:3)))
  result <- clean_expression_data(mat)
  expect_equal(nrow(result), 0)
})

# --- integrate_clinical_expression adversarial ---

test_that("integrate: both NULL", {
  result <- integrate_clinical_expression(NULL, NULL)
  expect_equal(length(result$matched_samples), 0)
})

test_that("integrate: empty clinical, valid expression", {
  clinical <- data.frame(submitter_id = character(0))
  expr <- matrix(1:4, nrow = 2, ncol = 2,
                 dimnames = list(c("g1", "g2"), c("S1", "S2")))
  result <- suppressWarnings(integrate_clinical_expression(clinical, expr))
  expect_equal(length(result$matched_samples), 0)
})

# --- query_commpass_parquet adversarial ---

test_that("query_commpass_parquet: empty parquet file", {
  tmp_dir <- file.path(tempdir(), "test_empty_pq")
  clinical_dir <- file.path(tmp_dir, "clinical")
  dir.create(clinical_dir, recursive = TRUE, showWarnings = FALSE)

  empty_df <- data.frame(
    submitter_id = character(0),
    gender = character(0),
    stringsAsFactors = FALSE
  )
  arrow::write_parquet(empty_df, file.path(clinical_dir, "clinical_data.parquet"))

  result <- query_commpass_parquet("clinical", data_dir = tmp_dir)
  expect_equal(nrow(result), 0)

  unlink(tmp_dir, recursive = TRUE)
})

test_that("query_commpass_parquet: filter on nonexistent column errors gracefully", {
  tmp_dir <- file.path(tempdir(), "test_bad_filter")
  clinical_dir <- file.path(tmp_dir, "clinical")
  dir.create(clinical_dir, recursive = TRUE, showWarnings = FALSE)

  test_data <- data.frame(
    submitter_id = c("P1", "P2"),
    gender = c("male", "female"),
    stringsAsFactors = FALSE
  )
  arrow::write_parquet(test_data, file.path(clinical_dir, "clinical_data.parquet"))

  # Filtering on a column that doesn't exist should error
  expect_error(
    query_commpass_parquet(
      "clinical",
      data_dir = tmp_dir,
      filters = list(nonexistent_col = "value")
    )
  )

  unlink(tmp_dir, recursive = TRUE)
})

test_that("query_commpass_parquet: empty filters list behaves like no filter", {
  tmp_dir <- file.path(tempdir(), "test_empty_filters")
  clinical_dir <- file.path(tmp_dir, "clinical")
  dir.create(clinical_dir, recursive = TRUE, showWarnings = FALSE)

  test_data <- data.frame(
    submitter_id = c("P1", "P2"),
    stringsAsFactors = FALSE
  )
  arrow::write_parquet(test_data, file.path(clinical_dir, "clinical_data.parquet"))

  result <- query_commpass_parquet("clinical", data_dir = tmp_dir, filters = list())
  expect_equal(nrow(result), 2)

  unlink(tmp_dir, recursive = TRUE)
})
