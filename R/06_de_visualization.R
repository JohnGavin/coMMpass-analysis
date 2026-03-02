# R/06_de_visualization.R
# Standalone DE visualization functions
# Extracted from inst/shiny/modules/mod_de_viz.R for use in vignettes and reports

#' @importFrom stats prcomp setNames
NULL

# --- Column name helpers (internal) ---

#' Find the adjusted p-value column name
#' @param df Data frame with DE results
#' @return Column name string
#' @keywords internal
find_padj_col <- function(df) {
  candidates <- c("padj", "FDR", "adj.P.Val")
  for (col in candidates) {
    if (col %in% names(df)) return(col)
  }
  NULL
}

#' Find the log fold-change column name
#' @param df Data frame with DE results
#' @return Column name string
#' @keywords internal
find_lfc_col <- function(df) {
  candidates <- c("log2FoldChange", "log2FC", "logFC")
  for (col in candidates) {
    if (col %in% names(df)) return(col)
  }
  NULL
}

#' Find the mean expression column name
#' @param df Data frame with DE results
#' @return Column name string
#' @keywords internal
find_expr_col <- function(df) {
  candidates <- c("baseMean", "AveExpr", "logCPM")
  for (col in candidates) {
    if (col %in% names(df)) return(col)
  }
  NULL
}

# --- VST and PCA ---

#' Run variance stabilizing transformation
#'
#' Wrapper around DESeq2::vst() for use in visualization. VST is appropriate
#' for PCA, heatmaps, and clustering -- not for DE testing (which uses raw
#' counts).
#'
#' @param se_data SummarizedExperiment with "counts" assay
#' @param blind Logical, whether VST should be blind to the design (default
#'   TRUE for exploratory analysis)
#' @return SummarizedExperiment with "vst" assay added, or NULL if DESeq2
#'   is not available
#' @family differential-expression
#' @export
run_vst <- function(se_data, blind = TRUE) {
  if (!requireNamespace("DESeq2", quietly = TRUE)) {
    logger::log_warn("DESeq2 not available, skipping VST")
    return(NULL)
  }
  if (is.null(se_data)) return(NULL)

  counts <- get_counts_assay(se_data)
  if (ncol(counts) < 2) {
    logger::log_warn("Need at least 2 samples for VST")
    return(NULL)
  }

  logger::log_info("Running VST on {ncol(counts)} samples, {nrow(counts)} genes")

  dds <- DESeq2::DESeqDataSetFromMatrix(
    countData = counts,
    colData = SummarizedExperiment::colData(se_data),
    design = ~1
  )
  vsd <- DESeq2::vst(dds, blind = blind)
  vst_mat <- SummarizedExperiment::assay(vsd)

  SummarizedExperiment::`assay<-`(se_data, "vst", value = vst_mat)
}

#' Compute PCA from transformed expression data
#'
#' @param expr_matrix Numeric matrix (genes x samples) of transformed
#'   expression values (e.g., VST or logCPM)
#' @param n_top Number of most variable genes to use (default 500)
#' @param metadata Optional data frame of sample annotations to merge with
#'   PCA coordinates
#' @return List with components: coords (data frame with PC1, PC2, ...),
#'   var_explained (numeric vector of variance proportions), n_genes_used
#' @family differential-expression
#' @export
compute_pca <- function(expr_matrix, n_top = 500L, metadata = NULL) {
  if (is.null(expr_matrix) || ncol(expr_matrix) < 2) {
    return(list(
      coords = data.frame(),
      var_explained = numeric(0),
      n_genes_used = 0L
    ))
  }

  # Select most variable genes
  gene_vars <- apply(expr_matrix, 1, stats::var)
  gene_vars <- gene_vars[!is.na(gene_vars) & gene_vars > 0]
  n_use <- min(n_top, length(gene_vars))
  top_genes <- names(sort(gene_vars, decreasing = TRUE))[seq_len(n_use)]
  sub_mat <- expr_matrix[top_genes, , drop = FALSE]

  pca <- stats::prcomp(t(sub_mat), center = TRUE, scale. = TRUE)
  var_exp <- pca$sdev^2 / sum(pca$sdev^2)

  coords <- as.data.frame(pca$x)
  coords$sample <- rownames(coords)

  if (!is.null(metadata) && is.data.frame(metadata)) {
    # Merge by sample name or rowname
    if ("sample" %in% names(metadata)) {
      coords <- merge(coords, metadata, by = "sample", all.x = TRUE)
    } else if (!is.null(rownames(metadata))) {
      metadata$sample <- rownames(metadata)
      coords <- merge(coords, metadata, by = "sample", all.x = TRUE)
    }
  }

  list(
    coords = coords,
    var_explained = var_exp,
    n_genes_used = n_use
  )
}

