# R/viz/eda_plots.R
# Named visualization functions for exploratory analysis vignette targets.
# Each function's body is extractable as code provenance via code_vig_* targets.

#' @keywords internal
make_age_histogram <- function(eda_clinical_summary) {
  if (is.null(eda_clinical_summary)) return(NULL)
  clin <- eda_clinical_summary
  if (is.null(clin$age_years) || length(clin$age_years) == 0) return(NULL)

  age_df <- data.frame(age = clin$age_years)
  med_age <- sprintf("%.1f", median(clin$age_years, na.rm = TRUE))

  ggplot2::ggplot(age_df, ggplot2::aes(x = age)) +
    ggplot2::geom_histogram(bins = 30, fill = "steelblue",
                            colour = "white") +
    ggplot2::geom_vline(
      xintercept = median(clin$age_years, na.rm = TRUE),
      linetype = "dashed", colour = "red"
    ) +
    ggplot2::labs(
      x = "Age (years)", y = "Number of Patients",
      title = "Age at Diagnosis",
      subtitle = paste0("n = ", length(clin$age_years),
                        " patients, median = ", med_age, " years"),
      caption = paste0(
        "Age at diagnosis for ", length(clin$age_years), " CoMMpass patients. ",
        "x-axis: age in years (converted from GDC days via / 365.25); ",
        "y-axis: number of patients. ",
        "Median = ", med_age, " years (dashed red line). ",
        "Source: GDC clinical. ",
        "See glossary for age unit conventions; ",
        "survival-analysis Cox models include age as a covariate."
      )
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.caption = ggplot2::element_text(
      size = 7, hjust = 0, lineheight = 1.2
    ))
}

#' @keywords internal
make_count_distribution_plot <- function(raw_rnaseq) {
  if (!file.exists(raw_rnaseq)) return(NULL)
  se <- readRDS(raw_rnaseq)
  if (!inherits(se, "SummarizedExperiment")) return(NULL)

  counts <- get_counts_assay(se)
  log_counts <- log10(counts + 1)
  mean_expr <- rowMeans(log_counts)
  gene_meta <- as.data.frame(SummarizedExperiment::rowData(se))
  has_biotype <- "gene_type" %in% names(gene_meta)

  if (has_biotype) {
    gene_meta$biotype_group <- dplyr::case_when(
      gene_meta$gene_type == "protein_coding" ~ "protein-coding",
      gene_meta$gene_type %in% c(
        "lncRNA", "processed_pseudogene",
        "unprocessed_pseudogene",
        "transcribed_unprocessed_pseudogene",
        "transcribed_processed_pseudogene"
      ) ~ "lncRNA / pseudogene",
      TRUE ~ "other (miRNA, snoRNA, etc.)"
    )
    plot_df <- data.frame(
      mean_expr = mean_expr,
      biotype = gene_meta$biotype_group,
      stringsAsFactors = FALSE
    )
    biotype_colors <- c(
      "protein-coding" = "#0066CC",
      "lncRNA / pseudogene" = "#DC3545",
      "other (miRNA, snoRNA, etc.)" = "#6C757D"
    )
    p <- ggplot2::ggplot(plot_df, ggplot2::aes(
      x = mean_expr, fill = biotype
    )) +
      ggplot2::geom_histogram(
        bins = 50, alpha = 0.6, position = "identity"
      ) +
      ggplot2::scale_fill_manual(values = biotype_colors) +
      ggplot2::labs(
        title = "Distribution of Mean Gene Expression by Biotype",
        subtitle = paste0(
          format(nrow(counts), big.mark = ","), " genes, ",
          ncol(counts), " samples"
        ),
        x = "Mean log10(counts + 1)",
        y = "Number of Genes",
        fill = NULL
      ) +
      ggplot2::theme_minimal()
  } else {
    plot_df <- data.frame(mean_expr = mean_expr)
    p <- ggplot2::ggplot(plot_df, ggplot2::aes(x = mean_expr)) +
      ggplot2::geom_histogram(
        bins = 50, fill = "steelblue", alpha = 0.7
      ) +
      ggplot2::labs(
        title = "Distribution of Mean Gene Expression",
        subtitle = paste0(
          format(nrow(counts), big.mark = ","), " genes, ",
          ncol(counts), " samples"
        ),
        x = "Mean log10(counts + 1)",
        y = "Number of Genes"
      ) +
      ggplot2::theme_minimal()
  }
  p
}

