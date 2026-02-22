# R/05_pathway_analysis.R
# Pathway and enrichment analysis functions using fgsea and msigdbr

#' Build ranked gene vector from DE results
#'
#' Extracts a named numeric vector of gene ranks suitable for fgsea.
#' Uses the DESeq2 Wald statistic if available, otherwise computes
#' \code{-log10(pvalue) * sign(log2FoldChange)}.
#'
#' @param de_table Data frame of DE results with gene identifiers as rownames
#'   (or in a 'gene'/'gene_id' column) and test statistics.
#' @param gene_id_type Gene ID type in the DE results: \code{"ensembl_gene"},
#'   \code{"gene_symbol"}, or \code{"entrez_gene"}.
#' @return Named numeric vector (names = gene IDs, values = ranking statistic),
#'   sorted in decreasing order.
#' @keywords internal
build_gene_ranks <- function(de_table, gene_id_type = "ensembl_gene") {
  if (is.null(de_table) || !is.data.frame(de_table) || nrow(de_table) == 0) {
    return(numeric(0))
  }

  # Get gene names
  genes <- rownames(de_table)
  if (is.null(genes) || all(is.na(genes))) {
    gene_col <- intersect(c("gene", "gene_id", "Gene"), names(de_table))
    if (length(gene_col) > 0) {
      genes <- de_table[[gene_col[1]]]
    }
  }
  if (is.null(genes)) return(numeric(0))

  # Strip ENSEMBL version suffix (e.g. ENSG00000141510.17 -> ENSG00000141510)
  if (gene_id_type == "ensembl_gene") {
    genes <- sub("\\.\\d+$", "", genes)
  }

  # Determine ranking statistic
  if ("stat" %in% names(de_table)) {
    # DESeq2 Wald statistic (preferred)
    ranks <- as.numeric(de_table$stat)
  } else {
    # Compute from p-value and fold change
    lfc_col <- intersect(c("log2FoldChange", "logFC"), names(de_table))
    pval_col <- intersect(c("pvalue", "PValue", "P.Value"), names(de_table))
    if (length(lfc_col) == 0 || length(pval_col) == 0) {
      cli::cli_abort(c(
        "x" = "Cannot build gene ranks: need 'stat' or (log2FC + pvalue) columns",
        "i" = "Available columns: {paste(names(de_table), collapse = ', ')}"
      ))
    }
    lfc <- as.numeric(de_table[[lfc_col[1]]])
    pval <- as.numeric(de_table[[pval_col[1]]])
    # Clamp p-values away from 0 to avoid Inf
    pval[pval == 0] <- .Machine$double.xmin
    ranks <- -log10(pval) * sign(lfc)
  }

  # Remove NA genes and ranks
  valid <- !is.na(genes) & nchar(genes) > 0 & !is.na(ranks)
  ranks <- ranks[valid]
  names(ranks) <- genes[valid]

  # Remove duplicates (keep the one with largest absolute rank)
  if (any(duplicated(names(ranks)))) {
    dup_genes <- unique(names(ranks)[duplicated(names(ranks))])
    keep <- !names(ranks) %in% dup_genes
    for (g in dup_genes) {
      idx <- which(names(ranks) == g)
      keep[idx[which.max(abs(ranks[idx]))]] <- TRUE
    }
    ranks <- ranks[keep]
  }

  sort(ranks, decreasing = TRUE)
}

