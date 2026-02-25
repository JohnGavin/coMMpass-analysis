# tests/testthat/test-snapshot-real-data.R
# Snapshot tests on real targets data committed in _targets/objects/
# These validate structural stability of pipeline outputs.

# Helper: read target object from committed store
read_target <- function(name) {
 path <- here::here("_targets/objects", name)
 if (!file.exists(path)) {
   skip(paste0("Target object '", name, "' not found in _targets/objects/"))
 }
 readRDS(path)
}

# ============================================================================
# clinical_data_clean snapshots
# ============================================================================

test_that("clinical_data_clean structure snapshot", {
  df <- read_target("clinical_data_clean")
  expect_snapshot({
    df |> names() |> sort() |> print()
    df |> sapply(class) |> (\(x) sort(names(x)))() |> print()
    cat("Dimensions:", nrow(df), "x", ncol(df), "\n")
  })
})

test_that("clinical_data_clean boundaries snapshot", {
  df <- read_target("clinical_data_clean")
  expect_snapshot({
    df$age_at_diagnosis_years |> range(na.rm = TRUE) |>
      (\(r) cat("age_at_diagnosis_years:", r[1], "to", r[2], "\n"))()
    df$submitter_id |> unique() |> length() |>
      (\(n) cat("Unique patients:", n, "\n"))()
    df$gender |> table(useNA = "ifany") |> sort() |> print()
    df$vital_status |> table(useNA = "ifany") |> sort() |> print()
  })
})

# ============================================================================
# survival_data snapshots
# ============================================================================

test_that("survival_data structure snapshot", {
  df <- read_target("survival_data")
  expect_snapshot({
    df |> names() |> sort() |> print()
    df |> sapply(class) |> (\(x) sort(names(x)))() |> print()
    cat("Dimensions:", nrow(df), "x", ncol(df), "\n")
  })
})

test_that("survival_data boundaries snapshot", {
  df <- read_target("survival_data")
  expect_snapshot({
    df$time |> range(na.rm = TRUE) |>
      (\(r) cat("time range:", r[1], "to", r[2], "\n"))()
    df$status |> table(useNA = "ifany") |> print()
    df$risk_group |> table(useNA = "ifany") |> sort() |> print()
  })
})

# ============================================================================
# deseq2_results snapshots
# ============================================================================

test_that("deseq2_results structure snapshot", {
  res <- read_target("deseq2_results")
  expect_snapshot({
    cat("class:", paste(class(res), collapse = ", "), "\n")
    cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    cat("method:", res$method, "\n")
    cat("n_deg:", res$n_deg, "\n")
    cat("results_table cols:", paste(names(res$results_table), collapse = ", "), "\n")
    cat("results_table nrow:", nrow(res$results_table), "\n")
  })
})

test_that("deseq2_results significance snapshot", {
  res <- read_target("deseq2_results")
  expect_snapshot({
    sig <- sum(res$results_table$padj < 0.05, na.rm = TRUE)
    cat("Significant (padj < 0.05):", sig, "\n")
    res$results_table$log2FC |> range(na.rm = TRUE) |>
      (\(r) cat("log2FC range:", r[1], "to", r[2], "\n"))()
  })
})

# ============================================================================
# edger_results snapshots
# ============================================================================

test_that("edger_results structure snapshot", {
  res <- read_target("edger_results")
  expect_snapshot({
    cat("class:", paste(class(res), collapse = ", "), "\n")
    cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    cat("method:", res$method, "\n")
    cat("n_deg:", res$n_deg, "\n")
    cat("results_table cols:", paste(names(res$results_table), collapse = ", "), "\n")
    cat("results_table nrow:", nrow(res$results_table), "\n")
  })
})

test_that("edger_results significance snapshot", {
  res <- read_target("edger_results")
  expect_snapshot({
    sig <- sum(res$results_table$padj < 0.05, na.rm = TRUE)
    cat("Significant (padj < 0.05):", sig, "\n")
    res$results_table$log2FC |> range(na.rm = TRUE) |>
      (\(r) cat("log2FC range:", r[1], "to", r[2], "\n"))()
  })
})

