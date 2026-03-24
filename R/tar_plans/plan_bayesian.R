# R/tar_plans/plan_bayesian.R
# Bayesian survival analysis targets

plan_bayesian <- list(
  # Basic Bayesian Cox: age + gender (comparable to shiny_cox_os_age_risk)
  tar_target(
    bayes_cox_basic,
    {
      if (!requireNamespace("brms", quietly = TRUE)) return(NULL)
      fit_bayesian_cox(survival_data,
                       covariates = c("age_years", "gender"),
                       chains = 2, iter = 2000, seed = 42)
    },
    packages = c("brms"),
    deployment = "main",
    cue = tar_cue(mode = "never")  # Only run on explicit request
  ),

  # Hierarchical Bayesian Cox: age + gender with ISS random intercepts
  tar_target(
    bayes_cox_hierarchical,
    {
      if (!requireNamespace("brms", quietly = TRUE)) return(NULL)
      fit_bayesian_cox(survival_data,
                       covariates = c("age_years", "gender"),
                       hierarchical = "iss_stage",
                       chains = 2, iter = 2000, seed = 42)
    },
    packages = c("brms"),
    deployment = "main",
    cue = tar_cue(mode = "never")
  ),

  # Frequentist Cox with same covariates as Bayesian (age + gender)
  tar_target(
    freq_cox_age_gender,
    {
      tryCatch(
        run_cox_regression(survival_data, covariates = c("age_years", "gender")),
        error = function(e) NULL
      )
    },
    packages = c("survival")
  ),

  # Comparison table: frequentist vs Bayesian (same covariates)
  tar_target(
    bayes_freq_comparison,
    {
      if (is.null(bayes_cox_basic) || is.null(freq_cox_age_gender)) return(NULL)
      compare_bayesian_frequentist(freq_cox_age_gender, bayes_cox_basic)
    }
  ),

  # --- Vignette targets ---
  tar_target(
    vig_bayes_freq_table,
    {
      if (is.null(bayes_freq_comparison)) return(NULL)
      DT::datatable(bayes_freq_comparison, rownames = FALSE,
        options = list(dom = "t", paging = FALSE),
        caption = htmltools::tags$caption(
          style = "caption-side: bottom; text-align: left;",
          "Comparison of frequentist (coxph) and Bayesian (brms) Cox PH model estimates. ",
          "HR = hazard ratio; CI = 95% confidence/credible interval. ",
          "Bayesian model uses weakly informative priors (brms default). ",
          "Rhat < 1.01 indicates MCMC convergence."
        ))
    },
    packages = c("DT", "htmltools")
  ),

  tar_target(
    vig_bayes_diagnostics,
    {
      if (is.null(bayes_cox_basic)) return(NULL)
      # Summary diagnostics
      post <- brms::fixef(bayes_cox_basic)
      rhat <- if ("Rhat" %in% colnames(post)) round(post[, "Rhat"], 3) else NA_real_
      data.frame(
        Parameter = rownames(post),
        Estimate = round(post[, "Estimate"], 4),
        SE = round(post[, "Est.Error"], 4),
        Rhat = rhat,
        stringsAsFactors = FALSE
      )
    },
    packages = c("brms")
  )
)
