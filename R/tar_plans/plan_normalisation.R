# R/tar_plans/plan_normalisation.R
# Clinical-informed biomarker normalisation targets

plan_normalisation <- list(
  tar_target(
    biomarker_normalised,
    {
      clin_file <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(clin_file)) return(NULL)
      clin <- arrow::read_parquet(clin_file)
      normalize_biomarkers(clin, method = "clinical")
    },
    packages = c("arrow")
  ),

  # Comparison: clinical vs z-score normalisation
  tar_target(
    vig_normalisation_comparison,
    {
      clin_file <- file.path(clinical_data, "clinical_data.parquet")
      if (!file.exists(clin_file)) return(NULL)
      clin <- arrow::read_parquet(clin_file)
      refs <- clinical_reference_ranges()

      # Find biomarkers present in data
      col_map <- list(
        creatinine = "creatinine", albumin = "albumin",
        hemoglobin = "hemoglobin", calcium = "calcium",
        ldh = "ldh", b2m = "b2m"
      )

      rows <- list()
      for (bm in names(col_map)) {
        col <- intersect(tolower(names(clin)), col_map[[bm]])
        if (length(col) == 0) next
        col_name <- names(clin)[tolower(names(clin)) == col[1]]
        vals <- as.numeric(clin[[col_name]])
        if (all(is.na(vals))) next

        ref <- refs[refs$biomarker == bm, ]
        clin_norm <- normalize_clinical(vals, ref$low, ref$high, "clinical")
        z_norm <- normalize_clinical(vals, ref$low, ref$high, "zscore")

        rows[[length(rows) + 1]] <- data.frame(
          Biomarker = bm,
          Unit = ref$unit,
          N = sum(!is.na(vals)),
          Raw_Mean = round(mean(vals, na.rm = TRUE), 2),
          Raw_SD = round(stats::sd(vals, na.rm = TRUE), 2),
          Ref_Range = paste0("[", ref$low, "-", ref$high, "]"),
          Clinical_Mean = round(mean(clin_norm, na.rm = TRUE), 3),
          Clinical_SD = round(stats::sd(clin_norm, na.rm = TRUE), 3),
          Zscore_Mean = round(mean(z_norm, na.rm = TRUE), 3),
          Zscore_SD = round(stats::sd(z_norm, na.rm = TRUE), 3),
          stringsAsFactors = FALSE
        )
      }
      if (length(rows) == 0) return(NULL)
      df <- do.call(rbind, rows)
      DT::datatable(df, rownames = FALSE,
        options = list(dom = "t", paging = FALSE, scrollX = TRUE),
        caption = htmltools::tags$caption(
          style = "caption-side: bottom; text-align: left;",
          "Comparison of clinical-informed (SCOPE) vs z-score normalisation. ",
          "Clinical method maps reference range to [0, 7] with sigmoid compression of extremes. ",
          "Z-score centers at mean with unit variance. ",
          "Ref_Range = clinical reference range for each biomarker. ",
          "Source: Hussain et al. (2024) npj Digital Medicine."
        ))
    },
    packages = c("arrow", "DT", "htmltools")
  ),

  # Reference ranges table for vignette
  tar_target(
    vig_reference_ranges,
    {
      refs <- clinical_reference_ranges()
      DT::datatable(refs, rownames = FALSE,
        options = list(dom = "t", paging = FALSE),
        caption = htmltools::tags$caption(
          style = "caption-side: bottom; text-align: left;",
          "Clinical reference ranges for myeloma-relevant biomarkers. ",
          "Used by normalize_clinical() for clinical-informed normalisation. ",
          "Values within [low, high] are in the normal range; values outside are compressed by sigmoid. ",
          "Source: standard laboratory ranges."
        ))
    },
    packages = c("DT", "htmltools")
  )
)
