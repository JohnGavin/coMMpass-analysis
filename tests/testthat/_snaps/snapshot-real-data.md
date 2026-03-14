# clinical_data_clean structure snapshot

    Code
      print(sort(names(df)))
    Output
       [1] "age_at_diagnosis"                        
       [2] "age_at_diagnosis_years"                  
       [3] "age_at_index"                            
       [4] "ajcc_clinical_m"                         
       [5] "ajcc_clinical_n"                         
       [6] "ajcc_clinical_stage"                     
       [7] "ajcc_clinical_t"                         
       [8] "ajcc_pathologic_m"                       
       [9] "ajcc_pathologic_n"                       
      [10] "ajcc_pathologic_stage"                   
      [11] "ajcc_pathologic_t"                       
      [12] "ajcc_staging_system_edition"             
      [13] "ann_arbor_b_symptoms"                    
      [14] "ann_arbor_clinical_stage"                
      [15] "ann_arbor_extranodal_involvement"        
      [16] "ann_arbor_pathologic_stage"              
      [17] "best_overall_response"                   
      [18] "burkitt_lymphoma_clinical_variant"       
      [19] "cause_of_death"                          
      [20] "child_pugh_classification"               
      [21] "classification_of_tumor"                 
      [22] "cog_liver_stage"                         
      [23] "cog_neuroblastoma_risk_group"            
      [24] "cog_renal_stage"                         
      [25] "cog_rhabdomyosarcoma_risk_group"         
      [26] "created_datetime"                        
      [27] "days_to_best_overall_response"           
      [28] "days_to_birth"                           
      [29] "days_to_death"                           
      [30] "days_to_diagnosis"                       
      [31] "days_to_last_follow_up"                  
      [32] "days_to_last_known_disease_status"       
      [33] "days_to_recurrence"                      
      [34] "demographic_id"                          
      [35] "diagnosis_id"                            
      [36] "disease_type"                            
      [37] "enneking_msts_grade"                     
      [38] "enneking_msts_metastasis"                
      [39] "enneking_msts_stage"                     
      [40] "enneking_msts_tumor_site"                
      [41] "esophageal_columnar_dysplasia_degree"    
      [42] "esophageal_columnar_metaplasia_present"  
      [43] "ethnicity"                               
      [44] "figo_stage"                              
      [45] "first_symptom_prior_to_diagnosis"        
      [46] "gastric_esophageal_junction_involvement" 
      [47] "gender"                                  
      [48] "goblet_cells_columnar_mucosa_present"    
      [49] "icd_10_code"                             
      [50] "inpc_grade"                              
      [51] "inpc_histologic_group"                   
      [52] "inrg_stage"                              
      [53] "inss_stage"                              
      [54] "irs_group"                               
      [55] "irs_stage"                               
      [56] "ishak_fibrosis_score"                    
      [57] "iss_stage"                               
      [58] "last_known_disease_status"               
      [59] "laterality"                              
      [60] "medulloblastoma_molecular_classification"
      [61] "metastasis_at_diagnosis"                 
      [62] "method_of_diagnosis"                     
      [63] "mitosis_karyorrhexis_index"              
      [64] "morphology"                              
      [65] "n_missing"                               
      [66] "percent_missing"                         
      [67] "primary_diagnosis"                       
      [68] "primary_site"                            
      [69] "prior_malignancy"                        
      [70] "prior_treatment"                         
      [71] "progression_or_recurrence"               
      [72] "project"                                 
      [73] "race"                                    
      [74] "residual_disease"                        
      [75] "site_of_resection_or_biopsy"             
      [76] "state"                                   
      [77] "submitter_id"                            
      [78] "submitter_id_1"                          
      [79] "submitter_id_2"                          
      [80] "submitter_sample_ids"                    
      [81] "supratentorial_localization"             
      [82] "synchronous_malignancy"                  
      [83] "tissue_or_organ_of_origin"               
      [84] "tumor_confined_to_organ_of_origin"       
      [85] "tumor_grade"                             
      [86] "updated_datetime"                        
      [87] "vital_status"                            
      [88] "wilms_tumor_histologic_subtype"          
      [89] "year_of_birth"                           
      [90] "year_of_death"                           
      [91] "year_of_diagnosis"                       
    Code
      print((function(x) sort(names(x)))(sapply(df, class)))
    Output
       [1] "age_at_diagnosis"                        
       [2] "age_at_diagnosis_years"                  
       [3] "age_at_index"                            
       [4] "ajcc_clinical_m"                         
       [5] "ajcc_clinical_n"                         
       [6] "ajcc_clinical_stage"                     
       [7] "ajcc_clinical_t"                         
       [8] "ajcc_pathologic_m"                       
       [9] "ajcc_pathologic_n"                       
      [10] "ajcc_pathologic_stage"                   
      [11] "ajcc_pathologic_t"                       
      [12] "ajcc_staging_system_edition"             
      [13] "ann_arbor_b_symptoms"                    
      [14] "ann_arbor_clinical_stage"                
      [15] "ann_arbor_extranodal_involvement"        
      [16] "ann_arbor_pathologic_stage"              
      [17] "best_overall_response"                   
      [18] "burkitt_lymphoma_clinical_variant"       
      [19] "cause_of_death"                          
      [20] "child_pugh_classification"               
      [21] "classification_of_tumor"                 
      [22] "cog_liver_stage"                         
      [23] "cog_neuroblastoma_risk_group"            
      [24] "cog_renal_stage"                         
      [25] "cog_rhabdomyosarcoma_risk_group"         
      [26] "created_datetime"                        
      [27] "days_to_best_overall_response"           
      [28] "days_to_birth"                           
      [29] "days_to_death"                           
      [30] "days_to_diagnosis"                       
      [31] "days_to_last_follow_up"                  
      [32] "days_to_last_known_disease_status"       
      [33] "days_to_recurrence"                      
      [34] "demographic_id"                          
      [35] "diagnosis_id"                            
      [36] "disease_type"                            
      [37] "enneking_msts_grade"                     
      [38] "enneking_msts_metastasis"                
      [39] "enneking_msts_stage"                     
      [40] "enneking_msts_tumor_site"                
      [41] "esophageal_columnar_dysplasia_degree"    
      [42] "esophageal_columnar_metaplasia_present"  
      [43] "ethnicity"                               
      [44] "figo_stage"                              
      [45] "first_symptom_prior_to_diagnosis"        
      [46] "gastric_esophageal_junction_involvement" 
      [47] "gender"                                  
      [48] "goblet_cells_columnar_mucosa_present"    
      [49] "icd_10_code"                             
      [50] "inpc_grade"                              
      [51] "inpc_histologic_group"                   
      [52] "inrg_stage"                              
      [53] "inss_stage"                              
      [54] "irs_group"                               
      [55] "irs_stage"                               
      [56] "ishak_fibrosis_score"                    
      [57] "iss_stage"                               
      [58] "last_known_disease_status"               
      [59] "laterality"                              
      [60] "medulloblastoma_molecular_classification"
      [61] "metastasis_at_diagnosis"                 
      [62] "method_of_diagnosis"                     
      [63] "mitosis_karyorrhexis_index"              
      [64] "morphology"                              
      [65] "n_missing"                               
      [66] "percent_missing"                         
      [67] "primary_diagnosis"                       
      [68] "primary_site"                            
      [69] "prior_malignancy"                        
      [70] "prior_treatment"                         
      [71] "progression_or_recurrence"               
      [72] "project"                                 
      [73] "race"                                    
      [74] "residual_disease"                        
      [75] "site_of_resection_or_biopsy"             
      [76] "state"                                   
      [77] "submitter_id"                            
      [78] "submitter_id_1"                          
      [79] "submitter_id_2"                          
      [80] "submitter_sample_ids"                    
      [81] "supratentorial_localization"             
      [82] "synchronous_malignancy"                  
      [83] "tissue_or_organ_of_origin"               
      [84] "tumor_confined_to_organ_of_origin"       
      [85] "tumor_grade"                             
      [86] "updated_datetime"                        
      [87] "vital_status"                            
      [88] "wilms_tumor_histologic_subtype"          
      [89] "year_of_birth"                           
      [90] "year_of_death"                           
      [91] "year_of_diagnosis"                       
    Code
      cat("Dimensions:", nrow(df), "x", ncol(df), "\n")
    Output
      Dimensions: 995 x 91 

