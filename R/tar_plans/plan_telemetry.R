# plan_telemetry.R
# Git changelog, GitHub activity, and codebase metrics targets
# All targets use cue = "always" since git/GitHub state changes outside pipeline

# --- Internal helper: parse git log with numstat ---
parse_git_changelog <- function(max_commits = 20) {
  if (!requireNamespace("gert", quietly = TRUE)) return(NULL)

  log_df <- gert::git_log(max = max_commits)

  # Get numstat via system2

  numstat_raw <- system2(
    "git",
    c("log", paste0("-", max_commits), "--numstat", "--format=COMMIT:%H"),
    stdout = TRUE, stderr = FALSE
  )

  # Parse numstat into per-file records
  current_hash <- NA_character_
  records <- list()
  for (line in numstat_raw) {
    if (grepl("^COMMIT:", line)) {
      current_hash <- sub("^COMMIT:", "", line)
    } else if (nzchar(trimws(line)) && !is.na(current_hash)) {
      parts <- strsplit(trimws(line), "\t")[[1]]
      if (length(parts) == 3) {
        records[[length(records) + 1]] <- data.frame(
          hash = current_hash,
          added = suppressWarnings(as.integer(parts[1])),
          deleted = suppressWarnings(as.integer(parts[2])),
          file = parts[3],
          stringsAsFactors = FALSE
        )
      }
    }
  }

  if (length(records) == 0) {
    numstat_df <- data.frame(
      hash = character(), added = integer(),
      deleted = integer(), file = character(),
      stringsAsFactors = FALSE
    )
  } else {
    numstat_df <- do.call(rbind, records)
  }

  # Categorize files
  categorize_file <- function(f) {
    dplyr::case_when(
      grepl("^R/", f)          ~ "R Source",
      grepl("^tests/", f)      ~ "Tests",
      grepl("^vignettes/", f)  ~ "Vignettes",
      grepl("^\\.github/", f)  ~ "CI/CD",
      grepl("^man/", f)        ~ "Docs",
      grepl("DESCRIPTION|NAMESPACE|\\.yml$|\\.yaml$", f) ~ "Config",
      TRUE                     ~ "Other"
    )
  }

  # Categorize commit messages by conventional-commit prefix
  categorize_commit <- function(msg) {
    msg <- trimws(msg)
    dplyr::case_when(
      grepl("^feat[:(]",     msg, ignore.case = TRUE) ~ "New Feature",
      grepl("^fix[:(]",      msg, ignore.case = TRUE) ~ "Bug Fix",
      grepl("^docs[:(]",     msg, ignore.case = TRUE) ~ "Documentation",
      grepl("^ci[:(]",       msg, ignore.case = TRUE) ~ "CI/CD",
      grepl("^refactor[:(]", msg, ignore.case = TRUE) ~ "Refactoring",
      grepl("^test[:(]",     msg, ignore.case = TRUE) ~ "Tests",
      grepl("^chore[:(]",    msg, ignore.case = TRUE) ~ "Maintenance",
      grepl("^style[:(]",    msg, ignore.case = TRUE) ~ "Style",
      grepl("^perf[:(]",     msg, ignore.case = TRUE) ~ "Performance",
      TRUE                                            ~ "Other"
    )
  }

  # Aggregate numstat per commit
  if (nrow(numstat_df) > 0) {
    numstat_df$category <- categorize_file(numstat_df$file)
    agg <- numstat_df |>
      dplyr::group_by(hash) |>
      dplyr::summarise(
        n_files = dplyr::n(),
        lines_added = sum(added, na.rm = TRUE),
        lines_removed = sum(deleted, na.rm = TRUE),
        file_categories = paste(
          sort(unique(category)), collapse = ", "
        ),
        .groups = "drop"
      )
  } else {
    agg <- data.frame(
      hash = character(), n_files = integer(),
      lines_added = integer(), lines_removed = integer(),
      file_categories = character(), stringsAsFactors = FALSE
    )
  }

  # Build result by joining log with numstat aggregates
  # Use first 40 chars of commit hash for joining
  log_df$hash <- substr(log_df$commit, 1, 40)
  agg$hash <- substr(agg$hash, 1, 40)

  result <- dplyr::left_join(
    tibble::tibble(
      date = as.Date(log_df$time),
      hash = log_df$hash,
      message = log_df$message
    ),
    agg,
    by = "hash"
  )

  # Add commit type and summary (first line of message)
  result$type <- categorize_commit(result$message)
  result$summary <- vapply(
    strsplit(result$message, "\n"), `[`, character(1), 1
  )

  # Replace NAs with 0 for numeric columns

  result$n_files[is.na(result$n_files)] <- 0L
  result$lines_added[is.na(result$lines_added)] <- 0L
  result$lines_removed[is.na(result$lines_removed)] <- 0L
  result$file_categories[is.na(result$file_categories)] <- ""

  result[, c("date", "type", "summary", "n_files",
             "lines_added", "lines_removed", "file_categories")]
}

