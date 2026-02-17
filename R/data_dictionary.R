# R/data_dictionary.R
# Data dictionary for CoMMpass variables
# Documents column names, types, units, and GDC sources

#' Get CoMMpass Data Dictionary
#'
#' Returns a tibble documenting all known variables in the CoMMpass dataset,
#' including clinical, biospecimen, and RNA-seq data. Each variable includes
#' its category, data type, units, description, typical range, and a link
#' to the GDC data dictionary.
#'
#' @return A tibble with columns: variable, category, data_type, units,
#'   description, typical_range, gdc_link
#' @export
#' @examples
#' dd <- get_commpass_data_dictionary()
#' # Filter to clinical variables
#' dplyr::filter(dd, category == "clinical")
get_commpass_data_dictionary <- function() {
  gdc_base <- "https://docs.gdc.cancer.gov/Data_Dictionary/viewer/#?view=table-definition-view&id="

  clinical_vars <- tibble::tribble(
    ~variable, ~data_type, ~units, ~description, ~typical_range,
    "submitter_id", "character", NA_character_,
    "Patient identifier assigned by the submitting institution (MMRF)", "MMRF_0001 to MMRF_2149",

    "project_id", "character", NA_character_,
    "GDC project identifier", "MMRF-COMMPASS",

    "age_at_diagnosis", "integer", "days",
    "Age at primary diagnosis in DAYS (divide by 365.25 for years). GDC stores all ages in days.",
    "10000-35000 (approx 27-96 years)",

    "gender", "character", NA_character_,
    "Patient sex/gender", "female, male, not reported",

    "race", "character", NA_character_,
    "Patient race category per NIH guidelines",
    "white, black or african american, asian, not reported, other",

    "ethnicity", "character", NA_character_,
    "Patient ethnicity per NIH guidelines",
    "not hispanic or latino, hispanic or latino, not reported",

    "vital_status", "character", NA_character_,
    "Patient vital status at last follow-up", "Alive, Dead, Not Reported",

    "days_to_death", "integer", "days",
    "Number of days from diagnosis to death. NA if patient is alive.", "0-5000+",

    "days_to_last_follow_up", "integer", "days",
    "Number of days from diagnosis to last follow-up. NA if patient is deceased.", "0-5000+",

    "primary_diagnosis", "character", NA_character_,
    "ICD-O-3 morphology code description for the primary diagnosis",
    "Plasma cell myeloma, Myeloma NOS",

    "disease_type", "character", NA_character_,
    "Type of disease studied", "Multiple Myeloma",

    "site_of_resection_or_biopsy", "character", NA_character_,
    "Anatomic site of tissue sample collection", "Bone marrow, Blood",

    "tissue_or_organ_of_origin", "character", NA_character_,
    "Anatomic site of the disease origin", "Bone marrow",

    "year_of_diagnosis", "integer", "year",
    "Calendar year of primary diagnosis", "2005-2020",

    "classification_of_tumor", "character", NA_character_,
    "Tumor classification", "primary, recurrence, metastasis, not reported",

    "prior_malignancy", "character", NA_character_,
    "Whether patient had a prior malignancy", "yes, no, not reported",

    "prior_treatment", "character", NA_character_,
    "Whether patient received prior treatment", "yes, no, not reported",

    "ajcc_staging_system_edition", "character", NA_character_,
    "AJCC staging edition used", "various editions",

    "days_to_last_known_disease_status", "integer", "days",
    "Days from diagnosis to last disease status assessment", "0-5000+"
  )
  clinical_vars$category <- "clinical"

  biospecimen_vars <- tibble::tribble(
    ~variable, ~data_type, ~units, ~description, ~typical_range,
    "sample_submitter_id", "character", NA_character_,
    "Sample identifier assigned by submitting institution", "MMRF_0001_1_BM, etc.",

    "sample_id", "character", NA_character_,
    "GDC-assigned UUID for the sample", "UUID format",

    "sample_type", "character", NA_character_,
    "Type of sample collected", "Primary Blood Derived Cancer - Bone Marrow, etc.",

    "sample_type_id", "character", NA_character_,
    "Numeric code for sample type", "01, 09, 10, etc.",

    "tissue_type", "character", NA_character_,
    "Whether tissue is tumor or normal", "Tumor, Normal",

    "preservation_method", "character", NA_character_,
    "Method used to preserve the sample", "FFPE, Frozen, etc.",

    "composition", "character", NA_character_,
    "Sample composition category", "Bone Marrow Components, Blood Derived"
  )
  biospecimen_vars$category <- "biospecimen"

  rnaseq_count_vars <- tibble::tribble(
    ~variable, ~data_type, ~units, ~description, ~typical_range,
    "gene_id", "character", NA_character_,
    "Ensembl gene identifier (ENSG with version)", "ENSG00000000003.15",

    "unstranded", "integer", "raw counts",
    "Unstranded read counts from STAR aligner. Use for DESeq2/edgeR analysis.", "0-1000000+",

    "stranded_first", "integer", "raw counts",
    "First-strand read counts (dUTP protocol)", "0-1000000+",

    "stranded_second", "integer", "raw counts",
    "Second-strand read counts", "0-1000000+",

    "tpm_unstranded", "numeric", "TPM",
    "Transcripts Per Million (unstranded). Normalized for gene length and sequencing depth.",
    "0-100000+",

    "fpkm_unstranded", "numeric", "FPKM",
    "Fragments Per Kilobase of transcript per Million mapped reads (unstranded).",
    "0-100000+",

    "fpkm_uq_unstranded", "numeric", "FPKM-UQ",
    "Upper quartile normalized FPKM (unstranded).", "0-100000+"
  )
  rnaseq_count_vars$category <- "rnaseq_counts"

  rnaseq_meta_vars <- tibble::tribble(
    ~variable, ~data_type, ~units, ~description, ~typical_range,
    "gene_name", "character", NA_character_,
    "HGNC gene symbol", "TP53, KRAS, MYC, etc.",

    "gene_type", "character", NA_character_,
    "Biotype from GENCODE annotation",
    "protein_coding, lncRNA, miRNA, processed_pseudogene, etc.",

    "barcode", "character", NA_character_,
    "TCGA-style barcode for the sample", "MMRF-COMMPASS-XXXX-TBM-...",

    "patient", "character", NA_character_,
    "Patient identifier extracted from barcode", "MMRF-COMMPASS-XXXX",

    "sample_type", "character", NA_character_,
    "Sample type from barcode decoding", "Primary Blood Derived Cancer - Bone Marrow"
  )
  rnaseq_meta_vars$category <- "rnaseq_metadata"

  # Combine all categories
  dd <- dplyr::bind_rows(
    clinical_vars,
    biospecimen_vars,
    rnaseq_count_vars,
    rnaseq_meta_vars
  )

  # Add GDC links
  dd$gdc_link <- dplyr::case_when(
    dd$category == "clinical" ~
      paste0(gdc_base, "clinical"),
    dd$category == "biospecimen" ~
      paste0(gdc_base, "sample"),
    dd$category %in% c("rnaseq_counts", "rnaseq_metadata") ~
      "https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/",
    TRUE ~ NA_character_
  )

  # Reorder columns
  dd <- dd[, c("variable", "category", "data_type", "units", "description",
               "typical_range", "gdc_link")]

  tibble::as_tibble(dd)
}

