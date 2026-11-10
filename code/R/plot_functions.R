# Shared spaghetti and scatter plot functions for the MRS group figures.

get_ptau_colors <- function(ptau_labels) {
  setNames(
    c("#457B9D", "#2A9D8F", "#E76F51")[seq_along(ptau_labels)],
    ptau_labels
  )
}

make_spaghetti_panel_labels <- function(group_summary, mrs_levels) {
  panel_labels <- setNames(
    sprintf(
      "%s\nN = %d participants; MRS z fixed at %.2f",
      as.character(group_summary$MRS_group),
      group_summary$n_participants,
      group_summary$MRS_z_median
    ),
    as.character(group_summary$MRS_group)
  )
  panel_labels[mrs_levels]
}

make_scatter_panel_labels <- function(group_summary, mrs_levels) {
  setNames(
    sprintf(
      "%s\nN = %d participants", mrs_levels,
      group_summary$n_participants[match(
        mrs_levels, as.character(group_summary$MRS_group)
      )]
    ),
    mrs_levels
  )
}

# Add the facet-panel column; `panel_labels` is named by MRS group.
add_panel_column <- function(df, panel_labels) {
  df %>%
    dplyr::mutate(
      MRS_panel = factor(
        as.character(.data$MRS_group),
        levels = names(panel_labels), labels = unname(panel_labels)
      )
    )
}

make_spaghetti_caption <- function(reference_values, width = 110) {
  text <- sprintf(
    paste0(
      "Gray: observed participant trajectories. Shading: pointwise 95%% CI for ",
      "the adjusted mean. MRS z is fixed at each group's participant median. ",
      "pTau display values are pooled participant-level quartiles. ",
      "Age z = 0; PHC sex = %s; APOE4 = %s; education = %.2f. ",
      "Check the predictor-range table for subgroup support of these pTau values."
    ),
    reference_values$PHC_Sex,
    as.character(reference_values$APOE4),
    reference_values$PHC_Education
  )
  wrap_caption(text, width)
}

make_scatter_caption <- function(width = 110) {
  text <- paste(
    "One point per participant. Correlation: Spearman rho and two-sided P.",
    "Trend: ordinary least-squares line with a 95% confidence band.",
    "Panels share the y-axis; each x-axis ends at the MRS cutoff (the median)."
  )
  wrap_caption(text, width)
}

# Wrap a caption at `width` characters, joining the lines with "\n".
wrap_caption <- function(text, width) {
  paste(strwrap(gsub("\n", " ", text, fixed = TRUE), width = width), collapse = "\n")
}

prediction_ribbon_layer <- function(prediction_data) {
  ggplot2::geom_ribbon(
    data = prediction_data,
    ggplot2::aes(
      x = time, ymin = lower.CL, ymax = upper.CL,
      group = pTau_label, fill = pTau_label
    ),
    alpha = 0.16
  )
}

observed_trajectory_layers <- function(observed_data) {
  list(
    ggplot2::geom_line(
      data = observed_data,
      ggplot2::aes(x = time, y = PHC_MEM, group = RID),
      color = "gray55", alpha = 0.25, linewidth = 0.4
    ),
    ggplot2::geom_point(
      data = observed_data,
      ggplot2::aes(x = time, y = PHC_MEM),
      color = "gray55", alpha = 0.25, size = 0.7
    )
  )
}

prediction_line_layer <- function(prediction_data) {
  ggplot2::geom_line(
    data = prediction_data,
    ggplot2::aes(x = time, y = emmean, group = pTau_label, color = pTau_label),
    linewidth = 1.3
  )
}

spaghetti_scales <- function(ptau_colors) {
  list(
    ggplot2::scale_color_manual(values = ptau_colors, drop = FALSE),
    ggplot2::scale_fill_manual(values = ptau_colors, drop = FALSE),
    # Leave breathing room between the trajectories and the panel boundaries.
    ggplot2::scale_x_continuous(
      expand = ggplot2::expansion(mult = c(0.04, 0.06))
    ),
    ggplot2::scale_y_continuous(
      expand = ggplot2::expansion(mult = c(0.10, 0.10))
    )
  )
}

spaghetti_labels <- function(caption) {
  ggplot2::labs(
    title = "Observed memory and adjusted pTau trajectories by MRS group",
    subtitle = "Separate Reduced Models; continuous MRS and baseline pTau within each group",
    x = "Time since baseline (years)", y = "PHC Memory",
    color = "Baseline pTau value", caption = caption
  )
}

# Outer margins, panel spacing, and legend placement.
spaghetti_layout_theme <- function() {
  ggplot2::theme(
    plot.margin = ggplot2::margin(t = 24, r = 28, b = 24, l = 28),
    panel.spacing.x = grid::unit(2, "lines"),
    legend.position = "bottom",
    legend.box.spacing = grid::unit(14, "pt"),
    legend.margin = ggplot2::margin(t = 8, b = 8),
    legend.spacing.x = grid::unit(12, "pt")
  )
}

# Spacing around the title, panel labels, axis titles, and caption.
spaghetti_text_theme <- function() {
  ggplot2::theme(
    plot.title = ggplot2::element_text(
      margin = ggplot2::margin(b = 10)
    ),
    plot.subtitle = ggplot2::element_text(
      margin = ggplot2::margin(b = 18)
    ),
    strip.text = ggplot2::element_text(
      lineheight = 1.15, margin = ggplot2::margin(t = 10, b = 14)
    ),
    axis.title.x = ggplot2::element_text(
      margin = ggplot2::margin(t = 14)
    ),
    axis.title.y = ggplot2::element_text(
      margin = ggplot2::margin(r = 14)
    ),
    plot.caption = ggplot2::element_text(
      hjust = 0, lineheight = 1.2,
      margin = ggplot2::margin(t = 18)
    )
  )
}

