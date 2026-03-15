# R/tar_plans/plan_survival_analysis.R
# Survival analysis targets using real clinical + cytogenetic data

plan_survival_analysis <- list(

  # Prepare survival data from cleaned clinical + cytogenetic data
  tar_target(
    survival_data,
    {
      # clinical_data_clean is a data frame; cytogenetic_data is a file path
      cyto_path <- NULL
      if (is.character(cytogenetic_data) && file.exists(cytogenetic_data)) {
        cyto_path <- cytogenetic_data
      }
      prepare_survival_data(clinical_data_clean, cyto_file = cyto_path)
    },
    packages = c("survival")
  ),

  # Overall Kaplan-Meier (no stratification)
  tar_target(
    km_overall,
    run_kaplan_meier(survival_data, strata = NULL),
    packages = c("survival")
  ),

  # KM by cytogenetic risk group (high vs standard)
  tar_target(
    km_by_risk,
    {
      if ("risk_group" %in% names(survival_data) &&
          sum(!is.na(survival_data$risk_group)) >= 5) {
        run_kaplan_meier(survival_data, strata = "risk_group")
      } else {
        list(fit = NULL, logrank_p = NA_real_,
             note = "Cytogenetic risk data not available or too few patients")
      }
    },
    packages = c("survival")
  ),

  # KM by ISS stage
  tar_target(
    km_by_iss,
    {
      if ("iss_stage" %in% names(survival_data) &&
          sum(!is.na(survival_data$iss_stage)) >= 5) {
        run_kaplan_meier(survival_data, strata = "iss_stage")
      } else {
        list(fit = NULL, logrank_p = NA_real_,
             note = "ISS stage data not available or too few patients")
      }
    },
    packages = c("survival")
  ),

  # Cox regression: age + gender
  tar_target(
    cox_basic,
    run_cox_regression(
      survival_data,
      covariates = c("age_years", "gender")
    ),
    packages = c("survival")
  ),

  # Cox regression: age + gender + ISS + cytogenetic risk
  tar_target(
    cox_full,
    {
      covs <- c("age_years", "gender")
      if ("iss_stage" %in% names(survival_data) &&
          sum(!is.na(survival_data$iss_stage)) >= 10) {
        covs <- c(covs, "iss_stage")
      }
      if ("risk_group" %in% names(survival_data) &&
          sum(!is.na(survival_data$risk_group)) >= 10) {
        covs <- c(covs, "risk_group")
      }
      run_cox_regression(survival_data, covariates = covs)
    },
    packages = c("survival")
  ),

  # KM by individual cytogenetic markers
  tar_target(
    km_by_markers,
    run_km_by_markers(survival_data, min_positive = 3L),
    packages = c("survival")
  ),

  # KM by gene expression: top 5 DE genes, median split (#53)
  tar_target(
    km_by_expression,
    {
      if (is.null(vst_counts) || is.null(consensus_de_genes)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")

      top_genes <- if (is.data.frame(consensus_de_genes)) {
        head(consensus_de_genes$gene, 5)
      } else if (is.character(consensus_de_genes)) {
        head(consensus_de_genes, 5)
      } else if (is.list(consensus_de_genes) &&
                 !is.null(consensus_de_genes$consensus_genes)) {
        head(consensus_de_genes$consensus_genes, 5)
      } else {
        return(NULL)
      }

      available <- intersect(top_genes, rownames(vst_mat))
      if (length(available) == 0) return(NULL)

      result <- lapply(stats::setNames(available, available), function(g) {
        run_km_by_expression(survival_data, vst_mat, gene = g,
                             split = "median")
      })
      rm(vst_counts, vst_mat)
      result
    },
    packages = c("survival")
  ),

  # Expression by cytogenetic subtype: top 5 DE genes (#54)
  tar_target(
    expr_by_subtype,
    {
      if (is.null(vst_counts) || is.null(consensus_de_genes)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")

      cyto_path <- NULL
      if (is.character(cytogenetic_data) && file.exists(cytogenetic_data)) {
        cyto_path <- cytogenetic_data
      }
      if (is.null(cyto_path)) return(NULL)
      cyto <- arrow::read_parquet(cyto_path)

      top_genes <- if (is.data.frame(consensus_de_genes)) {
        head(consensus_de_genes$gene, 5)
      } else if (is.character(consensus_de_genes)) {
        head(consensus_de_genes, 5)
      } else if (is.list(consensus_de_genes) &&
                 !is.null(consensus_de_genes$consensus_genes)) {
        head(consensus_de_genes$consensus_genes, 5)
      } else {
        return(NULL)
      }

      available <- intersect(top_genes, rownames(vst_mat))
      if (length(available) == 0) return(NULL)

      result <- lapply(stats::setNames(available, available), function(g) {
        p <- plot_expression_by_subtype(vst_mat, cyto, gene = g)
        # Convert to grob to strip ggplot2 S7 env overhead (9 MB → <1 KB)
        ggplot2::ggplotGrob(p)
      })
      rm(vst_counts, vst_mat, cyto)
      result
    }
  )
)