# --- Targets ---

plan_telemetry <- list(

  # Per-vignette footer: 20-commit changelog as DT

  targets::tar_target(
    vig_git_changelog,
    {
      df <- parse_git_changelog(max_commits = 20)
      if (is.null(df) || nrow(df) == 0) return(NULL)
      DT::datatable(
        df,
        colnames = c("Date", "Type", "Summary", "Files",
                      "+Lines", "-Lines", "File Categories"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          paste0(
            "Last 20 project commits with change statistics. ",
            "Date = commit date; Type = conventional-commit prefix ",
            "(feat/fix/docs/ci/refactor/test/chore). ",
            "Files = number of files modified; +Lines/-Lines = lines added/removed. ",
            "Source: git log --numstat. ",
            "See changes-by-type table for aggregate breakdown."
          )
        ),
        options = list(
          pageLength = 10, dom = "tip",
          order = list(list(0, "desc")),
          columnDefs = list(
            list(className = "dt-right", targets = 3:5)
          )
        ),
        rownames = FALSE
      )
    },
    packages = c("gert", "dplyr", "tibble", "DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # Telemetry aggregate: 200-commit summary
  targets::tar_target(
    vig_git_changelog_summary,
    {
      df <- parse_git_changelog(max_commits = 200)
      if (is.null(df) || nrow(df) == 0) {
        return(list(
          by_type = NULL, by_file_category = NULL,
          weekly_velocity = NULL, totals = NULL
        ))
      }

      by_type <- df |>
        dplyr::count(type, sort = TRUE, name = "commits") |>
        dplyr::mutate(
          total_added = tapply(df$lines_added, df$type, sum)[type],
          total_removed = tapply(df$lines_removed, df$type, sum)[type]
        )

      # Split file_categories and count
      all_cats <- unlist(strsplit(df$file_categories, ", "))
      all_cats <- all_cats[nzchar(all_cats)]
      by_file_category <- as.data.frame(
        sort(table(all_cats), decreasing = TRUE),
        stringsAsFactors = FALSE
      )
      names(by_file_category) <- c("category", "commits_touching")

      # Weekly velocity
      df$week <- format(df$date, "%Y-W%V")
      weekly_velocity <- df |>
        dplyr::count(week, type, name = "commits") |>
        dplyr::arrange(week)

      totals <- list(
        total_commits = nrow(df),
        total_added = sum(df$lines_added),
        total_removed = sum(df$lines_removed),
        total_files_changed = sum(df$n_files),
        date_range = paste(
          format(min(df$date), "%Y-%m-%d"), "to",
          format(max(df$date), "%Y-%m-%d")
        )
      )

      list(
        by_type = by_type,
        by_file_category = by_file_category,
        weekly_velocity = weekly_velocity,
        totals = totals
      )
    },
    packages = c("gert", "dplyr", "tibble"),
    cue = targets::tar_cue(mode = "always")
  ),

  # Commit velocity bar chart
  targets::tar_target(
    vig_commit_velocity,
    {
      summary <- vig_git_changelog_summary
      wv <- summary$weekly_velocity
      if (is.null(wv) || nrow(wv) == 0) return(NULL)

      # Color palette for commit types
      type_colors <- c(
        "New Feature"   = "#2ecc71", "Bug Fix"       = "#e74c3c",
        "Documentation" = "#3498db", "CI/CD"         = "#f39c12",
        "Refactoring"   = "#9b59b6", "Tests"         = "#1abc9c",
        "Maintenance"   = "#95a5a6", "Style"         = "#e67e22",
        "Performance"   = "#2c3e50", "Other"         = "#bdc3c7"
      )

      date_range <- summary$totals$date_range
      n_total <- summary$totals$total_commits
      n_added <- format(summary$totals$total_added, big.mark = ",")
      n_removed <- format(summary$totals$total_removed, big.mark = ",")

      ggplot2::ggplot(wv, ggplot2::aes(x = week, y = commits, fill = type)) +
        ggplot2::geom_col() +
        ggplot2::scale_fill_manual(
          values = type_colors, name = "Change Type"
        ) +
        ggplot2::labs(
          title = "Weekly Commit Velocity",
          subtitle = paste("Last", n_total, "commits"),
          x = "Week", y = "Commits",
          caption = paste0(
            "Stacked bar chart of weekly commit activity (", date_range, "). ",
            "x-axis: ISO week; y-axis: number of commits; ",
            "fill color = conventional-commit type (feat/fix/docs/ci/etc.). ",
            n_total, " commits total; +", n_added, "/-", n_removed, " lines changed. ",
            "Source: git log. ",
            "See changes-by-type table for per-type aggregates and ",
            "changelog for individual commit details."
          )
        ) +
        ggplot2::theme_minimal(base_size = 10) +
        ggplot2::theme(
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 7),
          plot.caption = ggplot2::element_text(
            size = 7, hjust = 0, lineheight = 1.2
          )
        )
    },
    packages = c("ggplot2"),
    cue = targets::tar_cue(mode = "always")
  ),

  # GitHub activity: issues and PRs
  targets::tar_target(
    vig_github_activity,
    {
      if (!requireNamespace("gh", quietly = TRUE)) {
        return(list(
          issues_open = NA, issues_closed = NA,
          prs_merged = NA, error = "gh package not available"
        ))
      }
      owner <- "JohnGavin"
      repo <- "coMMpass-analysis"
      tryCatch({
        issues_open <- gh::gh(
          "/repos/{owner}/{repo}/issues",
          owner = owner, repo = repo, state = "open", per_page = 100
        )
        issues_closed <- gh::gh(
          "/repos/{owner}/{repo}/issues",
          owner = owner, repo = repo, state = "closed", per_page = 100
        )
        # Filter out PRs (they appear in issues endpoint too)
        issues_open <- Filter(
          function(x) is.null(x$pull_request), issues_open
        )
        issues_closed <- Filter(
          function(x) is.null(x$pull_request), issues_closed
        )
        prs_closed <- gh::gh(
          "/repos/{owner}/{repo}/pulls",
          owner = owner, repo = repo, state = "closed", per_page = 100
        )
        list(
          issues_open = length(issues_open),
          issues_closed = length(issues_closed),
          prs_merged = sum(
            vapply(prs_closed, function(x) !is.null(x$merged_at), logical(1))
          )
        )
      }, error = function(e) {
        list(
          issues_open = NA, issues_closed = NA,
          prs_merged = NA, error = conditionMessage(e)
        )
      })
    },
    packages = c("gh"),
    cue = targets::tar_cue(mode = "always")
  ),

  # Codebase metrics
  targets::tar_target(
    vig_codebase_metrics,
    {
      r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE,
                            recursive = TRUE)
      r_files <- r_files[!grepl("R/dev/", r_files)]
      test_files <- list.files("tests/testthat", pattern = "^test-.*\\.R$")
      vignette_files <- list.files("vignettes", pattern = "\\.(qmd|Rmd)$")
      plan_files <- list.files("R/tar_plans", pattern = "^plan_.*\\.R$")

      lines_of_code <- sum(vapply(r_files, function(f) {
        code <- readLines(f, warn = FALSE)
        sum(nchar(trimws(code)) > 0 & !grepl("^\\s*#", code))
      }, integer(1)))

      exports <- tryCatch(
        sum(grepl("^export\\(", readLines("NAMESPACE", warn = FALSE))),
        error = function(e) 0L
      )

      desc <- read.dcf("DESCRIPTION", fields = c("Version", "Package"))

      DT::datatable(
        tibble::tibble(
          Metric = c(
            "R source files", "Test files", "Vignettes",
            "Pipeline plans", "Exported functions",
            "Lines of R code", "Version"
          ),
          Value = c(
            as.character(length(r_files)),
            as.character(length(test_files)),
            as.character(length(vignette_files)),
            as.character(length(plan_files)),
            as.character(exports),
            format(lines_of_code, big.mark = ","),
            desc[1, "Version"]
          )
        ),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          paste0(
            desc[1, "Package"], " v", desc[1, "Version"],
            " codebase metrics. ",
            "R source files includes R/ and R/tar_plans/ (excluding R/dev/). ",
            "Lines of R code excludes comments and blank lines. ",
            "Exported functions counted from NAMESPACE. ",
            "Source: file system scan at pipeline build time. ",
            "See pipeline-dag for target dependency structure."
          )
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE)
      )
    },
    packages = c("tibble", "DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # Pipeline summary (plans, targets, top size/time)
  # NOTE: tar_meta() cannot run inside a pipeline, so we read the

  # metadata CSV directly from the _targets/meta/meta file.
  targets::tar_target(
    vig_pipeline_summary,
    {
      plan_files <- list.files(
        "R/tar_plans", pattern = "^plan_.*\\.R$", full.names = TRUE
      )
      plan_counts <- lapply(plan_files, function(f) {
        code <- readLines(f, warn = FALSE)
        n <- sum(grepl("tar_target\\(|tar_quarto\\(", code))
        tibble::tibble(plan = basename(f), targets = n)
      })
      plan_tbl <- dplyr::bind_rows(plan_counts) |>
        dplyr::arrange(dplyr::desc(targets))

      # Read metadata directly from store instead of tar_meta()
      meta_path <- file.path("_targets", "meta", "meta")
      if (file.exists(meta_path)) {
        meta <- tryCatch(
          utils::read.csv(meta_path, stringsAsFactors = FALSE, sep = "|"),
          error = function(e) NULL
        )
      } else {
        meta <- NULL
      }

      top_size <- NULL
      top_time <- NULL
      if (!is.null(meta) && "bytes" %in% names(meta) &&
          "seconds" %in% names(meta)) {
        meta$seconds <- as.numeric(meta$seconds)
        meta$bytes <- as.numeric(meta$bytes)

        top_size <- meta |>
          dplyr::filter(!is.na(bytes), bytes > 0) |>
          dplyr::arrange(dplyr::desc(bytes)) |>
          dplyr::slice_head(n = 5)

        top_time <- meta |>
          dplyr::filter(!is.na(seconds), seconds > 0) |>
          dplyr::arrange(dplyr::desc(seconds)) |>
          dplyr::slice_head(n = 5)
      }

      list(
        plan_tbl = plan_tbl,
        total_plans = nrow(plan_tbl),
        total_targets = sum(plan_tbl$targets),
        top_size = top_size,
        top_time = top_time
      )
    },
    packages = c("dplyr", "tibble"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: timing table (DT from meta CSV) ---
  targets::tar_target(
    vig_timing_table,
    {
      meta_path <- file.path("_targets", "meta", "meta")
      if (!file.exists(meta_path)) return(NULL)
      meta <- utils::read.csv(meta_path, stringsAsFactors = FALSE, sep = "|")
      meta_timed <- meta[!is.na(meta$seconds), c("name", "seconds", "bytes")]
      meta_timed$seconds <- as.numeric(meta_timed$seconds)
      meta_timed <- meta_timed[order(-meta_timed$seconds), ]
      meta_timed$size <- ifelse(
        is.na(meta_timed$bytes), "\u2014",
        ifelse(meta_timed$bytes > 1e6,
          paste0(round(meta_timed$bytes / 1e6, 1), " MB"),
          ifelse(meta_timed$bytes > 1e3,
            paste0(round(meta_timed$bytes / 1e3, 1), " KB"),
            paste0(meta_timed$bytes, " B")
          )
        )
      )
      display <- meta_timed[, c("name", "seconds", "size")]

      total_time <- round(sum(meta_timed$seconds, na.rm = TRUE) / 60, 1)
      slowest <- display$name[1]
      caption <- paste0(
        "Build durations for ", nrow(display), " targets with timing data. ",
        "Sorted by seconds (descending); total build time = ", total_time, " min. ",
        "Slowest target: ", slowest, " (",
        round(meta_timed$seconds[1], 1), " s). ",
        "Size = serialized object size on disk. ",
        "Source: _targets/meta/meta (pipe-delimited CSV). ",
        "See size distribution plot for visual comparison."
      )

      DT::datatable(
        display,
        colnames = c("Target", "Seconds", "Size"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(pageLength = 15, scrollX = TRUE,
                       order = list(list(1, "desc")))
      )
    },
    packages = c("DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: build status summary ---
  targets::tar_target(
    vig_build_status,
    {
      meta_path <- file.path("_targets", "meta", "meta")
      if (!file.exists(meta_path)) return(NULL)
      meta <- utils::read.csv(meta_path, stringsAsFactors = FALSE, sep = "|")
      meta$seconds <- as.numeric(meta$seconds)
      meta$bytes <- as.numeric(meta$bytes)

      n_targets <- nrow(meta)
      n_errors <- sum(!is.na(meta$error))
      total_time <- round(sum(meta$seconds, na.rm = TRUE) / 60, 1)
      total_size <- round(sum(meta$bytes, na.rm = TRUE) / 1e6, 1)

      status_df <- data.frame(
        Metric = c("Total targets", "With timing data", "With errors",
                    "With warnings", "Total build time", "Total serialized size"),
        Value = c(
          as.character(n_targets),
          as.character(sum(!is.na(meta$seconds))),
          as.character(n_errors),
          as.character(sum(!is.na(meta$warnings))),
          paste0(total_time, " min"),
          paste0(total_size, " MB")
        ),
        stringsAsFactors = FALSE
      )

      caption <- paste0(
        "Pipeline build summary for ", n_targets, " targets. ",
        "Total build time: ", total_time, " min; total serialized size: ",
        total_size, " MB. ",
        if (n_errors > 0) paste0(n_errors, " targets have errors — see errors table. ")
        else "No errors in the last build. ",
        "Source: _targets/meta/meta. ",
        "See timing table for per-target durations and size plot for distribution."
      )

      DT::datatable(
        status_df,
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE)
      )
    },
    packages = c("DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: errors/warnings table ---
  targets::tar_target(
    vig_errors_table,
    {
      meta_path <- file.path("_targets", "meta", "meta")
      if (!file.exists(meta_path)) return(NULL)
      meta <- utils::read.csv(meta_path, stringsAsFactors = FALSE, sep = "|")
      issues <- meta[!is.na(meta$error) | !is.na(meta$warnings),
                     c("name", "error", "warnings")]
      if (nrow(issues) == 0) {
        issues <- data.frame(
          Status = "No errors or warnings in the last build.",
          stringsAsFactors = FALSE
        )
        caption <- paste0(
          "Error and warning report for the pipeline build. ",
          "No errors or warnings were recorded. ",
          "Source: _targets/meta/meta. ",
          "See pipeline-dag for dependency structure."
        )
      } else {
        caption <- paste0(
          nrow(issues), " targets with errors or warnings. ",
          "name = target identifier; error = error message (if any); ",
          "warnings = warning messages (if any). ",
          "Source: _targets/meta/meta. ",
          "See pipeline-dag for dependency chains to diagnose root causes."
        )
      }

      DT::datatable(
        issues,
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(pageLength = 15, scrollX = TRUE)
      )
    },
    packages = c("DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: outdated list (text, cannot call tar_outdated inside pipeline) ---
  targets::tar_target(
    vig_outdated_list,
    {
      "Run targets::tar_outdated() locally to check for outdated targets."
    },
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: size distribution plot ---
  targets::tar_target(
    vig_size_plot,
    {
      meta_path <- file.path("_targets", "meta", "meta")
      if (!file.exists(meta_path)) return(NULL)
      meta <- utils::read.csv(meta_path, stringsAsFactors = FALSE, sep = "|")
      meta$bytes <- as.numeric(meta$bytes)
      meta_sized <- meta[!is.na(meta$bytes) & meta$bytes > 0, ]
      if (nrow(meta_sized) == 0) return(NULL)
      total_mb <- round(sum(meta_sized$bytes, na.rm = TRUE) / 1e6, 1)
      largest <- meta_sized$name[which.max(meta_sized$bytes)]
      largest_mb <- round(max(meta_sized$bytes, na.rm = TRUE) / 1e6, 1)

      # Assign size categories for faceted display
      meta_sized$size_cat <- cut(
        meta_sized$bytes,
        breaks = c(0, 1e3, 1e4, 1e5, 1e6, Inf),
        labels = c("< 1 KB", "1-10 KB", "10-100 KB", "100 KB-1 MB", "> 1 MB"),
        ordered_result = TRUE
      )

      p <- ggplot2::ggplot(
        meta_sized,
        ggplot2::aes(x = bytes / 1e3, y = stats::reorder(name, bytes))
      ) +
        ggplot2::geom_col(fill = "steelblue", width = 0.7) +
        ggplot2::facet_wrap(~size_cat, scales = "free", ncol = 1) +
        ggplot2::labs(
          title = "Target Sizes (serialized)",
          subtitle = paste0(nrow(meta_sized), " targets with stored objects"),
          x = "Size (KB)", y = NULL,
          caption = paste0(
            "Serialized sizes for ", nrow(meta_sized), " targets stored in _targets/objects/. ",
            "Faceted by size category. ",
            "Largest: ", largest, " (", largest_mb, " MB); ",
            "total: ", total_mb, " MB. ",
            "Source: _targets/meta/meta."
          )
        ) +
        ggplot2::theme_minimal(base_size = 10) +
        ggplot2::theme(
          axis.text.y = ggplot2::element_text(size = 7),
          strip.text = ggplot2::element_text(size = 9, face = "bold"),
          plot.caption = ggplot2::element_text(
            size = 7, hjust = 0, lineheight = 1.2
          )
        )
      ggplot2::ggplotGrob(p)
    },
    packages = c("ggplot2"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: changes by type (extracted from summary) ---
  targets::tar_target(
    vig_changes_by_type,
    {
      s <- vig_git_changelog_summary
      if (is.null(s) || is.null(s$by_type)) return(NULL)
      bt <- s$by_type
      n_commits <- s$totals$total_commits
      dominant <- bt$type[1]
      caption <- paste0(
        "Commits by type (conventional-commit prefix) for the last ",
        n_commits, " commits. ",
        "Dominant type: ", dominant, " (", bt$commits[1], " commits). ",
        "total_added/total_removed = lines of code changed per type. ",
        "Source: git log --numstat. ",
        "See commit velocity plot for weekly trends and changelog for details."
      )
      DT::datatable(
        bt,
        colnames = c("Type", "Commits", "Lines Added", "Lines Removed"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE,
                       order = list(list(1, "desc")))
      )
    },
    packages = c("DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: changes by file category ---
  targets::tar_target(
    vig_changes_by_file_category,
    {
      s <- vig_git_changelog_summary
      if (is.null(s) || is.null(s$by_file_category)) return(NULL)
      bfc <- s$by_file_category
      top_cat <- bfc$category[1]
      caption <- paste0(
        "Files changed by category across the last ",
        s$totals$total_commits, " commits. ",
        "Most active category: ", top_cat, " (",
        bfc$commits_touching[1], " commits). ",
        "category = file path pattern (R Source, Tests, Vignettes, CI/CD, etc.). ",
        "commits_touching = number of commits that modified at least one file in this category. ",
        "Source: git log --numstat."
      )
      DT::datatable(
        bfc,
        colnames = c("Category", "Commits Touching"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE,
                       order = list(list(1, "desc")))
      )
    },
    packages = c("DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Telemetry vignette: GitHub activity table ---
  targets::tar_target(
    vig_github_activity_table,
    {
      gh_data <- vig_github_activity
      if (is.null(gh_data) || !is.null(gh_data$error)) {
        err_df <- data.frame(
          Status = paste0("GitHub API: ",
            if (!is.null(gh_data$error)) gh_data$error else "data not available"),
          stringsAsFactors = FALSE
        )
        caption <- paste0(
          "GitHub activity metrics (unavailable). ",
          "The GitHub API could not be reached or returned an error. ",
          "Retry locally with a valid GITHUB_PAT. ",
          "Source: GitHub REST API via gh package."
        )
        return(DT::datatable(
          err_df,
          caption = htmltools::tags$caption(
            style = "caption-side: top; text-align: left;", caption
          ),
          rownames = FALSE,
          options = list(dom = "t", paging = FALSE)
        ))
      }
      gh_df <- data.frame(
        Metric = c("Open Issues", "Closed Issues", "Merged PRs"),
        Count = c(gh_data$issues_open, gh_data$issues_closed, gh_data$prs_merged),
        stringsAsFactors = FALSE
      )
      total_issues <- gh_data$issues_open + gh_data$issues_closed
      caption <- paste0(
        "GitHub activity for JohnGavin/coMMpass-analysis. ",
        total_issues, " total issues (",
        gh_data$issues_open, " open, ", gh_data$issues_closed, " closed); ",
        gh_data$prs_merged, " merged PRs. ",
        "Source: GitHub REST API (/repos/{owner}/{repo}/issues and /pulls). ",
        "See changelog for recent commit details."
      )
      DT::datatable(
        gh_df,
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE)
      )
    },
    packages = c("DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # --- Chunk-target mapping audit ---
  targets::tar_target(
    vig_chunk_audit,
    {
      vigs <- list.files("vignettes", pattern = "\\.qmd$", full.names = TRUE)
      results <- list()
      for (f in vigs) {
        lines <- readLines(f, warn = FALSE)
        vig <- sub("\\.qmd$", "", basename(f))
        cs_all <- grep("^```\\{r", lines)
        ce_all <- grep("^```$", lines)
        for (cs in cs_all) {
          ce <- min(ce_all[ce_all > cs])
          if (is.infinite(ce)) next
          header <- lines[cs]
          body <- lines[(cs + 1):(ce - 1)]
          code <- paste(body, collapse = "\n")
          nm <- regmatches(header, regexec("\\{r\\s+([^,}]+)", header))[[1]]
          chunk_name <- if (length(nm) >= 2) trimws(nm[2]) else "<unnamed>"
          trefs <- unique(unlist(regmatches(code,
            gregexpr('"(vig_[^"]+|code_[^"]+|config|glossary_table|dag_[^"]+|eda_[^"]+)"',
                     code))))
          trefs <- gsub('"', '', trefs)
          has_show <- grepl("show_target", code)
          ef <- any(grepl("echo.*false", body))
          it <- if (length(trefs) > 0) paste(trefs, collapse = ", ") else "<none>"
          ct <- if (has_show) "show_target"
                else if (grepl("safe_tar_read", code)) "safe_tar_read"
                else "<infra>"
          results[[length(results) + 1]] <- data.frame(
            Vignette = vig, Chunk = chunk_name, Call = ct,
            Target = it, echo_false = ef, stringsAsFactors = FALSE
          )
        }
      }
      df <- do.call(rbind, results)
      # Flag exceptions
      infra_chunks <- c("setup", "pkgdown-banner", "session-info", "sessioninfo")
      df$Status <- ifelse(
        df$Chunk %in% infra_chunks, "infra (OK)",
        ifelse(df$Target == "<none>", "VIOLATION", "mapped")
      )
      df
    },
    cue = targets::tar_cue(mode = "always")
  ),

  targets::tar_target(
    vig_chunk_audit_table,
    {
      if (is.null(vig_chunk_audit)) return(NULL)
      exc <- vig_chunk_audit[vig_chunk_audit$Status != "mapped", ]
      DT::datatable(exc, rownames = FALSE,
        options = list(dom = "t", paging = FALSE),
        caption = htmltools::tags$caption(
          style = "caption-side: bottom; text-align: left;",
          "Chunk-target mapping exceptions. 'infra (OK)' = setup/banner/sessionInfo. ",
          "'VIOLATION' = content chunk without a pipeline target. ",
          "All content chunks should use show_target() with a vig_* target."
        ))
    },
    packages = c("DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  )
)
