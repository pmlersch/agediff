###############################################################################
## agediff_basic_multivariate.R
## Basic multivariate analysis of within-couple age gaps: location-scale
## mixed models (M1–M4) and cohort-level model-based figures.
##
## Depends on: agediff_descriptive.R  (must be sourced first)
##
## Structure:
##   5. Location-scale mixed models (M1–M5, model comparison)
##   6. Model-based figures — cohort level (Figures 11–13)
##
## Packages used (in addition to those loaded by agediff_descriptive.R):
##   nlme     — lme() and varIdent() for location-scale models
##   lme4     — lmer() for standard mixed-effects models (comparison)
##   knitr    — kable() for model comparison tables
##   patchwork — plot_layout() and plot_annotation() for multi-panel figures
###############################################################################

# Source the descriptive script if its key output (df) is not already in memory.
# When run standalone this sources the full pipeline; when called from the Stata
# do-file via rcall (where agediff_descriptive.R has already been sourced in the
# same persistent R session) the guard prevents re-running it.
if (!exists("df") || !inherits(df, "data.table")) {
  source("code/descriptive.R")
}

# Load additional packages needed for multivariate modelling -------------------
library(nlme)         # provides lme() and varIdent() for location-scale models
library(lme4)         # provides lmer() for standard mixed-effects models
library(knitr)        # provides kable() for model comparison tables
library(patchwork)    # provides plot_layout() and plot_annotation() for multi-panel figures


# =============================================================================
# 5. LOCATION-SCALE MIXED MODELS
# =============================================================================
#
# We use nlme::lme() with the varIdent() variance function.
# Standard mixed models assume equal residual variance across all groups
# (homoskedasticity). The varIdent() function relaxes this assumption by
# estimating a SEPARATE residual standard deviation for each level of a
# grouping variable (e.g., each country or each cohort).
#
# This is a "location-scale" approach because:
#   - LOCATION (mean): modeled via fixed + random effects in lme()
#   - SCALE (variance): modeled via the weights = varIdent() argument
#
# This lets us formally test: does the VARIANCE of the age gap differ
# across cohorts? Across countries? Both?
#
# We estimate five models of increasing complexity:
#   M1: Homoskedastic baseline (equal variance everywhere)
#   M2: Variance differs by cohort (varIdent on cohort_group)
#   M3: Variance differs by country (varIdent on country)
#   M4: Random slope on cohort — country-specific cohort trends in the mean
#   M5: Crossed varIdent — separate variance per country × cohort cell
# We compare them via likelihood ratio tests and AIC.

# Convert grouping variables to factors (lme/nlme requires this)
df[, cohort_f  := factor(cohort_group)]            # birth cohort as factor
df[, country_f := factor(country)]                 # country as factor

# Drop cohort groups with very few observations (< 500) before modeling.
# These tiny groups (e.g., 1920-1929 has 1 obs) cause convergence issues.
cohort_counts <- table(df$cohort_group)             # count records per cohort
keep_cohorts  <- names(cohort_counts[cohort_counts >= 500])  # keep only large groups
df_for_model  <- df[cohort_group %in% keep_cohorts] # filter

# Re-level the factor to drop empty levels after filtering
df_for_model[, cohort_f := factor(cohort_f, levels = keep_cohorts)]

# For computational speed, draw a 10% random subsample (~40,000 rows).
# nlme on 400k rows would be very slow; 40k gives stable, precise estimates.
set.seed(123)                                       # ensure reproducibility
df_model <- as.data.frame(df_for_model[sample(.N, min(.N, 40000))])  # lme() needs a data.frame

# Drop any unused factor levels that remain after subsetting
df_model$cohort_f  <- droplevels(df_model$cohort_f)
df_model$country_f <- droplevels(df_model$country_f)

cat("\nModel subsample size:", nrow(df_model), "\n")
cat("Cohort levels in model:", paste(levels(df_model$cohort_f), collapse = ", "), "\n")

