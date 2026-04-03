###############################################################################
## check_source_specific.R
## Source-specific robustness checks: do the main findings hold within each
## individual data source (DHS, ESS, ISSP, IPUMS)?
##
## Motivation:
##   The pooled analysis combines four very different data sources. If the
##   findings (declining mean age gap, rising SD over cohorts) are driven by
##   one dominant source (most likely IPUMS, which contributes the bulk of
##   observations), the cross-source replication here would reveal that.
##
## Structure:
##   1. Descriptive overview — sample composition by source
##   2. Raw cohort trends — mean and SD of age gap by cohort × source
##   3. Source-specific location-scale models (M2 per source)
##   4. Comparison figures (Figures Rob1–Rob4)
##   5. Summary table of model-based estimates across sources
##
## Depends on: code/descriptive.R  (loads df, sets theme, loads ggplot2 etc.)
##
## Packages used (in addition to those loaded by descriptive.R):
##   nlme     — lme() and varIdent() for location-scale models
##   knitr    — kable() for formatted tables
##   patchwork — combine multi-panel figures
###############################################################################

# Source the descriptive script if its key output (df) is not already in memory.
if (!exists("df") || !inherits(df, "data.table")) {
  source("code/descriptive.R")
}

# Load additional packages needed for modelling and tables --------------------
library(nlme)         # lme() and varIdent() for location-scale models
library(knitr)        # kable() for formatted tables
library(patchwork)    # combine panels with | and /

# Define tuning constants (matches multivariate_basic.R settings) -------------
MIN_COHORT_OBS   <- 500L   # minimum observations per cohort to include in model
MAX_SUBSAMPLE    <- 40000L  # maximum subsample size per source (for run-time)

# Define source labels and a consistent colour palette across all figures ------
source_labels <- c(dhs = "DHS", ess = "ESS", issp = "ISSP", ipums = "IPUMS")
source_colors <- c(dhs = "#E41A1C", ess = "#377EB8", issp = "#FF7F00", ipums = "#4DAF4A")


# =============================================================================
# 1. DESCRIPTIVE OVERVIEW — SAMPLE COMPOSITION BY SOURCE
# =============================================================================
#
# Print how many observations each source contributes overall and by cohort,
# so we can judge whether any source is too small to fit a model.

cat("\n=============================================================\n")
cat("CHECK 1: Sample size and basic statistics by source\n")
cat("=============================================================\n")

src_overview <- df[, .(
  n_obs      = .N,
  n_countries = uniqueN(country_name),
  n_cohorts  = uniqueN(cohort_group),
  mean_gap   = round(mean(age_diff), 2),
  sd_gap     = round(sd(age_diff),   2),
  pct_wife_older = round(mean(wife_older) * 100, 1)
), by = source]

print(kable(src_overview, format = "simple"))

cat("\nSample size by source × cohort:\n")
src_cohort_n <- df[, .N, by = .(source, cohort_group, cohort_start)][order(source, cohort_start)]
print(kable(src_cohort_n, format = "simple"))


# =============================================================================
# 2. RAW COHORT TRENDS — MEAN AND SD BY COHORT × SOURCE
# =============================================================================
#
# Before fitting any models, inspect the raw descriptive trends within each
# source.  If the pooled finding (falling mean, rising SD) is an artefact of
# one source, these tables will show it immediately.

cat("\n=============================================================\n")
cat("CHECK 2: Mean and SD of age gap by cohort × source\n")
cat("=============================================================\n")

raw_trends <- df[, .(
  n_obs    = .N,
  mean_gap = round(mean(age_diff), 2),
  sd_gap   = round(sd(age_diff),   2),
  pct_wife_older = round(mean(wife_older) * 100, 1)
), by = .(source, cohort_group, cohort_start)][order(source, cohort_start)]

print(kable(raw_trends, format = "simple"))


# =============================================================================
# 3. SOURCE-SPECIFIC LOCATION-SCALE MODELS (M2 PER SOURCE)
# =============================================================================
#
# Fit the key model (M2: mean ~ cohort, random intercept per country,
# variance by cohort) separately for each source.  This allows a direct
# comparison of model-estimated cohort means and SDs across sources.
#
# Only cohorts with >= MIN_COHORT_OBS observations within that source are kept.
# A 10% subsample is drawn within each source to keep run-time manageable.

cat("\n=============================================================\n")
cat("CHECK 3: Source-specific location-scale models (M2)\n")
cat("=============================================================\n")

sources_available <- sort(unique(df$source))  # e.g. c("dhs","ess","ipums","issp")

# Store fitted models, predicted means, and predicted SDs in named lists
src_models    <- list()
src_mean_pred <- list()
src_sd_pred   <- list()

