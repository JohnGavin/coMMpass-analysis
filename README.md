# commpass

Reproducible analysis of the MMRF CoMMpass (Clinical Outcomes in MM to Personal Assessment of Genetic Profile) multiple myeloma study data using R and Nix.

## Overview

The [CoMMpass study](https://themmrf.org/finding-a-cure/personalized-treatment-approaches/) is a landmark longitudinal genomic-clinical study of **1,143 newly diagnosed multiple myeloma patients** collected between 2011-2016 with 8-year follow-up. This project provides:

- Reproducible Nix environment with all required R/Bioconductor packages
- Analysis workflows for RNA-seq, single-cell, and survival analysis
- Direct access to CoMMpass data via GDC API and AWS S3 (open access)

## Interactive Dashboard

> **Status: Under construction.** The Shinylive dashboard is not yet deployed.
> See [`inst/shinylive/dashboard_shinylive.qmd`](inst/shinylive/dashboard_shinylive.qmd) for the source.

Planned features:
- Quality Control metrics and visualizations
- Differential Expression analysis (volcano plots, MA plots, heatmaps)
- Survival Analysis (Kaplan-Meier curves, Cox regression)
- Pathway Analysis (enrichment plots, GSEA)

## Usage

### Quick Start (without Nix)

```r
# Install from GitHub (requires Bioconductor deps)
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")
BiocManager::install(c("TCGAbiolinks", "DESeq2", "edgeR", "limma",
                        "SummarizedExperiment", "fgsea"))
remotes::install_github("JohnGavin/coMMpass-analysis")

# Clone the repo (targets needs _targets.R in working directory)
# git clone https://github.com/JohnGavin/coMMpass-analysis.git
# setwd("coMMpass-analysis")

# Run the pipeline — downloads data from GDC, then runs all analyses
library(targets)
tar_make()

# Check pipeline status (229 targets in full pipeline)
tar_meta(fields = c("seconds", "bytes")) |>
  dplyr::filter(!is.na(seconds)) |>
  dplyr::arrange(dplyr::desc(seconds)) |>
  head(5)
#> # A tibble: 5 × 3
#>   name                  seconds   bytes
#> 1 raw_rnaseq              113.       79
#> 2 deseq2_results           50.0 2712950
#> 3 clinical_data            38.4      70
#> 4 deseq2_paired_results    26.1 2143795
#> 5 edger_results            20.4 1257741

# Read a result
km <- tar_read(km_overall)
str(km, max.level = 1)
#> List of 8
#>  $ fit            :List of 17
#>  $ median_survival: Named num NA
#>  $ n_per_group    : Named num 994
#>  $ data           :'data.frame': 994 obs. of 14 variables
```

> **Note:** The pipeline downloads ~3.6 GB of RNA-seq data from GDC on first
> run. Subsequent runs skip downloads (`cue = "never"`). The `config` target
> sets `sample_limit = 200` by default — edit `R/tar_plans/plan_data_acquisition.R`
> to change this.

### Quick Start (with Nix — fully reproducible)

```bash
# Requires Nix package manager (https://nixos.org/download.html)
chmod +x default.sh
./default.sh

# macOS only: prevent sleep during long builds
caffeinate -i ./default.sh
```

### What Happens

1. **`default.sh`** checks if `default_dev.nix` needs regeneration
2. Runs **`default.R`** which:
   - Extracts package dependencies from `DESCRIPTION` (single source of truth)
   - Calls `rix::rix()` to generate `default_dev.nix`
3. Builds the Nix environment with `nix-build`
4. Creates a GC root symlink (prevents garbage collection)
5. Enters an interactive shell with all packages

### In the Nix Shell

```bash
# Count files in CoMMpass S3 bucket (no credentials needed)
aws s3 ls --no-sign-request s3://gdc-mmrf-commpass-phs000748-2-open/ | wc
#       46     230    2627
# 46 top-level prefixes/files

# Start R
R
```

```r
# For users: library(coMMpass) works if installed via Nix
library(coMMpass)

# For developers: use load_all() for live source changes
# devtools::load_all()
```

## Data Access

| Access Level | Data Type | Requirements | Used by this pipeline |
|---|---|---|---|
| **[GDC Data Portal](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS)** | Clinical, RNA-seq (995 cases) | None (open access) | Yes |
| **[AWS Open Data](https://registry.opendata.aws/mmrf-commpass/)** | RNA-seq gene expression | None (AWS CLI) | Yes |
| **[MMRF Researcher Gateway](https://research.themmrf.org/)** | FISH, PFS, treatment response | Free registration (pending) | No (12 targets blocked) |
| **dbGaP Controlled** | Raw sequences (BAM/FASTQ) | Institutional IRB | No |

### AWS S3 (Easiest - No Account Required)

```bash
# List available files
aws s3 ls --no-sign-request s3://gdc-mmrf-commpass-phs000748-2-open/

# Download directly
aws s3 cp --no-sign-request \
  s3://gdc-mmrf-commpass-phs000748-2-open/path/to/file.tsv \
  ./data/
```

### TCGAbiolinks (Recommended R Package)

```r
library(TCGAbiolinks)

system.time({
  query <- GDCquery(
    project = "MMRF-COMMPASS",
    data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification",
    workflow.type = "STAR - Counts"
  )
})
#    user  system elapsed
#   2.858   0.193  12.465

# WARNING: Downloads 859 files totalling ~3.6 GB
# Downloads in chunks of ~1 GB each
GDCdownload(query)
# Downloading data for project MMRF-COMMPASS
# GDCdownload will download 859 files. A total of 3.625715802 GB
# Downloading chunk 1 of 4 (236 files, size = 995.931306 MB) as ...tar.gz
# Downloading chunk 2 of 4 (233 files, size = 980.248560 MB) as ...tar.gz
# Downloading chunk 3 of 4 (221 files, size = 919.145699 MB) as ...tar.gz
# Downloading chunk 4 of 4 (169 files, size = 830.245815 MB) as ...tar.gz

data <- GDCprepare(query)
# Returns a RangedSummarizedExperiment:
str(data, max.level = 2)
# Formal class 'RangedSummarizedExperiment' [package "SummarizedExperiment"]
#   ..@ assays  : 4 assays (unstranded, stranded_first, stranded_second, tpm_unstrand)
#   ..@ colData : 859 samples × 89 clinical variables
#   ..@ rowData : 60,660 genes (Ensembl IDs, gene symbols, biotypes)
```

## Key Packages Included

| Category | Packages |
|----------|----------|
| **Data Access** | TCGAbiolinks, GenomicDataCommons, aws.s3 |
| **Survival** | survival, survminer, timeROC |
| **Single-cell** | Seurat, SingleR, infercnv, copykat, monocle3 |
| **DE Analysis** | DESeq2, edgeR, limma |
| **Pathways** | clusterProfiler, fgsea, ReactomePA |
| **Pipelines** | targets, crew, mirai |

## Project Structure

```
coMMpass/
├── R/                          # Package functions & pipeline plans
│   ├── tar_plans/              # Modular targets plans
│   └── dev/                    # Development tools
├── vignettes/                  # Analysis vignettes (pkgdown articles)
├── inst/shinylive/             # Dashboard source (WIP)
├── data/                       # Downloaded data (gitignored)
├── default.sh                  # Nix environment setup
└── default.R                   # rix configuration
```

> Individual files (DESCRIPTION, NAMESPACE, .gitignore, .Rbuildignore, LICENSE) excluded for brevity.

## Key References

### Code Repositories

| Repository | Description |
|------------|-------------|
| [tgen/MMRF_CoMMpass](https://github.com/tgen/MMRF_CoMMpass) | TGen analysis scripts (R, Shell, MATLAB) |
| [theMMRF/CoMMpass_Chromothripsis_Calculation](https://github.com/theMMRF/CoMMpass_Chromothripsis_Calculation) | Chromothripsis estimation (R) |

### Papers

- [MMRFBiolinks (Briefings in Bioinformatics 2021)](https://pubmed.ncbi.nlm.nih.gov/33821961/) -- R/Bioconductor interface for CoMMpass data
- [Comprehensive molecular profiling of multiple myeloma (Nature Genetics 2024)](https://www.nature.com/articles/s41588-024-01853-0) -- Refined copy number and expression subtypes from 1,143 patients
  - [Winship Cancer Institute summary](https://winshipcancer.emory.edu/newsroom/articles/2024/landmark-study-reveals-new-insights-into-multiple-myeloma-progression.php) -- accessible overview
  - [MMRF press release](https://themmrf.org/mmrf-press-releases/multiple-myeloma-research-foundation-mmrf-announces-new-publication-on-commpass-study-in-nature-genetics-defining-distinct-subtypes-of-multiple-myeloma-and-high-risk-genetic-markers/) -- patient-facing summary
- [Bone marrow immune cell atlas in multiple myeloma (Nature Cancer 2025)](https://www.nature.com/articles/s43018-025-01072-4) -- ~1.5M immune cells from 335 patients
  - [Mount Sinai newsroom article](https://www.mountsinai.org/about/newsroom/2026/mount-sinai-researchers-help-create-largest-immune-cell-atlas-of-bone-marrow-in-multiple-myeloma-patients) -- accessible overview

## Glossary

See the [Glossary](https://johngavin.github.io/coMMpass-analysis/articles/glossary.html) vignette for definitions of terms used throughout this project.

## Requirements

- [Nix](https://nixos.org/download.html) package manager
- [Cachix](https://cachix.org/) (optional, for faster builds)

```bash
# Configure cachix caches
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use rstats-on-nix    # Pre-built R packages
cachix use johngavin         # Compiled coMMpass R package
```

## License

MIT
