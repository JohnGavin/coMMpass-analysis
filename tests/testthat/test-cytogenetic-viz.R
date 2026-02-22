# tests/testthat/test-cytogenetic-viz.R
# Tests for cytogenetic visualization functions

# Helper: create mock cytogenetic data
mock_cyto_data <- function(n = 20) {
  set.seed(42)
  data.frame(
    patient_id = paste0("MMRF_", seq_len(n)),
    iss_stage = sample(c("I", "II", "III", NA), n, replace = TRUE),
    t_4_14 = sample(c("positive", "negative", NA), n, replace = TRUE,
                     prob = c(0.15, 0.7, 0.15)),
    t_11_14 = sample(c("positive", "negative", NA), n, replace = TRUE,
                      prob = c(0.2, 0.65, 0.15)),
    t_14_16 = sample(c("positive", "negative", NA), n, replace = TRUE,
                      prob = c(0.05, 0.8, 0.15)),
    del_17p = sample(c("positive", "negative", NA), n, replace = TRUE,
                      prob = c(0.1, 0.75, 0.15)),
    gain_1q = sample(c("positive", "negative", NA), n, replace = TRUE,
                      prob = c(0.3, 0.55, 0.15)),
    risk_group = sample(c("high", "standard", NA), n, replace = TRUE,
                         prob = c(0.3, 0.6, 0.1)),
    stringsAsFactors = FALSE
  )
}

# --- plot_cytogenetic_oncoprint ---

test_that("plot_cytogenetic_oncoprint creates ggplot", {
  cyto <- mock_cyto_data()
  p <- plot_cytogenetic_oncoprint(cyto)
  expect_s3_class(p, "ggplot")
})

test_that("plot_cytogenetic_oncoprint handles NULL input", {
  p <- plot_cytogenetic_oncoprint(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_cytogenetic_oncoprint handles empty data", {
  p <- plot_cytogenetic_oncoprint(data.frame())
  expect_s3_class(p, "ggplot")
})

test_that("plot_cytogenetic_oncoprint handles all-NA data", {
  cyto <- data.frame(
    patient_id = paste0("P", 1:5),
    t_4_14 = rep(NA_character_, 5),
    del_17p = rep(NA_character_, 5),
    stringsAsFactors = FALSE
  )
  p <- plot_cytogenetic_oncoprint(cyto)
  expect_s3_class(p, "ggplot")
})

test_that("plot_cytogenetic_oncoprint respects sort_by", {
  cyto <- mock_cyto_data()
  p1 <- plot_cytogenetic_oncoprint(cyto, sort_by = "frequency")
  p2 <- plot_cytogenetic_oncoprint(cyto, sort_by = "risk")
  expect_s3_class(p1, "ggplot")
  expect_s3_class(p2, "ggplot")
})

test_that("plot_cytogenetic_oncoprint accepts custom markers", {
  cyto <- mock_cyto_data()
  p <- plot_cytogenetic_oncoprint(cyto, markers = c("t_4_14", "del_17p"))
  expect_s3_class(p, "ggplot")
})

test_that("plot_cytogenetic_oncoprint handles missing marker columns", {
  cyto <- data.frame(
    patient_id = paste0("P", 1:5),
    no_markers_here = 1:5,
    stringsAsFactors = FALSE
  )
  p <- plot_cytogenetic_oncoprint(cyto)
  expect_s3_class(p, "ggplot")
})

# --- calculate_cooccurrence ---

test_that("calculate_cooccurrence returns correct structure", {
  cyto <- mock_cyto_data(50)
  result <- calculate_cooccurrence(cyto)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("marker1", "marker2", "odds_ratio", "pvalue", "padj",
                     "n_both", "n_either", "tendency") %in% names(result)))
})

test_that("calculate_cooccurrence handles NULL input", {
  result <- calculate_cooccurrence(NULL)
  expect_equal(nrow(result), 0)
})

test_that("calculate_cooccurrence handles empty data", {
  result <- calculate_cooccurrence(data.frame())
  expect_equal(nrow(result), 0)
})

