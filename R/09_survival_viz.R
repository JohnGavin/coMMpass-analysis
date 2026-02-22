# R/09_survival_viz.R
# Survival analysis visualization: KM curves, forest plots

# Suppress R CMD check NOTEs for ggplot2 aes() variables
utils::globalVariables(c(
  "time", "surv", "lower", "upper", "group",
  "variable", "HR", "HR_lower", "HR_upper", "label"
))

#' Plot Kaplan-Meier curve
#'
#' Creates a ggplot2-based KM survival curve from a survfit object.
#' Supports stratified and unstratified curves with optional log-rank p-value.
#'
#' @param km_result List from [run_kaplan_meier()] with `fit`, `logrank_p`,
#'   `median_survival`, `n_per_group`, `strata`
#' @param title Plot title
#' @param xlab X-axis label
#' @param time_breaks Sequence of time breaks for x-axis (in days). Default
#'   marks every 365 days.
#' @return A ggplot object
#' @export
plot_km <- function(km_result,
                    title = "Kaplan-Meier Survival Curve",
                    xlab = "Time (days)",
                    time_breaks = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required.")
  }

  if (is.null(km_result) || is.null(km_result$fit)) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No KM data available") +
             ggplot2::theme_void())
  }

  fit <- km_result$fit

  # Extract data from survfit object
  if (!is.null(km_result$strata) && !is.null(fit$strata)) {
    # Stratified: build data frame per group
    strata_names <- names(fit$strata)
    strata_sizes <- fit$strata
    strata_vec <- rep(strata_names, strata_sizes)

    # Clean strata labels (remove "variable=" prefix)
    strata_vec <- sub("^[^=]+=", "", strata_vec)

    km_df <- data.frame(
      time = fit$time,
      surv = fit$surv,
      lower = fit$lower,
      upper = fit$upper,
      group = strata_vec,
      stringsAsFactors = FALSE
    )

    # Add time=0 starting point for each group
    groups <- unique(strata_vec)
    starts <- data.frame(
      time = rep(0, length(groups)),
      surv = rep(1, length(groups)),
      lower = rep(1, length(groups)),
      upper = rep(1, length(groups)),
      group = groups,
      stringsAsFactors = FALSE
    )
    km_df <- rbind(starts, km_df)
  } else {
    # Unstratified
    km_df <- data.frame(
      time = c(0, fit$time),
      surv = c(1, fit$surv),
      lower = c(1, fit$lower),
      upper = c(1, fit$upper),
      group = "Overall",
      stringsAsFactors = FALSE
    )
  }

  # Build subtitle with log-rank p-value and n
  subtitle_parts <- character()
  if (!is.null(km_result$n_per_group)) {
    n_str <- paste(names(km_result$n_per_group), "=",
                   km_result$n_per_group, collapse = ", ")
    subtitle_parts <- c(subtitle_parts, paste0("n: ", n_str))
  }
  if (!is.na(km_result$logrank_p)) {
    p_str <- if (km_result$logrank_p < 0.001) "< 0.001" else
      sprintf("= %.3f", km_result$logrank_p)
    subtitle_parts <- c(subtitle_parts, paste0("Log-rank p ", p_str))
  }
  subtitle <- paste(subtitle_parts, collapse = " | ")

  p <- ggplot2::ggplot(km_df, ggplot2::aes(
    x = time, y = surv, color = group
  )) +
    ggplot2::geom_step(linewidth = 0.8) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = lower, ymax = upper, fill = group),
      alpha = 0.15, color = NA, stat = "identity"
    ) +
    ggplot2::scale_y_continuous(
      limits = c(0, 1), labels = scales::percent_format(accuracy = 1)
    ) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = xlab,
      y = "Survival Probability",
      color = if (!is.null(km_result$strata)) km_result$strata else NULL,
      fill = if (!is.null(km_result$strata)) km_result$strata else NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "bottom")

  if (!is.null(time_breaks)) {
    p <- p + ggplot2::scale_x_continuous(breaks = time_breaks)
  }

  # Single group: remove legend
  if (length(unique(km_df$group)) == 1) {
    p <- p + ggplot2::theme(legend.position = "none")
  }

  p
}


