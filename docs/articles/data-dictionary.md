# 02. Data Dictionary

## Overview

This document describes all variables in the MMRF CoMMpass dataset as
downloaded from the [Genomic Data Commons
(GDC)](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS). The
CoMMpass (Relating Clinical Outcomes in Multiple Myeloma to Personal
Assessment of Genetic Profile) study is a longitudinal observational
study of ~1,000 newly diagnosed multiple myeloma patients.

**Data sources:**

- [GDC Portal -
  MMRF-COMMPASS](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS)
- [GDC Data
  Dictionary](https://docs.gdc.cancer.gov/Data_Dictionary/viewer/)
- [MMRF CoMMpass Study](https://themmrf.org/research/commpass-study/)

## Complete Data Dictionary

## Clinical Data

Clinical data includes patient demographics, disease characteristics,
and outcomes. Downloaded via
[`TCGAbiolinks::GDCquery_clinic()`](https://rdrr.io/pkg/TCGAbiolinks/man/GDCquery_clinic.html).

    #> *Clinical data not available. Run the pipeline to download.*

## Biospecimen Data

Biospecimen data describes the tissue samples collected from patients.

    #> *Biospecimen data not available. Run the pipeline to download.*

## RNA-seq Data

RNA-seq gene expression data is generated using the STAR aligner and
quantified against GENCODE annotations. Data is available in multiple
quantification types.

    #> *RNA-seq data not available. Run the pipeline to download.*

## Column Name Mappings

GDC uses standardized column names. Common aliases used in analysis:

| GDC Column               | Common Alias       | Notes                     |
|--------------------------|--------------------|---------------------------|
| `submitter_id`           | patient_id         | Unique patient identifier |
| `age_at_diagnosis`       | age_days           | In **days**, not years    |
| `vital_status`           | status             | Alive/Dead                |
| `days_to_death`          | os_time (if dead)  | Overall survival time     |
| `days_to_last_follow_up` | os_time (if alive) | Censoring time            |
| `gender`                 | sex                | male/female               |
| `primary_diagnosis`      | diagnosis          | ICD-O-3 morphology        |

## Units Reference

**Age and time variables are stored in DAYS by GDC.** This is the single
most common source of errors in GDC analyses.

| Variable | Unit | Conversion |
|----|----|----|
| `age_at_diagnosis` | days | `age_years = age_at_diagnosis / 365.25` |
| `days_to_death` | days | Used directly in survival analysis |
| `days_to_last_follow_up` | days | Censoring time for survival |
| `days_to_last_known_disease_status` | days | Disease assessment time |
| `unstranded` / `stranded_*` | raw integer counts | Input for DESeq2/edgeR |
| `tpm_unstranded` | TPM | Cross-sample comparison |
| `fpkm_unstranded` | FPKM | Largely deprecated, use TPM |

## Data Sources & Links

- **GDC Portal**: <https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS>
- **GDC Data Dictionary**:
  <https://docs.gdc.cancer.gov/Data_Dictionary/viewer/>
- **GDC mRNA Analysis Pipeline**:
  <https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/>
- **MMRF CoMMpass Study**:
  <https://themmrf.org/research/commpass-study/>
- **GENCODE**: <https://www.gencodegenes.org/>
- **Ensembl**: <https://www.ensembl.org/>

## R Code Examples

### Loading Data

``` r
library(coMMpass)

# Load clinical data from parquet
clinical <- query_commpass_parquet("clinical")

# Load with DuckDB lazy evaluation
con <- DBI::dbConnect(duckdb::duckdb())
clinical_tbl <- get_commpass_tbl("clinical", con = con)
result <- clinical_tbl |>
  dplyr::filter(gender == "female") |>
  dplyr::select(submitter_id, age_at_diagnosis, vital_status) |>
  dplyr::mutate(age_years = age_at_diagnosis / 365.25) |>
  dplyr::collect()
DBI::dbDisconnect(con, shutdown = TRUE)
```

### Exploring the Dictionary

``` r
dd <- get_commpass_data_dictionary()

# Find all clinical variables
dplyr::filter(dd, category == "clinical")

# Get detailed docs for a variable
docs <- get_variable_docs("age_at_diagnosis")
cat(docs$usage_notes)
```

## Reproducibility

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
    #> [1] DT_0.34.0      dplyr_1.1.4    targets_1.11.4
    #> 
    #> loaded via a namespace (and not attached):
    #>  [1] base64url_1.4     jsonlite_2.0.0    compiler_4.5.2    tidyselect_1.2.1 
    #>  [5] callr_3.7.6       jquerylib_0.1.4   systemfonts_1.3.1 textshaping_1.0.4
    #>  [9] yaml_2.3.12       fastmap_1.2.0     R6_2.6.1          generics_0.1.4   
    #> [13] igraph_2.2.1      knitr_1.51        htmlwidgets_1.6.4 backports_1.5.0  
    #> [17] tibble_3.3.1      desc_1.4.3        bslib_0.9.0       pillar_1.11.1    
    #> [21] rlang_1.1.7       cachem_1.1.0      xfun_0.56         fs_1.6.6         
    #> [25] sass_0.4.10       otel_0.2.0        cli_3.6.5         pkgdown_2.2.0    
    #> [29] magrittr_2.0.4    crosstalk_1.2.2   ps_1.9.1          digest_0.6.39    
    #> [33] processx_3.8.6    secretbase_1.1.1  lifecycle_1.0.5   prettyunits_1.2.0
    #> [37] vctrs_0.7.0       evaluate_1.0.5    glue_1.8.0        data.table_1.18.0
    #> [41] codetools_0.2-20  ragg_1.5.0        rmarkdown_2.30    tools_4.5.2      
    #> [45] pkgconfig_2.0.3   htmltools_0.5.9
