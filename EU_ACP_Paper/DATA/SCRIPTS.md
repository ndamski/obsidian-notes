

## 01_Build Panel

![[01_build_panel.r]]


The full data pipeline that constructs `eu_acp_panel_v3`. Run this first. It loads BACI annual files (caching the filtered result to `baci_raw_cache_v3.rds` to avoid reloading ~30 CSV files), downloads WDI GDP/population via the `WDI` package (cached to `wdi_gdp_pop_cache_v3.rds`), and merges in CEPII Gravity structural variables. Key construction choices documented in the script header: time-varying EU membership via the enlargement table (2004, 2007, 2013 accessions); EPA treatment dates verified against EUR-Lex; EAC, HTI, MWI, ZMB coded `epa = 0` throughout; WSM and SLB excluded from EPA treatment due to near-zero EU trade. Cook Islands and Niue GDP/population are manually patched (not in WDI). Intra-REC trade share and intensity are computed from raw BACI flows with separate handling for Mauritania (ECOWAS 1995–2000 only) and Timor-Leste (PIF from 2002; `rec = NA` pre-independence). Outputs: `eu_acp_panel_v3.rds` and `.csv`.

***

## 02_Estimate Gravity

![[02_estimate_gravity.r]]



Estimation and output script. Run after `01_build_panel.R`. Loads the panel, applies SACU IT share imputation (SACU members frequently show structural zeros in BACI intra-SADC flows; replaced with the mean of the five non-SACU SADC members by year), and estimates five main specifications using `fixest`: M1 baseline PPML, M2 main PPML with IT share (primary result), M3 with EPA × IT share interaction, M4 using IT intensity, and M5 OLS on log trade. Fixed effects throughout are exporter-year + ACP-country + year (importer-year is intentionally split to preserve identification of `it_share` and `epa`, which vary only at the ACP × year level). Also runs directional decompositions (ACP exports vs EU exports), REC subsample regressions, a suite of robustness checks (NB-PML, sample exclusions, regional subsamples, SACU exclusion), and marginal effects calculations. Saves LaTeX tables and PNG figures to `output/tables/` and `output/figures/`.