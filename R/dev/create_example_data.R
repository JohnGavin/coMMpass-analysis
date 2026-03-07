# R/dev/create_example_data.R
# Reproducible generation of example datasets for coMMpass pipeline testing
#
# Usage:
#   source("R/dev/create_example_data.R")
#   create_all_example_data()
#
# The rnaseq_se.rds stores plain-R components (matrix + data.frames) rather
# than a serialised SummarizedExperiment S4 object.  example_data()
# reconstructs the SE at load time, so creation needs no Bioconductor
# packages and works on any platform.

#' Create all example datasets and save to inst/extdata/example/
#'
#' Generates small synthetic datasets that exercise the full coMMpass pipeline:
#' - rnaseq_se.rds: list(counts, rowData, colData) — plain R objects
#' - clinical.rds: clinical data frame (20 patients)
#' - cytogenetic.rds: cytogenetic markers data frame (20 patients)
#'
#' @param outdir Directory to write RDS files (default: inst/extdata/example/)
#' @return Invisible list of created objects
create_all_example_data <- function(
    outdir = here::here("inst", "extdata", "example")
) {
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

  set.seed(42)
  n_genes <- 50L
  n_samples <- 20L

  patient_ids <- sprintf("MMRF_%04d", seq_len(n_samples))

  # --- 1. RNA-seq components (plain R, no S4) ---
  se_parts <- create_example_se_parts(n_genes, n_samples, patient_ids)
  saveRDS(se_parts, file.path(outdir, "rnaseq_se.rds"))

  # --- 2. Clinical data ---
  clinical <- create_example_clinical(patient_ids)
  saveRDS(clinical, file.path(outdir, "clinical.rds"))

  # --- 3. Cytogenetic data ---
  cytogenetic <- create_example_cytogenetic(patient_ids)
  saveRDS(cytogenetic, file.path(outdir, "cytogenetic.rds"))

  # --- 4. Treatment data ---
  treatment <- create_example_treatment(patient_ids)
  saveRDS(treatment, file.path(outdir, "treatment.rds"))

  files <- c("rnaseq_se.rds", "clinical.rds", "cytogenetic.rds", "treatment.rds")
  sizes <- vapply(file.path(outdir, files), file.size, numeric(1))
  cat(sprintf(
    "Created %d files in %s (%s bytes total)\n",
    length(sizes), outdir, sum(sizes)
  ))

  invisible(list(
    rnaseq_se_parts = se_parts,
    clinical = clinical,
    cytogenetic = cytogenetic,
    treatment = treatment
  ))
}


# --- Helper: SE components as plain R objects ---
create_example_se_parts <- function(n_genes, n_samples, patient_ids) {
  # Gene IDs: Ensembl-format with version suffixes to exercise stripping logic
  gene_ids <- sprintf(
    "ENSG%011d.%d",
    seq_len(n_genes),
    sample(1:15, n_genes, replace = TRUE)
  )

  # Mix of biotypes to exercise count distribution plot
  biotypes <- c(
    rep("protein_coding", 30),
    rep("lncRNA", 10),
    rep("miRNA", 5),
    rep("pseudogene", 3),
    rep("rRNA", 2)
  )

  sample_ids <- sprintf("TCGA-AB-%04d-01A", seq_len(n_samples))

  # NB-distributed counts: realistic RNA-seq shape
  gene_means <- exp(rnorm(n_genes, mean = 3, sd = 2))
  counts <- matrix(
    stats::rnbinom(n_genes * n_samples, mu = gene_means, size = 5),
    nrow = n_genes, ncol = n_samples,
    dimnames = list(gene_ids, sample_ids)
  )

  # Ensure a few zero-count genes for edge case coverage
  counts[1:3, ] <- 0L

  row_data <- data.frame(
    gene_id = gene_ids,
    gene_type = biotypes,
    stringsAsFactors = FALSE,
    row.names = gene_ids
  )

  col_data <- data.frame(
    submitter_id = patient_ids,
    sample_type = sample(
      c("Primary Tumor", "Recurrent Tumor"),
      n_samples,
      replace = TRUE,
      prob = c(0.85, 0.15)
    ),
    stringsAsFactors = FALSE,
    row.names = sample_ids
  )

  list(counts = counts, rowData = row_data, colData = col_data)
}


