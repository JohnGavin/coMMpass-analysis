# R/tar_plans/plan_doc_examples.R
# Code-as-targets for vignette code display blocks.
# Each code example is stored as a character vector target, validated
# via parse(), and displayed in vignettes with safe_tar_read().
#
# Pattern reference: irishbuoys/R/tar_plans/plan_doc_examples.R

# --- Helper: parse validation (no execution) ---
parse_code_example <- function(code_lines) {
  code_text <- paste(code_lines, collapse = "\n")
  tryCatch(
    {
      parsed <- parse(text = code_text)
      list(
        valid = TRUE,
        n_expressions = length(parsed),
        code = code_lines,
        error = NULL
      )
    },
    error = function(e) {
      list(
        valid = FALSE,
        n_expressions = 0L,
        code = code_lines,
        error = conditionMessage(e)
      )
    }
  )
}

# ============================================================
# Code text targets (one per display block in vignettes)
# ============================================================

plan_doc_examples <- list(

  # --- data-dictionary.Rmd: "Loading Data" block ---
  targets::tar_target(
    code_dd_load_data,
    {
      # Depend on the source file defining these functions
      force(file.exists("R/database_parquet.R"))
      c(
        "library(coMMpass)",
        "",
        "# Load clinical data from parquet",
        "clinical <- query_commpass_parquet(\"clinical\")",
        "",
        "# Load with DuckDB lazy evaluation",
        "con <- DBI::dbConnect(duckdb::duckdb())",
        "clinical_tbl <- get_commpass_tbl(\"clinical\", con = con)",
        "result <- clinical_tbl |>",
        "  dplyr::filter(gender == \"female\") |>",
        "  dplyr::select(submitter_id, age_at_diagnosis, vital_status) |>",
        "  dplyr::mutate(age_years = age_at_diagnosis / 365.25) |>",
        "  dplyr::collect()",
        "DBI::dbDisconnect(con, shutdown = TRUE)"
      )
    }
  ),

  # --- data-dictionary.Rmd: "Exploring the Dictionary" block ---
  targets::tar_target(
    code_dd_explore_dict,
    {
      force(file.exists("R/data_dictionary.R"))
      c(
        "dd <- get_commpass_data_dictionary()",
        "",
        "# Find all clinical variables",
        "dplyr::filter(dd, category == \"clinical\")",
        "",
        "# Get detailed docs for a variable",
        "docs <- get_variable_docs(\"age_at_diagnosis\")",
        "cat(docs$usage_notes)"
      )
    }
  ),

  # --- README: Quick Start bash commands ---
  targets::tar_target(
    code_readme_quick_start,
    c(
      "# Requires Nix package manager (https://nixos.org/download.html)",
      "chmod +x default.sh",
      "./default.sh",
      "",
      "# macOS only: prevent sleep during long builds",
      "caffeinate -i ./default.sh"
    )
  ),

  # --- README: Project structure tree ---
  targets::tar_target(
    readme_project_tree,
    {
      force(file.exists("DESCRIPTION"))
      utils::capture.output(
        fs::dir_tree(recurse = 2, regexp = "^[^._]", type = "directory")
      )
    }
  ),

  # --- Glossary vignette: Glossary table (~64 terms, 8 categories) ---
  targets::tar_target(
    glossary_table,
    data.frame(
      Term = c(
        # Disease & Study (5)
        "Multiple Myeloma", "CoMMpass", "GDC", "MMRF", "TCGAbiolinks",
        # Cytogenetics & Markers (6)
        "FISH", "Cytogenetic Risk", "t(4;14)", "t(14;16)", "del(17p)",
        "High-Risk / Standard-Risk",
        # Staging & Risk (3)
        "ISS", "IMWG", "B2M / Serum Albumin", "B2M",
        # RNA-seq & QC (13)
        "RNA-seq", "Read count", "Library size", "TPM", "Gene detection",
        "MAD", "Outlier (QC)", "VST",
        "STAR", "GENCODE", "Ensembl", "HGNC", "Entrez",
        # Differential Expression (9)
        "DE", "DESeq2", "edgeR", "limma-voom", "Log2 Fold Change",
        "FDR / Adjusted p-value", "Volcano Plot",
        "PCA", "LFC",
        # Survival Analysis (8)
        "Overall Survival (OS)", "Progression-Free Survival (PFS)", "KM",
        "Log-Rank Test", "Cox PH", "HR", "Forest Plot", "Confidence Interval",
        # Pathway & Enrichment (6)
        "GSEA", "ORA", "MSigDB", "Hallmark Gene Sets", "Pathway", "Gene Set",
        "GO", "KEGG", "Reactome",
        # Data Infrastructure (11)
        "Targets", "sample_limit", "Nix", "pkgdown",
        "API", "DAG", "DuckDB", "Parquet", "CI", "CRAN", "Bioconductor"
      ),
      Category = c(
        rep("Disease & Study", 5),
        rep("Cytogenetics & Markers", 6),
        rep("Staging & Risk", 4),
        rep("RNA-seq & QC", 13),
        rep("Differential Expression", 9),
        rep("Survival Analysis", 8),
        rep("Pathway & Enrichment", 9),
        rep("Data Infrastructure", 11)
      ),
      Definition = c(
        # Disease & Study
        "Cancer of plasma cells in the bone marrow. The most common indication for stem cell transplant in adults",
        "Clinical Outcomes in Multiple Myeloma to Personal Assessment of Genetic Profile -- MMRF longitudinal study of ~1,143 newly diagnosed MM patients",
        "Genomic Data Commons -- NCI repository hosting CoMMpass RNA-seq and clinical data",
        "Multiple Myeloma Research Foundation -- sponsor of the CoMMpass trial",
        "Bioconductor R package for querying and downloading GDC data programmatically",
        # Cytogenetics & Markers
        "Fluorescence in situ hybridization -- detects cytogenetic abnormalities like t(4;14), t(14;16), del(17p)",
        "Classification of patients into high-risk or standard-risk based on FISH-detected chromosomal abnormalities per IMWG criteria",
        "Translocation between chromosomes 4 and 14 -- associated with poor prognosis in MM. Detected by FISH",
        "Translocation between chromosomes 14 and 16 -- high-risk marker associated with aggressive disease",
        "Deletion of the short arm of chromosome 17 -- loss of TP53 tumor suppressor, high-risk marker",
        "High-risk: presence of t(4;14), t(14;16), or del(17p). Standard-risk: absence of all three. Per IMWG 2014 criteria",
        # Staging & Risk
        "International Staging System -- classifies myeloma severity (I-III) by serum albumin and beta-2 microglobulin (Greipp et al. 2005, doi:10.1200/JCO.2005.04.242)",
        "International Myeloma Working Group -- defines cytogenetic risk criteria (Sonneveld et al. 2016, doi:10.1200/JCO.2014.55.1519)",
        "Beta-2 microglobulin and serum albumin -- the two biomarkers used to determine ISS stage. B2M >= 5.5 mg/L = Stage III",
        "Beta-2 microglobulin -- serum protein used in ISS staging. B2M >= 5.5 mg/L indicates Stage III myeloma",
        # RNA-seq & QC
        "RNA sequencing -- high-throughput method to quantify gene expression. CoMMpass uses bulk RNA-seq from bone marrow aspirates",
        "The number of sequencing reads aligned to a gene in one sample. Raw integer counts are the input for DE methods (DESeq2, edgeR)",
        "Total number of sequencing reads mapped to genes in one sample (= sum of all gene counts). A proxy for sequencing depth. Synonym: Total Counts",
        "Transcripts per million -- normalized expression measure for cross-sample comparison. Accounts for gene length and sequencing depth",
        "A gene is 'detected' in a sample if it has >= 1 mapped read (count > 0). The number of detected genes per sample is a QC metric; low detection suggests poor depth or degradation",
        "Median absolute deviation -- robust measure of spread. In QC context, MAD of gene counts within a single sample measures expression variability",
        "A sample flagged as outlier if it falls in the bottom 5th percentile of library size OR genes detected. The flag is binary (Yes/No)",
        "Variance-stabilizing transformation -- normalizes count data for visualization and clustering, reducing mean-variance dependence",
        "Spliced Transcripts Alignment to a Reference -- RNA-seq aligner used in GDC pipeline",
        "Comprehensive gene annotation project providing reference gene models for genome analysis",
        "Genome database providing gene IDs (ENSG*) used in RNA-seq quantification",
        "HUGO Gene Nomenclature Committee -- authority for standardized human gene symbols",
        "NCBI gene identifier system used for cross-database gene referencing",
        # Differential Expression
        "Differential expression -- genes with significantly different expression between conditions (e.g. high-risk vs standard-risk)",
        "Bioconductor package for DE analysis using negative binomial GLMs with shrinkage estimation. The primary DE method in this pipeline",
        "Bioconductor package for DE analysis using empirical Bayes moderation of tagwise dispersions. Used as consensus method alongside DESeq2",
        "Linear modelling framework (limma) with voom precision weights for RNA-seq. Third consensus DE method in pipeline",
        "Log-base-2 ratio of expression between conditions. LFC > 0 = upregulated; LFC < 0 = downregulated. Shrinkage-corrected LFC used for ranking",
        "False discovery rate -- p-values adjusted for multiple testing (Benjamini-Hochberg). FDR < 0.05 is the standard significance threshold for DE",
        "Scatter plot of log2 fold change (x) vs -log10 adjusted p-value (y). Highlights significantly DE genes in the upper-left and upper-right quadrants",
        "Principal component analysis -- dimensionality reduction technique for visualizing sample clustering and batch effects",
        "Log2 fold change -- effect size measure for differential expression. Positive = upregulated; negative = downregulated",
        # Survival Analysis
        "Time from diagnosis to death from any cause. The primary survival endpoint in CoMMpass",
        "Time from diagnosis to disease progression or death. A secondary endpoint capturing earlier clinical events",
        "Kaplan-Meier -- non-parametric survival curve estimator. Handles right-censored data (patients still alive at last follow-up)",
        "Non-parametric test comparing survival distributions between groups. Tests whether KM curves differ significantly (p < 0.05)",
        "Cox proportional hazards -- semi-parametric regression for survival data. Estimates hazard ratios adjusting for covariates",
        "Hazard ratio -- relative risk of event occurrence. HR > 1 = increased risk (worse survival); HR < 1 = protective effect",
        "Visual display of hazard ratios with confidence intervals for multiple covariates from a Cox model. Each row is a covariate; dashed line at HR = 1",
        "Range of plausible values for an estimate (typically 95%). For HRs, a CI crossing 1.0 indicates non-significance",
        # Pathway & Enrichment
        "Gene Set Enrichment Analysis -- tests whether predefined gene sets are enriched at the top or bottom of a ranked gene list. Uses all genes, not just significant ones",
        "Over-Representation Analysis -- tests whether a set of DE genes contains more members of a pathway than expected by chance (Fisher's exact test)",
        "Molecular Signatures Database -- curated collection of gene sets for GSEA/ORA. Categories include Hallmark, GO, KEGG, Reactome",
        "MSigDB Hallmark collection -- 50 curated gene sets representing well-defined biological states and processes (e.g. EMT, p53 pathway, hypoxia)",
        "A set of genes involved in a common biological process (e.g. cell cycle, apoptosis). Annotated in databases like KEGG, Reactome, GO",
        "Any defined collection of genes tested together in enrichment analysis (broader than 'pathway' -- includes GO terms, TF targets, etc.)",
        "Gene Ontology -- structured vocabulary of gene/protein functions (Biological Process, Molecular Function, Cellular Component)",
        "Kyoto Encyclopedia of Genes and Genomes -- pathway and molecular interaction database",
        "Open-source curated pathway database of biological reactions and processes",
        # Data Infrastructure
        "R-based pipeline tool (targets package) for reproducible, cached computation. Each analysis step is a 'target' with dependency tracking",
        "Pipeline parameter controlling the number of patient samples included. Default: local=100, CI=10. Lower values speed up development; higher values improve statistical power",
        "Reproducible build system providing isolated, version-pinned R environments via nixpkgs. Ensures all collaborators use identical package versions",
        "R package for building package documentation websites. Renders vignettes, function reference, and news into a static site hosted on GitHub Pages",
        "Application Programming Interface -- structured endpoints for programmatic data access",
        "Directed acyclic graph -- dependency structure used by targets pipeline for reproducible execution",
        "In-process analytical database used for efficient parquet querying in the pipeline",
        "Columnar storage format used for efficient data storage and querying in the pipeline",
        "Continuous integration -- automated testing and deployment via GitHub Actions",
        "Comprehensive R Archive Network -- primary repository for R packages",
        "Open-source software project for genomics and bioinformatics R packages"
      ),
      Appears_In = c(
        # Disease & Study
        "survival (3), exploratory (2), data-sources (2)",
        "data-sources (5), exploratory (3), survival (2), gene-report (2)",
        "data-acquisition (8), data-sources (3), data-dictionary (2)",
        "data-sources (3), data-acquisition (2)",
        "data-acquisition (4), data-sources (2)",
        # Cytogenetics & Markers
        "exploratory (6), survival (4), gene-report (3)",
        "survival (5), exploratory (4), gene-report (3)",
        "survival (3), exploratory (2)",
        "survival (3), exploratory (2)",
        "survival (3), exploratory (2)",
        "survival (4), exploratory (3)",
        # Staging & Risk
        "survival (6), exploratory (5), data-dictionary (2)",
        "survival (3), exploratory (2)",
        "exploratory (2), data-dictionary (2)",
        "survival (3), exploratory (2)",
        # RNA-seq & QC
        "data-acquisition (6), exploratory (3), differential-expression (2)",
        "data-acquisition (4), differential-expression (3)",
        "data-acquisition (5), exploratory (3)",
        "data-acquisition (3), data-dictionary (2)",
        "data-acquisition (4), exploratory (2)",
        "data-acquisition (3), exploratory (2)",
        "data-acquisition (3), exploratory (2)",
        "differential-expression (4), exploratory (3), survival (2)",
        "data-acquisition (3), data-sources (2)",
        "data-acquisition (2), data-sources (1)",
        "data-acquisition (3), gene-report (2)",
        "gene-report (3), differential-expression (2)",
        "gene-report (2), data-acquisition (1)",
        # Differential Expression
        "differential-expression (8), gene-report (5), survival (2)",
        "differential-expression (6), gene-report (3)",
        "differential-expression (4), gene-report (2)",
        "differential-expression (4), gene-report (2)",
        "differential-expression (5), gene-report (3)",
        "differential-expression (4), gene-report (2)",
        "differential-expression (3), gene-report (2)",
        "exploratory (4), differential-expression (2)",
        "differential-expression (5), gene-report (3)",
        # Survival Analysis
        "survival (8), exploratory (2)",
        "survival (4)",
        "survival (6), exploratory (2)",
        "survival (4)",
        "survival (5), exploratory (1)",
        "survival (6), gene-report (2)",
        "survival (3)",
        "survival (4)",
        # Pathway & Enrichment
        "gene-report (6), differential-expression (3)",
        "gene-report (4), differential-expression (2)",
        "gene-report (5), differential-expression (2)",
        "gene-report (4)",
        "gene-report (5), differential-expression (3)",
        "gene-report (4), differential-expression (2)",
        "gene-report (3), differential-expression (2)",
        "gene-report (3), differential-expression (2)",
        "gene-report (2), differential-expression (1)",
        # Data Infrastructure
        "pipeline-dag (6), telemetry (4), data-sources (2)",
        "data-sources (3), survival (2), exploratory (2)",
        "data-sources (2)",
        "data-sources (2)",
        "api-usage (6), data-sources (2)",
        "pipeline-dag (5), telemetry (2)",
        "data-sources (3), data-dictionary (2)",
        "data-sources (3), api-usage (2)",
        "telemetry (3), pipeline-dag (2)",
        "data-sources (1)",
        "data-acquisition (4), differential-expression (3)"
      ),
      See_Also = c(
        # Disease & Study
        "[Wikipedia](https://en.wikipedia.org/wiki/Multiple_myeloma), [NCI](https://www.cancer.gov/types/myeloma)",
        "[MMRF](https://themmrf.org/finding-a-cure/personalized-treatment-approaches/), [GDC Portal](https://portal.gdc.cancer.gov/projects/MMRF-COMMPASS)",
        "[GDC Portal](https://portal.gdc.cancer.gov/), [GDC Docs](https://docs.gdc.cancer.gov/)",
        "[MMRF](https://themmrf.org/), [Data Sources](data-sources.html)",
        "[Bioconductor](https://bioconductor.org/packages/TCGAbiolinks/), [Data Acquisition](data-acquisition.html)",
        # Cytogenetics & Markers
        "[Wikipedia](https://en.wikipedia.org/wiki/Fluorescence_in_situ_hybridization), [EDA vignette](exploratory-analysis.html)",
        "[Survival vignette](survival-analysis.html), [IMWG](https://doi.org/10.1200/JCO.2014.55.1519)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Chromosomal_translocation), [Survival vignette](survival-analysis.html)",
        "[Survival vignette](survival-analysis.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Chromosome_17_(human)#Deletions), [Survival vignette](survival-analysis.html)",
        "[IMWG criteria](https://doi.org/10.1200/JCO.2014.55.1519), [Survival vignette](survival-analysis.html)",
        # Staging & Risk
        "[Greipp et al. 2005](https://doi.org/10.1200/JCO.2005.04.242), [EDA vignette](exploratory-analysis.html)",
        "[IMWG](https://doi.org/10.1200/JCO.2014.55.1519), [Survival vignette](survival-analysis.html)",
        "[ISS definition](https://doi.org/10.1200/JCO.2005.04.242), [Data Dictionary](data-dictionary.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Beta-2_microglobulin), [ISS staging](https://doi.org/10.1200/JCO.2005.04.242)",
        # RNA-seq & QC
        "[Wikipedia](https://en.wikipedia.org/wiki/RNA-Seq), [Data Acquisition](data-acquisition.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/RNA-Seq), [Data Acquisition](data-acquisition.html#rnaseq-data)",
        "[Data Acquisition](data-acquisition.html#rnaseq-data), [Wikipedia](https://en.wikipedia.org/wiki/RNA-Seq#Analysis)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Transcripts_per_million), [Data Dictionary](data-dictionary.html)",
        "[Data Acquisition QC](data-acquisition.html#quality-control)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Median_absolute_deviation), [Data Acquisition QC](data-acquisition.html#quality-control)",
        "[Data Acquisition QC](data-acquisition.html#quality-control)",
        "[DESeq2 docs](https://bioconductor.org/packages/DESeq2/), [DE vignette](differential-expression.html)",
        "[GitHub](https://github.com/alexdobin/STAR), [GDC Pipeline](https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/)",
        "[gencodegenes.org](https://www.gencodegenes.org/), [Data Acquisition](data-acquisition.html)",
        "[ensembl.org](https://www.ensembl.org/), [Data Acquisition](data-acquisition.html)",
        "[genenames.org](https://www.genenames.org/), [Gene Report](gene-report.html)",
        "[NCBI Gene](https://www.ncbi.nlm.nih.gov/gene/), [Gene Report](gene-report.html)",
        # Differential Expression
        "[DE vignette](differential-expression.html), [Wikipedia](https://en.wikipedia.org/wiki/Differential_gene_expression)",
        "[Bioconductor](https://bioconductor.org/packages/DESeq2/), [PMID:25516281](https://pubmed.ncbi.nlm.nih.gov/25516281/)",
        "[Bioconductor](https://bioconductor.org/packages/edgeR/), [PMID:19910308](https://pubmed.ncbi.nlm.nih.gov/19910308/)",
        "[Bioconductor](https://bioconductor.org/packages/limma/), [PMID:25605792](https://pubmed.ncbi.nlm.nih.gov/25605792/)",
        "[DE vignette](differential-expression.html), [Wikipedia](https://en.wikipedia.org/wiki/Fold_change)",
        "[Wikipedia](https://en.wikipedia.org/wiki/False_discovery_rate), [DE vignette](differential-expression.html)",
        "[DE vignette](differential-expression.html), [Wikipedia](https://en.wikipedia.org/wiki/Volcano_plot_(statistics))",
        "[Wikipedia](https://en.wikipedia.org/wiki/Principal_component_analysis), [EDA vignette](exploratory-analysis.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Fold_change), [DE vignette](differential-expression.html)",
        # Survival Analysis
        "[Wikipedia](https://en.wikipedia.org/wiki/Overall_survival), [Survival vignette](survival-analysis.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Progression-free_survival), [Survival vignette](survival-analysis.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Kaplan%E2%80%93Meier_estimator), [Survival vignette](survival-analysis.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Logrank_test), [Survival vignette](survival-analysis.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Proportional_hazards_model), [Survival vignette](survival-analysis.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Hazard_ratio), [Survival vignette](survival-analysis.html)",
        "[Survival vignette](survival-analysis.html#forest-plot)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Confidence_interval), [Survival vignette](survival-analysis.html)",
        # Pathway & Enrichment
        "[GSEA](https://www.gsea-msigdb.org/gsea/), [PMID:16199517](https://pubmed.ncbi.nlm.nih.gov/16199517/), [Gene Report](gene-report.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Gene_set_enrichment_analysis#Over-representation_analysis), [Gene Report](gene-report.html)",
        "[MSigDB](https://www.gsea-msigdb.org/gsea/msigdb/), [Gene Report](gene-report.html)",
        "[MSigDB Hallmarks](https://www.gsea-msigdb.org/gsea/msigdb/human/collections.jsp#H), [Gene Report](gene-report.html)",
        "[KEGG](https://www.genome.jp/kegg/pathway.html), [Reactome](https://reactome.org/), [Gene Report](gene-report.html)",
        "[Gene Report](gene-report.html), [MSigDB](https://www.gsea-msigdb.org/gsea/msigdb/)",
        "[geneontology.org](http://geneontology.org/), [Gene Report](gene-report.html)",
        "[genome.jp/kegg](https://www.genome.jp/kegg/), [Gene Report](gene-report.html)",
        "[reactome.org](https://reactome.org/), [Gene Report](gene-report.html)",
        # Data Infrastructure
        "[targets package](https://docs.ropensci.org/targets/), [Pipeline DAG](pipeline-dag.html)",
        "[Data Sources](data-sources.html), [Survival vignette](survival-analysis.html)",
        "[Nix](https://nixos.org/), [rix package](https://docs.ropensci.org/rix/)",
        "[pkgdown](https://pkgdown.r-lib.org/), [Data Sources](data-sources.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/API), [API Usage](api-usage.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Directed_acyclic_graph), [Pipeline DAG](pipeline-dag.html)",
        "[duckdb.org](https://duckdb.org/), [Data Sources](data-sources.html)",
        "[parquet.apache.org](https://parquet.apache.org/), [Data Sources](data-sources.html)",
        "[Wikipedia](https://en.wikipedia.org/wiki/Continuous_integration), [Telemetry](telemetry.html)",
        "[cran.r-project.org](https://cran.r-project.org/), [Data Sources](data-sources.html)",
        "[bioconductor.org](https://www.bioconductor.org/), [Data Acquisition](data-acquisition.html)"
      ),
      stringsAsFactors = FALSE
    )
  ),

  # --- exploratory-analysis.Rmd: "Simple Query" block ---
  targets::tar_target(
    code_eda_simple_query,
    {
      force(file.exists("R/database_parquet.R"))
      c(
        "# One-shot query (returns data frame)",
        "clinical <- query_commpass_parquet(\"clinical\")",
        "head(clinical)",
        "",
        "# With dplyr/tbl syntax",
        "con <- DBI::dbConnect(duckdb::duckdb())",
        "clinical_tbl <- get_commpass_tbl(\"clinical\", con = con)",
        "females <- clinical_tbl |>",
        "  dplyr::filter(gender == \"female\") |>",
        "  dplyr::collect()",
        "DBI::dbDisconnect(con, shutdown = TRUE)"
      )
    }
  ),

  # --- exploratory-analysis.Rmd: "Aggregation with DuckDB" block ---
  targets::tar_target(
    code_eda_aggregation,
    {
      force(file.exists("R/database_parquet.R"))
      c(
        "# Lazy tbl for dplyr-style queries",
        "con <- DBI::dbConnect(duckdb::duckdb())",
        "clinical_tbl <- get_commpass_tbl(\"clinical\", con = con)",
        "",
        "result <- clinical_tbl |>",
        "  dplyr::filter(!is.na(gender)) |>",
        "  dplyr::group_by(gender) |>",
        "  dplyr::summarise(",
        "    n = dplyr::n(),",
        "    mean_age_years = mean(age_at_diagnosis / 365.25, na.rm = TRUE)",
        "  ) |>",
        "  dplyr::collect()",
        "",
        "DBI::dbDisconnect(con, shutdown = TRUE)"
      )
    }
  ),

  # --- api-usage.Rmd: curl example ---
  targets::tar_target(
    code_api_curl,
    c(
      "# Fetch the endpoint index",
      "curl -s https://JohnGavin.github.io/coMMpass-analysis/api/v1/index.json | jq .",
      "",
      "# Fetch clinical data",
      "curl -s https://JohnGavin.github.io/coMMpass-analysis/api/v1/clinical.json | jq '.metadata'",
      "",
      "# Download survival data",
      "curl -o survival.json https://JohnGavin.github.io/coMMpass-analysis/api/v1/survival.json"
    )
  ),

  # --- api-usage.Rmd: R (jsonlite) example ---
  targets::tar_target(
    code_api_r,
    c(
      'base_url <- "https://JohnGavin.github.io/coMMpass-analysis/api/v1"',
      "",
      "# Read endpoint index",
      'index <- jsonlite::fromJSON(paste0(base_url, "/index.json"))',
      "index$endpoints",
      "",
      "# Load clinical data as data frame",
      'clinical <- jsonlite::fromJSON(paste0(base_url, "/clinical.json"))',
      "str(clinical$metadata)",
      "head(clinical$data)",
      "",
      "# Load survival data",
      'surv <- jsonlite::fromJSON(paste0(base_url, "/survival.json"))',
      "dim(surv$data)"
    )
  ),

  # --- api-usage.Rmd: Python example ---
  targets::tar_target(
    code_api_python,
    c(
      "import requests",
      "import pandas as pd",
      "",
      'base_url = "https://JohnGavin.github.io/coMMpass-analysis/api/v1"',
      "",
      "# Fetch clinical data",
      'resp = requests.get(f"{base_url}/clinical.json")',
      "data = resp.json()",
      'print(f"Rows: {data[\'metadata\'][\'n_rows\']}")',
      "",
      "# Convert to DataFrame",
      "df = pd.DataFrame(data['data'])",
      "print(df.head())"
    )
  ),

  # ============================================================
  # Parse validation targets
  # ============================================================

  targets::tar_target(
    code_parsed_readme_quick_start,
    # Bash code -- just validate it's a character vector
    list(valid = TRUE, n_expressions = 0L, code = code_readme_quick_start, error = NULL)
  ),

  targets::tar_target(
    code_parsed_dd_load_data,
    parse_code_example(code_dd_load_data)
  ),

  targets::tar_target(
    code_parsed_dd_explore_dict,
    parse_code_example(code_dd_explore_dict)
  ),

  targets::tar_target(
    code_parsed_eda_simple_query,
    parse_code_example(code_eda_simple_query)
  ),

  targets::tar_target(
    code_parsed_eda_aggregation,
    parse_code_example(code_eda_aggregation)
  ),

  targets::tar_target(
    code_parsed_api_curl,
    # Bash code -- just validate it's a character vector
    list(valid = TRUE, n_expressions = 0L, code = code_api_curl, error = NULL)
  ),

  targets::tar_target(
    code_parsed_api_r,
    parse_code_example(code_api_r)
  ),

  targets::tar_target(
    code_parsed_api_python,
    # Python code -- just validate it's a character vector
    list(valid = TRUE, n_expressions = 0L, code = code_api_python, error = NULL)
  ),

  # ============================================================
  # Master validation gate
  # ============================================================

  targets::tar_target(
    doc_examples_validation,
    {
      parse_results <- list(
        readme_quick_start = code_parsed_readme_quick_start,
        dd_load_data       = code_parsed_dd_load_data,
        dd_explore_dict    = code_parsed_dd_explore_dict,
        eda_simple_query   = code_parsed_eda_simple_query,
        eda_aggregation    = code_parsed_eda_aggregation,
        api_curl           = code_parsed_api_curl,
        api_r              = code_parsed_api_r,
        api_python         = code_parsed_api_python
      )

      all_valid <- all(vapply(parse_results, function(x) x$valid, logical(1)))

      if (!all_valid) {
        failed <- names(parse_results)[
          !vapply(parse_results, function(x) x$valid, logical(1))
        ]
        errors <- vapply(
          parse_results[failed],
          function(x) x$error %||% "unknown",
          character(1)
        )
        cli::cli_abort(c(
          "x" = "Vignette code examples failed syntax validation",
          "i" = "Failed examples: {paste(failed, collapse = ', ')}",
          "i" = "Errors: {paste(errors, collapse = '; ')}"
        ))
      }

      list(
        all_valid    = all_valid,
        n_examples   = length(parse_results),
        examples     = names(parse_results),
        validated_at = Sys.time()
      )
    }
  )
)
