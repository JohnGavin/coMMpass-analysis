# R/07_gene_annotation.R
# Gene annotation and enrichment visualization functions

#' Annotate Ensembl gene IDs with symbols and descriptions
#'
#' Maps Ensembl gene IDs to HGNC symbols and Entrez IDs. Uses msigdbr gene
#' mapping as the primary source (always available with msigdbr). Falls back
#' to org.Hs.eg.db + AnnotationDbi if msigdbr is not installed.
#'
#' @param ensembl_ids Character vector of Ensembl gene IDs (versions stripped)
#' @return Data frame with columns: ensembl_gene, gene_symbol, entrez_gene.
#'   Unmappable IDs have NA for symbol/entrez.
#' @export
annotate_genes <- function(ensembl_ids) {
  if (is.null(ensembl_ids) || length(ensembl_ids) == 0) {
    return(data.frame(
      ensembl_gene = character(0),
      gene_symbol = character(0),
      entrez_gene = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Strip version suffixes if present
  ensembl_clean <- sub("\\.\\d+$", "", ensembl_ids)

  # Try msigdbr first (lighter dependency, usually available)
  if (requireNamespace("msigdbr", quietly = TRUE)) {
    return(annotate_via_msigdbr(ensembl_clean))
  }

  # Fallback: org.Hs.eg.db + AnnotationDbi
  if (requireNamespace("AnnotationDbi", quietly = TRUE) &&
      requireNamespace("org.Hs.eg.db", quietly = TRUE)) {
    return(annotate_via_orgdb(ensembl_clean))
  }

  # No annotation source available
  logger::log_warn(
    "No annotation package available (msigdbr or org.Hs.eg.db). ",
    "Returning IDs without symbols."
  )
  data.frame(
    ensembl_gene = ensembl_clean,
    gene_symbol = NA_character_,
    entrez_gene = NA_character_,
    stringsAsFactors = FALSE
  )
}

#' Annotate genes using msigdbr mapping table
#' @param ensembl_ids Character vector of clean Ensembl IDs
#' @return Data frame with ensembl_gene, gene_symbol, entrez_gene
#' @keywords internal
annotate_via_msigdbr <- function(ensembl_ids) {
  # msigdbr Hallmark contains most human genes
  hallmark <- msigdbr::msigdbr(species = "Homo sapiens", category = "H")

  # Build unique mapping table
  mapping <- unique(hallmark[, c("ensembl_gene", "gene_symbol", "entrez_gene")])
  mapping <- mapping[!is.na(mapping$ensembl_gene) &
                       nchar(mapping$ensembl_gene) > 0, ]
  # Deduplicate: keep first mapping per Ensembl ID
  mapping <- mapping[!duplicated(mapping$ensembl_gene), ]

  # If Hallmark doesn't cover all genes, try C2 as well
  if (sum(ensembl_ids %in% mapping$ensembl_gene) < length(ensembl_ids) * 0.5) {
    c2 <- msigdbr::msigdbr(species = "Homo sapiens", category = "C2")
    c2_map <- unique(c2[, c("ensembl_gene", "gene_symbol", "entrez_gene")])
    c2_map <- c2_map[!is.na(c2_map$ensembl_gene) &
                       nchar(c2_map$ensembl_gene) > 0, ]
    c2_map <- c2_map[!duplicated(c2_map$ensembl_gene), ]
    # Add genes not already in mapping
    new_genes <- c2_map[!c2_map$ensembl_gene %in% mapping$ensembl_gene, ]
    mapping <- rbind(mapping, new_genes)
  }

  # Left join
  result <- data.frame(ensembl_gene = ensembl_ids, stringsAsFactors = FALSE)
  result <- merge(result, mapping, by = "ensembl_gene", all.x = TRUE,
                  sort = FALSE)
  # Restore original order
  result <- result[match(ensembl_ids, result$ensembl_gene), ]
  result$entrez_gene <- as.character(result$entrez_gene)
  rownames(result) <- NULL

  n_mapped <- sum(!is.na(result$gene_symbol))
  logger::log_info(
    "Gene annotation: {n_mapped}/{length(ensembl_ids)} Ensembl IDs mapped ",
    "to symbols via msigdbr"
  )
  result
}

#' Annotate genes using org.Hs.eg.db
#' @param ensembl_ids Character vector of clean Ensembl IDs
#' @return Data frame with ensembl_gene, gene_symbol, entrez_gene
#' @keywords internal
annotate_via_orgdb <- function(ensembl_ids) {
  symbols <- AnnotationDbi::mapIds(
    org.Hs.eg.db::org.Hs.eg.db,
    keys = ensembl_ids,
    column = "SYMBOL",
    keytype = "ENSEMBL",
    multiVals = "first"
  )
  entrez <- AnnotationDbi::mapIds(
    org.Hs.eg.db::org.Hs.eg.db,
    keys = ensembl_ids,
    column = "ENTREZID",
    keytype = "ENSEMBL",
    multiVals = "first"
  )

  result <- data.frame(
    ensembl_gene = ensembl_ids,
    gene_symbol = unname(symbols),
    entrez_gene = unname(entrez),
    stringsAsFactors = FALSE
  )

  n_mapped <- sum(!is.na(result$gene_symbol))
  logger::log_info(
    "Gene annotation: {n_mapped}/{length(ensembl_ids)} Ensembl IDs mapped ",
    "to symbols via org.Hs.eg.db"
  )
  result
}

#' Add gene symbol column to DE results table
#'
#' @param de_results Data frame with Ensembl IDs as rownames
#' @param annotation Data frame from annotate_genes()
#' @return DE results with gene_symbol column prepended
#' @export
annotate_de_results <- function(de_results, annotation) {
  if (is.null(de_results) || nrow(de_results) == 0) return(de_results)
  if (is.null(annotation) || nrow(annotation) == 0) return(de_results)

  genes <- sub("\\.\\d+$", "", rownames(de_results))
  idx <- match(genes, annotation$ensembl_gene)
  de_results$gene_symbol <- annotation$gene_symbol[idx]

  # Move gene_symbol to first column
  cols <- c("gene_symbol", setdiff(names(de_results), "gene_symbol"))
  de_results[, cols]
}

# --- Enrichment Visualization ---

#' Dot plot of enrichment results
#'
#' Creates a dot plot of the top N enriched pathways. Dot size represents
#' gene set size, color represents significance (adjusted p-value or NES).
#'
#' @param enrich_result Data frame with pathway enrichment results. Must
#'   contain columns: pathway, padj, and one of: NES (GSEA), overlap (ORA).
#' @param n Number of top pathways to show (default 15)
#' @param color_by Which metric to color by: "padj" (default) or "NES"
#' @param title Plot title
#' @return A ggplot2 object
#' @export
plot_enrichment_dotplot <- function(
  enrich_result,
  n = 15L,
  color_by = "padj",
  title = "Enrichment Dot Plot"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required")
  }
  if (is.null(enrich_result) || nrow(enrich_result) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title, subtitle = "No enrichment results"))
  }

  # Sort by padj and take top N
  df <- enrich_result[order(enrich_result$padj), ]
  df <- utils::head(df, n)

  # Determine size variable
  size_var <- if ("size" %in% names(df)) "size" else
    if ("gene_set_size" %in% names(df)) "gene_set_size" else NULL

  # Clean pathway names for display
  df$pathway_label <- gsub("^HALLMARK_|^KEGG_|^REACTOME_|^GO_", "",
                           df$pathway)
  df$pathway_label <- gsub("_", " ", df$pathway_label)
  df$pathway_label <- factor(df$pathway_label,
                              levels = rev(df$pathway_label))

  # Color variable
  if (color_by == "NES" && "NES" %in% names(df)) {
    df$color_val <- df$NES
    color_label <- "NES"
    color_scale <- ggplot2::scale_color_gradient2(
      low = "#0066CC", mid = "white", high = "#DC3545",
      midpoint = 0, name = color_label
    )
  } else {
    df$color_val <- -log10(df$padj)
    color_label <- expression(-log[10]~"adj. p-value")
    color_scale <- ggplot2::scale_color_viridis_c(
      name = color_label, option = "plasma"
    )
  }

  aes_list <- list(
    x = quote(.data$color_val),
    y = quote(.data$pathway_label),
    color = quote(.data$color_val)
  )
  if (!is.null(size_var)) {
    aes_list$size <- as.name(size_var)
  }

  p <- ggplot2::ggplot(df, do.call(ggplot2::aes, aes_list)) +
    ggplot2::geom_point() +
    color_scale +
    ggplot2::labs(
      title = title,
      subtitle = paste0("Top ", nrow(df), " pathways by adjusted p-value"),
      x = if (color_by == "NES") "Normalized Enrichment Score" else
        expression(-log[10]~"adj. p-value"),
      y = NULL,
      size = "Gene set size"
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 9)
    )

  p
}