# --- Plot functions ---

#' Volcano plot of DE results
#'
#' Creates a ggplot2 volcano plot with significance thresholds and optional
#' gene labels.
#'
#' @param de_results Data frame with DE results (must have padj and log2FC
#'   columns -- auto-detected from DESeq2/edgeR/limma conventions)
#' @param lfc_threshold Log2 fold-change threshold for significance (default 1)
#' @param padj_threshold Adjusted p-value threshold (default 0.05)
#' @param n_label Number of top genes to label (default 10)
#' @param title Plot title
#' @return A ggplot2 object
#' @family differential-expression
#' @export
plot_volcano <- function(
  de_results,
  lfc_threshold = 1,
  padj_threshold = 0.05,
  n_label = 10L,
  title = "Volcano Plot"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for plot_volcano()")
  }
  if (is.null(de_results) || nrow(de_results) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title, subtitle = "No data available"))
  }

  padj_col <- find_padj_col(de_results)
  lfc_col <- find_lfc_col(de_results)
  if (is.null(padj_col) || is.null(lfc_col)) {
    cli::cli_abort(c(
      "x" = "Cannot find required columns in DE results",
      "i" = "Need padj/FDR/adj.P.Val and log2FoldChange/logFC columns"
    ))
  }

  df <- de_results
  df$gene <- rownames(df)
  df$neg_log10_padj <- -log10(df[[padj_col]])
  df$lfc <- df[[lfc_col]]

  # Classify genes

  df$status <- "Not Significant"
  sig <- df[[padj_col]] < padj_threshold & !is.na(df[[padj_col]])
  df$status[sig & df$lfc > lfc_threshold] <- "Up"
  df$status[sig & df$lfc < -lfc_threshold] <- "Down"
  df$status <- factor(df$status, levels = c("Up", "Down", "Not Significant"))

  # Label top genes by significance
  df_sig <- df[df$status != "Not Significant", ]
  if (nrow(df_sig) > 0) {
    df_sig <- df_sig[order(df_sig[[padj_col]]), ]
    label_genes <- utils::head(df_sig$gene, n_label)
  } else {
    label_genes <- character(0)
  }
  df$label <- ifelse(df$gene %in% label_genes, df$gene, NA_character_)

  n_up <- sum(df$status == "Up")
  n_down <- sum(df$status == "Down")

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$lfc, y = .data$neg_log10_padj)) +
    ggplot2::geom_point(
      ggplot2::aes(color = .data$status),
      size = 1, alpha = 0.6
    ) +
    ggplot2::scale_color_manual(
      values = c("Up" = "#DC3545", "Down" = "#0066CC", "Not Significant" = "#CCCCCC"),
      name = "Direction"
    ) +
    ggplot2::geom_vline(
      xintercept = c(-lfc_threshold, lfc_threshold),
      linetype = "dashed", color = "grey40"
    ) +
    ggplot2::geom_hline(
      yintercept = -log10(padj_threshold),
      linetype = "dashed", color = "grey40"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = paste0(n_up, " up, ", n_down, " down (|LFC|>", lfc_threshold,
                         ", padj<", padj_threshold, ")"),
      x = expression(log[2]~"fold change"),
      y = expression(-log[10]~"adjusted p-value")
    ) +
    ggplot2::theme_minimal(base_size = 12)

  # Add gene labels if ggrepel available
  if (length(label_genes) > 0 &&
      requireNamespace("ggplot2", quietly = TRUE)) {
    p <- p + ggplot2::geom_text(
      data = df[!is.na(df$label), ],
      ggplot2::aes(label = .data$label),
      size = 2.5, hjust = -0.1, vjust = 0.5, check_overlap = TRUE
    )
  }

  p
}

