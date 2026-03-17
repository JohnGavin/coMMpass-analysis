# inst/vignette_utils.R
# Shared utilities for vignette rendering
# Source this from vignette setup chunks instead of duplicating safe_tar_read()

# Discover targets store
.find_tar_store <- function() {
  proj_dir <- Sys.getenv("TAR_PROJECT")
  if (proj_dir != "" && dir.exists(file.path(proj_dir, "_targets")))
    return(file.path(proj_dir, "_targets"))
  if (dir.exists("_targets")) return("_targets")
  if (dir.exists("../_targets")) return("../_targets")
  NULL
}

tar_store <- .find_tar_store()

# Render a value appropriately based on its type
.render_val <- function(val) {
  if (is.null(val)) return(invisible(NULL))

  # Grobs from ggplotGrob() — draw directly

  if (inherits(val, c("gtable", "grob", "gTree"))) {
    grid::grid.newpage()
    grid::grid.draw(val)
    return(invisible(val))
  }

  # htmltools tag lists and htmlwidgets — use knitr's knit_print
  if (inherits(val, c("shiny.tag.list", "shiny.tag", "htmlwidget"))) {
    if (requireNamespace("knitr", quietly = TRUE) && knitr::is_latex_output() == FALSE) {
      # In knitr context, return the object for auto-printing
      return(val)
    }
    return(val)
  }

  # Character strings (code snippets, text blocks) — cat() to avoid [1] prefix
  if (is.character(val) && !inherits(val, "html")) {
    cat(val, sep = "\n")
    return(invisible(val))
  }

  # Everything else (DT, ggplot, data.frame, etc.) — return for auto-print
  val
}

safe_tar_read <- function(name) {
  # Try targets store first
  if (!is.null(tar_store)) {
    val <- tryCatch(
      targets::tar_read_raw(name, store = tar_store),
      error = function(e) NULL
    )
    if (!is.null(val) &&
        !(is.character(val) && length(val) == 1 &&
          grepl("not available", val, ignore.case = TRUE))) {
      return(.render_val(val))
    }
  }

  # Fallback to pre-computed RDS files
  rds_candidates <- c(
    system.file(paste0("extdata/vignettes/", name, ".rds"), package = "coMMpass"),
    file.path("inst/extdata/vignettes", paste0(name, ".rds")),
    file.path("../inst/extdata/vignettes", paste0(name, ".rds"))
  )
  for (rds in rds_candidates) {
    if (nzchar(rds) && file.exists(rds)) {
      obj <- readRDS(rds)
      # data.frames with a caption attribute get DT wrapping at render time
      if (is.data.frame(obj) && requireNamespace("DT", quietly = TRUE)) {
        cap <- attr(obj, "dt_caption")
        dt_opts <- attr(obj, "dt_options")
        if (is.null(dt_opts)) dt_opts <- list()
        if (!is.null(cap)) {
          return(DT::datatable(obj, rownames = FALSE, options = dt_opts,
                               caption = htmltools::HTML(cap)))
        }
        return(DT::datatable(obj, rownames = FALSE, options = dt_opts))
      }
      if (!is.null(obj)) return(.render_val(obj))
    }
  }
  invisible(NULL)
}

show_target <- function(name, .safe_tar_read = safe_tar_read) {
  code_name <- paste0("code_", name)
  code <- .safe_tar_read(code_name)
  if (!is.null(code) && is.character(code) && nzchar(paste(code, collapse = ""))) {
    cat('<details><summary>Generating code</summary>\n\n```r\n')
    cat(paste(code, collapse = "\n"))
    cat('\n```\n</details>\n\n')
  }
  .safe_tar_read(name)
}
