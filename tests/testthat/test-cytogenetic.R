# tests/testthat/test-cytogenetic.R
# Tests for cytogenetic data extraction and classification

test_that("parse_cytogenetic_status handles all formats", {
  expect_equal(
    parse_cytogenetic_status(c("Yes", "No", "1", "0", "TRUE", "FALSE")),
    c("positive", "negative", "positive", "negative", "positive", "negative")
  )
  expect_equal(
    parse_cytogenetic_status(c("Positive", "Negative", "y", "n")),
    c("positive", "negative", "positive", "negative")
  )
  expect_equal(parse_cytogenetic_status(c(NA, "Unknown")), c(NA_character_, NA_character_))
  expect_equal(parse_cytogenetic_status(NULL), NA_character_)
})

test_that("classify_cytogenetic_risk classifies correctly", {
  cyto <- data.frame(
    t_4_14 = c("positive", "negative", "negative", NA),
    t_14_16 = c("negative", "negative", "negative", NA),
    del_17p = c("negative", "negative", "positive", NA),
    gain_1q = c("negative", "negative", "negative", NA),
    t_14_20 = c("negative", "negative", "negative", NA),
    stringsAsFactors = FALSE
  )

  risk <- classify_cytogenetic_risk(cyto)
  expect_equal(risk[1], "high")    # t(4;14) positive
  expect_equal(risk[2], "standard") # all negative
  expect_equal(risk[3], "high")    # del(17p) positive
  expect_true(is.na(risk[4]))      # all NA -> unknown
})

test_that("classify_cytogenetic_risk handles missing markers", {
  cyto <- data.frame(x = 1:3) # no marker columns
  risk <- classify_cytogenetic_risk(cyto)
  expect_true(all(is.na(risk)))
})

test_that("parse_commpass_barcodes extracts patient and visit", {
  barcodes <- c(
    "MMRF_1234_1_BM_CD138pos_T1",
    "MMRF_1234_2_BM_CD138pos_T1",
    "MMRF_5678_1_PB_CD138pos_T1"
  )

  parsed <- parse_commpass_barcodes(barcodes)
  expect_s3_class(parsed, "data.frame")
  expect_equal(nrow(parsed), 3)
  expect_equal(parsed$patient_id, c("1234", "1234", "5678"))
  expect_equal(parsed$visit_number, c(1L, 2L, 1L))
})

test_that("parse_commpass_barcodes returns NULL for non-CoMMpass barcodes", {
  result <- parse_commpass_barcodes(c("TCGA-AA-1234", "BRCA-5678"))
  expect_null(result)
})

test_that("build_paired_coldata identifies paired patients", {
  sample_ids <- c(
    "MMRF_1111_1_BM", "MMRF_1111_2_BM",  # paired
    "MMRF_2222_1_BM", "MMRF_2222_3_BM",  # paired
    "MMRF_3333_1_BM"                       # unpaired
  )

  clinical <- data.frame(submitter_id = "dummy")

  result <- build_paired_coldata(sample_ids, clinical)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 4) # only paired samples
  expect_true(all(c("patient_id", "visit") %in% names(result)))
  expect_equal(levels(result$visit), c("baseline", "relapsed"))
})

test_that("compute_riss classifies R-ISS stages correctly", {
  # R-ISS I: ISS I + standard risk + normal LDH

  expect_equal(compute_riss("Stage I", "Standard", ldh = 200), "R-ISS I")
  # R-ISS I: ISS I + standard risk + LDH unknown

  expect_equal(compute_riss("Stage I", "Standard", ldh = NA), "R-ISS I")

  # R-ISS III: ISS III + high risk

  expect_equal(compute_riss("Stage III", "High", ldh = 200), "R-ISS III")
  # R-ISS III: ISS III + elevated LDH
  expect_equal(compute_riss("Stage III", "Standard", ldh = 300), "R-ISS III")
  # R-ISS III: ISS III + both
  expect_equal(compute_riss("Stage III", "High", ldh = 300), "R-ISS III")

  # R-ISS II: everything else
  expect_equal(compute_riss("Stage II", "Standard", ldh = 200), "R-ISS II")
  expect_equal(compute_riss("Stage I", "High", ldh = 200), "R-ISS II")
  expect_equal(compute_riss("Stage III", "Standard", ldh = 200), "R-ISS II")

  # NA input
  expect_true(is.na(compute_riss(NA, "Standard", ldh = 200)))
})

test_that("compute_riss handles vectorized input", {
  result <- compute_riss(
    c("Stage I", "Stage III", "Stage II", NA),
    c("Standard", "High", "Standard", "Standard"),
    ldh = c(200, 300, NA, 200)
  )

  expect_equal(result, c("R-ISS I", "R-ISS III", "R-ISS II", NA))
})

test_that("compute_riss validates input lengths", {
  expect_error(compute_riss(c("Stage I", "Stage II"), "Standard"))
})

test_that("placeholder_results returns correct structure", {
  res <- placeholder_results("test_method")
  expect_type(res, "list")
  expect_equal(res$method, "test_method")
  expect_equal(res$n_deg, 0L)
  expect_s3_class(res$results_table, "data.frame")
})