# clinical_data_clean boundaries snapshot

    Code
      (function(r) cat("age_at_diagnosis_years:", r[1], "to", r[2], "\n"))(range(df$
        age_at_diagnosis_years, na.rm = TRUE))
    Output
      age_at_diagnosis_years: 27.8 to 89.8 
    Code
      (function(n) cat("Unique patients:", n, "\n"))(length(unique(df$submitter_id)))
    Output
      Unique patients: 995 
    Code
      print(sort(table(df$gender, useNA = "ifany")))
    Output
      
      female   male 
         393    602 
    Code
      print(sort(table(df$vital_status, useNA = "ifany")))
    Output
      
       dead alive 
        191   804 

# survival_data structure snapshot

    Code
      print(sort(names(df)))
    Output
       [1] "age_years"  "del_17p"    "del_1p"     "gain_1q"    "gender"    
       [6] "iss_stage"  "patient_id" "risk_group" "status"     "t_11_14"   
      [11] "t_14_16"    "t_14_20"    "t_4_14"     "time_days" 
    Code
      print((function(x) sort(names(x)))(sapply(df, class)))
    Output
       [1] "age_years"  "del_17p"    "del_1p"     "gain_1q"    "gender"    
       [6] "iss_stage"  "patient_id" "risk_group" "status"     "t_11_14"   
      [11] "t_14_16"    "t_14_20"    "t_4_14"     "time_days" 
    Code
      cat("Dimensions:", nrow(df), "x", ncol(df), "\n")
    Output
      Dimensions: 994 x 14 

