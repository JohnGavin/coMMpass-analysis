# coMMpass 0.1.0

* Initial release of the MMRF CoMMpass data analysis pipeline.
* GDC data acquisition for RNA-seq, clinical, and biospecimen data.
* Cytogenetic marker extraction (t(4;14), del(17p), etc.).
* Differential expression via DESeq2, edgeR, and limma with consensus analysis.
* Paired-sample DE analysis with apeglm shrinkage.
* Pathway enrichment: GSEA and ORA using local MSigDB gene sets (hallmark, KEGG).
* Survival analysis: Kaplan-Meier and Cox regression with cytogenetic stratification.
* Reproducible targets pipeline with crew parallelism.
* Nix-based development environment for full reproducibility.
* Shiny dashboard with QC, DE, survival, and pathway modules.
