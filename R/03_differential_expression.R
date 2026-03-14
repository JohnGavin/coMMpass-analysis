# R/03_differential_expression.R
# Differential expression analysis functions

#' @importFrom stats model.matrix
NULL

#' Run DESeq2 differential expression analysis
#'
#' Runs DESeq2 with optional apeglm log-fold-change shrinkage and optional
#' paired longitudinal design for within-patient comparisons.
#'
#' @param se_data A SummarizedExperiment object
#' @param clinical_data Clinical data frame
#' @param design_formula Design formula for the model
#' @param shrink_lfc If TRUE, apply apeglm LFC shrinkage (default TRUE)
#' @param paired If TRUE, use paired longitudinal design with patient as
#'   blocking factor. Requires 'patient_id' and 'visit' columns in
#'   clinical_data. Only patients with >=2 timepoints are included.
#' @return List with DE results including raw and shrunken (if requested)
#' @family differential-expression
#' @export
run_deseq2 <- function(
  se_data,
  clinical_data,
  design_formula = ~condition,
  shrink_lfc = TRUE,
  paired = FALSE
) {
  logger::log_info("Running DESeq2 analysis (paired={paired}, shrink_lfc={shrink_lfc})...")

  if (paired) {
    return(run_deseq2_paired(se_data, clinical_data, shrink_lfc = shrink_lfc))
  }

  # Standard unpaired analysis
  counts <- extract_counts(se_data)
  col_data <- prepare_coldata(se_data, clinical_data, design_formula)

  if (is.null(counts) || is.null(col_data)) {
    return(placeholder_results("DESeq2"))
  }

  dds <- DESeq2::DESeqDataSetFromMatrix(
    countData = counts,
    colData = col_data,
    design = design_formula
  )
  dds <- DESeq2::DESeq(dds)
  res <- DESeq2::results(dds)

  results <- list(
    method = "DESeq2",
    design = deparse(design_formula),
    paired = FALSE,
    results_table = as.data.frame(res),
    n_deg = sum(res$padj < 0.05, na.rm = TRUE)
  )

  # apeglm LFC shrinkage for stable fold-change estimates
  if (shrink_lfc) {
    coef_name <- DESeq2::resultsNames(dds)[2]
    res_shrunk <- DESeq2::lfcShrink(dds, coef = coef_name, type = "apeglm")
    results$results_shrunk <- as.data.frame(res_shrunk)
    results$shrinkage_coef <- coef_name
    logger::log_info("Applied apeglm shrinkage on coefficient: {coef_name}")
  }

  logger::log_info("DESeq2 complete: {results$n_deg} DEGs (padj < 0.05)")
  return(results)
}

#' Run paired longitudinal DESeq2 analysis
#'
#' Within-patient comparison controlling for inter-patient variability.
#' Uses design `~ patient_id + visit` where patient_id is a blocking factor
#' and visit captures the treatment/relapse effect. Only patients with >=2
#' timepoints are included.
#'
#' @param se_data A SummarizedExperiment object
#' @param clinical_data Clinical data frame with patient_id and visit columns
#' @param shrink_lfc If TRUE, apply apeglm LFC shrinkage (default TRUE)
#' @return List with paired DE results
#' @keywords internal
run_deseq2_paired <- function(se_data, clinical_data, shrink_lfc = TRUE) {
  logger::log_info("Running paired longitudinal DESeq2 analysis...")

  counts <- extract_counts(se_data)
  if (is.null(counts)) return(placeholder_results("DESeq2_paired"))

  # Build sample metadata with patient + visit info
  sample_ids <- colnames(counts)
  col_data <- build_paired_coldata(sample_ids, clinical_data)

  if (is.null(col_data) || nrow(col_data) < 4) {
    logger::log_warn("Insufficient paired samples for longitudinal analysis")
    return(placeholder_results("DESeq2_paired"))
  }

  # Filter counts to paired samples only
  counts <- counts[, rownames(col_data), drop = FALSE]

  logger::log_info(
    "Paired design: {length(unique(col_data$patient_id))} patients, ",
    "{nrow(col_data)} samples"
  )

  # Paired design: patient blocks out inter-patient variability
  dds <- DESeq2::DESeqDataSetFromMatrix(
    countData = counts,
    colData = col_data,
    design = ~ patient_id + visit
  )
  dds <- DESeq2::DESeq(dds)

  # Results for visit effect (relapse vs baseline)
  res <- DESeq2::results(dds)

  results <- list(
    method = "DESeq2_paired",
    design = "~ patient_id + visit",
    paired = TRUE,
    n_patients = length(unique(col_data$patient_id)),
    n_samples = nrow(col_data),
    results_table = as.data.frame(res),
    n_deg = sum(res$padj < 0.05, na.rm = TRUE)
  )

  if (shrink_lfc) {
    coef_names <- DESeq2::resultsNames(dds)
    visit_coef <- grep("^visit", coef_names, value = TRUE)
    if (length(visit_coef) > 0) {
      res_shrunk <- DESeq2::lfcShrink(
        dds, coef = visit_coef[1], type = "apeglm"
      )
      results$results_shrunk <- as.data.frame(res_shrunk)
      results$shrinkage_coef <- visit_coef[1]
      logger::log_info("Applied apeglm shrinkage on: {visit_coef[1]}")
    }
  }

  logger::log_info(
    "Paired DESeq2 complete: {results$n_deg} DEGs from ",
    "{results$n_patients} patients"
  )
  return(results)
}

