# R/08_cytogenetic_viz.R
# Cytogenetic landscape visualization: oncoprint and co-occurrence

# Suppress R CMD check NOTEs for ggplot2 aes() variables
utils::globalVariables(c(
  "patient", "marker_label", "alt_type", "freq",
  "label1", "label2", "signed_logp",
  "expression", "marker_status"
))

#' Plot cytogenetic oncoprint
#'
#' Creates an oncoprint-style heatmap showing cytogenetic alterations across
#' patients. Rows are alterations, columns are patients. Uses ggplot2 for
#' portability (no ComplexHeatmap dependency).
#'
#' @param cyto_data Data frame from extract_cytogenetic_data() with columns:
#'   patient_id, iss_stage, t_4_14, t_11_14, t_14_16, del_17p, gain_1q, etc.
#' @param markers Character vector of marker columns to include. Default uses
#'   all available markers.
#' @param sort_by How to sort patients. One of "frequency" (default) or "risk".
#' @param title Plot title.
#' @return A ggplot object
#' @family cytogenetics
#' @export
#' @examples
#' \dontrun{
#' cyto <- arrow::read_parquet("data/raw/clinical/cytogenetic_data.parquet")
#' plot_cytogenetic_oncoprint(cyto)
#' }
plot_cytogenetic_oncoprint <- function(cyto_data,
                                       markers = NULL,
                                       sort_by = c("frequency", "risk"),
                                       title = "Cytogenetic Landscape") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for oncoprint plots.")
  }

  sort_by <- match.arg(sort_by)

  # Handle NULL/empty input

  if (is.null(cyto_data) || nrow(cyto_data) == 0) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No cytogenetic data available") +
             ggplot2::theme_void())
  }

  # Auto-detect marker columns
  all_markers <- c("t_4_14", "t_11_14", "t_14_16", "t_14_20",
                    "del_17p", "del_1p", "gain_1q")
  if (is.null(markers)) {
    markers <- intersect(all_markers, names(cyto_data))
  }
  if (length(markers) == 0) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No marker columns found") +
             ggplot2::theme_void())
  }

  # Build binary matrix (1 = positive, 0 = negative/NA)
  mat <- cyto_data[, markers, drop = FALSE]
  mat[] <- lapply(mat, function(x) as.integer(x == "positive"))
  mat[is.na(mat)] <- 0L

  # Pretty marker labels
  marker_labels <- c(
    t_4_14 = "t(4;14)", t_11_14 = "t(11;14)", t_14_16 = "t(14;16)",
    t_14_20 = "t(14;20)", del_17p = "del(17p)", del_1p = "del(1p)",
    gain_1q = "gain(1q)"
  )

  # Sort patients
  if (sort_by == "frequency") {
    row_order <- order(-rowSums(mat))
  } else {
    # Risk group first, then frequency
    risk <- if ("risk_group" %in% names(cyto_data)) {
      factor(cyto_data$risk_group, levels = c("high", "standard"))
    } else {
      factor(rep("unknown", nrow(cyto_data)))
    }
    row_order <- order(risk, -rowSums(mat))
  }
  mat <- mat[row_order, , drop = FALSE]

  # Sort markers by frequency (most frequent on top)
  marker_freq <- colSums(mat)
  marker_order <- order(-marker_freq)
  mat <- mat[, marker_order, drop = FALSE]
  markers <- markers[marker_order]

  # Convert to long format for ggplot2
  mat$patient_idx <- seq_len(nrow(mat))
  long <- do.call(rbind, lapply(markers, function(m) {
    data.frame(
      patient = mat$patient_idx,
      marker = m,
      status = mat[[m]],
      stringsAsFactors = FALSE
    )
  }))

  # Assign alteration type for coloring
  long$alt_type <- ifelse(
    grepl("^t_", long$marker), "Translocation",
    ifelse(grepl("^del_", long$marker), "Deletion", "Gain")
  )

  # Map marker names
  long$marker_label <- marker_labels[long$marker]
  # Order by frequency
  long$marker_label <- factor(long$marker_label,
                               levels = rev(marker_labels[markers]))

  # Build plot
  alt_colors <- c(
    "Translocation" = "#2166AC",
    "Deletion" = "#B2182B",
    "Gain" = "#4DAF4A"
  )

  p <- ggplot2::ggplot(
    long[long$status == 1, ],
    ggplot2::aes(x = patient, y = marker_label, fill = alt_type)
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.3) +
    ggplot2::scale_fill_manual(
      values = alt_colors,
      name = "Alteration Type",
      drop = FALSE
    ) +
    ggplot2::scale_x_continuous(expand = c(0, 0)) +
    ggplot2::labs(
      title = title,
      subtitle = paste0(nrow(mat), " patients, ", length(markers), " markers"),
      x = paste0("Patients (n = ", nrow(mat), ")"),
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      panel.grid = ggplot2::element_blank(),
      legend.position = "bottom"
    )

  # Add frequency annotation on the right
  freq_df <- data.frame(
    marker_label = factor(marker_labels[markers],
                           levels = rev(marker_labels[markers])),
    freq = paste0(round(100 * marker_freq[markers] / nrow(mat), 1), "%"),
    stringsAsFactors = FALSE
  )
  p <- p + ggplot2::geom_text(
    data = freq_df,
    ggplot2::aes(x = nrow(mat) + nrow(mat) * 0.02, y = marker_label,
                 label = freq),
    inherit.aes = FALSE, hjust = 0, size = 3.5
  ) +
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::theme(plot.margin = ggplot2::margin(5.5, 40, 5.5, 5.5))

  p
}


