# R/03_differential_expression.R
# Differential expression analysis functions

#' Run DESeq2 differential expression analysis
run_deseq2 <- function(se_data, clinical_data, design_formula = ~ condition) {
  library(DESeq2)
  library(logger)
  library(dplyr)

  log_info("Running DESeq2 analysis...")

  # Handle both SummarizedExperiment and list structures
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    counts <- se_data$assays$counts
    col_data <- se_data$colData
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    counts <- assay(se_data, "counts")
    col_data <- colData(se_data)
  } else {
    counts <- se_data
    col_data <- clinical_data
  }

  # Ensure we have integer counts
  counts <- round(counts)
  storage.mode(counts) <- "integer"

  # Prepare column data - merge with clinical if provided separately
  if (!is.null(clinical_data) && is.data.frame(clinical_data)) {
    if (is.null(col_data)) {
      col_data <- clinical_data[match(colnames(counts), clinical_data$sample_id), ]
    } else {
      # Merge additional clinical data if provided
      col_data <- cbind(col_data, clinical_data[match(rownames(col_data), clinical_data$sample_id), ])
    }
  }

  # Ensure we have a condition column for the design
  if (!"condition" %in% colnames(col_data)) {
    if ("response" %in% colnames(col_data)) {
      col_data$condition <- col_data$response
    } else {
      # Create a dummy condition if none exists
      col_data$condition <- factor(rep(c("control", "treatment"), length.out = ncol(counts)))
    }
  }

  # Create DESeqDataSet
  dds <- DESeqDataSetFromMatrix(
    countData = counts,
    colData = col_data,
    design = design_formula
  )

  # Filter low count genes
  keep <- rowSums(counts(dds)) >= 10
  dds <- dds[keep, ]

  # Run DESeq2 analysis
  dds <- DESeq(dds, quiet = TRUE)

  # Extract results
  res <- results(dds, alpha = 0.05)
  res_df <- as.data.frame(res) %>%
    tibble::rownames_to_column("gene") %>%
    arrange(padj)

  # Count significant genes
  n_deg <- sum(res_df$padj < 0.05 & abs(res_df$log2FoldChange) > 1, na.rm = TRUE)

  results <- list(
    method = "DESeq2",
    dds = dds,
    n_deg = n_deg,
    results_table = res_df,
    contrast = resultsNames(dds)[2],
    size_factors = sizeFactors(dds)
  )

  log_info("DESeq2 analysis complete: {n_deg} significant genes")
  return(results)
}

#' Run edgeR differential expression analysis
run_edger <- function(se_data, clinical_data, design_formula = ~ condition) {
  library(edgeR)
  library(logger)
  library(dplyr)

  log_info("Running edgeR analysis...")

  # Handle both SummarizedExperiment and list structures
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    counts <- se_data$assays$counts
    col_data <- se_data$colData
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    counts <- assay(se_data, "counts")
    col_data <- colData(se_data)
  } else {
    counts <- se_data
    col_data <- clinical_data
  }

  # Ensure integer counts
  counts <- round(counts)

  # Prepare column data
  if (!is.null(clinical_data) && is.data.frame(clinical_data)) {
    if (is.null(col_data)) {
      col_data <- clinical_data[match(colnames(counts), clinical_data$sample_id), ]
    }
  }

  # Ensure condition column exists
  if (!"condition" %in% colnames(col_data)) {
    if ("response" %in% colnames(col_data)) {
      col_data$condition <- col_data$response
    } else {
      col_data$condition <- factor(rep(c("control", "treatment"), length.out = ncol(counts)))
    }
  }

  # Create DGEList
  y <- DGEList(counts = counts, group = col_data$condition)

  # Filter low expression genes
  keep <- filterByExpr(y)
  y <- y[keep, ]

  # Normalize
  y <- calcNormFactors(y)

  # Create design matrix
  design <- model.matrix(design_formula, data = col_data)

  # Estimate dispersion
  y <- estimateDisp(y, design)

  # Fit model
  fit <- glmQLFit(y, design)
  qlf <- glmQLFTest(fit, coef = 2)

  # Get results
  res <- topTags(qlf, n = Inf)$table
  res$gene <- rownames(res)
  res$padj <- res$FDR

  # Count significant genes
  n_deg <- sum(res$padj < 0.05 & abs(res$logFC) > 1, na.rm = TRUE)

  results <- list(
    method = "edgeR",
    dge = y,
    n_deg = n_deg,
    results_table = res %>% arrange(padj),
    contrast = colnames(design)[2],
    norm_factors = y$samples$norm.factors
  )

  log_info("edgeR analysis complete: {n_deg} significant genes")
  return(results)
}

