

# coMMpass

Reproducible analysis of the MMRF CoMMpass (Clinical Outcomes in MM to
Personal Assessment of Genetic Profile) multiple myeloma study data
using R and Nix.

## Overview

The [CoMMpass
study](https://themmrf.org/finding-a-cure/personalized-treatment-approaches/)
is a landmark longitudinal genomic-clinical study of **1,143 newly
diagnosed multiple myeloma patients** collected between 2011-2016 with
8-year follow-up. This project provides:

- Reproducible Nix environment with all required R/Bioconductor packages
- Analysis workflows for RNA-seq, single-cell, and survival analysis
- Direct access to CoMMpass data via GDC API and AWS S3 (open access)

## Usage

### Quick Start (without Nix)

``` r
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
```

#### Pipeline status

The pipeline has **231 targets** (total build time: 387s).

Top 5 targets by build time:

|     | name                  | seconds |   MB |
|:----|:----------------------|--------:|-----:|
| 70  | raw_rnaseq            |   113.2 | 0.00 |
| 171 | deseq2_results        |    50.0 | 2.71 |
| 36  | clinical_data         |    38.4 | 0.00 |
| 170 | deseq2_paired_results |    26.1 | 2.14 |
| 169 | edger_results         |    20.4 | 1.26 |

#### Example: read a result

``` r
km <- tar_read(km_overall)
str(km, max.level = 1)
#> List of 8
#>  $ fit            :List of 17
#>   ..- attr(*, "class")= chr "survfit"
#>  $ logrank        : NULL
#>  $ logrank_p      : num NA
#>  $ median_survival: Named num NA
#>   ..- attr(*, "names")= chr "overall"
#>  $ n_per_group    : Named num 994
#>   ..- attr(*, "names")= chr "overall"
#>  $ strata         : NULL
#>  $ formula        :Class 'formula'  language survival::Surv(time_days, status) ~ 1
#>   .. ..- attr(*, ".Environment")=<environment: 0x8c0f51888> 
#>  $ data           :'data.frame': 994 obs. of  14 variables:
```

> **Note:** The pipeline downloads ~3.6 GB of RNA-seq data from GDC on
> first run. Subsequent runs skip downloads (`cue = "never"`). The
> `config` target sets `sample_limit = 200` by default — edit
> `R/tar_plans/plan_data_acquisition.R` to change this.

### Quick Start (with Nix — fully reproducible)

``` bash
# Requires Nix package manager (https://nixos.org/download.html)
chmod +x default.sh
./default.sh

# macOS only: prevent sleep during long builds
caffeinate -i ./default.sh
```

### What Happens

1.  **`default.sh`** checks if `default_dev.nix` needs regeneration
2.  Runs **`default.R`** which:
    - Extracts package dependencies from `DESCRIPTION` (single source of
      truth)
    - Calls `rix::rix()` to generate `default_dev.nix`
3.  Builds the Nix environment with `nix-build`
4.  Creates a GC root symlink (prevents garbage collection)
5.  Enters an interactive shell with all packages

## Data Access

| Access Level | Data Type | Requirements | Used by this pipeline |
|----|----|----|----|
| **[GDC Data Portal](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS)** | Clinical, RNA-seq (995 cases) | None (open access) | Yes |
| **[AWS Open Data](https://registry.opendata.aws/mmrf-commpass/)** | RNA-seq gene expression | None (AWS CLI) | Yes |
| **[MMRF Researcher Gateway](https://research.themmrf.org/)** | FISH, PFS, treatment response | Free registration (pending) | No (12 targets blocked) |
| **dbGaP Controlled** | Raw sequences (BAM/FASTQ) | Institutional IRB | No |

## Key Packages Included

| Category        | Packages                                 |
|-----------------|------------------------------------------|
| **Data Access** | TCGAbiolinks, GenomicDataCommons, aws.s3 |
| **Survival**    | survival                                 |
| **DE Analysis** | DESeq2, edgeR, limma                     |
| **Pathways**    | fgsea                                    |
| **Causal**      | dagitty, ggdag                           |
| **Pipelines**   | targets, crew, mirai                     |

## Project Structure

    coMMpass/
    ├── R/                          # Package functions & pipeline plans
    │   ├── tar_plans/              # Modular targets plans
    │   └── viz/                    # Visualization functions
    ├── vignettes/                  # Analysis vignettes (pkgdown articles)
    ├── inst/extdata/vignettes/     # Pre-computed RDS for CI
    ├── data/                       # Downloaded data (gitignored)
    ├── default.sh                  # Nix environment setup
    └── default.R                   # rix configuration

## Key References

- [Keats JJ et al. Blood
  2013](https://doi.org/10.1182/blood.V122.21.532.532) — CoMMpass
  interim analysis
- [Nature Genetics
  2024](https://www.nature.com/articles/s41588-024-01853-0) — Molecular
  profiling of 1,143 patients
- [Nature Cancer
  2025](https://www.nature.com/articles/s43018-025-01072-4) — Bone
  marrow immune cell atlas

## Glossary

See the
[Glossary](https://johngavin.github.io/coMMpass-analysis/articles/glossary.html)
vignette for definitions of terms used throughout this project.

## Requirements

- [Nix](https://nixos.org/download.html) package manager (for
  reproducible environment)
- [Cachix](https://cachix.org/) (optional, for faster builds)

``` bash
# Configure cachix caches
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use rstats-on-nix    # Pre-built R packages
cachix use johngavin         # Compiled coMMpass R package
```

## License

MIT
