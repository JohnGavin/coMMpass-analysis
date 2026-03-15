# R/01_data_acquisition.R
# Data acquisition functions for CoMMpass analysis
# Downloads RNA-seq and clinical data from GDC
# Saves in parquet format (primary) + RDS (secondary)

#' Download RNA-seq data from GDC
#'
#' Downloads RNA-seq gene expression data from the Genomic Data Commons (GDC)
#' for the specified project. Data is saved as a SummarizedExperiment RDS and
#' as parquet files (counts, sample metadata, gene metadata).
#'
#' @param project_id Project identifier (default: "MMRF-COMMPASS")
#' @param data_dir Directory to save data
#' @param sample_limit Maximum number of samples (NULL for all, default 200)
#' @param random_sample If TRUE and sample_limit is set, randomly sample
#'   patients using seed for reproducibility (default TRUE)
#' @param seed Random seed for reproducible sampling (default 42)
#' @param use_parquet If TRUE, also save parquet files alongside RDS (default TRUE)
#' @return Path to the saved RDS file containing the SummarizedExperiment
#' @family data-acquisition
#' @export
#' @examples
#' \dontrun{
#' # Download 200 random samples with parquet output
#' rnaseq_file <- download_gdc_rnaseq(sample_limit = 200)
#'
#' # Load the SummarizedExperiment
#' se_data <- readRDS(rnaseq_file)
#'
#' # Or load parquet directly
#' counts <- arrow::read_parquet("data/raw/gdc/rnaseq_counts.parquet")
#' }
download_gdc_rnaseq <- function(
  project_id = "MMRF-COMMPASS",
  data_dir = "data/raw/gdc",
  sample_limit = 200,
  random_sample = TRUE,
  seed = 42,
  use_parquet = TRUE
) {
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)
  output_file <- file.path(data_dir, "rnaseq_se.rds")

  # In CI, use fewer samples but still real data
  if (Sys.getenv("CI") == "true" || Sys.getenv("GITHUB_ACTIONS") == "true") {
    sample_limit <- min(sample_limit, 20)
    logger::log_info("CI environment: limiting to {sample_limit} samples")
  }

  logger::log_info("Querying GDC for {project_id} RNA-seq data...")

  # Query GDC
  query <- TCGAbiolinks::GDCquery(
    project = project_id,
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    workflow.type = "STAR - Counts"
  )

  # Subset samples if requested
  if (!is.null(sample_limit)) {
    query_results <- TCGAbiolinks::getResults(query)
    n_available <- nrow(query_results)

    if (n_available > sample_limit) {
      if (random_sample) {
        set.seed(seed)
        selected_idx <- sort(sample.int(n_available, sample_limit))
        logger::log_info(
          "Randomly sampling {sample_limit} of {n_available} samples (seed={seed})"
        )
      } else {
        selected_idx <- seq_len(sample_limit)
        logger::log_info("Taking first {sample_limit} of {n_available} samples")
      }
      selected_barcodes <- query_results$cases[selected_idx]
      query <- TCGAbiolinks::GDCquery(
        project = project_id,
        data.category = "Transcriptome Profiling",
        data.type = "Gene Expression Quantification",
        workflow.type = "STAR - Counts",
        barcode = selected_barcodes
      )
    }
  }

  # Download and prepare
  logger::log_info("Downloading data to {data_dir}...")
  TCGAbiolinks::GDCdownload(query, directory = data_dir)

  logger::log_info("Preparing SummarizedExperiment object...")
  se_data <- TCGAbiolinks::GDCprepare(query, directory = data_dir)

  # Save as RDS (Bioconductor compatibility)
  saveRDS(se_data, output_file)
  logger::log_info("Saved SummarizedExperiment to {output_file}")

  # Save parquet files for DuckDB querying
  if (use_parquet) {
    save_rnaseq_parquet(se_data, data_dir)
  }

  # Save download metadata
  metadata <- list(
    download_time = Sys.time(),
    project_id = project_id,
    n_samples = ncol(se_data),
    n_genes = nrow(se_data),
    sample_limit = sample_limit,
    random_sample = random_sample,
    seed = seed,
    assay_names = SummarizedExperiment::assayNames(se_data),
    coldata_names = names(SummarizedExperiment::colData(se_data)),
    rowdata_names = names(SummarizedExperiment::rowData(se_data))
  )
  saveRDS(metadata, file.path(data_dir, "rnaseq_metadata.rds"))

  return(as.character(output_file))
}

