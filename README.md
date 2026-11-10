# Blood DNA methylation signatures of cognitive reserve against tau-associated memory decline in mild cognitive impairment

David Lukacsovich, Lissette Gomez, Deirdre M. O’Shea, Juan I. Young, Brian W. Kunkle, Wei Zhang, Zhixin Mao, X. Steven Chen, Eden R. Martin, Lily Wang

### Description

This GitHub repository includes scripts used for the analyses in the above manuscript.

The DNA methylation changes associated with cognitive reserve in aging remain 
poorly understood. We studied blood DNA methylation (DNAm) as a modifier of 
the association between serum tau phosphorylated at threonine 181 (pTau181) 
and memory in 325 Health and Retirement Study participants with mild cognitive 
impairment at baseline (year 2016). Our epigenome-wide analyses identified one 
CpG at 5% false discovery rate, 24 suggestive CpGs (P-value < 10-5) and 32 
significant differentially methylated regions, which were enriched in cellular 
responses to chemical stress, cell adhesion, membrane trafficking and lipid 
processing pathways. We developed a methylation-based reserve score (MRS), 
which was associated with slower memory decline over six years in 127 HRS 
participants. In 88 amyloid-positive participants with mild cognitive 
impairment from the Alzheimer’s Disease Neuroimaging Initiative, higher MRS 
corresponded to a weaker association between baseline cerebrospinal fluid 
pTau181 and memory decline (interaction P-value = 5.95 × 10-4). Our findings 
support blood methylation as a candidate marker of cognitive reserve.

Scripts are numbered in the order they are run.

### 1. Prepare the HRS cohort

| File                                                  | Link |
|-------------------------------------------------------|------|
| code/analyze/01a_get_phenotype_data.Rmd               | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/01a_get_phenotype_data.Rmd) |
| code/analyze/01b_compute_hcap_memory_scores.Rmd       | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/01b_compute_hcap_memory_scores.Rmd) |
| code/analyze/01c_merge_hcap_memory_scores.Rmd         | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/01c_merge_hcap_memory_scores.Rmd) |
| code/analyze/01d_predict_smoking.Rmd                  | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/01d_predict_smoking.Rmd) |
| code/analyze/01e_merge_parameters.Rmd                 | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/01e_merge_parameters.Rmd) |
| code/analyze/01f_get_subject_characteristics.Rmd      | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/01f_get_subject_characteristics.Rmd) |
| code/analyze/01g_get_longitudinal_characteristics.Rmd | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/01g_get_longitudinal_characteristics.Rmd) |

### 2. Identify CpGs and DMRs with a DNAm x pTau181 interaction on memory

| File                                                  | Link |
|-------------------------------------------------------|------|
| code/analyze/02a_mem_interaction.Rmd                  | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/02a_mem_interaction.Rmd) |
| code/analyze/02b_bacon_correct.Rmd                    | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/02b_bacon_correct.Rmd) |
| code/analyze/02c_prepare_combp.Rmd                    | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/02c_prepare_combp.Rmd) |
| code/analyze/02d_summarize_combp.Rmd                  | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/02d_summarize_combp.Rmd) |

### 3. Sensitivity analysis that additionally adjusts for smoking status

The smoking-adjusted models are fit alongside the primary analysis in 02a-02d. These scripts compare the two.

| File                                                  | Link |
|-------------------------------------------------------|------|
| code/analyze/03a_prepare_region_combp.Rmd             | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/03a_prepare_region_combp.Rmd) |
| code/analyze/03b_smoking_sensitivity_comparison.Rmd   | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/03b_smoking_sensitivity_comparison.Rmd) |

### 4. Integrative analyses (pathway analysis, eQTm, brain-blood DNAm correlations)

| File                                                  | Link |
|-------------------------------------------------------|------|
| code/analyze/04a_pathway_analysis.Rmd                 | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/04a_pathway_analysis.Rmd) |
| code/analyze/04b_eQTM_association.Rmd                 | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/04b_eQTM_association.Rmd) |
| code/analyze/04c_brain_blood_correlation.Rmd          | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/04c_brain_blood_correlation.Rmd) |

### 5. Associations of significant CpGs and DMRs with memory and pTau181

| File                                                  | Link |
|-------------------------------------------------------|------|
| code/analyze/05a_top_interaction_cpg_mci.Rmd          | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/05a_top_interaction_cpg_mci.Rmd) |
| code/analyze/05b_top_interaction_dmr_mci.Rmd          | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/05b_top_interaction_dmr_mci.Rmd) |

### 6. MRS and longitudinal memory in HRS

| File                                                  | Link |
|-------------------------------------------------------|------|
| code/analyze/06a_calculate_mrs.Rmd                    | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/06a_calculate_mrs.Rmd) |
| code/analyze/06b_mrs_time.Rmd                         | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/06b_mrs_time.Rmd) |

### 7. External validation in ADNI

| File                                                  | Link |
|-------------------------------------------------------|------|
| code/analyze/07a_gather_ADNI_data.Rmd                 | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/07a_gather_ADNI_data.Rmd) |
| code/analyze/07b_calculate_mrs_ADNI.Rmd               | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/07b_calculate_mrs_ADNI.Rmd) |
| code/analyze/07c_compare_ADNI_HRS.Rmd                 | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/07c_compare_ADNI_HRS.Rmd) |
| code/analyze/07d_prep_and_split_MRS.Rmd               | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/07d_prep_and_split_MRS.Rmd) |
| code/analyze/07e_fit_models.Rmd                       | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/07e_fit_models.Rmd) |
| code/analyze/07f_plots_and_comparison.Rmd             | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/07f_plots_and_comparison.Rmd) |
| code/analyze/07g_get_ADNI_characteristics.Rmd         | [Link to the script](https://github.com/TransBioInfoLab/ad_cr_hrs/blob/main/code/analyze/07g_get_ADNI_characteristics.Rmd) |
