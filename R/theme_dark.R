# R/viz/theme_dark.R
# Dark theme for all coMMpass plots — matches pkgdown dark mode

#' Dark theme for coMMpass plots
#'
#' A dark-background theme consistent with the pkgdown site's dark mode.
#' Applies to all ggplot2 plots rendered in vignettes.
#'
#' @param base_size Base font size (default 10)
#' @return A ggplot2 theme object
#' @keywords internal
theme_commpass_dark <- function(base_size = 14) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "black", color = NA),
      panel.background = ggplot2::element_rect(fill = "black", color = NA),
      panel.grid.major = ggplot2::element_line(color = "#333333", linewidth = 0.3),
      panel.grid.minor = ggplot2::element_blank(),
      text = ggplot2::element_text(color = "white"),
      axis.text = ggplot2::element_text(color = "#cccccc"),
      axis.title = ggplot2::element_text(color = "white"),
      axis.line = ggplot2::element_line(color = "white", linewidth = 0.5),
      plot.title = ggplot2::element_text(color = "white", face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "#b0b0b0"),
      plot.caption = ggplot2::element_text(
        color = "#888888", size = 7, hjust = 0, lineheight = 1.2
      ),
      legend.background = ggplot2::element_rect(fill = "black", color = NA),
      legend.text = ggplot2::element_text(color = "white"),
      legend.title = ggplot2::element_text(color = "white"),
      legend.position = "bottom",
      strip.text = ggplot2::element_text(color = "white", face = "bold"),
      strip.background = ggplot2::element_rect(fill = "#222222", color = NA)
    )
}