#' Build paired sample metadata
#'
#' Identifies patients with >=2 timepoints and creates a colData frame
#' suitable for DESeq2's paired design (~ patient_id + visit).
#'
#' @param sample_ids Character vector of sample IDs from expression data
#' @param clinical_data Clinical data frame
#' @return Data frame with patient_id and visit columns, rownames = sample_ids
#' @keywords internal
build_paired_coldata <- function(sample_ids, clinical_data) {
  # Extract patient ID and visit number from CoMMpass sample barcodes

  # CoMMpass barcodes: MMRF_1234_1_BM (patient_visit_tissue)
  parsed <- parse_commpass_barcodes(sample_ids)

  if (is.null(parsed) || nrow(parsed) == 0) {
    logger::log_warn("Could not parse CoMMpass barcodes for pairing")
    return(NULL)
  }

  # Keep only patients with >=2 timepoints
  patient_counts <- table(parsed$patient_id)
  paired_patients <- names(patient_counts[patient_counts >= 2])

  if (length(paired_patients) == 0) {
    logger::log_warn("No patients with >=2 timepoints found")
    return(NULL)
  }

  paired <- parsed[parsed$patient_id %in% paired_patients, ]
  logger::log_info(
    "Found {length(paired_patients)} patients with >=2 timepoints ",
    "({nrow(paired)} samples total)"
  )

  # Create binary visit factor: baseline (visit 1) vs relapsed (visit 2+)
  paired$visit <- factor(
    ifelse(paired$visit_number == 1, "baseline", "relapsed"),
    levels = c("baseline", "relapsed")
  )
  paired$patient_id <- factor(paired$patient_id)

  # Set rownames for DESeq2
  col_data <- as.data.frame(paired[, c("patient_id", "visit")])
  rownames(col_data) <- paired$sample_id

  col_data
}

#' Parse CoMMpass sample barcodes
#'
#' Extracts patient ID, visit number, and tissue type from CoMMpass-style
#' sample barcodes (e.g., "MMRF_1234_1_BM" or longer GDC barcodes).
#'
#' @param barcodes Character vector of sample barcodes
#' @return Data frame with sample_id, patient_id, visit_number columns
#' @keywords internal
parse_commpass_barcodes <- function(barcodes) {
  # CoMMpass barcodes vary in format:
  # Short: MMRF_1234_1_BM
  # GDC:   MMRF_1234_1_BM_CD138pos_T1_TSMRU
  # Extract the 4-digit patient ID and single-digit visit number

  patient_ids <- stringr::str_extract(barcodes, "(?<=MMRF_)\\d{4}")
  visit_numbers <- stringr::str_extract(barcodes, "(?<=MMRF_\\d{4}_)\\d")

  if (all(is.na(patient_ids))) {
    # Try alternative barcode format (submitter_id style)
    patient_ids <- stringr::str_extract(barcodes, "MMRF_\\d{4}")
    visit_numbers <- rep(NA_character_, length(barcodes))
  }

  valid <- !is.na(patient_ids) & !is.na(visit_numbers)
  if (sum(valid) == 0) return(NULL)

  data.frame(
    sample_id = barcodes[valid],
    patient_id = patient_ids[valid],
    visit_number = as.integer(visit_numbers[valid]),
    stringsAsFactors = FALSE
  )
}