#' @keywords internal
make_gender_table <- function(eda_clinical_summary) {
  if (is.null(eda_clinical_summary)) return(NULL)
  clin <- eda_clinical_summary
  if (is.null(clin$gender_table)) return(NULL)

  gt <- clin$gender_table
  gt$Percentage <- sprintf("%.1f%%", 100 * gt$Freq / sum(gt$Freq))

  caption <- paste0(
    "Gender distribution for ", clin$n_patients,
    " CoMMpass patients. ",
    "Var1 = GDC gender category (male/female). ",
    "Freq = number of patients. ",
    "Percentage = proportion of total cohort. ",
    "Data: GDC clinical ",
    "(https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS)."
  )
  DT::datatable(
    gt, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_race_table <- function(eda_clinical_summary) {
  if (is.null(eda_clinical_summary)) return(NULL)
  clin <- eda_clinical_summary
  if (is.null(clin$race_table)) return(NULL)

  rt <- clin$race_table
  rt$Percentage <- sprintf("%.1f%%", 100 * rt$Freq / sum(rt$Freq))

  caption <- paste0(
    "Race distribution for ", clin$n_patients,
    " CoMMpass patients. ",
    "Var1 = self-reported race category (GDC definitions). ",
    "Freq = number of patients. ",
    "Percentage = proportion of total cohort. ",
    "Categories from GDC clinical data."
  )
  DT::datatable(
    rt, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_vital_table <- function(eda_clinical_summary) {
  if (is.null(eda_clinical_summary)) return(NULL)
  clin <- eda_clinical_summary
  if (is.null(clin$vital_table)) return(NULL)

  vt <- clin$vital_table
  vt$Percentage <- sprintf("%.1f%%", 100 * vt$Freq / sum(vt$Freq))

  caption <- paste0(
    "Vital status for ", clin$n_patients,
    " CoMMpass patients. ",
    "Status = Alive (censored at last follow-up) or Dead (event observed). ",
    "Freq = number of patients. ",
    "Percentage = proportion of total cohort. ",
    "Data: GDC clinical."
  )
  DT::datatable(
    vt, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_iss_table <- function(eda_iss_summary) {
  if (is.null(eda_iss_summary)) return(NULL)
  iss <- eda_iss_summary
  if (!isTRUE(iss$available)) return(NULL)

  caption <- paste0(
    "ISS stage distribution for ", iss$n_with_iss,
    " patients with staging data (",
    iss$n_missing, " missing). ",
    "ISS = International Staging System ",
    "(https://doi.org/10.1200/JCO.2005.04.242). ",
    "Stage I = beta-2 microglobulin < 3.5 mg/L and albumin >= 3.5 g/dL. ",
    "Stage II = not I or III. ",
    "Stage III = beta-2 microglobulin >= 5.5 mg/L. ",
    "Freq = number of patients in each stage."
  )
  DT::datatable(
    iss$iss_table, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_iss_barplot <- function(eda_iss_summary) {
  if (is.null(eda_iss_summary)) return(NULL)
  iss <- eda_iss_summary
  if (!isTRUE(iss$available) || nrow(iss$iss_table) == 0) return(NULL)

  iss_plot <- iss$iss_table[!is.na(iss$iss_table$ISS_Stage), ]
  if (nrow(iss_plot) == 0) return(NULL)

  ggplot2::ggplot(iss_plot, ggplot2::aes(x = ISS_Stage, y = Freq)) +
    ggplot2::geom_col(fill = "steelblue") +
    ggplot2::labs(
      x = "ISS Stage", y = "Number of Patients",
      title = "ISS Stage Distribution",
      subtitle = paste0("n = ", sum(iss_plot$Freq),
                        " patients with staging data"),
      caption = paste0(
        "ISS stage distribution for ", sum(iss_plot$Freq),
        " patients with staging data. ",
        "Stage I: B2M < 3.5 mg/L + albumin >= 3.5 g/dL. ",
        "Stage II: not I or III. Stage III: B2M >= 5.5 mg/L. ",
        "x-axis: ISS stage; y-axis: number of patients. ",
        "Source: ISS (Greipp et al. 2005, doi:10.1200/JCO.2005.04.242). ",
        "See survival-analysis KM curves by ISS for prognostic impact."
      )
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(plot.caption = ggplot2::element_text(
      size = 7, hjust = 0, lineheight = 1.2
    ))
}

#' @keywords internal
make_iss_age_table <- function(eda_iss_summary) {
  if (is.null(eda_iss_summary)) return(NULL)
  iss <- eda_iss_summary
  if (!isTRUE(iss$available) || is.null(iss$age_by_iss)) return(NULL)

  age_tbl <- do.call(rbind, lapply(names(iss$age_by_iss), function(stage) {
    x <- iss$age_by_iss[[stage]]
    data.frame(
      ISS_Stage = stage, N = x$n,
      Mean_Age = sprintf("%.1f", x$mean),
      Median_Age = sprintf("%.1f", x$median),
      SD = sprintf("%.1f", x$sd)
    )
  }))

  caption <- paste0(
    "Age at diagnosis (years) by ISS stage. ",
    "ISS_Stage = International Staging System stage (I/II/III). ",
    "N = number of patients. ",
    "Mean_Age, Median_Age = central tendency in years. ",
    "SD = standard deviation. ",
    "GDC stores age in days; converted via age / 365.25."
  )
  DT::datatable(
    age_tbl, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}
