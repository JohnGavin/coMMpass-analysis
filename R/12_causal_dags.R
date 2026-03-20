# R/12_causal_dags.R
# Causal DAG definitions for CoMMpass multiple myeloma analysis

#' Define the CoMMpass causal DAG
#'
#' Encodes domain-knowledge causal assumptions for the CoMMpass multiple
#' myeloma analysis. Nodes represent measured or latent variables; edges
#' represent assumed causal effects.
#'
#' @return A `dagitty::dagitty` DAG object
#' @export
commpass_dag <- function() {
  if (!requireNamespace("dagitty", quietly = TRUE)) {
    cli::cli_abort(c(
      "x" = "Package {.pkg dagitty} required for causal DAG analysis",
      "i" = "Available in the Nix shell"
    ))
  }

  dagitty::dagitty(paste(
    "dag {",
    "cytogenetic_risk [exposure]",
    "overall_survival [outcome]",
    "age [adjusted]",
    "gender",
    "iss_stage",
    "gene_expression",
    "treatment",
    "treatment_response",
    "tumor_biology [latent]",
    "comorbidities [latent]",
    "age -> comorbidities",
    "age -> treatment",
    "age -> overall_survival",
    "gender -> comorbidities",
    "tumor_biology -> cytogenetic_risk",
    "tumor_biology -> gene_expression",
    "tumor_biology -> iss_stage",
    "cytogenetic_risk -> iss_stage",
    "cytogenetic_risk -> treatment",
    "cytogenetic_risk -> gene_expression",
    "cytogenetic_risk -> overall_survival",
    "iss_stage -> treatment",
    "iss_stage -> overall_survival",
    "comorbidities -> treatment",
    "comorbidities -> overall_survival",
    "treatment -> treatment_response",
    "treatment -> overall_survival",
    "treatment_response -> overall_survival",
    "gene_expression -> overall_survival",
    "}",
    sep = " ; "
  ))
}


#' Get adjustment sets for a given analysis
#'
#' Uses the DAG to identify the minimal sufficient adjustment set for
#' estimating the causal effect of `exposure` on `outcome`.
#'
#' @param exposure Character. The exposure variable name in the DAG.
#' @param outcome Character. The outcome variable name in the DAG.
#' @param dag A `dagitty` DAG object. Defaults to [commpass_dag()].
#' @return A list of character vectors, each a minimal sufficient adjustment set.
#' @export
get_adjustment_sets <- function(exposure = "cytogenetic_risk",
                                outcome = "overall_survival",
                                dag = NULL) {
  if (is.null(dag)) dag <- commpass_dag()
  dagitty::adjustmentSets(dag, exposure = exposure, outcome = outcome,
                          type = "minimal")
}


#' Plot the CoMMpass causal DAG
#'
#' Renders the DAG using ggdag with sensible defaults.
#'
#' @param dag A `dagitty` DAG object. Defaults to [commpass_dag()].
#' @param title Plot title.
#' @return A ggplot object.
#' @export
plot_dag <- function(dag = NULL,
                     title = "CoMMpass Causal DAG") {
  if (is.null(dag)) dag <- commpass_dag()
  if (!requireNamespace("ggdag", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggdag} required for DAG plots")
  }

  ggdag::ggdag(dag, text = TRUE, use_labels = "name") +
    ggdag::theme_dag() +
    ggplot2::labs(
      title = title,
      caption = paste(
        "Nodes: measured and latent variables in CoMMpass analysis.",
        "Edges: assumed causal effects based on domain knowledge.",
        "Latent variables (dashed): tumor biology, comorbidities.",
        "Use dagitty::adjustmentSets() to identify confounders."
      )
    ) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#1a1a2e", color = NA),
      panel.background = ggplot2::element_rect(fill = "#1a1a2e", color = NA),
      text = ggplot2::element_text(color = "white"),
      plot.title = ggplot2::element_text(color = "white"),
      plot.caption = ggplot2::element_text(size = 7, hjust = 0, lineheight = 1.2, color = "grey80")
    )
}


#' Compare model covariates against DAG-implied adjustments
#'
#' Checks whether the covariates used in a model match any of the
#' DAG-implied minimal sufficient adjustment sets.
#'
#' @param model_covariates Character vector of covariates used in the model.
#' @param exposure Character. Exposure variable.
#' @param outcome Character. Outcome variable.
#' @param dag A `dagitty` DAG object.
#' @return A list with `$sufficient` (logical), `$model_covariates`,
#'   `$adjustment_sets`, and `$recommendation`.
#' @export
check_adjustment <- function(model_covariates,
                             exposure = "cytogenetic_risk",
                             outcome = "overall_survival",
                             dag = NULL) {
  if (is.null(dag)) dag <- commpass_dag()
  adj_sets <- get_adjustment_sets(exposure, outcome, dag)
  adj_list <- lapply(adj_sets, as.character)

  # Check if model covariates are a superset of any minimal set
  sufficient <- any(vapply(adj_list, function(s) {
    all(s %in% model_covariates)
  }, logical(1)))

  recommendation <- if (sufficient) {
    "Model covariates include a sufficient adjustment set."
  } else if (length(adj_list) == 0) {
    "No adjustment set exists (effect may not be identifiable)."
  } else {
    missing <- setdiff(adj_list[[1]], model_covariates)
    paste0("Consider adding: ", paste(missing, collapse = ", "),
           " (from minimal adjustment set).")
  }

  list(
    sufficient = sufficient,
    model_covariates = model_covariates,
    adjustment_sets = adj_list,
    recommendation = recommendation
  )
}
