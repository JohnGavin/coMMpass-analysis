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
        "In CI, this is capped at 20 samples ",
        "(see R/01_data_acquisition.R) to keep build times under ",
        "10 minutes.\n\n",
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
      # Remove large objects from aes() quosure environment before serializing
      rm(se, counts, log_counts, mean_expr, gene_meta)
      # Convert to grob to strip ggplot2 S7 env overhead
      ggplot2::ggplotGrob(p)
    },
    packages = c("SummarizedExperiment", "ggplot2", "dplyr")
  ),

  # --- Data at a Glance summary table (data-sources) ---
  tar_target(
    vig_data_at_glance,
    {
      rows <- list()

      # Clinical data
      clin_file <- file.path(clinical_data, "clinical_data.parquet")
      if (file.exists(clin_file)) {
        clin <- arrow::read_parquet(clin_file)
        iss_pct <- round(100 * sum(!is.na(clin$iss_stage)) / nrow(clin))
        rows <- c(rows, list(data.frame(
          Dataset = "Clinical metadata",
          Records = nrow(clin), Variables = ncol(clin),
          Completeness = paste0("ISS: ", iss_pct, "%"),
          Source = "GDC API (open)",
          stringsAsFactors = FALSE
        )))
      }

      # Treatment data
      trt_file <- file.path(clinical_data, "treatment_data.parquet")
      if (file.exists(trt_file)) {
        trt <- arrow::read_parquet(trt_file)
        rows <- c(rows, list(data.frame(
          Dataset = "Treatment records",
          Records = nrow(trt),
          Variables = ncol(trt),
          Completeness = paste0(length(unique(trt$public_id)), " patients"),
          Source = "GDC API (open)",
          stringsAsFactors = FALSE
        )))
      }

      # RNA-seq
      if (!is.null(raw_rnaseq) && file.exists(raw_rnaseq)) {
        se <- readRDS(raw_rnaseq)
        rows <- c(rows, list(data.frame(
          Dataset = "RNA-seq (STAR counts)",
          Records = ncol(se),
          Variables = nrow(se),
          Completeness = "100%",
          Source = "GDC STAR-Counts",
          stringsAsFactors = FALSE
        )))
      }

      # MSigDB
      rows <- c(rows, list(data.frame(
        Dataset = "MSigDB gene sets",
        Records = 708, Variables = 2,
        Completeness = "Hallmark + KEGG",
        Source = "Pre-bundled parquet",
        stringsAsFactors = FALSE
      )))

      if (length(rows) == 0) return(NULL)
      df <- do.call(rbind, rows)
      names(df)[2:3] <- c("Rows", "Columns")
      DT::datatable(df, rownames = FALSE, options = list(dom = "t", paging = FALSE),
                    caption = htmltools::tags$caption(
                      style = "caption-side: bottom; text-align: left;",
                      "Summary of all datasets used by the coMMpass pipeline. ",
                      "Rows = records (patients/samples/treatment lines). ",
                      "Columns = variables per record. ",
                      "All data sourced from GDC open-access endpoints; ",
                      "MMRF Gateway data (FISH, PFS, response) not yet available."
                    ))
    },
    packages = c("arrow", "DT", "htmltools", "SummarizedExperiment")
  ),

  # --- Clinical data preview (data-dictionary) ---
  tar_target(
    vig_clinical_preview,
    {
      clin_file <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(clin_file)) return(NULL)
      clin <- arrow::read_parquet(clin_file)
      # Show first 5 rows of key columns
      key_cols <- intersect(
        c("submitter_id", "age_at_diagnosis", "gender", "race",
          "vital_status", "days_to_death", "days_to_last_follow_up",
          "iss_stage"),
        names(clin)
      )
      preview <- utils::head(clin[, key_cols, drop = FALSE], 5)
      DT::datatable(preview, rownames = FALSE,
                    options = list(dom = "t", paging = FALSE, scrollX = TRUE),
                    caption = htmltools::tags$caption(
                      style = "caption-side: bottom; text-align: left;",
                      "First 5 rows of key clinical variables. ",
                      "submitter_id = MMRF patient ID; age_at_diagnosis = days; ",
                      "iss_stage = International Staging System (I/II/III). ",
                      "Full dataset: ", nrow(clin), " patients x ", ncol(clin), " variables."
                    ))
    },
    packages = c("arrow", "DT", "htmltools")
  ),

  # --- Treatment data preview (data-dictionary) ---
  tar_target(
    vig_treatment_preview,
    {
      trt_file <- file.path(clinical_data, "treatment_data.parquet")
      if (!file.exists(trt_file)) return(NULL)
      trt <- arrow::read_parquet(trt_file)
      preview <- utils::head(trt, 5)
      DT::datatable(preview, rownames = FALSE,
                    options = list(dom = "t", paging = FALSE, scrollX = TRUE),
                    caption = htmltools::tags$caption(
                      style = "caption-side: bottom; text-align: left;",
                      "First 5 treatment records from GDC API. ",
                      "Each row = one drug administration for one patient. ",
                      "regimen_or_line_of_therapy = treatment line (First, Second, etc). ",
                      "Full dataset: ", nrow(trt), " records, ",
                      length(unique(trt$public_id)), " patients."
                    ))
    },
    packages = c("arrow", "DT", "htmltools")
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
    make_age_histogram(eda_clinical_summary),
    packages = c("ggplot2")
  ),

  # --- Gender table ---
  tar_target(
    vig_gender_table,
    make_gender_table(eda_clinical_summary),
    packages = c("DT", "htmltools")
  ),

  # --- Race table ---
  tar_target(
    vig_race_table,
    make_race_table(eda_clinical_summary),
    packages = c("DT", "htmltools")
  ),

  # --- Vital status table ---
  tar_target(
    vig_vital_table,
    make_vital_table(eda_clinical_summary),
    packages = c("DT", "htmltools")
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
    make_iss_table(eda_iss_summary),
    packages = c("DT", "htmltools")
  ),

  # --- ISS barplot ---
  tar_target(
    vig_iss_barplot,
    make_iss_barplot(eda_iss_summary),
    packages = c("ggplot2")
  ),

  # --- Age by ISS table ---
  tar_target(
    vig_iss_age_table,
    make_iss_age_table(eda_iss_summary),
    packages = c("DT", "htmltools")
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
          caption = paste0(
            "Distribution of sample types across ", sum(st$Freq),
            " CoMMpass biospecimens. ",
            "x-axis: sample type category (Primary Tumor, Blood Derived Normal, etc.); ",
            "y-axis: count of samples. ",
            "Key finding: Primary Tumor dominates (",
            max(st$Freq), " samples). ",
            "Source: GDC biospecimen API. ",
            "See data-dictionary biospecimen columns for field definitions."
          )
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(plot.caption = ggplot2::element_text(
          size = 7, hjust = 0, lineheight = 1.2
        ))
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
          caption = paste0(
            "Distribution of samples per patient for ",
            length(bio$samples_per_patient), " CoMMpass patients. ",
            "x-axis: number of biospecimen samples per patient; ",
            "y-axis: number of patients with that count. ",
            "Median = ", median(bio$samples_per_patient),
            " samples; range = ",
            min(bio$samples_per_patient), "-",
            max(bio$samples_per_patient), ". ",
            "Multiple samples may reflect longitudinal collection ",
            "(baseline + relapse). ",
            "Source: GDC biospecimen. ",
            "See paired DE analysis for baseline vs relapse comparisons."
          )
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(plot.caption = ggplot2::element_text(
          size = 7, hjust = 0, lineheight = 1.2
        ))
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
          caption = paste0(
            "Boxplot of per-sample library sizes for ", rna$n_samples,
            " CoMMpass RNA-seq samples. ",
            "y-axis: total mapped reads in millions. ",
            "Median = ", sprintf("%.1f", median(rna$library_sizes) / 1e6),
            "M; range = ", sprintf("%.1f", min(rna$library_sizes) / 1e6),
            "M - ", sprintf("%.1f", max(rna$library_sizes) / 1e6), "M. ",
            "Samples below the 5th percentile are flagged as QC outliers. ",
            "Source: GDC STAR-Counts. ",
            "See QC metrics table for outlier flags and genes-detected histogram."
          )
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(
          axis.text.x = ggplot2::element_blank(),
          axis.ticks.x = ggplot2::element_blank(),
          plot.caption = ggplot2::element_text(
            size = 7, hjust = 0, lineheight = 1.2
          )
        )
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
          caption = paste0(
            "Histogram of genes detected (count > 0) per sample for ",
            rna$n_samples, " CoMMpass RNA-seq samples. ",
            "x-axis: number of genes with at least 1 mapped read; ",
            "y-axis: number of samples. ",
            "Median = ", format(median(rna$genes_detected), big.mark = ","),
            " genes; range = ", format(min(rna$genes_detected), big.mark = ","),
            " - ", format(max(rna$genes_detected), big.mark = ","), ". ",
            "Low detection indicates poor sequencing depth or RNA degradation. ",
            "Source: GDC STAR-Counts. ",
            "See QC metrics table for outlier flags based on this metric."
          )
        ) +
        ggplot2::theme_minimal() +
        ggplot2::theme(plot.caption = ggplot2::element_text(
          size = 7, hjust = 0, lineheight = 1.2
        ))
    },
    packages = c("ggplot2")
  ),

  # --- Cytogenetic frequency table ---
  tar_target(
    vig_cyto_frequency_table,
    make_cyto_frequency_table(cyto_frequency_summary),
    packages = c("DT", "htmltools")
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
    make_cyto_cooccurrence_table(cyto_cooccurrence),
    packages = c("DT", "htmltools")
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
    make_duckdb_demo_simple(eda_duckdb_demo),
    packages = c("DT", "htmltools")
  ),

  # --- DuckDB demo aggregation result ---
  tar_target(
    vig_duckdb_demo_agg,
    make_duckdb_demo_agg(eda_duckdb_demo),
    packages = c("DT", "htmltools")
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
    make_de_method_table(de_method_summary),
    packages = c("DT", "htmltools")
  ),

  # --- DE method barplot ---
  tar_target(
    vig_de_method_barplot,
    make_de_method_barplot(de_method_summary),
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
      p <- plot_volcano(volcano_plot_data, lfc_threshold = 1,
                   padj_threshold = 0.05, n_label = 10,
                   title = "DESeq2 Volcano Plot")
      ggplot2::ggplotGrob(p)
    }
  ),

  # --- MA plot ---
  tar_target(
    vig_ma_plot,
    {
      if (is.null(ma_plot_data)) return(NULL)
      if (nrow(ma_plot_data) == 0) return(NULL)
      p <- plot_ma(ma_plot_data, lfc_threshold = 1, padj_threshold = 0.05,
              title = "DESeq2 MA Plot")
      ggplot2::ggplotGrob(p)
    }
  ),

  # --- Heatmap ---
  tar_target(
    vig_heatmap_plot,
    {
      if (is.null(top_de_heatmap_data)) return(NULL)
      if (is.null(top_de_heatmap_data$expr_matrix)) return(NULL)
      if (is.null(top_de_heatmap_data$de_results)) return(NULL)
      p <- plot_heatmap_de(top_de_heatmap_data$expr_matrix,
                      top_de_heatmap_data$de_results,
                      n_genes = 50, title = "Top 50 DE Genes")
      ggplot2::ggplotGrob(p)
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
      p <- plot_volcano(pr$results_table, lfc_threshold = 1,
                   padj_threshold = 0.05, n_label = 10,
                   title = "Paired DE: Baseline vs Relapse")
      ggplot2::ggplotGrob(p)
    }
  ),

  # --- Annotated DE table ---
  tar_target(
    vig_annotated_de_table,
    make_annotated_de_table(de_results_annotated),
    packages = c("DT", "htmltools")
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
      if (all(is.na(median_os))) {
        n_patients <- if (!is.null(km_overall$fit)) {
          sum(km_overall$fit$n)
        } else NA
        return(paste0(
          "\n**Median overall survival** has not been reached in this cohort",
          if (!is.na(n_patients)) paste0(" (n = ", n_patients, " patients)") else "",
          ". This indicates that more than 50% of patients remain alive at ",
          "last follow-up, which is consistent with improving outcomes in ",
          "multiple myeloma with modern therapies.\n"
        ))
      }
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
    make_cox_basic_table(cox_basic),
    packages = c("DT", "htmltools")
  ),

  # --- Cox full table ---
  tar_target(
    vig_cox_full_table,
    make_cox_full_table(cox_full),
    packages = c("DT", "htmltools")
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
    make_ph_test_table(cox_full, cox_basic),
    packages = c("DT", "htmltools")
  ),

  # --- Cox model comparison table ---
  tar_target(
    vig_cox_comparison,
    make_cox_comparison(cox_basic, cox_full),
    packages = c("DT", "htmltools")
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
      # Return list of grobs (first non-NULL)
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
            "CoMMpass Data Dictionary (",
            nrow(dd_display), " variables). ",
            "Click column headers to sort; use filters to search. ",
            "GDC links open the official GDC data dictionary page. ",
            "Source: GDC clinical + biospecimen + RNA-seq metadata. ",
            "See glossary for term definitions and units-table for measurement conventions."
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
          paste0(
            "Biospecimen data columns for ", nrow(bio), " records (",
            ncol(bio), " variables). ",
            "Column = field name from GDC biospecimen endpoint; ",
            "R Type = data type in R; Non-NA = non-missing count; ",
            "% Complete = data completeness; Unique Values = cardinality. ",
            "Source: GDC biospecimen API. ",
            "See clinical table for patient-level demographics and ",
            "exploratory-analysis for sample-type distribution."
          )
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
          paste0(
            "RNA-seq sample metadata columns from the SummarizedExperiment colData (",
            nrow(sample_cols), " columns, ", ncol(se), " samples). ",
            "Column = metadata field name; Type = R class; ",
            "N_Unique = number of distinct values. ",
            "Source: GDC mRNA-seq pipeline via TCGAbiolinks. ",
            "See data-dictionary clinical table for patient-level variables."
          )
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
          paste0(
            "GDC column name mappings to common aliases used in analysis code (",
            nrow(mappings), " mappings). ",
            "GDC_Column = official GDC field name; ",
            "Common_Alias = shorthand used in pipeline code. ",
            "Key: age_at_diagnosis is in DAYS (not years); ",
            "vital_status determines whether days_to_death or ",
            "days_to_last_follow_up is used for OS time. ",
            "See data-dictionary for full variable definitions."
          )
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
      # (targets >= 1.10). Build visNetwork widget from tar_manifest()
      # with layer-based coloring matching inst/shinylive/pipeline_dag.qmd.
      manifest <- targets::tar_manifest()

      # --- Layer assignment (same patterns as Shinylive DAG) ---
      layer_patterns <- c(
        "^(raw_rnaseq|clinical_data$|fetch_)" = "data-acquisition",
        "^(clinical_data_clean|expression_data_clean|integrated|filtered|normalized)" = "data-cleaning",
        "^(cyto|fish_)" = "cytogenetics",
        "^(qc_|data_quality)" = "quality-control",
        "^(deseq2|edger|limma|consensus_de)" = "differential-expression",
        "^(survival|cox_|km_)" = "survival",
        "^(gsea|pathway|gene_annot)" = "pathway",
        "^(eda_)" = "eda",
        "^(save_|parquet|duckdb)" = "storage",
        "^(api_|shiny_)" = "api",
        "^(vig_|code_|doc_|readme_|glossary)" = "documentation",
        "^(config|nix_|dag_|pkgctx)" = "infrastructure"
      )
      layer_colors <- c(
        "data-acquisition" = "#4CAF50", "data-cleaning" = "#2196F3",
        "cytogenetics" = "#9C27B0", "quality-control" = "#FF9800",
        "differential-expression" = "#F44336", "survival" = "#00BCD4",
        "pathway" = "#E91E63", "eda" = "#8BC34A",
        "storage" = "#795548", "api" = "#607D8B",
        "documentation" = "#CDDC39", "infrastructure" = "#9E9E9E",
        "other" = "#BDBDBD"
      )
      assign_layer <- function(nm) {
        for (pat in names(layer_patterns)) {
          if (grepl(pat, nm)) return(layer_patterns[[pat]])
        }
        "other"
      }

      # --- Build nodes ---
      layers <- vapply(manifest$name, assign_layer, character(1),
                        USE.NAMES = FALSE)
      colors <- unname(layer_colors[layers])
      nodes <- data.frame(
        id = manifest$name,
        label = manifest$name,
        group = layers,
        color = colors,
        title = paste0("<b>", manifest$name, "</b><br>Layer: ", layers),
        stringsAsFactors = FALSE
      )

      # --- Infer edges from command text references ---
      edges_list <- lapply(seq_len(nrow(manifest)), function(i) {
        cmd <- manifest$command[i]
        refs <- manifest$name[manifest$name != manifest$name[i] &
                                vapply(manifest$name, function(nm) {
                                  grepl(paste0("\\b", nm, "\\b"), cmd)
                                }, logical(1))]
        if (length(refs) > 0) {
          data.frame(from = refs, to = manifest$name[i],
                      stringsAsFactors = FALSE)
        }
      })
      edges <- do.call(rbind, edges_list)
      if (is.null(edges)) edges <- data.frame(from = character(0),
                                                to = character(0))

      # --- Build visNetwork widget ---
      n_targets <- nrow(manifest)
      n_layers <- length(unique(layers))
      n_edges <- if (!is.null(edges)) nrow(edges) else 0

      widget <- visNetwork::visNetwork(
        nodes, edges,
        main = paste("Pipeline DAG:", n_targets, "targets"),
        height = "600px", width = "100%"
      ) |>
        visNetwork::visEdges(arrows = "to", color = list(opacity = 0.4)) |>
        visNetwork::visOptions(
          highlightNearest = list(enabled = TRUE, degree = 1),
          nodesIdSelection = TRUE
        ) |>
        visNetwork::visLegend(useGroups = TRUE, position = "right") |>
        visNetwork::visPhysics(stabilization = list(iterations = 200))

      caption_html <- htmltools::tags$figcaption(
        style = "text-align: left; font-size: 0.85em; margin-top: 0.5em; line-height: 1.4;",
        paste0(
          "Interactive pipeline DAG with ", n_targets, " targets across ",
          n_layers, " layers and ", n_edges, " dependency edges. ",
          "Nodes are colored by layer (data-acquisition, cleaning, cytogenetics, QC, ",
          "DE, survival, pathway, EDA, storage, API, documentation, infrastructure). ",
          "Click a node to highlight its direct dependencies; use the dropdown to find targets by name. ",
          "Hover for target name and layer. ",
          "Source: targets::tar_manifest(). ",
          "See project-overview for architectural description and telemetry for build metrics."
        )
      )

      htmltools::tagList(widget, caption_html)
    },
    packages = c("targets", "visNetwork", "htmltools")
  ),

  # --- Git info table (shared by all vignettes) ---
  tar_target(
    vig_git_info,
    make_git_info(),
    packages = c("gert", "DT", "htmltools")
  ),

  # ================================================================
  # Code provenance targets (code_vig_*)
  # Each extracts the body of a named visualization function as text,
  # so vignettes can show the generating code instead of safe_tar_read().
  # ================================================================

  tar_target(code_vig_de_method_barplot, {
    paste(deparse(body(make_de_method_barplot)), collapse = "\n")
  }),
  tar_target(code_vig_de_method_table, {
    paste(deparse(body(make_de_method_table)), collapse = "\n")
  }),
  tar_target(code_vig_annotated_de_table, {
    paste(deparse(body(make_annotated_de_table)), collapse = "\n")
  }),
  tar_target(code_vig_age_histogram, {
    paste(deparse(body(make_age_histogram)), collapse = "\n")
  }),
  tar_target(code_vig_count_distribution_plot, {
    paste(deparse(body(make_count_distribution_plot)), collapse = "\n")
  }),
  tar_target(code_vig_gender_table, {
    paste(deparse(body(make_gender_table)), collapse = "\n")
  }),
  tar_target(code_vig_race_table, {
    paste(deparse(body(make_race_table)), collapse = "\n")
  }),
  tar_target(code_vig_vital_table, {
    paste(deparse(body(make_vital_table)), collapse = "\n")
  }),
  tar_target(code_vig_iss_table, {
    paste(deparse(body(make_iss_table)), collapse = "\n")
  }),
  tar_target(code_vig_iss_barplot, {
    paste(deparse(body(make_iss_barplot)), collapse = "\n")
  }),
  tar_target(code_vig_iss_age_table, {
    paste(deparse(body(make_iss_age_table)), collapse = "\n")
  }),
  tar_target(code_vig_cox_basic_table, {
    paste(deparse(body(make_cox_basic_table)), collapse = "\n")
  }),
  tar_target(code_vig_cox_full_table, {
    paste(deparse(body(make_cox_full_table)), collapse = "\n")
  }),
  tar_target(code_vig_ph_test_table, {
    paste(deparse(body(make_ph_test_table)), collapse = "\n")
  }),
  tar_target(code_vig_cox_comparison, {
    paste(deparse(body(make_cox_comparison)), collapse = "\n")
  }),
  tar_target(code_vig_cyto_frequency_table, {
    paste(deparse(body(make_cyto_frequency_table)), collapse = "\n")
  }),
  tar_target(code_vig_cyto_cooccurrence_table, {
    paste(deparse(body(make_cyto_cooccurrence_table)), collapse = "\n")
  }),
  tar_target(code_vig_duckdb_demo_simple, {
    paste(deparse(body(make_duckdb_demo_simple)), collapse = "\n")
  }),
  tar_target(code_vig_duckdb_demo_agg, {
    paste(deparse(body(make_duckdb_demo_agg)), collapse = "\n")
  }),
  tar_target(code_vig_git_info, {
    paste(deparse(body(make_git_info)), collapse = "\n")
  }),

  # ================================================================
  # glossary.qmd targets
  # ================================================================

  # --- Units reference table ---
  tar_target(
    vig_units_table,
    {
      units_df <- data.frame(
        Variable = c(
          "age_at_diagnosis", "days_to_death", "days_to_last_follow_up",
          "days_to_last_known_disease_status",
          "unstranded / stranded_*", "tpm_unstranded", "fpkm_unstranded"
        ),
        Unit = c("days", "days", "days", "days",
                 "raw integer counts", "TPM", "FPKM"),
        Conversion_or_Notes = c(
          "age_years = age_at_diagnosis / 365.25",
          "Used directly in survival analysis",
          "Censoring time for survival",
          "Disease assessment time",
          "Input for DESeq2/edgeR",
          "Cross-sample comparison (transcripts per million)",
          "Largely deprecated, use TPM"
        ),
        stringsAsFactors = FALSE
      )

      caption <- paste0(
        "Unit reference for ", nrow(units_df), " key variables. ",
        "All time/age variables are in DAYS (GDC convention); ",
        "divide by 365.25 for years. ",
        "Expression units: raw counts for DE analysis (DESeq2/edgeR), ",
        "TPM for cross-sample comparison, FPKM is deprecated. ",
        "Source: GDC data model. ",
        "See data-dictionary for full variable definitions."
      )

      DT::datatable(
        units_df,
        colnames = c("Variable", "Unit", "Conversion / Notes"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE)
      )
    },
    packages = c("DT", "htmltools")
  ),

  # ================================================================
  # data-sources.qmd targets
  # ================================================================

  # --- MSigDB parquet stats ---
  tar_target(
    vig_msigdb_stats,
    {
      msigdb_dir <- file.path("inst", "extdata", "msigdb")
      if (!dir.exists(msigdb_dir)) return(NULL)
      parquet_files <- list.files(msigdb_dir, pattern = "\\.parquet$",
                                  full.names = TRUE)
      if (length(parquet_files) == 0) return(NULL)
      stats_df <- do.call(rbind, lapply(parquet_files, function(f) {
        tbl <- arrow::read_parquet(f)
        data.frame(
          File = basename(f),
          Size = paste0(round(file.size(f) / 1024, 1), " KB"),
          Rows = nrow(tbl),
          Columns = ncol(tbl),
          Gene_Sets = length(unique(tbl$gs_name)),
          Unique_Genes = length(unique(tbl$ensembl_gene)),
          ID_Type = "Ensembl",
          stringsAsFactors = FALSE
        )
      }))

      total_sets <- sum(stats_df$Gene_Sets)
      total_genes <- max(stats_df$Unique_Genes)
      caption <- paste0(
        "MSigDB gene set collections bundled in inst/extdata/msigdb/ (",
        nrow(stats_df), " parquet files). ",
        "Total: ", total_sets, " gene sets across ",
        format(total_genes, big.mark = ","), " unique Ensembl gene IDs. ",
        "Gene_Sets = distinct pathways per collection; ",
        "Unique_Genes = genes annotated in that collection. ",
        "Source: MSigDB Hallmark + KEGG via msigdbr. ",
        "See differential-expression GSEA/ORA sections for enrichment results."
      )

      DT::datatable(
        stats_df,
        colnames = c("File", "Size", "Rows", "Columns",
                      "Gene Sets", "Unique Genes", "ID Type"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE, scrollX = TRUE)
      )
    },
    packages = c("arrow", "DT", "htmltools")
  ),

  # ================================================================
  # gene-report.qmd targets (require Bioconductor — guarded stubs)
  # ================================================================

  tar_target(
    vig_gene_expression_dist,
    {
      if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) return(NULL)
      if (is.null(vst_counts)) return(NULL)
      gene_symbol <- "CD70"
      gene_id <- resolve_gene_id(gene_symbol, vst_counts)
      if (is.na(gene_id)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")
      expr_vals <- as.numeric(vst_mat[gene_id, ])
      df <- data.frame(expression = expr_vals)
      med_val <- round(median(expr_vals), 2)
      sd_val <- round(sd(expr_vals), 2)
      n_samp <- length(expr_vals)

      p <- ggplot2::ggplot(df, ggplot2::aes(x = expression)) +
        ggplot2::geom_histogram(bins = 30, fill = "#2166AC", alpha = 0.7) +
        ggplot2::geom_vline(xintercept = median(expr_vals), linetype = "dashed",
                            color = "#B2182B") +
        ggplot2::labs(
          title = paste0(gene_symbol, " Expression Distribution"),
          subtitle = paste0("n = ", n_samp, " samples | ",
                            "Median = ", med_val,
                            " | SD = ", sd_val),
          x = "VST Expression", y = "Count",
          caption = paste0(
            "Distribution of ", gene_symbol, " VST-normalized expression across ",
            n_samp, " CoMMpass bone marrow samples. ",
            "x-axis: variance-stabilized transformed counts (DESeq2 vst()); ",
            "y-axis: number of samples. ",
            "Dashed red line = median (", med_val, "); SD = ", sd_val, ". ",
            "VST stabilizes variance across the expression range. ",
            "Source: GDC STAR-Counts. ",
            "See DE volcano plot for differential expression of this gene."
          )
        ) +
        ggplot2::theme_minimal(base_size = 12) +
        ggplot2::theme(plot.caption = ggplot2::element_text(
          size = 7, hjust = 0, lineheight = 1.2
        ))
      # Remove large objects from aes() quosure environment before serializing
      rm(vst_counts, vst_mat, expr_vals, gene_id)
      p
    },
    packages = c("ggplot2")
  ),

  tar_target(
    vig_gene_km_expression,
    {
      if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) return(NULL)
      if (is.null(vst_counts) || is.null(survival_data)) return(NULL)
      gene_symbol <- "CD70"
      gene_id <- resolve_gene_id(gene_symbol, vst_counts)
      if (is.na(gene_id)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")
      km_res <- run_km_by_expression(
        survival_data, vst_mat, gene = gene_id, split = "median"
      )
      if (is.null(km_res$fit)) return(NULL)
      p <- plot_km(km_res,
        title = paste0("Survival by ", gene_symbol, " Expression (Median Split)"))

      n_high <- km_res$n_per_group["High"]
      n_low <- km_res$n_per_group["Low"]
      logrank_p <- if (!is.na(km_res$logrank_p)) {
        if (km_res$logrank_p < 0.001) "< 0.001" else sprintf("%.3f", km_res$logrank_p)
      } else "NA"

      p + ggplot2::labs(caption = paste0(
        "KM survival curves for ", gene_symbol, " high (n = ", n_high,
        ") vs low (n = ", n_low, ") expression groups (median split of VST values). ",
        "x-axis: time in days from diagnosis; y-axis: survival probability. ",
        "Shaded bands = 95% CI. Log-rank p = ", logrank_p, ". ",
        "Source: GDC clinical (OS) + STAR-Counts (VST). ",
        "See survival-analysis for multivariate Cox models adjusting for clinical covariates."
      )) +
        ggplot2::theme(plot.caption = ggplot2::element_text(
          size = 7, hjust = 0, lineheight = 1.2
        ))
    },
    packages = c("ggplot2")
  ),

  tar_target(
    vig_gene_expr_subtype,
    {
      if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) return(NULL)
      if (is.null(vst_counts) || is.null(cytogenetic_data)) return(NULL)
      gene_symbol <- "CD70"
      gene_id <- resolve_gene_id(gene_symbol, vst_counts)
      if (is.na(gene_id)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")
      cyto_df <- if (is.character(cytogenetic_data) && file.exists(cytogenetic_data)) {
        arrow::read_parquet(cytogenetic_data)
      } else if (is.data.frame(cytogenetic_data)) {
        cytogenetic_data
      } else {
        NULL
      }
      if (is.null(cyto_df)) return(NULL)
      p <- plot_expression_by_subtype(vst_mat, cyto_df, gene = gene_id)
      p <- p + ggplot2::labs(caption = paste0(
        gene_symbol, " VST expression across cytogenetic subtypes defined by FISH markers. ",
        "Each box = IQR of VST values; whiskers = 1.5x IQR; dots = outliers. ",
        "Subtypes: t(4;14), t(11;14), t(14;16), del(17p), gain(1q), standard-risk. ",
        "Comparison: Wilcoxon rank-sum between each subtype vs rest. ",
        "Source: GDC STAR-Counts (VST) + FISH data. ",
        "See exploratory-analysis cytogenetic landscape for alteration frequencies."
      )) +
        ggplot2::theme(plot.caption = ggplot2::element_text(
          size = 7, hjust = 0, lineheight = 1.2
        ))
      rm(vst_counts, vst_mat, cyto_df, gene_id)
      ggplot2::ggplotGrob(p)
    },
    packages = c("ggplot2")
  ),

  tar_target(
    vig_gene_correlations,
    {
      if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) return(NULL)
      if (is.null(vst_counts)) return(NULL)
      gene_symbol <- "CD70"
      gene_id <- resolve_gene_id(gene_symbol, vst_counts)
      if (is.na(gene_id)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")
      gene_vars <- apply(vst_mat, 1, var)
      top_candidates <- names(sort(gene_vars, decreasing = TRUE))[1:500]
      top_candidates <- setdiff(top_candidates, gene_id)
      cor_batch <- correlate_genes_batch(
        vst_mat, target_gene = gene_id,
        candidate_genes = top_candidates, method = "pearson"
      )
      if (nrow(cor_batch) == 0) return(NULL)
      top10 <- head(cor_batch[, c("gene", "estimate", "p_value", "padj")], 10)
      top10$estimate <- round(top10$estimate, 3)
      top10$p_value <- signif(top10$p_value, 4)
      top10$padj <- signif(top10$padj, 4)

      top_gene <- top10$gene[1]
      top_r <- top10$estimate[1]
      n_samples <- ncol(vst_mat)
      caption <- paste0(
        "Top 10 genes most correlated with ", gene_symbol,
        " (Pearson r, VST-normalized expression, n = ", n_samples, " samples). ",
        "Strongest correlation: ", top_gene, " (r = ", top_r, "). ",
        "estimate = Pearson correlation coefficient; ",
        "p_value = unadjusted; padj = BH-corrected. ",
        "Candidates: top 500 most variable genes. ",
        "See scatter plot below for visualization of the top correlation."
      )

      DT::datatable(
        top10,
        colnames = c("Gene", "Pearson r", "p-value", "Adjusted p"),
        caption = htmltools::tags$caption(
          style = "caption-side: top; text-align: left;", caption
        ),
        rownames = FALSE,
        options = list(dom = "t", paging = FALSE)
      )
    },
    packages = c("DT", "htmltools")
  ),

  tar_target(
    vig_gene_correlation_plot,
    {
      if (!requireNamespace("SummarizedExperiment", quietly = TRUE)) return(NULL)
      if (is.null(vst_counts)) return(NULL)
      gene_symbol <- "CD70"
      gene_id <- resolve_gene_id(gene_symbol, vst_counts)
      if (is.na(gene_id)) return(NULL)
      vst_mat <- SummarizedExperiment::assay(vst_counts, "vst")
      gene_vars <- apply(vst_mat, 1, var)
      top_candidates <- names(sort(gene_vars, decreasing = TRUE))[1:500]
      top_candidates <- setdiff(top_candidates, gene_id)
      cor_batch <- correlate_genes_batch(
        vst_mat, target_gene = gene_id,
        candidate_genes = top_candidates, method = "pearson"
      )
      if (nrow(cor_batch) == 0) return(NULL)
      top_gene <- cor_batch$gene[1]
      cor_res <- correlate_genes(vst_mat, gene_id, top_gene)
      r_val <- round(cor_res$estimate, 3)
      p_val <- if (cor_res$p_value < 0.001) "< 0.001" else sprintf("%.4f", cor_res$p_value)
      n_samp <- ncol(vst_mat)

      p <- plot_gene_correlation(cor_res)
      p <- p + ggplot2::labs(caption = paste0(
        "Scatter plot of ", gene_symbol, " vs ", top_gene,
        " VST expression (Pearson r = ", r_val,
        ", p ", p_val, ", n = ", n_samp, " samples). ",
        "Each point = one patient sample; blue line = linear regression fit. ",
        "VST values are variance-stabilized counts (DESeq2). ",
        top_gene, " is the most correlated gene from the top 500 most variable. ",
        "Source: GDC STAR-Counts. ",
        "See correlations table above for the full top-10 list."
      )) +
        ggplot2::theme(plot.caption = ggplot2::element_text(
          size = 7, hjust = 0, lineheight = 1.2
        ))
      rm(vst_counts, vst_mat, gene_id, cor_batch, cor_res)
      p
    },
    packages = c("ggplot2")
  )
)
