# 05. Survival Analysis

## Overview

This vignette presents survival analysis results for the CoMMpass
cohort, stratified by clinical and cytogenetic features. Methods
include:

- **Kaplan-Meier curves** with log-rank tests for group comparisons
- **Cox proportional hazards models** for multivariate analysis
- **Forest plots** of hazard ratios with 95% confidence intervals

> **Note:** This vignette was built in CI with `sample_limit=10`. Local
> builds default to 100 samples. Numbers below reflect the CI subset.

## Overall Survival

    #> *Overall KM not available. Run `tar_make()` to build survival targets.*

## Survival by ISS Stage

The [International Staging System
(ISS)](https://doi.org/10.1200/JCO.2005.04.242) stratifies myeloma
patients by serum albumin and beta-2 microglobulin. ISS III is expected
to have worse survival than ISS I.

    #> *ISS data not available.*

## Survival by Cytogenetic Risk Group

Cytogenetic risk per [IMWG 2014
criteria](https://doi.org/10.1200/JCO.2014.55.1519): **high-risk** =
t(4;14) OR t(14;16) OR del(17p); **standard-risk** = all others.

    #> *Cytogenetic risk data not available.*

## Survival by Individual Cytogenetic Markers

Each marker is analyzed separately: patients with vs without the
alteration.

    #> *Individual marker KM data not available. Run `tar_make()` first.*

## Cox Proportional Hazards

### Basic Model: Age + Gender

    #> *Basic Cox model not available. Run `tar_make()` first.*

### Full Model: Age + Gender + ISS + Cytogenetic Risk

    #> *Full Cox model not available. Run `tar_make()` first.*

### Forest Plot

    #> *Forest plot not available.*

### Proportional Hazards Assumption

    #> *PH test not available.*

## Model Comparison

    #> *Model comparison not available.*

## Next Steps

- **Gene expression stratification**: Median-split KM by top DE gene
  expression (requires DE and VST targets).
- **Time-varying coefficients**: For covariates violating the PH
  assumption.
- **Cure models**: If a plateau is observed in KM curves, consider
  mixture cure models.
- See the [differential expression
  vignette](https://johngavin.github.io/coMMpass/articles/differential-expression.md)
  for DE gene signatures that could inform survival stratification.