# --------------------------------------------------------------------------
# Model 1: Homoskedastic baseline
# --------------------------------------------------------------------------
# The mean age gap depends on cohort (fixed effect) and varies by country
# (random intercept), but the residual variance is the SAME everywhere.
cat("\nFitting Model 1: Homoskedastic random-intercept model...\n")
m1_homo <- lme(
  fixed   = age_diff ~ cohort_f,                   # fixed effect: cohort dummies
  random  = ~ 1 | country_f,                       # random intercept per country
  data    = df_model,                              # the 40k subsample
  method  = "REML",                                # restricted maximum likelihood
  control = lmeControl(opt = "optim", maxIter = 100, msMaxIter = 100)
)

# Print a brief summary of the baseline model
cat("\n===== Model 1: Homoskedastic random-intercept =====\n")
print(summary(m1_homo))

# --------------------------------------------------------------------------
# Model 2: Variance differs by COHORT
# --------------------------------------------------------------------------
# Same fixed and random effects as Model 1, but now we ALSO allow the
# residual SD to be different in each birth-cohort group.
# varIdent(form = ~1 | cohort_f) estimates one variance ratio per cohort,
# relative to the first cohort (reference category, ratio fixed at 1).
cat("\nFitting Model 2: Heteroskedastic by cohort...\n")
m2_var_cohort <- lme(
  fixed   = age_diff ~ cohort_f,                   # same fixed effects
  random  = ~ 1 | country_f,                       # same random intercept
  weights = varIdent(form = ~ 1 | cohort_f),       # allow different SD per cohort
  data    = df_model,
  method  = "REML",
  control = lmeControl(opt = "optim", maxIter = 100, msMaxIter = 100)
)

cat("\n===== Model 2: Variance differs by cohort =====\n")
print(summary(m2_var_cohort))

# --------------------------------------------------------------------------
# Model 3: Variance differs by COUNTRY
# --------------------------------------------------------------------------
# Now variance is allowed to differ across countries rather than cohorts.
# This tests whether some countries have much wider age-gap distributions.
cat("\nFitting Model 3: Heteroskedastic by country...\n")
m3_var_country <- lme(
  fixed   = age_diff ~ cohort_f,                   # same fixed effects
  random  = ~ 1 | country_f,                       # same random intercept
  weights = varIdent(form = ~ 1 | country_f),      # allow different SD per country
  data    = df_model,
  method  = "REML",
  control = lmeControl(opt = "optim", maxIter = 100, msMaxIter = 100)
)

cat("\n===== Model 3: Variance differs by country =====\n")
print(summary(m3_var_country))

# --------------------------------------------------------------------------
# Model 4: Random slope — does the cohort trend vary across countries?
# --------------------------------------------------------------------------
# We add a random slope on a numeric cohort index so that each country can
# have its own cohort TREND in the MEAN, testing whether convergence toward
# smaller age gaps is uniform.  Note: this captures country heterogeneity in
# the mean trajectory, not in the variance — the latter is addressed by M5.
cat("\nFitting Model 4: Random slope on cohort index...\n")

# Create a numeric cohort index (1, 2, 3, …) so we can fit a random slope
df_model$cohort_idx <- as.numeric(df_model$cohort_f)

m4_rs <- lme(
  fixed   = age_diff ~ cohort_f,                   # same fixed effects (cohort dummies)
  random  = ~ 1 + cohort_idx | country_f,          # random intercept AND slope per country
  weights = varIdent(form = ~ 1 | cohort_f),       # heteroskedastic by cohort (from M2)
  data    = df_model,
  method  = "REML",
  control = lmeControl(opt = "optim", maxIter = 100, msMaxIter = 100)
)

cat("\n===== Model 4: Random slope + variance by cohort =====\n")
print(summary(m4_rs))

# --------------------------------------------------------------------------
# Model 5: Crossed varIdent — variance by country × cohort jointly
# --------------------------------------------------------------------------
# Models M2 and M3 test variance by cohort and by country separately, but the
# paper's central claim is that NORMATIVITY shifts DIFFERENTLY across countries
# over time — i.e., there is a country × cohort interaction in the VARIANCE.
# A crossed varIdent estimates a separate residual SD for each country × cohort
# cell, directly quantifying this interaction.
#
# M2 is nested in M5 (all cells in the same cohort constrained to equal SD).
# M3 is nested in M5 (all cells in the same country constrained to equal SD).
# Comparing M5 to M2 and M3 via LRT therefore tests whether the cohort variance
# trajectory genuinely differs across countries.
cat("\nFitting Model 5: Crossed varIdent by country \u00d7 cohort...\n")

