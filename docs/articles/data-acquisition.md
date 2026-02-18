# 01. Data Acquisition & Status

## Overview

This report summarizes the initial data acquisition step for the MMRF
CoMMpass study. We access Open Access RNA-seq data from the GDC S3
bucket (`s3://gdc-mmrf-commpass-phs000748-2-open/`) via the `targets`
pipeline.

## Pipeline Configuration

| Parameter         | Value         |
|:------------------|:--------------|
| Project ID        | MMRF-COMMPASS |
| Sample Limit      | 10            |
| Data Directory    | data          |
| Results Directory | results       |
| Random Seed       | 42            |

Pipeline Configuration

## RNA-seq Data

RNA-seq gene expression data is downloaded from GDC as a
SummarizedExperiment object.

    #> ### RNA-seq Data Summary
    #> 
    #> - **Samples:** 10 
    #> - **Genes:** 100 
    #> - **Total counts:** 62,993 
    #> - **Median counts per sample:** 6,287 
    #> - **Genes detected (>0 in any sample):** 100 
    #> - **Sparsity (% zero entries):** 0.3% 
    #> 
    #> 
    #> ### Count Distribution

## Clinical Data

Clinical metadata retrieved from GDC provides patient demographics,
disease characteristics, and outcomes.

    #> ### Clinical Data Overview
    #> 
    #> - **Total patients:** 10 
    #> - **Number of variables:** 11 
    #> - **Data completeness:** 90.9% 
    #> 
    #> ### Patient Demographics
    #> 
    #> 
    #> 
    #> ### Age at Diagnosis (years)
    #> 
    #> - **Median:** 65.5 
    #> - **Range:** 53.0 - 75.0 
    #> 
    #> 
    #> ### Sample Clinical Data
    #> 
    #> 
    #> ### Data Completeness Analysis

| Variable               | Missing_Count | Missing_Percent |
|:-----------------------|--------------:|:----------------|
| days_to_death          |             5 | 50.0%           |
| days_to_last_follow_up |             5 | 50.0%           |
| submitter_id           |             0 | 0.0%            |
| patient_id             |             0 | 0.0%            |
| project_id             |             0 | 0.0%            |
| age_at_diagnosis       |             0 | 0.0%            |
| gender                 |             0 | 0.0%            |
| race                   |             0 | 0.0%            |
| ethnicity              |             0 | 0.0%            |
| vital_status           |             0 | 0.0%            |
| disease_stage          |             0 | 0.0%            |

Variables with Most Missing Data (Top 20)

## Quality Control

    #> ### QC Metrics Summary