#' Bar plot of enrichment results
#'
#' Creates a horizontal bar plot of the top N enriched pathways, colored
#' by direction (GSEA) or significance (ORA).
#'
#' @param enrich_result Data frame with pathway enrichment results
#' @param n Number of top pathways to show (default 15)
#' @param title Plot title
#' @return A ggplot2 object
#' @export
plot_enrichment_barplot <- function(
  enrich_result,
  n = 15L,
  title = "Enrichment Bar Plot"
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required")
  }
  if (is.null(enrich_result) || nrow(enrich_result) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title, subtitle = "No enrichment results"))
  }

  df <- enrich_result[order(enrich_result$padj), ]
  df <- utils::head(df, n)

  # Clean pathway names
  df$pathway_label <- gsub("^HALLMARK_|^KEGG_|^REACTOME_|^GO_", "",
                           df$pathway)
  df$pathway_label <- gsub("_", " ", df$pathway_label)
  df$pathway_label <- factor(df$pathway_label,
                              levels = rev(df$pathway_label))

  # Use NES for GSEA results, -log10(padj) for ORA
  if ("NES" %in% names(df)) {
    df$bar_val <- df$NES
    df$direction <- ifelse(df$NES > 0, "Up", "Down")
    xlab <- "Normalized Enrichment Score"

    p <- ggplot2::ggplot(df, ggplot2::aes(
      x = .data$bar_val, y = .data$pathway_label, fill = .data$direction
    )) +
      ggplot2::geom_col() +
      ggplot2::scale_fill_manual(
        values = c("Up" = "#DC3545", "Down" = "#0066CC"),
        name = "Direction"
      ) +
      ggplot2::geom_vline(xintercept = 0, linewidth = 0.3)
  } else {
    df$bar_val <- -log10(df$padj)
    xlab <- expression(-log[10]~"adj. p-value")

    p <- ggplot2::ggplot(df, ggplot2::aes(
      x = .data$bar_val, y = .data$pathway_label
    )) +
      ggplot2::geom_col(fill = "#2E86AB")
  }

  n_sig <- sum(enrich_result$padj < 0.05, na.rm = TRUE)

  p +
    ggplot2::labs(
      title = title,
      subtitle = paste0(n_sig, " significant pathways (padj < 0.05)"),
      x = xlab,
      y = NULL
    ) +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      axis.text.y = ggplot2::element_text(size = 9)
    )
}