#' Save SummarizedExperiment as parquet files
#'
#' Extracts counts matrix, sample metadata, and gene metadata from a
#' SummarizedExperiment and saves each as a parquet file.
#'
#' @param se SummarizedExperiment object
#' @param data_dir Directory to save parquet files
#' @return Invisible list of output file paths
#' @keywords internal
save_rnaseq_parquet <- function(se, data_dir) {
  # Counts: wide format with gene_id column for DuckDB queries
  # Try "unstranded" first (standard GDC STAR-Counts assay name),

  # fall back to "counts" then first assay
  assay_names <- SummarizedExperiment::assayNames(se)
  if ("unstranded" %in% assay_names) {
    counts_mat <- SummarizedExperiment::assay(se, "unstranded")
  } else if ("counts" %in% assay_names) {
    counts_mat <- get_counts_assay(se)
  } else {
    counts_mat <- SummarizedExperiment::assay(se, 1)
    logger::log_warn(
      "Using first assay ({assay_names[1]}) - 'unstranded' not found"
    )
  }

  counts_df <- as.data.frame(counts_mat)
  counts_df$gene_id <- rownames(counts_mat)
  # Move gene_id to first column
  counts_df <- counts_df[, c("gene_id", setdiff(names(counts_df), "gene_id"))]

  counts_file <- file.path(data_dir, "rnaseq_counts.parquet")
  arrow::write_parquet(counts_df, counts_file, compression = "zstd")
  logger::log_info("Saved counts to {counts_file}")

  # Sample metadata
  sample_meta <- as.data.frame(SummarizedExperiment::colData(se))
  
  # Flatten list columns (arrow cannot write list columns to parquet)
  list_cols <- sapply(sample_meta, function(x) is.list(x) && !is.data.frame(x))
  if (any(list_cols)) {
    for (col_name in names(sample_meta)[list_cols]) {
      sample_meta[[col_name]] <- sapply(
        sample_meta[[col_name]],
        function(x) if (length(x) == 0) NA_character_ else paste(x, collapse = "; ")
      )
    }
  }
  sample_file <- file.path(data_dir, "rnaseq_sample_metadata.parquet")
  arrow::write_parquet(sample_meta, sample_file, compression = "zstd")
  logger::log_info("Saved sample metadata to {sample_file}")

  # Gene metadata
  gene_meta <- as.data.frame(SummarizedExperiment::rowData(se))
  gene_file <- file.path(data_dir, "rnaseq_gene_metadata.parquet")
  arrow::write_parquet(gene_meta, gene_file, compression = "zstd")
  logger::log_info("Saved gene metadata to {gene_file}")

  invisible(list(
    counts = counts_file,
    sample_metadata = sample_file,
    gene_metadata = gene_file
  ))
}

#' Download data from AWS S3 open access bucket
#' @param bucket_name S3 bucket name
#' @param prefix File prefix to filter
#' @param data_dir Local directory for downloads
#' @param region AWS region
#' @return Directory path as character string
download_aws_data <- function(
  bucket_name = "gdc-mmrf-commpass-phs000748-2-open",
  prefix = NULL,
  data_dir = "data/raw/aws",
  region = "us-east-1"
) {
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

  logger::log_info("Listing S3 bucket contents...")

  bucket_contents <- aws.s3::get_bucket_df(
    bucket = bucket_name,
    region = region,
    use_https = TRUE,
    prefix = prefix
  )

  logger::log_info("Found {nrow(bucket_contents)} files in bucket")

  downloaded_files <- list()
  for (i in seq_len(min(10, nrow(bucket_contents)))) {
    file_key <- bucket_contents$Key[i]
    local_file <- file.path(data_dir, basename(file_key))

    logger::log_info("Downloading {file_key}...")

    aws.s3::save_object(
      object = file_key,
      bucket = bucket_name,
      file = local_file,
      region = region
    )

    downloaded_files[[i]] <- local_file
  }

  logger::log_info("Downloaded {length(downloaded_files)} files to {data_dir}")
  return(as.character(data_dir))
}

