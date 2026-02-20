# tests/testthat/test-pathway-analysis.R
# Tests for real pathway/GSEA analysis functions

# --- build_gene_ranks tests ---

test_that("build_gene_ranks extracts ranks from DESeq2-style results", {
  set.seed(42)
  de_table <- data.frame(
    log2FoldChange = rnorm(200),
    stat = rnorm(200, sd = 3),
    pvalue = runif(200, 0.0001, 1),
    padj = runif(200, 0.001, 1),
    row.names = paste0("ENSG", sprintf("%011d", seq_len(200)), ".5")
  )

  ranks <- build_gene_ranks(de_table, gene_id_type = "ensembl_gene")

  expect_type(ranks, "double")
  expect_true(length(ranks) > 0)
  expect_true(length(ranks) <= 200)
  # Names should have version stripped

  expect_false(any(grepl("\\.", names(ranks))))
  # Should be sorted descending
  expect_true(all(diff(ranks) <= 0))
  # Should use stat column (not derived from pvalue)
  expect_equal(ranks, sort(ranks, decreasing = TRUE))
})

test_that("build_gene_ranks computes from lfc + pvalue when no stat column", {
  set.seed(42)
  de_table <- data.frame(
    logFC = c(2, -1.5, 0.5, -3),
    PValue = c(0.001, 0.01, 0.5, 0.0001),
    row.names = paste0("gene", 1:4)
  )

  ranks <- build_gene_ranks(de_table, gene_id_type = "gene_symbol")

  expect_type(ranks, "double")
  expect_equal(length(ranks), 4)
  # gene4 has smallest p-value and negative FC -> most negative rank
  expect_true(ranks["gene4"] < 0)
  # gene1 has small p-value and positive FC -> positive rank
  expect_true(ranks["gene1"] > 0)
})

test_that("build_gene_ranks handles NULL/empty input", {
  expect_equal(length(build_gene_ranks(NULL)), 0)
  expect_equal(length(build_gene_ranks(data.frame())), 0)
})

test_that("build_gene_ranks removes duplicate genes keeping max abs rank", {
  de_table <- data.frame(
    stat = c(5, -2, 3),
    row.names = c("ENSG001.1", "ENSG001.2", "ENSG002.1")
  )

  ranks <- build_gene_ranks(de_table, gene_id_type = "ensembl_gene")

  # ENSG001 appears twice (from .1 and .2), should keep the one with |5| > |-2|
  expect_equal(length(ranks), 2)
  expect_true("ENSG001" %in% names(ranks))
  expect_equal(unname(ranks["ENSG001"]), 5)
})

test_that("build_gene_ranks errors on missing columns", {
  de_table <- data.frame(x = 1:5, row.names = paste0("gene", 1:5))
  expect_error(build_gene_ranks(de_table), "Cannot build gene ranks")
})

# --- run_gsea tests ---

test_that("run_gsea returns empty results for NULL input", {
  result <- run_gsea(de_results = NULL)
  expect_type(result, "list")
  expect_equal(result$n_gene_sets, 0L)
  expect_equal(result$n_significant, 0L)
  expect_s3_class(result$top_gene_sets, "data.frame")
  expect_equal(nrow(result$top_gene_sets), 0)
})

test_that("run_gsea returns empty results for empty data frame", {
  result <- run_gsea(de_results = data.frame())
  expect_type(result, "list")
  expect_equal(result$n_gene_sets, 0L)
})

test_that("run_gsea errors with too few ranked genes", {
  skip_if_not_installed("fgsea")
  skip_if_not_installed("msigdbr")

  de_table <- data.frame(
    stat = rnorm(50),
    row.names = paste0("gene", 1:50)
  )
  expect_error(run_gsea(de_table, gene_id_type = "gene_symbol"),
               "Only 50 genes")
})

test_that("run_gsea works with custom gene sets", {
  skip_if_not_installed("fgsea")

  set.seed(42)
  n_genes <- 500
  gene_names <- paste0("gene", seq_len(n_genes))
  de_table <- data.frame(
    stat = rnorm(n_genes, sd = 3),
    row.names = gene_names
  )

  # Create custom gene sets using gene names from de_table
  custom_sets <- list(
    pathway_A = gene_names[1:50],
    pathway_B = gene_names[51:120],
    pathway_C = gene_names[200:280]
  )

  result <- run_gsea(
    de_table,
    gene_sets = custom_sets,
    gene_id_type = "gene_symbol",
    min_size = 10,
    max_size = 500
  )

  expect_type(result, "list")
  expect_true("results" %in% names(result))
  expect_true("n_gene_sets" %in% names(result))
  expect_true("top_gene_sets" %in% names(result))
  expect_s3_class(result$top_gene_sets, "data.frame")
  expect_true(result$n_gene_sets > 0)
  expect_equal(result$collection, "custom")
  # Check top_gene_sets has expected columns
  expect_true(all(c("pathway", "NES", "pval", "padj", "size") %in%
                    names(result$top_gene_sets)))
})

