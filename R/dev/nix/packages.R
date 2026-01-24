# ============================================================================
# CoMMpass Multiple Myeloma Analysis Environment
# ============================================================================
# Comprehensive package list for MMRF CoMMpass analysis
# Generated from PLAN_CoMMpass_Analysis.md

# CRAN packages
cran_packages <- c(
  # Survival analysis
  "survival", "survminer", "survivalAnalysis", "timeROC", "pec",
  "riskRegression",

  # Single-cell (CRAN)
  "Seurat", "SeuratObject", "sctransform", "harmony", "clustree",

  # Data wrangling
  "tidyverse", "data.table", "dtplyr", "arrow", "janitor", "skimr",

  # Visualization
  "circlize", "ggrepel", "ggpubr", "patchwork", "viridis",
  "RColorBrewer", "pheatmap", "cowplot",

  # Reporting
  "knitr", "rmarkdown", "DT", "gt", "flextable",

  # Utilities
  "devtools", "remotes", "BiocManager", "here", "fs", "glue",
  "logger", "tictoc", "progressr", "future", "furrr",

  # AWS access
  "aws.s3", "aws.signature",

  # Pipeline management
  "targets", "tarchetypes", "crew", "mirai", "nanonext",

  # Development and version control
  "usethis", "gert", "gh", "testthat", "pkgdown", "styler",

  # Additional utilities
  "duckdb", "dbplyr", "httr2"
)

# Bioconductor packages
bioc_packages <- c(
  # Core infrastructure
  "SummarizedExperiment", "GenomicRanges", "Biostrings", "rtracklayer",
  "AnnotationDbi", "org.Hs.eg.db", "TxDb.Hsapiens.UCSC.hg38.knownGene",

  # Data access
  "TCGAbiolinks", "GenomicDataCommons",

  # Differential expression
  "DESeq2", "edgeR", "limma",

  # Single-cell
  "SingleCellExperiment", "scran", "scater", "DropletUtils",
  "SingleR", "celldex", "batchelor", "infercnv",

  # Pathway analysis
  "clusterProfiler", "enrichplot", "fgsea", "msigdbr",
  "DOSE", "ReactomePA", "ComplexHeatmap"
)

# GitHub packages
# Note: These will be installed from GitHub for latest features
# For reproducibility, specific commits should be used in production
git_packages <- list(
  list(
    package_name = "MMRFBiolinks",
    repo_url = "https://github.com/marziasettino/MMRFBiolinks",
    commit = "HEAD"  # Consider pinning to specific commit
  ),
  list(
    package_name = "copykat",
    repo_url = "https://github.com/navinlabcode/copykat",
    commit = "HEAD"
  )
  # Note: monocle3 and SCENIC have complex dependencies
  # They may need special handling or installation post-environment setup
)

# System dependencies (for Nix)
system_packages <- c(
  "jags",           # Required for infercnv
  "hdf5",           # Required for single-cell data
  "gsl",            # Required for some Bioc packages
  "libxml2",        # Required for XML parsing
  "curl",           # Required for data downloads
  "openssl",        # Required for secure connections
  "glpk",           # Required for optimization
  "zlib",           # Required for compression
  "cairo",          # Required for graphics
  "pandoc"          # Required for document generation
)

# Helper function to generate Nix environment
generate_nix_env <- function(
    project_path = here::here(),
    r_version = "4.4.1",
    ide = "none",
    include_git_pkgs = FALSE  # Git packages can be complex in Nix
) {
  require(rix)

  # Combine packages
  all_r_pkgs <- unique(c(cran_packages, bioc_packages))

  # Include git packages if requested
  git_pkgs_to_use <- if (include_git_pkgs) git_packages else list()

  # Generate Nix configuration
  rix::rix(
    r_ver = r_version,
    r_pkgs = all_r_pkgs,
    system_pkgs = system_packages,
    git_pkgs = git_pkgs_to_use,
    ide = ide,
    project_path = project_path,
    overwrite = TRUE
  )

  message("Nix environment configuration generated successfully.")
  message("Total R packages: ", length(all_r_pkgs))
  message("System packages: ", length(system_packages))
  if (include_git_pkgs) {
    message("GitHub packages: ", length(git_packages))
  }
}

# Export package lists for documentation
export_package_lists <- function(output_dir = "R/dev/nix") {
  # Create summary file
  summary_file <- file.path(output_dir, "package_summary.md")

  summary_lines <- c(
    "# CoMMpass Analysis Package Summary",
    "",
    paste0("Generated: ", Sys.Date()),
    "",
    "## Package Counts",
    paste0("- CRAN packages: ", length(cran_packages)),
    paste0("- Bioconductor packages: ", length(bioc_packages)),
    paste0("- GitHub packages: ", length(git_packages)),
    paste0("- System dependencies: ", length(system_packages)),
    paste0("- **Total R packages: ", length(unique(c(cran_packages, bioc_packages))), "**"),
    "",
    "## Package Categories",
    "- Data Access: TCGAbiolinks, GenomicDataCommons, aws.s3",
    "- Bulk RNA-seq: DESeq2, edgeR, limma",
    "- Single-cell: Seurat, SingleR, inferCNV",
    "- Survival: survival, survminer, coxph",
    "- Pathway: clusterProfiler, fgsea, ReactomePA",
    "- Pipeline: targets, crew, mirai"
  )

  writeLines(summary_lines, summary_file)
  message("Package summary written to: ", summary_file)
}