#' Download clinical data from GDC
#'
#' Downloads clinical and biospecimen data from the Genomic Data Commons (GDC)
#' for the specified project. Data is saved in parquet and RDS formats.
#'
#' @param project_id Project identifier (default: "MMRF-COMMPASS")
#' @param data_dir Directory to save data
#' @param use_parquet If TRUE, also save parquet files (default TRUE)
#' @return Path to the directory containing the saved data files
#' @family data-acquisition
#' @export
#' @examples
#' \dontrun{
#' # Download clinical data
#' clinical_dir <- download_clinical_data()
#'
#' # Load from parquet
#' clinical <- arrow::read_parquet(file.path(clinical_dir, "clinical_data.parquet"))
#' }
download_clinical_data <- function(
  project_id = "MMRF-COMMPASS",
  data_dir = "data/raw/clinical",
  use_parquet = TRUE
) {
  dir.create(data_dir, recursive = TRUE, showWarnings = FALSE)

  logger::log_info("Downloading clinical data for {project_id}...")

  # Download clinical data from GDC
  clinical <- TCGAbiolinks::GDCquery_clinic(
    project = project_id, type = "clinical"
  )
  if (is.null(clinical) || nrow(clinical) == 0) {
    cli::cli_abort(c(
      "x" = "GDC returned no clinical data for {project_id}.",
      "i" = "Check your internet connection and GDC API status.",
      "i" = "GDC status: https://portal.gdc.cancer.gov/"
    ))
  }
  logger::log_info("Retrieved {nrow(clinical)} clinical records")

  # Download biospecimen data
  biospecimen <- TCGAbiolinks::GDCquery_clinic(
    project = project_id, type = "biospecimen"
  )
  if (is.null(biospecimen) || nrow(biospecimen) == 0) {
    cli::cli_abort(c(
      "x" = "GDC returned no biospecimen data for {project_id}.",
      "i" = "Check your internet connection and GDC API status."
    ))
  }
  logger::log_info("Retrieved {nrow(biospecimen)} biospecimen records")

  # Save as RDS (fast R loading)
  saveRDS(clinical, file.path(data_dir, "clinical_data.rds"))
  saveRDS(biospecimen, file.path(data_dir, "biospecimen_data.rds"))

  # Remove list columns (nested data frames) - parquet doesn't support them
  if (use_parquet) {
    clinical <- as.data.frame(clinical)
    biospecimen <- as.data.frame(biospecimen)
    
    for (col in names(clinical)) {
      if (is.list(clinical[[col]]) && !is.data.frame(clinical[[col]])) {
        clinical[[col]] <- NULL
      }
    }
    for (col in names(biospecimen)) {
      if (is.list(biospecimen[[col]]) && !is.data.frame(biospecimen[[col]])) {
        biospecimen[[col]] <- NULL
      }
    }
  }

  # Save as parquet (queryable via DuckDB)
  if (use_parquet) {
    arrow::write_parquet(
      clinical,
      file.path(data_dir, "clinical_data.parquet"),
      compression = "zstd"
    )
    arrow::write_parquet(
      biospecimen,
      file.path(data_dir, "biospecimen_data.parquet"),
      compression = "zstd"
    )
    logger::log_info("Saved parquet files to {data_dir}")
  }

  # Save download metadata
  metadata <- list(
    download_time = Sys.time(),
    project_id = project_id,
    n_clinical = nrow(clinical),
    n_biospecimen = nrow(biospecimen),
    clinical_columns = names(clinical),
    biospecimen_columns = names(biospecimen)
  )
  saveRDS(metadata, file.path(data_dir, "clinical_metadata.rds"))

  # Download treatment data via GDC API (nested in diagnoses)
  logger::log_info("Extracting treatment data from GDC API...")
  tryCatch({
    all_trts <- list()
    offset <- 0L
    page_size <- 100L
    total <- nrow(clinical)

    while (offset < total) {
      url <- paste0(
        "https://api.gdc.cancer.gov/cases?",
        "filters=%7B%22op%22%3A%22%3D%22%2C%22content%22%3A%7B%22field%22%3A",
        "%22project.project_id%22%2C%22value%22%3A%22", project_id, "%22%7D%7D",
        "&expand=diagnoses.treatments",
        "&fields=submitter_id,diagnoses.treatments.therapeutic_agents,",
        "diagnoses.treatments.regimen_or_line_of_therapy,",
        "diagnoses.treatments.days_to_treatment_start,",
        "diagnoses.treatments.days_to_treatment_end",
        "&size=", page_size, "&from=", offset
      )
      res <- jsonlite::fromJSON(url)
      hits <- res$data$hits
      for (i in seq_len(nrow(hits))) {
        pid <- hits$submitter_id[i]
        diags <- hits$diagnoses[[i]]
        if (is.null(diags) || !is.data.frame(diags)) next
        trts <- diags$treatments[[1]]
        if (is.null(trts) || !is.data.frame(trts)) next
        trts$public_id <- pid
        all_trts <- c(all_trts, list(trts))
      }
      offset <- offset + page_size
    }

    if (length(all_trts) > 0) {
      trt_df <- do.call(rbind, all_trts)
      # Keep only useful columns
      keep_cols <- intersect(
        c("public_id", "therapeutic_agents", "regimen_or_line_of_therapy",
          "days_to_treatment_start", "days_to_treatment_end"),
        names(trt_df)
      )
      trt_df <- trt_df[, keep_cols, drop = FALSE]
      if (use_parquet) {
        arrow::write_parquet(
          trt_df,
          file.path(data_dir, "treatment_data.parquet"),
          compression = "zstd"
        )
      }
      saveRDS(trt_df, file.path(data_dir, "treatment_data.rds"))
      logger::log_info("Saved {nrow(trt_df)} treatment records for {length(unique(trt_df$public_id))} patients")
    }
  }, error = function(e) {
    logger::log_warn("Failed to extract treatment data: {conditionMessage(e)}")
  })

  logger::log_info("Clinical data saved to {data_dir}")

  return(as.character(data_dir))
}

