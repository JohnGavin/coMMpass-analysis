# R/viz/show_target.R
# Vignette helper that renders both the generating code and the output
# for a given vig_* target.

#' Show a vignette target with its generating code
#'
#' Combines the generating R code (from code_vig_* targets) with the
#' rendered output (from vig_* targets) in a single chunk. The code
#' is shown in a collapsible `<details>` block.
#'
#' @param name Character. The target name (e.g., "vig_de_method_barplot").
#' @param safe_tar_read Function. The safe_tar_read function from
#'   the vignette setup chunk.
#' @return The rendered object (ggplot, DT widget, etc.), with
#'   generating code printed above via cat().
#' @keywords internal
show_target <- function(name, safe_tar_read) {
  code_name <- paste0("code_", name)
  code <- safe_tar_read(code_name)

  # Show generating code in a collapsible block
  if (!is.null(code) && is.character(code) && nzchar(code)) {
    cat('<details><summary>Generating code</summary>\n\n```r\n')
    cat(paste(code, collapse = "\n"))
    cat('\n```\n</details>\n\n')
  }

  # Return the actual rendered output
  safe_tar_read(name)
}
