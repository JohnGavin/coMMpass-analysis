# modules/mod_qc_viz.R
# Module for QC visualization

#' QC Visualization Module UI
mod_qc_viz_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(12),

      # QC metrics overview
      card(
        card_header("Quality Control Metrics"),
        card_body(
          layout_columns(
            col_widths = c(6, 6),
            plotlyOutput(ns("library_size_plot")),
            plotlyOutput(ns("gene_detection_plot"))
          ),

          hr(),

          layout_columns(
            col_widths = c(6, 6),
            plotlyOutput(ns("pca_plot")),
            plotlyOutput(ns("outlier_plot"))
          ),

          hr(),

          h5("Sample QC Table"),
          DTOutput(ns("qc_table"))
        )
      )
    )
  )
}

#' QC Visualization Module Server
mod_qc_viz_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {

    # Library size distribution
    output$library_size_plot <- renderPlotly({
      req(shared_data$qc_metrics)

      p <- plot_ly(
        data = shared_data$qc_metrics,
        x = ~sample,
        y = ~total_counts,
        type = 'bar',
        marker = list(
          color = ~total_counts,
          colorscale = 'Blues',
          showscale = FALSE
        ),
        text = ~paste("Sample:", sample,
                     "<br>Total counts:", format(total_counts, big.mark = ",")),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = "Library Size Distribution",
          xaxis = list(title = "Sample", tickangle = -45),
          yaxis = list(title = "Total Counts"),
          margin = list(b = 100)
        )

      p
    })

    # Gene detection plot
    output$gene_detection_plot <- renderPlotly({
      req(shared_data$qc_metrics)

      p <- plot_ly(
        data = shared_data$qc_metrics,
        y = ~detected_genes,
        type = 'box',
        name = "Detected Genes",
        marker = list(color = "#2E86AB")
      ) %>%
        add_trace(
          y = ~detected_genes,
          type = 'scatter',
          mode = 'markers',
          name = "Samples",
          marker = list(
            color = "#A23B72",
            size = 8
          ),
          text = ~paste("Sample:", sample,
                       "<br>Detected genes:", detected_genes),
          hovertemplate = "%{text}<extra></extra>"
        ) %>%
        layout(
          title = "Gene Detection per Sample",
          yaxis = list(title = "Number of Detected Genes"),
          showlegend = FALSE
        )

      p
    })

    # PCA plot
    output$pca_plot <- renderPlotly({
      req(shared_data$raw_data)

      # Simple PCA for visualization
      if (is.list(shared_data$raw_data) && "counts" %in% names(shared_data$raw_data)) {
        counts <- shared_data$raw_data$counts

        # Log transform and transpose
        log_counts <- log2(counts + 1)
        pca_result <- prcomp(t(log_counts), scale. = TRUE, center = TRUE)

        # Get PC scores
        pc_df <- data.frame(
          sample = rownames(pca_result$x),
          PC1 = pca_result$x[,1],
          PC2 = pca_result$x[,2],
          stringsAsFactors = FALSE
        )

        # Calculate variance explained
        var_explained <- round(100 * pca_result$sdev^2 / sum(pca_result$sdev^2), 1)

        p <- plot_ly(
          data = pc_df,
          x = ~PC1,
          y = ~PC2,
          type = 'scatter',
          mode = 'markers+text',
          text = ~sample,
          textposition = "top center",
          marker = list(
            size = 12,
            color = "#2E86AB"
          ),
          hovertemplate = paste("Sample: %{text}",
                               "<br>PC1: %{x:.2f}",
                               "<br>PC2: %{y:.2f}",
                               "<extra></extra>")
        ) %>%
          layout(
            title = "PCA of Samples",
            xaxis = list(title = paste0("PC1 (", var_explained[1], "% variance)")),
            yaxis = list(title = paste0("PC2 (", var_explained[2], "% variance)"))
          )
      } else {
        # Empty plot if no data
        p <- plot_ly() %>%
          layout(
            title = "PCA Plot",
            annotations = list(
              text = "No expression data available",
              showarrow = FALSE,
              xref = "paper",
              yref = "paper",
              x = 0.5,
              y = 0.5
            )
          )
      }

      p
    })

    # Outlier detection plot
    output$outlier_plot <- renderPlotly({
      req(shared_data$qc_metrics)

      # Add outlier status if not present
      if (!"is_outlier" %in% names(shared_data$qc_metrics)) {
        shared_data$qc_metrics$is_outlier <- FALSE
      }

      # Color by outlier status
      colors <- ifelse(shared_data$qc_metrics$is_outlier, "#DC3545", "#28A745")
      status <- ifelse(shared_data$qc_metrics$is_outlier, "Outlier", "Pass QC")

      p <- plot_ly(
        data = shared_data$qc_metrics,
        x = ~log10(total_counts),
        y = ~detected_genes,
        type = 'scatter',
        mode = 'markers',
        marker = list(
          size = 10,
          color = colors,
          line = list(
            color = 'black',
            width = 1
          )
        ),
        text = ~paste("Sample:", sample,
                     "<br>Status:", status,
                     "<br>Total counts:", format(total_counts, big.mark = ","),
                     "<br>Detected genes:", detected_genes),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = "Outlier Detection",
          xaxis = list(title = "Log10(Total Counts)"),
          yaxis = list(title = "Detected Genes"),
          shapes = list(
            # Add reference lines for outlier thresholds
            list(
              type = 'line',
              x0 = min(log10(shared_data$qc_metrics$total_counts)),
              x1 = max(log10(shared_data$qc_metrics$total_counts)),
              y0 = quantile(shared_data$qc_metrics$detected_genes, 0.05),
              y1 = quantile(shared_data$qc_metrics$detected_genes, 0.05),
              line = list(
                color = 'red',
                dash = 'dash',
                width = 1
              )
            )
          )
        )

      p
    })

    # QC metrics table
    output$qc_table <- renderDT({
      req(shared_data$qc_metrics)

      # Add percentage columns if available
      display_df <- shared_data$qc_metrics
      if ("total_counts" %in% names(display_df)) {
        display_df$total_counts <- format(display_df$total_counts, big.mark = ",")
      }

      datatable(
        display_df,
        options = list(
          pageLength = 10,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        extensions = 'Buttons'
      ) %>%
        formatStyle(
          columns = "is_outlier",
          backgroundColor = styleEqual(TRUE, "#FFE5E5"),
          target = 'row'
        )
    })
  })
}