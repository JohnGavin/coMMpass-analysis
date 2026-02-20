# tests/testthat/test-de-visualization.R
# Tests for DE visualization functions

# --- Column helpers ---

test_that("find_padj_col detects DESeq2, edgeR, limma columns", {
  expect_equal(find_padj_col(data.frame(padj = 1)), "padj")
  expect_equal(find_padj_col(data.frame(FDR = 1)), "FDR")
  expect_equal(find_padj_col(data.frame(adj.P.Val = 1)), "adj.P.Val")
  expect_null(find_padj_col(data.frame(x = 1)))
})

test_that("find_lfc_col detects DESeq2, edgeR, limma columns", {
  expect_equal(find_lfc_col(data.frame(log2FoldChange = 1)), "log2FoldChange")
  expect_equal(find_lfc_col(data.frame(logFC = 1)), "logFC")
  expect_null(find_lfc_col(data.frame(x = 1)))
})

test_that("find_expr_col detects expression columns", {
  expect_equal(find_expr_col(data.frame(baseMean = 1)), "baseMean")
  expect_equal(find_expr_col(data.frame(AveExpr = 1)), "AveExpr")
  expect_equal(find_expr_col(data.frame(logCPM = 1)), "logCPM")
  expect_null(find_expr_col(data.frame(x = 1)))
})

# --- compute_pca ---

test_that("compute_pca returns correct structure", {
  set.seed(42)
  mat <- matrix(rnorm(500), nrow = 50, ncol = 10,
                dimnames = list(paste0("gene", 1:50), paste0("S", 1:10)))

  result <- compute_pca(mat, n_top = 30)

  expect_type(result, "list")
  expect_true("coords" %in% names(result))
  expect_true("var_explained" %in% names(result))
  expect_true("n_genes_used" %in% names(result))
  expect_equal(nrow(result$coords), 10)
  expect_true("PC1" %in% names(result$coords))
  expect_true("PC2" %in% names(result$coords))
  expect_equal(result$n_genes_used, 30)
  expect_true(sum(result$var_explained) > 0.99)
})

test_that("compute_pca handles NULL/small input", {
  result <- compute_pca(NULL)
  expect_equal(nrow(result$coords), 0)
  expect_equal(result$n_genes_used, 0L)

  # Single sample
  mat <- matrix(1:10, nrow = 10, ncol = 1)
  result <- compute_pca(mat)
  expect_equal(nrow(result$coords), 0)
})

test_that("compute_pca merges metadata", {
  set.seed(42)
  mat <- matrix(rnorm(200), nrow = 20, ncol = 10,
                dimnames = list(paste0("g", 1:20), paste0("S", 1:10)))
  meta <- data.frame(sample = paste0("S", 1:10), group = rep(c("A", "B"), 5))

  result <- compute_pca(mat, n_top = 20, metadata = meta)

  expect_true("group" %in% names(result$coords))
  expect_equal(nrow(result$coords), 10)
})

# --- plot_volcano ---

test_that("plot_volcano creates ggplot from DESeq2-style results", {
  set.seed(42)
  de <- data.frame(
    log2FoldChange = rnorm(100, sd = 2),
    padj = runif(100, 0, 1),
    baseMean = runif(100, 10, 1000),
    row.names = paste0("gene", 1:100)
  )

  p <- plot_volcano(de)
  expect_s3_class(p, "ggplot")
})

test_that("plot_volcano creates ggplot from edgeR-style results", {
  de <- data.frame(
    logFC = rnorm(50, sd = 2),
    FDR = runif(50, 0, 1),
    logCPM = runif(50, 2, 8),
    row.names = paste0("gene", 1:50)
  )

  p <- plot_volcano(de)
  expect_s3_class(p, "ggplot")
})

test_that("plot_volcano handles NULL/empty input", {
  p <- plot_volcano(NULL)
  expect_s3_class(p, "ggplot")

  p <- plot_volcano(data.frame())
  expect_s3_class(p, "ggplot")
})

test_that("plot_volcano errors without required columns", {
  de <- data.frame(x = 1:5, row.names = paste0("g", 1:5))
  expect_error(plot_volcano(de), "Cannot find required columns")
})

