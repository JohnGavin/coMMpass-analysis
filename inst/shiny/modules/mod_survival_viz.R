# modules/mod_survival_viz.R
# Module for survival analysis visualization

#' Survival Visualization Module UI
mod_survival_viz_ui <- function(id) {
  ns <- NS(id)

  tagList(
    layout_columns(
      col_widths = c(3, 9),

      # Left panel - Controls
      card(
        card_header("Survival Analysis Controls"),
        card_body(
          radioButtons(
            ns("survival_type"),
            "Survival Endpoint:",
            choices = c("Overall Survival" = "os",
                       "Progression-Free Survival" = "pfs"),
            selected = "os"
          ),

          selectInput(
            ns("group_by"),
            "Group By:",
            choices = c("Risk Group" = "risk_group",
                       "ISS Stage" = "stage",
                       "Response" = "response",
                       "None" = "none"),
            selected = "risk_group"
          ),

          hr(),

          h5("Cox Regression"),
          checkboxGroupInput(
            ns("cox_covariates"),
            "Select Covariates:",
            choices = c("Age" = "age",
                       "Stage" = "stage",
                       "Risk Group" = "risk_group"),
            selected = c("age", "stage")
          ),

          actionButton(
            ns("run_cox"),
            "Run Cox Model",
            class = "btn-primary",
            icon = icon("play")
          ),

          hr(),

          h5("Survival Summary"),
          tableOutput(ns("survival_summary"))
        )
      ),

      # Right panel - Visualizations
      card(
        card_header("Survival Analysis Results"),
        card_body(
          navset_tab(
            nav_panel(
              "Kaplan-Meier Plot",
              plotlyOutput(ns("km_plot"), height = "500px"),
              verbatimTextOutput(ns("km_stats"))
            ),
            nav_panel(
              "Cox Regression",
              plotlyOutput(ns("forest_plot"), height = "400px"),
              hr(),
              tableOutput(ns("cox_table"))
            ),
            nav_panel(
              "Risk Table",
              DTOutput(ns("risk_table"))
            ),
            nav_panel(
              "Survival Data",
              DTOutput(ns("survival_data_table"))
            )
          )
        )
      )
    )
  )
}

