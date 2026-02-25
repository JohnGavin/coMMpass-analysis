# R/tar_plans/plan_api.R
# Targets to generate static JSON files for Phase 1 API.
# Writes to docs/api/v1/ for GitHub Pages hosting.

plan_api <- list(

  # --- Index endpoint ---
  tar_target(
    api_index,
    generate_api_index()
  ),

  # --- Clinical data ---
  tar_target(
    api_clinical,
    {
      clin <- api_get_clinical()
      generate_api_endpoint(clin, "clinical",
                            "Clinical data for CoMMpass patients")
    }
  ),

  # --- DE results ---
  tar_target(
    api_de_results,
    {
      de <- api_get_de_results()
      generate_api_endpoint(de, "de-results",
                            "Differential expression results (DESeq2)")
    }
  ),

  # --- Survival data ---
  tar_target(
    api_survival,
    {
      surv <- api_get_survival()
      generate_api_endpoint(surv, "survival",
                            "Prepared survival data with covariates")
    }
  ),

  # --- Pathway results ---
  tar_target(
    api_pathways,
    {
      pw <- api_get_pathways()
      generate_api_endpoint(pw, "pathways",
                            "GSEA pathway analysis results")
    }
  ),

  # --- Cytogenetics ---
  tar_target(
    api_cytogenetics,
    {
      cyto <- tryCatch(
        targets::tar_read("cyto_viz_data"),
        error = function(e) NULL
      )
      generate_api_endpoint(cyto, "cytogenetics",
                            "Cytogenetic marker status and risk classification")
    }
  ),

  # --- Data dictionary ---
  tar_target(
    api_data_dict,
    {
      dd <- tryCatch(get_commpass_data_dictionary(), error = function(e) NULL)
      generate_api_endpoint(dd, "data-dictionary",
                            "Variable metadata and data dictionary")
    }
  ),

  # --- Write all JSON files to docs/api/v1/ ---
  tar_target(
    save_api_files,
    {
      out_dir <- "docs/api/v1"
      dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

      files <- list(
        "index.json"           = api_index,
        "clinical.json"        = api_clinical,
        "de-results.json"      = api_de_results,
        "survival.json"        = api_survival,
        "pathways.json"        = api_pathways,
        "cytogenetics.json"    = api_cytogenetics,
        "data-dictionary.json" = api_data_dict
      )

      paths <- character(length(files))
      for (i in seq_along(files)) {
        fp <- file.path(out_dir, names(files)[i])
        content <- files[[i]]

        # api_index is a list, others are already JSON strings
        if (is.list(content) && !is.character(content)) {
          content <- jsonlite::toJSON(
            content,
            pretty = TRUE,
            auto_unbox = TRUE,
            POSIXt = "ISO8601",
            Date = "ISO8601",
            na = "null"
          )
        }

        writeLines(content, fp)
        paths[i] <- fp
      }

      cli::cli_alert_success(
        "Wrote {length(paths)} API files to {.path {out_dir}}"
      )
      paths
    },
    packages = c("jsonlite", "cli")
  )
)
