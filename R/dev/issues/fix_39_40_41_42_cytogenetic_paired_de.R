# R/dev/issues/fix_39_40_41_42_cytogenetic_paired_de.R
# Implements features from CD70-in-Multiple-Myeloma comparison
#
# Issues addressed:
#   #39 - feat: Add cytogenetic subgroup data acquisition and analysis
#   #42 - feat: Add ISS staging stratification to EDA
#   #40 - feat: Add paired longitudinal DE design for within-patient comparisons
#   #41 - feat: Add apeglm LFC shrinkage to DESeq2 workflow
#
# Reference: https://github.com/BonellPatinoE/CD70-in-Multiple-Myeloma
#
# Changes:
#   1. New R/01b_cytogenetic_data.R:
#      - extract_cytogenetic_data() extracts FISH markers from GDC clinical data
#      - parse_cytogenetic_status() standardizes Yes/No/1/0 to positive/negative
#      - classify_cytogenetic_risk() assigns IMWG 2014 risk groups
#      - Markers: t(4;14), t(11;14), t(14;16), t(14;20), del(17p), del(1p), gain(1q)
#
#   2. Rewritten R/03_differential_expression.R:
#      - run_deseq2() now supports paired=TRUE for longitudinal within-patient design
#      - run_deseq2() now supports shrink_lfc=TRUE for apeglm LFC shrinkage
#      - New run_deseq2_paired() using ~ patient_id + visit design
#      - New parse_commpass_barcodes() for extracting patient/visit from barcodes
#      - New build_paired_coldata() for identifying patients with >=2 timepoints
#      - Replaced placeholder implementations of run_edger(), run_limma(),
#        find_consensus_genes() with real implementations
#
#   3. New R/tar_plans/plan_cytogenetic.R:
#      - cytogenetic_data target depending on clinical_data
#
#   4. Updated R/tar_plans/plan_differential_expression.R:
#      - Added deseq2_paired_results target
#
#   5. Updated _targets.R:
#      - Added plan_cytogenetic to pipeline
#
#   6. Updated DESCRIPTION:
#      - Added apeglm to Suggests (Bioconductor)
#      - Moved stringr from Suggests to Imports (used in barcode parsing)
#
#   7. Updated .github/workflows/02-data.yaml, 03-analysis.yaml, 04-website.yaml:
#      - Adopted targets-runs orphan branch pattern from b-rodrigues/nix_targets_pipeline
#      - Replaced artifact-based state with permanent git branch
#      - Replaced hardcoded target names with tar_make()
#      - Added failure artifacts + contents:write permissions
#
#   8. New tests/testthat/test-cytogenetic.R
#
#   9. Updated R/tar_plans/plan_eda.R:
#      - Added eda_iss_summary target for ISS stage distribution
#      - Age by ISS stage cross-tabulation
#
#   10. Updated vignettes/exploratory-analysis.Rmd:
#       - Added ISS Staging section with distribution table, barplot, age-by-ISS
#
# Note on cytogenetic data access:
#   SeqFISH files (Pairoscope, GATK CNA) are MMRF Researcher Gateway exclusive.
#   We extract FISH results from GDC clinical data instead, which covers all
#   7 markers. For higher-resolution data, MMRF Gateway access is needed (see #39).
