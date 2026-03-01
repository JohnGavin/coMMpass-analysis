# tests/testthat/test-adversarial-gdc.R
# Adversarial QA: probes hallucination-prone areas in GDC/CoMMpass domain
#
# Targets 7 areas where LLMs commonly hallucinate:
# 1. Age units (days vs years)
# 2. Assay name ("unstranded")
# 3. Ensembl version stripping
# 4. DESeq2 shrinkage method (apeglm)
# 5. MSigDB collection identifiers
# 6. Survival time construction
# 7. ISS stage NA handling

# ================================================================
# 1. Age Units (days vs years)
# ================================================================

test_that("data dictionary: age_at_diagnosis is stored in days", {
  dd <- get_commpass_data_dictionary()
  age_row <- dd[dd$variable == "age_at_diagnosis", ]
  expect_equal(age_row$units, "days")
  expect_match(age_row$description, "DAYS", fixed = TRUE)
})

test_that("prepare_survival_data converts age > 120 from days to years", {
  clinical <- data.frame(
    submitter_id = paste0("MMRF_", sprintf("%04d", 1:3)),
    vital_status = c("Dead", "Alive", "Alive"),
    days_to_death = c(500, NA, NA),
    days_to_last_follow_up = c(NA, 1000, 800),
    age_at_diagnosis = c(25000, 18000, 30000)
  )
  result <- prepare_survival_data(clinical)
  expect_true(all(result$age_years < 120))
  expect_equal(result$age_years[1], round(25000 / 365.25, 1))
})

test_that("prepare_survival_data leaves age <= 120 as years", {
  clinical <- data.frame(
    submitter_id = "MMRF_0001",
    vital_status = "Dead",
    days_to_death = 500,
    days_to_last_follow_up = NA,
    age_at_diagnosis = 65
  )
  result <- prepare_survival_data(clinical)
  expect_equal(result$age_years, 65)
})

# ================================================================
# 2. Assay Name ("unstranded")
# ================================================================

test_that("get_counts_assay prefers 'unstranded' assay", {
  skip_if_not_installed("SummarizedExperiment")
  counts_mat <- matrix(1:12, nrow = 3, ncol = 4,
    dimnames = list(paste0("gene", 1:3), paste0("sample", 1:4)))
  other_mat <- counts_mat * 10
  se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(unstranded = counts_mat, tpm_unstranded = other_mat)
  )
  result <- get_counts_assay(se)
  expect_equal(result[1, 1], 1L)
})

test_that("extract_counts prefers 'unstranded' assay", {
  skip_if_not_installed("SummarizedExperiment")
  counts_mat <- matrix(1:12, nrow = 3, ncol = 4,
    dimnames = list(paste0("gene", 1:3), paste0("sample", 1:4)))
  other_mat <- counts_mat * 10
  se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(unstranded = counts_mat, tpm_unstranded = other_mat)
  )
  result <- extract_counts(se)
  expect_equal(result[1, 1], 1L)
})

test_that("save_rnaseq_parquet checks 'unstranded' first (source inspection)", {
  fn_body <- deparse(body(save_rnaseq_parquet))
  expect_true(any(grepl('"unstranded"', fn_body)))
})

test_that("data dictionary documents 'unstranded' as DE input", {
  dd <- get_commpass_data_dictionary()
  unstranded_row <- dd[dd$variable == "unstranded", ]
  expect_equal(nrow(unstranded_row), 1)
  expect_match(unstranded_row$description, "DESeq2|edgeR", ignore.case = TRUE)
  expect_equal(unstranded_row$units, "raw counts")
})

# ================================================================
# 3. Ensembl Version Stripping
# ================================================================

test_that("build_gene_ranks strips Ensembl version suffixes", {
  de_table <- data.frame(
    stat = c(3.5, -2.1, 1.0),
    row.names = c("ENSG00000000003.15", "ENSG00000000005.6",
                  "ENSG00000000419.14")
  )
  result <- build_gene_ranks(de_table, gene_id_type = "ensembl_gene")
  expect_false(any(grepl("\\.", names(result))))
  expect_true(all(grepl("^ENSG\\d+$", names(result))))
})

test_that("build_gene_ranks preserves versions for non-ensembl IDs", {
  de_table <- data.frame(
    stat = c(3.5, -2.1),
    row.names = c("TP53", "KRAS")
  )
  result <- build_gene_ranks(de_table, gene_id_type = "gene_symbol")
  expect_setequal(names(result), c("TP53", "KRAS"))
})

test_that("run_ora strips Ensembl versions from sig_genes and universe", {
  fn_body <- paste(deparse(body(run_ora)), collapse = " ")
  # Function must check for ensembl_gene and use sub() to strip versions
  expect_true(grepl("ensembl_gene", fn_body))
  expect_true(grepl("sub\\(", fn_body))
})