|                  | Metric         | Value             |
|:-----------------|:---------------|:------------------|
| sample1          | sample         | SAMPLE_01         |
| sample2          | total_counts   | SAMPLE_02         |
| sample3          | detected_genes | SAMPLE_03         |
| sample4          | median_count   | SAMPLE_04         |
| sample5          | mad_count      | SAMPLE_05         |
| sample6          | size_factor    | SAMPLE_06         |
| sample7          | is_outlier     | SAMPLE_07         |
| sample8          | sample         | SAMPLE_08         |
| sample9          | total_counts   | SAMPLE_09         |
| sample10         | detected_genes | SAMPLE_10         |
| total_counts1    | median_count   | 6374              |
| total_counts2    | mad_count      | 6231              |
| total_counts3    | size_factor    | 6293              |
| total_counts4    | is_outlier     | 6174              |
| total_counts5    | sample         | 6323              |
| total_counts6    | total_counts   | 6130              |
| total_counts7    | detected_genes | 6281              |
| total_counts8    | median_count   | 6280              |
| total_counts9    | mad_count      | 6435              |
| total_counts10   | size_factor    | 6472              |
| detected_genes1  | is_outlier     | 99                |
| detected_genes2  | sample         | 100               |
| detected_genes3  | total_counts   | 99                |
| detected_genes4  | detected_genes | 99                |
| detected_genes5  | median_count   | 100               |
| detected_genes6  | mad_count      | 100               |
| detected_genes7  | size_factor    | 100               |
| detected_genes8  | is_outlier     | 100               |
| detected_genes9  | sample         | 100               |
| detected_genes10 | total_counts   | 100               |
| median_count1    | detected_genes | 7                 |
| median_count2    | median_count   | 6                 |
| median_count3    | mad_count      | 6                 |
| median_count4    | size_factor    | 6                 |
| median_count5    | is_outlier     | 6                 |
| median_count6    | sample         | 6                 |
| median_count7    | total_counts   | 7                 |
| median_count8    | detected_genes | 6                 |
| median_count9    | median_count   | 6.5               |
| median_count10   | mad_count      | 6                 |
| mad_count1       | size_factor    | 4.4478            |
| mad_count2       | is_outlier     | 4.4478            |
| mad_count3       | sample         | 4.4478            |
| mad_count4       | total_counts   | 4.4478            |
| mad_count5       | detected_genes | 2.9652            |
| mad_count6       | median_count   | 4.4478            |
| mad_count7       | mad_count      | 5.1891            |
| mad_count8       | size_factor    | 4.4478            |
| mad_count9       | is_outlier     | 4.4478            |
| mad_count10      | sample         | 2.9652            |
| size_factor1     | total_counts   | 1.01383807857484  |
| size_factor2     | detected_genes | 0.991092731032289 |
| size_factor3     | median_count   | 1.00095435024654  |
| size_factor4     | mad_count      | 0.982026403690154 |
| size_factor5     | size_factor    | 1.00572610147924  |
| size_factor6     | is_outlier     | 0.975027835215524 |
| size_factor7     | sample         | 0.99904564975346  |
| size_factor8     | total_counts   | 0.998886591379036 |
| size_factor9     | detected_genes | 1.02354063941467  |
| size_factor10    | median_count   | 1.02942579926833  |
| is_outlier1      | mad_count      | FALSE             |
| is_outlier2      | size_factor    | FALSE             |
| is_outlier3      | is_outlier     | FALSE             |
| is_outlier4      | sample         | FALSE             |
| is_outlier5      | total_counts   | FALSE             |
| is_outlier6      | detected_genes | TRUE              |
| is_outlier7      | median_count   | FALSE             |
| is_outlier8      | mad_count      | FALSE             |
| is_outlier9      | size_factor    | FALSE             |
| is_outlier10     | is_outlier     | FALSE             |

Quality Control Metrics

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
| Commit Hash | a631c4a544c36ece578317fa83eef69dd4e2f508 |
| Author      | jg <JohnGavin@users.noreply.github.com>  |
| Time        | 2026-02-18 13:48:02                      |
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
    #> [25] S4Vectors_0.48.0            lifecycle_1.0.5            
    #> [27] compiler_4.5.2              farver_2.1.2               
    #> [29] credentials_2.0.3           textshaping_1.0.4          
    #> [31] Seqinfo_1.0.0               codetools_0.2-20           
    #> [33] sys_3.4.3                   htmltools_0.5.9            
    #> [35] sass_0.4.10                 yaml_2.3.12                
    #> [37] lazyeval_0.2.2              pillar_1.11.1              
    #> [39] pkgdown_2.2.0               jquerylib_0.1.4            
    #> [41] tidyr_1.3.2                 openssl_2.3.4              
    #> [43] DelayedArray_0.36.0         cachem_1.1.0               
    #> [45] abind_1.4-8                 tidyselect_1.2.1           
    #> [47] digest_0.6.39               stringi_1.8.7              
    #> [49] purrr_1.2.1                 fastmap_1.2.0              
    #> [51] grid_4.5.2                  SparseArray_1.10.8         
    #> [53] cli_3.6.5                   magrittr_2.0.4             
    #> [55] S4Arrays_1.10.1             withr_3.0.2                
    #> [57] prettyunits_1.2.0           scales_1.4.0               
    #> [59] backports_1.5.0             XVector_0.50.0             
    #> [61] rmarkdown_2.30              httr_1.4.7                 
    #> [63] matrixStats_1.5.0           igraph_2.2.1               
    #> [65] otel_0.2.0                  askpass_1.2.1              
    #> [67] ragg_1.5.0                  evaluate_1.0.5             
    #> [69] knitr_1.51                  GenomicRanges_1.62.1       
    #> [71] IRanges_2.44.0              viridisLite_0.4.2          
    #> [73] rlang_1.1.7                 gert_2.3.1                 
    #> [75] glue_1.8.0                  BiocGenerics_0.56.0        
    #> [77] jsonlite_2.0.0              R6_2.6.1                   
    #> [79] MatrixGenerics_1.22.0       systemfonts_1.3.1          
    #> [81] fs_1.6.6
