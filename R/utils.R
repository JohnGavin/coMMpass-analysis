# R/utils.R
# Utility functions for CoMMpass analysis

#' Get counts assay from SummarizedExperiment
#' 
#' GDC STAR-Counts uses 'unstranded', but fallback to 'counts' if present
#' @param se SummarizedExperiment object
#' @return Counts matrix
#' @export
get_counts_assay <- function(se) {
  assay_names <- SummarizedExperiment::assayNames(se)
  if ('unstranded' %in% assay_names) {
    return(SummarizedExperiment::assay(se, 'unstranded'))
  } else if ('counts' %in% assay_names) {
    return(SummarizedExperiment::assay(se, 'counts'))
  } else if (length(assay_names) > 0) {
    logger::log_warn('Using first assay: {assay_names[1]}')
    return(SummarizedExperiment::assay(se, 1))
  } else {
    cli::cli_abort('No assays found in SummarizedExperiment')
  }
}

#' Setup logging
#'
#' @param log_file Optional path to a log file. If NULL, logs to console.
setup_logging <- function(log_file = NULL) {
  if (!is.null(log_file)) {
    logger::log_appender(logger::appender_file(log_file))
  }

  logger::log_threshold(logger::INFO)
  logger::log_info("Logging initialized")
}

#' Create project directories
#'
#' @param base_dir Base directory path (default: ".")
create_project_dirs <- function(base_dir = ".") {
  dirs <- c(
    "data/raw/gdc",
    "data/raw/aws",
    "data/raw/clinical",
    "data/processed",
    "results/figures",
    "results/tables",
    "results/reports",
    "logs"
  )
  
  for (dir in dirs) {
    dir_path <- file.path(base_dir, dir)
    dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)
  }
  
  logger::log_info("Project directories created")
}

#' Save results with timestamp
#'
#' @param object R object to save
#' @param base_name Base name for the output file
#' @param dir Directory to save to (default: "results")
save_timestamped <- function(object, base_name, dir = "results") {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  filename <- paste0(base_name, "_", timestamp, ".rds")
  filepath <- file.path(dir, filename)
  
  saveRDS(object, filepath)
  logger::log_info("Saved {base_name} to {filepath}")
  
  return(filepath)
}

#' Generate summary statistics
#'
#' @param se_data A SummarizedExperiment object with a "counts" assay
summarize_data <- function(se_data) {
  counts <- get_counts_assay(se_data)

  summary_stats <- list(
    n_samples = ncol(counts),
    n_genes = nrow(counts),
    total_counts = sum(counts),
    median_counts_per_sample = median(colSums(counts)),
    median_genes_detected = median(colSums(counts > 0)),
    sparsity = mean(counts == 0)
  )
  
  return(summary_stats)
}

#' Check package dependencies
check_dependencies <- function() {
  required_pkgs <- c(
    "TCGAbiolinks", "GenomicDataCommons", "SummarizedExperiment",
    "DESeq2", "edgeR", "limma",
    "survival",  # survminer removed - not available in nixpkgs
    "targets", "crew",
    "tidyverse", "logger"
  )
  
  missing_pkgs <- required_pkgs[!required_pkgs %in% installed.packages()[, "Package"]]
  
  if (length(missing_pkgs) > 0) {
    warning("Missing packages: ", paste(missing_pkgs, collapse = ", "))
    return(FALSE)
  }
  
  message("All required packages are installed")
  return(TRUE)
}

#' Strip plotly closure bloat for compact serialization
#'
#' Plotly htmlwidgets capture parent environments in closures, causing
#' 60-80x size inflation when serialized via saveRDS/targets. This function
#' runs plotly_build() to resolve lazy data, then replaces closure
#' environments with emptyenv() to eliminate the bloat.
#'
#' @param p A plotly htmlwidget object
#' @return The same plotly object with closures stripped (much smaller on disk)
#' @family utilities
#' @export
#' @examples
#' \dontrun{
#' p <- plotly::plot_ly(mtcars, x = ~mpg, type = "histogram")
#' object.size(p)       # large
#' p2 <- strip_plotly(p)
#' object.size(p2)      # small
#' }
strip_plotly <- function(p) {
  # Build resolves lazy visdat closures into concrete data
  built <- plotly::plotly_build(p)
  # Replace any remaining closures with empty environments
  built$x$visdat <- NULL
  built$x$cur_data <- NULL
  built$x$attrs <- NULL
  built
}

