# Critical Review of the Analysis Plan: Descriptive and Multivariate Components

**Reviewer perspective:** Formal demographer with expertise in cross-national comparative methods, family demography, and survey methodology.

**Documents reviewed:** `code/descriptive.R`, `code/descriptive.do`, `code/multivariate_basic.R`, `code/multivariate_advanced.R`, `manuscript/agediff_manuscript.md`, `manuscript/results.md`

---

## 1. Conceptual and Definitional Issues

### 1.1 Conflation of birth cohort and marriage cohort

The manuscript motivates the study in terms of "normativity" of age differences over time, indexed by **birth cohort**. But the observed outcome --- age difference in the **current** marriage at survey date --- conflates first marriages, remarriages, and differential survival of unions. A couple observed in a census is a *surviving stock*, not a flow. Birth cohort is therefore confounded with:

- **Selective union dissolution:** Couples with non-normative age gaps may divorce at higher rates, censoring them from the surviving-marriage sample. This attenuates observed variance in older cohorts *mechanistically*, not because norms were stricter.
- **Remarriage patterns:** Remarriages tend to have larger age gaps (especially for men). The share of remarriages in the observed stock varies by cohort and country, injecting composition effects into cohort comparisons.
- **Differential mortality:** In older cohorts, husbands with very large age gaps (much older) are more likely to have died, removing high-gap couples from observation. This left-truncates the distribution for older cohorts.

The manuscript acknowledges selectivity in one sentence in the Discussion ("dissolved marriages are excluded, variance in older cohorts is likely understated") but does not address it analytically. **This is the single most serious threat to the central claim that variance trends reflect changing normativity.** A sensitivity analysis restricting to first marriages (where available) or bounding the bias is essential.

### 1.2 "Normativity" is not variance

The conceptual framework equates low variance with high normativity and high variance with low normativity. This is an oversimplification. A society could have *multiple competing norms* (e.g., arranged marriage with large gaps in one subgroup, free-choice marriage with small gaps in another), producing high variance despite strong norms in each subgroup. The variance decomposition cannot distinguish between:

- Weak norms (everybody picks freely, lots of scatter)
- Strong but heterogeneous norms (distinct subpopulations each with tight clustering)

Bimodal distributions --- which the ridgeline plots might reveal --- would be a smoking gun for the latter. The analysis plan does not systematically test for multimodality, despite the ridgeline plots being well-suited for visual detection.

### 1.3 "Husband minus wife" assumes a binary

The outcome variable is defined as `husband's age - wife's age`. The manuscript title says "different-sex marriage," but the ISSP note in Methods states "sex of partner is not surveyed, so I cannot exclude same-sex partners." This means some observations in the ISSP data may be same-sex couples miscoded as different-sex. The DHS samples only women 15--49 with a male partner, so the problem is source-specific. The analysis plan does not flag this inconsistency or test its sensitivity.

---

## 2. Descriptive Analysis: Methodological Concerns

### 2.1 Pooling heterogeneous data sources without adjustment

The analysis pools DHS, ESS, ISSP, and IPUMS data. These sources differ fundamentally in:

- **Target population:** DHS covers women 15--49 only; IPUMS covers entire households; ESS/ISSP are individual-level surveys of adults 15+.
- **Age measurement:** DHS uses self/proxy-reported current age (prone to heaping); IPUMS uses birth year from census records; ESS/ISSP use self-reported age.
- **Coverage:** DHS covers developing countries; ESS covers Europe; IPUMS has the broadest but uneven coverage.

Pooling these without source-level fixed effects or weights in the descriptive tables means that the "overall" statistics (Table 1) and cross-country comparisons (Tables 2-5) are comparing incompatible sampling frames. A country observed only through DHS (women 15--49) will mechanically have different age and variance profiles than a country observed through a census. The existing `review_tableO1_anomalies.md` documents the DHS age-cap problem but the analysis plan does not implement any of its recommended fixes before proceeding to modelling.

### 2.2 The 100-observation cell threshold is arbitrary and inconsistent

The code uses `n_cell >= 100` as a filter throughout (descriptive.R line 163; descriptive.do passim). However:

- The comment in descriptive.R line 160 says "min 30 obs per cell" but the actual code uses 100. This discrepancy suggests the threshold was changed without updating documentation.
- 100 observations is adequate for estimating a mean but not for estimating a standard deviation or the shape of a density reliably, especially in the tails. For the heatmap of SD (Figure 7), cells with exactly 100 obs will have noisy SD estimates that could dominate the visual.
- The threshold is applied at the country x cohort level but not at the country level overall. Countries with total N < 1,000 (Japan: 652, Kosovo: 695, South Korea: 697) remain in the pooled statistics and potentially in the models.

### 2.3 No survey weights

The descriptive tables use unweighted statistics. If the underlying surveys have complex designs (as DHS and IPUMS generally do), unweighted means and SDs are biased. The manuscript does not justify the decision to ignore weights or discuss its implications. For IPUMS data in particular, the `perwt` variable is essential for population-representative statistics.

### 2.4 Variance decomposition assumes balanced design

