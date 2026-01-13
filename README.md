# commpass

Reproducible analysis of the MMRF CoMMpass (Clinical Outcomes in MM to Personal Assessment of Genetic Profile) multiple myeloma study data using R and Nix.

## Overview

The [CoMMpass study](https://themmrf.org/finding-a-cure/personalized-treatment-approaches/) is a landmark longitudinal genomic-clinical study of **1,143 newly diagnosed multiple myeloma patients** collected between 2011-2016 with 8-year follow-up. This project provides:

- Reproducible Nix environment with all required R/Bioconductor packages
- Analysis workflows for RNA-seq, single-cell, and survival analysis
- Direct access to CoMMpass data via AWS S3, GDC, and MMRF Researcher Gateway

## Usage

### Quick Start

```bash
# Make executable and run
chmod +x default.sh
./default.sh

# Or with caffeinate for long builds
caffeinate -i ./default.sh
```

### What Happens

1. **`default.sh`** checks if `default_dev.nix` needs regeneration
2. Runs **`default.R`** which:
   - Sources package definitions from `R/dev/nix/packages.R`
   - Calls `rix::rix()` to generate `default_dev.nix`
3. Builds the Nix environment with `nix-build`
4. Creates a GC root symlink (prevents garbage collection)
5. Enters an interactive shell with all packages

### In the Nix Shell

```bash
# List CoMMpass S3 bucket (no credentials needed)
aws s3 ls --no-sign-request s3://gdc-mmrf-commpass-phs000748-2-open/

# Start R
R

# In R:
library(TCGAbiolinks)
query <- GDCquery(project = "MMRF-COMMPASS", ...)
```

## Data Access

| Access Level | Data Type | Requirements |
|--------------|-----------|--------------|
| **AWS Open Data** | RNA-seq gene expression | None (just AWS CLI) |
| **MMRF Researcher Gateway** | Clinical + genomic | Free registration |
| **dbGaP Controlled** | Raw sequences (BAM/FASTQ) | Institutional affiliation + IRB |

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

query <- GDCquery(
  project = "MMRF-COMMPASS",
  data.category = "Transcriptome Profiling",
  data.type = "Gene Expression Quantification",
  workflow.type = "STAR - Counts"
)

GDCdownload(query)
data <- GDCprepare(query)
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
├── README.md                    # This file
├── PLAN_CoMMpass_Analysis.md    # Detailed analysis plan
├── default.sh                   # Nix environment setup
├── default.R                    # rix configuration
├── R/
│   └── dev/nix/
│       └── packages.R           # Package definitions
├── vignettes/                   # Quarto analysis documents
└── data/                        # Downloaded data (gitignored)
```

## Key References

### Code Repositories

| Repository | Description |
|------------|-------------|
| [tgen/MMRF_CoMMpass](https://github.com/tgen/MMRF_CoMMpass) | TGen analysis scripts (R, Shell, MATLAB) |
| [theMMRF/CoMMpass_Chromothripsis_Calculation](https://github.com/theMMRF/CoMMpass_Chromothripsis_Calculation) | Chromothripsis estimation (R) |

### Data Portals

- [GDC Data Portal](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS) - 995 cases, 34,109 files
- [AWS Open Data Registry](https://registry.opendata.aws/mmrf-commpass/)
- [MMRF Researcher Gateway](https://research.themmrf.org/)

### Papers

- [MMRFBiolinks (Briefings in Bioinformatics 2021)](https://pubmed.ncbi.nlm.nih.gov/33821961/)
- [Mount Sinai Immune Cell Atlas](https://www.mountsinai.org/about/newsroom/2026/mount-sinai-researchers-help-create-largest-immune-cell-atlas-of-bone-marrow-in-multiple-myeloma-patients)

## Requirements

- [Nix](https://nixos.org/download.html) package manager
- [Cachix](https://cachix.org/) (optional, for faster builds)

```bash
# Install cachix for faster builds
nix-env -iA cachix -f https://cachix.org/api/v1/install
cachix use rstats-on-nix
```

## License

MIT
