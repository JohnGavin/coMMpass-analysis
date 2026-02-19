#' Extract Package Dependencies from DESCRIPTION
#'
#' Parses Imports and Suggests fields from a DESCRIPTION file,
#' removing version constraints and base R packages.
#'
#' @param desc_path Path to DESCRIPTION file.
#' @return Character vector of package names (no base packages).
#' @keywords internal
get_description_deps <- function(desc_path = "DESCRIPTION") {
  if (!file.exists(desc_path)) {
    cli::cli_abort(c(
      "x" = "DESCRIPTION file not found at {.path {desc_path}}",
      "i" = "Run from the package root directory."
    ))
  }
  desc <- read.dcf(desc_path)
  parse_field <- function(field) {
    if (!field %in% colnames(desc)) return(character())
    pkgs <- strsplit(desc[, field], ",\\s*|\n\\s*")[[1]]
    gsub("\\s*\\([^)]+\\)", "", trimws(pkgs)) |>
      (\(x) x[nzchar(x) & !is.na(x)])()
  }
  deps <- unique(c(parse_field("Imports"), parse_field("Suggests")))
  base_pkgs <- c(
    "stats", "graphics", "grDevices", "utils", "datasets",
    "methods", "base", "tools", "parallel", "compiler",
    "grid", "splines", "stats4", "tcltk", "R"
  )
  deps[!deps %in% base_pkgs]
}