The between/within variance decomposition in descriptive.R (section 4) computes between-country variance as `var(country_means)` and within-country variance as a weighted mean of country variances. This is a standard ANOVA decomposition, but it assumes:

- Equal or at least documented weighting of countries. `var(country_means)` weights each country equally regardless of sample size, meaning Mali (N = a few thousand) gets the same weight as the United States (N = millions) in the between-country component.
- No confounding by data source composition. Countries with census data have far larger samples and different age profiles than countries with survey data only.

The ICC computed from this decomposition is therefore not comparable to the ICC from the mixed models (which weight by observation count). The manuscript risks presenting two ICC estimates that differ substantially without explaining why.

### 2.5 Mode-based ordering of ridgeline plots

Figure 3 orders countries by the approximate mode of the density (descriptive.R line 92-98). The mode is estimated via `density()$x[which.max(density()$y)]` using default bandwidth. For countries with heaped or multimodal distributions, this mode estimate is sensitive to bandwidth choice and may not be substantively meaningful. Ordering by median or mean would be more robust and more interpretable.

---

## 3. Multivariate Analysis: Methodological Concerns

### 3.1 The 10% random subsample undermines inference

The models are fit on a 10% random subsample (~40,000 observations) "for computational speed" (multivariate_basic.R line 72-75). This is problematic because:

- **Standard errors are inflated** by a factor of ~sqrt(10) relative to the full sample, reducing power to detect variance differences across cells. For a crossed varIdent model with potentially hundreds of country x cohort cells, 40,000 observations means some cells have very few observations (perhaps < 50), making cell-specific SD estimates unreliable.
- **The subsample is drawn once** with `set.seed(123)`. Results may be sensitive to the particular draw. No bootstrap or repeated-sampling robustness check is performed.
- **Model comparison via LRT is affected:** The likelihood ratio test statistic scales with N. On a 10% subsample, tests may fail to reject differences that would be highly significant on the full sample, or conversely, may yield different relative model rankings.
- Modern computing should handle 400K observations with `nlme::lme()` in reasonable time. If speed is truly an issue, `lme4::lmer()` handles large N efficiently, and the `gamlss` package provides location-scale models with more scalable estimation.

### 3.2 Normality assumption of the location-scale model

The entire modelling framework assumes that, conditional on cohort and country, age differences are normally distributed with group-specific means and variances. But the descriptive analysis itself shows:

- **Right skew:** The histogram (Figure 1) and ridgeline plots show a long right tail. The mean exceeds the median in most countries.
- **Age heaping:** Spikes at 0, 5, 10 years violate continuity assumptions.
- **Potential multimodality:** Some country distributions may be bimodal.

Figure 13 then draws "model-implied normal density curves" as the key results figure. If the underlying distribution is not normal, these curves are misleading --- they will understate the probability mass in the tails and at the heaping points, and overstate it near the mean. The model diagnostics section (Section 7 of multivariate_advanced.R) checks residual normality, but the results are not discussed or used to qualify the model-implied density figures.

A more robust approach would use a distributional regression framework (e.g., GAMLSS) that can accommodate skewness and kurtosis, or at minimum present the model-implied densities alongside the empirical densities for validation.

### 3.3 Model specification issues

**Fixed effects:** All five models use `cohort_f` (categorical cohort dummies) as the only fixed effect. There are no individual-level covariates (education, urbanicity, marriage order) in the main models, nor any country-level covariates (GDP, gender equality index) despite the manuscript's theoretical framework emphasizing these. The manuscript text describes associations with economic development and gender equality in the Results section, but no model in the code includes these as predictors. Either these results come from code not included in the reviewed scripts, or the manuscript describes results that have not been estimated.

**Random effects:** Models M1-M3 and M5 have only a random intercept for country. Model M4 adds a random slope on `cohort_idx` (a numeric index 1, 2, 3, ...). Using a numeric index assumes a linear cohort trend across countries, which may not hold. More importantly, M4 combines a random slope on `cohort_idx` with fixed-effect cohort dummies (`cohort_f`), creating a tension: the fixed effects already capture the non-linear cohort profile, while the random slope assumes country deviations are linear. This is defensible but should be explicitly justified.

**Model M5 (crossed varIdent):** This model estimates a separate residual SD for each country x cohort cell. With, say, 50 countries and 7 cohorts, this is ~350 variance parameters plus 1 base sigma. On a 40,000-observation subsample, many cells will have fewer than ~115 observations, making cell-specific variance estimates noisy. The LRT comparing M5 to M2 or M3 tests whether all ~350 parameters jointly improve fit, but with such a large number of parameters, it will almost always reject even trivially small differences.

### 3.4 REML estimation invalidates likelihood ratio tests

All models are estimated with `method = "REML"` (restricted maximum likelihood). Likelihood ratio tests comparing models with **different fixed effects** are invalid under REML --- only ML-based LRTs are appropriate for comparing fixed-effect structures. However, the models compared here (M1-M5) all share the same fixed effects (`age_diff ~ cohort_f`); they differ only in the variance structure or random effects. For variance-structure comparisons (M1 vs M2, M1 vs M3, M2 vs M5, M3 vs M5), REML-based LRTs are valid. But for the comparison of M1/M2 vs M4 (which differs in the random-effect structure), REML is also appropriate since the fixed effects are the same. This is one point where the analysis is actually correct, but it should be stated explicitly to pre-empt reviewer concerns.