set.seed(123)  # reproducibility

for (src in sources_available) {

  cat("\n--- Source:", toupper(src), "---\n")

  # Subset to this source
  df_src <- df[source == src]

  # Keep only cohorts with >= MIN_COHORT_OBS observations in this source
  cohort_counts_src <- table(df_src$cohort_group)
  keep_cohorts_src  <- names(cohort_counts_src[cohort_counts_src >= MIN_COHORT_OBS])

  if (length(keep_cohorts_src) < 2) {
    cat("  Skipping", toupper(src), "— fewer than 2 cohorts with >= MIN_COHORT_OBS obs.\n")
    next
  }

  df_src_filt <- df_src[cohort_group %in% keep_cohorts_src]
  df_src_filt[, cohort_f  := factor(cohort_group, levels = keep_cohorts_src)]
  df_src_filt[, country_f := factor(country_name)]

  # Drop unused factor levels
  df_src_filt[, cohort_f  := droplevels(cohort_f)]
  df_src_filt[, country_f := droplevels(country_f)]

  # Check we still have enough countries for a random intercept
  n_ctries <- uniqueN(df_src_filt$country_f)
  if (n_ctries < 3) {
    cat("  Skipping", toupper(src), "— fewer than 3 countries after filtering.\n")
    next
  }

  # Draw 10% subsample (up to MAX_SUBSAMPLE rows) — keeps run-time manageable
  n_sub  <- min(nrow(df_src_filt), MAX_SUBSAMPLE)
  df_sub <- as.data.frame(df_src_filt[sample(.N, n_sub)])

  df_sub$cohort_f  <- droplevels(df_sub$cohort_f)
  df_sub$country_f <- droplevels(df_sub$country_f)

  cat("  Subsample size:", nrow(df_sub), "\n")
  cat("  Cohorts:", paste(levels(df_sub$cohort_f), collapse = ", "), "\n")
  cat("  Countries:", n_ctries, "\n")

  # Fit M2: location-scale model with cohort-varying variance
  m2_src <- tryCatch(
    lme(
      fixed   = age_diff ~ cohort_f,
      random  = ~ 1 | country_f,
      weights = varIdent(form = ~ 1 | cohort_f),
      data    = df_sub,
      method  = "REML",
      control = lmeControl(opt = "optim", maxIter = 100, msMaxIter = 100)
    ),
    error = function(e) {
      cat("  Model failed for", toupper(src), ":", conditionMessage(e), "\n")
      NULL
    }
  )

  if (is.null(m2_src)) next

  src_models[[src]] <- m2_src

  # --- Extract predicted cohort means (fixed effects only) -------------------
  model_cohorts_src <- levels(df_sub$cohort_f)
  newdata_src <- data.frame(
    cohort_f  = factor(model_cohorts_src, levels = model_cohorts_src),
    country_f = factor(levels(df_sub$country_f)[1])
  )
  newdata_src$mu_hat <- predict(m2_src, newdata = newdata_src, level = 0)

  # --- Extract predicted cohort SDs ------------------------------------------
  base_sigma_src   <- m2_src$sigma
  var_weights_src  <- coef(m2_src$modelStruct$varStruct, unconstrained = FALSE)
  ref_cohort_src   <- setdiff(model_cohorts_src, names(var_weights_src))

  all_wts_src <- setNames(rep(1.0, length(model_cohorts_src)), model_cohorts_src)
  all_wts_src[names(var_weights_src)] <- as.numeric(var_weights_src)

  sd_pred_src <- data.frame(
    cohort   = model_cohorts_src,
    resid_sd = base_sigma_src * all_wts_src,
    source   = src
  )

  # Convert cohort factor to character before storing so that rbind() across
  # sources does not lose factor-level information (factors from different
  # sources may have different levels, causing silent integer coercion).
  newdata_src$cohort_f <- as.character(newdata_src$cohort_f)
  sd_pred_src$cohort   <- as.character(sd_pred_src$cohort)

  newdata_src$source <- src
  src_mean_pred[[src]] <- newdata_src
  src_sd_pred[[src]]   <- sd_pred_src

  cat("  Model fitted successfully.\n")
} # end model fitting loop

# Combine model results across sources into single data.frames for plotting ---
all_mean_pred <- if (length(src_mean_pred) > 0) do.call(rbind, src_mean_pred) else data.frame()
all_sd_pred   <- if (length(src_sd_pred)   > 0) do.call(rbind, src_sd_pred)   else data.frame()


# =============================================================================
# 4. COMPARISON FIGURES — RAW DESCRIPTIVE (Rob1–Rob2)
# =============================================================================
#
# Rob1 and Rob2 are computed directly from the harmonized data (no models
# needed) so they always run regardless of whether models converged.

