# 01. Data Acquisition & Status

## Overview

This report summarizes the initial data acquisition step for the MMRF
CoMMpass study. We access Open Access RNA-seq data from the GDC S3
bucket (`s3://gdc-mmrf-commpass-phs000748-2-open/`) via the `targets`
pipeline.

## Pipeline Configuration

    #> *Pipeline configuration not available. Run `tar_make(config)` to generate.*

## RNA-seq Data

RNA-seq gene expression data is downloaded from GDC as a
SummarizedExperiment object.

    #> *RNA-seq data not available. Run `tar_make(raw_rnaseq)` to download.*

## Clinical Data

Clinical metadata retrieved from GDC provides patient demographics,
disease characteristics, and outcomes.

    #> *Clinical data not available. Run `tar_make(clinical_data)` to retrieve.*

## Quality Control

    #> *QC data not available. Run `tar_make()` to generate.*

## Reproducibility

Git Commit Info (click to expand)

| Item        | Value                                    |
|:------------|:-----------------------------------------|
| Commit Hash | 5511edba7dac6e3b8a9336c778bce986385ebffd |
| Author      | John Gavin <john.b.gavin@gmail.com>      |
| Time        | 2026-02-15 19:53:06                      |
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
    #>  [9] callr_3.7.6                 vctrs_0.7.0                
    #> [11] tools_4.5.2                 ps_1.9.1                   
    #> [13] generics_0.1.4              stats4_4.5.2               
    #> [15] base64url_1.4               tibble_3.3.1               
    #> [17] pkgconfig_2.0.3             Matrix_1.7-4               
    #> [19] data.table_1.18.0           secretbase_1.1.1           
    #> [21] RColorBrewer_1.1-3          S7_0.2.1                   
    #> [23] desc_1.4.3                  S4Vectors_0.48.0           
    #> [25] lifecycle_1.0.5             compiler_4.5.2             
    #> [27] farver_2.1.2                credentials_2.0.3          
    #> [29] textshaping_1.0.4           Seqinfo_1.0.0              
    #> [31] codetools_0.2-20            sys_3.4.3                  
    #> [33] htmltools_0.5.9             sass_0.4.10                
    #> [35] yaml_2.3.12                 lazyeval_0.2.2             
    #> [37] pillar_1.11.1               pkgdown_2.2.0              
    #> [39] jquerylib_0.1.4             tidyr_1.3.2                
    #> [41] openssl_2.3.4               DelayedArray_0.36.0        
    #> [43] cachem_1.1.0                abind_1.4-8                
    #> [45] tidyselect_1.2.1            digest_0.6.39              
    #> [47] stringi_1.8.7               purrr_1.2.1                
    #> [49] fastmap_1.2.0               grid_4.5.2                 
    #> [51] SparseArray_1.10.8          cli_3.6.5                  
    #> [53] magrittr_2.0.4              S4Arrays_1.10.1            
    #> [55] withr_3.0.2                 prettyunits_1.2.0          
    #> [57] scales_1.4.0                backports_1.5.0            
    #> [59] XVector_0.50.0              rmarkdown_2.30             
    #> [61] httr_1.4.7                  matrixStats_1.5.0          
    #> [63] igraph_2.2.1                otel_0.2.0                 
    #> [65] askpass_1.2.1               ragg_1.5.0                 
    #> [67] evaluate_1.0.5              knitr_1.51                 
    #> [69] GenomicRanges_1.62.1        IRanges_2.44.0             
    #> [71] viridisLite_0.4.2           rlang_1.1.7                
    #> [73] gert_2.3.1                  glue_1.8.0                 
    #> [75] BiocGenerics_0.56.0         jsonlite_2.0.0             
    #> [77] R6_2.6.1                    MatrixGenerics_1.22.0      
    #> [79] systemfonts_1.3.1           fs_1.6.6
