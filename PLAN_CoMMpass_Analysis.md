# CoMMpass Multiple Myeloma Analysis Plan

## Overview

This document outlines a reproducible analysis plan for the [MMRF CoMMpass](https://themmrf.org/finding-a-cure/personalized-treatment-approaches/) (Clinical Outcomes in MM to Personal Assessment of Genetic Profile) study data. The CoMMpass study is a landmark longitudinal genomic-clinical study of **1,143 newly diagnosed multiple myeloma patients** collected between 2011-2016 with 8-year follow-up.

## Data Access for Non-Medical/Individual Researchers

### Can Non-Medical Users Access CoMMpass Data?

**Yes, with some caveats.** The data has multiple access tiers:

| Access Level | Data Type | Requirements | Best For |
|--------------|-----------|--------------|----------|
| **Open Access** | Aggregated counts, clinical summaries | None | Learning, exploratory |
| **AWS Open Data** | RNA-seq gene expression | None (AWS CLI) | Developers, bulk analysis |
| **MMRF Researcher Gateway** | Clinical + genomic | Free registration | All researchers |
| **dbGaP Controlled** | Raw sequences, PHI | Institutional affiliation, IRB | Academic research |

### Practical Access Options for Individual Developers

#### Option 1: AWS Open Data (Easiest - No Account Required)

```bash
# List available files (no AWS account needed)
aws s3 ls --no-sign-request s3://gdc-mmrf-commpass-phs000748-2-open/

# Download RNA-seq data directly
aws s3 cp --no-sign-request \
  s3://gdc-mmrf-commpass-phs000748-2-open/path/to/file.tsv \
  ./data/
```

- **Bucket**: `s3://gdc-mmrf-commpass-phs000748-2-open`
- **Region**: us-east-1
- **Contents**: RNA-seq gene expression quantification
- **License**: [NIH Genomic Data Sharing Policy](https://gdc.cancer.gov/access-data/data-access-policies)

#### Option 2: MMRF Researcher Gateway (Free Registration)

1. Register at [research.themmrf.org](https://research.themmrf.org)
2. Email rogersj@themmrf.org to request access
3. Download tab-delimited clinical/genomic datasets
4. **Publication requirement**: Acknowledge MMRF, 30-day notice before publication

#### Option 3: dbGaP Controlled Access (Academic Only)

Required for raw sequences (FASTQ, BAM) and individual-level protected data:

- Study accession: `phs000748`
- Requires: NIH eRA Commons account, institutional affiliation
- Security: NIST SP 800-171 compliant systems
- **Not suitable for individual/hobby projects**

---

## Primary Data Portals

| Portal | Description | Access Type |
|--------|-------------|-------------|
| [NCI GDC Data Portal](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS) | Source of truth; monthly releases | Controlled/Open |
| [MMRF Researcher Gateway](https://research.themmrf.org/) | Clinical annotations, curated datasets | Registration required |
| [AWS Open Data Registry](https://registry.opendata.aws/mmrf-commpass/) | Cloud-based access | **Open (no account)** |

### Available Data Types

| Data Type | Description | Samples |
|-----------|-------------|---------|
| **WGS** | Whole Genome Sequencing | ~1,100 patients |
| **WES** | Whole Exome Sequencing | ~1,100 patients |
| **RNA-seq** | Bulk transcriptomics | ~1,100 patients |
| **scRNA-seq** | Single-cell (Mount Sinai atlas) | 335 patients, ~1.5M cells |
| **Clinical** | Demographics, treatments, outcomes | All patients |

### Key Findings Already Established

- **12 expression subtypes** of multiple myeloma identified via RNA-seq clustering
- **Immune cell atlas** revealing immunosenescence in rapid relapse patients
- **Actionable DNA alterations** mapped to expression subtypes

---

## R Package Options for Data Access

### MMRFBiolinks Status (⚠️ Maintenance Concern)

The [MMRFBiolinks](https://github.com/marziasettino/MMRFBiolinks) package:
- **Last active development**: ~2021
- **Issues**: 7 open issues, no recent responses
- **CI/CD**: Uses deprecated Travis CI
- **Status**: Functional but unmaintained

**Recommendation**: Use as reference but prefer alternatives for new projects.

### Recommended Alternatives

| Package | Maintenance | MMRF Support | Best For |
|---------|-------------|--------------|----------|
| **TCGAbiolinks** | ✅ Active (Bioconductor) | ✅ `project="MMRF-COMMPASS"` | GDC data download |
| **GenomicDataCommons** | ✅ Active (Bioconductor) | ✅ Direct API access | Programmatic queries |
| **aws.s3** | ✅ Active (CRAN) | ✅ S3 bucket access | Bulk downloads |
| **httr2 + GDC API** | ✅ Active (CRAN) | ✅ REST API | Custom workflows |

### Modern Data Access Approach (Recommended)

```r
# Option A: TCGAbiolinks (actively maintained)
library(TCGAbiolinks)

query <- GDCquery(
  project = "MMRF-COMMPASS",
  data.category = "Transcriptome Profiling",
  data.type = "Gene Expression Quantification",
  workflow.type = "STAR - Counts"
)
GDCdownload(query)
data <- GDCprepare(query)

# Option B: GenomicDataCommons (lower-level, more control)
library(GenomicDataCommons)

# List available projects
projects() |>
  filter(project_id == "MMRF-COMMPASS") |>
  results()

# Query files
files() |>
  filter(cases.project.project_id == "MMRF-COMMPASS") |>
  filter(data_type == "Gene Expression Quantification") |>
  results()

# Option C: Direct AWS S3 (fastest for bulk downloads)
library(aws.s3)

# List bucket contents
bucket_contents <- get_bucket_df(
  bucket = "gdc-mmrf-commpass-phs000748-2-open",
  region = "us-east-1",
  use_https = TRUE
)

# Download specific file
save_object(
  object = "path/to/file.tsv",
  bucket = "gdc-mmrf-commpass-phs000748-2-open",
  file = "local_data.tsv",
  region = "us-east-1"
)
```

### Clinical Data Access (Without MMRFBiolinks)

For clinical data, use direct GDC API or MMRF Researcher Gateway downloads:

```r
library(TCGAbiolinks)

# Get clinical data directly from GDC
clinical <- GDCquery_clinic(project = "MMRF-COMMPASS", type = "clinical")

# Or download as biospecimen
biospec <- GDCquery_clinic(project = "MMRF-COMMPASS", type = "biospecimen")
```

---

## Analysis Workflow Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DATA ACQUISITION                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │ GDC Portal  │    │ MMRF-RG     │    │ AWS S3      │                 │
│  │ (genomics)  │    │ (clinical)  │    │ (bulk)      │                 │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                 │
│         │                  │                  │                         │
│         └──────────────────┼──────────────────┘                         │
│                            ▼                                            │
│              ┌─────────────────────────┐                               │
│              │    MMRFBiolinks /       │                               │
│              │    TCGAbiolinks         │                               │
│              └────────────┬────────────┘                               │
└───────────────────────────┼─────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                        BULK RNA-seq ANALYSIS                            │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │ DESeq2      │    │ edgeR       │    │ limma-voom  │                 │
│  │ (DE genes)  │    │ (TMM norm)  │    │ (robust)    │                 │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                 │
│         └──────────────────┼──────────────────┘                         │
│                            ▼                                            │
│              ┌─────────────────────────┐                               │
│              │   Consensus DE genes    │                               │
│              └────────────┬────────────┘                               │
└───────────────────────────┼─────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      SINGLE-CELL ANALYSIS                               │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │ Seurat      │    │ inferCNV/   │    │ Monocle     │                 │
│  │ (QC/cluster)│    │ CopyKat     │    │ (trajectory)│                 │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                 │
│         └──────────────────┼──────────────────┘                         │
│                            ▼                                            │
│              ┌─────────────────────────┐                               │
│              │   Cell type annotation  │                               │
│              │   (SingleR/CellTypist)  │                               │
│              └────────────┬────────────┘                               │
└───────────────────────────┼─────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      SURVIVAL ANALYSIS                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │ survival    │    │ survminer   │    │ coxph       │                 │
│  │ (Surv obj)  │    │ (KM plots)  │    │ (Cox reg)   │                 │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                 │
│         └──────────────────┼──────────────────┘                         │
│                            ▼                                            │
│              ┌─────────────────────────┐                               │
│              │  Prognostic signatures  │                               │
│              └────────────┬────────────┘                               │
└───────────────────────────┼─────────────────────────────────────────────┘
                            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    PATHWAY & INTEGRATION                                │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                 │
│  │clusterProf. │    │ GSEA        │    │ ComplexHeat │                 │
│  │ (enrichment)│    │ (gene sets) │    │ (heatmaps)  │                 │
│  └─────────────┘    └─────────────┘    └─────────────┘                 │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## R Package Requirements for rix

### Core Data Access & Infrastructure

```r
# Data access packages
pkgs_data_access <- c(
  "TCGAbiolinks",        # GDC data access (Bioconductor)
  "GenomicDataCommons",  # Direct GDC API access (Bioconductor)
  "aws.s3"               # AWS S3 access for CoMMpass
)

# GitHub packages (install via rix git_pkgs)
git_pkgs_data_access <- list(
  list(
    package_name = "MMRFBiolinks",
    repo_url = "https://github.com/marziasettino/MMRFBiolinks",
    commit = "HEAD"  # Pin to specific commit for reproducibility
  )
)
```

### Bioconductor Packages

```r
# Core Bioconductor infrastructure
pkgs_bioc_core <- c(
  "SummarizedExperiment",   # Data container for genomics
  "GenomicRanges",          # Genomic intervals
  "Biostrings",             # Biological sequences
  "rtracklayer",            # Import/export genome tracks
  "AnnotationDbi",          # Annotation databases
  "org.Hs.eg.db",           # Human gene annotations
  "TxDb.Hsapiens.UCSC.hg38.knownGene"  # Transcript annotations
)

# Differential expression
pkgs_bioc_de <- c(
  "DESeq2",                 # DE analysis (negative binomial)
  "edgeR",                  # DE analysis (negative binomial + TMM)
  "limma"                   # DE analysis (linear models + voom)
)

# Single-cell analysis
pkgs_bioc_sc <- c(
  "SingleCellExperiment",   # scRNA-seq data container
  "scran",                  # scRNA-seq normalization
  "scater",                 # scRNA-seq QC & visualization
  "DropletUtils",           # 10X data processing
  "SingleR",                # Automated cell type annotation
  "celldex",                # Reference datasets for SingleR
  "batchelor",              # Batch correction
  "infercnv"                # CNV inference from scRNA-seq
)

# Pathway analysis
pkgs_bioc_pathway <- c(
  "clusterProfiler",        # GO/KEGG enrichment
  "enrichplot",             # Enrichment visualization
  "fgsea",                  # Fast GSEA
  "msigdbr",                # MSigDB gene sets
  "DOSE",                   # Disease Ontology
  "ReactomePA"              # Reactome pathways
)
```

### CRAN Packages

```r
# Survival analysis
pkgs_survival <- c(
  "survival",               # Core survival analysis
  "survminer",              # KM plot visualization
  "survivalAnalysis",       # High-level survival interface
  "timeROC",                # Time-dependent ROC
  "pec",                    # Prediction error curves
  "riskRegression"          # Risk prediction
)

# Single-cell (CRAN)
pkgs_sc_cran <- c(
  "Seurat",                 # Primary scRNA-seq toolkit
  "SeuratObject",           # Seurat data structures
  "sctransform",            # Variance stabilization
  "harmony",                # Batch correction
  "clustree",               # Clustering tree visualization
  "monocle3"                # Trajectory analysis (via GitHub)
)

# Data wrangling & visualization
pkgs_tidyverse <- c(
  "tidyverse",              # Core tidyverse

  "data.table",             # Fast data manipulation
  "dtplyr",                 # data.table backend for dplyr
  "arrow",                  # Parquet/Arrow support
  "janitor",                # Data cleaning
  "skimr"                   # Data summaries
)

# Visualization
pkgs_viz <- c(
  "ComplexHeatmap",         # Advanced heatmaps (Bioconductor)
  "circlize",               # Circular plots
  "ggrepel",                # Label repulsion
  "ggpubr",                 # Publication-ready plots
  "patchwork",              # Plot composition
  "viridis",                # Color scales
  "RColorBrewer",           # Color palettes
  "pheatmap",               # Heatmaps
  "cowplot"                 # Plot arrangement
)

# Reporting
pkgs_reporting <- c(
  "knitr",                  # Literate programming
  "rmarkdown",              # R Markdown
  "DT",                     # Interactive tables
  "gt",                     # Publication tables
  "flextable"               # Flexible tables
)
```

### GitHub Packages (via rix git_pkgs)

```r
git_pkgs <- list(
  list(
    package_name = "MMRFBiolinks",
    repo_url = "https://github.com/marziasettino/MMRFBiolinks",
    commit = "HEAD"
  ),
  list(
    package_name = "CopyKat",
    repo_url = "https://github.com/navinlabcode/copykat",
    commit = "HEAD"
  ),
  list(
    package_name = "monocle3",
    repo_url = "https://github.com/cole-trapnell-lab/monocle3",
    commit = "HEAD"
  ),
  list(
    package_name = "SCENIC",
    repo_url = "https://github.com/aertslab/SCENIC",
    commit = "HEAD"
  )
)
```

---

## Complete rix Configuration

```r
# R/dev/nix/packages.R

# ============================================================================
# CoMMpass Multiple Myeloma Analysis Environment
# ============================================================================

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
  "aws.s3", "aws.signature"
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
git_packages <- list(
  list(
    package_name = "MMRFBiolinks",
    repo_url = "https://github.com/marziasettino/MMRFBiolinks",
    commit = "HEAD"
  ),
  list(
    package_name = "copykat",
    repo_url = "https://github.com/navinlabcode/copykat",
    commit = "HEAD"
  )
)

# System dependencies (for Nix)
system_deps <- c(
  "jags",           # Required for infercnv
  "hdf5",           # Required for single-cell data
  "gsl",            # Required for some Bioc packages
  "libxml2",        # Required for XML parsing
  "curl",           # Required for data downloads
  "openssl"         # Required for secure connections
)
```

---

## Analysis Modules

### Module 1: Data Acquisition

```r
# Example: Download RNA-seq data from GDC
library(MMRFBiolinks)
library(TCGAbiolinks)

# Query MMRF-COMMPASS project
query <- GDCquery(
  project = "MMRF-COMMPASS",
  data.category = "Transcriptome Profiling",
  data.type = "Gene Expression Quantification",
  workflow.type = "STAR - Counts"
)

# Download and prepare
GDCdownload(query)
data <- GDCprepare(query)

# Access clinical data via MMRF-RG
clinical <- clinMMGateway()  # From MMRFBiolinks
```

### Module 2: Differential Expression

```r
# DESeq2 workflow
library(DESeq2)

dds <- DESeqDataSetFromMatrix(
  countData = counts,
  colData = clinical,
  design = ~ treatment_response
)
dds <- DESeq(dds)
res <- results(dds, contrast = c("treatment_response", "responder", "non_responder"))
```

### Module 3: Survival Analysis

```r
# Kaplan-Meier and Cox regression
library(survival)
library(survminer)

# Fit survival model
fit <- survfit(Surv(time, status) ~ risk_group, data = clinical)

# Kaplan-Meier plot
ggsurvplot(fit,
           data = clinical,
           risk.table = TRUE,
           pval = TRUE,
           conf.int = TRUE)

# Cox proportional hazards
cox_model <- coxph(Surv(time, status) ~ age + stage + gene_signature,
                   data = clinical)
```

### Module 4: Single-Cell Analysis

```r
# Seurat workflow for Mount Sinai atlas data
library(Seurat)

# Create Seurat object
seurat_obj <- CreateSeuratObject(counts = sc_counts,
                                  meta.data = sc_meta)

# Standard workflow
seurat_obj <- seurat_obj %>%
  NormalizeData() %>%
  FindVariableFeatures() %>%
  ScaleData() %>%
  RunPCA() %>%
  FindNeighbors(dims = 1:30) %>%
  FindClusters(resolution = 0.5) %>%
  RunUMAP(dims = 1:30)

# Cell type annotation
library(SingleR)
ref <- celldex::HumanPrimaryCellAtlasData()
predictions <- SingleR(seurat_obj, ref = ref, labels = ref$label.main)
```

---

## Key References

### Papers & Documentation
1. [MMRFBiolinks Paper (Briefings in Bioinformatics 2021)](https://pubmed.ncbi.nlm.nih.gov/33821961/)
2. [Mount Sinai Immune Cell Atlas (Nature Cancer 2026)](https://www.mountsinai.org/about/newsroom/2026/mount-sinai-researchers-help-create-largest-immune-cell-atlas-of-bone-marrow-in-multiple-myeloma-patients)
3. [Using MMRFBiolinks for Prognostic Markers (Methods Mol Biol 2022)](https://pubmed.ncbi.nlm.nih.gov/34902136/)
4. [MMRF Research Programs IMS 2025 Summary](https://themmrf.org/mmrf-research-programs-expand-understanding-of-the-biology-of-multiple-myeloma-and-patient-reported-outcomes-in-new-data-featured-at-the-20th-ims-annual-meeting/)

### Data Portals
5. [GDC Data Portal - MMRF-COMMPASS](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS) (995 cases, 34,109 files)
6. [AWS Open Data Registry](https://registry.opendata.aws/mmrf-commpass/)
7. [MMRF Researcher Gateway](https://research.themmrf.org/)

### Code Repositories (with R scripts)

| Repository | Description | Language |
|------------|-------------|----------|
| [tgen/MMRF_CoMMpass](https://github.com/tgen/MMRF_CoMMpass) | TGen analysis scripts for recreating CoMMpass analyses | R (21.9%), Shell, MATLAB, Perl |
| [theMMRF/CoMMpass_Chromothripsis_Calculation](https://github.com/theMMRF/CoMMpass_Chromothripsis_Calculation) | Chromothripsis estimation from WGS/WES data | **R** |
| [theMMRF/MMRF_ImmuneAtlas](https://github.com/theMMRF/MMRF_ImmuneAtlas) | Immune Atlas Research Consortium code | HTML |

### Tutorials
8. [Survival Analysis in R Tutorial](https://bioconnector.github.io/workshops/r-survival.html)

---

## Next Steps

1. [ ] Register for MMRF Researcher Gateway access
2. [ ] Apply for GDC controlled access (dbGaP) if needed
3. [ ] Generate Nix environment with `rix::rix()`
4. [ ] Create targets pipeline for reproducible workflow
5. [ ] Develop Shinylive dashboard for results exploration

---

## File Organization

```
proj/data/coMMpass/
├── README.md                    # Project overview and usage
├── PLAN_CoMMpass_Analysis.md    # This document
├── default.sh                   # Nix environment setup script
├── default.R                    # rix configuration
├── default_dev.nix              # Generated Nix environment
├── R/
│   ├── dev/nix/
│   │   └── packages.R           # Package definitions for rix
│   ├── 01_data_acquisition.R
│   ├── 02_quality_control.R
│   ├── 03_differential_expression.R
│   ├── 04_survival_analysis.R
│   ├── 05_single_cell.R
│   └── 06_pathway_analysis.R
├── _targets.R                   # Targets pipeline
├── vignettes/
│   ├── 01_overview.qmd
│   ├── 02_bulk_rnaseq.qmd
│   ├── 03_single_cell.qmd
│   └── 04_survival.qmd
└── data/
    ├── raw/                     # Downloaded from GDC/MMRF-RG
    ├── processed/               # Cleaned/normalized
    └── results/                 # Analysis outputs
```
