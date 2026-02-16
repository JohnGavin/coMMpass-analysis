#' @keywords internal
"_PACKAGE"

# Base R imports ---------------------------------------------------------------
#' @importFrom stats as.formula mad median quantile rnorm runif sd
#' @importFrom utils head installed.packages
NULL

# logger imports ---------------------------------------------------------------
#' @importFrom logger log_info log_warn log_appender appender_file log_threshold INFO
NULL

# Bioconductor imports ---------------------------------------------------------
#' @importFrom SummarizedExperiment assay assay<- assayNames colData rowData
NULL

# edgeR imports ----------------------------------------------------------------
#' @importFrom edgeR DGEList calcNormFactors cpm
NULL

# dplyr imports ----------------------------------------------------------------
#' @importFrom dplyr .data
NULL
