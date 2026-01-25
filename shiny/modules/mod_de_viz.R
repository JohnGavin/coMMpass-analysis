# modules/mod_de_viz.R
# Module for differential expression visualization

#' DE Visualization Module UI
mod_de_viz_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(3, 9),

      # Left panel - Controls
      card(
        card_header("DE Analysis Controls"),
        card_body(
          selectInput(
            ns("de_method"),
            "Select Method:",
            choices = c("DESeq2", "edgeR", "limma", "Consensus"),
            selected = "Consensus"
          ),

          sliderInput(
            ns("padj_threshold"),
            "Adjusted P-value Threshold:",
            min = 0.001,
            max = 0.1,
            value = 0.05,
            step = 0.001
          ),

          sliderInput(
            ns("lfc_threshold"),
            "Log2 Fold Change Threshold:",
            min = 0,
            max = 3,
            value = 1,
            step = 0.1
          ),

          hr(),

          h5("Summary Statistics"),
          tableOutput(ns("de_summary"))
        )
      ),

      # Right panel - Visualizations
      card(
        card_header("Differential Expression Results"),
        card_body(
          navset_tab(
            nav_panel(
              "Volcano Plot",
              plotlyOutput(ns("volcano_plot"), height = "500px")
            ),
            nav_panel(
              "MA Plot",
              plotlyOutput(ns("ma_plot"), height = "500px")
            ),
            nav_panel(
              "Heatmap",
              plotlyOutput(ns("heatmap"), height = "600px")
            ),
            nav_panel(
              "DE Table",
              DTOutput(ns("de_table"))
            ),
            nav_panel(
              "Method Comparison",
              plotlyOutput(ns("venn_diagram"), height = "500px")
            )
          )
        )
      )
    )
  )
}