# --- Helper: Clinical data ---
create_example_clinical <- function(patient_ids) {
  n <- length(patient_ids)
  is_dead <- sample(c(TRUE, FALSE), n, replace = TRUE, prob = c(0.4, 0.6))

  # ISS stage (needed to correlate b2m/albumin)
  iss <- sample(
    c("Stage I", "Stage II", "Stage III", NA),
    n, replace = TRUE, prob = c(0.3, 0.35, 0.25, 0.1)
  )

  # B2M and albumin correlated with ISS stage
  # ISS I: b2m < 3.5 & albumin >= 3.5

  # ISS III: b2m >= 5.5
  b2m_base <- ifelse(iss == "Stage I", 2.5, ifelse(iss == "Stage III", 7, 4))
  b2m_base[is.na(b2m_base)] <- 4
  albumin_base <- ifelse(iss == "Stage I", 4.0, ifelse(iss == "Stage III", 3.0, 3.5))
  albumin_base[is.na(albumin_base)] <- 3.5

  data.frame(
    submitter_id = patient_ids,
    vital_status = ifelse(is_dead, "Dead", "Alive"),
    days_to_death = ifelse(
      is_dead, as.integer(abs(rnorm(n, 800, 300))), NA_integer_
    ),
    days_to_last_follow_up = ifelse(
      !is_dead, as.integer(abs(rnorm(n, 1200, 400))), NA_integer_
    ),
    age_at_diagnosis = as.integer(rnorm(n, 65, 10) * 365.25),
    gender = sample(c("male", "female"), n, replace = TRUE),
    iss_stage = iss,
    heavy_chain = sample(
      c("IgG", "IgA", "IgD", "Light chain only"),
      n, replace = TRUE, prob = c(0.57, 0.20, 0.02, 0.21)
    ),
    light_chain = sample(
      c("Kappa", "Lambda"), n, replace = TRUE, prob = c(0.65, 0.35)
    ),
    ecog_status = sample(0:4, n, replace = TRUE,
                          prob = c(0.25, 0.40, 0.20, 0.10, 0.05)),
    ldh = round(rnorm(n, 200, 60)),
    b2m = round(pmax(0.5, b2m_base + rnorm(n, 0, 1)), 1),
    albumin = round(pmax(1.5, albumin_base + rnorm(n, 0, 0.4)), 1),
    flc_kappa = round(pmax(1, rlnorm(n, 2.5, 0.8)), 1),
    flc_lambda = round(pmax(1, rlnorm(n, 2.0, 0.6)), 1),
    hemoglobin = round(pmax(5, rnorm(n, 11, 1.5)), 1),
    creatinine = round(pmax(0.3, rnorm(n, 1.0, 0.4)), 2),
    calcium = round(pmax(7, rnorm(n, 9.5, 0.8)), 1),
    platelets = as.integer(pmax(20, rnorm(n, 200, 60))),
    stringsAsFactors = FALSE
  )
}


# --- Helper: Cytogenetic data ---
create_example_cytogenetic <- function(patient_ids) {
  n <- length(patient_ids)
  marker <- function(prob = 0.2) {
    sample(c("Yes", "No"), n, replace = TRUE, prob = c(prob, 1 - prob))
  }

  cyto <- data.frame(
    patient_id = patient_ids,
    t_4_14 = marker(0.15),
    t_11_14 = marker(0.20),
    t_14_16 = marker(0.05),
    del_17p = marker(0.10),
    gain_1q = marker(0.25),
    stringsAsFactors = FALSE
  )

  # Derive risk group from markers
  high_risk <- cyto$t_4_14 == "Yes" |
    cyto$del_17p == "Yes" |
    cyto$t_14_16 == "Yes"
  cyto$risk_group <- ifelse(high_risk, "High", "Standard")

  cyto
}


# --- Helper: Treatment data ---
create_example_treatment <- function(patient_ids) {
  n <- length(patient_ids)

  # Each patient gets 1-3 treatment lines
  rows <- lapply(patient_ids, function(pid) {
    n_lines <- sample(1:3, 1, prob = c(0.4, 0.35, 0.25))
    regimens <- c("VRd", "Rd", "Kd", "DaraVd", "Pd", "Mel", "KRd", "Vd")
    responses <- c("sCR", "CR", "VGPR", "PR", "MR", "SD", "PD")

    lapply(seq_len(n_lines), function(line) {
      data.frame(
        public_id = pid,
        line = line,
        trtshnm = sample(regimens, 1),
        bestrespassess = sample(responses, 1,
          prob = c(0.05, 0.15, 0.25, 0.25, 0.10, 0.10, 0.10)),
        sct_flag = if (line == 1) sample(c("Yes", "No"), 1, prob = c(0.3, 0.7)) else "No",
        trtstdy = as.integer(cumsum(c(0, rep(180, line - 1)))[line]),
        stringsAsFactors = FALSE
      )
    })
  })

  do.call(rbind, unlist(rows, recursive = FALSE))
}
