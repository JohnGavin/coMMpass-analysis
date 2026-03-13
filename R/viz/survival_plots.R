# R/viz/survival_plots.R
# Named visualization functions for survival analysis vignette targets.
# Each function's body is extractable as code provenance via code_vig_* targets.

#' @keywords internal
make_cox_basic_table <- function(cox_basic) {
  if (is.null(cox_basic) || is.null(cox_basic$hazard_ratios)) return(NULL)

  hr <- cox_basic$hazard_ratios
  for (col in names(hr)) {
    if (is.numeric(hr[[col]])) {
      hr[[col]] <- if (col == "p.value") signif(hr[[col]], 4)
                   else round(hr[[col]], 3)
    }
  }
  caption <- paste0(
    "Cox PH model: age + gender. ",
    "term = covariate name. ",
    "HR (hazard ratio) > 1 = increased hazard (worse survival). ",
    "CI = 95% confidence interval for HR. ",
    "p.value = Wald test significance. ",
    "n = ", cox_basic$n, " patients, ",
    cox_basic$n_events, " events. C-index = ",
    round(cox_basic$concordance, 3), ". ",
    "* p < 0.05, ** p < 0.01, *** p < 0.001."
  )
  DT::datatable(
    hr, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 15, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_cox_full_table <- function(cox_full) {
  if (is.null(cox_full) || is.null(cox_full$hazard_ratios)) return(NULL)

  hr <- cox_full$hazard_ratios
  for (col in names(hr)) {
    if (is.numeric(hr[[col]])) {
      hr[[col]] <- if (col == "p.value") signif(hr[[col]], 4)
                   else round(hr[[col]], 3)
    }
  }
  caption <- paste0(
    "Multivariate Cox PH model with clinical and cytogenetic covariates. ",
    "term = covariate name. ",
    "HR > 1 = increased hazard (worse survival). ",
    "CI = 95% confidence interval. ",
    "n = ", cox_full$n, " patients, ", cox_full$n_events, " events. ",
    "C-index = ", round(cox_full$concordance, 3), ". ",
    "Covariates: ",
    paste(cox_full$covariates_used, collapse = ", "), "."
  )
  DT::datatable(
    hr, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 15, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_ph_test_table <- function(cox_full, cox_basic) {
  cox_for_ph <- if (!is.null(cox_full)) cox_full else cox_basic
  if (is.null(cox_for_ph) || is.null(cox_for_ph$ph_test)) return(NULL)

  ph <- cox_for_ph$ph_test
  ph_table <- as.data.frame(ph$table)
  ph_table$variable <- rownames(ph_table)
  ph_table <- ph_table[, c("variable", "chisq", "p")]
  names(ph_table) <- c("Variable", "Chi-squared", "p-value")
  ph_table$`Chi-squared` <- round(ph_table$`Chi-squared`, 2)
  ph_table$`p-value` <- signif(ph_table$`p-value`, 4)

  caption <- paste0(
    "Proportional hazards assumption test (cox.zph). ",
    "Variable = covariate tested. ",
    "Chi-squared = Schoenfeld residual test statistic. ",
    "p-value < 0.05 indicates the PH assumption may be violated ",
    "(hazard ratio changes over time). ",
    "If violated, time-varying coefficients or stratification ",
    "should be considered."
  )
  DT::datatable(
    ph_table, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 15, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_cox_comparison <- function(cox_basic, cox_full) {
  if (is.null(cox_basic) || is.null(cox_full)) return(NULL)
  if (is.null(cox_basic$concordance) ||
      is.null(cox_full$concordance)) return(NULL)

  comp <- data.frame(
    Model = c(
      "Basic (age + gender)",
      paste0("Full (",
             paste(cox_full$covariates_used, collapse = " + "), ")")
    ),
    N = c(cox_basic$n, cox_full$n),
    Events = c(cox_basic$n_events, cox_full$n_events),
    C_index = c(round(cox_basic$concordance, 3),
                round(cox_full$concordance, 3)),
    stringsAsFactors = FALSE
  )

  caption <- paste0(
    "Cox model comparison. ",
    "Model = covariates included. ",
    "N = patients with complete data for all covariates. ",
    "Events = observed deaths. ",
    "C-index = concordance statistic ",
    "(0.5 = random, 1.0 = perfect discrimination). ",
    "Higher C-index indicates better prognostic discrimination."
  )
  DT::datatable(
    comp, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    colnames = c("Model", "N", "Events", "C-index"),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}
