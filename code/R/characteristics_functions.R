# Shared subject-characteristics table functions.

# Collapse recorded smoking status into ever and never smokers.
recode_smoking <- function(smoking) {
  dplyr::case_when(
    is.na(smoking) ~ NA_character_,
    smoking %in% c("Current", "Former") ~ "Ever_Smoker",
    smoking == "Never" ~ "Non-Smoker",
    TRUE ~ "Mislabeled"
  )
}

# HRS MCI subjects with recoded smoking status. With `longitudinal = TRUE`,
# only subjects with follow-up time and O'Shea memory in both waves are kept.
read_hrs_characteristics <- function(data_dir, longitudinal = FALSE) {
  pheno_df <- read.csv(file.path(data_dir, "NHW_HCAP_MCI.csv"))

  if (longitudinal) {
    pheno_df <- pheno_df %>%
      dplyr::filter(
        !is.na(.data$time),
        !is.na(.data$OSHEA_MEM_16),
        !is.na(.data$OSHEA_MEM_22)
      )
  }

  pheno_df %>%
    dplyr::mutate(Smoking = recode_smoking(.data$Smoking))
}

# Mean (SD) of a numeric column.
get_numeric_stats <- function(pheno_df, column) {
  pheno_df$data <- pheno_df[, column]

  res <- paste0(
    round(mean(pheno_df$data, na.rm = TRUE), 2),
    " (",
    round(stats::sd(pheno_df$data, na.rm = TRUE), 2),
    ")"
  )

  data.frame(
    label = column,
    category = "",
    statistic = res,
    exp_count = sum(!is.na(pheno_df$data)),
    missing_count = sum(is.na(pheno_df$data))
  )
}

# Count (percent) of each level of a categorical column.
get_categoric_stats <- function(pheno_df, column) {
  pheno_df$data <- pheno_df[, column]

  stat_df <- pheno_df %>%
    dplyr::mutate(data = ifelse(is.na(.data$data), "Not Reported", .data$data)) %>%
    dplyr::filter(!is.na(.data$data)) %>%
    dplyr::group_by(.data[[column]], .data$data) %>%
    dplyr::summarise(
      count = dplyr::n()
    ) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(rate = round(100 * count / nrow(pheno_df), digits = 2)) %>%
    dplyr::mutate(statistic = paste0(.data$count, " (", .data$rate, ")")) %>%
    dplyr::select(label = dplyr::all_of(column), category = "data", "statistic") %>%
    dplyr::mutate(label := column)

  stat_df$exp_count <- sum(!is.na(pheno_df$data))
  stat_df$missing_count <- sum(is.na(pheno_df$data))

  stat_df
}

get_stats <- function(pheno_df, column, category = c("numeric", "categoric")) {
  category <- match.arg(category)

  if (category == "numeric") {
    res_df <- get_numeric_stats(pheno_df, column)
  } else {
    res_df <- get_categoric_stats(pheno_df, column)
  }

  res_df
}

# One table of statistics for several columns. `column_types` is a named
# vector: names are columns, values are "numeric" or "categoric".
summarize_characteristics <- function(pheno_df, column_types) {
  plyr::ldply(
    .data = seq_along(column_types),
    .fun = function(index) {
      get_stats(pheno_df, names(column_types)[[index]], column_types[[index]])
    }
  )
}