#' Main data acquisition function
#'
#' Orchestrates the download of CoMMpass data from various sources including
#' RNA-seq data from GDC, clinical data, and optionally AWS data.
#'
#' @param download_rnaseq Whether to download RNA-seq data
#' @param download_clinical Whether to download clinical data
#' @param download_aws Whether to download from AWS
#' @param sample_limit Limit number of samples (NULL for all)
#' @param random_sample If TRUE, randomly sample patients
#' @param seed Random seed for sampling
#' @param use_parquet If TRUE, save parquet files
#' @return List of file paths to the downloaded data
#' @family data-acquisition
#' @export
#' @examples
#' \dontrun{
#' # Download only clinical data
#' results <- acquire_commpass_data(
#'   download_rnaseq = FALSE,
#'   download_clinical = TRUE,
#'   download_aws = FALSE
#' )
#' }
acquire_commpass_data <- function(
  download_rnaseq = TRUE,
  download_clinical = TRUE,
  download_aws = FALSE,
  sample_limit = 200,
  random_sample = TRUE,
  seed = 42,
  use_parquet = TRUE
) {
  logger::log_info("Starting CoMMpass data acquisition...")

  results <- list()

  if (download_clinical) {
    results$clinical <- download_clinical_data(use_parquet = use_parquet)
  }

  if (download_rnaseq) {
    results$rnaseq <- download_gdc_rnaseq(
      sample_limit = sample_limit,
      random_sample = random_sample,
      seed = seed,
      use_parquet = use_parquet
    )
  }

  if (download_aws) {
    results$aws_files <- download_aws_data()
  }

  logger::log_info("Data acquisition complete")
  return(results)
}
