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
theme_commpass_dark <- function(base_size = 10) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.background = ggplot2::element_rect(fill = "#1a1a2e", color = NA),
      panel.background = ggplot2::element_rect(fill = "#1a1a2e", color = NA),
      panel.grid.major = ggplot2::element_line(color = "#2d2d44", linewidth = 0.3),
      panel.grid.minor = ggplot2::element_line(color = "#252540", linewidth = 0.2),
      text = ggplot2::element_text(color = "#e0e0e0"),
      axis.text = ggplot2::element_text(color = "#b0b0b0"),
      axis.title = ggplot2::element_text(color = "#d0d0d0"),
      plot.title = ggplot2::element_text(color = "white", face = "bold"),
      plot.subtitle = ggplot2::element_text(color = "#b0b0b0"),
      plot.caption = ggplot2::element_text(
        color = "#888888", size = 7, hjust = 0, lineheight = 1.2
      ),
      legend.background = ggplot2::element_rect(fill = "#1a1a2e", color = NA),
      legend.text = ggplot2::element_text(color = "#d0d0d0"),
      legend.title = ggplot2::element_text(color = "#e0e0e0"),
      strip.text = ggplot2::element_text(color = "white", face = "bold"),
      strip.background = ggplot2::element_rect(fill = "#252540", color = NA)
    )
}
