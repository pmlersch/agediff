###############################################################################
## agediff_advanced_multivariate.R
## Advanced multivariate analysis: country-level model-based figures and
## full model diagnostics.
##
## Depends on: agediff_basic_multivariate.R  (which sources agediff_descriptive.R)
##
## Structure:
##   6. Model-based figures — country level (Figures 10–13b)
##   7. Model diagnostics (Figures D1–D9 and numeric summaries)
##   Summary of all key outputs
##
## All required packages are loaded by the sourced scripts or explicitly below.
###############################################################################

# Source the basic multivariate script if its key output (m2_var_cohort) is not
# already in memory.  When run standalone this sources the full pipeline; when
# called from the Stata do-file via rcall (where the earlier scripts have already
# been sourced in the same persistent R session) the guard prevents re-running.
if (!exists("m2_var_cohort")) {
  source("code/multivariate_basic.R")
}

# Load packages used in this script that are not guaranteed by sourced scripts.
library(dplyr)        # provides %>% pipe and mutate() for data manipulation
library(knitr)        # provides kable() for formatted table output


# =============================================================================
# 6. MODEL-BASED FIGURES — COUNTRY LEVEL (Figures 10–13b)
# =============================================================================

# ---- Figure 10: Country-level residual SD from Model 3 ----------------------
# Model 3 estimated a separate residual SD for each country.
# We extract these to see which countries have the widest/narrowest distributions.

# Base sigma for the reference country
base_sigma_country <- m3_var_country$sigma

# Extract the country-specific variance weights (reference country excluded, = 1)
var_weights_country <- coef(
  m3_var_country$modelStruct$varStruct,
  unconstrained = FALSE
)

# All country levels
all_countries <- levels(df_model$country_f)

# Build a named vector of weights: reference = 1, others from varIdent
all_wt_country <- setNames(rep(1, length(all_countries)), all_countries)
all_wt_country[names(var_weights_country)] <- as.numeric(var_weights_country)

# Compute estimated residual SD per country: base_sigma × weight
country_sd_df <- data.frame(
  country  = all_countries,
  resid_sd = base_sigma_country * all_wt_country
)

# Sort countries by their SD for a clean caterpillar display
country_sd_df <- country_sd_df %>%
  mutate(country = fct_reorder(country, resid_sd))  # reorder factor by SD

cat("\n===== Estimated residual SD per country (Model 3) =====\n")
print(kable(
  country_sd_df[order(-country_sd_df$resid_sd), ],  # print sorted descending
  format = "simple", digits = 3, row.names = FALSE
))

fig10 <- ggplot(country_sd_df, aes(
  x = resid_sd,                                     # estimated SD on x-axis
  y = country                                       # country on y-axis (sorted)
)) +
  geom_point(color = "firebrick", size = 2.5) +     # one dot per country
  labs(
    x     = "Estimated residual SD of age gap (years)",
    y     = NULL,
    title = "Figure 10: Country-level age-gap dispersion",
    subtitle = "From location-scale model with country-specific variance"
  )

ggsave("results/fig10_country_sigma_re.pdf", fig10, width = 8, height = 10)
ggsave("results/fig10_country_sigma_re.emf", fig10, width = 8, height = 10, device = devEMF::emf)
ggsave("results/fig10_country_sigma_re.png", fig10, width = 8, height = 10, dpi = 300)
cat("Saved: results/fig10_country_sigma_re\n")

# ---- Figure 11: Country random intercepts (mean deviations) -----------------
# The random intercepts from Model 3 show how each country's MEAN age gap
# deviates from the overall (fixed-effect) mean.

# Extract the country-level BLUPs (best linear unbiased predictions)
# ranef() returns a data.frame with one row per country
mu_ranef <- ranef(m3_var_country)                   # random effects for the mean

# Convert to a tidy data.frame for plotting
mu_re_df <- data.frame(
  country = rownames(mu_ranef),                     # country names
  re_mu   = mu_ranef[, 1]                           # random intercept value
)

# Sort by random intercept for clean display
mu_re_df <- mu_re_df %>%
  mutate(country = fct_reorder(country, re_mu))

