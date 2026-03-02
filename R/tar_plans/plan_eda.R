# R/tar_plans/plan_eda.R
# Pre-compute EDA summaries consumed by vignettes/exploratory-analysis.Rmd
#
# Data architecture: acquisition targets store FILE PATHS, not data frames.
#   - clinical_data  = "data/raw/clinical" (directory containing .rds/.csv)
#   - raw_rnaseq     = "data/raw/gdc/rnaseq_se.rds" (path to SE object)
# Each EDA target loads data from these paths.

plan_eda <- list(

  # --- Clinical demographics summary ---
  tar_target(
    eda_clinical_summary,
    {
      # clinical_data is a directory path; load the RDS from it
      pq_path <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(pq_path)) return(NULL)
      clin <- arrow::read_parquet(pq_path)
      if (!is.data.frame(clin) || nrow(clin) == 0) return(NULL)
      names(clin) <- make.unique(names(clin))

      # Age in years (GDC stores age_at_diagnosis in days)
      age_years <- NULL
      if ("age_at_diagnosis" %in% names(clin) &&
          is.numeric(clin$age_at_diagnosis)) {
        vals <- clin$age_at_diagnosis[!is.na(clin$age_at_diagnosis)]
        is_days <- length(vals) > 0 && max(vals, na.rm = TRUE) > 120
        age_years <- if (is_days) vals / 365.25 else vals
      }

      list(
        n_patients    = nrow(clin),
        n_variables   = ncol(clin),
        completeness  = mean(!is.na(clin)),
        age_years     = age_years,
        gender_table  = if ("gender" %in% names(clin))
          as.data.frame(table(Gender = clin$gender, useNA = "ifany")) else NULL,
        race_table    = if ("race" %in% names(clin))
          as.data.frame(table(Race = clin$race, useNA = "ifany")) else NULL,
        vital_table   = if ("vital_status" %in% names(clin))
          as.data.frame(table(Status = clin$vital_status, useNA = "ifany")) else NULL,
        days_to_death = if ("days_to_death" %in% names(clin))
          summary(clin$days_to_death[!is.na(clin$days_to_death)]) else NULL,
        days_to_last_followup = if ("days_to_last_follow_up" %in% names(clin))
          summary(clin$days_to_last_follow_up[!is.na(clin$days_to_last_follow_up)]) else NULL
      )
    }
  ),

  # --- Biospecimen summary ---
  tar_target(
    eda_biospecimen_summary,
    {
      # biospecimen lives in the same directory as clinical_data
      pq_path <- file.path(clinical_data, "biospecimen_data.parquet")
      if (!file.exists(pq_path)) return(NULL)
      bio <- arrow::read_parquet(pq_path)
      if (!is.data.frame(bio) || nrow(bio) == 0) return(NULL)
      names(bio) <- make.unique(names(bio))

      # Samples per patient
      id_col <- intersect(c("submitter_id", "case_submitter_id", "patient_id"),
                          names(bio))
      samples_per_patient <- if (length(id_col) > 0) {
        tbl <- table(bio[[id_col[1]]])
        as.numeric(tbl)
      } else {
        NULL
      }

      list(
        n_samples     = nrow(bio),
        n_variables   = ncol(bio),
        sample_type_table = if ("sample_type" %in% names(bio))
          as.data.frame(table(Sample_Type = bio$sample_type, useNA = "ifany")) else NULL,
        tissue_type_table = if ("tissue_type" %in% names(bio))
          as.data.frame(table(Tissue_Type = bio$tissue_type, useNA = "ifany")) else NULL,
        samples_per_patient = samples_per_patient,
        id_col_used   = if (length(id_col) > 0) id_col[1] else NA_character_
      )
    }
  ),

  # --- RNA-seq quality summary ---
  tar_target(
    eda_rnaseq_summary,
    {
      # raw_rnaseq is the file path to the SummarizedExperiment RDS
      if (!file.exists(raw_rnaseq)) return(NULL)
      se <- readRDS(raw_rnaseq)

      # Extract count matrix from SE
      mat <- NULL
      if (inherits(se, "SummarizedExperiment")) {
        assay_names <- SummarizedExperiment::assayNames(se)
        if ("unstranded" %in% assay_names) {
          mat <- SummarizedExperiment::assay(se, "unstranded")
        } else if ("counts" %in% assay_names) {
          mat <- SummarizedExperiment::assay(se, "counts")
        } else if (length(assay_names) > 0) {
          mat <- SummarizedExperiment::assay(se, 1)
        }
      } else if (is.matrix(se)) {
        mat <- se
      }

      if (is.null(mat) || nrow(mat) == 0) return(NULL)

      library_sizes   <- colSums(mat)
      genes_detected  <- colSums(mat > 0)
      sparsity        <- mean(mat == 0)

      list(
        n_genes        = nrow(mat),
        n_samples      = ncol(mat),
        library_sizes  = library_sizes,
        genes_detected = genes_detected,
        sparsity       = sparsity,
        total_counts   = sum(as.numeric(mat)),
        median_library_size = median(library_sizes)
      )
    },
    packages = c("SummarizedExperiment")
  ),

  # --- DuckDB query demo (pre-run so vignette shows output) ---
  tar_target(
    eda_duckdb_demo,
    {
      # Query clinical parquet directly with DuckDB
      pq_path <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(pq_path)) return(NULL)

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

      DBI::dbExecute(con, paste0(
        "CREATE VIEW clinical AS SELECT * FROM read_parquet('",
        pq_path, "')"
      ))

      # Example 1: simple select via dplyr/tbl
      clinical_tbl <- dplyr::tbl(con, "clinical")
      demo_result <- clinical_tbl |>
        dplyr::select(submitter_id, gender, vital_status,
                      age_at_diagnosis) |>
        utils::head(10) |>
        dplyr::collect()

      # Example 2: aggregation via dplyr/tbl
      agg_result <- clinical_tbl |>
        dplyr::filter(!is.na(gender), age_at_diagnosis != "NA") |>
        dplyr::group_by(gender) |>
        dplyr::summarise(
          n = dplyr::n(),
          mean_age_years = round(mean(as.numeric(age_at_diagnosis) / 365.25,
                                       na.rm = TRUE), 1)
        ) |>
        dplyr::collect()

      list(
        demo_result = demo_result,
        agg_result  = agg_result
      )
    },
    packages = c("DBI", "duckdb", "arrow", "dplyr")
  ),

  # --- ISS staging summary (#42) ---
  tar_target(
    eda_iss_summary,
    {
      pq_path <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(pq_path)) return(NULL)
      clin <- arrow::read_parquet(pq_path)
      if (!is.data.frame(clin) || nrow(clin) == 0) return(NULL)
      names(clin) <- tolower(make.unique(names(clin)))

      # Find ISS column (various possible names from GDC)
      iss_col <- grep("^iss|staging_system", names(clin), value = TRUE)
      if (length(iss_col) == 0) {
        return(list(available = FALSE, note = "No ISS column found in clinical data"))
      }

      iss_vals <- clin[[iss_col[1]]]
      iss_vals[iss_vals %in% c("", "Not Reported", "not reported")] <- NA

      iss_table <- as.data.frame(
        table(ISS_Stage = iss_vals, useNA = "ifany"),
        stringsAsFactors = FALSE
      )
      iss_table$Percentage <- sprintf("%.1f%%", 100 * iss_table$Freq / sum(iss_table$Freq))

      # Age by ISS (if age available)
      age_col <- intersect(c("age_at_diagnosis", "age_at_index"), names(clin))
      age_by_iss <- NULL
      if (length(age_col) > 0 && sum(!is.na(iss_vals)) > 0) {
        age_raw <- as.numeric(clin[[age_col[1]]])
        is_days <- max(age_raw, na.rm = TRUE) > 120
        age_years <- if (is_days) age_raw / 365.25 else age_raw

        valid <- !is.na(iss_vals) & !is.na(age_years)
        if (sum(valid) > 0) {
          age_by_iss <- tapply(age_years[valid], iss_vals[valid], function(x) {
            list(n = length(x), mean = mean(x), median = median(x), sd = sd(x))
          })
        }
      }

      list(
        available = TRUE,
        iss_col = iss_col[1],
        n_with_iss = sum(!is.na(iss_vals)),
        n_missing = sum(is.na(iss_vals)),
        iss_table = iss_table,
        age_by_iss = age_by_iss
      )
    }
  ),

  # --- QC metrics formatted for vignette display ---
  tar_target(
    eda_qc_summary,
    {
      # qc_metrics is a target dependency (data frame from calculate_qc_metrics)
      if (!is.data.frame(qc_metrics) || nrow(qc_metrics) == 0) return(NULL)

      formatted <- data.frame(
        Sample = qc_metrics$sample,
        `Total Counts` = format(qc_metrics$total_counts, big.mark = ","),
        `Detected Genes` = format(qc_metrics$detected_genes, big.mark = ","),
        `Median Count` = sprintf("%.1f", qc_metrics$median_count),
        `MAD Count` = sprintf("%.1f", qc_metrics$mad_count),
        `Size Factor` = sprintf("%.3f", qc_metrics$size_factor),
        Outlier = ifelse(qc_metrics$is_outlier, "Yes", "No"),
        check.names = FALSE,
        stringsAsFactors = FALSE
      )

      list(
        table = formatted,
        n_samples = nrow(qc_metrics),
        n_outliers = sum(qc_metrics$is_outlier),
        caption = sprintf(
          paste0(
            "Per-sample QC metrics for %d samples. ",
            "Total Counts = library size, ",
            "Detected Genes = genes with >0 counts, ",
            "Size Factor = library size / median library size. ",
            "%d outlier(s) flagged (bottom 5%% by library size or genes detected). ",
            "Data: GDC STAR-Counts pipeline."
          ),
          nrow(qc_metrics), sum(qc_metrics$is_outlier)
        )
      )
    }
  ),

  # --- Missing data summary (only variables WITH missing data) ---
  tar_target(
    eda_missing_summary,
    {
      pq_path <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(pq_path)) return(NULL)
      clin <- arrow::read_parquet(pq_path)
      if (!is.data.frame(clin) || nrow(clin) == 0) return(NULL)

      n_vars <- ncol(clin)
      missing_counts <- colSums(is.na(clin))
      has_missing <- missing_counts > 0
      n_complete <- sum(!has_missing)

      if (sum(has_missing) == 0) {
        return(list(
          all_complete = TRUE,
          n_vars = n_vars,
          n_complete = n_complete,
          missing_table = NULL,
          caption = sprintf(
            "All %d variables are fully complete (0%% missing).", n_vars
          )
        ))
      }

      missing_df <- data.frame(
        Variable = names(missing_counts[has_missing]),
        `Missing Count` = as.integer(missing_counts[has_missing]),
        `Missing Percent` = sprintf(
          "%.1f%%", 100 * missing_counts[has_missing] / nrow(clin)
        ),
        check.names = FALSE,
        stringsAsFactors = FALSE
      )
      missing_df <- missing_df[order(-missing_df$`Missing Count`), ]
      rownames(missing_df) <- NULL

      list(
        all_complete = FALSE,
        n_vars = n_vars,
        n_complete = n_complete,
        missing_table = missing_df,
        caption = sprintf(
          "%d of %d variables are fully complete (0%% missing). "
        , n_complete, n_vars
        )
      )
    }
  ),

  # --- Cross-dataset integration summary ---
  tar_target(
    eda_integration_summary,
    {
      # Load both clinical and biospecimen from the clinical_data directory
      clin_path <- file.path(clinical_data, "clinical_data.parquet")
      bio_path  <- file.path(clinical_data, "biospecimen_data.parquet")
      if (!file.exists(clin_path) || !file.exists(bio_path)) return(NULL)

      clin <- arrow::read_parquet(clin_path)
      bio  <- arrow::read_parquet(bio_path)
      if (!is.data.frame(clin) || !is.data.frame(bio)) return(NULL)

      clin_ids <- unique(clin$submitter_id)
      bio_id_col <- intersect(
        c("submitter_id", "case_submitter_id", "patient_id"), names(bio)
      )
      if (length(bio_id_col) == 0) return(NULL)

      bio_ids <- unique(bio[[bio_id_col[1]]])
      shared  <- intersect(clin_ids, bio_ids)

      list(
        n_clinical_patients     = length(clin_ids),
        n_biospecimen_patients  = length(bio_ids),
        n_shared                = length(shared),
        n_clinical_only         = length(setdiff(clin_ids, bio_ids)),
        n_biospecimen_only      = length(setdiff(bio_ids, clin_ids)),
        bio_id_col_used         = bio_id_col[1]
      )
    }
  )
)