#' GSEA running enrichment score plot
#'
#' Shows the running enrichment score for a specific gene set from fgsea
#' results, along with the ranked gene positions.
#'
#' @param gsea_result List from run_gsea() containing results and ranked_genes
#' @param gene_set_name Name of the gene set to plot
#' @param gene_sets Named list of gene sets (required for tick marks).
#'   If NULL, attempts to retrieve from msigdbr using the collection.
#' @param title Plot title (default: gene set name)
#' @return A ggplot2 object
#' @export
plot_gsea_running_score <- function(
  gsea_result,
  gene_set_name,
  gene_sets = NULL,
  title = NULL
) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required")
  }
  if (is.null(gsea_result) || length(gsea_result$ranked_genes) == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = if (!is.null(title)) title else gene_set_name,
                           subtitle = "No GSEA data"))
  }

  # Get gene set members
  if (is.null(gene_sets)) {
    if (!requireNamespace("msigdbr", quietly = TRUE)) {
      cli::cli_abort("Provide gene_sets or install msigdbr")
    }
    gene_sets <- get_msigdb_gene_sets(gsea_result$collection, "ensembl_gene")
  }

  if (!gene_set_name %in% names(gene_sets)) {
    cli::cli_abort("Gene set '{gene_set_name}' not found")
  }

  ranked <- gsea_result$ranked_genes
  pathway_genes <- gene_sets[[gene_set_name]]
  hits <- names(ranked) %in% pathway_genes

  # Compute running enrichment score
  n <- length(ranked)
  n_hit <- sum(hits)
  if (n_hit == 0) {
    return(ggplot2::ggplot() + ggplot2::theme_void() +
             ggplot2::labs(title = title %||% gene_set_name,
                           subtitle = "No hits in ranked list"))
  }

  abs_ranked <- abs(ranked)
  hit_scores <- abs_ranked * hits
  nr <- sum(hit_scores)

  running_score <- numeric(n)
  score <- 0
  for (i in seq_len(n)) {
    if (hits[i]) {
      score <- score + hit_scores[i] / nr
    } else {
      score <- score - 1 / (n - n_hit)
    }
    running_score[i] <- score
  }

  # Get NES and padj from results
  res_row <- gsea_result$results[gsea_result$results$pathway == gene_set_name, ]
  nes <- if (nrow(res_row) > 0) round(res_row$NES[1], 3) else NA
  padj <- if (nrow(res_row) > 0) signif(res_row$padj[1], 3) else NA

  # Build plot data
  plot_df <- data.frame(
    rank = seq_len(n),
    score = running_score,
    hit = hits
  )

  clean_title <- if (is.null(title)) {
    gsub("^HALLMARK_|^KEGG_|^REACTOME_", "", gene_set_name)
  } else {
    title
  }

  subtitle <- paste0("NES = ", nes, ", padj = ", padj,
                      " (", n_hit, " genes)")

  p <- ggplot2::ggplot(plot_df) +
    ggplot2::geom_line(
      ggplot2::aes(x = .data$rank, y = .data$score),
      color = "#2E86AB", linewidth = 1
    ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    # Tick marks for gene set members
    ggplot2::geom_segment(
      data = plot_df[plot_df$hit, ],
      ggplot2::aes(x = .data$rank, xend = .data$rank,
                    y = -0.05, yend = 0.05),
      color = "grey30", linewidth = 0.2
    ) +
    ggplot2::labs(
      title = clean_title,
      subtitle = subtitle,
      x = "Gene rank",
      y = "Enrichment score"
    ) +
    ggplot2::theme_minimal(base_size = 12)

  p
}