# The same spacing applies to the HTML figure and all saved PDF figures.
spaghetti_theme <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    spaghetti_layout_theme() +
    spaghetti_text_theme()
}

make_spaghetti_memory_plot <- function(
    observed_data, prediction_data, ptau_colors, caption
) {
  ggplot2::ggplot() +
    prediction_ribbon_layer(prediction_data) +
    observed_trajectory_layers(observed_data) +
    prediction_line_layer(prediction_data) +
    ggplot2::facet_wrap(~ MRS_panel, nrow = 1) +
    spaghetti_scales(ptau_colors) +
    spaghetti_labels(caption) +
    ggplot2::guides(fill = "none") +
    spaghetti_theme()
}

# The single-group figures share axis limits so they can be compared.
get_shared_axis_limits <- function(observed_data, prediction_data) {
  list(
    time = range(c(0, observed_data$time), finite = TRUE),
    memory = range(
      c(observed_data$PHC_MEM, prediction_data$lower.CL, prediction_data$upper.CL),
      finite = TRUE
    )
  )
}

make_group_spaghetti_plot <- function(
    group_name, observed_data, prediction_data, ptau_colors, caption,
    axis_limits
) {
  make_spaghetti_memory_plot(
    dplyr::filter(observed_data, .data$MRS_group == group_name),
    dplyr::filter(prediction_data, .data$MRS_group == group_name),
    ptau_colors, caption
  ) +
    ggplot2::coord_cartesian(
      xlim = axis_limits$time, ylim = axis_limits$memory
    ) +
    ggplot2::labs(
      title = paste("Observed memory and adjusted pTau trajectories:", group_name)
    )
}

scatter_point_and_trend_layers <- function() {
  list(
    ggplot2::geom_point(
      ggplot2::aes(color = MRS_group), alpha = 0.75, size = 2
    ),
    ggplot2::geom_smooth(
      method = "lm", formula = y ~ x, se = TRUE,
      color = "gray25", fill = "gray70", alpha = 0.3, linewidth = 0.9
    )
  )
}

scatter_correlation_label_layer <- function(label_data) {
  ggplot2::geom_label(
    data = label_data,
    ggplot2::aes(x = -Inf, y = Inf, label = label),
    inherit.aes = FALSE, hjust = -0.05, vjust = 1.1,
    size = 3.4, fill = "white"
  )
}

scatter_scales <- function() {
  list(
    ggplot2::scale_color_manual(
      values = c("Low MRS" = "#457B9D", "High MRS" = "#E76F51"),
      guide = "none"
    ),
    # The x-axis range of each panel is set by scatter_x_bounds_layer().
    ggplot2::scale_x_continuous(expand = ggplot2::expansion(mult = 0)),
    ggplot2::scale_y_continuous(
      expand = ggplot2::expansion(mult = c(0.05, 0.20))
    )
  )
}

# Each panel's x-axis runs from the outer edge of its own data (plus a small
# margin) to the MRS cutoff. The Low panel ends at the cutoff and the High panel
# starts at it, so no empty space is drawn where the other group's values would
# be. That gap only exists because the groups are defined by the cutoff.
scatter_x_bounds_layer <- function(
    scatter_data, mrs_cutoff, mrs_levels, margin = 0.05
) {
  bounds <- lapply(seq_along(mrs_levels), function(i) {
    group_data <- scatter_data[scatter_data$MRS_group == mrs_levels[i], ]
    x_range <- range(group_data$mrs_z)
    padding <- margin * diff(x_range)
    # mrs_levels[1] is the low group: its outer edge is on the left.
    x_limits <- if (i == 1L) {
      c(x_range[1] - padding, mrs_cutoff)
    } else {
      c(mrs_cutoff, x_range[2] + padding)
    }
    data.frame(MRS_panel = group_data$MRS_panel[1], mrs_z = x_limits)
  })

  ggplot2::geom_blank(
    data = dplyr::bind_rows(bounds),
    ggplot2::aes(x = mrs_z), inherit.aes = FALSE
  )
}

make_mrs_ptau_scatter_plot <- function(
    scatter_data, label_data, caption, mrs_cutoff, mrs_levels
) {
  ggplot2::ggplot(
    scatter_data,
    ggplot2::aes(x = mrs_z, y = baseline_pTau)
  ) +
    scatter_point_and_trend_layers() +
    scatter_correlation_label_layer(label_data) +
    scatter_x_bounds_layer(scatter_data, mrs_cutoff, mrs_levels) +
    # x differs by panel (it stops at the cutoff); y stays shared.
    ggplot2::facet_wrap(~ MRS_panel, nrow = 1, scales = "free_x") +
    scatter_scales() +
    # Points exactly on the cutoff sit on the panel edge; do not clip them.
    ggplot2::coord_cartesian(clip = "off") +
    ggplot2::labs(
      title = "MRS and baseline pTau within high and low MRS groups",
      x = "MRS (pooled participant-level z-score)",
      y = "Baseline pTau (input-data scale)",
      caption = caption
    ) +
    ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(plot.caption = ggplot2::element_text(hjust = 0))
}
