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

  # htmltools tag lists and htmlwidgets
  if (inherits(val, c("shiny.tag.list", "shiny.tag", "htmlwidget"))) {
    # In pkgdown CI, htmlwidgets can crash with glue/htmltools errors
    # Return the object for auto-printing only in local/interactive mode
    in_pkgdown <- nzchar(Sys.getenv("IN_PKGDOWN"))
    if (in_pkgdown) {
      cat("*Interactive widget available in local builds only.*\n")
      return(invisible(val))
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
      # data.frames: use kable for pkgdown (DT JS unreliable), DT for local
      if (is.data.frame(obj)) {
        cap <- attr(obj, "dt_caption")
        in_pkgdown <- nzchar(Sys.getenv("IN_PKGDOWN"))
        if (in_pkgdown) {
          # Static HTML table — no JavaScript dependency
          cap_text <- if (!is.null(cap)) gsub("<[^>]+>", "", cap) else NULL
          cat(knitr::kable(obj, format = "html", row.names = FALSE,
                           caption = cap_text), sep = "\n")
          return(invisible(obj))
        }
        if (requireNamespace("DT", quietly = TRUE)) {
          dt_opts <- attr(obj, "dt_options")
          if (is.null(dt_opts)) dt_opts <- list()
          if (!is.null(cap)) {
            return(DT::datatable(obj, rownames = FALSE, options = dt_opts,
                                 caption = htmltools::HTML(cap)))
          }
          return(DT::datatable(obj, rownames = FALSE, options = dt_opts))
        }
        # Fallback: kable
        cat(knitr::kable(obj, format = "html", row.names = FALSE), sep = "\n")
        return(invisible(obj))
      }
      if (!is.null(obj)) return(.render_val(obj))
    }
  }
  invisible(NULL)
}

show_target <- function(name, .safe_tar_read = safe_tar_read) {
  code_shown <- FALSE

  # Tier 1: code_vig_* pipeline target (backed by deparse(body(fn)))
  # Available both locally (targets store) and in CI (RDS fallback)
  code_name <- paste0("code_", name)
  code <- .safe_tar_read(code_name)
  if (!is.null(code) && is.character(code) && nzchar(paste(code, collapse = ""))) {
    # Use HTML <pre><code> not markdown fences — markdown inside <details> is not parsed
    escaped <- gsub("&", "&amp;", paste(code, collapse = "\n"))
    escaped <- gsub("<", "&lt;", escaped)
    escaped <- gsub(">", "&gt;", escaped)
    cat('<details><summary>Generating code</summary>\n')
    cat('<pre><code class="language-r">', escaped, '</code></pre>\n', sep = "")
    cat('</details>\n\n')
    code_shown <- TRUE
  }

  # Tier 2: tar_manifest()$command (local only — no targets store in CI)
  if (!code_shown) {
    tryCatch({
      if (!is.null(tar_store)) {
        manifest <- targets::tar_manifest(store = tar_store)
        row <- manifest[manifest$name == name, ]
        if (nrow(row) > 0 && !is.na(row$command[1]) && nzchar(row$command[1])) {
          escaped <- gsub("&", "&amp;", row$command[1])
          escaped <- gsub("<", "&lt;", escaped)
          escaped <- gsub(">", "&gt;", escaped)
          cat('<details><summary>Target definition</summary>\n')
          cat('<pre><code class="language-r">', escaped, '</code></pre>\n', sep = "")
          cat('</details>\n\n')
          code_shown <- TRUE
        }
      }
    }, error = function(e) NULL)
  }

  # Tier 3: render the output
  result <- .safe_tar_read(name)

  # If NULL, show informative callout instead of blank space
  if (is.null(result)) {
    cat(paste0(
      '<div style="padding: 1em; margin: 1em 0; border-left: 4px solid #f39c12; ',
      'background: #2d2d2d; color: #ccc; border-radius: 4px;">',
      '<strong>Data not available:</strong> Target <code>', name, '</code> ',
      'returned NULL. This typically means the required data is not available ',
      'from the current data source (GDC API). See the ',
      '<a href="data-sources.html">Data Sources</a> vignette for details.',
      '</div>\n'
    ))
  }

  result
}
