# Shared formatting and comparison-table functions for the MRS groups.

# Vectorized: returns "Not estimable" wherever the P value is not finite.
format_p_value <- function(p_value) {
  ifelse(
    is.finite(p_value),
    format.pval(p_value, digits = 3, eps = 0.001),
    "Not estimable"
  )
}

format_mean_sd_median <- function(x) {
  if (length(x) == 0L) {
    return("\u2014")
  }
  sprintf("%.2f \u00b1 %.2f (%.2f)", mean(x), stats::sd(x), stats::median(x))
}

format_count_percent <- function(count, denominator) {
  if (denominator == 0L) {
    return("\u2014")
  }
  sprintf("%d (%.1f%%)", count, 100 * count / denominator)
}

# Spearman correlation of MRS with baseline pTau in one group's participants.
spearman_one_group <- function(group_df, group_name, mrs_levels) {
  n_group <- nrow(group_df)
  estimable <- n_group >= 3L &&
    dplyr::n_distinct(group_df$mrs_z) > 1L &&
    dplyr::n_distinct(group_df$baseline_pTau) > 1L

  if (estimable) {
    test <- stats::cor.test(
      group_df$mrs_z, group_df$baseline_pTau,
      method = "spearman", exact = FALSE
    )
    rho <- unname(test$estimate)
    p_value <- test$p.value
    label <- sprintf(
      "Spearman rho = %.2f\nP = %s",
      rho, format.pval(p_value, digits = 3, eps = 0.001)
    )
  } else {
    rho <- NA_real_
    p_value <- NA_real_
    label <- "Spearman correlation not estimable"
  }

  data.frame(
    MRS_group = factor(group_name, levels = mrs_levels),
    N = n_group, rho = rho, p_value = p_value,
    label = label
  )
}

compute_spearman_by_group <- function(participants, mrs_levels) {
  rows <- lapply(mrs_levels, function(group_name) {
    spearman_one_group(
      dplyr::filter(participants, .data$MRS_group == group_name),
      group_name, mrs_levels
    )
  })
  dplyr::bind_rows(rows)
}

format_spearman_table <- function(spearman_results) {
  spearman_results %>%
    dplyr::transmute(
      MRS_group, N,
      Spearman_rho = round(.data$rho, 3),
      P = format_p_value(.data$p_value)
    )
}

# NA if the test cannot be run (fewer than two groups, or no variation).
kruskal_p_value <- function(values, groups) {
  groups <- droplevels(groups)
  if (nlevels(groups) < 2L || length(unique(values)) <= 1L) {
    return(NA_real_)
  }
  tryCatch(
    stats::kruskal.test(values, groups)$p.value,
    error = function(e) NA_real_
  )
}

# One table row: participant N, mean +/- SD (median) per group, and the test.
summarize_continuous_variable <- function(data, variable, label, group_levels) {
  values <- data[[variable]]
  usable <- is.finite(values)

  row <- data.frame(
    Variable = unname(label),
    `Total N` = sum(usable), check.names = FALSE
  )
  for (group in group_levels) {
    x <- values[usable & as.character(data$MRS_group) == group]
    short_name <- sub(" MRS$", "", group)
    row[[paste(short_name, "N")]] <- length(x)
    row[[group]] <- format_mean_sd_median(x)
  }
  row[["Kruskal-Wallis P"]] <- format_p_value(
    kruskal_p_value(values[usable], data$MRS_group[usable])
  )
  row
}

summarize_mrs_continuous <- function(data, variable_labels, group_levels) {
  rows <- lapply(names(variable_labels), function(variable) {
    summarize_continuous_variable(
      data, variable, variable_labels[[variable]], group_levels
    )
  })
  dplyr::bind_rows(rows)
}

summarize_followup <- function(model_df) {
  model_df %>%
    dplyr::group_by(.data$RID, .data$MRS_group) %>%
    dplyr::summarise(
      followup_years = max(.data$time),
      n_visits = dplyr::n_distinct(.data$time),
      .groups = "drop"
    )
}

fisher_p_value <- function(counts, variable) {
  # Drop empty rows and columns before testing.
  test_counts <- counts[
    rowSums(counts) > 0L, colSums(counts) > 0L, drop = FALSE
  ]
  if (!all(dim(test_counts) >= 2L)) {
    return(NA_real_)
  }
  tryCatch(
    stats::fisher.test(test_counts, workspace = 20000000)$p.value,
    error = function(e) {
      warning(
        "Fisher test for ", variable, " could not be computed: ",
        conditionMessage(e)
      )
      NA_real_
    }
  )
}

# One table row for level `i` of a variable (`counts`: levels x groups).
categorical_level_row <- function(label, counts, i, total_n, fisher_p) {
  row <- data.frame(
    Variable = label,
    Level = rownames(counts)[i],
    `Total N` = total_n,
    `Total level n` = sum(counts[i, ]),
    check.names = FALSE
  )
  for (j in seq_len(ncol(counts))) {
    group <- colnames(counts)[j]
    denominator <- sum(counts[, j])
    short_name <- sub(" MRS$", "", group)
    row[[paste(short_name, "N")]] <- denominator
    row[[group]] <- format_count_percent(counts[i, j], denominator)
  }
  row[["Fisher P"]] <- format_p_value(fisher_p)
  row
}

summarize_categorical_variable <- function(data, variable, label, group_levels) {
  # Missing or empty values are excluded from every denominator.
  level_chr <- as.character(data[[variable]])
  keep <- !is.na(level_chr) & nzchar(level_chr)
  level_chr <- level_chr[keep]

  level_values <- sort(unique(level_chr))
  counts <- table(
    factor(level_chr, levels = level_values),
    factor(data$MRS_group[keep], levels = group_levels)
  )
  fisher_p <- fisher_p_value(counts, variable)

  rows <- lapply(seq_along(level_values), function(i) {
    categorical_level_row(label, counts, i, length(level_chr), fisher_p)
  })
  dplyr::bind_rows(rows)
}

summarize_mrs_categorical <- function(data, variable_labels, group_levels) {
  rows <- lapply(names(variable_labels), function(variable) {
    summarize_categorical_variable(
      data, variable, variable_labels[[variable]], group_levels
    )
  })
  dplyr::bind_rows(rows)
}
