# tests/testthat/test-utils.R
# Tests for R/utils.R exported functions

test_that("format_file_size handles typical sizes", {
  expect_equal(format_file_size(0), "0 bytes")
  expect_equal(format_file_size(500), "500 bytes")
  expect_equal(format_file_size(1024), "1.0 KB")
  expect_equal(format_file_size(1048576), "1.0 MB")
  expect_equal(format_file_size(1073741824), "1.0 GB")
  expect_equal(format_file_size(1099511627776), "1.0 TB")
})

test_that("format_file_size handles vectorized input", {
  result <- format_file_size(c(1024, 1048576, 1073741824))
  expect_length(result, 3)
  expect_equal(result, c("1.0 KB", "1.0 MB", "1.0 GB"))
})

test_that("format_file_size handles NA values", {
  result <- format_file_size(c(1024, NA, 1048576))
  expect_length(result, 3)
  expect_true(is.na(result[2]))
  expect_equal(result[1], "1.0 KB")
  expect_equal(result[3], "1.0 MB")
})

test_that("format_file_size handles non-numeric input", {
  result <- format_file_size("not a number")
  expect_type(result, "character")
  expect_equal(result, "not a number")
})

test_that("format_file_size respects digits parameter", {
  expect_match(format_file_size(1536, digits = 2), "1\\.50 KB")
  expect_match(format_file_size(1536, digits = 0), "2 KB")
})

test_that("format_file_size handles edge cases", {

  # Very large value (1e15 is ~909 TB; need > 1024^5 for PB)
  result <- format_file_size(1e15)
  expect_match(result, "TB")

  # Actual PB value
  result_pb <- format_file_size(1024^5)
  expect_match(result_pb, "PB")

  # Single byte
  expect_match(format_file_size(1), "1 bytes")

  # Fractional bytes (unusual but should not error)
  expect_type(format_file_size(0.5), "character")
})

test_that("format_with_commas formats numbers correctly", {
  expect_equal(trimws(format_with_commas(1234567)), "1,234,567")
  expect_equal(trimws(format_with_commas(100)), "100")
  expect_equal(trimws(format_with_commas(0)), "0")
})

test_that("format_with_commas handles vectors", {
  result <- format_with_commas(c(1000, 2000000))
  expect_length(result, 2)
  expect_match(result[1], "1,000")
  expect_match(result[2], "2,000,000")
})

test_that("format_with_commas handles negative numbers", {
  result <- format_with_commas(-1234567)
  expect_match(result, "-1,234,567")
})

test_that("create_summary_table works with basic data frame", {
  df <- data.frame(
    x = c(1, 2, 3, 4, 5),
    y = c(10, 20, 30, 40, 50),
    label = c("a", "b", "c", "d", "e")
  )
  result <- create_summary_table(df)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)  # Only numeric columns: x, y
  expect_true("Variable" %in% names(result))
  expect_true("Mean" %in% names(result))
  expect_true("Median" %in% names(result))
})

test_that("create_summary_table filters to specified vars", {
  df <- data.frame(x = 1:5, y = 6:10, z = 11:15)
  result <- create_summary_table(df, vars = c("x", "z"))
  expect_equal(nrow(result), 2)
  expect_equal(result$Variable, c("x", "z"))
})

test_that("create_summary_table handles missing values", {
  df <- data.frame(x = c(1, 2, NA, 4, NA))
  result <- create_summary_table(df)
  expect_equal(result$N, 3)
  expect_equal(result$Missing, 2)
})

test_that("create_summary_table handles all-NA column", {
  df <- data.frame(x = rep(NA_real_, 5))
  # Should still produce a row but with N=0; min/max will warn
  result <- suppressWarnings(create_summary_table(df))
  expect_equal(nrow(result), 1)
  expect_equal(result$N, 0)
})

test_that("create_summary_table returns NULL-like for no numeric columns", {
  df <- data.frame(a = letters[1:5], b = LETTERS[1:5])
  result <- create_summary_table(df)
  expect_null(result)
})

test_that("create_summary_table ignores non-existent var names", {
  df <- data.frame(x = 1:5)
  result <- create_summary_table(df, vars = c("x", "nonexistent"))
  expect_equal(nrow(result), 1)
  expect_equal(result$Variable, "x")
})