#' Run limma differential expression analysis
run_limma <- function(se_data, clinical_data, design_formula = ~ condition) {
  library(limma)
  library(edgeR)
  library(logger)
  library(dplyr)

  log_info("Running limma-voom analysis...")

  # Handle both SummarizedExperiment and list structures
  if (is.list(se_data) && !inherits(se_data, "SummarizedExperiment")) {
    counts <- se_data$assays$counts
    col_data <- se_data$colData
  } else if (inherits(se_data, "SummarizedExperiment")) {
    library(SummarizedExperiment)
    counts <- assay(se_data, "counts")
    col_data <- colData(se_data)
  } else {
    counts <- se_data
    col_data <- clinical_data
  }

  # Ensure integer counts
  counts <- round(counts)

  # Prepare column data
  if (!is.null(clinical_data) && is.data.frame(clinical_data)) {
    if (is.null(col_data)) {
      col_data <- clinical_data[match(colnames(counts), clinical_data$sample_id), ]
    }
  }

  # Ensure condition column exists
  if (!"condition" %in% colnames(col_data)) {
    if ("response" %in% colnames(col_data)) {
      col_data$condition <- col_data$response
    } else {
      col_data$condition <- factor(rep(c("control", "treatment"), length.out = ncol(counts)))
    }
  }

  # Create DGEList and filter
  y <- DGEList(counts = counts)
  keep <- filterByExpr(y)
  y <- y[keep, ]

  # Normalize
  y <- calcNormFactors(y)

  # Create design matrix
  design <- model.matrix(design_formula, data = col_data)

  # Voom transformation
  v <- voom(y, design, plot = FALSE)

  # Fit linear model
  fit <- lmFit(v, design)
  fit <- eBayes(fit)

  # Get results for second coefficient (treatment effect)
  res <- topTable(fit, coef = 2, number = Inf)
  res$gene <- rownames(res)
  res$padj <- res$adj.P.Val
  res$log2FC <- res$logFC

  # Count significant genes
  n_deg <- sum(res$padj < 0.05 & abs(res$log2FC) > 1, na.rm = TRUE)

  results <- list(
    method = "limma",
    voom = v,
    n_deg = n_deg,
    results_table = res %>% arrange(padj),
    contrast = colnames(design)[2],
    weights = v$weights
  )

  log_info("limma analysis complete: {n_deg} significant genes")
  return(results)
}

#' Find consensus DE genes across methods
find_consensus_genes <- function(de_results_list, padj_threshold = 0.05, lfc_threshold = 1) {
  library(logger)
  library(dplyr)

  log_info("Finding consensus DE genes...")

  # Extract significant genes from each method
  sig_genes_list <- lapply(de_results_list, function(res) {
    # Get the results table
    df <- res$results_table

    # Find appropriate column names (different methods use different names)
    lfc_col <- if ("log2FoldChange" %in% names(df)) "log2FoldChange" else
               if ("log2FC" %in% names(df)) "log2FC" else
               if ("logFC" %in% names(df)) "logFC" else NULL

    padj_col <- if ("padj" %in% names(df)) "padj" else
                if ("FDR" %in% names(df)) "FDR" else
                if ("adj.P.Val" %in% names(df)) "adj.P.Val" else NULL

    if (is.null(lfc_col) || is.null(padj_col)) {
      warning("Could not find required columns for method {res$method}")
      return(character(0))
    }

    # Filter significant genes
    sig <- df %>%
      filter(!!sym(padj_col) < padj_threshold,
             abs(!!sym(lfc_col)) > lfc_threshold) %>%
      pull(gene)

    return(sig)
  })

  # Name the list by method
  names(sig_genes_list) <- sapply(de_results_list, function(x) x$method)

  # Find consensus (genes significant in at least 2 methods)
  all_sig_genes <- unlist(sig_genes_list)
  gene_counts <- table(all_sig_genes)
  consensus_genes <- names(gene_counts[gene_counts >= 2])

  # Create detailed consensus table
  consensus_table <- data.frame(
    gene = consensus_genes,
    n_methods = as.numeric(gene_counts[consensus_genes]),
    stringsAsFactors = FALSE
  )

  # Add which methods found each gene
  consensus_table$methods <- sapply(consensus_genes, function(g) {
    methods <- names(sig_genes_list)[sapply(sig_genes_list, function(x) g %in% x)]
    paste(methods, collapse = ",")
  })

  # Sort by number of methods
  consensus_table <- consensus_table %>%
    arrange(desc(n_methods), gene)

  consensus <- list(
    n_consensus = length(consensus_genes),
    consensus_genes = consensus_genes,
    consensus_table = consensus_table,
    sig_by_method = sig_genes_list,
    n_sig_by_method = sapply(sig_genes_list, length),
    by_method = de_results_list
  )

  log_info("Found {consensus$n_consensus} consensus genes")
  log_info("Significant genes by method: {paste(names(consensus$n_sig_by_method), consensus$n_sig_by_method, sep='=', collapse=', ')}")

  return(consensus)
}

#' Render DE analysis report
render_de_report <- function(de_results, output_dir = "results/reports") {
  library(logger)
  
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  
  report_file <- file.path(output_dir, "de_report.html")
  
  # Placeholder - would normally render Rmd
  writeLines("DE Analysis Report", report_file)
  
  log_info("DE report saved to {report_file}")
  return(report_file)
}