#' Extract counts matrix from SummarizedExperiment
#' @param se_data SummarizedExperiment object
#' @return Integer matrix of counts, or NULL
#' @keywords internal
extract_counts <- function(se_data) {
  if (!inherits(se_data, "SummarizedExperiment")) {
    logger::log_warn("Input is not a SummarizedExperiment, returning NULL")
    return(NULL)
  }

  assay_names <- SummarizedExperiment::assayNames(se_data)
  if ("unstranded" %in% assay_names) {
    counts <- SummarizedExperiment::assay(se_data, "unstranded")
  } else if ("counts" %in% assay_names) {
    counts <- get_counts_assay(se_data)
  } else {
    counts <- SummarizedExperiment::assay(se_data, 1)
  }

  # DESeq2 requires integer counts
  storage.mode(counts) <- "integer"
  counts
}

#' Prepare colData for DESeq2
#' @param se_data SummarizedExperiment object
#' @param clinical_data Clinical data frame
#' @param design_formula Design formula
#' @return Data frame suitable for DESeq2 colData
#' @keywords internal
prepare_coldata <- function(se_data, clinical_data, design_formula) {
  # Extract variables needed from design formula
  design_vars <- all.vars(design_formula)

  col_data <- as.data.frame(SummarizedExperiment::colData(se_data))

  # Derive missing design variables from available clinical data
  if ("condition" %in% design_vars && !"condition" %in% names(col_data)) {
    # Derive condition from vital_status (Alive → control, Dead → case)
    if ("vital_status" %in% names(col_data)) {
      vs <- tolower(col_data$vital_status)
      col_data$condition <- factor(
        ifelse(vs %in% c("dead", "deceased"), "Dead", "Alive"),
        levels = c("Alive", "Dead")
      )
      n_dead <- sum(col_data$condition == "Dead", na.rm = TRUE)
      n_alive <- sum(col_data$condition == "Alive", na.rm = TRUE)
      logger::log_info(
        "Derived 'condition' from vital_status: {n_alive} Alive, {n_dead} Dead"
      )
      if (n_dead < 3 || n_alive < 3) {
        logger::log_warn(
          "Too few samples in one group (Alive={n_alive}, Dead={n_dead}); ",
          "need >= 3 per group for DE"
        )
        return(NULL)
      }
    } else if ("vital_status" %in% names(clinical_data)) {
      # Try from clinical_data argument if not in SE colData
      vs <- tolower(clinical_data$vital_status)
      col_data$condition <- factor(
        ifelse(vs %in% c("dead", "deceased"), "Dead", "Alive"),
        levels = c("Alive", "Dead")
      )
      logger::log_info("Derived 'condition' from clinical_data$vital_status")
    }
  }

  # Check if design variables are available
  missing_vars <- setdiff(design_vars, names(col_data))
  if (length(missing_vars) > 0) {
    logger::log_warn(
      "Design variables not in colData: {paste(missing_vars, collapse = ', ')}"
    )
    return(NULL)
  }

  col_data
}

#' Create placeholder results when real analysis cannot run
#' @param method Method name
#' @return List with placeholder DE results
#' @keywords internal
placeholder_results <- function(method) {
  list(
    method = method,
    n_deg = 0L,
    results_table = data.frame(
      gene = character(0),
      log2FoldChange = numeric(0),
      padj = numeric(0)
    ),
    note = "Placeholder: insufficient data for analysis"
  )
}

#' Run edgeR differential expression analysis
#'
#' @param se_data A SummarizedExperiment object
#' @param clinical_data Clinical data frame
#' @param design_formula Design formula for the model
#' @return List with DE results
run_edger <- function(se_data, clinical_data, design_formula = ~condition) {
  logger::log_info("Running edgeR analysis...")

  counts <- extract_counts(se_data)
  if (is.null(counts)) return(placeholder_results("edgeR"))

  col_data <- prepare_coldata(se_data, clinical_data, design_formula)
  if (is.null(col_data)) return(placeholder_results("edgeR"))

  design_vars <- all.vars(design_formula)
  design_mat <- model.matrix(design_formula, data = col_data)

  dge <- edgeR::DGEList(counts = counts)
  dge <- edgeR::calcNormFactors(dge)
  dge <- edgeR::estimateDisp(dge, design_mat)

  fit <- edgeR::glmQLFit(dge, design_mat)
  qlf <- edgeR::glmQLFTest(fit)
  res <- edgeR::topTags(qlf, n = Inf, sort.by = "none")$table

  results <- list(
    method = "edgeR",
    design = deparse(design_formula),
    results_table = res,
    n_deg = sum(res$FDR < 0.05, na.rm = TRUE)
  )

  logger::log_info("edgeR complete: {results$n_deg} DEGs (FDR < 0.05)")
  return(results)
}