fig11 <- ggplot(mu_re_df, aes(
  x = re_mu,                                        # random intercept on x-axis
  y = country                                       # country on y-axis (sorted)
)) +
  geom_vline(                                       # reference at zero (average)
    xintercept = 0, linetype = "dashed", color = "grey60"
  ) +
  geom_point(color = "navy", size = 2.5) +
  labs(
    x     = "Country deviation from overall mean (years)",
    y     = NULL,
    title = "Figure 11: Country random intercepts — deviation in mean age gap",
    subtitle = "Positive = larger-than-average age gap; negative = smaller"
  )

ggsave("results/fig11_country_mu_re.pdf", fig11, width = 8, height = 10)
ggsave("results/fig11_country_mu_re.emf", fig11, width = 8, height = 10, device = devEMF::emf)
ggsave("results/fig11_country_mu_re.png", fig11, width = 8, height = 10, dpi = 300)
cat("Saved: results/fig11_country_mu_re\n")

# ---- Figure 12: Mean RE vs. variance — do they go together? -----------------
# Key theoretical question: do countries with larger mean age gaps also have
# more or less dispersion? We plot country random intercepts (mean) against
# country-specific residual SDs (variance).

# Merge the two country-level summaries
re_combined <- merge(
  mu_re_df,                                         # random intercepts for mean
  country_sd_df,                                    # estimated residual SDs
  by = "country"
)

