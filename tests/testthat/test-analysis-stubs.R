# tests/testthat/test-analysis-stubs.R
# Tests for analysis functions

# Survival analysis tests in test-survival-analysis.R
# Pathway analysis tests in test-pathway-analysis.R

test_that("calculate_qc_metrics works with mock SE", {
  skip_if_not_installed("SummarizedExperiment")

  counts <- matrix(
    rpois(300, lambda = 100),
    nrow = 30, ncol = 10,
    dimnames = list(paste0("gene", 1:30), paste0("sample", 1:10))
  )
  se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(counts = counts)
  )

  result <- calculate_qc_metrics(se)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 10)
  expect_true(all(c("sample", "total_counts", "detected_genes",
                     "size_factor", "is_outlier") %in% names(result)))
})
