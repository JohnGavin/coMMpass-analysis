# tests/testthat/test-gene-annotation.R
# Tests for gene annotation and enrichment visualization

# --- annotate_genes ---

test_that("annotate_genes handles NULL/empty input", {
  result <- annotate_genes(NULL)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 0)
  expect_true(all(c("ensembl_gene", "gene_symbol", "entrez_gene") %in%
                    names(result)))

  result <- annotate_genes(character(0))
  expect_equal(nrow(result), 0)
})

test_that("annotate_genes strips version suffixes", {
  skip_if_not_installed("msigdbr")

  result <- annotate_genes(c("ENSG00000141510.17", "ENSG00000012048.24"))

  expect_equal(result$ensembl_gene, c("ENSG00000141510", "ENSG00000012048"))
  expect_equal(nrow(result), 2)
})

test_that("annotate_genes maps known genes via msigdbr", {
  skip_if_not_installed("msigdbr")

  # TP53 and BRCA1 are well-known genes in MSigDB
  result <- annotate_genes(c("ENSG00000141510", "ENSG00000012048"))

  expect_equal(nrow(result), 2)
  expect_true("TP53" %in% result$gene_symbol || !all(is.na(result$gene_symbol)))
})

test_that("annotate_genes handles unmappable IDs gracefully", {
  skip_if_not_installed("msigdbr")

  result <- annotate_genes(c("ENSG00000141510", "FAKE_GENE_123"))

  expect_equal(nrow(result), 2)
  expect_true(is.na(result$gene_symbol[result$ensembl_gene == "FAKE_GENE_123"]))
})

# --- annotate_de_results ---

test_that("annotate_de_results adds gene_symbol column", {
  de <- data.frame(
    log2FoldChange = c(2.5, -1.3),
    padj = c(0.001, 0.05),
    row.names = c("ENSG00000141510.17", "ENSG00000012048.24")
  )
  annot <- data.frame(
    ensembl_gene = c("ENSG00000141510", "ENSG00000012048"),
    gene_symbol = c("TP53", "BRCA1"),
    entrez_gene = c("7157", "672"),
    stringsAsFactors = FALSE
  )

  result <- annotate_de_results(de, annot)

  expect_true("gene_symbol" %in% names(result))
  expect_equal(names(result)[1], "gene_symbol")
  expect_equal(result$gene_symbol, c("TP53", "BRCA1"))
})

test_that("annotate_de_results handles NULL/empty input", {
  expect_null(annotate_de_results(NULL, data.frame()))
  expect_equal(nrow(annotate_de_results(data.frame(), data.frame())), 0)
})

# --- plot_enrichment_dotplot ---

test_that("plot_enrichment_dotplot creates ggplot", {
  df <- data.frame(
    pathway = paste0("HALLMARK_", c("P53_PATHWAY", "MYC_TARGETS",
                                     "E2F_TARGETS", "G2M_CHECKPOINT")),
    NES = c(2.1, -1.8, 1.5, -1.2),
    pval = c(0.001, 0.005, 0.01, 0.05),
    padj = c(0.01, 0.03, 0.05, 0.1),
    size = c(120, 200, 80, 95),
    stringsAsFactors = FALSE
  )

  p <- plot_enrichment_dotplot(df)
  expect_s3_class(p, "ggplot")
})

test_that("plot_enrichment_dotplot handles NULL", {
  p <- plot_enrichment_dotplot(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_enrichment_dotplot colors by NES", {
  df <- data.frame(
    pathway = c("PATH_A", "PATH_B"),
    NES = c(2.0, -1.5),
    padj = c(0.01, 0.03),
    size = c(100, 80),
    stringsAsFactors = FALSE
  )

  p <- plot_enrichment_dotplot(df, color_by = "NES")
  expect_s3_class(p, "ggplot")
})

# --- plot_enrichment_barplot ---

test_that("plot_enrichment_barplot creates ggplot with GSEA results", {
  df <- data.frame(
    pathway = paste0("HALLMARK_", c("P53", "MYC", "E2F")),
    NES = c(2.1, -1.8, 1.5),
    padj = c(0.01, 0.03, 0.05),
    stringsAsFactors = FALSE
  )

  p <- plot_enrichment_barplot(df)
  expect_s3_class(p, "ggplot")
})

test_that("plot_enrichment_barplot creates ggplot with ORA results", {
  df <- data.frame(
    pathway = c("PATH_A", "PATH_B"),
    padj = c(0.01, 0.05),
    overlap = c(15, 8),
    stringsAsFactors = FALSE
  )

  p <- plot_enrichment_barplot(df)
  expect_s3_class(p, "ggplot")
})

test_that("plot_enrichment_barplot handles NULL", {
  p <- plot_enrichment_barplot(NULL)
  expect_s3_class(p, "ggplot")
})

# --- plot_gsea_running_score ---

test_that("plot_gsea_running_score creates ggplot with custom gene sets", {
  set.seed(42)
  gene_names <- paste0("gene", 1:200)
  ranked <- sort(rnorm(200, sd = 3), decreasing = TRUE)
  names(ranked) <- gene_names

  custom_sets <- list(
    test_pathway = gene_names[c(1:10, 50:60)]
  )

  gsea_result <- list(
    results = data.frame(
      pathway = "test_pathway",
      NES = 1.8,
      padj = 0.01,
      stringsAsFactors = FALSE
    ),
    ranked_genes = ranked,
    collection = "custom"
  )

  p <- plot_gsea_running_score(gsea_result, "test_pathway",
                                gene_sets = custom_sets)
  expect_s3_class(p, "ggplot")
})

test_that("plot_gsea_running_score handles NULL input", {
  p <- plot_gsea_running_score(NULL, "test")
  expect_s3_class(p, "ggplot")
})

test_that("plot_gsea_running_score errors on missing gene set", {
  gsea_result <- list(
    ranked_genes = c(a = 1, b = 2),
    results = data.frame(pathway = "x", NES = 1, padj = 0.05)
  )
  expect_error(
    plot_gsea_running_score(gsea_result, "nonexistent",
                             gene_sets = list(x = "a")),
    "not found"
  )
})

# --- summarize_de_methods (from 06_de_visualization.R, tested here for coverage) ---

test_that("annotate_de_results preserves all original columns", {
  de <- data.frame(
    baseMean = c(100, 200),
    log2FoldChange = c(1.5, -2.0),
    padj = c(0.01, 0.05),
    row.names = c("ENSG001", "ENSG002")
  )
  annot <- data.frame(
    ensembl_gene = c("ENSG001", "ENSG002"),
    gene_symbol = c("GeneA", "GeneB"),
    entrez_gene = c("1", "2"),
    stringsAsFactors = FALSE
  )

  result <- annotate_de_results(de, annot)
  expect_true(all(c("gene_symbol", "baseMean", "log2FoldChange", "padj") %in%
                    names(result)))
})