fig12 <- ggplot(re_combined, aes(
  x     = re_mu,                                    # mean deviation (x)
  y     = resid_sd,                                 # residual SD (y)
  label = country                                   # text label
)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey80") +
  geom_point(color = "navy", size = 2.5) +     # one point per country
  geom_text(                                        # label each country
    nudge_y       = 0.08,
    size          = 2.5,
    check_overlap = TRUE
  ) +
  geom_smooth(                                      # linear trend line with CI
    method    = "lm",
    se        = TRUE,
    color     = "firebrick",
    linewidth = 0.6
  ) +
  labs(
    x     = "Country deviation in mean age gap (years)",
    y     = "Country-specific residual SD (years)",
    title = "Figure 12: Relationship between mean and variance across countries",
    subtitle = "Does a larger mean gap coincide with more or less dispersion?"
  )

ggsave("results/fig12_mean_vs_variance_re.pdf", fig12, width = 9, height = 7)
ggsave("results/fig12_mean_vs_variance_re.emf", fig12, width = 9, height = 7, device = devEMF::emf)
ggsave("results/fig12_mean_vs_variance_re.png", fig12, width = 9, height = 7, dpi = 300)
cat("Saved: results/fig12_mean_vs_variance_re\n")

# ---- Figure 13: Full distribution evolution for selected countries -----------
# Instead of just showing SD trends (a summary), we show the FULL density
# curves evolving across cohorts within each country. This is the most
# compelling way to see distributional change at the country level.
# Each panel is one country; each colored density is one cohort.
spotlight <- c("Sweden", "Germany", "United States", "Brazil",
               "India", "Egypt", "Nigeria", "Mali")

# Filter to spotlight countries and cohorts with enough data
spotlight_dens <- df[country %in% spotlight &
                       cohort_group %in% names(which(table(df$cohort_group) >= 500))]

# Order countries from low to high mean age gap for intuitive layout
spotlight_dens[, country := factor(country,
  levels = c("Sweden", "Germany", "United States", "Brazil",
             "India", "Egypt", "Nigeria", "Mali"))]

fig13 <- ggplot(spotlight_dens, aes(
  x     = age_diff,                                 # age gap on x-axis
  fill  = cohort_group,                             # one color per cohort
  color = cohort_group                              # matching border color
)) +
  geom_density(alpha = 0.25, linewidth = 0.5) +     # semi-transparent densities
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  facet_wrap(~ country, ncol = 2, scales = "free_y") + # one panel per country
  scale_fill_viridis_d(option = "D", name = "Birth cohort") +
  scale_color_viridis_d(option = "D", guide = "none") + # hide duplicate legend
  labs(
    x     = "Age difference (husband \u2212 wife, years)",
    y     = "Density",
    title = "Figure 13: How age-gap distributions evolve within countries",
    subtitle = "Each colored density is one birth cohort; panels ordered by mean age gap"
  ) +
  theme(legend.position = "bottom")                  # legend at bottom to save space

ggsave("results/fig13_country_density_evolution.pdf", fig13, width = 12, height = 14)
ggsave("results/fig13_country_density_evolution.emf", fig13, width = 12, height = 14, device = devEMF::emf)
ggsave("results/fig13_country_density_evolution.png", fig13, width = 12, height = 14, dpi = 300)
cat("Saved: results/fig13_country_density_evolution\n")

# ---- Figure 13b: SD trends for selected countries (supplement) ---------------
# Keep the SD trend lines as a compact supplement to the density panels.
spotlight_sd <- df[country %in% spotlight &
                     cohort_group %in% names(which(table(df$cohort_group) >= 500)),
                   .(SD = sd(age_diff)),
                   by = .(country, cohort_group)]

fig13b <- ggplot(spotlight_sd, aes(
  x     = cohort_group,                             # cohort on x-axis
  y     = SD,                                       # observed SD on y-axis
  color = country,                                  # one color per country
  group = country                                   # connect within country
)) +
  geom_line(linewidth = 0.7) +
  geom_point(size = 1.8) +
  labs(
    x     = "Birth cohort",
    y     = "SD of age gap (years)",
    color = "Country",
    title = "Figure 13b: Age-gap dispersion trends for selected countries"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/fig13b_country_sd_trends.pdf", fig13b, width = 10, height = 6)
ggsave("results/fig13b_country_sd_trends.emf", fig13b, width = 10, height = 6, device = devEMF::emf)
ggsave("results/fig13b_country_sd_trends.png", fig13b, width = 10, height = 6, dpi = 300)
cat("Saved: results/fig13b_country_sd_trends\n")


# =============================================================================
# 7. MODEL DIAGNOSTICS
# =============================================================================
#
# Good practice requires checking whether model assumptions hold.
# For mixed-effects location-scale models the key assumptions are:
#   (a) Residuals are approximately normally distributed (within groups)
#   (b) Residuals have constant variance WITHIN each variance stratum
#       (i.e., within each cohort for M2, within each country for M3)
#   (c) Random effects are approximately normally distributed
#   (d) No systematic pattern in residuals vs. fitted values
#
# We produce diagnostic figures for M2 (cohort variance) and M3 (country
# variance), since these are the two substantively important models.

# ---- Helper: extract standardized residuals and fitted values ----------------
# resid(model, type = "pearson") gives residuals scaled by the model's
# estimated SD for each observation's variance stratum. If the model is
# correct, these should look like standard normal draws (mean 0, SD ≈ 1).

# --------------------------------------------------------------------------
# Diagnostics for Model 2 (variance by cohort)
# --------------------------------------------------------------------------

# Extract Pearson (standardized) residuals — each residual is divided by
# its stratum-specific SD estimate, so they should all have SD ≈ 1.
m2_resid <- resid(m2_var_cohort, type = "pearson")  # standardized residuals

# Extract fitted values (population-level, i.e., fixed + random effects)
m2_fitted <- fitted(m2_var_cohort)                   # predicted values

# Combine into a data.frame for plotting
diag2 <- data.frame(
  fitted   = m2_fitted,                              # x-axis for most plots
  resid    = m2_resid,                               # standardized residuals
  cohort_f = df_model$cohort_f,                      # cohort group (for coloring)
  country_f = df_model$country_f                     # country (for grouping)
)

# ---- Figure D1: Residuals vs. Fitted (Model 2) ------------------------------
# If the model is well-specified, points should scatter randomly around zero
# with no fan shape, curve, or systematic pattern.
figD1 <- ggplot(diag2, aes(x = fitted, y = resid)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_point(alpha = 0.1, size = 0.5, color = "navy") +  # transparent dots
  geom_smooth(                                       # loess smoother to detect trend
    method = "loess", se = FALSE,
    color = "firebrick", linewidth = 0.7
  ) +
  labs(
    x     = "Fitted values (years)",
    y     = "Standardized residuals",
    title = "Diagnostic D1: Residuals vs. fitted (Model 2 — variance by cohort)"
  )

ggsave("results/figD1_resid_vs_fitted_m2.pdf", figD1, width = 8, height = 5)
ggsave("results/figD1_resid_vs_fitted_m2.emf", figD1, width = 8, height = 5, device = devEMF::emf)
ggsave("results/figD1_resid_vs_fitted_m2.png", figD1, width = 8, height = 5, dpi = 300)
cat("Saved: results/figD1_resid_vs_fitted_m2\n")

# ---- Figure D2: Q-Q plot of residuals (Model 2) -----------------------------
# A quantile-quantile plot compares the distribution of residuals against
# a theoretical normal distribution. Points should fall close to the
# diagonal line if residuals are approximately normal.
figD2 <- ggplot(diag2, aes(sample = resid)) +
  stat_qq(alpha = 0.1, size = 0.5, color = "navy") +       # plot quantiles
  stat_qq_line(color = "firebrick", linewidth = 0.7) +           # reference line
  labs(
    x     = "Theoretical quantiles (standard normal)",
    y     = "Sample quantiles (standardized residuals)",
    title = "Diagnostic D2: Q-Q plot of residuals (Model 2)"
  )

ggsave("results/figD2_qq_m2.pdf", figD2, width = 6, height = 6)
ggsave("results/figD2_qq_m2.emf", figD2, width = 6, height = 6, device = devEMF::emf)
ggsave("results/figD2_qq_m2.png", figD2, width = 6, height = 6, dpi = 300)
cat("Saved: results/figD2_qq_m2\n")

# ---- Figure D3: Residual spread by cohort (Model 2) -------------------------
# After accounting for heteroskedasticity via varIdent, the standardized
# residuals should have roughly equal spread across all cohort groups.
# If varIdent worked well, box widths should be similar.
figD3 <- ggplot(diag2, aes(x = cohort_f, y = resid)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_boxplot(                                      # one box per cohort
    fill    = "navy",
    alpha   = 0.3,
    outlier.alpha = 0.2,                             # fade outlier dots
    outlier.size  = 0.5
  ) +
  labs(
    x     = "Birth cohort",
    y     = "Standardized residuals",
    title = "Diagnostic D3: Residual spread by cohort (Model 2)",
    subtitle = "After varIdent correction, boxes should have similar spread"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/figD3_resid_by_cohort_m2.pdf", figD3, width = 8, height = 5)
ggsave("results/figD3_resid_by_cohort_m2.emf", figD3, width = 8, height = 5, device = devEMF::emf)
ggsave("results/figD3_resid_by_cohort_m2.png", figD3, width = 8, height = 5, dpi = 300)
cat("Saved: results/figD3_resid_by_cohort_m2\n")

# ---- Figure D4: Histogram of residuals (Model 2) ----------------------------
# A simple histogram overlaid with a normal density curve to visually assess
# whether the residual distribution is approximately bell-shaped.
figD4 <- ggplot(diag2, aes(x = resid)) +
  geom_histogram(                                    # histogram of residuals
    aes(y = after_stat(density)),                    # scale to density for overlay
    binwidth = 0.2,                                  # bin width
    fill     = "navy",
    color    = "white",
    alpha    = 0.7
  ) +
  stat_function(                                     # overlay a standard normal curve
    fun      = dnorm,                                # normal density function
    args     = list(mean = 0, sd = 1),               # mean 0, SD 1
    color    = "firebrick",
    linewidth = 0.8
  ) +
  labs(
    x     = "Standardized residuals",
    y     = "Density",
    title = "Diagnostic D4: Residual distribution (Model 2)",
    subtitle = "Red curve = standard normal (what we expect if assumptions hold)"
  )

ggsave("results/figD4_resid_hist_m2.pdf", figD4, width = 8, height = 5)
ggsave("results/figD4_resid_hist_m2.emf", figD4, width = 8, height = 5, device = devEMF::emf)
ggsave("results/figD4_resid_hist_m2.png", figD4, width = 8, height = 5, dpi = 300)
cat("Saved: results/figD4_resid_hist_m2\n")

# --------------------------------------------------------------------------
# Diagnostics for Model 3 (variance by country)
# --------------------------------------------------------------------------

# Extract Pearson residuals and fitted values for M3
m3_resid  <- resid(m3_var_country, type = "pearson")
m3_fitted <- fitted(m3_var_country)

diag3 <- data.frame(
  fitted    = m3_fitted,
  resid     = m3_resid,
  cohort_f  = df_model$cohort_f,
  country_f = df_model$country_f
)

# ---- Figure D5: Residuals vs. Fitted (Model 3) ------------------------------
figD5 <- ggplot(diag3, aes(x = fitted, y = resid)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_point(alpha = 0.1, size = 0.5, color = "navy") +
  geom_smooth(method = "loess", se = FALSE, color = "firebrick", linewidth = 0.7) +
  labs(
    x     = "Fitted values (years)",
    y     = "Standardized residuals",
    title = "Diagnostic D5: Residuals vs. fitted (Model 3 — variance by country)"
  )

ggsave("results/figD5_resid_vs_fitted_m3.pdf", figD5, width = 8, height = 5)
ggsave("results/figD5_resid_vs_fitted_m3.emf", figD5, width = 8, height = 5, device = devEMF::emf)
ggsave("results/figD5_resid_vs_fitted_m3.png", figD5, width = 8, height = 5, dpi = 300)
cat("Saved: results/figD5_resid_vs_fitted_m3\n")

# ---- Figure D6: Q-Q plot of residuals (Model 3) -----------------------------
figD6 <- ggplot(diag3, aes(sample = resid)) +
  stat_qq(alpha = 0.1, size = 0.5, color = "navy") +
  stat_qq_line(color = "firebrick", linewidth = 0.7) +
  labs(
    x     = "Theoretical quantiles",
    y     = "Sample quantiles (standardized residuals)",
    title = "Diagnostic D6: Q-Q plot of residuals (Model 3)"
  )

ggsave("results/figD6_qq_m3.pdf", figD6, width = 6, height = 6)
ggsave("results/figD6_qq_m3.emf", figD6, width = 6, height = 6, device = devEMF::emf)
ggsave("results/figD6_qq_m3.png", figD6, width = 6, height = 6, dpi = 300)
cat("Saved: results/figD6_qq_m3\n")

# ---- Figure D7: Residual spread by country (Model 3) ------------------------
# After varIdent by country, the standardized residual spread should be
# approximately equal across all 40 countries. We plot boxplots sorted by
# median to quickly spot any country where the correction didn't work well.
figD7 <- ggplot(diag3, aes(
  x = fct_reorder(country_f, resid, .fun = sd),     # sort by residual SD
  y = resid
)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  geom_boxplot(
    fill          = "navy",
    alpha         = 0.3,
    outlier.alpha = 0.2,
    outlier.size  = 0.3
  ) +
  coord_flip() +                                     # horizontal layout for readability
  labs(
    x     = NULL,
    y     = "Standardized residuals",
    title = "Diagnostic D7: Residual spread by country (Model 3)",
    subtitle = "After varIdent correction, all countries should have similar spread"
  )

ggsave("results/figD7_resid_by_country_m3.pdf", figD7, width = 8, height = 10)
ggsave("results/figD7_resid_by_country_m3.emf", figD7, width = 8, height = 10, device = devEMF::emf)
ggsave("results/figD7_resid_by_country_m3.png", figD7, width = 8, height = 10, dpi = 300)
cat("Saved: results/figD7_resid_by_country_m3\n")

# --------------------------------------------------------------------------
# Diagnostics for random effects (both models)
# --------------------------------------------------------------------------

# ---- Figure D8: Q-Q plot of country random intercepts (Model 3) -------------
# The random intercepts (BLUPs) should be approximately normally distributed.
# With only 40 countries this is hard to assess precisely, but gross departures
# from normality (heavy tails, skew) would be visible.
re_vals <- ranef(m3_var_country)[, 1]                # 40 country BLUPs

figD8 <- ggplot(data.frame(re = re_vals), aes(sample = re)) +
  stat_qq(color = "navy", size = 2) +           # quantile points
  stat_qq_line(color = "firebrick", linewidth = 0.7) + # reference line
  labs(
    x     = "Theoretical quantiles",
    y     = "Country random intercepts",
    title = "Diagnostic D8: Q-Q plot of country random effects (Model 3)",
    subtitle = "Points near the line suggest approximate normality of random effects"
  )

ggsave("results/figD8_qq_random_effects.pdf", figD8, width = 6, height = 6)
ggsave("results/figD8_qq_random_effects.emf", figD8, width = 6, height = 6, device = devEMF::emf)
ggsave("results/figD8_qq_random_effects.png", figD8, width = 6, height = 6, dpi = 300)
cat("Saved: results/figD8_qq_random_effects\n")

# --------------------------------------------------------------------------
# Numeric diagnostic summaries
# --------------------------------------------------------------------------

# Print summary statistics on the standardized residuals for each model.
# For a well-fitting model: mean ≈ 0, SD ≈ 1, skewness ≈ 0, kurtosis ≈ 3.
cat("\n===== Numeric diagnostics: standardized residuals =====\n")

# Function to compute basic summary stats for a vector of residuals
resid_summary <- function(r, model_name) {
  n    <- length(r)                                  # sample size
  mu   <- mean(r)                                    # should be ≈ 0
  s    <- sd(r)                                      # should be ≈ 1
  skew <- mean(((r - mu) / s)^3)                     # skewness (0 = symmetric)
  kurt <- mean(((r - mu) / s)^4)                     # kurtosis (3 = normal)
  data.frame(
    Model    = model_name,
    N        = n,
    Mean     = round(mu, 4),
    SD       = round(s, 4),
    Skewness = round(skew, 3),
    Kurtosis = round(kurt, 3)
  )
}

# Compute for M1, M2, M3
diag_summary <- rbind(
  resid_summary(resid(m1_homo, type = "pearson"), "M1: Homoskedastic"),
  resid_summary(m2_resid, "M2: Variance by cohort"),
  resid_summary(m3_resid, "M3: Variance by country")
)

print(kable(diag_summary, format = "simple"))

# Print variance of standardized residuals by cohort (for M2)
# After varIdent correction, these should all be close to 1.
cat("\n===== M2: SD of standardized residuals by cohort (target ≈ 1) =====\n")
resid_sd_by_cohort <- tapply(m2_resid, df_model$cohort_f, sd)
print(round(resid_sd_by_cohort, 3))

# Print variance of standardized residuals by country (for M3)
# After varIdent correction, these should all be close to 1.
cat("\n===== M3: SD of standardized residuals by country (target ≈ 1) =====\n")
resid_sd_by_country <- tapply(m3_resid, df_model$country_f, sd)
print(round(sort(resid_sd_by_country), 3))

# --------------------------------------------------------------------------
# Figure D9: Observed vs. predicted distributions (Model 3) ----------------
# --------------------------------------------------------------------------
# For 6 selected countries, overlay the observed age-gap density with the
# model-implied normal density (using the country-specific mean and SD).
# This checks whether the normal assumption is reasonable per country.

# Pick 6 countries spanning the range
diag_countries <- c("Sweden", "United States", "Brazil", "India", "Nigeria", "Mali")

# Get model-implied mean (fitted) and SD (country-specific residual SD) per country
# We use the full df_model, not just the subsample, for a smoother density
diag_obs <- df_model[df_model$country_f %in% diag_countries, ]

# For each country, compute the mean fitted value and the estimated SD
country_params <- data.frame(
  country_f = factor(diag_countries, levels = diag_countries),
  # Mean: overall fixed effect + country random intercept
  mu = sapply(diag_countries, function(c) {
    mean(fitted(m3_var_country)[df_model$country_f == c])
  }),
  # SD: country-specific residual SD from the varIdent model
  sigma = sapply(diag_countries, function(c) {
    # Look up the weight for this country; base_sigma * weight
    w <- if (c %in% names(var_weights_country)) {
      as.numeric(var_weights_country[c])
    } else {
      1  # reference country
    }
    base_sigma_country * w
  })
)

# Build a grid of x-values for the normal density curves
x_grid <- seq(-15, 25, by = 0.1)                    # range of age differences

# Expand into a data.frame with one row per x per country
norm_curves <- do.call(rbind, lapply(1:nrow(country_params), function(i) {
  data.frame(
    country_f = country_params$country_f[i],         # country label
    x         = x_grid,                              # x values
    density   = dnorm(                               # normal density
      x_grid,
      mean = country_params$mu[i],                   # country mean
      sd   = country_params$sigma[i]                 # country SD
    )
  )
}))

figD9 <- ggplot() +
  # Observed density (grey filled area)
  geom_density(
    data = diag_obs,
    aes(x = age_diff),                               # observed age gaps
    fill  = "grey80",
    color = "grey50",
    alpha = 0.5
  ) +
  # Model-implied normal density (red line)
  geom_line(
    data = norm_curves,
    aes(x = x, y = density),
    color     = "firebrick",
    linewidth = 0.7
  ) +
  facet_wrap(~ country_f, scales = "free_y", ncol = 3) + # one panel per country
  labs(
    x     = "Age difference (husband \u2212 wife, years)",
    y     = "Density",
    title = "Diagnostic D9: Observed vs. model-implied distributions",
    subtitle = "Grey = observed; red = normal(mean, SD) from Model 3"
  )

ggsave("results/figD9_observed_vs_predicted.pdf", figD9, width = 12, height = 7)
ggsave("results/figD9_observed_vs_predicted.emf", figD9, width = 12, height = 7, device = devEMF::emf)
ggsave("results/figD9_observed_vs_predicted.png", figD9, width = 12, height = 7, dpi = 300)
cat("Saved: results/figD9_observed_vs_predicted\n")


# =============================================================================
# SUMMARY OF KEY OUTPUTS
# =============================================================================
cat("\n")
cat("=====================================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("=====================================================\n")
cat("\n")
cat("Tables printed to console (Tables 1–5)\n")
cat("\n")
cat("Figures saved to results/:\n")
cat("  fig1_histogram.png               — Overall age-gap distribution\n")
cat("  fig2_caterpillar.png             — Median + IQR by country\n")
cat("  fig3_ridgeline.{pdf,emf,png}               — Full distributions by country\n")
cat("  fig3b_ridgeline_cohort.{pdf,emf,png}       — Distributions evolving across cohorts\n")
cat("  fig3c_ecdf_cohort.{emf,pdf}                — Overlaid ECDFs by cohort\n")
cat("  fig4_cohort_mean_sd.{emf,pdf}              — Mean and SD across cohorts\n")
cat("  fig4b_variance_decomposition.{pdf,emf,png} — Between/within variance + ICC\n")
cat("  fig5_heatmap_sd.{pdf,emf,png}              — SD heatmap (country × cohort)\n")
cat("  fig6_mean_vs_sd.{emf,pdf}                  — Mean vs SD scatter\n")
cat("  fig7_predicted_sd_cohort.{pdf,emf,png}     — Model-estimated SD by cohort\n")
cat("  fig8_predicted_mean_cohort.{pdf,emf,png}   — Model-predicted mean by cohort\n")
cat("  fig9_model_implied_densities.{pdf,emf,png} — KEY: model-implied densities by cohort\n")
cat("  fig10_country_sigma_re.{pdf,emf,png}       — Country residual SDs\n")
cat("  fig11_country_mu_re.{pdf,emf,png}          — Country mean deviations\n")
cat("  fig12_mean_vs_variance_re.{pdf,emf,png}    — Mean vs variance relationship\n")
cat("  fig13_country_density_evolution.{pdf,emf,png} — Full density evolution, 8 countries\n")
cat("  fig13b_country_sd_trends.{pdf,emf,png}     — SD trends for 8 countries\n")
cat("\n")
cat("Diagnostics saved to results/:\n")
cat("  figD1_resid_vs_fitted_m2.{pdf,emf,png} — Residuals vs fitted (M2)\n")
cat("  figD2_qq_m2.{pdf,emf,png}              — Q-Q plot of residuals (M2)\n")
cat("  figD3_resid_by_cohort_m2.{pdf,emf,png} — Residual boxplots by cohort (M2)\n")
cat("  figD4_resid_hist_m2.{pdf,emf,png}      — Residual histogram + normal curve (M2)\n")
cat("  figD5_resid_vs_fitted_m3.{pdf,emf,png} — Residuals vs fitted (M3)\n")
cat("  figD6_qq_m3.{pdf,emf,png}              — Q-Q plot of residuals (M3)\n")
cat("  figD7_resid_by_country_m3.{pdf,emf,png}— Residual boxplots by country (M3)\n")
cat("  figD8_qq_random_effects.{pdf,emf,png}  — Q-Q of country random intercepts\n")
cat("  figD9_observed_vs_predicted.{pdf,emf,png} — Observed vs model-implied densities\n")
cat("\n")
cat("Models estimated:\n")
cat("  M1: Homoskedastic random-intercept (baseline)\n")
cat("  M2: Heteroskedastic by cohort (varIdent on cohort)\n")
cat("  M3: Heteroskedastic by country (varIdent on country)\n")
cat("  M4: Random slope + heteroskedastic by cohort\n")
cat("=====================================================\n")
