# R/01b_cytogenetic_data.R
# Cytogenetic data extraction and classification for CoMMpass
# Extracts translocation and CNA status from GDC clinical data

#' Extract cytogenetic markers from clinical data
#'
#' Parses clinical data from GDC to extract translocation and copy number
#' alteration status. GDC clinical data includes FISH results for standard
#' myeloma cytogenetic markers.
#'
#' @param clinical_dir Path to clinical data directory (from download_clinical_data)
#' @return Path to saved cytogenetic parquet file
#' @export
#' @examples
#' \dontrun{
#' cyto_file <- extract_cytogenetic_data("data/raw/clinical")
#' cyto <- arrow::read_parquet(cyto_file)
#' }
extract_cytogenetic_data <- function(clinical_dir) {
  clinical_file <- file.path(clinical_dir, "clinical_data.rds")
  if (!file.exists(clinical_file)) {
    cli::cli_abort(c(
      "x" = "Clinical data not found at {clinical_file}",
      "i" = "Run download_clinical_data() first"
    ))
  }

  clinical <- readRDS(clinical_file)
  logger::log_info("Extracting cytogenetic markers from {nrow(clinical)} patients")

  # Standardize column names for matching
  col_names <- tolower(names(clinical))
  names(clinical) <- col_names

  # Build cytogenetic data frame starting with patient ID
  id_col <- intersect(
    c("submitter_id", "bcr_patient_barcode", "patient_id"),
    col_names
  )
  if (length(id_col) == 0) {
    cli::cli_abort(c(
      "x" = "No patient ID column found in clinical data",
      "i" = "Expected one of: submitter_id, bcr_patient_barcode, patient_id"
    ))
  }

  cyto <- data.frame(
    patient_id = clinical[[id_col[1]]],
    stringsAsFactors = FALSE
  )

  # Extract ISS staging
  iss_col <- grep("^iss", col_names, value = TRUE)
  if (length(iss_col) > 0) {
    cyto$iss_stage <- clinical[[iss_col[1]]]
    logger::log_info("Found ISS staging in column: {iss_col[1]}")
  } else {
    cyto$iss_stage <- NA_character_
    logger::log_info("ISS staging not found in clinical data")
  }

  # Map of cytogenetic markers to possible column name patterns
  marker_patterns <- list(
    t_4_14  = "t\\(?4[;,]14\\)?|whsc1|nsd2|fgfr3",
    t_11_14 = "t\\(?11[;,]14\\)?|ccnd1",
    t_14_16 = "t\\(?14[;,]16\\)?|maf[^b]|c.maf",
    t_14_20 = "t\\(?14[;,]20\\)?|mafb",
    del_17p  = "del\\(?17p|tp53.*del|17p.*del",
    del_1p   = "del\\(?1p|1p.*del",
    gain_1q  = "gain\\(?1q|1q.*gain|amp\\(?1q"
  )

  for (marker_name in names(marker_patterns)) {
    pattern <- marker_patterns[[marker_name]]
    matched_cols <- grep(pattern, col_names, value = TRUE, ignore.case = TRUE)

    if (length(matched_cols) > 0) {
      raw_val <- clinical[[matched_cols[1]]]
      cyto[[marker_name]] <- parse_cytogenetic_status(raw_val)
      logger::log_info(
        "Marker {marker_name}: found in column '{matched_cols[1]}', ",
        "{sum(cyto[[marker_name]] == 'positive', na.rm = TRUE)} positive"
      )
    } else {
      cyto[[marker_name]] <- NA_character_
      logger::log_info("Marker {marker_name}: no matching column found")
    }
  }

  # Derive risk classification (IMWG 2014 criteria)
  cyto$risk_group <- classify_cytogenetic_risk(cyto)

  # Summary
  n_any_data <- sum(rowSums(!is.na(cyto[, names(marker_patterns)])) > 0)
  logger::log_info("Cytogenetic data available for {n_any_data}/{nrow(cyto)} patients")

  # Save
  output_file <- file.path(clinical_dir, "cytogenetic_data.parquet")
  arrow::write_parquet(cyto, output_file, compression = "zstd")
  logger::log_info("Saved cytogenetic data to {output_file}")

  saveRDS(cyto, file.path(clinical_dir, "cytogenetic_data.rds"))

  return(output_file)
}

#' Parse cytogenetic status values to standardized categories
#'
#' Converts various representations of cytogenetic results (Yes/No, 1/0,
#' Positive/Negative, TRUE/FALSE) to a consistent factor.
#'
#' @param x Character or numeric vector of cytogenetic status values
#' @return Character vector with values "positive", "negative", or NA
#' @keywords internal
parse_cytogenetic_status <- function(x) {
  if (is.null(x)) return(NA_character_)

  x_lower <- tolower(as.character(x))

  result <- rep(NA_character_, length(x_lower))
  result[x_lower %in% c("yes", "1", "true", "positive", "present", "y")] <- "positive"
  result[x_lower %in% c("no", "0", "false", "negative", "absent", "n")] <- "negative"

  result
}

#' Classify cytogenetic risk group
#'
#' Assigns risk group based on IMWG 2014 revised criteria:
#' - High risk: t(4;14), t(14;16), t(14;20), del(17p), gain(1q21)
#' - Standard risk: t(11;14), or none of the above
#'
#' @param cyto Data frame with cytogenetic marker columns
#' @return Character vector of risk classifications
#' @keywords internal
classify_cytogenetic_risk <- function(cyto) {
  high_risk_markers <- c("t_4_14", "t_14_16", "t_14_20", "del_17p", "gain_1q")
  available_markers <- intersect(high_risk_markers, names(cyto))

  if (length(available_markers) == 0) {
    return(rep(NA_character_, nrow(cyto)))
  }

  is_high_risk <- apply(
    cyto[, available_markers, drop = FALSE],
    1,
    function(row) any(row == "positive", na.rm = TRUE)
  )

  has_any_data <- apply(
    cyto[, available_markers, drop = FALSE],
    1,
    function(row) any(!is.na(row))
  )

  result <- rep(NA_character_, nrow(cyto))
  result[has_any_data & is_high_risk] <- "high"
  result[has_any_data & !is_high_risk] <- "standard"

  result
}
