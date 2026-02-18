# fix_031_test_infrastructure.R
# Issue: https://github.com/JohnGavin/coMMpass-analysis/issues/31
# Branch: test/issue-31-test-infrastructure
#
# Summary:
#   Add testthat infrastructure and comprehensive tests for all 16 exported
#   functions. Includes adversarial QA edge-case tests.
#
# Files created:
#   - tests/testthat.R (testthat runner)
#   - tests/testthat/test-utils.R (format_file_size, format_with_commas, create_summary_table)
#   - tests/testthat/test-data-dictionary.R (get_commpass_data_dictionary, get_variable_docs)
#   - tests/testthat/test-data-cleaning.R (clean_clinical_data, clean_expression_data, integrate_clinical_expression)
#   - tests/testthat/test-database-parquet.R (query_commpass_parquet, get_commpass_tbl, resolve_parquet_path)
#   - tests/testthat/test-data-access.R (query_commpass_rna, get_commpass_clinical, list_s3_commpass, etc.)
#   - tests/testthat/test-analysis-stubs.R (prepare_survival_data, run_gsea, calculate_qc_metrics)
#   - tests/testthat/test-adversarial.R (edge cases for all exported functions)
#
# Files modified:
#   - DESCRIPTION (testthat >= 3.0.0, edition 3)
#
# Verification:
#   devtools::test()   # all tests pass
#   devtools::check()  # 0 errors, 0 warnings
