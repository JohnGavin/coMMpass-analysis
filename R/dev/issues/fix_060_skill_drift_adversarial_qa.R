# fix_060_skill_drift_adversarial_qa.R
# Issue #60: Skill drift detection + adversarial QA for GDC hallucinations
#
# Two mitigations against LLM hallucinations:
#
# 1. plan_skill_drift.R — targets plan that hashes R source files
#    and gdc-genomics skill references; warns when source changes
#    but skill hasn't been updated.
#
# 2. test-adversarial-gdc.R — 35 tests across 7 hallucination-prone areas:
#    - Age units (days vs years)
#    - Assay name ("unstranded")
#    - Ensembl version stripping
#    - DESeq2 shrinkage method (apeglm)
#    - MSigDB collection identifiers
#    - Survival time construction
#    - ISS stage NA handling
#
# Files created/modified:
#   R/tar_plans/plan_skill_drift.R  (new)
#   tests/testthat/test-adversarial-gdc.R  (new)
#   _targets.R  (added plan_skill_drift to pipeline)
#
# Verification:
#   devtools::test(filter = "adversarial-gdc")  # 35/35 pass
#   devtools::check(args = "--as-cran")          # 0 errors, 0 notes
#   targets::tar_validate()                      # valid pipeline
#   Full test suite: 616 pass / 0 fail / 11 skip (pre-existing)
