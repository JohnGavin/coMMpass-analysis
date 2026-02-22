# 01. Data Acquisition & Status

## Overview

This report summarizes the initial data acquisition step for the MMRF
CoMMpass study. We access Open Access RNA-seq data from the GDC S3
bucket (`s3://gdc-mmrf-commpass-phs000748-2-open/`) via the [`targets`
pipeline](https://github.com/JohnGavin/coMMpass-analysis/tree/main/R/tar_plans).

## Pipeline Configuration

    #> The pipeline downloads RNA-seq and clinical data from the [GDC portal](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS) for the **MMRF-COMMPASS** project.
    #> 
    #> - **Sample limit:** 100 patients (GDC has ~900; subsetting speeds local development). In CI, this is [capped at 10 samples](https://github.com/JohnGavin/coMMpass-analysis/blob/main/R/01_data_acquisition.R#L44-L47) to keep build times under 5 minutes.
    #> - **Random seed:** 42 --- ensures reproducible patient selection when `random_sample = TRUE`.
    #> - **Data directory:** `data` | **Results directory:** `results`

> **Note:** This vignette was built with `sample_limit = 100` patients.
> Numbers below reflect this subset, not the full ~900-patient CoMMpass
> cohort. For pipeline execution details, see [issue \#46 (telemetry
> vignette)](https://github.com/JohnGavin/coMMpass-analysis/issues/46).

## RNA-seq Data

RNA-seq gene expression data is downloaded from GDC as a
[SummarizedExperiment](https://bioconductor.org/packages/SummarizedExperiment/)
object containing
[STAR-Counts](https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/).

    #> ### RNA-seq Data Summary
    #> 
    #> - **Samples:** 10 
    #> - **Genes:** 100 
    #> - **Total counts:** 62,993 
    #> - **Median counts per sample:** 6,287 
    #> - **Genes detected (>0 in any sample):** 100 
    #> - **Sparsity (% zero entries):** 0.3%

| Sample    | Total Counts | Genes Detected | Median Count | Max Count |
|:----------|:-------------|:---------------|:-------------|:----------|
| SAMPLE_01 | 6,374        | 99             | 7.0          | 534       |
| SAMPLE_02 | 6,231        | 100            | 6.0          | 532       |
| SAMPLE_03 | 6,293        | 99             | 6.0          | 519       |
| SAMPLE_04 | 6,174        | 99             | 6.0          | 554       |
| SAMPLE_05 | 6,323        | 100            | 6.0          | 526       |
| SAMPLE_06 | 6,130        | 100            | 6.0          | 519       |
| SAMPLE_07 | 6,281        | 100            | 7.0          | 541       |
| SAMPLE_08 | 6,280        | 100            | 6.0          | 521       |
| SAMPLE_09 | 6,435        | 100            | 6.5          | 518       |
| SAMPLE_10 | 6,472        | 100            | 6.0          | 538       |

Per-sample expression summary for 10 samples. Total Counts = library
size, Genes Detected = genes with \>0 counts. Sample IDs are GDC
barcodes. Data: [GDC
STAR-Counts](https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/).

Distribution of mean gene expression (log10 scale) across all genes.
Bimodal shape reflects expressed vs. unexpressed genes. Data: GDC
STAR-Counts.

## Clinical Data

Clinical metadata retrieved from
[GDC](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS) provides
patient demographics, disease characteristics, and outcomes. See the
[data
dictionary](https://johngavin.github.io/coMMpass/articles/data-dictionary.md)
for variable definitions.

    #> ### Clinical Data Overview
    #> 
    #> - **Total patients:** 995 
    #> - **Number of variables:** 91 
    #> - **Data completeness:** 95.9% 
    #> 
    #> ### Patient Demographics
    #> 
    #> 
    #> 
    #> 
    #> ### Sample Clinical Data

### Data Completeness

    #> 84 of 89 variables are fully complete. Only variables **with** missing data are shown below. See [data dictionary](data-dictionary.html) for variable definitions.

| Variable       | Missing Count | Missing Percent |
|:---------------|--------------:|:----------------|
| year_of_birth  |           995 | 100.0%          |
| year_of_death  |           995 | 100.0%          |
| cause_of_death |           807 | 81.1%           |
| days_to_death  |           804 | 80.8%           |
| days_to_birth  |            42 | 4.2%            |

Variables with missing data (5 of 89 total). 84 variables are fully
complete and omitted. See [data
dictionary](https://johngavin.github.io/coMMpass/articles/data-dictionary.md)
for definitions.

## Quality Control

Quality control identifies outlier samples based on library size and
gene detection rate. Samples in the bottom 5% on either metric are
flagged. See
[`R/02_quality_control.R`](https://github.com/JohnGavin/coMMpass-analysis/blob/main/R/02_quality_control.R)
for filtering criteria.

**Variable definitions:**

- **Total Counts** — library size (sum of all read counts per sample)
- **Detected Genes** — number of genes with at least 1 read
- **Median Count** — median read count across all genes in a sample
- **MAD Count** — median absolute deviation of counts (spread measure)
- **Size Factor** — library size / median library size across all
  samples
- **Outlier** — flagged if in bottom 5% by library size OR genes
  detected

&nbsp;

    #> ### QC Metrics Summary
    #> 
    #> - **Samples assessed:** 10
    #> - **Outliers flagged:** 1

| Sample | Total Counts | Detected Genes | Median Count | MAD Count | Size Factor | Outlier |
|:---|:---|:---|:---|:---|:---|:---|
| SAMPLE_01 | 6,374 | 99 | 7.0 | 4.4 | 1.014 | No |
| SAMPLE_02 | 6,231 | 100 | 6.0 | 4.4 | 0.991 | No |
| SAMPLE_03 | 6,293 | 99 | 6.0 | 4.4 | 1.001 | No |
| SAMPLE_04 | 6,174 | 99 | 6.0 | 4.4 | 0.982 | No |
| SAMPLE_05 | 6,323 | 100 | 6.0 | 3.0 | 1.006 | No |
| SAMPLE_06 | 6,130 | 100 | 6.0 | 4.4 | 0.975 | Yes |
| SAMPLE_07 | 6,281 | 100 | 7.0 | 5.2 | 0.999 | No |
| SAMPLE_08 | 6,280 | 100 | 6.0 | 4.4 | 0.999 | No |
| SAMPLE_09 | 6,435 | 100 | 6.5 | 4.4 | 1.024 | No |
| SAMPLE_10 | 6,472 | 100 | 6.0 | 3.0 | 1.029 | No |

Per-sample QC metrics for 10 samples. Total Counts = library size,
Detected Genes = genes with \>0 counts, Size Factor = library size /
median library size. 1 outlier(s) flagged (bottom 5% by library size or
genes detected). Data: GDC STAR-Counts pipeline.

    #> 
    #> ### After Filtering
    #> 
    #> - **Samples retained:** 9 
    #> - **Genes retained:** 31 
    #> - **Genes removed:** 69 (69.0%)

## Reproducibility

Git Commit Info (click to expand)

| Item        | Value                                    |
|:------------|:-----------------------------------------|
| Commit Hash | 7beadbae6964858316be4988217b1ee10e1b626b |
| Author      | jg <JohnGavin@users.noreply.github.com>  |
| Time        | 2026-02-22 12:28:14                      |
| Branch      | main                                     |

Session Info (click to expand)

    #> R version 4.5.2 (2025-10-31)
    #> Platform: aarch64-apple-darwin24.6.0
    #> Running under: macOS Tahoe 26.2
    #> 
    #> Matrix products: default
    #> BLAS:   /nix/store/gf17x1bj3m732n39jznn6kz69szbr5rb-blas-3/lib/libblas.dylib 
    #> LAPACK: /nix/store/5kg4z5bffhr8nry8bl8l5wlxvpy54dm2-openblas-0.3.30/lib/libopenblasp-r0.3.30.dylib;  LAPACK version 3.12.0
    #> 
    #> locale:
    #> [1] en_US.UTF-8/en_US.UTF-8/en_US.UTF-8/C/en_US.UTF-8/en_US.UTF-8
    #> 
    #> time zone: UTC
    #> tzcode source: internal
    #> 
    #> attached base packages:
    #> [1] stats     graphics  grDevices utils     datasets  methods   base     
    #> 
    #> other attached packages:
    #> [1] DT_0.34.0      plotly_4.11.0  stringr_1.6.0  ggplot2_4.0.1  dplyr_1.1.4   
    #> [6] targets_1.11.4
    #> 
    #> loaded via a namespace (and not attached):
    #>  [1] SummarizedExperiment_1.40.0 gtable_0.3.6               
    #>  [3] xfun_0.56                   bslib_0.9.0                
    #>  [5] htmlwidgets_1.6.4           processx_3.8.6             
    #>  [7] lattice_0.22-7              Biobase_2.70.0             
    #>  [9] callr_3.7.6                 crosstalk_1.2.2            
    #> [11] vctrs_0.7.0                 tools_4.5.2                
    #> [13] ps_1.9.1                    generics_0.1.4             
    #> [15] stats4_4.5.2                base64url_1.4              
    #> [17] tibble_3.3.1                pkgconfig_2.0.3            
    #> [19] Matrix_1.7-4                data.table_1.18.0          
    #> [21] secretbase_1.1.1            RColorBrewer_1.1-3         
    #> [23] S7_0.2.1                    desc_1.4.3                 
    #> [25] S4Vectors_0.48.0            assertthat_0.2.1           
    #> [27] lifecycle_1.0.5             compiler_4.5.2             
    #> [29] farver_2.1.2                credentials_2.0.3          
    #> [31] textshaping_1.0.4           Seqinfo_1.0.0              
    #> [33] codetools_0.2-20            sys_3.4.3                  
    #> [35] htmltools_0.5.9             sass_0.4.10                
    #> [37] yaml_2.3.12                 lazyeval_0.2.2             
    #> [39] pillar_1.11.1               pkgdown_2.2.0              
    #> [41] jquerylib_0.1.4             tidyr_1.3.2                
    #> [43] openssl_2.3.4               DelayedArray_0.36.0        
    #> [45] cachem_1.1.0                abind_1.4-8                
    #> [47] tidyselect_1.2.1            digest_0.6.39              
    #> [49] stringi_1.8.7               purrr_1.2.1                
    #> [51] arrow_22.0.0                fastmap_1.2.0              
    #> [53] grid_4.5.2                  SparseArray_1.10.8         
    #> [55] cli_3.6.5                   magrittr_2.0.4             
    #> [57] S4Arrays_1.10.1             withr_3.0.2                
    #> [59] prettyunits_1.2.0           scales_1.4.0               
    #> [61] backports_1.5.0             bit64_4.6.0-1              
    #> [63] XVector_0.50.0              rmarkdown_2.30             
    #> [65] httr_1.4.7                  matrixStats_1.5.0          
    #> [67] bit_4.6.0                   igraph_2.2.1               
    #> [69] otel_0.2.0                  askpass_1.2.1              
    #> [71] ragg_1.5.0                  evaluate_1.0.5             
    #> [73] knitr_1.51                  GenomicRanges_1.62.1       
    #> [75] IRanges_2.44.0              viridisLite_0.4.2          
    #> [77] rlang_1.1.7                 gert_2.3.1                 
    #> [79] glue_1.8.0                  BiocGenerics_0.56.0        
    #> [81] jsonlite_2.0.0              R6_2.6.1                   
    #> [83] MatrixGenerics_1.22.0       systemfonts_1.3.1          
    #> [85] fs_1.6.6
