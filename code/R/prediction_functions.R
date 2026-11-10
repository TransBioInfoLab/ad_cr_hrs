# Shared covariate reference values and adjusted (emmeans) predictions.

# Most common level of `column` among participants, restricted to levels
# observed in every group's dataset.
common_reference_level <- function(column, group_dfs, participants) {
  common_levels <- Reduce(intersect, lapply(group_dfs, function(df) {
    as.character(unique(df[[column]]))
  }))
  if (!length(common_levels)) {
    stop("No common observed reference level for ", column, " across groups.")
  }
  counts <- table(participants[[column]])
  counts <- counts[names(counts) %in% common_levels]
  names(sort(counts, decreasing = TRUE))[1]
}

get_reference_values <- function(participants, group_dfs) {
  if (is.numeric(participants$APOE4)) {
    apoe_ref <- as.numeric(
      names(sort(table(participants$APOE4), decreasing = TRUE))[1]
    )
  } else {
    apoe_ref <- common_reference_level("APOE4", group_dfs, participants)
  }

  list(
    baseline_age_z = 0,
    PHC_Sex = common_reference_level("PHC_Sex", group_dfs, participants),
    APOE4 = apoe_ref,
    PHC_Education = mean(participants$PHC_Education)
  )
}

# Quartiles of baseline pTau. If quartiles coincide, the shared value is kept
# once and its label lists every percentile it stands for.
get_ptau_display_values <- function(participants) {
  percentile_names <- c("25th", "50th", "75th")
  quantiles <- stats::quantile(
    participants$baseline_pTau, probs = c(0.25, 0.50, 0.75), names = FALSE
  )
  values <- sort(unique(as.numeric(quantiles)))
  labels <- vapply(values, function(value) {
    paste0(
      "pTau: ",
      paste(percentile_names[quantiles == value], collapse = "/"),
      " percentile"
    )
  }, character(1))

  list(quantiles = quantiles, values = values, labels = labels)
}

make_ptau_quantile_table <- function(ptau_display) {
  data.frame(
    percentile = c("25th", "50th", "75th"),
    baseline_pTau = as.numeric(ptau_display$quantiles)
  )
}

warn_if_ptau_outside_range <- function(group_name, group_participants, ptau_values) {
  outside_values <- ptau_values[
    ptau_values < min(group_participants$baseline_pTau) |
      ptau_values > max(group_participants$baseline_pTau)
  ]
  if (length(outside_values)) {
    warning(
      group_name, ": pTau display values outside the observed group range: ",
      paste(signif(outside_values, 4), collapse = ", "),
      ". These fitted curves extrapolate beyond that group's pTau range."
    )
  }
}

# Adjusted mean memory over time at each pTau display value, from one group's
# own Reduced Model, with MRS held at that group's median.
predict_group_trajectories <- function(
    model, group_df, group_name, reference_values, ptau_values, mrs_levels
) {
  group_participants <- dplyr::distinct(group_df, .data$RID, .keep_all = TRUE)
  warn_if_ptau_outside_range(group_name, group_participants, ptau_values)

  group_mrs_median <- stats::median(group_participants$mrs_z)
  prediction_at <- c(reference_values, list(
    baseline_pTau = ptau_values,
    mrs_z = group_mrs_median,
    time = seq(0, max(group_df$time), length.out = 101)
  ))
  predictions <- as.data.frame(stats::confint(emmeans::emmeans(
    model, specs = ~ baseline_pTau * time,
    at = prediction_at, lmer.df = "satterthwaite", lmerTest.limit = Inf
  ), level = 0.95))
  predictions$MRS_group <- factor(group_name, levels = mrs_levels)
  predictions$mrs_z_reference <- group_mrs_median
  predictions
}

make_memory_predictions <- function(
    models, group_dfs, reference_values, ptau_display, mrs_levels
) {
  prediction_list <- lapply(mrs_levels, function(group_name) {
    predict_group_trajectories(
      models[[group_name]], group_dfs[[group_name]], group_name,
      reference_values, ptau_display$values, mrs_levels
    )
  })

  dplyr::bind_rows(prediction_list) %>%
    dplyr::mutate(
      pTau_label = factor(
        .data$baseline_pTau,
        levels = ptau_display$values, labels = ptau_display$labels
      )
    )
}
