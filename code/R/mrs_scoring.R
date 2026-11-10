# Shared methylation resilience score functions.

validate_mrs_inputs <- function(beta_mat, weights_df) {
  required_columns <- c("cpg", "gamma", "beta_ptau", "DMR", "is_individual")
  missing_columns <- setdiff(required_columns, names(weights_df))
  if (length(missing_columns)) {
    stop("weights_df is missing: ", paste(missing_columns, collapse = ", "))
  }

  weights_df <- weights_df %>%
    as.data.frame(stringsAsFactors = FALSE) %>%
    dplyr::mutate(
      cpg = as.character(.data$cpg),
      DMR = trimws(as.character(.data$DMR)),
      DMR = ifelse(is.na(.data$DMR) | .data$DMR == "", NA_character_, .data$DMR)
    )

  if (!nrow(weights_df) || anyNA(weights_df$cpg) ||
      any(weights_df$cpg == "") || anyDuplicated(weights_df$cpg)) {
    stop("weights_df must have one row per nonmissing, unique CpG ID.")
  }
  if (!is.logical(weights_df$is_individual) ||
      anyNA(weights_df$is_individual)) {
    stop("weights_df$is_individual must be TRUE or FALSE for every CpG.")
  }
  if (any(!weights_df$is_individual & is.na(weights_df$DMR))) {
    stop("Every CpG must be individually significant, assigned to a DMR, or both.")
  }
  if (
    !is.numeric(weights_df$gamma) ||
    !is.numeric(weights_df$beta_ptau) ||
    any(!is.finite(weights_df$gamma)) ||
    any(!is.finite(weights_df$beta_ptau))
  ) {
    stop("gamma and beta_ptau must be finite numeric coefficients.")
  }

  beta_mat <- as.matrix(beta_mat)
  if (
    !is.numeric(beta_mat) ||
    !nrow(beta_mat) ||
    is.null(colnames(beta_mat)) ||
    anyNA(colnames(beta_mat)) ||
    anyDuplicated(colnames(beta_mat))
  ) {
    stop("beta_mat must be numeric with samples in rows and unique CpG column names.")
  }
  if (is.null(rownames(beta_mat))) {
    rownames(beta_mat) <- paste0("S", seq_len(nrow(beta_mat)))
  }
  if (anyNA(rownames(beta_mat)) || anyDuplicated(rownames(beta_mat))) {
    stop("beta_mat must have unique, nonmissing sample IDs.")
  }

  missing_cpgs <- setdiff(weights_df$cpg, colnames(beta_mat))
  if (length(missing_cpgs)) {
    stop(length(missing_cpgs), " selected CpGs are missing from beta_mat.")
  }
  beta_mat <- beta_mat[, weights_df$cpg, drop = FALSE]
  if (any(is.infinite(beta_mat))) {
    stop("Selected DNAm values contain infinity.")
  }

  list(beta_mat = beta_mat, weights_df = weights_df)
}

build_mrs_audit_table <- function(methylation_percent_mat, weighted_slope_mat,
                                  weights_df, mrs_df) {
  sample_ids <- rownames(methylation_percent_mat)
  safe_sample_ids <- make.names(sample_ids, unique = TRUE)
  wide_df <- data.frame(
    cpg = weights_df$cpg,
    DMR = weights_df$DMR,
    is_individual = weights_df$is_individual,
    gamma = weights_df$gamma,
    beta_ptau = weights_df$beta_ptau,
    stringsAsFactors = FALSE
  )
  for (index in seq_along(sample_ids)) {
    wide_df[[paste0(safe_sample_ids[index], "_dnam")]] <-
      as.numeric(methylation_percent_mat[index, ])
    wide_df[[paste0(safe_sample_ids[index], "_product")]] <-
      as.numeric(weighted_slope_mat[index, ])
  }

  mrs_row_df <- wide_df[1, , drop = FALSE]
  mrs_row_df[1, ] <- NA
  mrs_row_df$cpg <- "MRS"
  for (index in seq_along(sample_ids)) {
    mrs_row_df[[paste0(safe_sample_ids[index], "_product")]] <-
      mrs_df$MRS_raw[index]
  }
  wide_df <- rbind(wide_df, mrs_row_df)
  rownames(wide_df) <- NULL
  wide_df
}

validate_weighted_mrs_inputs <- function(beta_mat, weights_df) {
  required_columns <- c("cpg_weight", "weighted_gamma", "weighted_ptau")
  missing_columns <- setdiff(required_columns, names(weights_df))
  if (length(missing_columns)) {
    stop("weights_df is missing: ", paste(missing_columns, collapse = ", "))
  }

  validated_inputs_ls <- validate_mrs_inputs(beta_mat, weights_df)
  weights_df <- validated_inputs_ls$weights_df
  if (!is.numeric(weights_df$cpg_weight) ||
      !is.numeric(weights_df$weighted_gamma) ||
      !is.numeric(weights_df$weighted_ptau) ||
      any(!is.finite(weights_df$cpg_weight)) ||
      any(weights_df$cpg_weight <= 0) ||
      any(!is.finite(weights_df$weighted_gamma)) ||
      any(!is.finite(weights_df$weighted_ptau))) {
    stop("CpG weights and weighted coefficients must be finite numeric values.")
  }
  if (!isTRUE(all.equal(weights_df$weighted_gamma,
                        weights_df$cpg_weight * weights_df$gamma)) ||
      !isTRUE(all.equal(weights_df$weighted_ptau,
                        weights_df$cpg_weight * weights_df$beta_ptau))) {
    stop("Weighted coefficients do not match the CpG weights and coefficients.")
  }

  validated_inputs_ls
}

