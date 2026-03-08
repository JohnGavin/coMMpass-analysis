# R/tar_plans/plan_vignette_outputs.R
# Pre-compute ALL vignette display objects as targets.
# Every non-setup chunk in every vignette is exactly:
#   safe_tar_read("vig_*")
# This file produces the final rendered objects (ggplot, DT, kable-ready df).

plan_vignette_outputs <- list(

  # ================================================================
  # data-acquisition.Rmd targets
  # ================================================================

  # --- Pipeline config text block ---
  tar_target(
    vig_config_text,
    {
      if (is.null(config)) return(NULL)
      paste0(
        "The pipeline downloads RNA-seq and clinical data from the ",
        "GDC portal (https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS) ",
        "for the ", config$project_id, " project.\n\n",
        "Sample limit: ", config$sample_limit,
        " patients (GDC has ~900; subsetting speeds local development). ",
        "In CI, this is capped at 10 samples ",
        "(see R/01_data_acquisition.R) to keep build times under ",
        "5 minutes.\n\n",
        "Random seed: ", config$seed,
        " --- ensures reproducible patient selection when ",
        "random_sample = TRUE.\n\n",
        "Data directory: ", config$data_dir,
        " | Results directory: ", config$results_dir
      )
    }
  ),

  # --- RNA-seq summary text ---
  tar_target(
    vig_rnaseq_summary_text,
    {
      if (is.null(eda_rnaseq_summary)) return(NULL)
      rna <- eda_rnaseq_summary
      paste0(
        "### RNA-seq Data Summary\n\n",
        "- **Samples:** ", rna$n_samples, "\n",
        "- **Genes:** ", format(rna$n_genes, big.mark = ","), "\n",
        "- **Total counts:** ",
        format(rna$total_counts, big.mark = ","),
        " (sum of all read counts across all genes and samples)\n",
        "- **Median counts per sample:** ",
        format(rna$median_library_size, big.mark = ","),
        " (median library size)\n",
        "- **Sparsity (% zero entries):** ",
        sprintf("%.1f%%", 100 * rna$sparsity), "\n"
      )
    }
  ),

  # --- Per-sample RNA-seq stats DT ---
  tar_target(
    vig_rnaseq_sample_stats,
    {
      if (!file.exists(raw_rnaseq)) return(NULL)
      se <- readRDS(raw_rnaseq)
      if (!inherits(se, "SummarizedExperiment")) return(NULL)

      assay_names <- SummarizedExperiment::assayNames(se)
      counts <- get_counts_assay(se)

      sample_stats <- data.frame(
        Sample = colnames(counts),
        Total_Counts = colSums(counts),
        Genes_Detected = colSums(counts > 0),
        Median_Count = round(apply(counts, 2, median), 1),
        Max_Count = apply(counts, 2, max),
        stringsAsFactors = FALSE
      )

      n_samples <- ncol(counts)
      caption <- paste0(
        "Per-sample RNA-seq summary for ", n_samples, " samples. ",
        "Total Counts = library size (sum of all read counts for one sample). ",
        "Genes Detected = number of genes with at least 1 mapped read. ",
        "Sample IDs are GDC barcodes. ",
        "Data: GDC STAR-Counts pipeline. ",
        "This table is NOT repeated in the QC section; see ",
        "Quality Control for outlier flags and size factors."
      )

      DT::datatable(
        sample_stats,
        filter = "top",
        options = list(pageLength = 10, scrollX = TRUE),
        colnames = c("Sample", "Total Counts (library size)",
                      "Genes Detected (count > 0)",
                      "Median Count", "Max Count"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          caption
        )
      )
    },
    packages = c("SummarizedExperiment", "DT", "htmltools")
  ),

  # --- Count distribution plotly/ggplot ---
  tar_target(
    vig_count_distribution_plot,
    {
      if (!file.exists(raw_rnaseq)) return(NULL)
      se <- readRDS(raw_rnaseq)
      if (!inherits(se, "SummarizedExperiment")) return(NULL)

      assay_names <- SummarizedExperiment::assayNames(se)
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
        p <- plotly::plot_ly(alpha = 0.6) |>
          plotly::add_histogram(
            data = dplyr::filter(plot_df, biotype == "protein-coding"),
            x = ~mean_expr, name = "protein-coding",
            marker = list(color = "#0066CC"), nbinsx = 50
          ) |>
          plotly::add_histogram(
            data = dplyr::filter(plot_df, biotype == "lncRNA / pseudogene"),
            x = ~mean_expr, name = "lncRNA / pseudogene",
            marker = list(color = "#DC3545"), nbinsx = 50
          ) |>
          plotly::add_histogram(
            data = dplyr::filter(
              plot_df, biotype == "other (miRNA, snoRNA, etc.)"
            ),
            x = ~mean_expr, name = "other (miRNA, snoRNA, etc.)",
            marker = list(color = "#6C757D"), nbinsx = 50
          ) |>
          plotly::layout(
            barmode = "overlay",
            title = list(text = paste0(
              "Distribution of Mean Gene Expression by Biotype<br>",
              "<sup>", format(nrow(counts), big.mark = ","), " genes, ",
              ncol(counts), " samples</sup>"
            )),
            xaxis = list(title = "Mean log10(counts + 1)"),
            yaxis = list(title = "Number of Genes"),
            bargap = 0.05
          )
      } else {
        plot_df <- data.frame(mean_expr = mean_expr)
        p <- plotly::plot_ly(
          x = mean_expr, type = "histogram", nbinsx = 50,
          marker = list(color = "steelblue"), name = "Gene Expression"
        ) |>
          plotly::layout(
            title = list(text = paste0(
              "Distribution of Mean Gene Expression<br>",
              "<sup>", format(nrow(counts), big.mark = ","), " genes, ",
              ncol(counts), " samples</sup>"
            )),
            xaxis = list(title = "Mean log10(counts + 1)"),
            yaxis = list(title = "Number of Genes"),
            bargap = 0.05
          )
      }
      strip_plotly(p)
    },
    packages = c("SummarizedExperiment", "plotly", "dplyr")
  ),

  # --- Clinical column structure DT (data-acquisition) ---
  tar_target(
    vig_clinical_column_info,
    {
      pq_path <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(pq_path)) return(NULL)
      clin <- arrow::read_parquet(pq_path)
      if (!is.data.frame(clin) || nrow(clin) == 0) return(NULL)
      names(clin) <- make.unique(names(clin))

      n_patients <- nrow(clin)
      summary_text <- paste0(
        "### Clinical Data Overview\n\n",
        "- **Total patients:** ", format(n_patients, big.mark = ","), "\n",
        "- **Number of variables:** ", ncol(clin), "\n",
        "- **Data completeness:** ",
        sprintf("%.1f%%", 100 * mean(!is.na(clin))), "\n\n",
        "### Column Structure\n\n",
        "All ", ncol(clin), " columns with type, completeness, and ",
        "example values. Columns grouped by similarity.\n"
      )

      col_info <- data.frame(
        Column = names(clin),
        Type = vapply(clin, function(x) class(x)[1], character(1)),
        Non_NA = vapply(clin, function(x) sum(!is.na(x)), integer(1)),
        Pct_Complete = vapply(
          clin, function(x) sprintf("%.0f%%", 100 * mean(!is.na(x))),
          character(1)
        ),
        N_Unique = vapply(
          clin, function(x) length(unique(x[!is.na(x)])),
          integer(1)
        ),
        Example = vapply(clin, function(x) {
          vals <- x[!is.na(x)]
          if (length(vals) == 0) return("(all NA)")
          if (is.numeric(vals)) {
            paste0("min=", signif(min(vals), 3),
                   " med=", signif(median(vals), 3),
                   " max=", signif(max(vals), 3))
          } else {
            vals_chr <- as.character(vals)
            top <- names(sort(table(vals_chr), decreasing = TRUE))[
              1:min(3, length(unique(vals_chr)))
            ]
            paste(top, collapse = ", ")
          }
        }, character(1)),
        stringsAsFactors = FALSE
      )

      unit_map <- c(
        age_at_diagnosis = "age_at_diagnosis_days",
        age_at_index = "age_at_index_days",
        days_to_death = "days_to_death_days",
        days_to_last_follow_up = "days_to_last_follow_up_days",
        days_to_last_known_disease_status =
          "days_to_last_known_disease_status_days"
      )
      for (i in seq_len(nrow(col_info))) {
        if (col_info$Column[i] %in% names(unit_map)) {
          col_info$Column[i] <- unit_map[col_info$Column[i]]
        }
      }

      id_cols <- grep("^(submitter|project|case|bcr|patient)", col_info$Column)
      demo_cols <- grep("(gender|sex|race|ethnicity|age_)", col_info$Column)
      time_cols <- grep("(days_|year_|date_)", col_info$Column)
      vital_cols <- grep("(vital|alive|dead|status|cause)", col_info$Column)
      disease_cols <- grep("(diagnosis|stage|grade|iss|tumor|site)",
                           col_info$Column)

      ordered_idx <- unique(c(id_cols, demo_cols, time_cols, vital_cols,
                               disease_cols, seq_len(nrow(col_info))))
      col_info <- col_info[ordered_idx, ]
      rownames(col_info) <- NULL

      caption <- paste0(
        "Structure of all ", ncol(clin), " clinical variables for ",
        n_patients, " patients. ",
        "Time variables are in DAYS (GDC convention). ",
        "Columns reordered: IDs > demographics > time > vital status > ",
        "disease > other. ",
        "See data dictionary for full definitions and ",
        "glossary for units reference."
      )

      DT::datatable(
        col_info,
        filter = "top",
        options = list(pageLength = 20, scrollX = TRUE, autoWidth = FALSE),
        colnames = c("Column (units appended)", "R Type", "Non-NA",
                      "% Complete", "Unique Values", "Example / Range"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          caption
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # --- Missing data text (data-acquisition) ---
  tar_target(
    vig_missing_data_text,
    {
      if (is.null(eda_missing_summary)) return(NULL)
      missing <- eda_missing_summary
      if (isTRUE(missing$all_complete)) {
        return(missing$caption)
      }
      paste0(
        missing$n_complete, " of ", missing$n_vars,
        " variables are fully complete. ",
        "Only variables **with** missing data are shown below. ",
        "See [data dictionary](data-dictionary.html) for variable definitions."
      )
    }
  ),

  # --- Missing data table (data-acquisition) ---
  tar_target(
    vig_missing_data_table,
    {
      if (is.null(eda_missing_summary)) return(NULL)
      missing <- eda_missing_summary
      if (isTRUE(missing$all_complete)) return(NULL)
      if (is.null(missing$missing_table)) return(NULL)

      caption <- paste0(
        "Variables with missing data (", nrow(missing$missing_table),
        " of ", missing$n_vars, " total). ",
        missing$n_complete, " variables are fully complete and omitted."
      )

      DT::datatable(
        missing$missing_table,
        filter = "top",
        options = list(pageLength = 15, scrollX = TRUE),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          caption
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # --- QC metrics text (data-acquisition) ---
  tar_target(
    vig_qc_text,
    {
      if (is.null(eda_qc_summary)) return(NULL)
      qc <- eda_qc_summary
      paste0(
        "### QC Metrics Summary\n\n",
        "- **Samples assessed:** ", qc$n_samples, "\n",
        "- **Outliers flagged:** ", qc$n_outliers, "\n"
      )
    }
  ),

  # --- QC metrics table (data-acquisition) ---
  tar_target(
    vig_qc_table,
    {
      if (is.null(eda_qc_summary)) return(NULL)
      qc <- eda_qc_summary

      DT::datatable(
        qc$table,
        filter = "top",
        options = list(pageLength = 15, scrollX = TRUE),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          qc$caption
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # --- Filtered data summary (data-acquisition) ---
  tar_target(
    vig_filtered_summary,
    {
      if (is.null(filtered_data)) return(NULL)
      if (!inherits(filtered_data, "SummarizedExperiment")) return(NULL)

      filtered_counts <- get_counts_assay(filtered_data)
      text <- paste0(
        "\n### After Filtering\n\n",
        "- **Samples retained:** ", ncol(filtered_counts), "\n",
        "- **Genes retained:** ",
        format(nrow(filtered_counts), big.mark = ","), "\n"
      )

      # Compare with raw if available
      if (file.exists(raw_rnaseq)) {
        se <- readRDS(raw_rnaseq)
        if (inherits(se, "SummarizedExperiment")) {
          assay_names <- SummarizedExperiment::assayNames(se)
          counts <- get_counts_assay(se)
          if (!is.null(counts)) {
            text <- paste0(text,
              "- **Genes removed:** ",
              format(nrow(counts) - nrow(filtered_counts), big.mark = ","),
              sprintf(" (%.1f%%)",
                      100 * (1 - nrow(filtered_counts) / nrow(counts))),
              "\n"
            )
          }
        }
      }
      text
    },
    packages = c("SummarizedExperiment")
  ),

  # ================================================================
  # exploratory-analysis.Rmd targets
  # ================================================================

  # --- Clinical demographics text ---
  tar_target(
    vig_clinical_demographics_text,
    {
      if (is.null(eda_clinical_summary)) return(NULL)
      clin <- eda_clinical_summary
      paste0(
        "- **Patients:** ", format(clin$n_patients, big.mark = ","), "\n",
        "- **Variables:** ", clin$n_variables, "\n",
        "- **Data completeness:** ",
        sprintf("%.1f%%", 100 * clin$completeness), "\n"
      )
    }
  ),

  # --- Age histogram ---
  tar_target(
    vig_age_histogram,
    {
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
          caption = "Data: GDC clinical. Dashed red line = median."
        ) +
        ggplot2::theme_minimal()
    },
    packages = c("ggplot2")
  ),

  # --- Gender table ---
  tar_target(
    vig_gender_table,
    {
      if (is.null(eda_clinical_summary)) return(NULL)
      clin <- eda_clinical_summary
      if (is.null(clin$gender_table)) return(NULL)

      gt <- clin$gender_table
      gt$Percentage <- sprintf("%.1f%%", 100 * gt$Freq / sum(gt$Freq))

      knitr::kable(
        gt, row.names = FALSE,
        caption = paste0(
          "Gender distribution for ", clin$n_patients,
          " CoMMpass patients. Data: GDC clinical ",
          "(https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS)."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- Race table ---
  tar_target(
    vig_race_table,
    {
      if (is.null(eda_clinical_summary)) return(NULL)
      clin <- eda_clinical_summary
      if (is.null(clin$race_table)) return(NULL)

      rt <- clin$race_table
      rt$Percentage <- sprintf("%.1f%%", 100 * rt$Freq / sum(rt$Freq))

      knitr::kable(
        rt, row.names = FALSE,
        caption = paste0(
          "Race distribution for ", clin$n_patients,
          " CoMMpass patients. Categories from GDC clinical data."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- Vital status table ---
  tar_target(
    vig_vital_table,
    {
      if (is.null(eda_clinical_summary)) return(NULL)
      clin <- eda_clinical_summary
      if (is.null(clin$vital_table)) return(NULL)

      vt <- clin$vital_table
      vt$Percentage <- sprintf("%.1f%%", 100 * vt$Freq / sum(vt$Freq))

      knitr::kable(
        vt, row.names = FALSE,
        caption = paste0(
          "Vital status for ", clin$n_patients,
          " CoMMpass patients. Alive = censored at last follow-up. ",
          "Data: GDC clinical."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- ISS distribution text ---
  tar_target(
    vig_iss_distribution_text,
    {
      if (is.null(eda_iss_summary)) return(NULL)
      iss <- eda_iss_summary
      if (!isTRUE(iss$available)) return(NULL)
      paste0(
        "- **Patients with ISS data:** ",
        format(iss$n_with_iss, big.mark = ","), "\n",
        "- **Missing ISS:** ",
        format(iss$n_missing, big.mark = ","), "\n",
        "- **Source column:** ", iss$iss_col, "\n"
      )
    }
  ),

  # --- ISS table ---
  tar_target(
    vig_iss_table,
    {
      if (is.null(eda_iss_summary)) return(NULL)
      iss <- eda_iss_summary
      if (!isTRUE(iss$available)) return(NULL)

      knitr::kable(
        iss$iss_table, row.names = FALSE,
        caption = paste0(
          "ISS stage distribution for ", iss$n_with_iss,
          " patients with staging data (",
          iss$n_missing, " missing). ",
          "ISS = International Staging System ",
          "(https://doi.org/10.1200/JCO.2005.04.242) ",
          "based on serum beta-2 microglobulin and albumin."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- ISS barplot ---
  tar_target(
    vig_iss_barplot,
    {
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
          caption = "ISS: International Staging System (Greipp et al., 2005)"
        ) +
        ggplot2::theme_minimal()
    },
    packages = c("ggplot2")
  ),

  # --- Age by ISS table ---
  tar_target(
    vig_iss_age_table,
    {
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

      knitr::kable(
        age_tbl, row.names = FALSE,
        caption = paste0(
          "Age at diagnosis (years) by ISS stage. ",
          "GDC stores age in days; converted via age / 365.25. ",
          "SD = standard deviation."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- Survival endpoints text ---
  tar_target(
    vig_survival_endpoints,
    {
      if (is.null(eda_clinical_summary)) return(NULL)
      clin <- eda_clinical_summary
      parts <- character(0)

      if (!is.null(clin$days_to_death)) {
        parts <- c(parts, paste0(
          "### Days to Death\n\n```\n",
          paste(utils::capture.output(print(clin$days_to_death)),
                collapse = "\n"),
          "\n```\n"
        ))
      }

      if (!is.null(clin$vital_table)) {
        total <- sum(clin$vital_table$Freq)
        alive_row <- clin$vital_table[
          tolower(clin$vital_table$Status) %in% c("alive"), , drop = FALSE
        ]
        if (nrow(alive_row) > 0) {
          parts <- c(parts, paste0(
            "- **Censoring rate:** ",
            sprintf("%.1f%%", 100 * sum(alive_row$Freq) / total),
            " (patients still alive at last follow-up)\n"
          ))
        }
      }

      if (!is.null(clin$days_to_last_followup)) {
        parts <- c(parts, paste0(
          "\n### Days to Last Follow-up\n\n```\n",
          paste(utils::capture.output(print(clin$days_to_last_followup)),
                collapse = "\n"),
          "\n```\n"
        ))
      }

      if (length(parts) == 0) return(NULL)
      paste(parts, collapse = "\n")
    }
  ),

  # --- Biospecimen overview text ---
  tar_target(
    vig_biospecimen_overview_text,
    {
      if (is.null(eda_biospecimen_summary)) return(NULL)
      bio <- eda_biospecimen_summary
      paste0(
        "- **Total samples:** ",
        format(bio$n_samples, big.mark = ","), "\n",
        "- **Variables:** ", bio$n_variables, "\n"
      )
    }
  ),

  # --- Sample type barplot ---
  tar_target(
    vig_sample_type_barplot,
    {
      if (is.null(eda_biospecimen_summary)) return(NULL)
      bio <- eda_biospecimen_summary
      if (is.null(bio$sample_type_table)) return(NULL)

      st <- bio$sample_type_table
      ggplot2::ggplot(st, ggplot2::aes(
        x = reorder(Sample_Type, Freq), y = Freq
      )) +
        ggplot2::geom_col(fill = "steelblue") +
        ggplot2::coord_flip() +
        ggplot2::labs(
          x = NULL, y = "Count",
          title = "Sample Types",
          subtitle = paste0("n = ", sum(st$Freq), " total biospecimens"),
          caption = "Data: GDC biospecimen"
        ) +
        ggplot2::theme_minimal()
    },
    packages = c("ggplot2")
  ),

  # --- Samples per patient histogram ---
  tar_target(
    vig_samples_per_patient_hist,
    {
      if (is.null(eda_biospecimen_summary)) return(NULL)
      bio <- eda_biospecimen_summary
      if (is.null(bio$samples_per_patient)) return(NULL)

      spp_df <- data.frame(n = bio$samples_per_patient)
      ggplot2::ggplot(spp_df, ggplot2::aes(x = n)) +
        ggplot2::geom_histogram(binwidth = 1, fill = "steelblue",
                                colour = "white") +
        ggplot2::labs(
          x = "Number of Samples", y = "Number of Patients",
          title = "Samples per Patient",
          subtitle = paste0("n = ", length(bio$samples_per_patient),
                            " patients, median = ",
                            median(bio$samples_per_patient), " samples"),
          caption = "Data: GDC biospecimen"
        ) +
        ggplot2::theme_minimal()
    },
    packages = c("ggplot2")
  ),

  # --- RNA-seq quality text ---
  tar_target(
    vig_rnaseq_quality_text,
    {
      if (is.null(eda_rnaseq_summary)) return(NULL)
      rna <- eda_rnaseq_summary
      paste0(
        "- **Genes:** ", format(rna$n_genes, big.mark = ","), "\n",
        "- **Samples:** ", rna$n_samples, "\n",
        "- **Total counts:** ",
        format(rna$total_counts, big.mark = ","), "\n",
        "- **Median library size:** ",
        format(rna$median_library_size, big.mark = ","), "\n",
        "- **Sparsity (% zero entries):** ",
        sprintf("%.1f%%", 100 * rna$sparsity), "\n"
      )
    }
  ),

  # --- Library size boxplot ---
  tar_target(
    vig_library_size_boxplot,
    {
      if (is.null(eda_rnaseq_summary)) return(NULL)
      rna <- eda_rnaseq_summary
      if (is.null(rna$library_sizes)) return(NULL)

      ls_df <- data.frame(library_size = rna$library_sizes / 1e6)
      ggplot2::ggplot(ls_df, ggplot2::aes(y = library_size)) +
        ggplot2::geom_boxplot(fill = "steelblue", width = 0.4) +
        ggplot2::labs(
          y = "Library Size (millions of reads)",
          title = "Library Size Distribution",
          subtitle = paste0("n = ", rna$n_samples, " samples, median = ",
                            sprintf("%.1f", median(rna$library_sizes) / 1e6),
                            "M"),
          caption = "Data: GDC STAR-Counts"
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(axis.text.x = ggplot2::element_blank(),
                       axis.ticks.x = ggplot2::element_blank())
    },
    packages = c("ggplot2")
  ),

  # --- Genes detected histogram ---
  tar_target(
    vig_genes_detected_hist,
    {
      if (is.null(eda_rnaseq_summary)) return(NULL)
      rna <- eda_rnaseq_summary
      if (is.null(rna$genes_detected)) return(NULL)

      gd_df <- data.frame(genes = rna$genes_detected)
      ggplot2::ggplot(gd_df, ggplot2::aes(x = genes)) +
        ggplot2::geom_histogram(bins = 30, fill = "steelblue",
                                colour = "white") +
        ggplot2::labs(
          x = "Genes Detected (count > 0)", y = "Number of Samples",
          title = "Genes Detected per Sample",
          subtitle = paste0("n = ", rna$n_samples, " samples, median = ",
                            format(median(rna$genes_detected),
                                   big.mark = ","),
                            " genes"),
          caption = "Data: GDC STAR-Counts"
        ) +
        ggplot2::theme_minimal()
    },
    packages = c("ggplot2")
  ),

  # --- Cytogenetic frequency table ---
  tar_target(
    vig_cyto_frequency_table,
    {
      if (is.null(cyto_frequency_summary)) return(NULL)
      if (nrow(cyto_frequency_summary) == 0) return(NULL)

      knitr::kable(
        cyto_frequency_summary, row.names = FALSE,
        caption = paste0(
          "Cytogenetic alteration frequencies from FISH testing. ",
          "n_tested = patients with FISH data for that marker. ",
          "High-risk: t(4;14), t(14;16), del(17p), gain(1q) per IMWG 2014. ",
          "See data dictionary for marker definitions."
        ),
        col.names = c("Marker", "Positive", "Tested", "%"),
        align = "lrrr"
      )
    },
    packages = c("knitr")
  ),

  # --- Cytogenetic oncoprint ---
  tar_target(
    vig_cyto_oncoprint,
    {
      if (is.null(cyto_viz_data)) return(NULL)
      if (nrow(cyto_viz_data) == 0) return(NULL)
      plot_cytogenetic_oncoprint(cyto_viz_data,
                                  title = "CoMMpass Cytogenetic Landscape")
    }
  ),

  # --- Co-occurrence table ---
  tar_target(
    vig_cyto_cooccurrence_table,
    {
      if (is.null(cyto_cooccurrence)) return(NULL)
      if (nrow(cyto_cooccurrence) == 0) return(NULL)

      marker_labels <- c(
        t_4_14 = "t(4;14)", t_11_14 = "t(11;14)", t_14_16 = "t(14;16)",
        t_14_20 = "t(14;20)", del_17p = "del(17p)", del_1p = "del(1p)",
        gain_1q = "gain(1q)"
      )
      display <- cyto_cooccurrence
      display$marker1 <- ifelse(
        display$marker1 %in% names(marker_labels),
        marker_labels[display$marker1], display$marker1
      )
      display$marker2 <- ifelse(
        display$marker2 %in% names(marker_labels),
        marker_labels[display$marker2], display$marker2
      )

      knitr::kable(
        display[, c("marker1", "marker2", "odds_ratio", "pvalue", "padj",
                     "n_both", "tendency")],
        row.names = FALSE, digits = c(0, 0, 2, 4, 4, 0, 0),
        caption = paste0(
          "Pairwise co-occurrence analysis of cytogenetic markers ",
          "(Fisher's exact test, BH-adjusted). ",
          "odds_ratio > 1 indicates co-occurrence; < 1 indicates mutual ",
          "exclusivity. * = padj < 0.05."
        ),
        col.names = c("Marker 1", "Marker 2", "Odds Ratio", "p-value",
                       "Adjusted p", "Both+", "Tendency")
      )
    },
    packages = c("knitr")
  ),

  # --- Co-occurrence heatmap ---
  tar_target(
    vig_cyto_cooccurrence_heatmap,
    {
      if (is.null(cyto_cooccurrence)) return(NULL)
      if (nrow(cyto_cooccurrence) == 0) return(NULL)
      plot_cooccurrence_heatmap(cyto_cooccurrence)
    }
  ),

  # --- DuckDB demo simple query result ---
  tar_target(
    vig_duckdb_demo_simple,
    {
      if (is.null(eda_duckdb_demo)) return(NULL)
      demo <- eda_duckdb_demo

      knitr::kable(
        demo$demo_result, row.names = FALSE,
        caption = paste0(
          "First 10 patients from clinical data via dplyr/DuckDB query. ",
          "age_at_diagnosis is in days."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- DuckDB demo aggregation result ---
  tar_target(
    vig_duckdb_demo_agg,
    {
      if (is.null(eda_duckdb_demo)) return(NULL)
      demo <- eda_duckdb_demo

      knitr::kable(
        demo$agg_result, row.names = FALSE,
        caption = paste0(
          "Patient count and mean age (years) by gender via ",
          "dplyr/DuckDB aggregation."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- Integration summary text ---
  tar_target(
    vig_integration_text,
    {
      if (is.null(eda_integration_summary)) return(NULL)
      integ <- eda_integration_summary
      paste0(
        "Patient ID overlap between clinical and biospecimen datasets:\n\n",
        "- **Clinical patients:** ",
        format(integ$n_clinical_patients, big.mark = ","), "\n",
        "- **Biospecimen patients:** ",
        format(integ$n_biospecimen_patients, big.mark = ","), "\n",
        "- **Shared (in both):** ",
        format(integ$n_shared, big.mark = ","), "\n",
        "- **Clinical only:** ",
        format(integ$n_clinical_only, big.mark = ","), "\n",
        "- **Biospecimen only:** ",
        format(integ$n_biospecimen_only, big.mark = ","), "\n"
      )
    }
  ),

  # --- PCA biplot: colored by gender (#25) ---
  tar_target(
    vig_pca_biplot,
    {
      if (is.null(eda_pca_summary) || nrow(eda_pca_summary$coords) == 0) {
        return(NULL)
      }
      plot_pca(eda_pca_summary, color_by = "gender",
               title = "PCA: Sample Clustering (by Gender)")
    }
  ),

  # --- PCA biplot: colored by vital status (#25) ---
  tar_target(
    vig_pca_biplot_vital,
    {
      if (is.null(eda_pca_summary) || nrow(eda_pca_summary$coords) == 0) {
        return(NULL)
      }
      plot_pca(eda_pca_summary, color_by = "vital_status",
               title = "PCA: Sample Clustering (by Vital Status)")
    }
  ),

  # ================================================================
  # differential-expression.Rmd targets
  # ================================================================

  # --- DE method comparison table ---
  tar_target(
    vig_de_method_table,
    {
      if (is.null(de_method_summary)) return(NULL)
      if (nrow(de_method_summary) == 0) return(NULL)

      knitr::kable(
        de_method_summary,
        caption = paste0(
          "Differential expression results across methods. ",
          "Significance thresholds: |log2FC| > 1, adjusted p-value < 0.05. ",
          "DESeq2 uses Wald test with apeglm shrinkage; edgeR uses ",
          "quasi-likelihood F-test; limma uses empirical Bayes moderated ",
          "t-test."
        ),
        col.names = c("Method", "Genes Tested", "Significant", "Up", "Down"),
        row.names = FALSE, align = "lrrrr"
      )
    },
    packages = c("knitr")
  ),

  # --- DE method barplot ---
  tar_target(
    vig_de_method_barplot,
    {
      if (is.null(de_method_summary)) return(NULL)
      if (nrow(de_method_summary) == 0) return(NULL)

      long <- rbind(
        data.frame(method = de_method_summary$method, direction = "Up",
                   count = de_method_summary$n_up),
        data.frame(method = de_method_summary$method, direction = "Down",
                   count = -de_method_summary$n_down)
      )

      ggplot2::ggplot(long, ggplot2::aes(x = method, y = count,
                                          fill = direction)) +
        ggplot2::geom_col() +
        ggplot2::scale_fill_manual(
          values = c("Up" = "#DC3545", "Down" = "#0066CC"),
          name = "Direction"
        ) +
        ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
        ggplot2::labs(
          title = "DE Genes by Method",
          x = NULL,
          y = "Number of genes (down shown as negative)"
        ) +
        ggplot2::theme_minimal(base_size = 12)
    },
    packages = c("ggplot2")
  ),

  # --- PCA plot ---
  tar_target(
    vig_pca_plot,
    {
      if (is.null(pca_data)) return(NULL)
      if (nrow(pca_data$coords) == 0) return(NULL)

      color_var <- NULL
      if ("condition" %in% names(pca_data$coords)) color_var <- "condition"
      plot_pca(pca_data, color_by = color_var, title = "Sample PCA (VST)")
    }
  ),

  # --- Volcano plot ---
  tar_target(
    vig_volcano_plot,
    {
      if (is.null(volcano_plot_data)) return(NULL)
      if (nrow(volcano_plot_data) == 0) return(NULL)
      plot_volcano(volcano_plot_data, lfc_threshold = 1,
                   padj_threshold = 0.05, n_label = 10,
                   title = "DESeq2 Volcano Plot")
    }
  ),

  # --- MA plot ---
  tar_target(
    vig_ma_plot,
    {
      if (is.null(ma_plot_data)) return(NULL)
      if (nrow(ma_plot_data) == 0) return(NULL)
      plot_ma(ma_plot_data, lfc_threshold = 1, padj_threshold = 0.05,
              title = "DESeq2 MA Plot")
    }
  ),

  # --- Heatmap ---
  tar_target(
    vig_heatmap_plot,
    {
      if (is.null(top_de_heatmap_data)) return(NULL)
      if (is.null(top_de_heatmap_data$expr_matrix)) return(NULL)
      if (is.null(top_de_heatmap_data$de_results)) return(NULL)
      plot_heatmap_de(top_de_heatmap_data$expr_matrix,
                      top_de_heatmap_data$de_results,
                      n_genes = 50, title = "Top 50 DE Genes")
    }
  ),

  # --- Consensus DE text ---
  tar_target(
    vig_consensus_text,
    {
      if (is.null(consensus_de_genes)) return(NULL)
      consensus <- consensus_de_genes
      if (is.null(consensus$n_consensus)) return(NULL)

      text <- paste0("**", consensus$n_consensus,
                     " consensus DE genes** found across all three methods.\n\n")

      if (consensus$n_consensus > 0 && !is.null(consensus$consensus_genes)) {
        n_show <- min(20, length(consensus$consensus_genes))
        text <- paste0(text,
          "Top ", n_show, " consensus genes (sorted by mean rank): ",
          paste(utils::head(consensus$consensus_genes, n_show),
                collapse = ", "),
          if (consensus$n_consensus > n_show) {
            paste0(", ... (", consensus$n_consensus - n_show, " more)")
          } else {
            ""
          },
          "\n\nThese genes are used for ",
          "[pathway analysis](pathway-analysis.html) via ORA.\n"
        )
      }
      text
    }
  ),

  # --- Paired DE text ---
  tar_target(
    vig_paired_de_text,
    {
      if (is.null(deseq2_paired_results)) return(NULL)
      pr <- deseq2_paired_results
      if (is.null(pr$results_table) || nrow(pr$results_table) == 0) {
        return(NULL)
      }

      n_patients <- pr$n_patients %||% NA
      n_samples <- pr$n_samples %||% NA
      n_deg <- pr$n_deg %||% 0

      paste0(
        "**Paired analysis**: ", n_patients, " patients, ",
        n_samples, " samples\n\n",
        "**", n_deg, " DE genes** at padj < 0.05\n"
      )
    }
  ),

  # --- Paired DE volcano plot ---
  tar_target(
    vig_paired_de_plot,
    {
      if (is.null(deseq2_paired_results)) return(NULL)
      pr <- deseq2_paired_results
      if (is.null(pr$results_table) || nrow(pr$results_table) == 0) {
        return(NULL)
      }
      plot_volcano(pr$results_table, lfc_threshold = 1,
                   padj_threshold = 0.05, n_label = 10,
                   title = "Paired DE: Baseline vs Relapse")
    }
  ),

  # --- Annotated DE table ---
  tar_target(
    vig_annotated_de_table,
    {
      if (is.null(de_results_annotated)) return(NULL)
      if (nrow(de_results_annotated) == 0) return(NULL)

      top <- utils::head(
        de_results_annotated[order(de_results_annotated$padj), ], 15
      )
      display_cols <- intersect(
        c("gene_symbol", "log2FoldChange", "baseMean", "padj"),
        names(top)
      )

      knitr::kable(
        top[, display_cols],
        caption = paste0(
          "Top 15 DE genes by adjusted p-value (DESeq2). ",
          "Gene symbols mapped from Ensembl IDs via MSigDB. ",
          "log2FoldChange: positive = upregulated in tumor/relapse. ",
          "See data dictionary for gene ID details."
        ),
        digits = c(0, 2, 1, 4),
        row.names = FALSE
      )
    },
    packages = c("knitr")
  ),

  # --- GSEA dotplot ---
  tar_target(
    vig_gsea_dotplot,
    {
      if (is.null(enrichment_dotplot_data)) return(NULL)
      if (nrow(enrichment_dotplot_data) == 0) return(NULL)
      plot_enrichment_dotplot(enrichment_dotplot_data, n = 15,
                              color_by = "NES",
                              title = "GSEA Hallmark Pathways")
    }
  ),

  # --- ORA barplot ---
  tar_target(
    vig_ora_barplot,
    {
      if (is.null(enrichment_barplot_data)) return(NULL)
      if (nrow(enrichment_barplot_data) == 0) return(NULL)
      plot_enrichment_barplot(enrichment_barplot_data, n = 15,
                              title = "ORA: Consensus DE Genes in Hallmark Pathways")
    }
  ),

  # ================================================================
  # survival-analysis.Rmd targets
  # ================================================================

  # --- KM overall plot ---
  tar_target(
    vig_km_overall,
    {
      if (is.null(km_overall)) return(NULL)
      if (is.null(km_overall$fit)) return(NULL)
      plot_km(km_overall, title = "Overall Survival")
    }
  ),

  # --- KM overall median text ---
  tar_target(
    vig_km_overall_text,
    {
      if (is.null(km_overall)) return(NULL)
      if (is.null(km_overall$fit)) return(NULL)
      median_os <- km_overall$median_survival
      if (all(is.na(median_os))) return(NULL)
      paste0(
        "\n**Median overall survival:** ",
        round(median_os[1]), " days (",
        round(median_os[1] / 365.25, 1), " years)\n"
      )
    }
  ),

  # --- KM by ISS ---
  tar_target(
    vig_km_iss,
    {
      if (is.null(km_by_iss)) return(NULL)
      if (is.null(km_by_iss$fit)) return(NULL)
      plot_km(km_by_iss, title = "Survival by ISS Stage")
    }
  ),

  # --- KM by risk ---
  tar_target(
    vig_km_risk,
    {
      if (is.null(km_by_risk)) return(NULL)
      if (is.null(km_by_risk$fit)) return(NULL)
      plot_km(km_by_risk, title = "Survival by Cytogenetic Risk")
    }
  ),

  # --- KM by individual markers ---
  tar_target(
    vig_km_markers,
    {
      if (is.null(km_by_markers)) return(NULL)
      if (length(km_by_markers) == 0) return(NULL)

      marker_labels <- c(
        t_4_14 = "t(4;14)", t_11_14 = "t(11;14)", t_14_16 = "t(14;16)",
        del_17p = "del(17p)", gain_1q = "gain(1q)"
      )

      plots <- list()
      for (m in names(km_by_markers)) {
        km <- km_by_markers[[m]]
        label <- if (m %in% names(marker_labels)) marker_labels[m] else m
        if (!is.null(km$fit)) {
          plots[[m]] <- plot_km(km, title = paste0("Survival by ", label))
        }
      }
      if (length(plots) == 0) return(NULL)
      plots
    }
  ),

  # --- Cox basic table ---
  tar_target(
    vig_cox_basic_table,
    {
      if (is.null(cox_basic)) return(NULL)
      if (is.null(cox_basic$hazard_ratios)) return(NULL)

      knitr::kable(
        cox_basic$hazard_ratios, row.names = FALSE,
        digits = c(0, 3, 3, 3, 4),
        caption = paste0(
          "Cox PH model: age + gender. HR > 1 = increased hazard ",
          "(worse survival). n = ", cox_basic$n, " patients, ",
          cox_basic$n_events, " events. C-index = ",
          round(cox_basic$concordance, 3), ". ",
          "* p < 0.05, ** p < 0.01, *** p < 0.001."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- Cox full table ---
  tar_target(
    vig_cox_full_table,
    {
      if (is.null(cox_full)) return(NULL)
      if (is.null(cox_full$hazard_ratios)) return(NULL)

      knitr::kable(
        cox_full$hazard_ratios, row.names = FALSE,
        digits = c(0, 3, 3, 3, 4),
        caption = paste0(
          "Cox PH model with clinical and cytogenetic covariates. ",
          "n = ", cox_full$n, " patients, ", cox_full$n_events, " events. ",
          "C-index = ", round(cox_full$concordance, 3), ". ",
          "Covariates: ",
          paste(cox_full$covariates_used, collapse = ", "), "."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- Forest plot ---
  tar_target(
    vig_forest_plot,
    {
      # Prefer full model, fall back to basic
      cox_for_forest <- if (!is.null(cox_full) &&
                            !is.null(cox_full$hazard_ratios) &&
                            nrow(cox_full$hazard_ratios) > 0) {
        cox_full
      } else if (!is.null(cox_basic) &&
                  !is.null(cox_basic$hazard_ratios) &&
                  nrow(cox_basic$hazard_ratios) > 0) {
        cox_basic
      } else {
        NULL
      }
      if (is.null(cox_for_forest)) return(NULL)

      title <- if (identical(cox_for_forest, cox_full)) {
        "Multivariate Cox: Hazard Ratios"
      } else {
        "Cox Regression: Hazard Ratios"
      }
      plot_forest(cox_for_forest, title = title)
    }
  ),

  # --- PH test table ---
  tar_target(
    vig_ph_test_table,
    {
      cox_for_ph <- if (!is.null(cox_full)) cox_full else cox_basic
      if (is.null(cox_for_ph)) return(NULL)
      if (is.null(cox_for_ph$ph_test)) return(NULL)

      ph <- cox_for_ph$ph_test
      ph_table <- as.data.frame(ph$table)
      ph_table$variable <- rownames(ph_table)
      ph_table <- ph_table[, c("variable", "chisq", "p")]
      names(ph_table) <- c("Variable", "Chi-squared", "p-value")

      knitr::kable(
        ph_table, row.names = FALSE, digits = c(0, 2, 4),
        caption = paste0(
          "Proportional hazards assumption test (cox.zph). ",
          "p < 0.05 indicates the PH assumption may be violated. ",
          "If violated, time-varying coefficients or stratification ",
          "should be considered."
        )
      )
    },
    packages = c("knitr")
  ),

  # --- Cox model comparison table ---
  tar_target(
    vig_cox_comparison,
    {
      if (is.null(cox_basic) || is.null(cox_full)) return(NULL)
      if (is.null(cox_basic$concordance) ||
          is.null(cox_full$concordance)) {
        return(NULL)
      }

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

      knitr::kable(
        comp, row.names = FALSE,
        caption = paste0(
          "Cox model comparison. C-index: concordance statistic ",
          "(0.5 = random, 1.0 = perfect discrimination). ",
          "Higher C-index indicates better prognostic discrimination."
        ),
        col.names = c("Model", "N", "Events", "C-index")
      )
    },
    packages = c("knitr")
  ),

  # --- KM by gene expression (#53) ---
  tar_target(
    vig_km_by_expression,
    {
      if (is.null(km_by_expression)) return(NULL)
      if (length(km_by_expression) == 0) return(NULL)

      plots <- list()
      for (g in names(km_by_expression)) {
        km <- km_by_expression[[g]]
        if (!is.null(km$fit)) {
          plots[[g]] <- plot_km(km,
            title = paste0("Survival by ", g, " Expression (Median Split)"))
        }
      }
      if (length(plots) == 0) return(NULL)
      plots
    }
  ),

  # --- Expression by cytogenetic subtype (#54) ---
  tar_target(
    vig_expr_by_subtype,
    {
      if (is.null(expr_by_subtype)) return(NULL)
      if (length(expr_by_subtype) == 0) return(NULL)
      # Return list of plots (first non-NULL)
      valid <- Filter(Negate(is.null), expr_by_subtype)
      if (length(valid) == 0) return(NULL)
      valid
    }
  ),

  # ================================================================
  # data-dictionary.Rmd targets
  # ================================================================

  # --- Data dictionary DT ---
  tar_target(
    vig_dd_dictionary_table,
    {
      dd <- tryCatch(get_commpass_data_dictionary(), error = function(e) NULL)
      if (is.null(dd)) return(NULL)

      dd_display <- dd
      if ("gdc_link" %in% names(dd_display)) {
        dd_display$gdc_link <- ifelse(
          is.na(dd_display$gdc_link) | dd_display$gdc_link == "",
          "",
          paste0('<a href="', dd_display$gdc_link,
                 '" target="_blank">GDC</a>')
        )
      }

      DT::datatable(
        dd_display,
        filter = "top", escape = FALSE,
        options = list(
          pageLength = 20, scrollX = TRUE, autoWidth = FALSE,
          columnDefs = list(
            list(className = "dt-nowrap", targets = "_all")
          )
        ),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          paste0(
            "CoMMpass Data Dictionary - All Variables. ",
            "Click column headers to sort; use filters to search. ",
            "GDC links open the official data dictionary page."
          )
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # --- Clinical summary text (data-dictionary) ---
  tar_target(
    vig_dd_clinical_text,
    {
      pq_path <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(pq_path)) return(NULL)
      clin <- arrow::read_parquet(pq_path)
      if (!is.data.frame(clin) || nrow(clin) == 0) return(NULL)
      paste0(
        "### Summary\n\n",
        "- **Total patients:** ", format(nrow(clin), big.mark = ","), "\n",
        "- **Variables:** ", ncol(clin), "\n",
        "- **Data completeness:** ",
        sprintf("%.1f%%", 100 * mean(!is.na(clin))), "\n\n",
        "### Column Structure\n"
      )
    }
  ),

  # --- Clinical column structure table (data-dictionary) ---
  tar_target(
    vig_dd_clinical_table,
    {
      pq_path <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(pq_path)) return(NULL)
      clin <- arrow::read_parquet(pq_path)
      if (!is.data.frame(clin) || nrow(clin) == 0) return(NULL)

      col_info <- data.frame(
        Column = names(clin),
        Type = vapply(clin, function(x) class(x)[1], character(1)),
        Non_NA = vapply(clin, function(x) sum(!is.na(x)), integer(1)),
        Pct_Complete = vapply(
          clin, function(x) sprintf("%.0f%%", 100 * mean(!is.na(x))),
          character(1)
        ),
        N_Unique = vapply(
          clin, function(x) length(unique(x[!is.na(x)])),
          integer(1)
        ),
        Example = vapply(clin, function(x) {
          vals <- x[!is.na(x)]
          if (length(vals) == 0) return("(all NA)")
          if (is.numeric(vals)) {
            paste0("min=", signif(min(vals), 3),
                   " med=", signif(median(vals), 3),
                   " max=", signif(max(vals), 3))
          } else {
            vals_chr <- as.character(vals)
            top <- names(sort(table(vals_chr), decreasing = TRUE))[
              1:min(3, length(unique(vals_chr)))
            ]
            paste(top, collapse = ", ")
          }
        }, character(1)),
        stringsAsFactors = FALSE
      )

      unit_map <- c(
        age_at_diagnosis = "age_at_diagnosis_days",
        age_at_index = "age_at_index_days",
        days_to_death = "days_to_death_days",
        days_to_last_follow_up = "days_to_last_follow_up_days",
        days_to_last_known_disease_status =
          "days_to_last_known_disease_status_days"
      )
      for (i in seq_len(nrow(col_info))) {
        if (col_info$Column[i] %in% names(unit_map)) {
          col_info$Column[i] <- unit_map[col_info$Column[i]]
        }
      }

      id_cols <- grep("^(submitter|project|case|bcr|patient)", col_info$Column)
      demo_cols <- grep("(gender|sex|race|ethnicity|age_)", col_info$Column)
      time_cols <- grep("(days_|year_|date_)", col_info$Column)
      vital_cols <- grep("(vital|alive|dead|status|cause)", col_info$Column)
      disease_cols <- grep("(diagnosis|stage|grade|iss|tumor|site)",
                           col_info$Column)
      ordered_idx <- unique(c(id_cols, demo_cols, time_cols, vital_cols,
                               disease_cols, seq_len(nrow(col_info))))
      col_info <- col_info[ordered_idx, ]
      rownames(col_info) <- NULL

      caption <- paste0(
        "Structure of all ", ncol(clin), " clinical variables for ",
        nrow(clin), " patients. ",
        "Time variables are in DAYS (GDC convention). ",
        "Columns reordered: IDs > demographics > time > vital status > ",
        "disease > other. See glossary for units reference."
      )

      DT::datatable(
        col_info,
        filter = "top",
        options = list(pageLength = 20, scrollX = TRUE, autoWidth = FALSE),
        colnames = c("Column (units appended)", "R Type", "Non-NA",
                      "% Complete", "Unique Values", "Example / Range"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # --- Biospecimen summary text (data-dictionary) ---
  tar_target(
    vig_dd_biospecimen_text,
    {
      bio_pq <- file.path(clinical_data, "biospecimen_data.parquet")
      if (!file.exists(bio_pq)) return(NULL)
      bio <- arrow::read_parquet(bio_pq)
      if (!is.data.frame(bio) || nrow(bio) == 0) return(NULL)
      paste0(
        "- **Total records:** ", format(nrow(bio), big.mark = ","), "\n",
        "- **Variables:** ", ncol(bio), "\n"
      )
    }
  ),

  # --- Biospecimen column table (data-dictionary) ---
  tar_target(
    vig_dd_biospecimen_table,
    {
      bio_pq <- file.path(clinical_data, "biospecimen_data.parquet")
      if (!file.exists(bio_pq)) return(NULL)
      bio <- arrow::read_parquet(bio_pq)
      if (!is.data.frame(bio) || nrow(bio) == 0) return(NULL)

      bio_cols <- data.frame(
        Column = names(bio),
        Type = vapply(bio, function(x) class(x)[1], character(1)),
        Non_NA = vapply(bio, function(x) sum(!is.na(x)), integer(1)),
        Pct_Complete = vapply(
          bio, function(x) sprintf("%.0f%%", 100 * mean(!is.na(x))),
          character(1)
        ),
        N_Unique = vapply(
          bio, function(x) length(unique(x[!is.na(x)])),
          integer(1)
        ),
        stringsAsFactors = FALSE
      )

      DT::datatable(
        bio_cols,
        filter = "top",
        options = list(pageLength = 15, scrollX = TRUE),
        colnames = c("Column", "R Type", "Non-NA",
                      "% Complete", "Unique Values"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          paste0("Biospecimen data columns for ", nrow(bio), " records. ",
                 "Click column headers to sort; use filters to search.")
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # --- RNA-seq dimensions text (data-dictionary) ---
  tar_target(
    vig_dd_rnaseq_text,
    {
      if (!file.exists(raw_rnaseq)) return(NULL)
      se <- readRDS(raw_rnaseq)
      if (!inherits(se, "SummarizedExperiment")) return(NULL)
      paste0(
        "### Dimensions\n\n",
        "- **Samples:** ", ncol(se), "\n",
        "- **Genes:** ", format(nrow(se), big.mark = ","), "\n",
        "- **Assays:** ",
        paste(SummarizedExperiment::assayNames(se), collapse = ", "), "\n"
      )
    },
    packages = c("SummarizedExperiment")
  ),

  # --- RNA-seq biotype table (data-dictionary) ---
  tar_target(
    vig_dd_rnaseq_biotype_table,
    {
      if (!file.exists(raw_rnaseq)) return(NULL)
      se <- readRDS(raw_rnaseq)
      if (!inherits(se, "SummarizedExperiment")) return(NULL)

      gene_meta <- as.data.frame(SummarizedExperiment::rowData(se))
      if (!"gene_type" %in% names(gene_meta)) return(NULL)

      type_counts <- sort(table(gene_meta$gene_type), decreasing = TRUE)
      type_df <- data.frame(
        Biotype = names(type_counts),
        Count = as.integer(type_counts),
        Percentage = sprintf("%.1f%%",
                             100 * as.numeric(type_counts) / nrow(gene_meta)),
        stringsAsFactors = FALSE
      )

      DT::datatable(
        type_df,
        filter = "top",
        options = list(pageLength = 15, scrollX = TRUE),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          paste0(
            "Gene biotypes from GENCODE annotations. ",
            format(nrow(gene_meta), big.mark = ","),
            " total gene entries. ",
            "protein_coding genes are the primary analysis target."
          )
        )
      )
    },
    packages = c("SummarizedExperiment", "DT", "htmltools")
  ),

  # --- RNA-seq sample metadata table (data-dictionary) ---
  tar_target(
    vig_dd_rnaseq_sample_table,
    {
      if (!file.exists(raw_rnaseq)) return(NULL)
      se <- readRDS(raw_rnaseq)
      if (!inherits(se, "SummarizedExperiment")) return(NULL)

      sample_meta <- as.data.frame(SummarizedExperiment::colData(se))
      sample_cols <- data.frame(
        Column = names(sample_meta),
        Type = vapply(sample_meta, function(x) class(x)[1], character(1)),
        N_Unique = vapply(
          sample_meta,
          function(x) length(unique(x[!is.na(x)])),
          integer(1)
        ),
        stringsAsFactors = FALSE
      )

      DT::datatable(
        sample_cols,
        filter = "top",
        options = list(pageLength = 15, scrollX = TRUE),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          "RNA-seq sample metadata columns from the SummarizedExperiment colData."
        )
      )
    },
    packages = c("SummarizedExperiment", "DT", "htmltools")
  ),

  # --- Column name mappings (data-dictionary) ---
  tar_target(
    vig_dd_column_mappings,
    {
      mappings <- data.frame(
        GDC_Column = c("submitter_id", "age_at_diagnosis", "vital_status",
                        "days_to_death", "days_to_last_follow_up",
                        "gender", "primary_diagnosis"),
        Common_Alias = c("patient_id", "age_days", "status",
                          "os_time (if dead)", "os_time (if alive)",
                          "sex", "diagnosis"),
        Notes = c("Unique patient identifier",
                  "In **days**, not years (divide by 365.25)",
                  "Alive/Dead",
                  "Overall survival time",
                  "Censoring time",
                  "male/female",
                  "ICD-O-3 morphology"),
        stringsAsFactors = FALSE
      )

      DT::datatable(
        mappings,
        filter = "top",
        options = list(pageLength = 10, scrollX = TRUE),
        colnames = c("GDC Column", "Common Alias", "Notes"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          "GDC column name mappings to common aliases used in analysis code."
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # ================================================================
  # api-usage.Rmd targets
  # ================================================================

  # --- API endpoints DT ---
  tar_target(
    vig_api_endpoints_dt,
    {
      idx <- tryCatch(generate_api_index(), error = function(e) NULL)
      if (is.null(idx) || is.null(idx$endpoints)) return(NULL)

      DT::datatable(
        idx$endpoints,
        filter = "top",
        options = list(pageLength = 10, scrollX = TRUE, dom = "Bfrtip"),
        colnames = c("Endpoint", "URL", "Description"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;",
          paste0(
            "Static API endpoints for CoMMpass analysis results. ",
            "Base URL: ", idx$base_url, ". ",
            "Data is pre-computed and updated on each pipeline run."
          )
        )
      )
    },
    packages = c("DT", "htmltools")
  ),

  # ================================================================
  # pipeline-dag.Rmd targets
  # ================================================================

  # --- Pipeline manifest summary (for DAG display in vignette) ---
  tar_target(
    vig_pipeline_dag,
    {
      # tar_visnetwork()/tar_network() cannot run inside a target
      # (targets >= 1.10). Use tar_manifest() which only reads the
      # pipeline definition, not the data store.
      manifest <- targets::tar_manifest()
      list(
        n_targets = nrow(manifest),
        targets = manifest$name,
        commands = manifest$command,
        note = paste(
          "Pipeline DAG has", nrow(manifest), "targets.",
          "Run targets::tar_visnetwork() interactively to view the graph."
        )
      )
    },
    packages = c("targets")
  ),

  # --- Git info table (shared by all vignettes) ---
  tar_target(
    vig_git_info,
    {
      if (!requireNamespace("gert", quietly = TRUE)) return(NULL)
      tryCatch({
        info <- gert::git_info()
        log1 <- gert::git_log(max = 1)
        knitr::kable(data.frame(
          Item = c("Commit Hash", "Author", "Time", "Branch"),
          Value = c(info$commit, log1$author,
                    as.character(log1$time), info$shorthand)
        ), row.names = FALSE)
      }, error = function(e) NULL)
    },
    packages = c("gert", "knitr")
  )
)
