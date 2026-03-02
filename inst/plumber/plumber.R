# inst/plumber/plumber.R
# Plumber API endpoint definitions for CoMMpass data access.
# Launch with: coMMpass::api_serve()

# Store path (set by api_serve or default)
STORE <- Sys.getenv("TARGETS_STORE", unset = "_targets")

#* @apiTitle CoMMpass Analysis API
#* @apiDescription Programmatic access to MMRF CoMMpass analysis results.
#*   Data is pre-computed via a targets pipeline.
#* @apiVersion 0.1.0

#* List available datasets
#* @get /datasets
#* @serializer json
function() {
  coMMpass::api_list_datasets()
}

#* Get clinical data
#* @param patient_ids Comma-separated patient IDs (optional)
#* @param variables Comma-separated column names (optional)
#* @get /data/clinical
#* @serializer json
function(patient_ids = NULL, variables = NULL) {
  ids <- if (!is.null(patient_ids)) {
    strsplit(patient_ids, ",")[[1]]
  } else {
    NULL
  }
  vars <- if (!is.null(variables)) {
    strsplit(variables, ",")[[1]]
  } else {
    NULL
  }
  result <- coMMpass::api_get_clinical(
    patient_ids = ids, variables = vars, store = STORE
  )
  if (is.null(result)) {
    list(error = "Clinical data not available. Run tar_make() first.")
  } else {
    result
  }
}

#* Get differential expression results
#* @param padj_threshold Maximum adjusted p-value (default: 1)
#* @param lfc_threshold Minimum absolute log2 fold change (default: 0)
#* @get /data/de_results
#* @serializer json
function(padj_threshold = 1, lfc_threshold = 0) {
  result <- coMMpass::api_get_de_results(
    padj_threshold = as.numeric(padj_threshold),
    lfc_threshold = as.numeric(lfc_threshold),
    store = STORE
  )
  if (is.null(result)) {
    list(error = "DE results not available. Run tar_make() first.")
  } else {
    result
  }
}

#* Get survival data
#* @get /data/survival
#* @serializer json
function() {
  result <- coMMpass::api_get_survival(store = STORE)
  if (is.null(result)) {
    list(error = "Survival data not available. Run tar_make() first.")
  } else {
    result
  }
}

#* Get pathway analysis results
#* @param significant_only Return only significant pathways (padj < 0.05)
#* @get /data/pathways
#* @serializer json
function(significant_only = FALSE) {
  sig <- isTRUE(as.logical(significant_only))
  result <- coMMpass::api_get_pathways(
    significant_only = sig, store = STORE
  )
  if (is.null(result)) {
    list(error = "Pathway results not available. Run tar_make() first.")
  } else {
    result
  }
}

#* Get cytogenetic data
#* @get /data/cytogenetics
#* @serializer json
function() {
  result <- tryCatch(
    targets::tar_read("cyto_viz_data", store = STORE),
    error = function(e) NULL
  )
  if (is.null(result)) {
    list(error = "Cytogenetic data not available. Run tar_make() first.")
  } else {
    result
  }
}

#* Health check
#* @get /health
#* @serializer json
function() {
  list(
    status = "ok",
    package_version = as.character(utils::packageVersion("coMMpass")),
    targets_store = STORE,
    timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z")
  )
}

#* Download dataset as CSV
#* @param dataset One of: clinical, de_results, survival, pathways, cytogenetics
#* @get /download/<dataset>
#* @serializer csv
function(dataset) {
  result <- switch(dataset,
    clinical = coMMpass::api_get_clinical(store = STORE),
    de_results = coMMpass::api_get_de_results(store = STORE),
    survival = coMMpass::api_get_survival(store = STORE),
    pathways = coMMpass::api_get_pathways(store = STORE),
    cytogenetics = tryCatch(
      targets::tar_read("cyto_viz_data", store = STORE),
      error = function(e) NULL
    ),
    NULL
  )
  if (is.null(result)) {
    data.frame(error = paste("Dataset", dataset, "not available"))
  } else {
    result
  }
}
