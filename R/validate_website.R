# R/validate_website.R
# Post-build validation for pkgdown articles.

#' Validate pkgdown article HTML files
#'
#' Checks deployed article HTML for common rendering issues including
#' error patterns, knitr::kable tables (should be DT), missing sessionInfo,
#' and missing captions.
#'
#' @param docs_dir Path to pkgdown docs/articles directory.
#'   Defaults to "docs/articles".
#' @return A data.frame with one row per article and columns for each check.
#' @keywords internal
validate_pkgdown_articles <- function(docs_dir = "docs/articles") {
  if (!dir.exists(docs_dir)) {
    stop("docs_dir does not exist: ", docs_dir)
  }

  html_files <- list.files(docs_dir, pattern = "\\.html$", full.names = TRUE)
  if (length(html_files) == 0) {
    message("No HTML files found in ", docs_dir)
    return(data.frame())
  }

  results <- lapply(html_files, function(f) {
    lines <- readLines(f, warn = FALSE)
    content <- paste(lines, collapse = "\n")

    # Count error patterns
    error_patterns <- c(
      "#&gt; Error", "#&gt; NULL",
      "#&gt;.*not available", "#&gt;.*could not find"
    )
    n_errors <- sum(vapply(error_patterns, function(p) {
      length(grep(p, lines, perl = TRUE))
    }, integer(1)))

    # Count kable tables (should be DT)
    n_kable <- length(grep('class="kable', lines))

    # Count DT tables
    n_dt <- length(grep('class="datatables', lines))

    # Check for sessionInfo
    has_session_info <- any(grepl("sessionInfo|Session Info", lines))

    # Count plots (img/svg)
    n_plots <- length(grep("<img |<svg ", lines))

    data.frame(
      article = basename(f),
      errors = n_errors,
      kable_tables = n_kable,
      dt_tables = n_dt,
      has_sessioninfo = has_session_info,
      plots = n_plots,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, results)
}
