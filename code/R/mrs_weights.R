# Shared CpG and DMR weight construction.

get_cpg_weights <- function() {
  cpg_df <- read.csv(
    file.path(save_dir, "comb-p-DMRs", "interact_mQTLs_inputs.csv")
  ) %>%
    dplyr::select(cpg = "cpgs", "Sources") %>%
    dplyr::mutate(is_individual = .data$Sources != "CpG in DMR")
  valid_sources <- c("individual CpG", "CpG in DMR", "DMR and Individual CpG")
  if (anyNA(cpg_df$Sources) || any(!cpg_df$Sources %in% valid_sources)) {
    stop("The selected CpG list contains an unexpected Sources value.")
  }
  dmr_df <- read.csv(
    file.path(save_dir, "comb-p-DMRs", "interact_DMRs.csv")
  ) %>%
    dplyr::select("DMR", cpg = "cpgs_in_region") %>%
    tidyr::separate_longer_delim("cpg", delim = ",") %>%
    dplyr::distinct(.data$DMR, .data$cpg)

  count_df <- dmr_df %>%
    dplyr::group_by(.data$DMR) %>%
    dplyr::summarise(dmr_size = dplyr::n()) %>%
    dplyr::ungroup()

  weights_df <- cpg_df %>%
    dplyr::left_join(dmr_df, by = "cpg") %>%
    dplyr::left_join(count_df, by = "DMR") %>%
    tidyr::replace_na(list(DMR = "", dmr_size = 0)) %>%
    dplyr::mutate(
      cpg_weight = as.numeric(.data$is_individual) +
        dplyr::if_else(.data$dmr_size > 0, 1 / .data$dmr_size, 0)
    )

  if (anyDuplicated(weights_df$cpg)) {
    stop("A selected CpG belongs to multiple DMRs or is duplicated in the input.")
  }
  expected_dmr <- weights_df$Sources %in%
    c("CpG in DMR", "DMR and Individual CpG")
  if (any(expected_dmr != (weights_df$dmr_size > 0))) {
    stop("Sources and DMR assignments disagree for selected CpGs.")
  }
  selected_counts_df <- weights_df %>%
    dplyr::filter(.data$dmr_size > 0) %>%
    dplyr::count(.data$DMR, name = "selected_size") %>%
    dplyr::left_join(count_df, by = "DMR")
  if (any(selected_counts_df$selected_size != selected_counts_df$dmr_size)) {
    stop("A DMR contains CpGs absent from the selected CpG list.")
  }

  weights_df
}

get_memory_weights <- function() {
  weights_df <- get_cpg_weights()
  stats_df <- read.csv(
    file.path(save_dir, "linear_model", "EAP_stats_bacon_interact.csv")
  )
  ptau_df <- read.csv(
    file.path(save_dir, "linear_model", "EAP_stats_bacon_ptau.csv")
  )

  weights_df <- weights_df %>%
    dplyr::left_join(
      stats_df %>%
        dplyr::select(cpg = "CpG", gamma = "estimate"),
      by = "cpg"
    ) %>%
    dplyr::left_join(
      ptau_df %>%
        dplyr::select(cpg = "CpG", beta_ptau = "estimate"),
      by = "cpg"
    ) %>%
    dplyr::mutate(
      weighted_ptau = .data$cpg_weight * .data$beta_ptau,
      weighted_gamma = .data$cpg_weight * .data$gamma
    )

  weights_df
}

# Add unavailable CpGs as missing values when scoring a different array.
add_missing_cpg_rows <- function(beta_mat, weight_df) {
  if (!is.matrix(beta_mat) || !is.numeric(beta_mat) ||
      is.null(rownames(beta_mat)) || anyNA(rownames(beta_mat)) ||
      anyDuplicated(rownames(beta_mat))) {
    stop("beta_mat must be a numeric matrix with unique, nonmissing CpG row names.")
  }
  if (!is.data.frame(weight_df) || !"cpg" %in% names(weight_df)) {
    stop("weight_df must be a data frame with a cpg column.")
  }

  weighted_cpgs <- as.character(weight_df$cpg)
  if (anyNA(weighted_cpgs) || any(weighted_cpgs == "") ||
      anyDuplicated(weighted_cpgs)) {
    stop("weight_df$cpg must contain unique, nonmissing CpG IDs.")
  }

  missing_cpgs <- setdiff(weighted_cpgs, rownames(beta_mat))
  if (!length(missing_cpgs)) {
    return(beta_mat)
  }

  missing_beta_mat <- matrix(
    NA_real_,
    nrow = length(missing_cpgs),
    ncol = ncol(beta_mat),
    dimnames = list(missing_cpgs, colnames(beta_mat))
  )
  rbind(beta_mat, missing_beta_mat)
}