#' Survival Visualization Module Server
mod_survival_viz_server <- function(id, shared_data) {
  moduleServer(id, function(input, output, session) {

    # Reactive for Cox results
    cox_results <- reactiveVal(NULL)

    # --- Column name mapping ---
    # Pipeline uses time_days/status; Shiny UI labels use os_time/iss_stage
    # This helper resolves the actual column names in the data
    resolve_cols <- function(surv_data, endpoint) {
      if (endpoint == "os") {
        time_col <- dplyr::case_when(
          "time_days" %in% names(surv_data) ~ "time_days",
          "os_time" %in% names(surv_data) ~ "os_time",
          TRUE ~ "time"
        )
        status_col <- if ("status" %in% names(surv_data)) "status" else "os_status"
      } else {
        time_col <- if ("pfs_time" %in% names(surv_data)) "pfs_time" else "time"
        status_col <- if ("pfs_status" %in% names(surv_data)) "pfs_status" else "status"
      }
      list(time = time_col, status = status_col)
    }

    # Map UI group_by values to pipeline column names
    resolve_strata <- function(group_by) {
      switch(group_by,
        "stage" = "iss_stage",
        group_by
      )
    }

    # Try loading a pre-computed target, return NULL on failure
    try_tar_read <- function(target_name) {
      tryCatch(
        targets::tar_read_raw(target_name),
        error = function(e) NULL
      )
    }

    # Build lookup key for pre-computed KM targets
    km_target_key <- function(endpoint, group_by) {
      strata_key <- switch(group_by,
        "none" = "overall",
        "risk_group" = "risk_group",
        "stage" = "iss_stage",
        "iss_stage" = "iss_stage",
        "response" = "response",
        NULL
      )
      if (is.null(strata_key)) return(NULL)
      paste0(endpoint, "_", strata_key)
    }

    # Lookup index for pre-computed KM targets
    km_target_map <- list(
      os_overall    = "km_overall",
      os_risk_group = "km_by_risk",
      os_iss_stage  = "km_by_iss",
      os_response   = "shiny_km_os_by_response",
      pfs_overall   = "shiny_km_pfs_overall",
      pfs_risk_group = "shiny_km_pfs_by_risk",
      pfs_iss_stage = "shiny_km_pfs_by_iss"
    )

    risk_target_map <- list(
      os_overall    = "shiny_risk_os_overall",
      os_risk_group = "shiny_risk_os_by_risk",
      os_iss_stage  = "shiny_risk_os_by_iss",
      os_response   = "shiny_risk_os_by_response",
      pfs_overall   = "shiny_risk_pfs_overall",
      pfs_risk_group = "shiny_risk_pfs_by_risk",
      pfs_iss_stage = "shiny_risk_pfs_by_iss"
    )

    # Survival summary
    output$survival_summary <- renderTable({
      req(shared_data$survival_data)

      surv_data <- shared_data$survival_data
      cols <- resolve_cols(surv_data, input$survival_type)
      time_col <- cols$time
      status_col <- cols$status

      if (time_col %in% names(surv_data) && status_col %in% names(surv_data)) {
        data.frame(
          Metric = c("Total Patients", "Events", "Censored",
                    "Median Follow-up", "1-Year Rate"),
          Value = c(
            nrow(surv_data),
            sum(surv_data[[status_col]], na.rm = TRUE),
            sum(!surv_data[[status_col]], na.rm = TRUE),
            round(median(surv_data[[time_col]], na.rm = TRUE), 1),
            "Calculated in plot"
          ),
          stringsAsFactors = FALSE
        )
      } else {
        data.frame(
          Metric = "No survival data",
          Value = "Load data first",
          stringsAsFactors = FALSE
        )
      }
    })

    # Kaplan-Meier plot
    output$km_plot <- renderPlotly({
      req(shared_data$survival_data)

      surv_data <- shared_data$survival_data
      cols <- resolve_cols(surv_data, input$survival_type)
      time_col <- cols$time
      status_col <- cols$status
      title_text <- if (input$survival_type == "os") {
        "Overall Survival"
      } else {
        "Progression-Free Survival"
      }

      # Check if columns exist
      if (!time_col %in% names(surv_data) || !status_col %in% names(surv_data)) {
        return(plot_ly() %>%
          layout(
            title = title_text,
            annotations = list(
              text = "Survival data not available",
              showarrow = FALSE,
              xref = "paper", yref = "paper",
              x = 0.5, y = 0.5
            )
          ))
      }

      # Create survival object and fit
      strata_col <- resolve_strata(input$group_by)
      if (input$group_by != "none" && strata_col %in% names(surv_data)) {
        formula <- as.formula(paste0("survival::Surv(", time_col, ", ", status_col, ") ~ ", strata_col))
        fit <- survival::survfit(formula, data = surv_data)

        # Get unique groups
        groups <- unique(surv_data[[strata_col]])
        n_groups <- length(groups)

        # Create plot data for each stratum
        plot_list <- list()
        colors <- c("#2E86AB", "#A23B72", "#F18F01", "#C73E1D")

        for (i in 1:n_groups) {
          stratum_data <- data.frame(
            time = fit$time[fit$strata == i],
            surv = fit$surv[fit$strata == i],
            upper = fit$upper[fit$strata == i],
            lower = fit$lower[fit$strata == i],
            n.risk = fit$n.risk[fit$strata == i],
            n.event = fit$n.event[fit$strata == i]
          )

          # Add starting point
          stratum_data <- rbind(
            data.frame(time = 0, surv = 1, upper = 1, lower = 1,
                      n.risk = fit$n[i], n.event = 0),
            stratum_data
          )

          plot_list[[i]] <- list(
            x = stratum_data$time,
            y = stratum_data$surv,
            name = as.character(groups[i]),
            type = 'scatter',
            mode = 'lines',
            line = list(shape = 'hv', color = colors[i], width = 2),
            hovertemplate = paste0(
              "Group: ", groups[i],
              "<br>Time: %{x:.0f}",
              "<br>Survival: %{y:.2%}",
              "<extra></extra>"
            )
          )
        }

        p <- plot_ly() %>%
          layout(
            title = paste(title_text, "by", strata_col),
            xaxis = list(title = "Time (days)"),
            yaxis = list(title = "Survival Probability", range = c(0, 1)),
            hovermode = 'x unified'
          )

        for (trace in plot_list) {
          p <- add_trace(p,
            x = trace$x, y = trace$y,
            name = trace$name,
            type = trace$type,
            mode = trace$mode,
            line = trace$line,
            hovertemplate = trace$hovertemplate
          )
        }

      } else {
        # Overall survival without groups
        formula <- as.formula(paste0("survival::Surv(", time_col, ", ", status_col, ") ~ 1"))
        fit <- survival::survfit(formula, data = surv_data)

        surv_df <- data.frame(
          time = c(0, fit$time),
          surv = c(1, fit$surv),
          upper = c(1, fit$upper),
          lower = c(1, fit$lower)
        )

        p <- plot_ly(
          data = surv_df,
          x = ~time,
          y = ~surv,
          type = 'scatter',
          mode = 'lines',
          line = list(shape = 'hv', color = '#2E86AB', width = 2),
          name = 'Survival',
          hovertemplate = "Time: %{x:.0f}<br>Survival: %{y:.2%}<extra></extra>"
        ) %>%
          add_ribbons(
            y = ~upper,
            ymin = ~lower,
            line = list(color = 'transparent'),
            fillcolor = 'rgba(46, 134, 171, 0.2)',
            name = '95% CI',
            showlegend = FALSE,
            hoverinfo = 'skip'
          ) %>%
          layout(
            title = title_text,
            xaxis = list(title = "Time (days)"),
            yaxis = list(title = "Survival Probability", range = c(0, 1))
          )
      }

      p
    })

    # KM statistics
    output$km_stats <- renderPrint({
      req(shared_data$survival_data)

      surv_data <- shared_data$survival_data
      cols <- resolve_cols(surv_data, input$survival_type)
      time_col <- cols$time
      status_col <- cols$status

      if (time_col %in% names(surv_data) && status_col %in% names(surv_data)) {
        strata_col <- resolve_strata(input$group_by)
        if (input$group_by != "none" && strata_col %in% names(surv_data)) {
          formula <- as.formula(paste0("survival::Surv(", time_col, ", ", status_col, ") ~ ", strata_col))

          # Log-rank test
          survdiff_result <- survival::survdiff(formula, data = surv_data)
          p_value <- 1 - pchisq(survdiff_result$chisq, length(survdiff_result$n) - 1)

          cat("Log-rank test p-value:", format(p_value, digits = 4), "\n")

          # Median survival by group
          fit <- survival::survfit(formula, data = surv_data)
          print(fit)
        } else {
          formula <- as.formula(paste0("survival::Surv(", time_col, ", ", status_col, ") ~ 1"))
          fit <- survival::survfit(formula, data = surv_data)
          print(fit)
        }
      } else {
        cat("Survival data not available")
      }
    })

    # Run Cox regression
    observeEvent(input$run_cox, {
      req(shared_data$survival_data)
      req(length(input$cox_covariates) > 0)

      surv_data <- shared_data$survival_data
      cols <- resolve_cols(surv_data, input$survival_type)
      time_col <- cols$time
      status_col <- cols$status

      # Map UI covariate names to pipeline column names
      covar_map <- c(
        "age" = "age_years",
        "stage" = "iss_stage",
        "risk_group" = "risk_group"
      )
      mapped_covars <- unname(covar_map[input$cox_covariates])
      mapped_covars <- mapped_covars[!is.na(mapped_covars)]

      # Check which covariates are available
      available_covars <- intersect(mapped_covars, names(surv_data))

      if (length(available_covars) > 0 && time_col %in% names(surv_data)) {
        # Create formula
        formula <- as.formula(paste0(
          "survival::Surv(", time_col, ", ", status_col, ") ~ ",
          paste(available_covars, collapse = " + ")
        ))

        # Fit Cox model
        cox_fit <- survival::coxph(formula, data = surv_data)

        # Store results
        cox_results(broom::tidy(cox_fit, exponentiate = TRUE, conf.int = TRUE))
      }
    })

    # Forest plot for Cox regression
    output$forest_plot <- renderPlotly({
      req(cox_results())

      df <- cox_results()

      # Create forest plot
      p <- plot_ly(
        data = df,
        x = ~estimate,
        y = ~term,
        type = 'scatter',
        mode = 'markers',
        marker = list(size = 10, color = '#2E86AB'),
        error_x = list(
          type = 'data',
          symmetric = FALSE,
          array = ~(conf.high - estimate),
          arrayminus = ~(estimate - conf.low),
          color = '#2E86AB'
        ),
        text = ~paste("Variable:", term,
                     "<br>HR:", round(estimate, 3),
                     "<br>95% CI:", round(conf.low, 3), "-", round(conf.high, 3),
                     "<br>P-value:", format(p.value, digits = 3)),
        hovertemplate = "%{text}<extra></extra>"
      ) %>%
        layout(
          title = "Forest Plot - Hazard Ratios",
          xaxis = list(
            title = "Hazard Ratio (95% CI)",
            zeroline = FALSE,
            type = 'log'
          ),
          yaxis = list(title = ""),
          shapes = list(
            list(
              type = 'line',
              x0 = 1, x1 = 1,
              y0 = -0.5, y1 = length(df$term) - 0.5,
              line = list(color = 'gray', dash = 'dash', width = 1)
            )
          )
        )

      p
    })

    # Cox regression table
    output$cox_table <- renderTable({
      req(cox_results())

      df <- cox_results()

      # Format for display
      display_df <- data.frame(
        Variable = df$term,
        `Hazard Ratio` = round(df$estimate, 3),
        `95% CI` = paste0("(", round(df$conf.low, 3), ", ", round(df$conf.high, 3), ")"),
        `P-value` = format(df$p.value, digits = 3),
        stringsAsFactors = FALSE
      )

      display_df
    })

    # Risk table
    output$risk_table <- renderDT({
      req(shared_data$survival_data)

      surv_data <- shared_data$survival_data
      cols <- resolve_cols(surv_data, input$survival_type)
      time_col <- cols$time
      status_col <- cols$status

      if (time_col %in% names(surv_data) && status_col %in% names(surv_data)) {
        # Try pre-computed risk table first
        key <- km_target_key(input$survival_type, input$group_by)
        pre_risk <- if (!is.null(key) && key %in% names(risk_target_map)) {
          try_tar_read(risk_target_map[[key]])
        }

        if (!is.null(pre_risk) && is.data.frame(pre_risk) && nrow(pre_risk) > 0) {
          risk_table <- pre_risk
        } else {
          # Fallback: compute on-the-fly
          time_points <- c(0, 365, 730, 1095, 1460)
          strata_col <- resolve_strata(input$group_by)

          if (input$group_by != "none" && strata_col %in% names(surv_data)) {
            formula <- as.formula(paste0(
              "survival::Surv(", time_col, ", ", status_col, ") ~ ", strata_col
            ))
            fit <- summary(
              survival::survfit(formula, data = surv_data),
              times = time_points
            )

            risk_table <- data.frame(
              Time = fit$time,
              Group = as.character(fit$strata),
              N_at_Risk = fit$n.risk,
              N_Events = fit$n.event,
              Survival = round(fit$surv, 3),
              stringsAsFactors = FALSE
            )
          } else {
            formula <- as.formula(paste0(
              "survival::Surv(", time_col, ", ", status_col, ") ~ 1"
            ))
            fit <- summary(
              survival::survfit(formula, data = surv_data),
              times = time_points
            )

            risk_table <- data.frame(
              Time = time_points,
              N_at_Risk = fit$n.risk,
              N_Events = fit$n.event,
              Survival = round(fit$surv, 3),
              stringsAsFactors = FALSE
            )
          }
        }

        datatable(
          risk_table,
          options = list(pageLength = 10, dom = "t"),
          rownames = FALSE
        )
      } else {
        datatable(data.frame(Message = "No survival data available"))
      }
    })

    # Survival data table
    output$survival_data_table <- renderDT({
      req(shared_data$survival_data)

      # Display first 100 rows
      display_df <- head(shared_data$survival_data, 100)

      # Round numeric columns
      numeric_cols <- sapply(display_df, is.numeric)
      display_df[numeric_cols] <- lapply(display_df[numeric_cols], function(x) round(x, 2))

      datatable(
        display_df,
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
  })
}