#' MA plot of DE results
#'
#' Plots mean expression (x-axis) vs log2 fold change (y-axis), a standard
#' diagnostic for RNA-seq DE analysis.
#'
#' @param de_results Data frame with DE results
#' @param lfc_threshold Log2 fold-change threshold for coloring (default 1)
#' @param padj_threshold Adjusted p-value threshold (default 0.05)
#' @param title Plot title
#' @return A ggplot2 object
#' @family differential-expression
#' @export
plot_ma <- function(
  de_results,
  lfc_threshold = 1,
  padj_threshold = 0.05,
  title = "MA Plot"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for plot_ma()")
  }
  if (is.null(de_results) || nrow(de_results) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title, subtitle = "No data available"))
  }

  padj_col <- find_padj_col(de_results)
  lfc_col <- find_lfc_col(de_results)
  expr_col <- find_expr_col(de_results)
  if (is.null(lfc_col)) {
    cli::cli_abort("Cannot find log fold-change column in DE results")
  }

  df <- de_results
  df$lfc <- df[[lfc_col]]

  # Mean expression: baseMean (DESeq2), AveExpr (limma), or logCPM (edgeR)
  if (!is.null(expr_col)) {
    if (expr_col == "baseMean") {
      df$mean_expr <- log10(df[[expr_col]] + 1)
    } else {
      df$mean_expr <- df[[expr_col]]
    }
  } else {
    cli::cli_abort("Cannot find mean expression column (baseMean/AveExpr/logCPM)")
  }

  # Significance
  df$significant <- FALSE
  if (!is.null(padj_col)) {
    df$significant <- df[[padj_col]] < padj_threshold &
      abs(df$lfc) > lfc_threshold &
      !is.na(df[[padj_col]])
  }

  n_sig <- sum(df$significant)

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$mean_expr, y = .data$lfc)) +
    ggplot2::geom_point(
      ggplot2::aes(color = .data$significant),
      size = 1, alpha = 0.5
    ) +
    ggplot2::scale_color_manual(
      values = c("TRUE" = "#DC3545", "FALSE" = "#CCCCCC"),
      labels = c("TRUE" = "Significant", "FALSE" = "Not significant"),
      name = ""
    ) +
    ggplot2::geom_hline(
      yintercept = c(-lfc_threshold, 0, lfc_threshold),
      linetype = c("dashed", "solid", "dashed"),
      color = c("grey40", "grey20", "grey40")
    ) +
    ggplot2::labs(
      title = title,
      subtitle = paste0(n_sig, " significant genes"),
      x = if (expr_col == "baseMean") expression(log[10]~"mean expression") else "Mean expression",
      y = expression(log[2]~"fold change")
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}

#' PCA plot
#'
#' Creates a PCA scatter plot from pre-computed PCA data.
#'
#' @param pca_data List from compute_pca() with coords and var_explained
#' @param color_by Column name in coords to color by (default NULL)
#' @param shape_by Column name in coords to use for shape (default NULL)
#' @param title Plot title
#' @return A ggplot2 object
#' @family differential-expression
#' @export
plot_pca <- function(
  pca_data,
  color_by = NULL,
  shape_by = NULL,
  title = "PCA"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for plot_pca()")
  }
  if (is.null(pca_data) || nrow(pca_data$coords) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title, subtitle = "No data available"))
  }

  coords <- pca_data$coords
  var_exp <- pca_data$var_explained

  # Build axis labels with variance explained
  xlab <- paste0("PC1 (", round(var_exp[1] * 100, 1), "% variance)")
  ylab <- paste0("PC2 (", round(var_exp[2] * 100, 1), "% variance)")

  aes_args <- list(x = quote(.data$PC1), y = quote(.data$PC2))
  if (!is.null(color_by) && color_by %in% names(coords)) {
    aes_args$color <- as.name(color_by)
  }
  if (!is.null(shape_by) && shape_by %in% names(coords)) {
    aes_args$shape <- as.name(shape_by)
  }

  p <- ggplot2::ggplot(coords, do.call(ggplot2::aes, aes_args)) +
    ggplot2::geom_point(size = 3, alpha = 0.8) +
    ggplot2::labs(
      title = title,
      subtitle = paste0("Top ", pca_data$n_genes_used, " most variable genes"),
      x = xlab,
      y = ylab
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}

