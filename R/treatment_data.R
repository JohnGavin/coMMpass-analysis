# R/treatment_data.R
# Treatment/regimen data extraction and cleaning

# Suppress R CMD check NOTEs
utils::globalVariables(c("regimen_name", "best_response"))

#' Clean and standardize treatment data
#'
#' Standardizes regimen names, derives regimen class, and creates an ordered
#' response factor from raw CoMMpass treatment response data.
#'
#' @param trtresp_raw Data frame of raw treatment response data with columns
#'   including patient/submitter ID, treatment line, regimen description,
#'   best response, and transplant status
#' @return Cleaned data frame with standardized columns: `patient_id`,
#'   `treatment_line`, `regimen_name`, `regimen_class`, `best_response`
#'   (ordered factor), `stem_cell_transplant` (logical),
#'   `treatment_start_days` (integer)
#' @family data-cleaning
#' @export
clean_treatment_data <- function(trtresp_raw) {
  if (is.null(trtresp_raw) || nrow(trtresp_raw) == 0) {
    return(data.frame(
      patient_id = character(), treatment_line = integer(),
      regimen_name = character(), regimen_class = character(),
      best_response = character(), stem_cell_transplant = logical(),
      treatment_start_days = integer(), stringsAsFactors = FALSE
    ))
  }

  trt <- trtresp_raw
  names(trt) <- tolower(names(trt))

  # Find patient ID column
  id_col <- intersect(
    c("public_id", "submitter_id", "patient_id", "mmrf_id"),
    names(trt)
  )
  if (length(id_col) == 0) {
    cli::cli_abort("No patient ID column found in treatment data")
  }

  result <- data.frame(
    patient_id = trt[[id_col[1]]],
    stringsAsFactors = FALSE
  )

  # Treatment line — extract from text if needed (GDC: "First line of therapy")
  line_col <- intersect(c("line", "treatment_line", "theression",
                          "regimen_or_line_of_therapy"), names(trt))
  if (length(line_col) > 0) {
    raw_line <- trt[[line_col[1]]]
    # Try numeric first
    num_line <- suppressWarnings(as.integer(raw_line))
    if (all(is.na(num_line)) && is.character(raw_line)) {
      # Parse "First line of therapy" → 1, "Second line" → 2, etc.
      line_map <- c(first = 1L, second = 2L, third = 3L, fourth = 4L,
                    fifth = 5L, sixth = 6L, seventh = 7L, eighth = 8L)
      first_word <- tolower(sub("\\s.*", "", raw_line))
      num_line <- line_map[first_word]
    }
    result$treatment_line <- num_line
  } else {
    result$treatment_line <- NA_integer_
  }

  # Regimen name — standardize common abbreviations
  reg_col <- intersect(
    c("trtshnm", "regimen", "regimen_name", "treatment_name",
      "therapeutic_agents"),
    names(trt)
  )
  raw_regimen <- if (length(reg_col) > 0) trt[[reg_col[1]]] else NA_character_
  result$regimen_name <- standardize_regimen(raw_regimen)

  # Derive regimen class
  result$regimen_class <- classify_regimen(result$regimen_name)

  # Best response — ordered factor
  resp_col <- intersect(c("bestrespassess", "best_response", "response"), names(trt))
  raw_resp <- if (length(resp_col) > 0) trt[[resp_col[1]]] else NA_character_
  result$best_response <- standardize_response(raw_resp)

  # Stem cell transplant
  sct_col <- intersect(c("sct_flag", "stem_cell_transplant", "transplant"), names(trt))
  if (length(sct_col) > 0) {
    sct_val <- tolower(trt[[sct_col[1]]])
    result$stem_cell_transplant <- sct_val %in% c("yes", "y", "1", "true")
  } else {
    result$stem_cell_transplant <- NA
  }

  # Treatment start (days from diagnosis)
  start_col <- intersect(c("trtstdy", "treatment_start_days", "start_days",
                           "days_to_treatment_start"), names(trt))
  result$treatment_start_days <- if (length(start_col) > 0) {
    suppressWarnings(as.integer(trt[[start_col[1]]]))
  } else {
    NA_integer_
  }

  result
}