# Create the crossed grouping variable: one level per country × cohort cell.
# The "__" separator avoids ambiguity with country names that contain spaces.
df_model$country_cohort_f <- factor(
  paste(df_model$country_f, df_model$cohort_f, sep = "__")
)

m5_var_crossed <- lme(
  fixed   = age_diff ~ cohort_f,                    # same fixed effects as M1–M4
  random  = ~ 1 | country_f,                        # random intercept per country
  weights = varIdent(form = ~ 1 | country_cohort_f), # separate SD per cell
  data    = df_model,
  method  = "REML",
  control = lmeControl(opt = "optim", maxIter = 200, msMaxIter = 200)
)

cat("\n===== Model 5: Crossed varIdent (country \u00d7 cohort) =====\n")
print(summary(m5_var_crossed))

# --------------------------------------------------------------------------
# Model comparison via likelihood ratio tests and AIC
# --------------------------------------------------------------------------
# The anova() function for lme objects performs a likelihood ratio test (LRT).
# A significant p-value means the more complex model fits significantly better.

cat("\n===== Likelihood ratio test: M1 (homo) vs M2 (cohort variance) =====\n")
print(anova(m1_homo, m2_var_cohort))               # does variance differ by cohort?

cat("\n===== Likelihood ratio test: M1 (homo) vs M3 (country variance) =====\n")
print(anova(m1_homo, m3_var_country))              # does variance differ by country?

cat("\n===== Likelihood ratio test: M2 (cohort) vs M5 (crossed) =====\n")
print(anova(m2_var_cohort, m5_var_crossed))        # does variance vary by COUNTRY within cohort?

cat("\n===== Likelihood ratio test: M3 (country) vs M5 (crossed) =====\n")
print(anova(m3_var_country, m5_var_crossed))       # does variance vary by COHORT within country?

# Build a compact AIC comparison table
aic_table <- data.frame(
  Model = c(
    "M1: Homoskedastic (equal variance)",
    "M2: Variance by cohort",
    "M3: Variance by country",
    "M4: Random slope + variance by cohort",
    "M5: Crossed variance (country \u00d7 cohort)"
  ),
  AIC = round(c(
    AIC(m1_homo),
    AIC(m2_var_cohort),
    AIC(m3_var_country),
    AIC(m4_rs),
    AIC(m5_var_crossed)
  ), 1),
  BIC = round(c(
    BIC(m1_homo),
    BIC(m2_var_cohort),
    BIC(m3_var_country),
    BIC(m4_rs),
    BIC(m5_var_crossed)
  ), 1)
)

cat("\n===== Model comparison (AIC / BIC — lower is better) =====\n")
print(kable(aic_table, format = "simple"))


# =============================================================================
# 6. MODEL-BASED FIGURES — COHORT LEVEL (Figures 7–9)
# =============================================================================

# ---- Figure 11: Residual SD by cohort from Model 2 --------------------------
# In Model 2, the varIdent structure estimates one SD multiplier per cohort
# relative to the reference cohort (whose multiplier is fixed at 1).
# The base residual SD (sigma) is the reference cohort's SD.
# For other cohorts: SD = base_sigma / weight   (where weight = 1/multiplier).

# Extract the base residual standard deviation from the model summary
base_sigma_cohort <- m2_var_cohort$sigma            # base SD (reference cohort)

# Extract the variance weights estimated by varIdent.
# varIdent stores multipliers for all NON-reference groups (the reference = 1).
# The names of the vector tell us which cohorts are non-reference.
var_weights_cohort <- coef(                         # extract coefficients from
  m2_var_cohort$modelStruct$varStruct,              # the variance structure object
  unconstrained = FALSE                             # return on the original scale
)

# Identify all cohort levels present in the model data
all_cohorts <- levels(df_model$cohort_f)            # all cohort levels

# The reference cohort is the one NOT listed in the weights vector
ref_cohort <- setdiff(all_cohorts, names(var_weights_cohort))