# --- plot_ma ---

test_that("plot_ma creates ggplot from DESeq2-style results", {
  de <- data.frame(
    log2FoldChange = rnorm(100, sd = 2),
    padj = runif(100, 0, 1),
    baseMean = runif(100, 10, 10000),
    row.names = paste0("gene", 1:100)
  )

  p <- plot_ma(de)
  expect_s3_class(p, "ggplot")
})

test_that("plot_ma handles NULL/empty input", {
  p <- plot_ma(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_ma errors without expression column", {
  de <- data.frame(
    log2FoldChange = 1:5,
    padj = rep(0.01, 5),
    row.names = paste0("g", 1:5)
  )
  expect_error(plot_ma(de), "Cannot find mean expression column")
})

# --- plot_pca ---

test_that("plot_pca creates ggplot from pca_data", {
  set.seed(42)
  mat <- matrix(rnorm(500), nrow = 50, ncol = 10,
                dimnames = list(paste0("g", 1:50), paste0("S", 1:10)))
  pca_data <- compute_pca(mat, n_top = 30)

  p <- plot_pca(pca_data)
  expect_s3_class(p, "ggplot")
})

test_that("plot_pca handles color_by and shape_by", {
  set.seed(42)
  mat <- matrix(rnorm(200), nrow = 20, ncol = 10,
                dimnames = list(paste0("g", 1:20), paste0("S", 1:10)))
  meta <- data.frame(sample = paste0("S", 1:10), group = rep(c("A", "B"), 5))
  pca_data <- compute_pca(mat, n_top = 20, metadata = meta)

  p <- plot_pca(pca_data, color_by = "group")
  expect_s3_class(p, "ggplot")
})

test_that("plot_pca handles NULL input", {
  p <- plot_pca(NULL)
  expect_s3_class(p, "ggplot")
})

# --- plot_heatmap_de ---

test_that("plot_heatmap_de creates ggplot", {
  set.seed(42)
  expr_mat <- matrix(rnorm(500, mean = 8), nrow = 50, ncol = 10,
                     dimnames = list(paste0("g", 1:50), paste0("S", 1:10)))
  de <- data.frame(
    padj = c(runif(20, 0, 0.01), runif(30, 0.1, 1)),
    log2FoldChange = rnorm(50, sd = 2),
    row.names = paste0("g", 1:50)
  )

  p <- plot_heatmap_de(expr_mat, de, n_genes = 15)
  expect_s3_class(p, "ggplot")
})

test_that("plot_heatmap_de handles NULL input", {
  p <- plot_heatmap_de(NULL, NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_heatmap_de handles non-overlapping genes", {
  expr_mat <- matrix(1:20, nrow = 4, ncol = 5,
                     dimnames = list(paste0("a", 1:4), paste0("S", 1:5)))
  de <- data.frame(padj = rep(0.01, 3), row.names = paste0("b", 1:3))

  p <- plot_heatmap_de(expr_mat, de, n_genes = 3)
  expect_s3_class(p, "ggplot")
})

# --- summarize_de_methods ---

test_that("summarize_de_methods returns correct structure", {
  de_list <- list(
    DESeq2 = data.frame(
      log2FoldChange = c(2, -1.5, 0.3, 3),
      padj = c(0.001, 0.01, 0.5, 0.0001),
      row.names = paste0("g", 1:4)
    ),
    edgeR = data.frame(
      logFC = c(1.5, -2, 0.1, 2.5),
      FDR = c(0.01, 0.001, 0.8, 0.01),
      row.names = paste0("g", 1:4)
    )
  )

  result <- summarize_de_methods(de_list)

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 2)
  expect_true(all(c("method", "n_tested", "n_sig", "n_up", "n_down") %in% names(result)))
  expect_equal(result$n_tested[1], 4)
})

test_that("summarize_de_methods handles NULL/empty", {
  result <- summarize_de_methods(NULL)
  expect_equal(nrow(result), 0)

  result <- summarize_de_methods(list())
  expect_equal(nrow(result), 0)
})