#' Standardize regimen names
#'
#' Maps verbose CoMMpass regimen descriptions to standard abbreviations.
#'
#' @param regimen Character vector of raw regimen names
#' @return Character vector of standardized regimen abbreviations
#' @keywords internal
standardize_regimen <- function(regimen) {
  if (is.null(regimen)) return(NA_character_)
  reg <- toupper(regimen)

  # Common CoMMpass regimen patterns
  reg <- gsub(".*BORTEZOMIB.*LENALIDOMIDE.*DEXAMETHASONE.*", "VRd", reg)
  reg <- gsub(".*LENALIDOMIDE.*DEXAMETHASONE.*", "Rd", reg)
  reg <- gsub(".*BORTEZOMIB.*DEXAMETHASONE.*", "Vd", reg)
  reg <- gsub(".*CARFILZOMIB.*LENALIDOMIDE.*DEXAMETHASONE.*", "KRd", reg)
  reg <- gsub(".*CARFILZOMIB.*DEXAMETHASONE.*", "Kd", reg)
  reg <- gsub(".*DARATUMUMAB.*BORTEZOMIB.*", "DaraVd", reg)
  reg <- gsub(".*DARATUMUMAB.*LENALIDOMIDE.*", "DaraRd", reg)
  reg <- gsub(".*POMALIDOMIDE.*DEXAMETHASONE.*", "Pd", reg)
  reg <- gsub(".*MELPHALAN.*", "Mel", reg)

  # Already-abbreviated regimens
  reg[toupper(reg) == "VRD"] <- "VRd"
  reg[toupper(reg) == "RD"] <- "Rd"
  reg[toupper(reg) == "KRD"] <- "KRd"
  reg[toupper(reg) == "VD"] <- "Vd"

  reg
}


#' Classify regimen by drug class
#'
#' @param regimen_std Character vector of standardized regimen names
#' @return Character vector of regimen classes
#' @keywords internal
classify_regimen <- function(regimen_std) {
  cls <- rep("Other", length(regimen_std))
  cls[grepl("V|Borte", regimen_std, ignore.case = TRUE)] <- "PI-based"
  cls[grepl("R|Len|Pom|Thal", regimen_std, ignore.case = TRUE)] <- "IMiD-based"
  cls[grepl("K|Carfil", regimen_std, ignore.case = TRUE)] <- "PI-based"
  cls[grepl("Dara|Isa|Elo", regimen_std, ignore.case = TRUE)] <- "mAb-based"
  # Combinations get the most targeted class

  cls[grepl("Dara", regimen_std, ignore.case = TRUE)] <- "mAb-based"
  cls[grepl("Mel", regimen_std, ignore.case = TRUE)] <- "Alkylator-based"
  cls
}


#' Standardize best response values
#'
#' Maps raw response strings to an ordered factor: sCR > CR > VGPR > PR >
#' MR > SD > PD.
#'
#' @param response Character vector of raw response values
#' @return Ordered factor of standardized responses
#' @keywords internal
standardize_response <- function(response) {
  if (is.null(response)) return(factor(NA, levels = response_levels(), ordered = TRUE))

  resp <- toupper(response)
  resp[resp %in% c("STRINGENT COMPLETE RESPONSE", "SCR")] <- "sCR"
  resp[resp %in% c("COMPLETE RESPONSE", "CR", "COMPLETE REMISSION")] <- "CR"
  resp[resp %in% c("VERY GOOD PARTIAL RESPONSE", "VGPR")] <- "VGPR"
  resp[resp %in% c("PARTIAL RESPONSE", "PR")] <- "PR"
  resp[resp %in% c("MINIMAL RESPONSE", "MR", "MINOR RESPONSE")] <- "MR"
  resp[resp %in% c("STABLE DISEASE", "SD")] <- "SD"
  resp[resp %in% c("PROGRESSIVE DISEASE", "PD", "DISEASE PROGRESSION")] <- "PD"

  factor(resp, levels = response_levels(), ordered = TRUE)
}


#' Response level ordering
#' @keywords internal
response_levels <- function() {
  c("sCR", "CR", "VGPR", "PR", "MR", "SD", "PD")
}


#' Summarize treatment lines per patient
#'
#' Creates a one-row-per-patient summary of treatment history.
#'
#' @param treatment_clean Cleaned treatment data from [clean_treatment_data()]
#' @return Data frame with columns: patient_id, n_lines, first_regimen,
#'   first_regimen_class, had_transplant, best_overall_response
#' @family data-cleaning
#' @export
summarize_treatment <- function(treatment_clean) {
  if (is.null(treatment_clean) || nrow(treatment_clean) == 0) {
    return(data.frame(
      patient_id = character(), n_lines = integer(),
      first_regimen = character(), first_regimen_class = character(),
      had_transplant = logical(), best_overall_response = character(),
      stringsAsFactors = FALSE
    ))
  }

  patients <- unique(treatment_clean$patient_id)
  result <- lapply(patients, function(pid) {
    pt <- treatment_clean[treatment_clean$patient_id == pid, ]
    pt <- pt[order(pt$treatment_line), ]

    first_line <- pt[1, ]
    best_resp <- if (any(!is.na(pt$best_response))) {
      as.character(min(pt$best_response, na.rm = TRUE))
    } else {
      NA_character_
    }

    data.frame(
      patient_id = pid,
      n_lines = max(pt$treatment_line, na.rm = TRUE),
      first_regimen = first_line$regimen_name,
      first_regimen_class = first_line$regimen_class,
      had_transplant = any(pt$stem_cell_transplant, na.rm = TRUE),
      best_overall_response = best_resp,
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, result)
}