test_that("calculate_cooccurrence handles single marker", {
  cyto <- data.frame(
    patient_id = paste0("P", 1:10),
    t_4_14 = sample(c("positive", "negative"), 10, replace = TRUE),
    stringsAsFactors = FALSE
  )
  result <- calculate_cooccurrence(cyto)
  expect_equal(nrow(result), 0)  # Need >=2 markers for pairs
})

test_that("calculate_cooccurrence detects known co-occurrence", {
  # Create perfect co-occurrence between two markers
  cyto <- data.frame(
    patient_id = paste0("P", 1:40),
    t_4_14 = c(rep("positive", 20), rep("negative", 20)),
    del_17p = c(rep("positive", 20), rep("negative", 20)),
    stringsAsFactors = FALSE
  )
  result <- calculate_cooccurrence(cyto)
  expect_equal(nrow(result), 1)
  expect_true(result$odds_ratio > 1)
  expect_true(result$pvalue < 0.05)
})

test_that("calculate_cooccurrence detects mutual exclusivity", {
  cyto <- data.frame(
    patient_id = paste0("P", 1:40),
    t_4_14 = c(rep("positive", 20), rep("negative", 20)),
    t_11_14 = c(rep("negative", 20), rep("positive", 20)),
    stringsAsFactors = FALSE
  )
  result <- calculate_cooccurrence(cyto)
  expect_equal(nrow(result), 1)
  expect_true(result$odds_ratio < 1)
})

test_that("calculate_cooccurrence applies BH correction", {
  cyto <- mock_cyto_data(100)
  result <- calculate_cooccurrence(cyto)
  # padj should be >= pvalue (BH correction)
  expect_true(all(result$padj >= result$pvalue - 1e-10))
})

# --- plot_cooccurrence_heatmap ---

test_that("plot_cooccurrence_heatmap creates ggplot", {
  cyto <- mock_cyto_data(50)
  cooc <- calculate_cooccurrence(cyto)
  p <- plot_cooccurrence_heatmap(cooc)
  expect_s3_class(p, "ggplot")
})

test_that("plot_cooccurrence_heatmap handles NULL", {
  p <- plot_cooccurrence_heatmap(NULL)
  expect_s3_class(p, "ggplot")
})

test_that("plot_cooccurrence_heatmap handles empty data", {
  p <- plot_cooccurrence_heatmap(data.frame(
    marker1 = character(), marker2 = character(),
    odds_ratio = numeric(), pvalue = numeric(),
    padj = numeric(), n_both = integer(), n_either = integer(),
    tendency = character()
  ))
  expect_s3_class(p, "ggplot")
})

# --- summarize_cytogenetics ---

test_that("summarize_cytogenetics returns correct structure", {
  cyto <- mock_cyto_data()
  result <- summarize_cytogenetics(cyto)
  expect_s3_class(result, "data.frame")
  expect_true(all(c("marker", "n_positive", "n_tested", "pct") %in%
                    names(result)))
})

test_that("summarize_cytogenetics includes risk group row", {
  cyto <- mock_cyto_data()
  result <- summarize_cytogenetics(cyto)
  expect_true("Any high-risk" %in% result$marker)
})

test_that("summarize_cytogenetics handles NULL input", {
  result <- summarize_cytogenetics(NULL)
  expect_equal(nrow(result), 0)
})

test_that("summarize_cytogenetics handles empty data", {
  result <- summarize_cytogenetics(data.frame())
  expect_equal(nrow(result), 0)
})

test_that("summarize_cytogenetics computes correct percentages", {
  cyto <- data.frame(
    patient_id = paste0("P", 1:10),
    t_4_14 = c(rep("positive", 3), rep("negative", 7)),
    risk_group = c(rep("high", 3), rep("standard", 7)),
    stringsAsFactors = FALSE
  )
  result <- summarize_cytogenetics(cyto)
  t414_row <- result[result$marker == "t(4;14)", ]
  expect_equal(t414_row$n_positive, 3)
  expect_equal(t414_row$n_tested, 10)
  expect_equal(t414_row$pct, 30.0)
})
