# R/tar_plans/plan_eda.R
# Pre-compute EDA summaries consumed by vignettes/exploratory-analysis.Rmd

plan_eda <- list(

  # --- Clinical demographics summary ---
  tar_target(
    eda_clinical_summary,
    {
      if (is.null(clinical_data) || !is.data.frame(clinical_data)) {
        return(NULL)
      }
      clin <- clinical_data
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
    },
    packages = c("dplyr")
  ),

  # --- Biospecimen summary ---
  tar_target(
    eda_biospecimen_summary,
    {
      if (is.null(biospecimen_data) || !is.data.frame(biospecimen_data)) {
        return(NULL)
      }
      bio <- biospecimen_data
      names(bio) <- make.unique(names(bio))

      # Samples per patient
      id_col <- intersect(c("submitter_id", "case_submitter_id"), names(bio))
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
    },
    packages = c("dplyr")
  ),

  # --- RNA-seq quality summary ---
  tar_target(
    eda_rnaseq_summary,
    {
      if (is.null(rnaseq_counts) || !is.data.frame(rnaseq_counts)) {
        return(NULL)
      }
      # rnaseq_counts is a data.frame from arrow::read_parquet
      # Expect gene identifiers in first column, samples in remaining columns
      count_cols <- names(rnaseq_counts)

      # Detect gene ID column (non-numeric or first column)
      gene_col <- NULL
      numeric_cols <- sapply(rnaseq_counts, is.numeric)
      if (!numeric_cols[1]) {
        gene_col <- count_cols[1]
        mat <- as.matrix(rnaseq_counts[, numeric_cols, drop = FALSE])
      } else {
        mat <- as.matrix(rnaseq_counts)
      }

      library_sizes   <- colSums(mat)
      genes_detected  <- colSums(mat > 0)
      sparsity        <- mean(mat == 0)

      list(
        n_genes        = nrow(mat),
        n_samples      = ncol(mat),
        library_sizes  = library_sizes,
        genes_detected = genes_detected,
        sparsity       = sparsity,
        total_counts   = sum(mat),
        median_library_size = median(library_sizes)
      )
    }
  ),

  # --- DuckDB query demo (pre-run so vignette shows output) ---
  tar_target(
    eda_duckdb_demo,
    {
      parquet_path <- file.path(
        config$data_dir, "raw", "clinical", "clinical_data.parquet"
      )
      if (!file.exists(parquet_path)) return(NULL)

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

      DBI::dbExecute(con, paste0(
        "CREATE VIEW clinical AS SELECT * FROM read_parquet('",
        parquet_path, "')"
      ))

      # Example 1: simple SELECT with filter
      demo_query_sql <- "SELECT submitter_id, gender, vital_status, age_at_diagnosis
                         FROM clinical
                         LIMIT 10"
      demo_result <- DBI::dbGetQuery(con, demo_query_sql)

      # Example 2: aggregation
      agg_query_sql <- "SELECT gender, COUNT(*) AS n,
                          ROUND(AVG(age_at_diagnosis / 365.25), 1) AS mean_age_years
                        FROM clinical
                        WHERE gender IS NOT NULL
                        GROUP BY gender"
      agg_result <- DBI::dbGetQuery(con, agg_query_sql)

      list(
        demo_sql    = demo_query_sql,
        demo_result = demo_result,
        agg_sql     = agg_query_sql,
        agg_result  = agg_result
      )
    },
    packages = c("DBI", "duckdb")
  ),

  # --- Cross-dataset integration summary ---
  tar_target(
    eda_integration_summary,
    {
      if (is.null(clinical_data) || !is.data.frame(clinical_data)) return(NULL)
      if (is.null(biospecimen_data) || !is.data.frame(biospecimen_data)) return(NULL)

      clin_ids <- unique(clinical_data$submitter_id)
      bio_id_col <- intersect(
        c("submitter_id", "case_submitter_id"), names(biospecimen_data)
      )
      if (length(bio_id_col) == 0) return(NULL)

      bio_ids <- unique(biospecimen_data[[bio_id_col[1]]])
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