### 3.5 No cross-validation or out-of-sample assessment

The analysis fits five models of increasing complexity and selects based on AIC/BIC and LRT. No cross-validation, split-sample validation, or posterior predictive checks are performed. Given the large number of variance parameters in M5 and the known issues with subsample sensitivity (3.1), in-sample model comparison alone is insufficient.

---

## 4. Inconsistencies Between Descriptive and Multivariate Components

### 4.1 The descriptive and model-based variance trends may tell different stories

The descriptive variance decomposition (descriptive.R section 4) is computed on the full sample with equal country weights. The model-based variance estimates (multivariate_basic.R) are computed on a 10% subsample with observation-level weighting (implicit in ML estimation). These will generally produce different ICC values and different cohort trends. The manuscript should compare the two explicitly and reconcile any discrepancies.

### 4.2 Figure numbering collision

The results guide (results.md line 22) notes a figure numbering collision: the R scripts use `fig7`-`fig13` for model figures, but the Stata script also produces a `fig7` (descriptive dot plot). The guide renumbers the R figures to 8-14b in the text but keeps the file names unchanged. This is confusing and error-prone. It also suggests the pipeline was not designed holistically --- the Stata and R components were developed independently and not fully integrated.

### 4.3 Cohort filtering differs between scripts

- descriptive.R uses `n_cell >= 100` per country x cohort cell.
- multivariate_basic.R drops cohort groups with total N < 500 before modelling (line 66), then further subsamples to 40K.
- descriptive.do uses `n_cell < 100` as a drop criterion.

These different thresholds mean the descriptive tables/figures and the multivariate models are not based on the same sample. Readers comparing descriptive patterns with model estimates may be misled.

---

## 5. Missing Elements

### 5.1 No formal test for distributional shape

The analysis claims to study "normativity" through variance, but never formally tests whether variance is the right summary. Skewness and kurtosis are not reported. A country with high kurtosis (heavy tails, sharp peak) has a very different normativity profile from one with low kurtosis (flat distribution) even at the same variance. Quantile-based measures (IQR, reported in the descriptive tables) partially address this, but the multivariate models ignore it entirely.

### 5.2 No robustness to outliers

The existing review (`review_tableO1_anomalies.md`) documents age differences of 80+ years that are almost certainly data errors. The analysis plan does not trim, winsorize, or otherwise handle these outliers before computing variances --- and variance is the key outcome. A single observation with `age_diff = 84` inflates the cell SD enormously. The descriptive means are somewhat robust, but the entire variance-focused analysis is highly sensitive to extreme values.

### 5.3 No sensitivity analysis for cohabitation vs. marriage

The manuscript states "I focus on marriage ... however, I also consider cohabitation in a robustness check." No cohabitation robustness check appears in the reviewed code.

### 5.4 No sensitivity analysis for first vs. all marriages

The manuscript acknowledges the confound of remarriage but provides no empirical test. IPUMS and some DHS data include marriage order; a restriction to first marriages would be informative.

### 5.5 No account for age heaping

The manuscript Methods section acknowledges heaping at 0, 5, and 10 years. The analysis plan does not adjust for it. Heaping inflates the density at those points and distorts variance estimates. Jittering, smoothing, or Whipple-index-based sensitivity analyses would strengthen the claims.

### 5.6 Macro-level covariates are not in the code

The Results section describes associations between age-gap variance and GDP/gender equality, but no model in the reviewed code includes macro-level covariates. Either this analysis exists in unreviewed code or the results are aspirational.

---

## 6. Summary of Major Recommendations

| Priority | Issue | Recommendation |
|----------|-------|----------------|
| **Critical** | Survivorship bias in stock sample confounds variance trends | Conduct sensitivity analysis restricting to first marriages; formally discuss direction of bias |
| **Critical** | No outlier treatment despite variance-focused analysis | Trim or winsorize extreme age differences (e.g., \|age_diff\| > 40) before all analyses |
| **Critical** | 10% subsample weakens inference for variance components | Fit models on the full sample, or at minimum on 50% with bootstrap replication |
| **High** | Pooling incompatible data sources without adjustment | Include source fixed effects in models; report source-stratified descriptives |
| **High** | Normality assumption contradicted by descriptive evidence | Use GAMLSS or quantile regression; overlay empirical and model-implied densities |
| **High** | Macro-level results described but not estimated in code | Implement models with GDP and GII covariates, or remove claims from manuscript |
| **Medium** | No survey weights | Incorporate design weights, at least for IPUMS and DHS |
| **Medium** | Inconsistent sample filters between descriptive and model code | Harmonize thresholds; document and justify any remaining differences |
| **Medium** | Comment says "min 30" but code uses 100 | Fix documentation-code inconsistency |
| **Low** | Figure numbering collision between Stata and R outputs | Adopt a unified numbering scheme across the full pipeline |
| **Low** | No formal multimodality test | Apply dip test or mixture model to flag bimodal country distributions |