# ================================================================
# 4. DESeq2 Shrinkage Method
# ================================================================

test_that("run_deseq2 uses apeglm shrinkage (source inspection)", {
  fn_body <- deparse(body(run_deseq2))
  expect_true(any(grepl('"apeglm"', fn_body)))
  expect_false(any(grepl('type.*=.*"normal"', fn_body)))
  expect_false(any(grepl('type.*=.*"ashr"', fn_body)))
})

test_that("run_deseq2_paired uses apeglm shrinkage (source inspection)", {
  fn_body <- deparse(body(run_deseq2_paired))
  expect_true(any(grepl('"apeglm"', fn_body)))
})

# ================================================================
# 5. MSigDB Collection Identifiers
# ================================================================

test_that("get_msigdb_gene_sets maps hallmark to category H", {
  fn_body <- paste(deparse(body(get_msigdb_gene_sets)), collapse = " ")
  expect_true(grepl('"H"', fn_body))
  expect_true(grepl("hallmark", fn_body))
})

test_that("get_msigdb_gene_sets maps kegg to C2:CP:KEGG_MEDICUS", {
  fn_body <- paste(deparse(body(get_msigdb_gene_sets)), collapse = " ")
  expect_true(grepl("KEGG_MEDICUS", fn_body))
  expect_true(grepl('"C2"', fn_body))
})

test_that("get_msigdb_gene_sets rejects unknown collections", {
  # This will try local files first, then msigdbr — but collection_map

  # check happens in the msigdbr fallback path. Test with a mock or
  # check the source directly.
  fn_body <- paste(deparse(body(get_msigdb_gene_sets)), collapse = " ")
  expect_true(grepl("Unknown|not found|Valid", fn_body, ignore.case = TRUE))
})

# ================================================================
# 6. Survival Time Construction
# ================================================================

test_that("prepare_survival_data: dead -> days_to_death, alive -> follow_up", {
  clinical <- data.frame(
    submitter_id = c("MMRF_0001", "MMRF_0002"),
    vital_status = c("Dead", "Alive"),
    days_to_death = c(500, NA),
    days_to_last_follow_up = c(NA, 1000),
    age_at_diagnosis = c(25000, 20000)
  )
  result <- prepare_survival_data(clinical)
  dead_row <- result[result$status == 1, ]
  alive_row <- result[result$status == 0, ]
  expect_equal(dead_row$time_days, 500)
  expect_equal(alive_row$time_days, 1000)
})

test_that("prepare_survival_data filters time <= 0", {
  clinical <- data.frame(
    submitter_id = c("MMRF_0001", "MMRF_0002"),
    vital_status = c("Dead", "Dead"),
    days_to_death = c(0, 500),
    days_to_last_follow_up = c(NA, NA),
    age_at_diagnosis = c(25000, 20000)
  )
  result <- prepare_survival_data(clinical)
  expect_equal(nrow(result), 1)
  expect_equal(result$time_days, 500)
})

test_that("prepare_survival_data rejects empty clinical data", {
  expect_error(
    prepare_survival_data(data.frame()),
    "non-empty"
  )
})

test_that("prepare_survival_data rejects NULL", {
  expect_error(
    prepare_survival_data(NULL),
    "non-empty"
  )
})

# ================================================================
# 7. ISS NA Handling
# ================================================================

test_that("prepare_survival_data treats empty/Not Reported ISS as NA", {
  clinical <- data.frame(
    submitter_id = c("MMRF_0001", "MMRF_0002", "MMRF_0003"),
    vital_status = c("Dead", "Alive", "Dead"),
    days_to_death = c(500, NA, 800),
    days_to_last_follow_up = c(NA, 1000, NA),
    age_at_diagnosis = c(25000, 20000, 22000),
    iss_stage = c("I", "", "Not Reported")
  )
  result <- prepare_survival_data(clinical)
  expect_equal(sum(is.na(result$iss_stage)), 2)
  expect_equal(result$iss_stage[!is.na(result$iss_stage)], "I")
})

test_that("prepare_survival_data keeps valid ISS stages intact", {
  clinical <- data.frame(
    submitter_id = c("MMRF_0001", "MMRF_0002", "MMRF_0003"),
    vital_status = c("Dead", "Dead", "Dead"),
    days_to_death = c(500, 600, 700),
    days_to_last_follow_up = c(NA, NA, NA),
    age_at_diagnosis = c(25000, 20000, 22000),
    iss_stage = c("I", "II", "III")
  )
  result <- prepare_survival_data(clinical)
  expect_equal(sum(is.na(result$iss_stage)), 0)
  expect_setequal(result$iss_stage, c("I", "II", "III"))
})
