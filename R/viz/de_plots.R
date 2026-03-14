# R/viz/de_plots.R
# Named visualization functions for differential expression vignette targets.
# Each function's body is extractable as code provenance via code_vig_* targets.

#' @keywords internal
make_de_method_barplot <- function(de_method_summary) {
  if (is.null(de_method_summary) || nrow(de_method_summary) == 0) return(NULL)

  long <- rbind(
    data.frame(method = de_method_summary$method, direction = "Up",
               count = de_method_summary$n_up),
    data.frame(method = de_method_summary$method, direction = "Down",
               count = -de_method_summary$n_down)
  )

  ggplot2::ggplot(long, ggplot2::aes(x = method, y = count,
                                      fill = direction)) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_manual(
      values = c("Up" = "#DC3545", "Down" = "#0066CC"),
      name = "Direction"
    ) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.3) +
    ggplot2::labs(
      title = "DE Genes by Method",
      x = NULL,
      y = "Number of genes (down shown as negative)",
      caption = paste0(
        "DESeq2: negative binomial GLM with apeglm shrinkage. ",
        "edgeR: quasi-likelihood F-test with TMM normalization. ",
        "limma: empirical Bayes moderated t-test with voom weights. ",
        "Up (red) = log2FC > 1. Down (blue) = log2FC < -1. ",
        "Thresholds: |log2FC| > 1, padj < 0.05. ",
        "With sample_limit=20, zero significant genes is expected. ",
        "Source: DESeq2/edgeR/limma results. ",
        "See method table for exact counts and annotated DE table for top genes."
      )
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.caption = ggplot2::element_text(
      size = 7, hjust = 0, lineheight = 1.2
    ))
}

#' @keywords internal
make_de_method_table <- function(de_method_summary) {
  if (is.null(de_method_summary) || nrow(de_method_summary) == 0) return(NULL)

  caption <- paste0(
    "Differential expression results across methods. ",
    "Method = DE analysis package. ",
    "DESeq2: negative binomial GLM with Wald test and apeglm LFC shrinkage. ",
    "edgeR: quasi-likelihood F-test with TMM normalization. ",
    "limma-voom: linear models with precision weights on log2-CPM. ",
    "Genes Tested = number of genes after filtering. ",
    "Significant = genes with |log2FC| > 1 AND adjusted p-value < 0.05. ",
    "Up/Down = direction of fold change (tumor vs normal)."
  )
  DT::datatable(
    de_method_summary, rownames = FALSE,
    filter = "top",
    options = list(pageLength = 10, scrollX = TRUE),
    colnames = c("Method", "Genes Tested", "Significant", "Up", "Down"),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}

#' @keywords internal
make_annotated_de_table <- function(de_results_annotated) {
  if (is.null(de_results_annotated) || nrow(de_results_annotated) == 0) {
    return(NULL)
  }

  top <- utils::head(
    de_results_annotated[order(de_results_annotated$padj), ], 15
  )
  display_cols <- intersect(
    c("gene_symbol", "log2FoldChange", "baseMean", "padj"),
    names(top)
  )

  if ("log2FoldChange" %in% names(top))
    top$log2FoldChange <- round(top$log2FoldChange, 2)
  if ("baseMean" %in% names(top))
    top$baseMean <- round(top$baseMean, 1)
  if ("padj" %in% names(top))
    top$padj <- signif(top$padj, 4)

  caption <- paste0(
    "Top 15 DE genes by adjusted p-value (DESeq2). ",
    "gene_symbol = HGNC symbol mapped from Ensembl IDs via MSigDB. ",
    "log2FoldChange = log2 ratio (positive = upregulated in tumor/relapse). ",
    "baseMean = mean normalized count across all samples. ",
    "padj = Benjamini-Hochberg adjusted p-value. ",
    "See data dictionary for gene ID details."
  )
  DT::datatable(
    top[, display_cols], rownames = FALSE,
    filter = "top",
    options = list(pageLength = 15, scrollX = TRUE),
    caption = htmltools::tags$caption(
      style = "caption-side: top; text-align: left;", caption
    )
  )
}