#' Calculate pairwise co-occurrence of cytogenetic alterations
#'
#' Computes Fisher's exact test for each pair of cytogenetic markers to
#' identify significant co-occurrence or mutual exclusivity patterns.
#'
#' @param cyto_data Data frame from extract_cytogenetic_data()
#' @param markers Character vector of marker columns. Default auto-detects.
#' @return Data frame with columns: marker1, marker2, odds_ratio, pvalue,
#'   padj (BH-corrected), n_both, n_either, tendency
#'   (co-occurrence/exclusive/none)
#' @family cytogenetics
#' @export
#' @examples
#' \dontrun{
#' cyto <- arrow::read_parquet("data/raw/clinical/cytogenetic_data.parquet")
#' cooc <- calculate_cooccurrence(cyto)
#' }
calculate_cooccurrence <- function(cyto_data, markers = NULL) {
  if (is.null(cyto_data) || nrow(cyto_data) == 0) {
    return(data.frame(
      marker1 = character(), marker2 = character(),
      odds_ratio = numeric(), pvalue = numeric(),
      padj = numeric(), n_both = integer(), n_either = integer(),
      tendency = character(), stringsAsFactors = FALSE
    ))
  }

  all_markers <- c("t_4_14", "t_11_14", "t_14_16", "t_14_20",
                    "del_17p", "del_1p", "gain_1q")
  if (is.null(markers)) {
    markers <- intersect(all_markers, names(cyto_data))
  }
  if (length(markers) < 2) {
    return(data.frame(
      marker1 = character(), marker2 = character(),
      odds_ratio = numeric(), pvalue = numeric(),
      padj = numeric(), n_both = integer(), n_either = integer(),
      tendency = character(), stringsAsFactors = FALSE
    ))
  }

  # Build binary matrix
  bin_mat <- cyto_data[, markers, drop = FALSE]
  bin_mat[] <- lapply(bin_mat, function(x) as.integer(x == "positive"))
  bin_mat[is.na(bin_mat)] <- 0L

  # All pairs
  pairs <- utils::combn(markers, 2, simplify = FALSE)
  results <- lapply(pairs, function(pair) {
    a <- bin_mat[[pair[1]]]
    b <- bin_mat[[pair[2]]]
    tab <- table(factor(a, levels = 0:1), factor(b, levels = 0:1))
    ft <- stats::fisher.test(tab)

    n_both <- sum(a == 1 & b == 1)
    n_either <- sum(a == 1 | b == 1)

    data.frame(
      marker1 = pair[1],
      marker2 = pair[2],
      odds_ratio = as.numeric(ft$estimate),
      pvalue = ft$p.value,
      n_both = n_both,
      n_either = n_either,
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, results)
  result$padj <- stats::p.adjust(result$pvalue, method = "BH")
  result$tendency <- ifelse(
    result$padj < 0.05 & result$odds_ratio > 1, "co-occurrence",
    ifelse(result$padj < 0.05 & result$odds_ratio < 1, "exclusive", "none")
  )

  result[order(result$pvalue), ]
}


#' Plot co-occurrence heatmap of cytogenetic alterations
#'
#' Displays pairwise co-occurrence patterns as a heatmap. Color indicates
#' -log10(p-value) direction: red for co-occurrence, blue for mutual
#' exclusivity.
#'
#' @param cooccurrence Data frame from calculate_cooccurrence()
#' @param title Plot title
#' @return A ggplot object
#' @family cytogenetics
#' @export
#' @examples
#' \dontrun{
#' cooc <- calculate_cooccurrence(cyto)
#' plot_cooccurrence_heatmap(cooc)
#' }
plot_cooccurrence_heatmap <- function(cooccurrence,
                                      title = "Cytogenetic Co-occurrence") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required.")
  }

  if (is.null(cooccurrence) || nrow(cooccurrence) == 0) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No co-occurrence data available") +
             ggplot2::theme_void())
  }

  # Pretty marker labels
  marker_labels <- c(
    t_4_14 = "t(4;14)", t_11_14 = "t(11;14)", t_14_16 = "t(14;16)",
    t_14_20 = "t(14;20)", del_17p = "del(17p)", del_1p = "del(1p)",
    gain_1q = "gain(1q)"
  )

  cooccurrence$label1 <- ifelse(
    cooccurrence$marker1 %in% names(marker_labels),
    marker_labels[cooccurrence$marker1], cooccurrence$marker1
  )
  cooccurrence$label2 <- ifelse(
    cooccurrence$marker2 %in% names(marker_labels),
    marker_labels[cooccurrence$marker2], cooccurrence$marker2
  )

  # Signed -log10(padj): positive = co-occurrence, negative = exclusive
  cooccurrence$signed_logp <- -log10(pmax(cooccurrence$padj, 1e-300)) *
    ifelse(cooccurrence$odds_ratio >= 1, 1, -1)

  # Symmetrize for full heatmap
  mirror <- cooccurrence
  mirror$label1 <- cooccurrence$label2
  mirror$label2 <- cooccurrence$label1
  mirror$marker1 <- cooccurrence$marker2
  mirror$marker2 <- cooccurrence$marker1
  full <- rbind(cooccurrence, mirror)

  # Order markers
  all_labels <- unique(c(full$label1, full$label2))
  full$label1 <- factor(full$label1, levels = all_labels)
  full$label2 <- factor(full$label2, levels = rev(all_labels))

  max_val <- max(abs(full$signed_logp), na.rm = TRUE)

  ggplot2::ggplot(full, ggplot2::aes(x = label1, y = label2,
                                      fill = signed_logp)) +
    ggplot2::geom_tile(color = "white", linewidth = 0.5) +
    ggplot2::geom_text(
      ggplot2::aes(label = ifelse(
        abs(signed_logp) > -log10(0.05), "*", ""
      )),
      size = 5
    ) +
    ggplot2::scale_fill_gradient2(
      low = "#2166AC", mid = "white", high = "#B2182B",
      midpoint = 0,
      limits = c(-max_val, max_val),
      name = expression(-log[10](padj) %*% sign)
    ) +
    ggplot2::labs(title = title, x = NULL, y = NULL) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
      panel.grid = ggplot2::element_blank()
    )
}


