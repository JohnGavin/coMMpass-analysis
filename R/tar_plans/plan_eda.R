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
      rds_path <- file.path(clinical_data, "clinical_data.rds")
      if (!file.exists(rds_path)) return(NULL)
      clin <- readRDS(rds_path)
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
      rds_path <- file.path(clinical_data, "biospecimen_data.rds")
      if (!file.exists(rds_path)) return(NULL)
      bio <- readRDS(rds_path)
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
      # Load clinical data from RDS, write temp parquet, query with DuckDB
      rds_path <- file.path(clinical_data, "clinical_data.rds")
      if (!file.exists(rds_path)) return(NULL)
      clin <- readRDS(rds_path)
      if (!is.data.frame(clin) || nrow(clin) == 0) return(NULL)

      # Write to a temporary parquet for the DuckDB demo
      tmp_parquet <- tempfile(fileext = ".parquet")
      arrow::write_parquet(clin, tmp_parquet)
      on.exit(unlink(tmp_parquet), add = TRUE)

      con <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
      on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

      DBI::dbExecute(con, paste0(
        "CREATE VIEW clinical AS SELECT * FROM read_parquet('",
        tmp_parquet, "')"
      ))

      # Example 1: simple SELECT
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
    packages = c("DBI", "duckdb", "arrow")
  ),

  # --- Cross-dataset integration summary ---
  tar_target(
    eda_integration_summary,
    {
      # Load both clinical and biospecimen from the clinical_data directory
      clin_path <- file.path(clinical_data, "clinical_data.rds")
      bio_path  <- file.path(clinical_data, "biospecimen_data.rds")
      if (!file.exists(clin_path) || !file.exists(bio_path)) return(NULL)

      clin <- readRDS(clin_path)
      bio  <- readRDS(bio_path)
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