#' Get gene set collections from MSigDB
#'
#' Retrieves gene sets from the Molecular Signatures Database (MSigDB) via
#' the msigdbr package. Returns a named list suitable for fgsea.
#'
#' @param collection Character string specifying the collection:
#'   \code{"hallmark"}, \code{"kegg"}, \code{"reactome"}, \code{"go_bp"},
#'   \code{"go_mf"}, \code{"go_cc"}, \code{"c2"} (all curated),
#'   or \code{"c7"} (immunologic).
#' @param gene_id_type Gene ID column to use: \code{"ensembl_gene"},
#'   \code{"gene_symbol"}, or \code{"entrez_gene"}.
#' @param organism Species name (default: \code{"Homo sapiens"}).
#' @return Named list of character vectors (pathway name -> gene IDs).
#' @keywords internal
get_msigdb_gene_sets <- function(collection = "hallmark",
                                  gene_id_type = "ensembl_gene",
                                  organism = "Homo sapiens") {
  if (!requireNamespace("msigdbr", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg msigdbr} required but not installed")
  }

  # Map collection shorthand to msigdbr parameters
  collection_map <- list(
    hallmark = list(category = "H", subcategory = NULL),
    kegg     = list(category = "C2", subcategory = "CP:KEGG_MEDICUS"),
    reactome = list(category = "C2", subcategory = "CP:REACTOME"),
    go_bp    = list(category = "C5", subcategory = "GO:BP"),
    go_mf    = list(category = "C5", subcategory = "GO:MF"),
    go_cc    = list(category = "C5", subcategory = "GO:CC"),
    c2       = list(category = "C2", subcategory = NULL),
    c7       = list(category = "C7", subcategory = NULL)
  )

  if (!collection %in% names(collection_map)) {
    cli::cli_abort(c(
      "x" = "Unknown gene set collection: {collection}",
      "i" = "Valid options: {paste(names(collection_map), collapse = ', ')}"
    ))
  }

  params <- collection_map[[collection]]

  # Fetch gene sets
  args <- list(species = organism, category = params$category)
  if (!is.null(params$subcategory)) {
    args$subcategory <- params$subcategory
  }
  msigdb_df <- do.call(msigdbr::msigdbr, args)

  # Map gene ID type to msigdbr column
  id_col_map <- c(
    ensembl_gene = "ensembl_gene",
    gene_symbol  = "gene_symbol",
    entrez_gene  = "entrez_gene"
  )
  id_col <- id_col_map[gene_id_type]
  if (is.na(id_col) || !id_col %in% names(msigdb_df)) {
    cli::cli_abort("Gene ID type '{gene_id_type}' not found in msigdbr output")
  }

  # Convert to named list
  gene_sets <- split(msigdb_df[[id_col]], msigdb_df$gs_name)
  # Remove NAs and empty strings from each set
  gene_sets <- lapply(gene_sets, function(x) {
    x <- x[!is.na(x) & nchar(x) > 0]
    unique(x)
  })
  # Remove empty sets
  gene_sets <- gene_sets[vapply(gene_sets, length, integer(1)) > 0]

  logger::log_info(
    "Loaded {length(gene_sets)} {collection} gene sets from MSigDB ",
    "(organism: {organism}, IDs: {gene_id_type})"
  )

  gene_sets
}

