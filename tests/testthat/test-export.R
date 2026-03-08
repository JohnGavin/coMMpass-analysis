# tests/testthat/test-export.R
# Tests for H5AD export functionality (#26)

test_that("export_h5ad errors without anndataR", {
  skip_if(requireNamespace("anndataR", quietly = TRUE),
    "anndataR is installed — cannot test missing-package guard")

  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  expect_error(
    export_h5ad(d$rnaseq_se, tempfile(fileext = ".h5ad")),
    "anndataR"
  )
})

test_that("export_h5ad errors on NULL input", {
  expect_error(export_h5ad(NULL, tempfile()), "SummarizedExperiment")
})

test_that("export_h5ad errors on non-SE input", {
  expect_error(export_h5ad(data.frame(x = 1), tempfile()), "SummarizedExperiment")
})

test_that("export_h5ad errors on missing assay", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")
  skip_if_not_installed("SingleCellExperiment")
  skip_if_not_installed("anndataR")

  d <- example_data()
  expect_error(
    export_h5ad(d$rnaseq_se, tempfile(), assay_name = "nonexistent"),
    "not found"
  )
})

test_that("export_h5ad writes file successfully", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")
  skip_if_not_installed("SingleCellExperiment")
  skip_if_not_installed("anndataR")

  d <- example_data()
  outfile <- tempfile(fileext = ".h5ad")
  result <- export_h5ad(d$rnaseq_se, outfile)

  expect_equal(result, outfile)
  expect_true(file.exists(outfile))
  expect_gt(file.size(outfile), 0)

  unlink(outfile)
})
