# tests/testthat/test-data-dictionary.R
# Tests for R/data_dictionary.R

test_that("get_commpass_data_dictionary returns a tibble", {
  dd <- get_commpass_data_dictionary()
  expect_s3_class(dd, "tbl_df")
  expect_gt(nrow(dd), 0)
})

test_that("get_commpass_data_dictionary has expected columns", {
  dd <- get_commpass_data_dictionary()
  expected_cols <- c("variable", "category", "data_type", "units",
                     "description", "typical_range", "gdc_link")
  expect_true(all(expected_cols %in% names(dd)))
})

test_that("get_commpass_data_dictionary covers all categories", {
  dd <- get_commpass_data_dictionary()
  categories <- unique(dd$category)
  expect_true("clinical" %in% categories)
  expect_true("biospecimen" %in% categories)
  expect_true("rnaseq_counts" %in% categories)
  expect_true("rnaseq_metadata" %in% categories)
})

test_that("get_commpass_data_dictionary has no empty descriptions", {
  dd <- get_commpass_data_dictionary()
  expect_true(all(!is.na(dd$description)))
  expect_true(all(nchar(dd$description) > 0))
})

test_that("get_commpass_data_dictionary has no duplicate variables within category", {
  dd <- get_commpass_data_dictionary()
  dupes <- dd |>
    dplyr::group_by(category, variable) |>
    dplyr::filter(dplyr::n() > 1)
  expect_equal(nrow(dupes), 0)
})

test_that("get_variable_docs returns expected structure for known variable", {
  docs <- get_variable_docs("age_at_diagnosis")
  expect_type(docs, "list")
  expect_equal(docs$variable, "age_at_diagnosis")
  expect_true(nchar(docs$description) > 0)
  expect_true(nchar(docs$scientific_context) > 0)
  expect_true(nchar(docs$calculation) > 0)
  expect_true(nchar(docs$usage_notes) > 0)
  expect_true(length(docs$references) > 0)
})

test_that("get_variable_docs returns structure for days_to_death", {
  docs <- get_variable_docs("days_to_death")
  expect_equal(docs$variable, "days_to_death")
  expect_type(docs$references, "character")
})

test_that("get_variable_docs returns structure for unstranded", {
  docs <- get_variable_docs("unstranded")
  expect_equal(docs$variable, "unstranded")
})

test_that("get_variable_docs falls back to dictionary for unknown variable", {
  # "gender" is in the dictionary but has no detailed docs entry
  docs <- get_variable_docs("gender")
  expect_equal(docs$variable, "gender")
  expect_true(nchar(docs$description) > 0)
})

test_that("get_variable_docs errors for completely unknown variable", {
  expect_error(
    get_variable_docs("totally_nonexistent_variable_xyz"),
    "not found"
  )
})