#' Run Gene Set Enrichment Analysis (GSEA)
#'
#' Performs pre-ranked GSEA using fgsea on differential expression results.
#' Genes are ranked by their test statistic (DESeq2 Wald stat or
#' \code{-log10(pvalue) * sign(log2FC)}). Gene sets come from MSigDB via
#' msigdbr.
#'
#' @param de_results Data frame of DE results. Must contain gene identifiers
#'   (as rownames or in a \code{gene}/\code{gene_id} column) and at least one
#'   of: \code{stat} (DESeq2 Wald statistic), or
#'   \code{log2FoldChange}/\code{logFC} + \code{pvalue}/\code{PValue}.
#' @param gene_sets Character string specifying the MSigDB collection:
#'   \code{"hallmark"} (default), \code{"kegg"}, \code{"reactome"},
#'   \code{"go_bp"}, \code{"go_mf"}, \code{"go_cc"}, \code{"c2"}, \code{"c7"}.
#'   Alternatively, a named list of character vectors (custom gene sets).
#' @param gene_id_type Type of gene identifiers: \code{"ensembl_gene"}
#'   (default), \code{"gene_symbol"}, or \code{"entrez_gene"}.
#' @param min_size Minimum gene set size (default: 15).
#' @param max_size Maximum gene set size (default: 500).
#' @return List with components:
#'   \describe{
#'     \item{results}{Data frame with pathway, NES, pval, padj, size,
#'       leadingEdge columns.}
#'     \item{n_gene_sets}{Number of gene sets tested.}
#'     \item{n_significant}{Number significant at padj < 0.05.}
#'     \item{top_gene_sets}{Top 20 enriched gene sets as a data frame.}
#'     \item{ranked_genes}{Named numeric vector of gene ranks used.}
#'     \item{collection}{Gene set collection used.}
#'   }
#' @export
run_gsea <- function(de_results,
                     gene_sets = "hallmark",
                     gene_id_type = "ensembl_gene",
                     min_size = 15L,
                     max_size = 500L) {
  # Handle NULL/empty input gracefully (before requiring fgsea)
  if (is.null(de_results) || !is.data.frame(de_results) || nrow(de_results) == 0) {
    logger::log_warn("No DE results provided, returning empty GSEA results")
    return(list(
      n_gene_sets = 0L,
      n_significant = 0L,
      top_gene_sets = data.frame(
        pathway = character(0), NES = numeric(0),
        pval = numeric(0), padj = numeric(0),
        size = integer(0), stringsAsFactors = FALSE
      ),
      results = data.frame(),
      ranked_genes = numeric(0),
      collection = if (is.character(gene_sets)) gene_sets else "custom"
    ))
  }

  if (!requireNamespace("fgsea", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg fgsea} required but not installed")
  }

  # Build ranked gene vector
  ranked <- build_gene_ranks(de_results, gene_id_type)
  if (length(ranked) < 100) {
    cli::cli_abort(c(
      "x" = "Only {length(ranked)} genes with valid ranks",
      "i" = "Need >= 100 ranked genes for meaningful GSEA"
    ))
  }

  # Get gene set pathways
  if (is.character(gene_sets) && length(gene_sets) == 1) {
    pathways <- get_msigdb_gene_sets(gene_sets, gene_id_type)
    collection_name <- gene_sets
  } else if (is.list(gene_sets)) {
    pathways <- gene_sets
    collection_name <- "custom"
  } else {
    cli::cli_abort("gene_sets must be a collection name or named list")
  }

  logger::log_info(
    "Running fgsea: {length(ranked)} ranked genes, ",
    "{length(pathways)} gene sets ({collection_name})"
  )

  # Run fgsea
  gsea_res <- fgsea::fgsea(
    pathways = pathways,
    stats = ranked,
    minSize = min_size,
    maxSize = max_size
  )

  # Convert to data frame and sort by padj
  gsea_df <- as.data.frame(gsea_res)
  gsea_df <- gsea_df[order(gsea_df$padj), ]

  # Build top_gene_sets summary
  n_sig <- sum(gsea_df$padj < 0.05, na.rm = TRUE)
  top_n <- min(20L, nrow(gsea_df))
  top_df <- data.frame(
    pathway = gsea_df$pathway[seq_len(top_n)],
    NES = round(gsea_df$NES[seq_len(top_n)], 3),
    pval = signif(gsea_df$pval[seq_len(top_n)], 3),
    padj = signif(gsea_df$padj[seq_len(top_n)], 3),
    size = gsea_df$size[seq_len(top_n)],
    stringsAsFactors = FALSE,
    row.names = NULL
  )

  logger::log_info(
    "GSEA complete: {n_sig} significant pathways (padj < 0.05) ",
    "of {nrow(gsea_df)} tested"
  )

  list(
    results = gsea_df,
    n_gene_sets = nrow(gsea_df),
    n_significant = n_sig,
    top_gene_sets = top_df,
    ranked_genes = ranked,
    collection = collection_name
  )
}

