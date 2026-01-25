# modules/mod_data_loader.R
# Module for loading and managing CoMMpass analysis data

#' Data Loader Module UI
mod_data_loader_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(4, 8),

      # Left panel - Data source selection
      card(
        card_header("Data Source"),
        card_body(
          radioButtons(
            ns("data_source"),
            "Select Data Source:",
            choices = list(
              "Example Data (Quick Start)" = "example",
              "Upload Results (.RDS)" = "upload",
              "Connect to targets" = "targets"
            ),
            selected = "example"
          ),

          conditionalPanel(
            condition = "input.data_source == 'upload'",
            ns = ns,
            fileInput(
              ns("upload_files"),
              "Upload Analysis Results:",
              multiple = TRUE,
              accept = c(".rds", ".RDS")
            )
          ),

          conditionalPanel(
            condition = "input.data_source == 'targets'",
            ns = ns,
            p(class = "text-muted",
              "This will load results from the targets pipeline.",
              "Ensure the pipeline has been run first."
            )
          ),

          hr(),

          actionButton(
            ns("load_data"),
            "Load Data",
            class = "btn-primary",
            icon = icon("download")
          ),

          br(), br(),

          verbatimTextOutput(ns("load_status"))
        )
      ),

      # Right panel - Data summary
      card(
        card_header("Data Summary"),
        card_body(
          h5("Loaded Datasets"),
          tableOutput(ns("data_summary")),

          hr(),

          h5("Sample Information"),
          plotlyOutput(ns("sample_distribution")),

          hr(),

          h5("Data Preview"),
          DTOutput(ns("data_preview"))
        )
      )
    )
  )
}

