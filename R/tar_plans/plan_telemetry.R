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
          style = "caption-side: bottom; text-align: left;",
          "Last 20 project commits with change statistics. ",
          "Source: git log --numstat."
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

      ggplot2::ggplot(wv, ggplot2::aes(x = week, y = commits, fill = type)) +
        ggplot2::geom_col() +
        ggplot2::scale_fill_manual(
          values = type_colors, name = "Change Type"
        ) +
        ggplot2::labs(
          title = "Weekly Commit Velocity",
          subtitle = paste("Last", summary$totals$total_commits, "commits"),
          x = "Week", y = "Commits"
        ) +
        ggplot2::theme_minimal(base_size = 10) +
        ggplot2::theme(
          axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 7)
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
          style = "caption-side: bottom; text-align: left;",
          paste0(desc[1, "Package"], " codebase metrics. ",
                 "Source: file system scan.")
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE)
      )
    },
    packages = c("tibble", "DT", "htmltools"),
    cue = targets::tar_cue(mode = "always")
  ),

  # Pipeline summary (plans, targets, top size/time)
  targets::tar_target(
    vig_pipeline_summary,
    {
      meta <- targets::tar_meta()
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

      list(
        plan_tbl = plan_tbl,
        total_plans = nrow(plan_tbl),
        total_targets = sum(plan_tbl$targets),
        top_size = top_size,
        top_time = top_time
      )
    },
    packages = c("targets", "dplyr", "tibble"),
    cue = targets::tar_cue(mode = "always")
  )
)