#' Run Over-Representation Analysis (ORA)
#'
#' Tests whether a set of significant genes is over-represented in gene set
#' collections using Fisher's exact test (hypergeometric distribution).
#' Gene sets come from MSigDB via msigdbr.
#'
#' @param sig_genes Character vector of significant gene identifiers.
#' @param universe Character vector of all tested gene identifiers (background).
#' @param gene_sets Character string specifying the MSigDB collection
#'   (same options as [run_gsea()]), or a named list of character vectors.
#' @param gene_id_type Type of gene identifiers: \code{"ensembl_gene"}
#'   (default), \code{"gene_symbol"}, or \code{"entrez_gene"}.
#' @param min_size Minimum gene set size (default: 10).
#' @param max_size Maximum gene set size (default: 500).
#' @return List with components:
#'   \describe{
#'     \item{results}{Data frame with pathway, overlap, gene_set_size,
#'       universe_size, p_value, padj, odds_ratio, overlapping_genes.}
#'     \item{n_pathways_tested}{Number of pathways tested.}
#'     \item{n_pathways_enriched}{Number significant at padj < 0.05.}
#'     \item{n_sig_genes}{Number of input significant genes.}
#'     \item{top_pathways}{Top 20 enriched pathways as a data frame.}
#'   }
#' @export
run_ora <- function(sig_genes,
                    universe,
                    gene_sets = "hallmark",
                    gene_id_type = "ensembl_gene",
                    min_size = 10L,
                    max_size = 500L) {
  if (is.null(sig_genes) || length(sig_genes) == 0) {
    cli::cli_abort(c(
      "x" = "No significant genes provided for ORA",
      "i" = "Check DE results for significant genes"
    ))
  }

  # Strip ENSEMBL version suffixes
  if (gene_id_type == "ensembl_gene") {
    sig_genes <- sub("\\.\\d+$", "", sig_genes)
    universe <- sub("\\.\\d+$", "", universe)
  }

  sig_genes <- unique(sig_genes)
  universe <- unique(universe)
  # Ensure sig_genes is a subset of universe
  sig_genes <- intersect(sig_genes, universe)

  if (length(sig_genes) < 5) {
    cli::cli_abort(c(
      "x" = "Only {length(sig_genes)} significant genes found in universe",
      "i" = "Need >= 5 genes for meaningful ORA"
    ))
  }

  # Get gene set pathways
  if (is.character(gene_sets) && length(gene_sets) == 1) {
    pathways <- get_msigdb_gene_sets(gene_sets, gene_id_type)
    collection_name <- gene_sets
  } else if (is.list(gene_sets)) {
    pathways <- gene_sets
    collection_name <- "custom"
  } else {
    cli::cli_abort("gene_sets must be a collection name or named list")
  }

  # Filter pathways by size and restrict to universe
  pathways <- lapply(pathways, function(gs) intersect(gs, universe))
  sizes <- vapply(pathways, length, integer(1))
  pathways <- pathways[sizes >= min_size & sizes <= max_size]

  logger::log_info(
    "Running ORA: {length(sig_genes)} DE genes, ",
    "{length(universe)} universe, {length(pathways)} gene sets ({collection_name})"
  )

  N <- length(universe)          # total genes
  K <- length(sig_genes)          # significant genes

  # Fisher's exact test for each pathway
  ora_list <- lapply(names(pathways), function(pw) {
    gs <- pathways[[pw]]
    n_gs <- length(gs)                           # genes in gene set
    overlap <- intersect(sig_genes, gs)
    k <- length(overlap)                          # overlap

    # 2x2 contingency table:
    #            In set  Not in set
    # DE           k     K - k
    # Not DE    n_gs-k   N - K - n_gs + k
    pval <- stats::phyper(
      k - 1, n_gs, N - n_gs, K,
      lower.tail = FALSE
    )

    odds <- if (k > 0 && (K - k) > 0 && (n_gs - k) > 0) {
      (k * (N - K - n_gs + k)) / ((K - k) * (n_gs - k))
    } else {
      NA_real_
    }

    data.frame(
      pathway = pw,
      overlap = k,
      gene_set_size = n_gs,
      p_value = pval,
      odds_ratio = round(odds, 3),
      overlapping_genes = paste(overlap, collapse = ";"),
      stringsAsFactors = FALSE
    )
  })

  ora_df <- do.call(rbind, ora_list)
  ora_df$universe_size <- N
  ora_df$padj <- stats::p.adjust(ora_df$p_value, method = "BH")

  # Sort by padj
  ora_df <- ora_df[order(ora_df$padj), ]
  rownames(ora_df) <- NULL

  n_enriched <- sum(ora_df$padj < 0.05, na.rm = TRUE)
  top_n <- min(20L, nrow(ora_df))
  top_df <- ora_df[seq_len(top_n), c("pathway", "overlap", "gene_set_size",
                                      "p_value", "padj", "odds_ratio")]
  top_df$p_value <- signif(top_df$p_value, 3)
  top_df$padj <- signif(top_df$padj, 3)
  rownames(top_df) <- NULL

  logger::log_info(
    "ORA complete: {n_enriched} enriched pathways (padj < 0.05) ",
    "of {nrow(ora_df)} tested"
  )

  list(
    results = ora_df,
    n_pathways_tested = nrow(ora_df),
    n_pathways_enriched = n_enriched,
    n_sig_genes = length(sig_genes),
    top_pathways = top_df,
    collection = collection_name
  )
}

