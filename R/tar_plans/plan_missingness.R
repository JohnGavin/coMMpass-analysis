# R/tar_plans/plan_missingness.R
# Missingness pattern analysis targets

plan_missingness <- list(
  tar_target(
    missingness_profile,
    {
      clin_file <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(clin_file)) return(NULL)
      clin <- arrow::read_parquet(clin_file)
      compute_missingness_profile(clin)
    },
    packages = c("arrow")
  ),

  tar_target(
    missingness_vs_survival,
    {
      if (is.null(survival_data) || is.null(clinical_data)) return(NULL)
      clin_file <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(clin_file)) return(NULL)
      clin <- arrow::read_parquet(clin_file)
      test_missingness_vs_outcome(survival_data, clin, min_missing_pct = 5)
    },
    packages = c("arrow", "survival")
  ),

  # --- Vignette targets ---
  tar_target(
    vig_missingness_heatmap,
    {
      if (is.null(missingness_profile)) return(NULL)
      pv <- missingness_profile$per_variable
      pv <- pv[pv$pct_missing > 0, ]
      if (nrow(pv) == 0) return(NULL)

      # Grouped bar chart of missingness by category
      p <- ggplot2::ggplot(pv, ggplot2::aes(
        x = stats::reorder(variable, pct_missing),
        y = pct_missing, fill = category
      )) +
        ggplot2::geom_col() +
        ggplot2::coord_flip() +
        ggplot2::facet_wrap(~category, scales = "free_y", ncol = 1) +
        ggplot2::labs(
          title = "Variable Missingness by Category",
          x = NULL, y = "% Missing",
          caption = paste0(
            "Percentage of patients with missing values for each clinical variable. ",
            "Faceted by variable category (demographic, staging, FISH, biomarker, outcome, treatment). ",
            "Variables with 0% missing excluded. ",
            "N = ", missingness_profile$n_patients, " patients, ",
            missingness_profile$n_variables, " variables. ",
            "Source: GDC clinical data."
          )
        ) +
        ggplot2::theme_minimal(base_size = 9) +
        ggplot2::theme(
          axis.text.y = ggplot2::element_text(size = 7),
          strip.text = ggplot2::element_text(face = "bold"),
          plot.caption = ggplot2::element_text(size = 7, hjust = 0, lineheight = 1.2)
        )
      ggplot2::ggplotGrob(p)
    },
    packages = c("ggplot2")
  ),

  tar_target(
    vig_missingness_summary_table,
    {
      if (is.null(missingness_profile)) return(NULL)
      pv <- missingness_profile$per_variable
      pv <- pv[pv$pct_missing > 0, c("variable", "category", "n_missing", "pct_missing")]
      names(pv) <- c("Variable", "Category", "N Missing", "% Missing")
      DT::datatable(pv, rownames = FALSE,
        options = list(pageLength = 20, dom = "tip",
                       order = list(list(3, "desc"))),
        caption = htmltools::tags$caption(
          style = "caption-side: bottom; text-align: left;",
          paste0("Variables with any missingness in the clinical dataset. ",
                 "Category = variable group (demographic/staging/FISH/biomarker/outcome). ",
                 "N = ", missingness_profile$n_patients, " patients. ",
                 "Source: GDC clinical data via TCGAbiolinks.")))
    },
    packages = c("DT", "htmltools")
  ),

  tar_target(
    vig_missingness_vs_survival_table,
    {
      if (is.null(missingness_vs_survival)) return(NULL)
      if (nrow(missingness_vs_survival) == 0) return(NULL)
      DT::datatable(missingness_vs_survival, rownames = FALSE,
        options = list(pageLength = 15, dom = "tip",
                       order = list(list(3, "asc"))),
        caption = htmltools::tags$caption(
          style = "caption-side: bottom; text-align: left;",
          paste0("Cox regression: Surv(time, status) ~ is_missing(variable). ",
                 "Tests whether patients with missing data have different survival. ",
                 "HR > 1 = missing → worse survival; HR < 1 = missing → better. ",
                 "MNAR = missingness not at random (clinically informative). ",
                 "Only variables with >= 5% missingness tested.")))
    },
    packages = c("DT", "htmltools")
  )
)
