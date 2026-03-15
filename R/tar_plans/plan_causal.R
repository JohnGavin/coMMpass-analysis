# R/tar_plans/plan_causal.R
# Causal DAG analysis targets

plan_causal <- list(
  tar_target(
    causal_dag,
    commpass_dag(),
    packages = c("dagitty")
  ),

  tar_target(
    causal_dag_plot,
    {
      if (!requireNamespace("ggdag", quietly = TRUE)) return(NULL)
      p <- plot_dag(causal_dag)
      ggplot2::ggplotGrob(p)
    },
    packages = c("ggdag", "ggplot2")
  ),

  tar_target(
    causal_adjustment_sets,
    {
      analyses <- list(
        cyto_survival = list(exposure = "cytogenetic_risk",
                             outcome = "overall_survival"),
        treatment_survival = list(exposure = "treatment",
                                  outcome = "overall_survival"),
        iss_survival = list(exposure = "iss_stage",
                            outcome = "overall_survival"),
        expression_survival = list(exposure = "gene_expression",
                                   outcome = "overall_survival")
      )
      lapply(analyses, function(a) {
        sets <- get_adjustment_sets(a$exposure, a$outcome, causal_dag)
        list(
          exposure = a$exposure,
          outcome = a$outcome,
          adjustment_sets = lapply(sets, as.character)
        )
      })
    },
    packages = c("dagitty")
  ),

  tar_target(
    causal_model_checks,
    {
      # Check current Cox models against DAG recommendations
      list(
        cox_age_iss = check_adjustment(
          model_covariates = c("age", "iss_stage"),
          exposure = "cytogenetic_risk",
          outcome = "overall_survival",
          dag = causal_dag
        ),
        cox_full = check_adjustment(
          model_covariates = c("age", "gender", "iss_stage"),
          exposure = "cytogenetic_risk",
          outcome = "overall_survival",
          dag = causal_dag
        )
      )
    },
    packages = c("dagitty")
  ),

  # Vignette targets
  tar_target(
    vig_causal_dag_plot,
    causal_dag_plot
  ),

  tar_target(
    vig_causal_adjustment_table,
    {
      if (is.null(causal_adjustment_sets)) return(NULL)
      rows <- lapply(names(causal_adjustment_sets), function(nm) {
        a <- causal_adjustment_sets[[nm]]
        sets_text <- if (length(a$adjustment_sets) == 0) {
          "Not identifiable"
        } else {
          paste(vapply(a$adjustment_sets, function(s) {
            paste0("{", paste(s, collapse = ", "), "}")
          }, character(1)), collapse = " or ")
        }
        data.frame(
          Analysis = nm,
          Exposure = a$exposure,
          Outcome = a$outcome,
          `Minimal Adjustment Sets` = sets_text,
          check.names = FALSE,
          stringsAsFactors = FALSE
        )
      })
      df <- do.call(rbind, rows)
      DT::datatable(df, rownames = FALSE,
                    caption = htmltools::tags$caption(
                      style = "caption-side: bottom; text-align: left;",
                      "DAG-implied minimal sufficient adjustment sets for each causal question. ",
                      "Each set blocks all backdoor paths between exposure and outcome. ",
                      "Source: dagitty::adjustmentSets() applied to the CoMMpass causal DAG."
                    ))
    },
    packages = c("DT", "htmltools")
  ),

  tar_target(
    vig_causal_model_check_table,
    {
      if (is.null(causal_model_checks)) return(NULL)
      rows <- lapply(names(causal_model_checks), function(nm) {
        chk <- causal_model_checks[[nm]]
        data.frame(
          Model = nm,
          Covariates = paste(chk$model_covariates, collapse = ", "),
          Sufficient = chk$sufficient,
          Recommendation = chk$recommendation,
          stringsAsFactors = FALSE
        )
      })
      df <- do.call(rbind, rows)
      DT::datatable(df, rownames = FALSE,
                    caption = htmltools::tags$caption(
                      style = "caption-side: bottom; text-align: left;",
                      "Comparison of current Cox model covariates against DAG-implied adjustment sets. ",
                      "Sufficient = TRUE means the model adjusts for all confounders on at least one backdoor path."
                    ))
    },
    packages = c("DT", "htmltools")
  )
)