test_that("run_gsea with msigdbr hallmark gene sets", {
  skip_if_not_installed("fgsea")
  skip_if_not_installed("msigdbr")

  # Create mock DE results with realistic ENSEMBL IDs
  set.seed(42)
  # Get some real gene IDs from msigdbr
  hallmark <- msigdbr::msigdbr(species = "Homo sapiens", category = "H")
  all_genes <- unique(hallmark$ensembl_gene)
  # Use a subset as our "DE results"
  n_genes <- min(5000, length(all_genes))
  selected <- sample(all_genes, n_genes)

  de_table <- data.frame(
    stat = rnorm(n_genes, sd = 3),
    log2FoldChange = rnorm(n_genes),
    pvalue = runif(n_genes, 1e-10, 1),
    padj = runif(n_genes, 1e-8, 1),
    row.names = selected
  )

  result <- run_gsea(
    de_table,
    gene_sets = "hallmark",
    gene_id_type = "ensembl_gene",
    min_size = 10
  )

  expect_type(result, "list")
  expect_true(result$n_gene_sets > 0)
  expect_true(nrow(result$top_gene_sets) > 0)
  expect_equal(result$collection, "hallmark")
  # Hallmark sets should all start with "HALLMARK_"
  expect_true(all(grepl("^HALLMARK_", result$top_gene_sets$pathway)))
})

# --- get_msigdb_gene_sets tests ---

test_that("get_msigdb_gene_sets retrieves hallmark sets", {
  skip_if_not_installed("msigdbr")

  sets <- get_msigdb_gene_sets("hallmark", "ensembl_gene")

  expect_type(sets, "list")
  expect_true(length(sets) >= 40)  # MSigDB Hallmark has 50 gene sets
  expect_true(all(grepl("^HALLMARK_", names(sets))))
  # Each set should have genes
  expect_true(all(vapply(sets, length, integer(1)) > 0))
})

test_that("get_msigdb_gene_sets errors on invalid collection", {
  skip_if_not_installed("msigdbr")
  expect_error(get_msigdb_gene_sets("nonexistent"), "Unknown gene set")
})

# --- run_ora tests ---

test_that("run_ora performs Fisher's exact test correctly", {
  skip_if_not_installed("msigdbr")

  # Get real gene IDs from hallmark sets
  hallmark <- msigdbr::msigdbr(species = "Homo sapiens", category = "H")
  all_genes <- unique(hallmark$ensembl_gene)

  # Pick genes from a specific pathway as "significant"
  p53_genes <- hallmark$ensembl_gene[hallmark$gs_name == "HALLMARK_P53_PATHWAY"]
  # Use a subset as sig_genes
  set.seed(42)
  sig_genes <- sample(p53_genes, min(30, length(p53_genes)))
  universe <- sample(all_genes, 3000)
  universe <- unique(c(universe, sig_genes))  # ensure sig_genes in universe

  result <- run_ora(
    sig_genes = sig_genes,
    universe = universe,
    gene_sets = "hallmark",
    gene_id_type = "ensembl_gene",
    min_size = 5
  )

  expect_type(result, "list")
  expect_true("results" %in% names(result))
  expect_true("n_pathways_enriched" %in% names(result))
  expect_true("top_pathways" %in% names(result))
  expect_s3_class(result$results, "data.frame")
  expect_true(nrow(result$results) > 0)
  expect_true(all(c("pathway", "overlap", "gene_set_size", "p_value", "padj")
                    %in% names(result$results)))
  # P53 pathway should be among the top results (it's where our genes come from)
  expect_true("HALLMARK_P53_PATHWAY" %in% result$results$pathway)
})

test_that("run_ora errors with no significant genes", {
  expect_error(run_ora(character(0), paste0("gene", 1:100)),
               "No significant genes")
  expect_error(run_ora(NULL, paste0("gene", 1:100)),
               "No significant genes")
})

test_that("run_ora errors with too few genes in universe", {
  skip_if_not_installed("msigdbr")
  # sig_genes not in universe = effectively 0 genes
  expect_error(
    run_ora(
      sig_genes = paste0("fake", 1:3),
      universe = paste0("real", 1:100),
      gene_sets = "hallmark"
    ),
    "significant genes found in universe"
  )
})

# --- run_pathway_analysis wrapper tests ---

test_that("run_pathway_analysis returns empty results for empty consensus", {
  skip_if_not_installed("msigdbr")

  de_genes <- list(
    n_consensus = 0L,
    consensus_genes = character(0),
    by_method = list()
  )

  result <- run_pathway_analysis(de_genes)
  expect_type(result, "list")
  expect_equal(result$n_pathways_enriched, 0L)
})

# --- generate_summary_report tests ---

test_that("generate_summary_report creates file", {
  tmp_dir <- tempdir()
  result <- generate_summary_report(
    qc_metrics = data.frame(sample = 1:5),
    de_genes = list(n_consensus = 10),
    survival = list(),
    pathways = list(n_pathways_enriched = 3),
    output_dir = tmp_dir
  )

  expect_true(file.exists(result))
  content <- readLines(result)
  expect_true(any(grepl("Samples analyzed: 5", content)))
  expect_true(any(grepl("Enriched pathways: 3", content)))
  unlink(result)
})