#' Summarize cytogenetic alteration frequencies
#'
#' Computes frequency and percentage for each marker and risk group.
#'
#' @param cyto_data Data frame from extract_cytogenetic_data()
#' @return Data frame with marker, n_positive, n_tested, pct columns
#' @family cytogenetics
#' @export
#' @examples
#' \dontrun{
#' cyto <- arrow::read_parquet("data/raw/clinical/cytogenetic_data.parquet")
#' summarize_cytogenetics(cyto)
#' }
summarize_cytogenetics <- function(cyto_data) {
  if (is.null(cyto_data) || nrow(cyto_data) == 0) {
    return(data.frame(
      marker = character(), n_positive = integer(),
      n_tested = integer(), pct = numeric(),
      stringsAsFactors = FALSE
    ))
  }

  all_markers <- c("t_4_14", "t_11_14", "t_14_16", "t_14_20",
                    "del_17p", "del_1p", "gain_1q")
  markers <- intersect(all_markers, names(cyto_data))

  marker_labels <- c(
    t_4_14 = "t(4;14)", t_11_14 = "t(11;14)", t_14_16 = "t(14;16)",
    t_14_20 = "t(14;20)", del_17p = "del(17p)", del_1p = "del(1p)",
    gain_1q = "gain(1q)"
  )

  result <- do.call(rbind, lapply(markers, function(m) {
    vals <- cyto_data[[m]]
    n_tested <- sum(!is.na(vals))
    n_positive <- sum(vals == "positive", na.rm = TRUE)
    data.frame(
      marker = if (m %in% names(marker_labels)) marker_labels[m] else m,
      n_positive = n_positive,
      n_tested = n_tested,
      pct = if (n_tested > 0) round(100 * n_positive / n_tested, 1) else NA_real_,
      stringsAsFactors = FALSE
    )
  }))
  row.names(result) <- NULL

  # Add risk group summary
  if ("risk_group" %in% names(cyto_data)) {
    n_high <- sum(cyto_data$risk_group == "high", na.rm = TRUE)
    n_classified <- sum(!is.na(cyto_data$risk_group))
    risk_row <- data.frame(
      marker = "Any high-risk",
      n_positive = n_high,
      n_tested = n_classified,
      pct = if (n_classified > 0) round(100 * n_high / n_classified, 1) else NA_real_,
      stringsAsFactors = FALSE
    )
    result <- rbind(result, risk_row)
  }

  result
}