# survival_data boundaries snapshot

    Code
      (function(r) cat("time range:", r[1], "to", r[2], "\n"))(range(df$time, na.rm = TRUE))
    Output
      time range: 1 to 1984 
    Code
      print(table(df$status, useNA = "ifany"))
    Output
      
        0   1 
      803 191 
    Code
      print(sort(table(df$risk_group, useNA = "ifany")))
    Output
      <NA> 
       994 

# deseq2_results structure snapshot

    Code
      cat("class:", paste(class(res), collapse = ", "), "\n")
    Output
      class: list 
    Code
      cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    Output
      names: design, method, n_deg, paired, results_shrunk, results_table, shrinkage_coef 
    Code
      cat("method:", res$method, "\n")
    Output
      method: DESeq2 
    Code
      cat("n_deg:", res$n_deg, "\n")
    Output
      n_deg: 1615 
    Code
      cat("results_table cols:", paste(names(res$results_table), collapse = ", "),
      "\n")
    Output
      results_table cols: baseMean, log2FoldChange, lfcSE, stat, pvalue, padj 
    Code
      cat("results_table nrow:", nrow(res$results_table), "\n")
    Output
      results_table nrow: 30675 

# deseq2_results significance snapshot

    Code
      sig <- sum(res$results_table$padj < 0.05, na.rm = TRUE)
      cat("Significant (padj < 0.05):", sig, "\n")
    Output
      Significant (padj < 0.05): 1615 
    Code
      (function(r) cat("log2FC range:", r[1], "to", r[2], "\n"))(range(res$
        results_table$log2FC, na.rm = TRUE))
    Condition
      Warning in `min()`:
      no non-missing arguments to min; returning Inf
      Warning in `max()`:
      no non-missing arguments to max; returning -Inf
    Output
      log2FC range: Inf to -Inf 

# edger_results structure snapshot

    Code
      cat("class:", paste(class(res), collapse = ", "), "\n")
    Output
      class: list 
    Code
      cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    Output
      names: design, method, n_deg, results_table 
    Code
      cat("method:", res$method, "\n")
    Output
      method: edgeR 
    Code
      cat("n_deg:", res$n_deg, "\n")
    Output
      n_deg: 3738 
    Code
      cat("results_table cols:", paste(names(res$results_table), collapse = ", "),
      "\n")
    Output
      results_table cols: logFC, logCPM, F, PValue, FDR 
    Code
      cat("results_table nrow:", nrow(res$results_table), "\n")
    Output
      results_table nrow: 30675 

# edger_results significance snapshot

    Code
      sig <- sum(res$results_table$padj < 0.05, na.rm = TRUE)
      cat("Significant (padj < 0.05):", sig, "\n")
    Output
      Significant (padj < 0.05): 0 
    Code
      (function(r) cat("log2FC range:", r[1], "to", r[2], "\n"))(range(res$
        results_table$log2FC, na.rm = TRUE))
    Condition
      Warning in `min()`:
      no non-missing arguments to min; returning Inf
      Warning in `max()`:
      no non-missing arguments to max; returning -Inf
    Output
      log2FC range: Inf to -Inf 

# limma_results structure snapshot

    Code
      cat("class:", paste(class(res), collapse = ", "), "\n")
    Output
      class: list 
    Code
      cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    Output
      names: design, method, n_deg, results_table 
    Code
      cat("method:", res$method, "\n")
    Output
      method: limma 
    Code
      cat("n_deg:", res$n_deg, "\n")
    Output
      n_deg: 159 
    Code
      cat("results_table cols:", paste(names(res$results_table), collapse = ", "),
      "\n")
    Output
      results_table cols: logFC, AveExpr, t, P.Value, adj.P.Val, B 
    Code
      cat("results_table nrow:", nrow(res$results_table), "\n")
    Output
      results_table nrow: 30675 