#' Get Extended Documentation for a Variable
#'
#' Returns detailed documentation for a specific variable, including
#' scientific context, calculation methods, and usage notes.
#'
#' @param variable Character string naming the variable to document
#' @return A list with elements: variable, description, scientific_context,
#'   calculation, usage_notes, references
#' @export
#' @examples
#' docs <- get_variable_docs("age_at_diagnosis")
#' cat(docs$usage_notes)
get_variable_docs <- function(variable) {
  docs <- list(
    age_at_diagnosis = list(
      variable = "age_at_diagnosis",
      description = "Patient age at primary diagnosis, stored in DAYS by GDC.",
      scientific_context = paste(
        "Multiple myeloma is predominantly a disease of older adults.",
        "Median age at diagnosis is ~69 years. Younger patients (<65) may",
        "be eligible for autologous stem cell transplant."
      ),
      calculation = "To convert to years: age_years = age_at_diagnosis / 365.25",
      usage_notes = paste(
        "CRITICAL: GDC stores age in DAYS, not years.",
        "Always divide by 365.25 before analysis or display.",
        "Values typically range from ~10,000 to ~35,000 days."
      ),
      references = c(
        "GDC Data Dictionary: https://docs.gdc.cancer.gov/Data_Dictionary/viewer/",
        "MMRF CoMMpass Study: https://themmrf.org/research/commpass-study/"
      )
    ),

    days_to_death = list(
      variable = "days_to_death",
      description = "Days from diagnosis to death.",
      scientific_context = paste(
        "Primary endpoint for overall survival analysis.",
        "Median OS for myeloma has improved significantly with novel therapies."
      ),
      calculation = "Used directly in survival::Surv(days_to_death, vital_status == 'Dead')",
      usage_notes = paste(
        "NA for patients who are alive (censored).",
        "Use days_to_last_follow_up for censoring time."
      ),
      references = c(
        "GDC Data Dictionary: https://docs.gdc.cancer.gov/Data_Dictionary/viewer/"
      )
    ),

    unstranded = list(
      variable = "unstranded",
      description = "Unstranded raw read counts from STAR aligner.",
      scientific_context = paste(
        "Raw counts are the preferred input for differential expression",
        "tools like DESeq2 and edgeR, which model count data with",
        "negative binomial distributions."
      ),
      calculation = paste(
        "Generated by STAR aligner quantMode GeneCounts.",
        "Counts reads mapping to GENCODE gene annotations."
      ),
      usage_notes = paste(
        "Use raw counts (not TPM/FPKM) for DESeq2/edgeR.",
        "TPM is preferred for comparing expression across samples.",
        "FPKM is largely deprecated in favor of TPM."
      ),
      references = c(
        "GDC mRNA Pipeline: https://docs.gdc.cancer.gov/Data/Bioinformatics_Pipelines/Expression_mRNA_Pipeline/",
        "STAR aligner: https://github.com/alexdobin/STAR"
      )
    )
  )

  if (!variable %in% names(docs)) {
    # Return basic info from the dictionary
    dd <- get_commpass_data_dictionary()
    row <- dd[dd$variable == variable, ]
    if (nrow(row) == 0) {
      cli::cli_abort(c(
        "x" = "Variable {.val {variable}} not found in data dictionary.",
        "i" = "Use {.fn get_commpass_data_dictionary} to see all variables."
      ))
    }
    return(list(
      variable = variable,
      description = row$description,
      scientific_context = "See GDC data dictionary for details.",
      calculation = NA_character_,
      usage_notes = paste("Category:", row$category, "| Type:", row$data_type),
      references = row$gdc_link
    ))
  }

  docs[[variable]]
}
