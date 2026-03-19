# R/14_bayesian_survival.R
# Bayesian survival models using brms

#' Fit a Bayesian Cox proportional hazards model
#'
#' Fits a Bayesian Cox PH model using brms with weakly informative priors.
#' Uses the `cox` family with right-censoring.
#'
#' @param survival_data Data frame with time_days, status, and covariates
#' @param covariates Character vector of covariate names
#' @param hierarchical Character. If non-NULL, fit random intercepts by this variable.
#' @param chains Integer. Number of MCMC chains (default 2 for speed).
#' @param iter Integer. Total iterations per chain (default 2000).
#' @param seed Integer. Random seed.
#' @return A brmsfit object, or NULL if brms is not available.
#' @export
fit_bayesian_cox <- function(survival_data, covariates = c("age_years", "gender"),
                             hierarchical = NULL, chains = 2, iter = 2000,
                             seed = 42) {
  if (!requireNamespace("brms", quietly = TRUE)) {
    cli::cli_warn("Package {.pkg brms} not installed — skipping Bayesian model")
    return(NULL)
  }

  sd <- survival_data[complete.cases(survival_data[, c("time_days", "status", covariates),
                                                    drop = FALSE]), ]
  if (nrow(sd) < 20) {
    cli::cli_warn("Too few complete cases ({nrow(sd)}) for Bayesian Cox model")
    return(NULL)
  }

  # brms censoring: cens(1) = right-censored, cens(0) = event
  # Our status: 1 = event, 0 = censored → brms wants the opposite
  sd$censored <- 1L - sd$status

  # Build formula
  rhs <- paste(covariates, collapse = " + ")
  if (!is.null(hierarchical) && hierarchical %in% names(sd)) {
    rhs <- paste0(rhs, " + (1 | ", hierarchical, ")")
  }
  form <- stats::as.formula(
    paste0("time_days | cens(censored) ~ ", rhs)
  )

  logger::log_info("Fitting Bayesian Cox: {deparse(form)}")
  logger::log_info("Data: {nrow(sd)} patients, {sum(sd$status)} events")

  fit <- tryCatch(
    brms::brm(
      formula = form,
      data = sd,
      family = brms::cox(),
      chains = chains,
      iter = iter,
      seed = seed,
      silent = 2,
      refresh = 0
    ),
    error = function(e) {
      cli::cli_warn("brms model failed: {conditionMessage(e)}")
      NULL
    }
  )

  fit
}


#' Compare Bayesian and frequentist Cox model results
#'
#' Creates a comparison table of hazard ratios from frequentist (coxph)
#' and Bayesian (brms) Cox models.
#'
#' @param freq_result List from [run_cox_regression()]
#' @param bayes_fit A brmsfit object from [fit_bayesian_cox()]
#' @return Data frame comparing HRs, CIs, and significance
#' @export
compare_bayesian_frequentist <- function(freq_result, bayes_fit) {
  if (is.null(freq_result) || is.null(bayes_fit)) return(NULL)

  # Frequentist results
  freq_coefs <- tryCatch({
    s <- summary(freq_result$fit)
    data.frame(
      Covariate = rownames(s$coefficients),
      Freq_HR = round(exp(s$coefficients[, "coef"]), 3),
      Freq_CI = paste0("[",
        round(s$conf.int[, "lower .95"], 3), ", ",
        round(s$conf.int[, "upper .95"], 3), "]"),
      Freq_p = signif(s$coefficients[, "Pr(>|z|)"], 3),
      stringsAsFactors = FALSE
    )
  }, error = function(e) NULL)

  if (is.null(freq_coefs)) return(NULL)

  # Bayesian results
  bayes_coefs <- tryCatch({
    post <- brms::fixef(bayes_fit)
    data.frame(
      Covariate = rownames(post),
      Bayes_HR = round(exp(post[, "Estimate"]), 3),
      Bayes_CI = paste0("[",
        round(exp(post[, "Q2.5"]), 3), ", ",
        round(exp(post[, "Q97.5"]), 3), "]"),
      Bayes_Rhat = round(post[, "Rhat"] %||% NA_real_, 3),
      stringsAsFactors = FALSE
    )
  }, error = function(e) NULL)

  if (is.null(bayes_coefs)) return(NULL)

  # Merge
  # Remove intercept from Bayesian (Cox has no intercept in freq)
  bayes_coefs <- bayes_coefs[bayes_coefs$Covariate != "Intercept", ]

  merged <- merge(freq_coefs, bayes_coefs, by = "Covariate", all = TRUE)
  merged
}
