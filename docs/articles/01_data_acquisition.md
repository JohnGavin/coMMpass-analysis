# 01. Data Acquisition & Status

## Overview

This report summarizes the initial data acquisition step for the MMRF
CoMMpass study. We access Open Access RNA-seq data from the GDC S3
bucket (`s3://gdc-mmrf-commpass-phs000748-2-open/`).

## S3 Bucket Status

We query the S3 bucket to get a complete manifest of available files.

    #> *Manifest data not available. Run `tar_make(s3_manifest)` to generate.*

### File Type Distribution

## Downloaded Samples

We downloaded a small subset of RNA-seq files for initial testing.

    #> *No downloaded files found. Run `tar_make(rna_sample_files)` to download sample data.*

## Clinical Data

Clinical metadata retrieved from GDC provides patient demographics,
disease characteristics, and outcomes.

    #> *Clinical data not available. Run `tar_make(clinical_data)` to retrieve.*

## Reproducibility

### Git Commit Info

| Item        | Value                                    |
|:------------|:-----------------------------------------|
| Commit Hash | 4fc983b0c23b71ec233a9307d70a22e13b13822c |
| Author      | main                                     |
| Time        | 4fc983b0c23b71ec233a9307d70a22e13b13822c |
| Branch      | main                                     |

### Session Info

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
    #>  [1] tidyr_1.3.2        sass_0.4.10        generics_0.1.4     stringi_1.8.7     
    #>  [5] digest_0.6.39      magrittr_2.0.4     evaluate_1.0.5     grid_4.5.2        
    #>  [9] RColorBrewer_1.1-3 fastmap_1.2.0      jsonlite_2.0.0     processx_3.8.6    
    #> [13] backports_1.5.0    secretbase_1.1.1   ps_1.9.1           httr_1.4.7        
    #> [17] purrr_1.2.1        viridisLite_0.4.2  scales_1.4.0       lazyeval_0.2.2    
    #> [21] codetools_0.2-20   textshaping_1.0.4  jquerylib_0.1.4    cli_3.6.5         
    #> [25] rlang_1.1.7        withr_3.0.2        cachem_1.1.0       yaml_2.3.12       
    #> [29] otel_0.2.0         tools_4.5.2        base64url_1.4      credentials_2.0.3 
    #> [33] vctrs_0.7.0        R6_2.6.1           lifecycle_1.0.5    fs_1.6.6          
    #> [37] htmlwidgets_1.6.4  ragg_1.5.0         pkgconfig_2.0.3    desc_1.4.3        
    #> [41] callr_3.7.6        pkgdown_2.2.0      pillar_1.11.1      bslib_0.9.0       
    #> [45] gtable_0.3.6       data.table_1.18.0  glue_1.8.0         systemfonts_1.3.1 
    #> [49] gert_2.3.1         xfun_0.56          tibble_3.3.1       tidyselect_1.2.1  
    #> [53] sys_3.4.3          knitr_1.51         farver_2.1.2       htmltools_0.5.9   
    #> [57] igraph_2.2.1       rmarkdown_2.30     compiler_4.5.2     prettyunits_1.2.0 
    #> [61] S7_0.2.1           askpass_1.2.1      openssl_2.3.4
