# Render each notebook in its own fresh R process, like RStudio's Knit
# button, so no objects, packages or options carry over between notebooks.
render_clean <- function(file) {
  xfun::Rscript_call(rmarkdown::render, list(file, "html_document"))
}

# 01: Prepare the HRS cohort
render_clean("01a_get_phenotype_data.Rmd")
render_clean("01b_compute_hcap_memory_scores.Rmd")
render_clean("01c_merge_hcap_memory_scores.Rmd")
render_clean("01d_predict_smoking.Rmd")
render_clean("01e_merge_parameters.Rmd")
render_clean("01f_get_subject_characteristics.Rmd")
render_clean("01g_get_longitudinal_characteristics.Rmd")

# 02: CpGs and DMRs with a DNAm x pTau181 interaction on memory
render_clean("02a_mem_interaction.Rmd")
render_clean("02b_bacon_correct.Rmd")
render_clean("02c_prepare_combp.Rmd")
render_clean("02d_summarize_combp.Rmd")

# 03: Sensitivity analysis that additionally adjusts for smoking status
render_clean("03a_prepare_region_combp.Rmd")
render_clean("03b_smoking_sensitivity_comparison.Rmd")

# 04: Integrative analyses (pathway analysis, eQTm, brain-blood correlations)
render_clean("04a_pathway_analysis.Rmd")
render_clean("04b_eQTM_association.Rmd")
render_clean("04c_brain_blood_correlation.Rmd")

# 05: Associations of significant CpGs and DMRs with memory and pTau181
render_clean("05a_top_interaction_cpg_mci.Rmd")
render_clean("05b_top_interaction_dmr_mci.Rmd")

# 06: MRS and longitudinal memory in HRS
render_clean("06a_calculate_mrs.Rmd")
render_clean("06b_mrs_time.Rmd")

# 07: External validation in ADNI
render_clean("07a_gather_ADNI_data.Rmd")
render_clean("07b_calculate_mrs_ADNI.Rmd")
render_clean("07c_compare_ADNI_HRS.Rmd")
render_clean("07d_prep_and_split_MRS.Rmd")
render_clean("07e_fit_models.Rmd")
render_clean("07f_plots_and_comparison.Rmd")
render_clean("07g_get_ADNI_characteristics.Rmd")