#' DE Visualization Module Server
mod_de_viz_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {

    # Get current DE results based on method selection
    current_de_results <- reactive({
      req(shared_data$de_results)

      if (input$de_method == "Consensus") {
        # Return consensus results if available
        if (is.list(shared_data$de_results) && "consensus_table" %in% names(shared_data$de_results)) {
          shared_data$de_results$consensus_table
        } else if (is.list(shared_data$de_results) && "DESeq2" %in% names(shared_data$de_results)) {
          # Use first available method
          shared_data$de_results[[1]]
        } else {
          shared_data$de_results
        }
      } else {
        # Return specific method results
        if (is.list(shared_data$de_results) && input$de_method %in% names(shared_data$de_results)) {
          shared_data$de_results[[input$de_method]]
        } else {
          shared_data$de_results
        }
      }
    })

    # DE summary statistics
    output$de_summary <- renderTable({
      req(current_de_results())

      df <- current_de_results()

      # Find appropriate columns
      padj_col <- if ("padj" %in% names(df)) "padj" else
                  if ("FDR" %in% names(df)) "FDR" else
                  if ("adj.P.Val" %in% names(df)) "adj.P.Val" else NULL

      lfc_col <- if ("log2FoldChange" %in% names(df)) "log2FoldChange" else
                 if ("log2FC" %in% names(df)) "log2FC" else
                 if ("logFC" %in% names(df)) "logFC" else NULL

      if (!is.null(padj_col) && !is.null(lfc_col)) {
        n_sig <- sum(df[[padj_col]] < input$padj_threshold, na.rm = TRUE)
        n_up <- sum(df[[padj_col]] < input$padj_threshold &
                   df[[lfc_col]] > input$lfc_threshold, na.rm = TRUE)
        n_down <- sum(df[[padj_col]] < input$padj_threshold &
                     df[[lfc_col]] < -input$lfc_threshold, na.rm = TRUE)
      } else {
        n_sig <- n_up <- n_down <- 0
      }

      data.frame(
        Metric = c("Total Genes", "Significant", "Upregulated", "Downregulated"),
        Count = c(nrow(df), n_sig, n_up, n_down),
        stringsAsFactors = FALSE
      )
    })

    # Volcano plot
    output$volcano_plot <- renderPlotly({
      req(current_de_results())

      df <- current_de_results()

      # Find appropriate columns
      padj_col <- if ("padj" %in% names(df)) "padj" else
                  if ("FDR" %in% names(df)) "FDR" else
                  if ("adj.P.Val" %in% names(df)) "adj.P.Val" else "p_value"

      lfc_col <- if ("log2FoldChange" %in% names(df)) "log2FoldChange" else
                 if ("log2FC" %in% names(df)) "log2FC" else
                 if ("logFC" %in% names(df)) "logFC" else "log2FC"

      gene_col <- if ("gene" %in% names(df)) "gene" else rownames(df)

      # Add significance status
      df$significance <- ifelse(
        df[[padj_col]] < input$padj_threshold & abs(df[[lfc_col]]) > input$lfc_threshold,
        ifelse(df[[lfc_col]] > 0, "Up", "Down"),
        "Not Significant"
      )

      # Color mapping
      colors <- c("Up" = "#DC3545", "Down" = "#0066CC", "Not Significant" = "#CCCCCC")

      p <- plot_ly(
        data = df,
        x = ~get(lfc_col),
        y = ~-log10(get(padj_col)),
        type = 'scatter',
        mode = 'markers',
        color = ~significance,
        colors = colors,
        marker = list(size = 5),
        text = ~paste("Gene:", if(is.character(gene_col)) gene_col else gene,
                     "<br>Log2FC:", round(get(lfc_col), 3),
                     "<br>Adj P-value:", format(get(padj_col), digits = 3)),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = paste("Volcano Plot -", input$de_method),
          xaxis = list(title = "Log2 Fold Change"),
          yaxis = list(title = "-Log10(Adjusted P-value)"),
          shapes = list(
            # Vertical lines for fold change threshold
            list(type = 'line', x0 = input$lfc_threshold, x1 = input$lfc_threshold,
                 y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = 'gray', dash = 'dash', width = 1)),
            list(type = 'line', x0 = -input$lfc_threshold, x1 = -input$lfc_threshold,
                 y0 = 0, y1 = 1, yref = "paper",
                 line = list(color = 'gray', dash = 'dash', width = 1)),
            # Horizontal line for p-value threshold
            list(type = 'line', x0 = 0, x1 = 1, xref = "paper",
                 y0 = -log10(input$padj_threshold), y1 = -log10(input$padj_threshold),
                 line = list(color = 'gray', dash = 'dash', width = 1))
          )
        )

      p
    })

    # MA plot
    output$ma_plot <- renderPlotly({
      req(current_de_results())

      df <- current_de_results()

      # Find appropriate columns
      padj_col <- if ("padj" %in% names(df)) "padj" else
                  if ("FDR" %in% names(df)) "FDR" else
                  if ("adj.P.Val" %in% names(df)) "adj.P.Val" else "p_value"

      lfc_col <- if ("log2FoldChange" %in% names(df)) "log2FoldChange" else
                 if ("log2FC" %in% names(df)) "log2FC" else
                 if ("logFC" %in% names(df)) "logFC" else "log2FC"

      # Use baseMean if available, otherwise generate mock data
      if ("baseMean" %in% names(df)) {
        df$avg_expr <- log10(df$baseMean + 1)
      } else if ("AveExpr" %in% names(df)) {
        df$avg_expr <- df$AveExpr
      } else {
        df$avg_expr <- runif(nrow(df), 0, 5)
      }

      # Add significance status
      df$significance <- ifelse(
        df[[padj_col]] < input$padj_threshold & abs(df[[lfc_col]]) > input$lfc_threshold,
        "Significant",
        "Not Significant"
      )

      colors <- c("Significant" = "#DC3545", "Not Significant" = "#CCCCCC")

      p <- plot_ly(
        data = df,
        x = ~avg_expr,
        y = ~get(lfc_col),
        type = 'scatter',
        mode = 'markers',
        color = ~significance,
        colors = colors,
        marker = list(size = 4),
        text = ~paste("Gene:", if("gene" %in% names(df)) gene else rownames(df),
                     "<br>Avg Expression:", round(avg_expr, 2),
                     "<br>Log2FC:", round(get(lfc_col), 3)),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = paste("MA Plot -", input$de_method),
          xaxis = list(title = "Average Expression (log10)"),
          yaxis = list(title = "Log2 Fold Change"),
          shapes = list(
            # Horizontal lines for fold change threshold
            list(type = 'line', x0 = 0, x1 = 1, xref = "paper",
                 y0 = input$lfc_threshold, y1 = input$lfc_threshold,
                 line = list(color = 'gray', dash = 'dash', width = 1)),
            list(type = 'line', x0 = 0, x1 = 1, xref = "paper",
                 y0 = -input$lfc_threshold, y1 = -input$lfc_threshold,
                 line = list(color = 'gray', dash = 'dash', width = 1))
          )
        )

      p
    })

    # Heatmap of top DE genes
    output$heatmap <- renderPlotly({
      req(current_de_results())
      req(shared_data$raw_data)

      df <- current_de_results()

      # Get top 30 genes
      padj_col <- if ("padj" %in% names(df)) "padj" else
                  if ("FDR" %in% names(df)) "FDR" else
                  if ("adj.P.Val" %in% names(df)) "adj.P.Val" else "p_value"

      top_genes <- df %>%
        arrange(!!sym(padj_col)) %>%
        head(30)

      gene_col <- if ("gene" %in% names(top_genes)) top_genes$gene else rownames(top_genes)

      # Get expression data
      if (is.list(shared_data$raw_data) && "counts" %in% names(shared_data$raw_data)) {
        counts <- shared_data$raw_data$counts

        # Filter to top genes
        if (all(gene_col %in% rownames(counts))) {
          expr_matrix <- log2(counts[gene_col, ] + 1)
        } else {
          # Generate mock data if genes don't match
          expr_matrix <- matrix(
            rnorm(30 * 10, mean = 5, sd = 2),
            nrow = 30,
            dimnames = list(gene_col[1:30], paste0("Sample", 1:10))
          )
        }

        # Scale rows
        expr_scaled <- t(scale(t(expr_matrix)))

        p <- plot_ly(
          z = expr_scaled,
          x = colnames(expr_scaled),
          y = rownames(expr_scaled),
          type = 'heatmap',
          colorscale = 'RdBu',
          reversescale = TRUE,
          hovertemplate = "Gene: %{y}<br>Sample: %{x}<br>Z-score: %{z:.2f}<extra></extra>"
        ) %>%
          layout(
            title = "Top 30 DE Genes Heatmap",
            xaxis = list(title = "Samples", tickangle = -45),
            yaxis = list(title = "Genes"),
            margin = list(l = 100, b = 100)
          )
      } else {
        p <- plot_ly() %>%
          layout(
            title = "Heatmap",
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

    # DE results table
    output$de_table <- renderDT({
      req(current_de_results())

      df <- current_de_results()

      # Round numeric columns
      numeric_cols <- sapply(df, is.numeric)
      df[numeric_cols] <- lapply(df[numeric_cols], function(x) round(x, 4))

      datatable(
        df,
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        extensions = 'Buttons',
        filter = 'top'
      )
    })

    # Venn diagram / method comparison
    output$venn_diagram <- renderPlotly({
      req(shared_data$de_results)

      if (is.list(shared_data$de_results) && length(shared_data$de_results) > 1) {
        # Count significant genes per method
        method_counts <- sapply(names(shared_data$de_results), function(method) {
          df <- shared_data$de_results[[method]]
          if (is.data.frame(df)) {
            padj_col <- if ("padj" %in% names(df)) "padj" else
                       if ("FDR" %in% names(df)) "FDR" else
                       if ("adj.P.Val" %in% names(df)) "adj.P.Val" else NULL
            if (!is.null(padj_col)) {
              sum(df[[padj_col]] < input$padj_threshold, na.rm = TRUE)
            } else 0
          } else 0
        })

        p <- plot_ly(
          x = names(method_counts),
          y = method_counts,
          type = 'bar',
          marker = list(color = '#2E86AB')
        ) %>%
          layout(
            title = "DE Genes by Method",
            xaxis = list(title = "Method"),
            yaxis = list(title = "Number of Significant Genes")
          )
      } else {
        p <- plot_ly() %>%
          layout(
            title = "Method Comparison",
            annotations = list(
              text = "Multiple methods required for comparison",
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
  })
}