#' Data Loader Module Server
mod_data_loader_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {

    # Load data based on source selection
    observeEvent(input$load_data, {

      if (input$data_source == "example") {
        # Load example data
        tryCatch({
          # Load pre-computed example results
          example_dir <- "../data/example/"

          shared_data$raw_data <- readRDS(file.path(example_dir, "counts.rds"))
          shared_data$qc_metrics <- readRDS(file.path(example_dir, "qc_metrics.rds"))
          shared_data$de_results <- readRDS(file.path(example_dir, "de_results.rds"))
          shared_data$survival_data <- readRDS(file.path(example_dir, "survival_data.rds"))
          shared_data$pathway_results <- readRDS(file.path(example_dir, "pathway_results.rds"))

          output$load_status <- renderText("Example data loaded successfully!")

        }, error = function(e) {
          # If pre-computed results don't exist, generate them
          output$load_status <- renderText("Generating example data...")

          # Source the generation script
          source("../R/generate_example_data.R")

          # Generate data
          counts <- generate_counts_matrix(n_genes = 100, n_samples = 30)
          clinical <- generate_clinical_data(n_samples = 30)

          # Create mock analysis results
          shared_data$raw_data <- list(
            counts = counts,
            clinical = clinical
          )

          shared_data$qc_metrics <- data.frame(
            sample = colnames(counts),
            total_counts = colSums(counts),
            detected_genes = colSums(counts > 0),
            stringsAsFactors = FALSE
          )

          shared_data$de_results <- list(
            DESeq2 = data.frame(
              gene = rownames(counts)[1:20],
              log2FC = rnorm(20, 0, 2),
              padj = runif(20, 0, 0.1),
              stringsAsFactors = FALSE
            )
          )

          shared_data$survival_data <- clinical

          shared_data$pathway_results <- data.frame(
            pathway = c("Cell cycle", "Apoptosis", "NF-kB signaling"),
            p_value = c(0.001, 0.01, 0.05),
            gene_count = c(15, 12, 8),
            stringsAsFactors = FALSE
          )

          output$load_status <- renderText("Example data generated successfully!")
        })

      } else if (input$data_source == "upload") {
        # Handle file upload
        req(input$upload_files)

        tryCatch({
          files <- input$upload_files

          for (i in 1:nrow(files)) {
            file_name <- files$name[i]
            file_path <- files$datapath[i]

            if (grepl("qc", file_name, ignore.case = TRUE)) {
              shared_data$qc_metrics <- readRDS(file_path)
            } else if (grepl("de|differential", file_name, ignore.case = TRUE)) {
              shared_data$de_results <- readRDS(file_path)
            } else if (grepl("surv", file_name, ignore.case = TRUE)) {
              shared_data$survival_data <- readRDS(file_path)
            } else if (grepl("path", file_name, ignore.case = TRUE)) {
              shared_data$pathway_results <- readRDS(file_path)
            } else if (grepl("raw|counts", file_name, ignore.case = TRUE)) {
              shared_data$raw_data <- readRDS(file_path)
            }
          }

          output$load_status <- renderText("Files uploaded successfully!")

        }, error = function(e) {
          output$load_status <- renderText(paste("Error loading files:", e$message))
        })

      } else if (input$data_source == "targets") {
        # Load from targets pipeline
        tryCatch({
          library(targets)

          # Load results from targets
          shared_data$raw_data <- tar_read(raw_data)
          shared_data$qc_metrics <- tar_read(qc_metrics)
          shared_data$de_results <- tar_read(consensus_de_genes)
          shared_data$survival_data <- tar_read(survival_data)
          shared_data$pathway_results <- tar_read(pathway_results)

          output$load_status <- renderText("Data loaded from targets pipeline!")

        }, error = function(e) {
          output$load_status <- renderText(paste("Error loading from targets:", e$message))
        })
      }
    })

    # Data summary table
    output$data_summary <- renderTable({
      req(shared_data$raw_data)

      data.frame(
        Dataset = c("Expression Data", "QC Metrics", "DE Results",
                   "Survival Data", "Pathway Results"),
        Status = c(
          ifelse(is.null(shared_data$raw_data), "Not loaded", "Loaded"),
          ifelse(is.null(shared_data$qc_metrics), "Not loaded", "Loaded"),
          ifelse(is.null(shared_data$de_results), "Not loaded", "Loaded"),
          ifelse(is.null(shared_data$survival_data), "Not loaded", "Loaded"),
          ifelse(is.null(shared_data$pathway_results), "Not loaded", "Loaded")
        ),
        Dimensions = c(
          if (!is.null(shared_data$raw_data)) {
            if (is.list(shared_data$raw_data) && "counts" %in% names(shared_data$raw_data)) {
              paste(dim(shared_data$raw_data$counts), collapse = " x ")
            } else "N/A"
          } else "-",
          if (!is.null(shared_data$qc_metrics)) {
            paste(dim(shared_data$qc_metrics), collapse = " x ")
          } else "-",
          if (!is.null(shared_data$de_results)) {
            if (is.list(shared_data$de_results)) {
              paste(length(shared_data$de_results), "methods")
            } else paste(dim(shared_data$de_results), collapse = " x ")
          } else "-",
          if (!is.null(shared_data$survival_data)) {
            paste(dim(shared_data$survival_data), collapse = " x ")
          } else "-",
          if (!is.null(shared_data$pathway_results)) {
            paste(dim(shared_data$pathway_results), collapse = " x ")
          } else "-"
        ),
        stringsAsFactors = FALSE
      )
    })

    # Sample distribution plot
    output$sample_distribution <- renderPlotly({
      req(shared_data$qc_metrics)

      p <- plot_ly(
        data = shared_data$qc_metrics,
        x = ~total_counts,
        y = ~detected_genes,
        type = 'scatter',
        mode = 'markers',
        marker = list(
          size = 10,
          color = ~total_counts,
          colorscale = 'Viridis',
          showscale = TRUE
        ),
        text = ~paste("Sample:", sample,
                     "<br>Total counts:", format(total_counts, big.mark = ","),
                     "<br>Detected genes:", detected_genes),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = "Sample Distribution",
          xaxis = list(title = "Total Counts"),
          yaxis = list(title = "Detected Genes"),
          hovermode = 'closest'
        )

      p
    })

    # Data preview table
    output$data_preview <- renderDT({
      req(shared_data$qc_metrics)

      datatable(
        shared_data$qc_metrics,
        options = list(
          pageLength = 5,
          scrollX = TRUE,
          dom = 'tp'
        ),
        rownames = FALSE
      )
    })

    # Return loaded data status
    return(reactive({
      list(
        loaded = !is.null(shared_data$raw_data),
        source = input$data_source
      )
    }))
  })
}