# Build a named vector of SD multipliers: reference = 1, others from varIdent
all_weights <- setNames(rep(1, length(all_cohorts)), all_cohorts)
all_weights[names(var_weights_cohort)] <- as.numeric(var_weights_cohort)

# Compute estimated residual SD per cohort: base_sigma × weight
cohort_sd_df <- data.frame(
  cohort   = all_cohorts,                           # cohort labels
  resid_sd = base_sigma_cohort * all_weights        # estimated SD per cohort
)

# Ensure cohorts are in chronological order for the plot
cohort_sd_df$cohort <- factor(cohort_sd_df$cohort, levels = all_cohorts)

# Print the table so we can inspect the values
cat("\n===== Estimated residual SD per cohort (Model 2) =====\n")
print(kable(cohort_sd_df, format = "simple", digits = 3))

fig11 <- ggplot(cohort_sd_df, aes(
  x     = cohort,                                   # cohort on x-axis
  y     = resid_sd,                                 # estimated SD on y-axis
  group = 1                                         # single connected line
)) +
  geom_line(color = "firebrick", linewidth = 0.8) + # trend line
  geom_point(color = "firebrick", size = 2.5) +     # point per cohort
  labs(
    x     = "Birth cohort",
    y     = "Estimated residual SD (years)",
    title = "Figure 11: Model-estimated age-gap dispersion by cohort",
    subtitle = "From location-scale model (nlme with varIdent)"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/fig11_predicted_sd_cohort.pdf", fig11, width = 8, height = 5)
ggsave("results/fig11_predicted_sd_cohort.emf", fig11, width = 8, height = 5, device = devEMF::emf)
ggsave("results/fig11_predicted_sd_cohort.png", fig11, width = 8, height = 5, dpi = 300)
cat("Saved: results/fig11_predicted_sd_cohort\n")

# ---- Figure 12: Predicted mean age gap by cohort from Model 2 ---------------
# The fixed-effect coefficients give the predicted mean at each cohort level.
# The intercept is the mean for the reference cohort; the other coefficients
# are DIFFERENCES from that reference.

# Extract fixed-effect coefficients
fix_coefs <- fixef(m2_var_cohort)                   # named vector of fixed effects

# Build a new-data frame with one row per cohort (for prediction).
# Use only cohort levels present in the model (not tiny dropped groups).
model_cohorts <- levels(df_model$cohort_f)           # cohorts actually in the model
newdata_cohort <- data.frame(
  cohort_f  = factor(model_cohorts, levels = model_cohorts), # cohort factor
  country_f = factor(levels(df_model$country_f)[1])          # pick any country (RE = 0)
)

# Predict the mean age gap at the population level (RE set to 0)
# level = 0 means we use only fixed effects, ignoring the country random intercept.
newdata_cohort$mu_hat <- predict(
  m2_var_cohort,                                    # the fitted model
  newdata   = newdata_cohort,                       # prediction data
  level     = 0                                     # population-average (fixed only)
)

fig12 <- ggplot(newdata_cohort, aes(
  x     = cohort_f,                                 # cohort on x-axis
  y     = mu_hat,                                   # predicted mean on y-axis
  group = 1
)) +
  geom_line(color = "navy", linewidth = 0.8) +
  geom_point(color = "navy", size = 2.5) +
  geom_hline(                                       # reference line at zero
    yintercept = 0, linetype = "dashed", color = "grey60"
  ) +
  labs(
    x     = "Birth cohort",
    y     = "Predicted mean age gap (years)",
    title = "Figure 12: Model-predicted mean age gap by cohort",
    subtitle = "Population-average prediction (country random effects = 0)"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/fig12_predicted_mean_cohort.pdf", fig12, width = 8, height = 5)
ggsave("results/fig12_predicted_mean_cohort.emf", fig12, width = 8, height = 5, device = devEMF::emf)
ggsave("results/fig12_predicted_mean_cohort.png", fig12, width = 8, height = 5, dpi = 300)
cat("Saved: results/fig12_predicted_mean_cohort\n")

# ---- Figure 13: Model-implied density curves by cohort ----------------------
# This is the KEY RESULTS FIGURE. Instead of an abstract mean±SD ribbon,
# we draw the actual normal density curves implied by the location-scale model
# for each cohort. This makes the distributional shift vivid: the reader can
# see the peak move leftward (mean shrinking) AND the curve widen (SD growing)
# simultaneously.

# Merge the mean and SD predictions into one data.frame
combined_pred <- merge(
  newdata_cohort[, c("cohort_f", "mu_hat")],        # predicted means
  cohort_sd_df,                                      # predicted SDs
  by.x = "cohort_f", by.y = "cohort"                # join on cohort
)

# Ensure chronological order
combined_pred$cohort_f <- factor(combined_pred$cohort_f, levels = model_cohorts)

# Build a fine grid of x-values spanning the plausible range of age differences
x_grid <- seq(-15, 25, by = 0.05)                   # fine grid for smooth curves

# For each cohort, compute the model-implied normal density: N(mu_hat, resid_sd)
model_densities <- do.call(rbind, lapply(1:nrow(combined_pred), function(i) {
  data.frame(
    cohort_f = combined_pred$cohort_f[i],            # cohort label
    x        = x_grid,                               # age difference values
    density  = dnorm(                                # normal density
      x_grid,
      mean = combined_pred$mu_hat[i],                # model-predicted mean
      sd   = combined_pred$resid_sd[i]               # model-predicted SD
    )
  )
}))

# Ensure cohort factor ordering is preserved
model_densities$cohort_f <- factor(model_densities$cohort_f, levels = model_cohorts)

# Panel A: stacked model-implied densities — the core visual
fig13a <- ggplot(model_densities, aes(
  x     = x,                                        # age gap on x-axis
  y     = density,                                  # density on y-axis
  fill  = cohort_f,                                 # color per cohort
  color = cohort_f                                  # matching border
)) +
  geom_area(alpha = 0.15, position = "identity") +  # overlaid (not stacked) areas
  geom_line(linewidth = 0.6) +                       # density outlines
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  scale_fill_viridis_d(option = "D", name = "Birth cohort") +
  scale_color_viridis_d(option = "D", guide = "none") +
  coord_cartesian(xlim = c(-10, 20)) +               # zoom to informative range
  labs(
    x     = "Age difference (husband \u2212 wife, years)",
    y     = "Density",
    title = "A: Model-implied age-gap distributions by cohort"
  ) +
  theme(legend.position = "bottom")

# Panel B: the same data shown as a ridgeline — another way to see the shift
# Trick: use the pre-computed densities to draw ridgelines manually.
# This avoids re-estimating and gives the model-implied shape.
fig13b <- ggplot(combined_pred, aes(
  x     = cohort_f,
  group = 1
)) +
  geom_ribbon(
    aes(ymin = mu_hat - resid_sd, ymax = mu_hat + resid_sd),
    fill = "navy", alpha = 0.2
  ) +
  geom_ribbon(
    aes(ymin = mu_hat - 2 * resid_sd, ymax = mu_hat + 2 * resid_sd),
    fill = "navy", alpha = 0.1
  ) +
  geom_line(aes(y = mu_hat), color = "navy", linewidth = 0.8) +
  geom_point(aes(y = mu_hat), color = "navy", size = 2.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  labs(
    x     = "Birth cohort",
    y     = "Age gap (years)",
    title = "B: Predicted mean \u00b1 1 and 2 SD"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

fig13 <- fig13a + fig13b +
  plot_layout(widths = c(2, 1)) +                    # density panel wider
  plot_annotation(
    title    = "Figure 13: Location-scale model \u2014 how the full distribution shifts across cohorts",
    subtitle = "Left: model-implied normal densities; Right: predicted mean with \u00b11 and \u00b12 SD bands"
  )

ggsave("results/fig13_model_implied_densities.pdf", fig13, width = 15, height = 6)
ggsave("results/fig13_model_implied_densities.emf", fig13, width = 15, height = 6, device = devEMF::emf)
ggsave("results/fig13_model_implied_densities.png", fig13, width = 15, height = 6, dpi = 300)
cat("Saved: results/fig13_model_implied_densities\n")