#' Heatmap of top DE genes
#'
#' Creates a heatmap of the top differentially expressed genes using
#' z-score scaled expression values.
#'
#' @param expr_matrix Numeric matrix of transformed expression (genes x samples)
#' @param de_results Data frame with DE results (rownames = gene IDs)
#' @param n_genes Number of top DE genes to show (default 50)
#' @param annotation_df Optional data frame of sample annotations for column
#'   annotation
#' @param title Plot title
#' @return A ggplot2 object (tile-based heatmap)
#' @family differential-expression
#' @export
plot_heatmap_de <- function(
  expr_matrix,
  de_results,
  n_genes = 50L,
  annotation_df = NULL,
  title = "Top DE Genes"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required for plot_heatmap_de()")
  }
  if (is.null(expr_matrix) || is.null(de_results) || nrow(de_results) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title, subtitle = "No data available"))
  }

  padj_col <- find_padj_col(de_results)
  if (is.null(padj_col)) {
    cli::cli_abort("Cannot find adjusted p-value column in DE results")
  }

  # Select top genes by adjusted p-value
  de_ordered <- de_results[order(de_results[[padj_col]]), ]
  top_genes <- utils::head(rownames(de_ordered), n_genes)
  # Intersect with available genes in expression matrix
  common_genes <- intersect(top_genes, rownames(expr_matrix))
  if (length(common_genes) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title,
                           subtitle = "No matching genes between DE results and expression"))
  }

  sub_mat <- expr_matrix[common_genes, , drop = FALSE]

  # Z-score scale rows
  sub_scaled <- t(scale(t(sub_mat)))

  # Cluster rows and columns
  if (nrow(sub_scaled) > 2 && ncol(sub_scaled) > 2) {
    row_order <- stats::hclust(stats::dist(sub_scaled))$order
    col_order <- stats::hclust(stats::dist(t(sub_scaled)))$order
  } else {
    row_order <- seq_len(nrow(sub_scaled))
    col_order <- seq_len(ncol(sub_scaled))
  }

  sub_scaled <- sub_scaled[row_order, col_order, drop = FALSE]

  # Melt to long format
  long_df <- data.frame(
    gene = rep(rownames(sub_scaled), ncol(sub_scaled)),
    sample = rep(colnames(sub_scaled), each = nrow(sub_scaled)),
    zscore = as.vector(sub_scaled),
    stringsAsFactors = FALSE
  )
  long_df$gene <- factor(long_df$gene, levels = rownames(sub_scaled))
  long_df$sample <- factor(long_df$sample, levels = colnames(sub_scaled))

  # Clamp z-scores for visual clarity
  long_df$zscore <- pmax(pmin(long_df$zscore, 3), -3)

  p <- ggplot2::ggplot(long_df, ggplot2::aes(
    x = .data$sample, y = .data$gene, fill = .data$zscore
  )) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient2(
      low = "#0066CC", mid = "white", high = "#DC3545",
      midpoint = 0, limits = c(-3, 3),
      name = "Z-score"
    ) +
    ggplot2::labs(
      title = title,
      subtitle = paste0(length(common_genes), " genes, ",
                         ncol(sub_scaled), " samples"),
      x = "Sample",
      y = "Gene"
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 7),
      axis.text.y = ggplot2::element_text(size = 6)
    )

  p
}

#' Summarize DE results across methods
#'
#' Creates a summary table showing the number of significant genes per DE
#' method.
#'
#' @param de_list Named list of DE result lists (each with results_table)
#' @param padj_threshold Adjusted p-value threshold (default 0.05)
#' @param lfc_threshold Log2 fold-change threshold (default 1)
#' @return Data frame with method, n_tested, n_sig, n_up, n_down
#' @family differential-expression
#' @export
summarize_de_methods <- function(
  de_list,
  padj_threshold = 0.05,
  lfc_threshold = 1
) {
  if (is.null(de_list) || length(de_list) == 0) {
    return(data.frame(
      method = character(0),
      n_tested = integer(0),
      n_sig = integer(0),
      n_up = integer(0),
      n_down = integer(0),
      stringsAsFactors = FALSE
    ))
  }

  results <- lapply(names(de_list), function(name) {
    res <- de_list[[name]]
    tbl <- if (is.data.frame(res)) res else res$results_table
    if (is.null(tbl) || nrow(tbl) == 0) {
      return(data.frame(
        method = name, n_tested = 0L, n_sig = 0L,
        n_up = 0L, n_down = 0L, stringsAsFactors = FALSE
      ))
    }

    padj_col <- find_padj_col(tbl)
    lfc_col <- find_lfc_col(tbl)
    if (is.null(padj_col) || is.null(lfc_col)) {
      return(data.frame(
        method = name, n_tested = nrow(tbl), n_sig = 0L,
        n_up = 0L, n_down = 0L, stringsAsFactors = FALSE
      ))
    }

    sig <- tbl[[padj_col]] < padj_threshold & !is.na(tbl[[padj_col]])
    up <- sig & tbl[[lfc_col]] > lfc_threshold
    down <- sig & tbl[[lfc_col]] < -lfc_threshold

    data.frame(
      method = name,
      n_tested = nrow(tbl),
      n_sig = sum(sig),
      n_up = sum(up),
      n_down = sum(down),
      stringsAsFactors = FALSE
    )
  })

  do.call(rbind, results)
}
