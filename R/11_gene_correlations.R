# R/11_gene_correlations.R
# Gene-gene correlation analysis utilities

# Suppress R CMD check NOTEs for ggplot2 aes() variables
utils::globalVariables(c("expr_x", "expr_y"))

#' Correlate two genes across samples
#'
#' Computes Pearson or Spearman correlation between two genes in an
#' expression matrix.
#'
#' @param expr_matrix Numeric matrix (genes x samples) of transformed
#'   expression values (e.g., VST)
#' @param gene_x Gene name for x-axis
#' @param gene_y Gene name for y-axis
#' @param method Correlation method: "pearson" (default) or "spearman"
#' @return List with components: gene_x, gene_y, method, estimate, p_value,
#'   n_samples, expr_x (numeric vector), expr_y (numeric vector)
#' @family gene-correlation
#' @export
correlate_genes <- function(expr_matrix,
                            gene_x,
                            gene_y,
                            method = c("pearson", "spearman")) {
  method <- match.arg(method)

  if (is.null(expr_matrix) || !is.matrix(expr_matrix)) {
    cli::cli_abort(c(
      "x" = "{.arg expr_matrix} must be a numeric matrix",
      "i" = "Use VST or log-transformed counts (genes x samples)"
    ))
  }

  if (!gene_x %in% rownames(expr_matrix)) {
    cli::cli_abort(c(
      "x" = "Gene {.val {gene_x}} not found in expression matrix",
      "i" = "Available genes: {length(rownames(expr_matrix))}"
    ))
  }
  if (!gene_y %in% rownames(expr_matrix)) {
    cli::cli_abort(c(
      "x" = "Gene {.val {gene_y}} not found in expression matrix",
      "i" = "Available genes: {length(rownames(expr_matrix))}"
    ))
  }

  x <- as.numeric(expr_matrix[gene_x, ])
  y <- as.numeric(expr_matrix[gene_y, ])

  valid <- !is.na(x) & !is.na(y)
  if (sum(valid) < 3) {
    return(list(
      gene_x = gene_x, gene_y = gene_y, method = method,
      estimate = NA_real_, p_value = NA_real_, n_samples = sum(valid),
      expr_x = x[valid], expr_y = y[valid]
    ))
  }

  ct <- stats::cor.test(x[valid], y[valid], method = method)

  list(
    gene_x = gene_x,
    gene_y = gene_y,
    method = method,
    estimate = unname(ct$estimate),
    p_value = ct$p.value,
    n_samples = sum(valid),
    expr_x = x[valid],
    expr_y = y[valid]
  )
}


#' Batch correlation: one gene vs many
#'
#' Correlates a target gene against a vector of candidate genes and returns
#' a summary data frame sorted by absolute correlation.
#'
#' @param expr_matrix Numeric matrix (genes x samples)
#' @param target_gene Gene name to correlate against
#' @param candidate_genes Character vector of gene names to test
#' @param method Correlation method: "pearson" or "spearman"
#' @return Data frame with columns: gene, estimate, p_value, padj, n_samples,
#'   method
#' @family gene-correlation
#' @export
correlate_genes_batch <- function(expr_matrix,
                                  target_gene,
                                  candidate_genes,
                                  method = c("pearson", "spearman")) {
  method <- match.arg(method)

  if (is.null(expr_matrix) || !is.matrix(expr_matrix)) {
    cli::cli_abort("{.arg expr_matrix} must be a numeric matrix")
  }
  if (!target_gene %in% rownames(expr_matrix)) {
    cli::cli_abort("Target gene {.val {target_gene}} not found in matrix")
  }

  # Filter to available candidates
  available <- intersect(candidate_genes, rownames(expr_matrix))
  if (length(available) == 0) {
    return(data.frame(
      gene = character(), estimate = numeric(), p_value = numeric(),
      padj = numeric(), n_samples = integer(), method = character(),
      stringsAsFactors = FALSE
    ))
  }

  results <- lapply(available, function(g) {
    res <- correlate_genes(expr_matrix, target_gene, g, method = method)
    data.frame(
      gene = g,
      estimate = res$estimate,
      p_value = res$p_value,
      n_samples = res$n_samples,
      method = method,
      stringsAsFactors = FALSE
    )
  })

  result <- do.call(rbind, results)
  result$padj <- stats::p.adjust(result$p_value, method = "BH")
  result <- result[order(-abs(result$estimate)), ]
  rownames(result) <- NULL

  result
}


#' Scatter plot of gene-gene correlation
#'
#' Creates a scatter plot with regression line, correlation coefficient,
#' and p-value annotation from a [correlate_genes()] result.
#'
#' @param cor_result List from [correlate_genes()]
#' @param title Plot title (default auto-generated)
#' @return A ggplot object
#' @family gene-correlation
#' @export
plot_gene_correlation <- function(cor_result, title = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg ggplot2} is required.")
  }

  if (is.null(cor_result) || length(cor_result$expr_x) < 3) {
    return(ggplot2::ggplot() +
             ggplot2::annotate("text", x = 0.5, y = 0.5,
                               label = "Insufficient data for correlation") +
             ggplot2::theme_void())
  }

  df <- data.frame(
    expr_x = cor_result$expr_x,
    expr_y = cor_result$expr_y
  )

  if (is.null(title)) {
    title <- paste0(cor_result$gene_x, " vs ", cor_result$gene_y)
  }

  r_label <- sprintf("R = %.3f", cor_result$estimate)
  p_label <- if (cor_result$p_value < 0.001) "p < 0.001" else
    sprintf("p = %.3f", cor_result$p_value)
  subtitle <- paste0(
    cor_result$method, ": ", r_label, ", ", p_label,
    " (n = ", cor_result$n_samples, ")"
  )

  ggplot2::ggplot(df, ggplot2::aes(x = expr_x, y = expr_y)) +
    ggplot2::geom_point(size = 1.5, alpha = 0.6, color = "#2166AC") +
    ggplot2::geom_smooth(method = "lm", se = TRUE, color = "#B2182B",
                         linewidth = 0.8, alpha = 0.2) +
    ggplot2::labs(
      title = title,
      subtitle = subtitle,
      x = paste0(cor_result$gene_x, " expression"),
      y = paste0(cor_result$gene_y, " expression")
    ) +
    ggplot2::theme_minimal(base_size = 12)
}