# ============================================================================
# limma_results snapshots
# ============================================================================

test_that("limma_results structure snapshot", {
  res <- read_target("limma_results")
  expect_snapshot({
    cat("class:", paste(class(res), collapse = ", "), "\n")
    cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    cat("method:", res$method, "\n")
    cat("n_deg:", res$n_deg, "\n")
    cat("results_table cols:", paste(names(res$results_table), collapse = ", "), "\n")
    cat("results_table nrow:", nrow(res$results_table), "\n")
  })
})

# ============================================================================
# gsea_results snapshots
# ============================================================================

test_that("gsea_results structure snapshot", {
  res <- read_target("gsea_results")
  expect_snapshot({
    cat("class:", paste(class(res), collapse = ", "), "\n")
    cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    cat("n_gene_sets:", res$n_gene_sets, "\n")
    cat("n_enriched_positive:", res$n_enriched_positive, "\n")
    cat("n_enriched_negative:", res$n_enriched_negative, "\n")
    cat("top_gene_sets cols:", paste(names(res$top_gene_sets), collapse = ", "), "\n")
    cat("top_gene_sets nrow:", nrow(res$top_gene_sets), "\n")
  })
})

test_that("gsea_results top pathways snapshot", {
  res <- read_target("gsea_results")
  expect_snapshot({
    res$top_gene_sets |>
      (\(df) df[order(df$q_value), ])() |>
      head(5) |>
      (\(df) {
        cat("Top 5 gene sets by q_value:\n")
        for (i in seq_len(nrow(df))) {
          cat("  ", df$gene_set[i], "NES:", df$NES[i],
              "q:", df$q_value[i], "\n")
        }
      })()
  })
})

# ============================================================================
# cox_model snapshots
# ============================================================================

test_that("cox_model structure snapshot", {
  res <- read_target("cox_model")
  expect_snapshot({
    cat("class:", paste(class(res), collapse = ", "), "\n")
    cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    cat("covariates:", paste(res$covariates, collapse = ", "), "\n")
    cat("n_samples:", res$n_samples, "\n")
    cat("concordance:", round(res$concordance, 4), "\n")
    cat("hazard_ratios cols:", paste(names(res$hazard_ratios), collapse = ", "), "\n")
    cat("hazard_ratios nrow:", nrow(res$hazard_ratios), "\n")
  })
})

test_that("cox_model hazard ratios snapshot", {
  res <- read_target("cox_model")
  expect_snapshot({
    res$hazard_ratios |>
      (\(df) {
        for (i in seq_len(nrow(df))) {
          cat(df$variable[i], "HR:", round(df$HR[i], 4),
              "p:", round(df$p_value[i], 4), "\n")
        }
      })()
  })
})

# ============================================================================
# km_analysis snapshots
# ============================================================================

test_that("km_analysis structure snapshot", {
  res <- read_target("km_analysis")
  expect_snapshot({
    cat("class:", paste(class(res), collapse = ", "), "\n")
    cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    cat("formula:", deparse(res$formula), "\n")
    cat("n_groups:", res$n_groups, "\n")
    cat("median_survival:", res$median_survival, "\n")
    cat("p_value:", res$p_value, "\n")
  })
})

# ============================================================================
# config snapshot
# ============================================================================

test_that("config structure snapshot", {
  cfg <- read_target("config")
  expect_snapshot({
    cat("class:", paste(class(cfg), collapse = ", "), "\n")
    cat("names:", paste(sort(names(cfg)), collapse = ", "), "\n")
  })
})

# ============================================================================
# data_quality_report snapshot
# ============================================================================

test_that("data_quality_report structure snapshot", {
  rpt <- read_target("data_quality_report")
  expect_snapshot({
    cat("class:", paste(class(rpt), collapse = ", "), "\n")
    if (is.data.frame(rpt)) {
      cat("names:", paste(sort(names(rpt)), collapse = ", "), "\n")
      cat("nrow:", nrow(rpt), "\n")
    } else if (is.list(rpt)) {
      cat("names:", paste(sort(names(rpt)), collapse = ", "), "\n")
    }
  })
})
