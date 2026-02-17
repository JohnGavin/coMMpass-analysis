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

    #> *Clinical summary not available. Run `tar_make()` first.*

### Age at Diagnosis

    #> *Age data not available.*

### Gender Distribution

    #> *Gender data not available.*

### Race Distribution

    #> *Race data not available.*

### Vital Status

    #> *Vital status data not available.*

## Survival Endpoints

    #> *Survival endpoint data not available. Run `tar_make()` first.*

## Biospecimen Overview

    #> *Biospecimen summary not available. Run `tar_make()` first.*

### Sample Types

    #> *Sample type data not available.*

### Samples per Patient

    #> *Samples-per-patient data not available.*

## RNA-seq Quality

    #> *RNA-seq summary not available. Run `tar_make()` first.*

### Library Size Distribution

    #> *Library size data not available.*

### Genes Detected per Sample

    #> *Genes-detected data not available.*

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

    #> *DuckDB demo not available. Run `tar_make()` first.*

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

    #> *DuckDB demo not available.*

## Cross-dataset Integration

    #> *Integration summary not available. Run `tar_make()` first.*

## Reproducibility

Git Commit Info (click to expand)

| Item        | Value                                    |
|:------------|:-----------------------------------------|
| Commit Hash | 689c9f1366a38a3e7f6b47b29a0a33cc77c63b49 |
| Author      | jg <JohnGavin@users.noreply.github.com>  |
| Time        | 2026-02-17 17:22:19                      |
| Branch      | fix/issue-29-pkgdown-rebuild             |

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
    #> [53] compiler_4.5.2     prettyunits_1.2.0  S7_0.2.1           askpass_1.2.1     
    #> [57] openssl_2.3.4