# ---- Figure Rob1: Raw mean age gap by cohort × source -----------------------
# Shows whether the declining mean trend is consistent across all 4 sources.

raw_mean_src <- df[, .(mean_gap = mean(age_diff), N = .N),
                   by = .(source, cohort_start, cohort_group)]
raw_mean_src <- raw_mean_src[N >= MIN_COHORT_OBS]  # only cohort×source cells with decent N
raw_mean_src[, source_label := source_labels[source]]

fig_rob1 <- ggplot(raw_mean_src, aes(
  x     = cohort_start,
  y     = mean_gap,
  color = source_label,
  group = source_label
)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  scale_x_continuous(breaks = seq(1920, 1990, 10)) +
  scale_color_manual(values = source_colors, labels = source_labels, name = "Source") +
  labs(
    x        = "Birth cohort",
    y        = "Mean age gap (years)",
    title    = "Figure Rob1: Mean age gap by birth cohort, separately by source",
    subtitle = paste0("Only cohort \u00d7 source cells with N \u2265 ", MIN_COHORT_OBS)
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/rob1_mean_by_source.pdf", fig_rob1, width = 9, height = 5)
ggsave("results/rob1_mean_by_source.png", fig_rob1, width = 9, height = 5, dpi = 300)
cat("Saved: results/rob1_mean_by_source\n")


# ---- Figure Rob2: Raw SD of age gap by cohort × source ----------------------
# Shows whether the increasing SD trend is consistent across all 4 sources.

raw_sd_src <- df[, .(sd_gap = sd(age_diff), N = .N),
                 by = .(source, cohort_start, cohort_group)]
raw_sd_src <- raw_sd_src[N >= MIN_COHORT_OBS]
raw_sd_src[, source_label := source_labels[source]]

fig_rob2 <- ggplot(raw_sd_src, aes(
  x     = cohort_start,
  y     = sd_gap,
  color = source_label,
  group = source_label
)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  scale_x_continuous(breaks = seq(1920, 1990, 10)) +
  scale_color_manual(values = source_colors, labels = source_labels, name = "Source") +
  labs(
    x        = "Birth cohort",
    y        = "SD of age gap (years)",
    title    = "Figure Rob2: SD of age gap by birth cohort, separately by source",
    subtitle = paste0("Only cohort \u00d7 source cells with N \u2265 ", MIN_COHORT_OBS)
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/rob2_sd_by_source.pdf", fig_rob2, width = 9, height = 5)
ggsave("results/rob2_sd_by_source.png", fig_rob2, width = 9, height = 5, dpi = 300)
cat("Saved: results/rob2_sd_by_source\n")


# ---- Figure Rob1+2 combined (two-panel summary figure) ----------------------
# A concise two-panel figure suitable for an online supplement.

fig_rob_combined <- (fig_rob1 / fig_rob2) +
  plot_annotation(
    title    = "Figure Rob1-2: Cohort trends in mean and SD of age gap by data source",
    subtitle = "Top: mean age gap; Bottom: SD of age gap. Raw descriptive estimates.",
    tag_levels = "A"
  )

ggsave("results/rob_combined_mean_sd.pdf", fig_rob_combined, width = 9, height = 9)
ggsave("results/rob_combined_mean_sd.png", fig_rob_combined, width = 9, height = 9, dpi = 300)
cat("Saved: results/rob_combined_mean_sd\n")


# =============================================================================
# 5. COMPARISON FIGURES — MODEL-BASED (Rob3–Rob4) & SUMMARY TABLE (Rob5)
# =============================================================================
#
# The following sections require at least one source-specific model to have
# converged successfully.

if (nrow(all_mean_pred) == 0 || nrow(all_sd_pred) == 0) {
  cat("\nNo source-specific models were successfully fitted. Skipping Rob3–Rob6.\n")
} else {

# Add human-readable source labels
all_mean_pred$source_label <- source_labels[all_mean_pred$source]
all_sd_pred$source_label   <- source_labels[all_sd_pred$source]

# Ensure cohort factor order is chronological: convert to character first, then factor
all_cohort_levels <- sort(unique(c(
  as.character(all_mean_pred$cohort_f),
  as.character(all_sd_pred$cohort)
)))
all_mean_pred$cohort_f <- factor(all_mean_pred$cohort_f, levels = all_cohort_levels)
all_sd_pred$cohort     <- factor(all_sd_pred$cohort,     levels = all_cohort_levels)

# ---- Figure Rob3: Model-estimated mean by cohort × source -------------------
# Same as Fig 8 but overlaid separately for each source.

fig_rob3 <- ggplot(all_mean_pred, aes(
  x     = cohort_f,
  y     = mu_hat,
  color = source_label,
  group = source_label
)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "grey60") +
  scale_color_manual(values = source_colors, labels = source_labels, name = "Source") +
  labs(
    x        = "Birth cohort",
    y        = "Model-predicted mean age gap (years)",
    title    = "Figure Rob3: Model-estimated cohort mean by source",
    subtitle = "Population-average fixed-effect predictions from source-specific M2 models"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/rob3_model_mean_by_source.pdf", fig_rob3, width = 9, height = 5)
ggsave("results/rob3_model_mean_by_source.png", fig_rob3, width = 9, height = 5, dpi = 300)
cat("Saved: results/rob3_model_mean_by_source\n")


# ---- Figure Rob4: Model-estimated cohort SD by source -----------------------
# Same as Fig 7 but overlaid separately for each source.

fig_rob4 <- ggplot(all_sd_pred, aes(
  x     = cohort,
  y     = resid_sd,
  color = source_label,
  group = source_label
)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 2.5) +
  scale_color_manual(values = source_colors, labels = source_labels, name = "Source") +
  labs(
    x        = "Birth cohort",
    y        = "Model-estimated residual SD (years)",
    title    = "Figure Rob4: Model-estimated cohort SD by source",
    subtitle = "Residual SD from source-specific location-scale models (M2 per source)"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

ggsave("results/rob4_model_sd_by_source.pdf", fig_rob4, width = 9, height = 5)
ggsave("results/rob4_model_sd_by_source.png", fig_rob4, width = 9, height = 5, dpi = 300)
cat("Saved: results/rob4_model_sd_by_source\n")


# =============================================================================
# 6. SUMMARY TABLE: MODEL-BASED ESTIMATES BY SOURCE
# =============================================================================
#
# Collects the key model outputs (cohort mean predictions and cohort SD
# estimates) from each source-specific M2 model into a single comparison table.

cat("\n=============================================================\n")
cat("CHECK 5: Summary of model-based estimates by source\n")
cat("=============================================================\n")

# Merge mean and SD predictions (cohort columns are now factors with same levels)
summary_tbl <- merge(
  all_mean_pred[, c("cohort_f", "mu_hat", "source", "source_label")],
  all_sd_pred[,   c("cohort",   "resid_sd", "source")],
  by.x = c("cohort_f", "source"),
  by.y = c("cohort",   "source"),
  all  = TRUE
)

summary_tbl <- summary_tbl[order(summary_tbl$source, summary_tbl$cohort_f), ]

cat("\nModel-estimated cohort mean and SD of age gap by source:\n")
print(kable(
  summary_tbl[, c("source_label", "cohort_f", "mu_hat", "resid_sd")],
  col.names = c("Source", "Cohort", "Est. mean (yrs)", "Est. SD (yrs)"),
  format = "simple", digits = 2, row.names = FALSE
))


# =============================================================================
# 7. CONSISTENCY ASSESSMENT
# =============================================================================
#
# Prints a brief qualitative assessment of whether the main findings
# (declining mean, rising SD) are consistent across all fitted sources.

cat("\n=============================================================\n")
cat("CHECK 6: Consistency of findings across sources\n")
cat("=============================================================\n")

for (src in names(src_models)) {

  mp <- src_mean_pred[[src]]
  sp <- src_sd_pred[[src]]
  # cohort_f is a character column; use sort(unique()) to get ordered levels
  cohort_levels_src <- sort(unique(mp$cohort_f))

  n_coh <- length(cohort_levels_src)
  if (n_coh < 2) next

  first_mu <- mp$mu_hat[mp$cohort_f == cohort_levels_src[1]]
  last_mu  <- mp$mu_hat[mp$cohort_f == cohort_levels_src[n_coh]]
  first_sd <- sp$resid_sd[sp$cohort == cohort_levels_src[1]]
  last_sd  <- sp$resid_sd[sp$cohort == cohort_levels_src[n_coh]]

  mu_dir <- if (last_mu < first_mu) "DECLINING \u2713" else "NOT declining \u2717"
  sd_dir <- if (last_sd > first_sd) "INCREASING \u2713" else "NOT increasing \u2717"

  cat(sprintf(
    "\n  %s (%s): mean %s (%.2f \u2192 %.2f), SD %s (%.2f \u2192 %.2f)\n",
    toupper(src), source_labels[src],
    mu_dir, first_mu, last_mu,
    sd_dir, first_sd, last_sd
  ))
}

cat("\nNote: '\u2713' means the finding is consistent with the pooled result.\n")
cat("      '\u2717' means the source-specific trend diverges.\n")
cat("If all sources show the same direction, the pooled findings are robust\n")
cat("to the choice of data source.\n")

} # end: if model results available
