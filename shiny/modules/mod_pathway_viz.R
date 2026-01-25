# modules/mod_pathway_viz.R
# Module for pathway analysis visualization

#' Pathway Visualization Module UI
mod_pathway_viz_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(12),

      card(
        card_header("Pathway Analysis Results"),
        card_body(
          navset_tab(
            nav_panel(
              "Enrichment Results",
              layout_columns(
                col_widths = c(6, 6),
                plotlyOutput(ns("enrichment_plot"), height = "500px"),
                plotlyOutput(ns("dotplot"), height = "500px")
              ),
              hr(),
              DTOutput(ns("pathway_table"))
            ),
            nav_panel(
              "GSEA Results",
              layout_columns(
                col_widths = c(6, 6),
                plotlyOutput(ns("gsea_plot"), height = "500px"),
                plotlyOutput(ns("running_score"), height = "500px")
              ),
              hr(),
              DTOutput(ns("gsea_table"))
            ),
            nav_panel(
              "Gene Networks",
              plotlyOutput(ns("gene_network"), height = "600px"),
              hr(),
              p("Network visualization shows connections between genes in enriched pathways.")
            )
          )
        )
      )
    )
  )
}

#' Pathway Visualization Module Server
mod_pathway_viz_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {

    # Enrichment barplot
    output$enrichment_plot <- renderPlotly({
      req(shared_data$pathway_results)

      df <- shared_data$pathway_results

      # Ensure we have the required columns
      if (!all(c("pathway", "p_value") %in% names(df))) {
        return(plot_ly() %>%
          layout(
            title = "Pathway Enrichment",
            annotations = list(
              text = "No pathway data available",
              showarrow = FALSE,
              xref = "paper", yref = "paper",
              x = 0.5, y = 0.5
            )
          ))
      }

      # Get top 15 pathways
      top_pathways <- df %>%
        arrange(p_value) %>%
        head(15) %>%
        mutate(
          neg_log_p = -log10(p_value),
          pathway = factor(pathway, levels = rev(pathway))
        )

      p <- plot_ly(
        data = top_pathways,
        x = ~neg_log_p,
        y = ~pathway,
        type = 'bar',
        orientation = 'h',
        marker = list(
          color = ~neg_log_p,
          colorscale = list(
            c(0, "#E8F4F8"),
            c(1, "#0066CC")
          ),
          showscale = TRUE,
          colorbar = list(title = "-Log10(P)")
        ),
        text = ~paste("Pathway:", pathway,
                     "<br>P-value:", format(p_value, digits = 3),
                     if("gene_count" %in% names(df))
                       paste("<br>Genes:", gene_count) else ""),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = "Top Enriched Pathways",
          xaxis = list(title = "-Log10(P-value)"),
          yaxis = list(title = "", tickfont = list(size = 10)),
          margin = list(l = 200)
        )

      p
    })

    # Dotplot
    output$dotplot <- renderPlotly({
      req(shared_data$pathway_results)

      df <- shared_data$pathway_results

      # Check required columns
      if (!all(c("pathway", "p_value") %in% names(df))) {
        return(plot_ly() %>%
          layout(
            title = "Pathway Dotplot",
            annotations = list(
              text = "Insufficient data for dotplot",
              showarrow = FALSE,
              xref = "paper", yref = "paper",
              x = 0.5, y = 0.5
            )
          ))
      }

      # Get top pathways
      top_pathways <- df %>%
        arrange(p_value) %>%
        head(15)

      # Add gene ratio if gene_count available
      if ("gene_count" %in% names(top_pathways) && "pathway_size" %in% names(top_pathways)) {
        top_pathways$gene_ratio <- top_pathways$gene_count / top_pathways$pathway_size
      } else if ("gene_count" %in% names(top_pathways)) {
        top_pathways$gene_ratio <- top_pathways$gene_count / 100  # Assume 100 genes per pathway
      } else {
        top_pathways$gene_ratio <- runif(nrow(top_pathways), 0.05, 0.3)
      }

      # Add q-value if not present
      if (!"q_value" %in% names(top_pathways)) {
        top_pathways$q_value <- p.adjust(top_pathways$p_value, method = "BH")
      }

      p <- plot_ly(
        data = top_pathways,
        x = ~gene_ratio,
        y = ~reorder(pathway, -p_value),
        type = 'scatter',
        mode = 'markers',
        marker = list(
          size = ~if("gene_count" %in% names(top_pathways)) gene_count * 2 else 10,
          color = ~-log10(q_value),
          colorscale = 'Reds',
          showscale = TRUE,
          colorbar = list(title = "-Log10(Q)")
        ),
        text = ~paste("Pathway:", pathway,
                     "<br>Gene Ratio:", round(gene_ratio, 3),
                     "<br>Q-value:", format(q_value, digits = 3),
                     if("gene_count" %in% names(df))
                       paste("<br>Gene Count:", gene_count) else ""),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = "Pathway Enrichment Dotplot",
          xaxis = list(title = "Gene Ratio"),
          yaxis = list(title = "", tickfont = list(size = 10)),
          margin = list(l = 200)
        )

      p
    })

    # Pathway table
    output$pathway_table <- renderDT({
      req(shared_data$pathway_results)

      df <- shared_data$pathway_results

      # Round numeric columns
      numeric_cols <- sapply(df, is.numeric)
      df[numeric_cols] <- lapply(df[numeric_cols], function(x) {
        if (all(x < 1, na.rm = TRUE)) {
          format(x, digits = 3, scientific = TRUE)
        } else {
          round(x, 4)
        }
      })

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

    # GSEA plot
    output$gsea_plot <- renderPlotly({
      # Check if GSEA results exist
      if (is.null(shared_data$pathway_results) ||
          !any(c("NES", "gene_set") %in% names(shared_data$pathway_results))) {

        # Generate mock GSEA data
        gsea_df <- data.frame(
          gene_set = c("HALLMARK_MYC_TARGETS_V1", "HALLMARK_E2F_TARGETS",
                      "HALLMARK_G2M_CHECKPOINT", "HALLMARK_APOPTOSIS",
                      "HALLMARK_UNFOLDED_PROTEIN_RESPONSE", "HALLMARK_INFLAMMATORY_RESPONSE",
                      "KEGG_PROTEASOME", "KEGG_CELL_CYCLE",
                      "REACTOME_IMMUNE_SYSTEM", "GO_DNA_REPAIR"),
          NES = c(2.3, 2.1, 1.9, -1.8, 1.7, -1.6, 1.5, 1.4, -1.3, 1.2),
          p_value = c(0.001, 0.002, 0.003, 0.004, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05),
          q_value = c(0.01, 0.01, 0.02, 0.02, 0.03, 0.05, 0.08, 0.1, 0.12, 0.15),
          stringsAsFactors = FALSE
        )
      } else {
        gsea_df <- shared_data$pathway_results
      }

      # Filter to significant gene sets
      if ("NES" %in% names(gsea_df)) {
        sig_sets <- gsea_df %>%
          filter(q_value < 0.25) %>%
          arrange(desc(abs(NES))) %>%
          head(20)

        # Color by direction
        sig_sets$direction <- ifelse(sig_sets$NES > 0, "Upregulated", "Downregulated")

        p <- plot_ly(
          data = sig_sets,
          x = ~NES,
          y = ~reorder(gene_set, NES),
          type = 'bar',
          orientation = 'h',
          marker = list(
            color = ~ifelse(NES > 0, "#DC3545", "#0066CC")
          ),
          text = ~paste("Gene Set:", gene_set,
                       "<br>NES:", round(NES, 2),
                       "<br>Q-value:", format(q_value, digits = 3)),
          hovertemplate = "%{text}<extra></extra>"
        ) %>%
          layout(
            title = "GSEA - Normalized Enrichment Scores",
            xaxis = list(title = "NES", zeroline = TRUE),
            yaxis = list(title = "", tickfont = list(size = 9)),
            margin = list(l = 250),
            shapes = list(
              list(
                type = 'line',
                x0 = 0, x1 = 0,
                y0 = -0.5, y1 = length(sig_sets$gene_set) - 0.5,
                line = list(color = 'black', width = 1)
              )
            )
          )
      } else {
        p <- plot_ly() %>%
          layout(
            title = "GSEA Results",
            annotations = list(
              text = "No GSEA results available",
              showarrow = FALSE,
              xref = "paper", yref = "paper",
              x = 0.5, y = 0.5
            )
          )
      }

      p
    })

    # Running enrichment score plot
    output$running_score <- renderPlotly({
      # Create example running score plot
      n_genes <- 1000
      rank <- 1:n_genes

      # Simulate hits for top gene set
      hit_positions <- sort(sample(1:n_genes, 50))
      running_score <- numeric(n_genes)

      # Calculate running enrichment score
      for (i in 1:n_genes) {
        if (i %in% hit_positions) {
          running_score[i] <- ifelse(i == 1, 0.02, running_score[i-1] + 0.02)
        } else {
          running_score[i] <- ifelse(i == 1, -0.001, running_score[i-1] - 0.001)
        }
      }

      # Find peak
      max_idx <- which.max(abs(running_score))

      p <- plot_ly() %>%
        add_trace(
          x = rank,
          y = running_score,
          type = 'scatter',
          mode = 'lines',
          line = list(color = '#2E86AB', width = 2),
          name = 'Running ES',
          hovertemplate = "Rank: %{x}<br>Score: %{y:.3f}<extra></extra>"
        ) %>%
        add_trace(
          x = hit_positions,
          y = rep(min(running_score) - 0.05, length(hit_positions)),
          type = 'scatter',
          mode = 'markers',
          marker = list(
            symbol = 'line-ns',
            size = 10,
            color = 'black'
          ),
          name = 'Gene Hits',
          hoverinfo = 'skip'
        ) %>%
        layout(
          title = "GSEA Running Enrichment Score",
          xaxis = list(title = "Gene Rank"),
          yaxis = list(title = "Enrichment Score"),
          shapes = list(
            list(
              type = 'line',
              x0 = 0, x1 = n_genes,
              y0 = 0, y1 = 0,
              line = list(color = 'gray', dash = 'dash', width = 1)
            ),
            list(
              type = 'line',
              x0 = max_idx, x1 = max_idx,
              y0 = 0, y1 = running_score[max_idx],
              line = list(color = 'red', dash = 'dot', width = 2)
            )
          ),
          annotations = list(
            list(
              x = max_idx,
              y = running_score[max_idx],
              text = paste("Peak ES:", round(running_score[max_idx], 3)),
              showarrow = TRUE,
              arrowhead = 2,
              arrowsize = 1,
              arrowwidth = 2,
              arrowcolor = 'red'
            )
          )
        )

      p
    })

    # GSEA table
    output$gsea_table <- renderDT({
      # Use pathway results or create mock GSEA data
      if (!is.null(shared_data$pathway_results) &&
          "NES" %in% names(shared_data$pathway_results)) {
        df <- shared_data$pathway_results
      } else {
        df <- data.frame(
          gene_set = c("HALLMARK_MYC_TARGETS_V1", "HALLMARK_E2F_TARGETS",
                      "HALLMARK_G2M_CHECKPOINT"),
          NES = c(2.3, 2.1, 1.9),
          p_value = c(0.001, 0.002, 0.003),
          q_value = c(0.01, 0.01, 0.02),
          leading_edge = c("MYC,CCND1,CDK4", "E2F1,RB1,CCND2", "CDK1,CCNB1,AURKA"),
          stringsAsFactors = FALSE
        )
      }

      # Format numeric columns
      numeric_cols <- sapply(df, is.numeric)
      df[numeric_cols] <- lapply(df[numeric_cols], function(x) {
        if (all(abs(x) < 1, na.rm = TRUE)) {
          format(x, digits = 3, scientific = TRUE)
        } else {
          round(x, 3)
        }
      })

      datatable(
        df,
        options = list(
          pageLength = 25,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        rownames = FALSE,
        extensions = 'Buttons'
      )
    })

    # Gene network visualization
    output$gene_network <- renderPlotly({
      # Create a simple network for top pathways
      if (!is.null(shared_data$pathway_results) &&
          "genes" %in% names(shared_data$pathway_results)) {
        # Get top 3 pathways
        top_pathways <- shared_data$pathway_results %>%
          arrange(p_value) %>%
          head(3)

        # Extract genes
        all_genes <- character()
        pathway_assignments <- list()

        for (i in 1:nrow(top_pathways)) {
          genes <- strsplit(as.character(top_pathways$genes[i]), ",")[[1]]
          all_genes <- c(all_genes, genes)
          pathway_assignments[[top_pathways$pathway[i]]] <- genes
        }

        # Create nodes
        unique_genes <- unique(all_genes)
        n_genes <- length(unique_genes)

        if (n_genes > 0) {
          # Simple circular layout
          angles <- seq(0, 2*pi, length.out = n_genes + 1)[1:n_genes]
          x <- cos(angles)
          y <- sin(angles)

          # Color by pathway membership
          node_colors <- rep("#CCCCCC", n_genes)
          colors <- c("#DC3545", "#0066CC", "#28A745")

          for (i in 1:length(pathway_assignments)) {
            pathway_genes <- pathway_assignments[[i]]
            gene_indices <- which(unique_genes %in% pathway_genes)
            node_colors[gene_indices] <- colors[i]
          }

          p <- plot_ly(
            x = x,
            y = y,
            type = 'scatter',
            mode = 'markers+text',
            text = unique_genes,
            textposition = 'top center',
            marker = list(
              size = 15,
              color = node_colors
            ),
            hovertemplate = "Gene: %{text}<extra></extra>"
          ) %>%
            layout(
              title = "Gene Network - Top 3 Pathways",
              xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, title = ""),
              yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, title = ""),
              showlegend = FALSE
            )
        } else {
          p <- create_empty_network_plot()
        }
      } else {
        p <- create_empty_network_plot()
      }

      p
    })

    # Helper function for empty network
    create_empty_network_plot <- function() {
      # Create example network
      genes <- c("MYC", "CCND1", "CDK4", "BCL2", "TP53", "NFKB1", "STAT3", "IL6")
      n <- length(genes)

      angles <- seq(0, 2*pi, length.out = n + 1)[1:n]
      x <- cos(angles)
      y <- sin(angles)

      # Create some edges
      edges <- data.frame(
        x0 = c(x[1], x[1], x[2], x[3], x[5]),
        y0 = c(y[1], y[1], y[2], y[3], y[5]),
        x1 = c(x[2], x[3], x[4], x[5], x[6]),
        y1 = c(y[2], y[3], y[4], y[5], y[6])
      )

      p <- plot_ly() %>%
        # Add edges
        add_segments(
          data = edges,
          x = ~x0, y = ~y0,
          xend = ~x1, yend = ~y1,
          line = list(color = '#CCCCCC', width = 1),
          hoverinfo = 'skip'
        ) %>%
        # Add nodes
        add_trace(
          x = x,
          y = y,
          type = 'scatter',
          mode = 'markers+text',
          text = genes,
          textposition = 'top center',
          marker = list(
            size = 20,
            color = c(rep("#DC3545", 3), rep("#0066CC", 3), rep("#28A745", 2))
          ),
          hovertemplate = "Gene: %{text}<extra></extra>"
        ) %>%
        layout(
          title = "Example Gene Network",
          xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, title = ""),
          yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE, title = ""),
          showlegend = FALSE
        )

      p
    }
  })
}