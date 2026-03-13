# R/viz/tables.R
# Named table-building functions for vignette targets.
# Each function's body is extractable as code provenance via code_vig_* targets.

#' @keywords internal
make_cyto_frequency_table <- function(cyto_frequency_summary) {
  if (is.null(cyto_frequency_summary) ||
      nrow(cyto_frequency_summary) == 0) return(NULL)

  caption <- paste0(
    "Cytogenetic alteration frequencies from FISH testing. ",
    "Marker = FISH probe target. ",
    "Positive = patients with alteration detected. ",
    "Tested = patients with FISH data for that marker. ",
    "% = prevalence among tested patients. ",
    "High-risk markers per IMWG 2014: t(4;14), t(14;16), del(17p), gain(1q). ",
    "t() = translocation, del() = deletion, gain() = extra copy. ",
    "See data dictionary for marker definitions."
  )
  DT::datatable(
    cyto_frequency_summary, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 15, scrollX = TRUE),
    colnames = c("Marker", "Positive", "Tested", "%"),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_cyto_cooccurrence_table <- function(cyto_cooccurrence) {
  if (is.null(cyto_cooccurrence) || nrow(cyto_cooccurrence) == 0) return(NULL)

  marker_labels <- c(
    t_4_14 = "t(4;14)", t_11_14 = "t(11;14)", t_14_16 = "t(14;16)",
    t_14_20 = "t(14;20)", del_17p = "del(17p)", del_1p = "del(1p)",
    gain_1q = "gain(1q)"
  )
  display <- cyto_cooccurrence
  display$marker1 <- ifelse(
    display$marker1 %in% names(marker_labels),
    marker_labels[display$marker1], display$marker1
  )
  display$marker2 <- ifelse(
    display$marker2 %in% names(marker_labels),
    marker_labels[display$marker2], display$marker2
  )

  display_df <- display[, c("marker1", "marker2", "odds_ratio", "pvalue",
                             "padj", "n_both", "tendency")]
  display_df$odds_ratio <- round(display_df$odds_ratio, 2)
  display_df$pvalue <- round(display_df$pvalue, 4)
  display_df$padj <- round(display_df$padj, 4)

  caption <- paste0(
    "Pairwise co-occurrence analysis of cytogenetic markers ",
    "(Fisher's exact test, BH-adjusted). ",
    "Marker 1/2 = FISH probe targets tested pairwise. ",
    "Odds Ratio > 1 = co-occurrence; < 1 = mutual exclusivity. ",
    "p-value = Fisher's exact test. ",
    "Adjusted p = Benjamini-Hochberg corrected. ",
    "Both+ = patients positive for both markers. ",
    "Tendency = co-occurrence or mutual exclusivity. ",
    "* = padj < 0.05."
  )
  DT::datatable(
    display_df, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 15, scrollX = TRUE),
    colnames = c("Marker 1", "Marker 2", "Odds Ratio", "p-value",
                 "Adjusted p", "Both+", "Tendency"),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_duckdb_demo_simple <- function(eda_duckdb_demo) {
  if (is.null(eda_duckdb_demo)) return(NULL)
  demo <- eda_duckdb_demo

  caption <- paste0(
    "First 10 patients from clinical data via dplyr/DuckDB query. ",
    "age_at_diagnosis is in days (GDC convention; divide by 365.25 for years). ",
    "This demonstrates zero-copy DuckDB access to parquet files."
  )
  DT::datatable(
    demo$demo_result, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_duckdb_demo_agg <- function(eda_duckdb_demo) {
  if (is.null(eda_duckdb_demo)) return(NULL)
  demo <- eda_duckdb_demo

  caption <- paste0(
    "Patient count and mean age (years) by gender via ",
    "dplyr/DuckDB aggregation. ",
    "n = number of patients. ",
    "mean_age = average age at diagnosis in years."
  )
  DT::datatable(
    demo$agg_result, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_git_info <- function() {
  if (!requireNamespace("gert", quietly = TRUE)) return(NULL)
  tryCatch({
    info <- gert::git_info()
    log1 <- gert::git_log(max = 1)
    git_df <- data.frame(
      Item = c("Commit Hash", "Author", "Time", "Branch"),
      Value = c(info$commit, log1$author,
                as.character(log1$time), info$shorthand),
      stringsAsFactors = FALSE
    )
    DT::datatable(
      git_df, rownames = FALSE,
      options = list(pageLength = 10, dom = "t", scrollX = TRUE),
      caption = htmltools::tags$caption(
        style = "caption-side: top; text-align: left;",
        "Git repository state at pipeline build time."
      )
    )
  }, error = function(e) NULL)
}