#' Format File Size in Human-Readable Format
#'
#' Converts file sizes from bytes to human-readable format with appropriate units
#'
#' @param size_bytes Numeric vector of file sizes in bytes
#' @param digits Number of decimal places to show (default: 1)
#' @return Character vector with formatted file sizes
#' @family utilities
#' @export
#' @examples
#' format_file_size(c(1024, 1048576, 5000877192))
#' # Returns: "1.0 KB", "1.0 MB", "4.7 GB"
format_file_size <- function(size_bytes, digits = 1) {
  # Handle NA and non-numeric values
  if (!is.numeric(size_bytes)) {
    return(as.character(size_bytes))
  }

  # Units and thresholds
  units <- c("bytes", "KB", "MB", "GB", "TB", "PB")
  thresholds <- c(1, 1024, 1024^2, 1024^3, 1024^4, 1024^5)

  # Vectorized formatting
  result <- character(length(size_bytes))

  for (i in seq_along(size_bytes)) {
    if (is.na(size_bytes[i])) {
      result[i] <- NA_character_
    } else if (!is.finite(size_bytes[i]) || size_bytes[i] < 0) {
      result[i] <- as.character(size_bytes[i])
    } else if (size_bytes[i] < 1) {
      result[i] <- paste(size_bytes[i], "bytes")
    } else {
      # Find appropriate unit
      unit_idx <- max(which(size_bytes[i] >= thresholds))
      value <- size_bytes[i] / thresholds[unit_idx]

      # Format with commas for raw bytes
      if (unit_idx == 1) {
        result[i] <- format(size_bytes[i], big.mark = ",", scientific = FALSE)
        result[i] <- paste(result[i], units[unit_idx])
      } else {
        result[i] <- sprintf(paste0("%.", digits, "f %s"), value, units[unit_idx])
      }
    }
  }

  return(result)
}

#' Format Number with Thousands Separator
#'
#' Adds commas as thousands separators to large numbers
#'
#' @param x Numeric value or vector
#' @return Character vector with formatted numbers
#' @family utilities
#' @export
#' @examples
#' format_with_commas(1234567)
#' # Returns: "1,234,567"
format_with_commas <- function(x) {
  format(x, big.mark = ",", scientific = FALSE)
}

#' Create Summary Statistics Table
#'
#' Generate a nicely formatted summary statistics table for numeric variables
#'
#' @param data Data frame
#' @param vars Character vector of variable names (NULL for all numeric)
#' @return Data frame with summary statistics
#' @family utilities
#' @export
create_summary_table <- function(data, vars = NULL) {
  # Select numeric variables if vars not specified
  if (is.null(vars)) {
    vars <- names(data)[sapply(data, is.numeric)]
  }

  # Calculate statistics
  summary_list <- list()
  for (var in vars) {
    if (var %in% names(data) && is.numeric(data[[var]])) {
      values <- data[[var]][!is.na(data[[var]])]

      summary_list[[var]] <- data.frame(
        Variable = var,
        N = length(values),
        Missing = sum(is.na(data[[var]])),
        Mean = round(mean(values), 2),
        SD = round(sd(values), 2),
        Min = round(min(values), 2),
        Q1 = round(quantile(values, 0.25), 2),
        Median = round(median(values), 2),
        Q3 = round(quantile(values, 0.75), 2),
        Max = round(max(values), 2),
        stringsAsFactors = FALSE
      )
    }
  }

  do.call(rbind, summary_list)
}
