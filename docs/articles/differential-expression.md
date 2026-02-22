# 04. Differential Expression Analysis

## Overview

This vignette presents differential expression (DE) results from the
CoMMpass RNA-seq pipeline, comparing tumor vs normal or baseline vs
relapse samples using three complementary methods: **DESeq2**,
**edgeR**, and **limma-voom**.

Visualizations include:

- **PCA** of VST-transformed counts for sample clustering
- **Volcano plot** showing fold-change vs significance
- **MA plot** showing mean expression vs fold-change
- **Heatmap** of top DE genes across samples
- **Method comparison** summarizing agreement across DE methods

> **Note:** This vignette was built in CI with `sample_limit=10`. Local
> builds default to 100 samples. Numbers below reflect the CI subset.

## Method Comparison

    #> *DE method summary not available. Run `tar_make()` to build pipeline targets.*

## Principal Component Analysis

PCA is computed from the top 500 most variable genes after
[variance-stabilizing
transformation](https://bioconductor.org/packages/DESeq2/) (VST), which
stabilizes variance across the expression range. VST is preferred over
raw counts or logCPM for exploratory visualization.

    #> *PCA data not available. Run `tar_make()` to compute VST and PCA targets.*

## Volcano Plot

The volcano plot shows statistical significance (-log10 adjusted
p-value) against biological effect size (log2 fold change). Genes in the
upper corners are both statistically significant and biologically
meaningful.

    #> *Volcano plot data not available. Run `tar_make()` to build DE targets.*

## MA Plot

The MA plot (Bland-Altman) shows mean expression (x-axis) against fold
change (y-axis). It reveals whether DE signals are concentrated at
particular expression levels and whether fold-change estimates are
biased.

    #> *MA plot data not available. Run `tar_make()` to build DE targets.*

## Heatmap of Top DE Genes

The heatmap shows Z-score scaled VST expression for the most significant
genes. Rows (genes) and columns (samples) are hierarchically clustered.

    #> *Heatmap data not available. Run `tar_make()` to build VST and DE targets.*

## Consensus Genes

Genes identified as significant by all three methods (DESeq2, edgeR,
limma) represent the highest-confidence DE candidates.

    #> *Consensus DE genes not available. Run `tar_make()` to build DE targets.*

## Paired Longitudinal DE

For patients with samples at multiple timepoints (baseline and relapse),
a paired design (`~ patient_id + visit`) controls for inter-patient
variability and tests for within-patient expression changes over time.

    #> *Paired DE results not available (requires patients with >=2 timepoints).*

## Annotated DE Results

Gene symbols make Ensembl IDs interpretable. The
[`annotate_genes()`](https://johngavin.github.io/coMMpass/reference/annotate_genes.md)
function maps Ensembl IDs to HGNC symbols using [MSigDB gene
mappings](https://www.gsea-msigdb.org/gsea/msigdb/).

    #> *Annotated DE results not available. Run `tar_make()` to build targets.*

## Pathway Enrichment Visualizations

### GSEA Enrichment Dot Plot

    #> *GSEA results not available. Run `tar_make()` with fgsea/msigdbr installed.*

### ORA Enrichment Bar Plot

    #> *ORA results not available. Run `tar_make()` with msigdbr installed.*

## Next Steps

- **Pathway analysis**: Consensus DE genes are tested for enrichment in
  MSigDB Hallmark, KEGG, and other collections. See the [pathway
  analysis
  vignette](https://johngavin.github.io/coMMpass/articles/pathway-analysis.md).
- **Survival analysis**: DE gene signatures can be correlated with
  overall survival. See the [data acquisition
  vignette](https://johngavin.github.io/coMMpass/articles/data-acquisition.md)
  for clinical data integration.