#' Run limma differential expression analysis
#'
#' @param se_data A SummarizedExperiment object
#' @param clinical_data Clinical data frame
#' @param design_formula Design formula for the model
#' @return List with DE results
run_limma <- function(se_data, clinical_data, design_formula = ~condition) {
  logger::log_info("Running limma-voom analysis...")

  counts <- extract_counts(se_data)
  if (is.null(counts)) return(placeholder_results("limma"))

  col_data <- prepare_coldata(se_data, clinical_data, design_formula)
  if (is.null(col_data)) return(placeholder_results("limma"))

  design_mat <- model.matrix(design_formula, data = col_data)

  dge <- edgeR::DGEList(counts = counts)
  dge <- edgeR::calcNormFactors(dge)

  v <- limma::voom(dge, design_mat)
  fit <- limma::lmFit(v, design_mat)
  fit <- limma::eBayes(fit)
  res <- limma::topTable(fit, number = Inf, sort.by = "none")

  results <- list(
    method = "limma",
    design = deparse(design_formula),
    results_table = res,
    n_deg = sum(res$adj.P.Val < 0.05, na.rm = TRUE)
  )

  logger::log_info("limma complete: {results$n_deg} DEGs (adj.P.Val < 0.05)")
  return(results)
}

#' Find consensus DE genes across methods
#'
#' @param de_results_list List of DE result objects from different methods
#' @param padj_threshold Adjusted p-value threshold (default: 0.05)
#' @param lfc_threshold Log2 fold change threshold (default: 1)
#' @return List with consensus gene information
find_consensus_genes <- function(
  de_results_list,
  padj_threshold = 0.05,
  lfc_threshold = 1
) {
  logger::log_info("Finding consensus DE genes...")

  # Extract significant gene sets from each method
  sig_genes_by_method <- lapply(de_results_list, function(res) {
    tbl <- res$results_table
    if (is.null(tbl) || nrow(tbl) == 0) return(character(0))

    # Different methods use different column names for adjusted p-value
    padj_col <- intersect(c("padj", "FDR", "adj.P.Val"), names(tbl))
    lfc_col <- intersect(c("log2FoldChange", "logFC"), names(tbl))

    if (length(padj_col) == 0 || length(lfc_col) == 0) return(character(0))

    sig <- tbl[[padj_col[1]]] < padj_threshold &
      abs(tbl[[lfc_col[1]]]) > lfc_threshold
    sig[is.na(sig)] <- FALSE

    gene_names <- rownames(tbl)
    if (is.null(gene_names)) {
      gene_col <- intersect(c("gene", "gene_id"), names(tbl))
      if (length(gene_col) > 0) gene_names <- tbl[[gene_col[1]]]
    }

    if (is.null(gene_names)) return(character(0))
    gene_names[sig]
  })

  # Find genes significant in all methods
  if (length(sig_genes_by_method) == 0) {
    return(list(n_consensus = 0L, consensus_genes = character(0)))
  }

  consensus <- Reduce(intersect, sig_genes_by_method)

  logger::log_info("Found {length(consensus)} consensus genes across {length(de_results_list)} methods")

  list(
    n_consensus = length(consensus),
    consensus_genes = consensus,
    n_by_method = vapply(sig_genes_by_method, length, integer(1)),
    by_method = de_results_list
  )
}

#' Render DE analysis report
#'
#' @param de_results DE results object
#' @param output_dir Directory for output report
#' @return Path to generated report
render_de_report <- function(de_results, output_dir = "results/reports") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  report_file <- file.path(output_dir, "de_report.html")
  writeLines("DE Analysis Report", report_file)

  logger::log_info("DE report saved to {report_file}")
  return(report_file)
}
