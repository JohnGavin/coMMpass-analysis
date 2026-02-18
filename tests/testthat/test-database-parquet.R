# tests/testthat/test-database-parquet.R
# Tests for R/database_parquet.R functions

test_that("resolve_parquet_path returns correct paths", {
  base <- "data/raw"
  expect_equal(
    resolve_parquet_path("clinical", base),
    file.path(base, "clinical", "clinical_data.parquet")
  )
  expect_equal(
    resolve_parquet_path("biospecimen", base),
    file.path(base, "clinical", "biospecimen_data.parquet")
  )
  expect_equal(
    resolve_parquet_path("rnaseq_counts", base),
    file.path(base, "gdc", "rnaseq_counts.parquet")
  )
})

test_that("resolve_parquet_path works with custom data_dir", {
  expect_equal(
    resolve_parquet_path("clinical", "/tmp/mydata"),
    "/tmp/mydata/clinical/clinical_data.parquet"
  )
})

test_that("query_commpass_parquet errors when parquet file missing", {
  expect_error(
    query_commpass_parquet("clinical", data_dir = tempdir()),
    "not found"
  )
})

test_that("query_commpass_parquet reads parquet file correctly", {
  # Create a temp parquet file
  tmp_dir <- file.path(tempdir(), "test_parquet")
  clinical_dir <- file.path(tmp_dir, "clinical")
  dir.create(clinical_dir, recursive = TRUE, showWarnings = FALSE)

  test_data <- data.frame(
    submitter_id = c("P1", "P2", "P3"),
    gender = c("male", "female", "male"),
    age_at_diagnosis = c(25000, 22000, 28000),
    stringsAsFactors = FALSE
  )
  arrow::write_parquet(test_data, file.path(clinical_dir, "clinical_data.parquet"))

  result <- query_commpass_parquet("clinical", data_dir = tmp_dir)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_true("submitter_id" %in% names(result))

  # Cleanup
  unlink(tmp_dir, recursive = TRUE)
})

test_that("query_commpass_parquet applies filters", {
  tmp_dir <- file.path(tempdir(), "test_parquet_filter")
  clinical_dir <- file.path(tmp_dir, "clinical")
  dir.create(clinical_dir, recursive = TRUE, showWarnings = FALSE)

  test_data <- data.frame(
    submitter_id = c("P1", "P2", "P3", "P4"),
    gender = c("male", "female", "male", "female"),
    vital_status = c("Alive", "Dead", "Alive", "Alive"),
    stringsAsFactors = FALSE
  )
  arrow::write_parquet(test_data, file.path(clinical_dir, "clinical_data.parquet"))

  result <- query_commpass_parquet(
    "clinical",
    data_dir = tmp_dir,
    filters = list(gender = "female")
  )
  expect_equal(nrow(result), 2)
  expect_true(all(result$gender == "female"))

  # Multiple filters
  result2 <- query_commpass_parquet(
    "clinical",
    data_dir = tmp_dir,
    filters = list(gender = "female", vital_status = "Alive")
  )
  expect_equal(nrow(result2), 1)

  unlink(tmp_dir, recursive = TRUE)
})

test_that("query_commpass_parquet validates data_type argument", {
  expect_error(
    query_commpass_parquet("invalid_type"),
    "arg"
  )
})

test_that("get_commpass_tbl errors when parquet file missing", {
  expect_error(
    get_commpass_tbl("clinical", data_dir = tempdir()),
    "not found"
  )
})

test_that("get_commpass_tbl returns lazy tbl with own connection", {

  tmp_dir <- file.path(tempdir(), "test_tbl")
  clinical_dir <- file.path(tmp_dir, "clinical")
  dir.create(clinical_dir, recursive = TRUE, showWarnings = FALSE)

  test_data <- data.frame(
    submitter_id = c("P1", "P2"),
    gender = c("male", "female"),
    stringsAsFactors = FALSE
  )
  arrow::write_parquet(test_data, file.path(clinical_dir, "clinical_data.parquet"))

  result <- get_commpass_tbl("clinical", data_dir = tmp_dir)
  expect_s3_class(result, "tbl")

  # Should have connection attribute
  con <- attr(result, "connection")
  expect_true(!is.null(con))

  # Can collect data
  collected <- dplyr::collect(result)
  expect_equal(nrow(collected), 2)

  # Clean up
  DBI::dbDisconnect(con, shutdown = TRUE)
  unlink(tmp_dir, recursive = TRUE)
})

test_that("get_commpass_tbl uses provided connection", {
  tmp_dir <- file.path(tempdir(), "test_tbl_con")
  clinical_dir <- file.path(tmp_dir, "clinical")
  dir.create(clinical_dir, recursive = TRUE, showWarnings = FALSE)

  test_data <- data.frame(
    submitter_id = c("P1", "P2"),
    gender = c("male", "female"),
    stringsAsFactors = FALSE
  )
  arrow::write_parquet(test_data, file.path(clinical_dir, "clinical_data.parquet"))

  con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
  result <- get_commpass_tbl("clinical", data_dir = tmp_dir, con = con)
  expect_s3_class(result, "tbl")

  # Should NOT have connection attribute when we provide our own
  expect_null(attr(result, "connection"))

  collected <- dplyr::collect(result)
  expect_equal(nrow(collected), 2)

  DBI::dbDisconnect(con, shutdown = TRUE)
  unlink(tmp_dir, recursive = TRUE)
})