# gsea_results structure snapshot

    Code
      cat("class:", paste(class(res), collapse = ", "), "\n")
    Output
      class: list 
    Code
      cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    Output
      names: n_enriched_negative, n_enriched_positive, n_gene_sets, top_gene_sets 
    Code
      cat("n_gene_sets:", res$n_gene_sets, "\n")
    Output
      n_gene_sets: 50 
    Code
      cat("n_enriched_positive:", res$n_enriched_positive, "\n")
    Output
      n_enriched_positive: 20 
    Code
      cat("n_enriched_negative:", res$n_enriched_negative, "\n")
    Output
      n_enriched_negative: 15 
    Code
      cat("top_gene_sets cols:", paste(names(res$top_gene_sets), collapse = ", "),
      "\n")
    Output
      top_gene_sets cols: gene_set, NES, p_value, q_value 
    Code
      cat("top_gene_sets nrow:", nrow(res$top_gene_sets), "\n")
    Output
      top_gene_sets nrow: 10 

# gsea_results top pathways snapshot

    Code
      (function(df) {
        cat("Top 5 gene sets by q_value:\n")
        for (i in seq_len(nrow(df))) {
          cat("  ", df$gene_set[i], "NES:", df$NES[i], "q:", df$q_value[i], "\n")
        }
      })(head((function(df) df[order(df$q_value), ])(res$top_gene_sets), 5))
    Output
      Top 5 gene sets by q_value:
         GeneSet_1 NES: -2.876098 q: 0.01091479 
         GeneSet_4 NES: 4.011644 q: 0.02688227 
         GeneSet_2 NES: 3.441212 q: 0.02746081 
         GeneSet_10 NES: -1.181647 q: 0.05489305 
         GeneSet_8 NES: 0.3790107 q: 0.06486528 

# cox_model structure snapshot

    Code
      cat("class:", paste(class(res), collapse = ", "), "\n")
    Output
      class: list 
    Code
      cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    Output
      names: concordance, covariates, hazard_ratios, n_samples 
    Code
      cat("covariates:", paste(res$covariates, collapse = ", "), "\n")
    Output
      covariates: age, stage, gene_signature 
    Code
      cat("n_samples:", res$n_samples, "\n")
    Output
      n_samples: 100 
    Code
      cat("concordance:", round(res$concordance, 4), "\n")
    Output
      concordance: 0.75 
    Code
      cat("hazard_ratios cols:", paste(names(res$hazard_ratios), collapse = ", "),
      "\n")
    Output
      hazard_ratios cols: variable, HR, p_value 
    Code
      cat("hazard_ratios nrow:", nrow(res$hazard_ratios), "\n")
    Output
      hazard_ratios nrow: 3 

# cox_model hazard ratios snapshot

    Code
      (function(df) {
        for (i in seq_len(nrow(df))) {
          cat(df$variable[i], "HR:", round(df$HR[i], 4), "p:", round(df$p_value[i], 4),
          "\n")
        }
      })(res$hazard_ratios)
    Output
      age HR: 1.85 p: 0.098 
      stage HR: 1.06 p: 0.051 
      gene_signature HR: 1.65 p: 0.094 

# km_analysis structure snapshot

    Code
      cat("class:", paste(class(res), collapse = ", "), "\n")
    Output
      class: list 
    Code
      cat("names:", paste(sort(names(res)), collapse = ", "), "\n")
    Output
      names: formula, median_survival, n_groups, p_value 
    Code
      cat("formula:", deparse(res$formula), "\n")
    Output
      formula: survival::Surv(time, status) ~ risk_group 
    Code
      cat("n_groups:", res$n_groups, "\n")
    Output
      n_groups: 3 
    Code
      cat("median_survival:", res$median_survival, "\n")
    Output
      median_survival: 500 350 200 
    Code
      cat("p_value:", res$p_value, "\n")
    Output
      p_value: 0.001 

# config structure snapshot

    Code
      cat("class:", paste(class(cfg), collapse = ", "), "\n")
    Output
      class: list 
    Code
      cat("names:", paste(sort(names(cfg)), collapse = ", "), "\n")
    Output
      names: data_dir, project_id, results_dir, sample_limit, seed 

# data_quality_report structure snapshot

    Code
      cat("class:", paste(class(rpt), collapse = ", "), "\n")
    Output
      class: list 
    Code
      if (is.data.frame(rpt)) {
        cat("names:", paste(sort(names(rpt)), collapse = ", "), "\n")
        cat("nrow:", nrow(rpt), "\n")
      } else if (is.list(rpt)) {
        cat("names:", paste(sort(names(rpt)), collapse = ", "), "\n")
      }
    Output
      names: clinical, expression, integration 