compute_weighted_cpg_slopes <- function(methylation_percent_mat, weights_df) {
  weighted_slope_mat <- sweep(
    methylation_percent_mat, 2, weights_df$weighted_gamma, "*"
  )
  sweep(weighted_slope_mat, 2, weights_df$weighted_ptau, "+")
}

summarize_weighted_mrs <- function(weighted_slope_mat, weights_df) {
  observed_mat <- !is.na(weighted_slope_mat)
  weighted_sum <- rowSums(weighted_slope_mat, na.rm = TRUE)
  # Missing CpGs contribute neither their slope nor their weight.
  total_weight <- as.numeric(observed_mat %*% weights_df$cpg_weight)
  raw_mrs <- weighted_sum / total_weight
  raw_mrs[total_weight == 0] <- NA_real_

  data.frame(
    sample_id = rownames(weighted_slope_mat),
    MRS_raw = raw_mrs,
    mrs = 100 * raw_mrs,
    n_cpgs_used = rowSums(observed_mat),
    total_weight = total_weight,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

build_weighted_mrs_audit_table <- function(methylation_percent_mat,
                                           weighted_slope_mat, weights_df,
                                           mrs_df) {
  wide_df <- build_mrs_audit_table(
    methylation_percent_mat, weighted_slope_mat, weights_df, mrs_df
  )
  wide_df$cpg_weight <- c(weights_df$cpg_weight, NA_real_)
  wide_df$weighted_gamma <- c(weights_df$weighted_gamma, NA_real_)
  wide_df$weighted_ptau <- c(weights_df$weighted_ptau, NA_real_)
  wide_df
}

#' Compute an MRS with one equally weighted term per individual CpG or DMR.
#'
#' @param beta_mat Numeric matrix/data frame with samples in rows, CpGs in
#'   columns, and DNAm beta values in 0-1 units.
#' @param weights_df One row per CpG, with cpg, gamma, beta_ptau, DMR,
#'   is_individual, cpg_weight, weighted_gamma, and weighted_ptau columns.
#' @return A list containing wide_df and mrs_df. MRS_raw is the sum of
#'   observed weighted CpG slopes divided by their total CpG weight;
#'   mrs is 100 times MRS_raw.
compute_mrs <- function(beta_mat, weights_df) {
  validated_inputs_ls <- validate_weighted_mrs_inputs(beta_mat, weights_df)
  weights_df <- validated_inputs_ls$weights_df
  methylation_percent_mat <- validated_inputs_ls$beta_mat * 100
  weighted_slope_mat <- compute_weighted_cpg_slopes(
    methylation_percent_mat, weights_df
  )
  mrs_df <- summarize_weighted_mrs(weighted_slope_mat, weights_df)
  wide_df <- build_weighted_mrs_audit_table(
    methylation_percent_mat, weighted_slope_mat, weights_df, mrs_df
  )

  list(wide_df = wide_df, mrs_df = mrs_df)
}

weight_sanity_check <- function(beta_data_mat, weights_df) {
  if (nrow(beta_data_mat) != length(unique(row.names(beta_data_mat)))) {
    stop("There are duplicate CpGs in the beta data")
  }

  missing_count <- sum(!(weights_df$cpg %in% row.names(beta_data_mat)))
  if (missing_count > 0) {
    stop(
      "There are ", missing_count, " out of ", nrow(weights_df),
      " weight cpgs missing in the beta data."
    )
  }

  na_count <- sum(is.na(weights_df[, c("gamma", "beta_ptau")]))
  inf_count <- sum(
    c(
      sum(!is.finite(weights_df$gamma)),
      sum(!is.finite(weights_df$beta_ptau))
    )
  )
  if (na_count > 0 | inf_count > 0) {
    stop("Some of the weights are infinite or missing.")
  }
}

plot_mrs_results <- function(mrs_result_ls) {
  hist(mrs_result_ls$mrs_df$MRS_raw)
  hist(mrs_result_ls$mrs_df$mrs)
}

save_mrs_results <- function(mrs_result_ls, out_dir) {
  write.csv(
    mrs_result_ls$mrs_df,
    file.path(out_dir, "EAP_MRS_scores.csv"),
    row.names = FALSE
  )
  write.csv(
    mrs_result_ls$wide_df,
    file.path(out_dir, "EAP_MRS_scores_components.csv"),
    row.names = FALSE
  )
}

# Score every sample (CpGs in rows of beta_data_mat) with the memory weights
# from mrs_weights.R, plot the score distributions, and save the scores to
# out_dir. Stops with `nonfinite_message` if any score is not finite.
run_mrs_analysis <- function(beta_data_mat, out_dir, nonfinite_message) {
  weights_df <- get_memory_weights()
  weight_sanity_check(beta_data_mat, weights_df)
  selected_beta_mat <- t(beta_data_mat[weights_df$cpg, , drop = FALSE])

  mrs_result_ls <- compute_mrs(selected_beta_mat, weights_df)
  if (any(!is.finite(mrs_result_ls$mrs_df$MRS_raw))) {
    stop(nonfinite_message)
  }

  plot_mrs_results(mrs_result_ls)

  save_mrs_results(mrs_result_ls, out_dir)
}
