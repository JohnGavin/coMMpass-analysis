# tests/testthat/test-example-data.R
# Tests for example_data() factory function

test_that("example_data() returns expected structure", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()

  expect_type(d, "list")
  expect_named(d, c("rnaseq_se", "clinical", "cytogenetic"))
})

test_that("rnaseq_se is a valid SummarizedExperiment", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  se <- d$rnaseq_se

  expect_s4_class(se, "SummarizedExperiment")
  expect_equal(nrow(se), 50)
  expect_equal(ncol(se), 20)
  expect_true("unstranded" %in% SummarizedExperiment::assayNames(se))

  # rowData has expected columns
  rd <- as.data.frame(SummarizedExperiment::rowData(se))
  expect_true("gene_id" %in% names(rd))
  expect_true("gene_type" %in% names(rd))

  # gene_ids have Ensembl-format with version suffix
  expect_true(all(grepl("^ENSG\\d+\\.\\d+$", rd$gene_id)))

  # Multiple biotypes present
  expect_true(length(unique(rd$gene_type)) >= 3)

  # colData has expected columns
  cd <- as.data.frame(SummarizedExperiment::colData(se))
  expect_true("submitter_id" %in% names(cd))
  expect_true("sample_type" %in% names(cd))
})

test_that("clinical data has expected structure", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  clin <- d$clinical

  expect_s3_class(clin, "data.frame")
  expect_equal(nrow(clin), 20)

  required_cols <- c(
    "submitter_id", "vital_status", "days_to_death",
    "days_to_last_follow_up", "age_at_diagnosis", "gender", "iss_stage",
    "heavy_chain", "light_chain", "ecog_status", "ldh"
  )
  for (col in required_cols) {
    expect_true(col %in% names(clin), info = paste("Missing column:", col))
  }

  # vital_status has expected values
  expect_true(all(clin$vital_status %in% c("Dead", "Alive")))

  # age_at_diagnosis is in days (> 120 means days, not years)
  expect_true(max(clin$age_at_diagnosis, na.rm = TRUE) > 120)

  # heavy_chain values
  expect_true(all(clin$heavy_chain %in% c("IgG", "IgA", "IgD", "Light chain only")))

  # light_chain values
  expect_true(all(clin$light_chain %in% c("Kappa", "Lambda")))

  # ecog_status in 0-4
  expect_true(all(clin$ecog_status %in% 0:4))

  # ldh is numeric
  expect_true(is.numeric(clin$ldh))
})

test_that("cytogenetic data has expected structure", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  cyto <- d$cytogenetic

  expect_s3_class(cyto, "data.frame")
  expect_equal(nrow(cyto), 20)

  required_cols <- c(
    "patient_id", "t_4_14", "t_11_14", "t_14_16",
    "del_17p", "gain_1q", "risk_group"
  )
  for (col in required_cols) {
    expect_true(col %in% names(cyto), info = paste("Missing column:", col))
  }

  # Markers are Yes/No
  marker_cols <- c("t_4_14", "t_11_14", "t_14_16", "del_17p", "gain_1q")
  for (col in marker_cols) {
    expect_true(
      all(cyto[[col]] %in% c("Yes", "No")),
      info = paste("Invalid values in", col)
    )
  }

  # risk_group is High/Standard
  expect_true(all(cyto$risk_group %in% c("High", "Standard")))
})

test_that("example data works with calculate_qc_metrics()", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  qc <- calculate_qc_metrics(d$rnaseq_se)

  expect_s3_class(qc, "data.frame")
  expect_equal(nrow(qc), 20)
  expect_true("total_counts" %in% names(qc))
  expect_true("detected_genes" %in% names(qc))
  expect_true("is_outlier" %in% names(qc))
})

test_that("example data works with clean_clinical_data()", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  clin <- clean_clinical_data(d$clinical)

  expect_s3_class(clin, "data.frame")
  expect_equal(nrow(clin), 20)
  # clean_clinical_data adds age_at_diagnosis_years
  expect_true("age_at_diagnosis_years" %in% names(clin))
  # clean_clinical_data adds missing counts
  expect_true("n_missing" %in% names(clin))
})

test_that("example data works with prepare_survival_data()", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()
  surv <- prepare_survival_data(d$clinical, cyto_file = d$cytogenetic)

  expect_s3_class(surv, "data.frame")
  expect_true(nrow(surv) > 0)
  expect_true("patient_id" %in% names(surv))
  expect_true("time_days" %in% names(surv))
  expect_true("status" %in% names(surv))
  # Cytogenetic merge adds risk_group
  expect_true("risk_group" %in% names(surv))
  # Clinical passthroughs
  expect_true("heavy_chain" %in% names(surv))
  expect_true("light_chain" %in% names(surv))
  expect_true("ecog_status" %in% names(surv))
  # All time values positive
  expect_true(all(surv$time_days > 0))
})

test_that("patient IDs are consistent across datasets", {
  skip_if_not_installed("SummarizedExperiment")
  skip_if_not_installed("S4Vectors")

  d <- example_data()

  clin_ids <- d$clinical$submitter_id
  cyto_ids <- d$cytogenetic$patient_id
  se_ids <- as.data.frame(
    SummarizedExperiment::colData(d$rnaseq_se)
  )$submitter_id

  # All three datasets cover the same 20 patients
  expect_equal(sort(clin_ids), sort(cyto_ids))
  expect_equal(sort(clin_ids), sort(se_ids))
})
