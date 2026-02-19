# plan_pkgctx.R
# Auto-generate compact API context files for LLMs via pkgctx.
# Outputs go to inst/extdata/ctx/<package>.ctx.yaml
#
# These files provide Claude with accurate function signatures and docs,
# reducing token usage by ~67% compared to full documentation.

#' Run pkgctx to generate a context YAML file
#'
#' @param pkg Package name or "." for current package.
#' @param output_path Path to write the .ctx.yaml file.
#' @return The output_path (for use as a file target).
#' @keywords internal
run_pkgctx <- function(pkg, output_path) {
  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  cmd <- sprintf(
    "nix run github:b-rodrigues/pkgctx -- r %s --compact > %s",
    shQuote(pkg), shQuote(output_path)
  )
  result <- system(cmd, intern = FALSE)
  if (result != 0) {
    cli::cli_warn(c(
      "!" = "pkgctx failed for {.pkg {pkg}}",
      "i" = "Exit code: {result}"
    ))
  }
  output_path
}

plan_pkgctx <- list(
  targets::tar_target(
    pkgctx_self,
    run_pkgctx(".", "inst/extdata/ctx/coMMpass.ctx.yaml"),
    format = "file"
  ),

  targets::tar_target(
    pkgctx_deps,
    {
      dep_pkgs <- c("dplyr", "targets", "DBI", "duckdb", "arrow", "cli")
      paths <- vapply(dep_pkgs, function(pkg) {
        out <- sprintf("inst/extdata/ctx/%s.ctx.yaml", pkg)
        run_pkgctx(pkg, out)
      }, character(1))
      paths
    },
    format = "file"
  )
)
