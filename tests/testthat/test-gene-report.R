# tests/testthat/test-gene-report.R
# Tests for parameterized gene report rendering (#44)

test_that("gene_report errors without quarto", {
  skip_if(requireNamespace("quarto", quietly = TRUE),
    "quarto is installed — cannot test missing-package guard")

  expect_error(gene_report("TP53"), "quarto")
})

test_that("gene_report function exists and has expected signature", {
  expect_true(is.function(gene_report))
  args <- formals(gene_report)
  expect_true("gene" %in% names(args))
  expect_true("output_dir" %in% names(args))
  expect_true("vst_matrix" %in% names(args))
  expect_true("surv_data" %in% names(args))
  expect_true("cyto_data" %in% names(args))
})
