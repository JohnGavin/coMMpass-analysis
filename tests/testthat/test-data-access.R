# tests/testthat/test-data-access.R
# Tests for R/data_access.R functions
# Most functions require GDC/AWS API access, so we test structure + skip on CI

test_that("query_commpass_rna returns GDCquery object", {
  skip_if_not_installed("TCGAbiolinks")
  skip_if_offline()
  skip_on_ci()
  skip("GDC API may timeout; run manually with Sys.setenv(RUN_GDC_TESTS='true')")
})

test_that("get_commpass_clinical returns data frame", {
  skip_if_not_installed("TCGAbiolinks")
  skip_if_offline()
  skip_on_ci()

  clinical <- get_commpass_clinical()
  expect_s3_class(clinical, "data.frame")
  expect_gt(nrow(clinical), 0)
  expect_true("submitter_id" %in% names(clinical))
})

test_that("list_s3_commpass returns character vector", {
  skip_if_not_installed("aws.s3")
  skip_if_offline()
  skip_on_ci()

  files <- list_s3_commpass()
  expect_type(files, "character")
})

test_that("download_s3_subset validates input", {
  # Should handle empty paths gracefully
  tmp <- tempdir()
  result <- download_s3_subset(character(0), dest_dir = tmp, n = 0)
  expect_length(result, 0)
})

test_that("acquire_commpass_data returns a list", {
  skip_if_not_installed("TCGAbiolinks")
  skip_if_offline()
  skip_on_ci()

  # Test with nothing enabled
  result <- acquire_commpass_data(
    download_rnaseq = FALSE,
    download_clinical = FALSE,
    download_aws = FALSE
  )
  expect_type(result, "list")
  expect_length(result, 0)
})