#' Plot gene expression by cytogenetic subtype
#'
#' Creates violin + box plots showing gene expression stratified by cytogenetic
#' marker status (positive vs negative). Adds Wilcoxon or t-test p-value
#' annotation.
#'
#' @param expr_matrix Numeric matrix (genes x samples) of transformed
#'   expression values (e.g., VST). Column names should match
#'   `cyto_data$patient_id`.
#' @param cyto_data Data frame with `patient_id` and marker columns
#'   (values: "positive"/"negative"/NA)
#' @param gene Gene name (rowname of `expr_matrix`)
#' @param markers Character vector of marker columns. Default auto-detects.
#' @param test Statistical test: "wilcox" (default) or "t.test"
#' @return A ggplot object with faceted violin/box plots, one panel per marker
#' @family cytogenetics
#' @export
plot_expression_by_subtype <- function(expr_matrix,
                                        cyto_data,
                                        gene,
                                        markers = NULL,
                                        test = c("wilcox", "t.test")) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required.")
  }
  test <- match.arg(test)

  if (is.null(expr_matrix) || !is.matrix(expr_matrix) ||
      is.null(cyto_data) || nrow(cyto_data) == 0) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No expression or cytogenetic data") +
             ggplot2::theme_void())
  }

  if (!gene %in% rownames(expr_matrix)) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = paste0("Gene '", gene, "' not found")) +
             ggplot2::theme_void())
  }

  # Auto-detect markers
  all_markers <- c("t_4_14", "t_11_14", "t_14_16", "t_14_20",
                    "del_17p", "del_1p", "gain_1q")
  if (is.null(markers)) {
    markers <- intersect(all_markers, names(cyto_data))
  }
  if (length(markers) == 0) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No marker columns found") +
             ggplot2::theme_void())
  }

  marker_labels <- c(
    t_4_14 = "t(4;14)", t_11_14 = "t(11;14)", t_14_16 = "t(14;16)",
    t_14_20 = "t(14;20)", del_17p = "del(17p)", del_1p = "del(1p)",
    gain_1q = "gain(1q)"
  )

  # Match patients
  common <- intersect(cyto_data$patient_id, colnames(expr_matrix))
  if (length(common) < 3) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "Too few matched patients") +
             ggplot2::theme_void())
  }

  expr_vals <- as.numeric(expr_matrix[gene, common])

  # Build long data frame across markers
  long_list <- lapply(markers, function(m) {
    status <- cyto_data[[m]][match(common, cyto_data$patient_id)]
    valid <- status %in% c("positive", "negative")
    if (sum(valid) < 3) return(NULL)

    data.frame(
      expression = expr_vals[valid],
      marker_status = status[valid],
      marker_label = if (m %in% names(marker_labels)) marker_labels[m] else m,
      stringsAsFactors = FALSE
    )
  })
  long <- do.call(rbind, Filter(Negate(is.null), long_list))

  if (is.null(long) || nrow(long) == 0) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "No valid marker data") +
             ggplot2::theme_void())
  }

  # Compute p-values per marker
  p_labels <- tapply(seq_len(nrow(long)), long$marker_label, function(idx) {
    sub <- long[idx, ]
    pos <- sub$expression[sub$marker_status == "positive"]
    neg <- sub$expression[sub$marker_status == "negative"]
    if (length(pos) < 3 || length(neg) < 3) return("n.s.")
    pval <- tryCatch({
      if (test == "wilcox") {
        stats::wilcox.test(pos, neg)$p.value
      } else {
        stats::t.test(pos, neg)$p.value
      }
    }, error = function(e) NA_real_)
    if (is.na(pval)) return("n.s.")
    if (pval < 0.001) return("p < 0.001")
    sprintf("p = %.3f", pval)
  })
  p_df <- data.frame(
    marker_label = names(p_labels),
    p_label = as.character(p_labels),
    y_pos = max(long$expression, na.rm = TRUE) * 1.05,
    stringsAsFactors = FALSE
  )

  long$marker_status <- factor(long$marker_status,
                                levels = c("negative", "positive"))

  ggplot2::ggplot(long, ggplot2::aes(x = marker_status, y = expression,
                                      fill = marker_status)) +
    ggplot2::geom_violin(alpha = 0.4, scale = "width") +
    ggplot2::geom_boxplot(width = 0.2, outlier.size = 0.8, alpha = 0.8) +
    ggplot2::geom_text(
      data = p_df,
      ggplot2::aes(x = 1.5, y = y_pos, label = p_label),
      inherit.aes = FALSE, size = 3, color = "grey30"
    ) +
    ggplot2::facet_wrap(~marker_label, scales = "free_y") +
    ggplot2::scale_fill_manual(
      values = c("negative" = "#4DAF4A", "positive" = "#B2182B"),
      name = "Status"
    ) +
    ggplot2::labs(
      title = paste0(gene, " Expression by Cytogenetic Subtype"),
      subtitle = paste0("n = ", length(common), " patients | ",
                         test, " test"),
      x = "Marker Status",
      y = paste0(gene, " expression (VST)")
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(legend.position = "none")
}