#' Run pathway enrichment analysis
#'
#' Wrapper that runs ORA on consensus DE genes. Uses MSigDB Hallmark gene
#' sets by default.
#'
#' @param de_genes Consensus DE result from [find_consensus_genes()] with
#'   \code{consensus_genes} character vector and \code{by_method} list.
#' @param method Gene set collection: \code{"hallmark"} (default),
#'   \code{"kegg"}, \code{"reactome"}, \code{"go_bp"}.
#' @return List with ORA results (see [run_ora()]).
#' @export
run_pathway_analysis <- function(de_genes, method = "hallmark") {
  logger::log_info("Running pathway analysis using {method} gene sets...")

  # Extract consensus genes and universe from DE results
  sig <- de_genes$consensus_genes
  if (is.null(sig) || length(sig) == 0) {
    logger::log_warn("No consensus DE genes, skipping pathway analysis")
    return(list(
      n_pathways_enriched = 0L,
      n_pathways_tested = 0L,
      top_pathways = data.frame(
        pathway = character(0), overlap = integer(0),
        gene_set_size = integer(0), p_value = numeric(0),
        padj = numeric(0), odds_ratio = numeric(0),
        stringsAsFactors = FALSE
      ),
      results = data.frame(),
      method = method
    ))
  }

  if (!requireNamespace("msigdbr", quietly = TRUE)) {
    cli::cli_abort("Package {.pkg msigdbr} required but not installed")
  }

  # Get universe from first available DE method
  universe <- character(0)
  if (!is.null(de_genes$by_method)) {
    for (res in de_genes$by_method) {
      if (!is.null(res$results_table) && nrow(res$results_table) > 0) {
        universe <- rownames(res$results_table)
        if (is.null(universe)) {
          gene_col <- intersect(c("gene", "gene_id"), names(res$results_table))
          if (length(gene_col) > 0) universe <- res$results_table[[gene_col[1]]]
        }
        break
      }
    }
  }

  if (length(universe) == 0) {
    logger::log_warn("No gene universe available from DE results")
    universe <- sig  # fallback: use sig genes as universe (not ideal)
  }

  result <- run_ora(
    sig_genes = sig,
    universe = universe,
    gene_sets = method,
    gene_id_type = "ensembl_gene"
  )

  result$method <- method
  logger::log_info("Found {result$n_pathways_enriched} enriched pathways")
  result
}

#' Generate summary report
#'
#' @param qc_metrics QC metrics data frame
#' @param de_genes DE results with consensus gene information
#' @param survival Survival analysis results
#' @param pathways Pathway analysis results
#' @param output_dir Directory for output report
#' @return Path to generated report
generate_summary_report <- function(qc_metrics, de_genes, survival, pathways,
                                   output_dir = "results/reports") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  report_file <- file.path(output_dir, "summary_report.html")

  n_samples <- if (is.data.frame(qc_metrics)) nrow(qc_metrics) else 0
  n_de <- if (is.list(de_genes)) de_genes$n_consensus else 0
  n_pathways <- if (is.list(pathways) && !is.null(pathways$n_pathways_enriched)) {
    pathways$n_pathways_enriched
  } else {
    0L
  }

  summary_text <- paste(
    "CoMMpass Analysis Summary",
    "========================",
    paste("Samples analyzed:", n_samples),
    paste("DE genes found:", n_de),
    paste("Enriched pathways:", n_pathways),
    sep = "\n"
  )

  writeLines(summary_text, report_file)

  logger::log_info("Summary report saved to {report_file}")
  report_file
}
