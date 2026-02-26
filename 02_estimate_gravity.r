# =============================================================================
# EU-ACP GRAVITY MODEL — ESTIMATION
# =============================================================================
# Research question:
#   Does intra-regional trade integration (IT Share) among ACP blocs act as
#   a stumbling block or building block for bilateral trade with EU members?
#   Secondary: does an in-force EPA moderate this relationship?
#
# Panel: 78 ACP countries (7 RECs) x EU-27 x 1995-2021
# Estimator: PPML (fepois) with exporter-year + ACP-country + year FEs.
# Standard errors clustered at the country-pair level throughout.
#
# Note on FE structure: importer_year would absorb it_share and epa (both
# vary only at the ACP country x year level), so these are split into
# acp_iso3 + year fixed effects, which preserves identification of the
# key variables while controlling for common time shocks.
#
# Run after 01_build_panel.R has saved eu_acp_panel_v3.rds.
# =============================================================================

library(tidyverse)
library(fixest)
library(RColorBrewer)

set.seed(42)

OUT_FIG <- "C:/Users/ndams/Documents/Erol/output/figures/"
OUT_TAB <- "C:/Users/ndams/Documents/Erol/output/tables/"
dir.create(OUT_FIG, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT_TAB, recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# 1. LOAD AND VALIDATE PANEL
# =============================================================================
panel <- readRDS("C:/Users/ndams/Documents/Erol/Data/eu_acp_panel_v3.rds")

if (n_distinct(panel$acp_iso3) != 78)
  stop(sprintf("Expected 78 ACP countries, got %d.", n_distinct(panel$acp_iso3)))

required_cols <- c("pair_id","ACP_to_EU","EU_to_ACP","it_share","it_intensity",
                   "ln_dist","lang","colonial","epa","gdp_acp","gdp_eu",
                   "total_bilateral","exporter_year","acp_iso3","year")
missing_cols <- setdiff(required_cols, names(panel))
if (length(missing_cols) > 0)
  stop("Panel missing columns: ", paste(missing_cols, collapse = ", "))

if (anyDuplicated(panel[, c("acp_iso3","eu_iso3","year")]))
  stop("Duplicate acp_iso3 x eu_iso3 x year rows — check panel build.")

REC_LEVELS  <- c("ECOWAS","Central Africa","SADC","EAC","COMESA","CARIFORUM","PIF")
REC_COLOURS <- setNames(brewer.pal(7, "Set2"), REC_LEVELS)

panel <- panel |>
  mutate(
    rec        = factor(rec, levels = REC_LEVELS),
    acp_region = case_when(
      rec %in% c("ECOWAS","Central Africa","SADC","EAC","COMESA") ~ "Africa",
      rec == "CARIFORUM" ~ "Caribbean",
      rec == "PIF"       ~ "Pacific"
    ),
    ln_trade_plus = log1p(total_bilateral)
  )

DICT <- c(
  ln_dist            = "ln(Distance)",
  contiguity         = "Contiguity",
  lang               = "Common Language",
  colonial           = "Colonial Tie",
  epa                = "EPA (=1 in force)",
  it_share           = "Intra-REC Trade Share",
  it_intensity       = "Intra-REC Trade Intensity",
  "epa:it_share"     = "EPA x IT Share",
  "epa:it_intensity" = "EPA x IT Intensity"
)

# =============================================================================
# 2. SUMMARY STATISTICS
# =============================================================================
sumstats <- panel |>
  filter(!is.na(rec)) |>
  distinct(acp_iso3, year, rec, it_share, it_intensity, gdp_acp, pop_acp, epa) |>
  group_by(rec) |>
  summarise(
    n_countries      = n_distinct(acp_iso3),
    n_cy             = n(),
    it_share_mean    = round(mean(it_share,     na.rm = TRUE), 3),
    it_share_sd      = round(sd(it_share,       na.rm = TRUE), 3),
    it_share_missing = round(100 * mean(is.na(it_share)), 1),
    it_int_mean      = round(mean(it_intensity, na.rm = TRUE), 3),
    gdp_acp_mean_mn  = round(mean(gdp_acp / 1e6, na.rm = TRUE), 1),
    pct_epa          = round(100 * mean(epa == 1L, na.rm = TRUE), 1),
    .groups = "drop"
  )

trade_stats <- panel |>
  filter(!is.na(rec)) |>
  group_by(rec) |>
  summarise(
    mean_bilateral_usd = round(mean(total_bilateral, na.rm = TRUE), 0),
    pct_zero_trade     = round(100 * mean(total_bilateral == 0), 1),
    .groups = "drop"
  )

sumstats_full <- left_join(sumstats, trade_stats, by = "rec")
print(sumstats_full)
write_csv(sumstats_full, paste0(OUT_TAB, "summary_statistics.csv"))

# =============================================================================
# 3. DATA DIAGNOSTICS
# =============================================================================

# -- Missing gravity covariates -----------------------------------------------
missing_covs <- panel |>
  distinct(acp_iso3, eu_iso3, year, ln_dist, gdp_acp, gdp_eu) |>
  filter(is.na(ln_dist) | is.na(gdp_acp) | is.na(gdp_eu)) |>
  count(acp_iso3, year, name = "n_eu_missing") |>
  arrange(desc(n_eu_missing))

if (nrow(missing_covs) > 0) {
  message("Country-years with missing covariates (expected: SOM, ERI, TLS pre-2002):")
  missing_covs |>
    group_by(acp_iso3) |>
    summarise(total_years_missing = sum(n_eu_missing > 0), .groups = "drop") |>
    arrange(desc(total_years_missing)) |>
    print(n = 50)
  write_csv(missing_covs, paste0(OUT_TAB, "missing_covariates.csv"))
}

# -- SACU IT Share imputation -------------------------------------------------
# SACU members (BWA/SWZ/LSO/NAM/ZAF) often do not report intra-SADC flows
# separately in BACI, generating two problems:
#   (a) True NAs: it_share = NA where total_trade = 0 in BACI.
#   (b) Structural zeros: it_share = 0 where total_trade > 0 but
#       intra_trade = 0 because intra-SADC flows are not separately reported.
# Strategy: replace both with the mean IT Share of the five non-SACU SADC
# members (MOZ/MWI/TZA/ZMB/ZWE) by year. Robustness check m_no_sacu
# drops all SACU countries entirely to confirm imputation is not driving results.

SACU_ISO3     <- c("BWA","SWZ","LSO","NAM","ZAF")
NON_SACU_SADC <- c("MOZ","MWI","TZA","ZMB","ZWE")

panel <- panel |> mutate(it_share_imputed = FALSE)

sacu_audit <- panel |>
  filter(acp_iso3 %in% SACU_ISO3) |>
  distinct(acp_iso3, year, it_share) |>
  mutate(problem = case_when(
    is.na(it_share) ~ "true_NA",
    it_share == 0   ~ "structural_zero",
    TRUE            ~ "ok"
  )) |>
  filter(problem != "ok") |>
  count(acp_iso3, problem)

if (nrow(sacu_audit) > 0) {
  message("SACU it_share problems detected:")
  print(sacu_audit)
  write_csv(sacu_audit, paste0(OUT_TAB, "sacu_it_share_audit.csv"))
}

sacu_impute <- panel |>
  filter(acp_iso3 %in% NON_SACU_SADC) |>
  distinct(acp_iso3, year, it_share) |>
  filter(!is.na(it_share), it_share > 0) |>
  group_by(year) |>
  summarise(it_share_sacu_imputed = mean(it_share, na.rm = TRUE), .groups = "drop")

panel <- panel |>
  left_join(sacu_impute, by = "year") |>
  mutate(
    it_share_imputed = acp_iso3 %in% SACU_ISO3 & rec == "SADC" &
                       (is.na(it_share) | it_share == 0),
    it_share = if_else(it_share_imputed, it_share_sacu_imputed, it_share)
  ) |>
  select(-it_share_sacu_imputed)

n_filled <- sum(panel$it_share_imputed, na.rm = TRUE)
n_sadc   <- sum(panel$rec == "SADC", na.rm = TRUE)
message(sprintf("SACU imputation: %d rows (%.1f%% of SADC obs).",
                n_filled, 100 * n_filled / n_sadc))

# -- EPA variation by REC -----------------------------------------------------
panel |>
  filter(!is.na(rec)) |>
  distinct(acp_iso3, year, rec, epa) |>
  group_by(rec) |>
  summarise(
    n_treated   = sum(epa == 1L, na.rm = TRUE),
    n_untreated = sum(epa == 0L, na.rm = TRUE),
    pct_treated = round(100 * mean(epa == 1L, na.rm = TRUE), 1),
    .groups = "drop"
  ) |>
  arrange(desc(pct_treated)) |>
  print()

# -- Contiguity check ---------------------------------------------------------
cont_tab   <- table(panel$contiguity)
pct_contig <- if ("1" %in% names(cont_tab)) 100 * cont_tab["1"] / sum(cont_tab) else 0
USE_CONTIGUITY <- pct_contig >= 0.5
message(sprintf("Contiguity: %.2f%% of pairs — %s from all formulas.",
                pct_contig, if (USE_CONTIGUITY) "RETAINED" else "EXCLUDED"))

# =============================================================================
# 4. MODEL FORMULAS
# =============================================================================
ct  <- if (USE_CONTIGUITY) " + contiguity" else ""
FE  <- "| exporter_year + acp_iso3 + year"

f_baseline  <- as.formula(paste0("total_bilateral ~ ln_dist", ct, " + lang + colonial + epa", FE))
f_main      <- as.formula(paste0("total_bilateral ~ ln_dist", ct, " + lang + colonial + epa + it_share", FE))
f_inter     <- as.formula(paste0("total_bilateral ~ ln_dist", ct, " + lang + colonial + epa + it_share + epa:it_share", FE))
f_intensity <- as.formula(paste0("total_bilateral ~ ln_dist", ct, " + lang + colonial + epa + it_intensity", FE))
f_ols       <- as.formula(paste0("ln_trade ~ ln_dist",        ct, " + lang + colonial + epa + it_share", FE))
f_ols_plus  <- as.formula(paste0("ln_trade_plus ~ ln_dist",   ct, " + lang + colonial + epa + it_share", FE))
f_acp_exp   <- as.formula(paste0("ACP_to_EU ~ ln_dist",       ct, " + lang + colonial + epa + it_share", FE))
f_eu_exp    <- as.formula(paste0("EU_to_ACP ~ ln_dist",       ct, " + lang + colonial + epa + it_share", FE))

# =============================================================================
# 5. DESCRIPTIVE FIGURES
# Each plot is assigned to a named object so it prints to the RStudio Plots
# pane via print(), then also saved to disk via ggsave().

# IT Share distribution by REC
p_it_dist <- panel |>
  filter(!is.na(rec), !is.na(it_share)) |>
  distinct(acp_iso3, year, rec, it_share) |>
  ggplot(aes(x = it_share, fill = rec)) +
  geom_histogram(bins = 40, alpha = 0.85) +
  facet_wrap(~rec, scales = "free_y", nrow = 3) +
  scale_fill_manual(values = REC_COLOURS) +
  labs(title = "Intra-REC Trade Share by Regional Grouping",
       x = "IT Share", y = "Count") +
  theme_minimal() +
  theme(legend.position = "none")
print(p_it_dist)
ggsave(paste0(OUT_FIG, "it_share_distribution.png"), p_it_dist, width = 12, height = 8)

# Mean IT Share over time by REC
p_it_time <- panel |>
  filter(!is.na(rec), !is.na(it_share)) |>
  distinct(acp_iso3, year, rec, it_share) |>
  group_by(rec, year) |>
  summarise(mean_it_share = mean(it_share, na.rm = TRUE), .groups = "drop") |>
  ggplot(aes(x = year, y = mean_it_share, colour = rec)) +
  geom_line(linewidth = 0.9) +
  geom_point(size = 1.5) +
  scale_x_continuous(breaks = seq(1995, 2021, 5)) +
  scale_colour_manual(values = REC_COLOURS) +
  labs(title = "Mean Intra-REC Trade Share Over Time",
       x = NULL, y = "IT Share", colour = "REC") +
  theme_minimal()
print(p_it_time)
ggsave(paste0(OUT_FIG, "it_share_time_series.png"), p_it_time, width = 10, height = 5)

# IT Share vs ln(EU-ACP trade) — faceted scatter by REC
rec_year_avg <- panel |>
  filter(total_bilateral > 0, !is.na(rec)) |>
  group_by(rec, year) |>
  summarise(
    mean_it_share = mean(it_share,            na.rm = TRUE),
    mean_ln_trade = mean(log(total_bilateral), na.rm = TRUE),
    .groups = "drop"
  )

p_scatter <- ggplot(rec_year_avg, aes(x = mean_it_share, y = mean_ln_trade, colour = rec)) +
  geom_point(alpha = 0.7, size = 2) +
  geom_smooth(method = "lm", se = TRUE, colour = "black", fill = "grey80", linewidth = 0.9) +
  facet_wrap(~rec, scales = "free", nrow = 3) +
  scale_colour_manual(values = REC_COLOURS) +
  labs(
    title    = "Intra-REC Trade Share vs EU-ACP Trade by REC",
    subtitle = "Each point = REC-year average 1995-2021; negative slope = stumbling block",
    x = "Mean Intra-REC Trade Share",
    y = "ln(Mean EU-ACP Bilateral Trade)"
  ) +
  theme_minimal() +
  theme(legend.position = "none")
print(p_scatter)
ggsave(paste0(OUT_FIG, "stumbling_block_scatter.png"), p_scatter, width = 13, height = 10)

# Event study — calendar time, EPA vs non-EPA countries
epa_entry_years <- panel |>
  filter(epa == 1L) |>
  group_by(acp_iso3) |>
  summarise(entry_year = min(year), .groups = "drop")

event_data <- panel |>
  left_join(epa_entry_years, by = "acp_iso3") |>
  mutate(
    treated     = !is.na(entry_year),
    time_to_epa = if_else(treated, year - entry_year, NA_integer_),
    group       = if_else(treated, "EPA countries", "Non-EPA ACP countries")
  ) |>
  filter(total_bilateral > 0)

epa_entries <- tibble(
  year  = c(2008, 2009, 2012, 2014, 2016, 2018, 2019),
  label = c("CARIFORUM","PNG","ESA-4","CMR/FJI","SADC/CIV/GHA","MOZ","COM")
)

p_event_cal <- event_data |>
  group_by(group, year) |>
  summarise(mean_ln_trade = mean(log(total_bilateral), na.rm = TRUE), .groups = "drop") |>
  ggplot(aes(x = year, y = mean_ln_trade, colour = group)) +
  geom_line(linewidth = 1) +
  geom_point(size = 1.8) +
  geom_vline(xintercept = epa_entries$year, linetype = "dashed",
             colour = "grey60", linewidth = 0.4) +
  geom_text(data = epa_entries,
            aes(x = year, y = Inf, label = label),
            inherit.aes = FALSE, angle = 90, hjust = 1.1, vjust = -0.3,
            size = 2.6, colour = "grey40") +
  scale_x_continuous(breaks = seq(1995, 2021, 5)) +
  scale_colour_manual(
    values = c("EPA countries" = "#E06C75", "Non-EPA ACP countries" = "#56B4E9"),
    name = NULL
  ) +
  labs(
    title    = "Mean EU-ACP Trade: EPA vs Non-EPA Countries Over Time",
    subtitle = "Dashed lines = provisional-application dates; EAC treated as non-EPA throughout",
    x = NULL, y = "Mean ln(Bilateral Trade)"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")
print(p_event_cal)
ggsave(paste0(OUT_FIG, "event_study_descriptive.png"), p_event_cal, width = 10, height = 6)

# Event study — relative time around EPA entry
p_event_rel <- event_data |>
  filter(treated, !is.na(time_to_epa), between(time_to_epa, -10, 10)) |>
  group_by(time_to_epa) |>
  summarise(mean_ln_trade = mean(log(total_bilateral), na.rm = TRUE), .groups = "drop") |>
  ggplot(aes(x = time_to_epa, y = mean_ln_trade)) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_line(colour = "#2E75B6", linewidth = 1) +
  geom_point(colour = "#2E75B6", size = 2.5) +
  scale_x_continuous(breaks = seq(-10, 10, 2)) +
  labs(
    title    = "EU-ACP Trade Around EPA Entry (Relative Time)",
    subtitle = "t = 0 = year of provisional application; EPA countries only; pooled",
    x = "Years relative to EPA entry",
    y = "Mean ln(Bilateral Trade)"
  ) +
  theme_minimal()
print(p_event_rel)
ggsave(paste0(OUT_FIG, "event_study_relative.png"), p_event_rel, width = 9, height = 5)

# Zero-trade distribution by ACP country
p_zero <- panel |>
  filter(total_bilateral == 0) |>
  group_by(acp_iso3, rec) |>
  summarise(n_zero = n(), .groups = "drop") |>
  mutate(pct_zero = round(100 * n_zero / (27 * length(1995:2021)), 1)) |>
  ggplot(aes(x = reorder(acp_iso3, pct_zero), y = pct_zero, fill = rec)) +
  geom_bar(stat = "identity") +
  coord_flip() +
  scale_fill_manual(values = REC_COLOURS) +
  labs(
    title    = "Percentage of Zero-Trade Dyads by ACP Country",
    subtitle = "EU-27 x ACP x 1995-2021",
    x = NULL, y = "% Zero-Trade Pairs"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom", legend.title = element_blank())
print(p_zero)
ggsave(paste0(OUT_FIG, "zero_trade_distribution.png"), p_zero, width = 10, height = 12)

# =============================================================================
# 6. MAIN ESTIMATION

# M1: Baseline gravity (no IT Share)
m1 <- fepois(f_baseline, data = panel, cluster = ~pair_id)

# M2: Main specification — IT Share direct effect (PRIMARY MODEL)
m2 <- fepois(f_main, data = panel, cluster = ~pair_id)

# Pearson dispersion check
pearson_stat <- sum(residuals(m2, type = "response")^2 / fitted(m2)) /
  (nobs(m2) - length(coef(m2)))
message(sprintf("M2 Pearson dispersion: %.2f (1.0 = ideal Poisson)", pearson_stat))
if (pearson_stat > 2) {
  message("  Overdispersion detected (>2). NB-PML in robustness table.")
} else if (pearson_stat > 1.5) {
  message("  Mild overdispersion (1.5-2). NB-PML included as precautionary check.")
} else {
  message("  No substantial overdispersion. NB-PML included for completeness.")
}

# NB-PML always estimated — compared directly to PPML in robustness table
# to confirm variance assumption is not driving the main result.
m2_nb <- fenegbin(f_main, data = panel, cluster = ~pair_id)
message(sprintf(
  "NB-PML vs PPML comparison — it_share: NB = %.4f (SE %.4f) | PPML = %.4f (SE %.4f)",
  coef(m2_nb)["it_share"], se(m2_nb)["it_share"],
  coef(m2)["it_share"],    se(m2)["it_share"]
))

# M3: IT Share x EPA interaction
m3 <- fepois(f_inter, data = panel, cluster = ~pair_id)

# M4: IT Intensity (alternative integration measure)
m4 <- fepois(f_intensity, data = panel, cluster = ~pair_id)

# M5: OLS on log trade (zero pairs dropped; benchmark for PPML comparison)
m5 <- feols(f_ols, data = panel |> filter(total_bilateral > 0), cluster = ~pair_id)

etable(
  m1, m2, m3, m4, m5,
  title    = "ACP Intra-Regional Trade Integration and EU-ACP Bilateral Trade",
  headers  = c("Baseline\nPPML","IT Share\nPPML (Main)","IT Share x EPA\nPPML",
               "IT Intensity\nPPML","IT Share\nOLS"),
  dict     = DICT,
  se.below = TRUE, depvar = FALSE, fitstat = ~n + r2,
  notes    = paste0(
    "Clustered (pair_id) SEs. Panel: 78 ACP countries x EU-27 x 1995-2021. ",
    "Cols (1)-(4): PPML. Col (5): OLS on log trade (zero pairs dropped). ",
    "EAC epa = 0 throughout (EU-EAC EPA never applied in panel period). ",
    "HTI, MWI, ZMB: signed but never applied / never signed."),
  file = paste0(OUT_TAB, "main_results.tex")
)

# =============================================================================
# 7. DIRECTIONAL DECOMPOSITION — ACP EXPORTS vs EU EXPORTS

m_acp_exp <- fepois(f_acp_exp, data = panel, cluster = ~pair_id)
m_eu_exp  <- fepois(f_eu_exp,  data = panel, cluster = ~pair_id)

etable(
  m2, m_acp_exp, m_eu_exp,
  title    = "IT Share Effect by Trade Direction",
  headers  = c("Total Bilateral","ACP Exports to EU","EU Exports to ACP"),
  dict     = DICT,
  se.below = TRUE, depvar = FALSE, fitstat = ~n,
  file     = paste0(OUT_TAB, "direction_results.tex")
)

# =============================================================================
# 8. REC SUBSAMPLE REGRESSIONS

rec_models <- REC_LEVELS |>
  set_names() |>
  map(function(r) fepois(f_main, data = panel |> filter(rec == r), cluster = ~pair_id))

do.call(etable, c(
  unname(rec_models),
  list(
    title    = "IT Share Effect by REC — Subsample Regressions",
    headers  = REC_LEVELS,
    dict     = DICT,
    se.below = TRUE, depvar = FALSE, fitstat = ~n,
    notes    = paste0(
      "PPML with exporter-year + ACP-country + year FEs. ",
      "EPA collinear with year FE in CARIFORUM (all 15 countries treated in 2009). ",
      "EAC: epa = 0 for all countries/years."),
    file     = paste0(OUT_TAB, "rec_subsample_results.tex")
  )
))

# =============================================================================
# 9. ADDITIONAL FIGURES — COEFFICIENT STABILITY AND REC FOREST PLOT

# Regional subsamples (also used in robustness)
m_africa    <- fepois(f_main, data = panel |> filter(acp_region == "Africa"),    cluster = ~pair_id)
m_caribbean <- fepois(f_main, data = panel |> filter(acp_region == "Caribbean"), cluster = ~pair_id)
m_pacific   <- fepois(f_main, data = panel |> filter(acp_region == "Pacific"),   cluster = ~pair_id)
m_from98    <- fepois(f_main, data = panel |> filter(year >= 1998),              cluster = ~pair_id)
m_no_zaf    <- fepois(f_main, data = panel |> filter(acp_iso3 != "ZAF"),         cluster = ~pair_id)
m_no_nga    <- fepois(f_main, data = panel |> filter(acp_iso3 != "NGA"),         cluster = ~pair_id)

# Coefficient stability plot
coef_data <- tibble(
  spec = c("M2: Main PPML","M2-NB: NB-PML","M5: OLS",
           "Africa","Caribbean","Pacific",
           "From 1998","Excl. South Africa","Excl. Nigeria"),
  coef = c(coef(m2)[["it_share"]], coef(m2_nb)[["it_share"]], coef(m5)[["it_share"]],
           coef(m_africa)[["it_share"]], coef(m_caribbean)[["it_share"]],
           coef(m_pacific)[["it_share"]],
           coef(m_from98)[["it_share"]], coef(m_no_zaf)[["it_share"]],
           coef(m_no_nga)[["it_share"]]),
  se   = c(se(m2)[["it_share"]], se(m2_nb)[["it_share"]], se(m5)[["it_share"]],
           se(m_africa)[["it_share"]], se(m_caribbean)[["it_share"]],
           se(m_pacific)[["it_share"]],
           se(m_from98)[["it_share"]], se(m_no_zaf)[["it_share"]],
           se(m_no_nga)[["it_share"]])
) |>
  mutate(ci_lo = coef - 1.96 * se, ci_hi = coef + 1.96 * se)

p_coef_stab <- ggplot(coef_data, aes(x = coef, y = reorder(spec, coef))) +
  geom_vline(xintercept = 0, linetype = "dashed", colour = "red") +
  geom_errorbar(aes(xmin = ci_lo, xmax = ci_hi), width = 0.3, colour = "steelblue") +
  geom_point(size = 3, colour = "steelblue") +
  labs(
    title    = "Coefficient Stability Across Specifications",
    subtitle = "Effect of IT Share on EU-ACP bilateral trade; 95% CI",
    x = "Coefficient on IT Share", y = NULL
  ) +
  theme_minimal()
print(p_coef_stab)
ggsave(paste0(OUT_FIG, "coef_stability.png"), p_coef_stab, width = 10, height = 6)

# REC forest plot (PIF excluded — sparse data)
rec_coefs <- imap_dfr(rec_models, function(mod, rec_name) {
  if (!"it_share" %in% names(coef(mod))) {
    message("  it_share collinear in REC: ", rec_name)
    return(NULL)
  }
  tibble(rec      = rec_name,
         estimate = coef(mod)[["it_share"]],
         se       = se(mod)[["it_share"]])
}) |>
  mutate(
    ci_lo = estimate - 1.96 * se,
    ci_hi = estimate + 1.96 * se,
    rec   = factor(rec, levels = rev(REC_LEVELS))
  )

if (nrow(rec_coefs) > 0) {
  p_rec_forest <- ggplot(rec_coefs |> filter(as.character(rec) != "PIF"),
         aes(x = estimate, y = rec, colour = rec)) +
    geom_vline(xintercept = 0, linetype = "dashed", colour = "grey50") +
    geom_errorbar(aes(xmin = ci_lo, xmax = ci_hi),
                  width = 0.25, linewidth = 0.8, orientation = "y") +
    geom_point(size = 3.5) +
    scale_colour_manual(values = REC_COLOURS) +
    labs(
      title    = "Effect of IT Share on EU-ACP Trade by REC",
      subtitle = "PPML subsample regressions; 95% CI; clustered SE at pair level\nPIF excluded (sparse data)",
      x = "Coefficient on Intra-REC Trade Share", y = NULL
    ) +
    theme_minimal() +
    theme(legend.position = "none")
  print(p_rec_forest)
  ggsave(paste0(OUT_FIG, "rec_coef_plot.png"), p_rec_forest, width = 8, height = 5)
}

# =============================================================================
# 10. MARGINAL EFFECTS — IT Share effect across its observed range

b_it <- coef(m2)["it_share"]
b_se <- se(m2)["it_share"]

rec_means <- panel |>
  filter(!is.na(it_share), !is.na(rec)) |>
  distinct(acp_iso3, year, rec, it_share) |>
  group_by(rec) |>
  summarise(mean_it = mean(it_share, na.rm = TRUE), .groups = "drop")

it_grid <- tibble(
  it_share_level = seq(
    quantile(panel$it_share, 0.02, na.rm = TRUE),
    quantile(panel$it_share, 0.98, na.rm = TRUE),
    length.out = 300
  )
) |>
  mutate(
    pct_change = 100 * (exp(b_it * it_share_level) - 1),
    ci_lo      = 100 * (exp((b_it - 1.96 * b_se) * it_share_level) - 1),
    ci_hi      = 100 * (exp((b_it + 1.96 * b_se) * it_share_level) - 1)
  )

p_marginal <- ggplot(it_grid, aes(x = it_share_level, y = pct_change)) +
  geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), fill = "#2E75B6", alpha = 0.15) +
  geom_line(colour = "#2E75B6", linewidth = 1.1) +
  geom_hline(yintercept = 0, linetype = "dashed", colour = "grey50") +
  geom_vline(xintercept = quantile(panel$it_share, c(0.25, 0.75), na.rm = TRUE),
             linetype = "dotdash", colour = "grey70", linewidth = 0.5) +
  geom_vline(data = rec_means,
             aes(xintercept = mean_it, colour = rec),
             linetype = "dotted", linewidth = 0.8) +
  geom_text(
    data = rec_means |>
      arrange(mean_it) |>
      mutate(label_y = max(it_grid$ci_hi) * c(0.55, 0.65, 0.75, 0.82, 0.88, 0.92, 0.92)),
    aes(x = mean_it, y = label_y, label = rec, colour = rec),
    angle = 90, hjust = 1, vjust = -0.4, size = 3, show.legend = FALSE
  ) +
  scale_colour_manual(values = REC_COLOURS, name = "REC mean") +
  labs(
    title    = "Effect of Intra-REC Trade Share on EU-ACP Trade",
    subtitle = "PPML (M2); shaded = 95% CI; dotted = REC mean IT Share; dot-dash = IQR",
    x = "Intra-REC Trade Share",
    y = "Estimated % change in bilateral trade"
  ) +
  theme_minimal()
print(p_marginal)
ggsave(paste0(OUT_FIG, "marginal_effects_it_share.png"), p_marginal, width = 9, height = 5)

# Marginal effects table — key percentiles + REC means (for paper/appendix)
it_p10  <- quantile(panel$it_share, 0.10, na.rm = TRUE)
it_mean <- mean(panel$it_share,           na.rm = TRUE)
it_p90  <- quantile(panel$it_share, 0.90, na.rm = TRUE)

marginal_tbl <- bind_rows(
  tibble(label = c("p10", "Mean", "p90"),
         it_level = c(it_p10, it_mean, it_p90)),
  rec_means |> transmute(label = paste0("REC mean: ", rec), it_level = mean_it)
) |>
  mutate(
    pct_change = round(100 * (exp(b_it * it_level) - 1), 1),
    ci_lo      = round(100 * (exp((b_it - 1.96 * b_se) * it_level) - 1), 1),
    ci_hi      = round(100 * (exp((b_it + 1.96 * b_se) * it_level) - 1), 1),
    it_level   = round(it_level, 4)
  )

print(marginal_tbl)
write_csv(marginal_tbl, paste0(OUT_TAB, "marginal_effects_table.csv"))

# LaTeX version
writeLines(c(
  "\\begin{tabular}{lrrr}",
  "\\midrule\\midrule",
  "Evaluation point & IT Share & \\% change in trade & 95\\% CI \\\\",
  "\\midrule",
  sprintf("%-28s & %.4f & %+.1f\\%% & [%.1f, %.1f] \\\\",
          marginal_tbl$label, marginal_tbl$it_level,
          marginal_tbl$pct_change, marginal_tbl$ci_lo, marginal_tbl$ci_hi),
  "\\midrule\\midrule",
  sprintf("\\ multicol{4}{l}{\\emph{PPML (M2) coefficient $\\hat{\\beta} = %.3f$, clustered SE = %.3f.}}\\\\",
          b_it, b_se),
  "\\ multicol{4}{l}{\\emph{\\% change $= 100(\\exp(\\hat{\\beta} \\times \\text{IT Share}) - 1)$.}}\\\\",
  "\\end{tabular}"
), paste0(OUT_TAB, "marginal_effects_table.tex"))
message("Marginal effects table saved.")

# =============================================================================
# 11. ROBUSTNESS CHECKS

m5b          <- feols(f_ols_plus, data = panel,                                       cluster = ~pair_id)
m_no_carifo  <- fepois(f_main, data = panel |> filter(rec != "CARIFORUM"),            cluster = ~pair_id)
m_no_pif     <- fepois(f_main, data = panel |> filter(rec != "PIF"),                  cluster = ~pair_id)
m_no_som_eri <- fepois(f_main, data = panel |> filter(!acp_iso3 %in% c("SOM","ERI")), cluster = ~pair_id)
m_no_sacu    <- fepois(f_main, data = panel |> filter(!acp_iso3 %in% SACU_ISO3),      cluster = ~pair_id)

etable(
  m2, m2_nb, m5b, m_no_carifo, m_no_pif,
  headers  = c("Baseline PPML","NB-PML","OLS log(1+trade)","Excl. CARIFORUM","Excl. PIF"),
  title    = "Robustness: Specification and Overdispersion Check",
  dict     = DICT,
  se.below = TRUE, depvar = FALSE, fitstat = ~n,
  notes    = paste0(
    "Col (2): Negative Binomial PML — relaxes Poisson variance assumption; ",
    "close agreement with col (1) confirms overdispersion is not biasing PPML SEs. ",
    "OLS log(1+trade) retains zero-trade pairs. ",
    "Excl. CARIFORUM: all 15 countries signed EPA simultaneously — no within-REC EPA variation. ",
    "Excl. PIF: Pacific Islands have >25% zero-trade share."),
  file     = paste0(OUT_TAB, "robustness_specification.tex")
)

etable(
  m2, m_from98, m_no_zaf, m_no_nga, m_no_som_eri, m_no_sacu,
  headers  = c("Baseline","From 1998","Excl. S.Africa","Excl. Nigeria","Excl. SOM+ERI","Excl. SACU"),
  title    = "Robustness: Sample Sensitivity",
  dict     = DICT,
  se.below = TRUE, depvar = FALSE, fitstat = ~n,
  notes    = paste0(
    "From 1998 drops years with sparse BACI coverage. ",
    "South Africa and Nigeria dominate SADC and ECOWAS trade totals. ",
    "SOM and ERI dropped due to persistent WDI data gaps. ",
    "Excl. SACU drops BWA/SWZ/LSO/NAM/ZAF to check sensitivity to IT Share imputation."),
  file     = paste0(OUT_TAB, "robustness_sample.tex")
)

etable(
  m2, m_africa, m_caribbean, m_pacific,
  headers  = c("Full ACP","Africa","Caribbean","Pacific"),
  title    = "Robustness: ACP Regional Subsamples",
  dict     = DICT,
  se.below = TRUE, depvar = FALSE, fitstat = ~n,
  notes    = "EPA absorbed by year FE in Caribbean subsample (all CARIFORUM countries signed in 2008/09).",
  file     = paste0(OUT_TAB, "robustness_regional.tex")
)

# =============================================================================
# 12. OLS vs PPML COMPARISON (zeros diagnostic)

coef_comparison <- tibble(
  model      = c("PPML — includes zeros (M2)", "OLS — excludes zeros (M5)"),
  it_share   = c(coef(m2)["it_share"],  coef(m5)["it_share"]),
  se         = c(se(m2)["it_share"],    se(m5)["it_share"]),
  n_obs      = c(nobs(m2),              nobs(m5)),
  zeros_incl = c(TRUE,                  FALSE)
) |>
  mutate(
    across(c(it_share, se), \(x) round(x, 4)),
    pct_diff_from_ppml = round(100 * (it_share - it_share[1]) / abs(it_share[1]), 1)
  )

print(coef_comparison)
write_csv(coef_comparison, paste0(OUT_TAB, "ols_vs_ppml_comparison.csv"))
message(sprintf(
  "Zero-trade pairs in PPML but not OLS: %d (%.1f%% of PPML sample).",
  nobs(m2) - nobs(m5), 100 * (nobs(m2) - nobs(m5)) / nobs(m2)
))

# =============================================================================
# 13. CONSOLIDATED RESULTS TABLE

safe_coef <- function(model, var) {
  if (var %in% names(coef(model))) coef(model)[[var]] else NA_real_
}
safe_se <- function(model, var) {
  if (var %in% names(se(model))) se(model)[[var]] else NA_real_
}
# it_p10, it_mean, it_p90, b_it all defined in section 10 above

results_consolidated <- bind_rows(
  tibble(
    type          = "Main",
    specification = c("M1: Baseline PPML","M2: Main PPML","M2-NB: NB-PML",
                      "M3: + EPA interaction","M4: IT Intensity","M5: OLS"),
    it_coef = c(safe_coef(m1,"it_share"),    safe_coef(m2,"it_share"),
                safe_coef(m2_nb,"it_share"), safe_coef(m3,"it_share"),
                safe_coef(m4,"it_intensity"), safe_coef(m5,"it_share")),
    it_se   = c(safe_se(m1,"it_share"),      safe_se(m2,"it_share"),
                safe_se(m2_nb,"it_share"),   safe_se(m3,"it_share"),
                safe_se(m4,"it_intensity"),  safe_se(m5,"it_share")),
    n       = c(nobs(m1), nobs(m2), nobs(m2_nb), nobs(m3), nobs(m4), nobs(m5))
  ),
  tibble(
    type          = "Direction",
    specification = c("D1: ACP exports to EU","D2: EU exports to ACP"),
    it_coef = c(safe_coef(m_acp_exp,"it_share"), safe_coef(m_eu_exp,"it_share")),
    it_se   = c(safe_se(m_acp_exp,  "it_share"), safe_se(m_eu_exp,  "it_share")),
    n       = c(nobs(m_acp_exp), nobs(m_eu_exp))
  ),
  tibble(
    type          = "Regional",
    specification = c("R1: Africa","R2: Caribbean","R3: Pacific","R4: Excl. SACU"),
    it_coef = c(safe_coef(m_africa,"it_share"),    safe_coef(m_caribbean,"it_share"),
                safe_coef(m_pacific,"it_share"),   safe_coef(m_no_sacu,"it_share")),
    it_se   = c(safe_se(m_africa,"it_share"),      safe_se(m_caribbean,"it_share"),
                safe_se(m_pacific,"it_share"),     safe_se(m_no_sacu,"it_share")),
    n       = c(nobs(m_africa), nobs(m_caribbean), nobs(m_pacific), nobs(m_no_sacu))
  ),
  tibble(
    type          = "Marginal",
    specification = c("ME: At p10 IT Share","ME: At mean IT Share","ME: At p90 IT Share"),
    it_coef       = c(it_p10, it_mean, it_p90),
    it_se         = NA_real_,
    n             = NA_integer_,
    pct_change    = round(100 * (exp(b_it * c(it_p10, it_mean, it_p90)) - 1), 1)
  )
) |>
  mutate(
    it_coef = round(it_coef, 3),
    it_se   = round(it_se, 3),
    sig = case_when(
      !is.na(it_se) & abs(it_coef / it_se) > 2.576 ~ "***",
      !is.na(it_se) & abs(it_coef / it_se) > 1.960 ~ "**",
      !is.na(it_se) & abs(it_coef / it_se) > 1.645 ~ "*",
      TRUE ~ ""
    )
  )

print(results_consolidated, n = 20)
write_csv(results_consolidated, paste0(OUT_TAB, "results_consolidated.csv"))

message("All estimation and diagnostics complete.")
message("  Figures: ", OUT_FIG)
message("  Tables:  ", OUT_TAB)

