# shiny/app.R
# CoMMpass Analysis Dashboard - Shinylive Compatible
# This dashboard visualizes results from the CoMMpass multiple myeloma analysis pipeline

library(shiny)
library(bslib)
library(plotly)
library(DT)
library(dplyr)
library(tidyr)
library(ggplot2)
library(survival)
library(survminer)

# Source modules
source("modules/mod_data_loader.R")
source("modules/mod_qc_viz.R")
source("modules/mod_de_viz.R")
source("modules/mod_survival_viz.R")
source("modules/mod_pathway_viz.R")

# Define UI
ui <- page_navbar(
  title = "CoMMpass Analysis Dashboard",
  theme = bs_theme(
    version = 5,
    primary = "#0066CC",
    secondary = "#6C757D",
    success = "#28A745",
    info = "#17A2B8",
    warning = "#FFC107",
    danger = "#DC3545"
  ),

  # Home tab
  nav_panel(
    title = "Overview",
    icon = icon("home"),
    layout_columns(
      col_widths = c(12),
      card(
        card_header("CoMMpass Multiple Myeloma Analysis"),
        card_body(
          h4("Welcome to the CoMMpass Analysis Dashboard"),
          p("This interactive dashboard provides visualization and exploration of the MMRF CoMMpass dataset analysis results."),
          hr(),
          h5("Dataset Overview"),
          p("The CoMMpass (Relating Clinical Outcomes in Multiple Myeloma to Personal Assessment of Genetic Profile) study includes:"),
          tags$ul(
            tags$li("1,143 newly diagnosed multiple myeloma patients"),
            tags$li("RNA-seq expression data"),
            tags$li("Clinical and survival outcomes"),
            tags$li("Cytogenetic and mutation data")
          ),
          hr(),
          h5("Analysis Modules"),
          p("Navigate through the tabs above to explore:"),
          tags$ul(
            tags$li(strong("Quality Control:"), " Sample and gene QC metrics, normalization results"),
            tags$li(strong("Differential Expression:"), " DE results from DESeq2, edgeR, and limma"),
            tags$li(strong("Survival Analysis:"), " Kaplan-Meier curves and Cox regression models"),
            tags$li(strong("Pathway Analysis:"), " Enrichment analysis and GSEA results")
          )
        )
      )
    )
  ),

  # Data Loading tab
  nav_panel(
    title = "Data",
    icon = icon("database"),
    mod_data_loader_ui("data_loader")
  ),

  # QC Visualization tab
  nav_panel(
    title = "Quality Control",
    icon = icon("chart-line"),
    mod_qc_viz_ui("qc_viz")
  ),

  # Differential Expression tab
  nav_panel(
    title = "Differential Expression",
    icon = icon("dna"),
    mod_de_viz_ui("de_viz")
  ),

  # Survival Analysis tab
  nav_panel(
    title = "Survival Analysis",
    icon = icon("heartbeat"),
    mod_survival_viz_ui("survival_viz")
  ),

  # Pathway Analysis tab
  nav_panel(
    title = "Pathway Analysis",
    icon = icon("project-diagram"),
    mod_pathway_viz_ui("pathway_viz")
  ),

  # About tab
  nav_panel(
    title = "About",
    icon = icon("info-circle"),
    card(
      card_header("About This Dashboard"),
      card_body(
        h5("Data Source"),
        p("Data from the MMRF CoMMpass study (phs000748) accessed via the NCI Genomic Data Commons."),
        hr(),
        h5("Analysis Pipeline"),
        p("Results generated using the targets-based R pipeline with:"),
        tags$ul(
          tags$li("Quality control and normalization"),
          tags$li("Multi-method differential expression analysis"),
          tags$li("Survival analysis (OS and PFS endpoints)"),
          tags$li("Pathway enrichment and GSEA")
        ),
        hr(),
        h5("Technology"),
        p("Built with R Shiny and convertible to Shinylive for browser-based execution without R server."),
        hr(),
        h5("Contact"),
        p("For questions or issues, please contact the analysis team or submit an issue on GitHub.")
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  # Initialize reactive values for shared data
  shared_data <- reactiveValues(
    raw_data = NULL,
    qc_metrics = NULL,
    de_results = NULL,
    survival_data = NULL,
    pathway_results = NULL,
    config = list(use_example = TRUE)
  )

  # Call module servers
  data_loader_results <- mod_data_loader_server("data_loader", shared_data)
  mod_qc_viz_server("qc_viz", shared_data)
  mod_de_viz_server("de_viz", shared_data)
  mod_survival_viz_server("survival_viz", shared_data)
  mod_pathway_viz_server("pathway_viz", shared_data)
}

# Run the app
shinyApp(ui = ui, server = server)