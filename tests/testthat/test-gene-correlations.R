# tests/testthat/test-gene-correlations.R
# Tests for gene-gene correlation analysis

# Helper: create mock expression matrix
mock_expr_matrix <- function(n_genes = 20, n_samples = 30) {
  set.seed(42)
  mat <- matrix(rnorm(n_genes * n_samples, mean = 10, sd = 2),
                nrow = n_genes, ncol = n_samples)
  rownames(mat) <- paste0("GENE", seq_len(n_genes))
  colnames(mat) <- paste0("MMRF_", seq_len(n_samples))
  # Make GENE1 and GENE2 correlated

  mat["GENE2", ] <- mat["GENE1", ] * 0.8 + rnorm(n_samples, sd = 1)
  mat
}

# --- correlate_genes ---

test_that("correlate_genes computes pearson correlation", {
  mat <- mock_expr_matrix()
  res <- correlate_genes(mat, "GENE1", "GENE2", method = "pearson")
  expect_type(res, "list")
  expect_equal(res$gene_x, "GENE1")
  expect_equal(res$gene_y, "GENE2")
  expect_equal(res$method, "pearson")
  expect_true(abs(res$estimate) > 0.3)
  expect_true(res$p_value < 0.05)
  expect_equal(res$n_samples, 30)
})

test_that("correlate_genes computes spearman correlation", {
  mat <- mock_expr_matrix()
  res <- correlate_genes(mat, "GENE1", "GENE2", method = "spearman")
  expect_equal(res$method, "spearman")
  expect_true(!is.na(res$estimate))
})

test_that("correlate_genes errors on missing gene", {
  mat <- mock_expr_matrix()
  expect_error(correlate_genes(mat, "MISSING", "GENE2"), "not found")
})

test_that("correlate_genes errors on NULL matrix", {
  expect_error(correlate_genes(NULL, "A", "B"), "must be a numeric matrix")
})

# --- correlate_genes_batch ---

test_that("correlate_genes_batch returns sorted data frame", {
  mat <- mock_expr_matrix()
  res <- correlate_genes_batch(mat, "GENE1",
                                candidate_genes = paste0("GENE", 2:5))
  expect_s3_class(res, "data.frame")
  expect_true("padj" %in% names(res))
  expect_equal(nrow(res), 4)
  # Sorted by absolute correlation
  expect_true(abs(res$estimate[1]) >= abs(res$estimate[nrow(res)]))
})

test_that("correlate_genes_batch handles no matching candidates", {
  mat <- mock_expr_matrix()
  res <- correlate_genes_batch(mat, "GENE1", c("MISSING1", "MISSING2"))
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 0)
})

# --- plot_gene_correlation ---

test_that("plot_gene_correlation creates ggplot", {
  skip_if_not_installed("ggplot2")
  mat <- mock_expr_matrix()
  cor_res <- correlate_genes(mat, "GENE1", "GENE2")
  p <- plot_gene_correlation(cor_res)
  expect_s3_class(p, "ggplot")
})

test_that("plot_gene_correlation handles NULL input", {
  skip_if_not_installed("ggplot2")
  p <- plot_gene_correlation(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_gene_correlation accepts custom title", {
  skip_if_not_installed("ggplot2")
  mat <- mock_expr_matrix()
  cor_res <- correlate_genes(mat, "GENE1", "GENE3")
  p <- plot_gene_correlation(cor_res, title = "Custom Title")
  expect_s3_class(p, "ggplot")
})
