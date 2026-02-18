# 03. Exploratory Data Analysis

## Overview

This vignette provides an exploratory analysis of the MMRF CoMMpass data
retrieved by the pipeline. It covers patient demographics, biospecimen
characteristics, RNA-seq quality metrics, and shows how to query the
underlying parquet files with DuckDB.

All summaries are **pre-computed** as targets (`eda_*`). If you have not
yet run the pipeline, placeholder messages appear instead of plots. Run
[`targets::tar_make()`](https://docs.ropensci.org/targets/reference/tar_make.html)
to populate the data.

## Clinical Demographics

    #> - **Patients:** 10 
    #> - **Variables:** 11 
    #> - **Data completeness:** 90.9%

### Age at Diagnosis

![Age at diagnosis
distribution](exploratory-analysis_files/figure-html/age-histogram-1.png)

Age at diagnosis distribution

### Gender Distribution

| Gender | Freq | Percentage |
|:-------|-----:|:-----------|
| female |    1 | 10.0%      |
| male   |    9 | 90.0%      |

Gender Distribution

### Race Distribution

| Race                      | Freq | Percentage |
|:--------------------------|-----:|:-----------|
| asian                     |    2 | 20.0%      |
| black or african american |    3 | 30.0%      |
| not reported              |    1 | 10.0%      |
| white                     |    4 | 40.0%      |

Race Distribution

### Vital Status

| Status | Freq | Percentage |
|:-------|-----:|:-----------|
| alive  |    5 | 50.0%      |
| dead   |    5 | 50.0%      |

Vital Status

## Survival Endpoints

    #> ### Days to Death
    #> 
    #> ```
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #>     296     325     361     451     447     826 
    #> ```
    #> 
    #> - **Censoring rate:** 50.0% (patients still alive at last follow-up)
    #> 
    #> ### Days to Last Follow-up
    #> 
    #> ```
    #>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
    #>   473.0   749.0   797.0   876.6   869.0  1495.0 
    #> ```

## Biospecimen Overview

    #> - **Total samples:** 10 
    #> - **Variables:** 8

### Sample Types

![Sample type
distribution](exploratory-analysis_files/figure-html/sample-type-bar-1.png)

Sample type distribution

### Samples per Patient

![Samples per patient
distribution](exploratory-analysis_files/figure-html/samples-per-patient-1.png)

Samples per patient distribution

## RNA-seq Quality

    #> - **Genes:** 100 
    #> - **Samples:** 10 
    #> - **Total counts:** 62,993 
    #> - **Median library size:** 6,287 
    #> - **Sparsity (% zero entries):** 0.3%

### Library Size Distribution

![Library sizes across
samples](exploratory-analysis_files/figure-html/library-size-boxplot-1.png)

Library sizes across samples

### Genes Detected per Sample

![Genes detected per
sample](exploratory-analysis_files/figure-html/genes-detected-histogram-1.png)

Genes detected per sample

## DuckDB Query Examples

The package provides two functions for querying the parquet files:

- [`query_commpass_parquet()`](https://JohnGavin.github.io/coMMpass-analysis/reference/query_commpass_parquet.md)
  – one-shot query that returns a data frame
- [`get_commpass_tbl()`](https://JohnGavin.github.io/coMMpass-analysis/reference/get_commpass_tbl.md)
  – returns a lazy
  [`dplyr::tbl()`](https://dplyr.tidyverse.org/reference/tbl.html) for
  chained operations

### Example: Simple Query

``` r
# One-shot query (returns data frame)
clinical <- query_commpass_parquet("clinical")
head(clinical)

# With filters
females <- query_commpass_parquet(
  "clinical",
  filters = list(gender = "female")
)
```

    #> **SQL equivalent:**
    #> 
    #> ```sql
    #>  SELECT submitter_id, gender, vital_status, age_at_diagnosis
    #>                          FROM clinical
    #>                          LIMIT 10 
    #> ```

| submitter_id | gender | vital_status | age_at_diagnosis |
|:-------------|:-------|:-------------|-----------------:|
| PATIENT_01   | male   | dead         |               64 |
| PATIENT_02   | male   | dead         |               73 |
| PATIENT_03   | male   | alive        |               56 |
| PATIENT_04   | male   | dead         |               53 |
| PATIENT_05   | male   | alive        |               74 |
| PATIENT_06   | female | alive        |               54 |
| PATIENT_07   | male   | dead         |               63 |
| PATIENT_08   | male   | alive        |               69 |
| PATIENT_09   | male   | alive        |               75 |
| PATIENT_10   | male   | dead         |               67 |

Sample query result (first 10 rows)

### Example: Aggregation with DuckDB

``` r
# Lazy tbl for dplyr-style queries
con <- DBI::dbConnect(duckdb::duckdb())
clinical_tbl <- get_commpass_tbl("clinical", con = con)

result <- clinical_tbl |>
  filter(!is.na(gender)) |>
  group_by(gender) |>
  summarise(
    n = n(),
    mean_age_years = mean(age_at_diagnosis / 365.25, na.rm = TRUE)
  ) |>
  collect()

DBI::dbDisconnect(con, shutdown = TRUE)
```

    #> **SQL equivalent:**
    #> 
    #> ```sql
    #>  SELECT gender, COUNT(*) AS n,
    #>                           ROUND(AVG(age_at_diagnosis / 365.25), 1) AS mean_age_years
    #>                         FROM clinical
    #>                         WHERE gender IS NOT NULL
    #>                         GROUP BY gender 
    #> ```

| gender |   n | mean_age_years |
|:-------|----:|---------------:|
| female |   1 |            0.1 |
| male   |   9 |            0.2 |

Aggregation result

## Cross-dataset Integration

    #> Patient ID overlap between clinical and biospecimen datasets:
    #> 
    #> - **Clinical patients:** 10 
    #> - **Biospecimen patients:** 10 
    #> - **Shared (in both):** 0 
    #> - **Clinical only:** 10 
    #> - **Biospecimen only:** 10

## Reproducibility

Git Commit Info (click to expand)

| Item        | Value                                    |
|:------------|:-----------------------------------------|
| Commit Hash | 17ea786e1bc8a1239ef0cf1bcec94edcb40fe9a7 |
| Author      | jg <JohnGavin@users.noreply.github.com>  |
| Time        | 2026-02-18 17:44:39                      |
| Branch      | fix/data-dictionary-column-widths        |

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
    #> [1] ggplot2_4.0.1  dplyr_1.1.4    targets_1.11.4
    #> 
    #> loaded via a namespace (and not attached):
    #>  [1] sass_0.4.10        generics_0.1.4     digest_0.6.39      magrittr_2.0.4    
    #>  [5] evaluate_1.0.5     grid_4.5.2         RColorBrewer_1.1-3 fastmap_1.2.0     
    #>  [9] jsonlite_2.0.0     processx_3.8.6     backports_1.5.0    secretbase_1.1.1  
    #> [13] ps_1.9.1           scales_1.4.0       codetools_0.2-20   textshaping_1.0.4 
    #> [17] jquerylib_0.1.4    cli_3.6.5          rlang_1.1.7        withr_3.0.2       
    #> [21] cachem_1.1.0       yaml_2.3.12        otel_0.2.0         tools_4.5.2       
    #> [25] base64url_1.4      credentials_2.0.3  vctrs_0.7.0        R6_2.6.1          
    #> [29] lifecycle_1.0.5    fs_1.6.6           htmlwidgets_1.6.4  ragg_1.5.0        
    #> [33] pkgconfig_2.0.3    desc_1.4.3         callr_3.7.6        pkgdown_2.2.0     
    #> [37] pillar_1.11.1      bslib_0.9.0        gtable_0.3.6       data.table_1.18.0 
    #> [41] glue_1.8.0         systemfonts_1.3.1  gert_2.3.1         xfun_0.56         
    #> [45] tibble_3.3.1       tidyselect_1.2.1   sys_3.4.3          knitr_1.51        
    #> [49] farver_2.1.2       htmltools_0.5.9    igraph_2.2.1       rmarkdown_2.30    
    #> [53] labeling_0.4.3     compiler_4.5.2     prettyunits_1.2.0  S7_0.2.1          
    #> [57] askpass_1.2.1      openssl_2.3.4