#' Plot forest plot of Cox hazard ratios
#'
#' Creates a forest plot from Cox regression results, showing hazard ratios
#' with 95% confidence intervals.
#'
#' @param cox_result List from [run_cox_regression()] with `hazard_ratios`,
#'   `concordance`, `n`, `n_events`
#' @param title Plot title
#' @return A ggplot object
#' @export
plot_forest <- function(cox_result, title = "Cox Regression Forest Plot") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required.")
  }

  if (is.null(cox_result) || is.null(cox_result$hazard_ratios) ||
      nrow(cox_result$hazard_ratios) == 0) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No Cox regression results available") +
             ggplot2::theme_void())
  }

  hr_df <- cox_result$hazard_ratios
  hr_df$variable <- factor(hr_df$variable, levels = rev(hr_df$variable))

  # Significance markers
  hr_df$sig <- ifelse(hr_df$p_value < 0.001, "***",
                       ifelse(hr_df$p_value < 0.01, "**",
                              ifelse(hr_df$p_value < 0.05, "*", "")))
  hr_df$label <- paste0(
    sprintf("%.2f", hr_df$HR),
    " (", sprintf("%.2f", hr_df$HR_lower), "-",
    sprintf("%.2f", hr_df$HR_upper), ")",
    hr_df$sig
  )

  subtitle <- paste0(
    "n = ", cox_result$n, " patients, ",
    cox_result$n_events, " events | ",
    "C-index = ", round(cox_result$concordance, 3)
  )

  ggplot2::ggplot(hr_df, ggplot2::aes(x = HR, y = variable)) +
    ggplot2::geom_vline(xintercept = 1, linetype = "dashed", color = "grey50") +
    ggplot2::geom_point(size = 3) +
    ggplot2::geom_errorbar(
      ggplot2::aes(xmin = HR_lower, xmax = HR_upper),
      width = 0.2, orientation = "y"
    ) +
    ggplot2::geom_text(
      ggplot2::aes(label = label),
      hjust = -0.1, size = 3.2, nudge_y = 0.25
    ) +
    ggplot2::scale_x_log10() +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = "Hazard Ratio (95% CI, log scale)",
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme(plot.margin = ggplot2::margin(5.5, 80, 5.5, 5.5))
}


#' Run KM analysis for each individual cytogenetic marker
#'
#' Iterates over cytogenetic markers and runs stratified KM analysis for each.
#' Markers with fewer than `min_positive` positive cases are skipped.
#'
#' @param surv_data Data frame from [prepare_survival_data()]
#' @param markers Character vector of marker column names. Default auto-detects.
#' @param min_positive Minimum number of positive cases to run analysis (default 3)
#' @return Named list of KM results, one per marker
#' @export
run_km_by_markers <- function(surv_data,
                               markers = NULL,
                               min_positive = 3L) {
  if (is.null(surv_data) || nrow(surv_data) == 0) return(list())

  all_markers <- c("t_4_14", "t_11_14", "t_14_16", "del_17p", "gain_1q")
  if (is.null(markers)) {
    markers <- intersect(all_markers, names(surv_data))
  }

  results <- list()
  for (m in markers) {
    vals <- surv_data[[m]]
    n_pos <- sum(vals == "positive", na.rm = TRUE)
    n_neg <- sum(vals == "negative", na.rm = TRUE)

    if (n_pos >= min_positive && n_neg >= min_positive) {
      results[[m]] <- tryCatch(
        run_kaplan_meier(surv_data, strata = m),
        error = function(e) {
          logger::log_info("KM for {m} failed: {conditionMessage(e)}")
          list(fit = NULL, logrank_p = NA_real_,
               note = paste("Failed:", conditionMessage(e)))
        }
      )
    } else {
      results[[m]] <- list(
        fit = NULL, logrank_p = NA_real_,
        note = paste0("Skipped: ", n_pos, " positive, ", n_neg, " negative")
      )
    }
  }

  results
}
