
## Original datasets

 From CEPii

[Gravity_csv_V202211](https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=8)

The CEPII Gravity dataset provides a comprehensive set of bilateral variables for any country pair from 1948 to 2020, covering everything needed to estimate a structural gravity equation: bilateral trade flows, capital-to-capital distances, trade facilitation measures, macroeconomic indicators, and proxies for cultural proximity such as common language and colonial history. In this project it serves as the source for all time-invariant and slow-moving dyadic gravity controls — specifically capital distance (`distcap`), official common language (`comlang_off`), contiguity (`contig`), and ever-colonial-relationship (`col_dep_ever`) — which are merged into the panel at the EU–ACP country-pair–year level. The dataset is loaded as a pre-converted `.rds` file (`Gravity_V202211.rds`) rather than the raw CSV for speed. Its 2020 coverage ceiling is the binding constraint on the panel: extending to 2022 would silently drop all 2022 observations due to missing gravity covariates for every dyad in that year, which is why the panel ends in 2021. CEPII GDP and population series from the same file are also available as a fallback if the WDI download fails, though they likewise only extend to 2020.

[BACI_HS92_V202601](https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele_item.asp?id=37)(1995-2024)

BACI provides harmonised bilateral trade flow data for around 200 countries at the 6-digit Harmonized System product level (roughly 5,000 products), drawing on Comtrade reports submitted by UN member states. Its key methodological contribution over raw Comtrade is the reconciliation of import and export reports: since country _i_ reports exports to _j_ and country _j_ independently reports imports from _i_, the raw Comtrade data contains duplicate and often inconsistent flow records. BACI resolves these discrepancies using CIF/FOB adjustment factors and a reconciliation procedure that produces a single harmonised value per directed trade flow. In this project, annual files for 1995–2021 (`BACI_HS92_Y{year}_V202601.csv`) are used as the primary source for all trade values. The 6-digit product dimension is immediately collapsed by summing across HS codes within each country-pair-year, since the analysis operates at the aggregate bilateral level; the collapsed result is cached as `baci_raw_cache_v3.rds`. BACI flows feed three distinct uses in the pipeline: EU–ACP bilateral trade values (`ACP_to_EU`, `EU_to_ACP`), intra-REC trade totals used to construct the IT share variable, and world trade totals used to normalise IT intensity.


***

### EU_ACP_Panel

![[eu_acp_panel_v3.csv]]

![[eu_acp_panel_v3.rds]]

A bilateral panel covering all EU–ACP country pairs (27 EU × 78 ACP countries), yielding 46,566 observations. Built from BACI, WDI, and CEPII Gravity sources. Each row represents a directed country-pair–year observation and includes:

- **Trade flows**: `ACP_to_EU`, `EU_to_ACP`, `total_bilateral` (in thousands USD); aggregated total and intra-REC trade for gravity controls
- **Gravity variables**: bilateral distance, common language, contiguity, colonial relationship (from CEPII Gravity)
- **Macroeconomic controls**: GDP and population for both the EU and ACP partner (from WDI); log-transformed versions included
- **Treatment variables**: `epa` (binary; 1 = EPA in force), `epa_years` (years since EPA entry into force), `tls_pre_indep` (pre-independence tariff preference flag)
- **Regional groupings**: `rec` identifies the ACP Regional Economic Community (ECOWAS, SADC, EAC, COMESA, Central Africa, CARIFORUM, PIF)
- **Fixed effect identifiers**: `pair_id`, `exporter_year`, `importer_year` for PPML/OLS estimation
- **Intermediary trade measures**: `it_share` (share of EU–ACP trade intermediated through third countries), `it_intensity`


***

### WDI_gdp_pop

![[wdi_gdp_pop_cache_v3.rds]]


A cached extract from the [World Bank World Development Indicators](https://databank.worldbank.org/source/world-development-indicators), downloaded via the `WDI` R package. On first run, `01_build_panel.R` queries the WDI API for two series — GDP at current USD (`NY.GDP.MKTP.CD`) and total population (`SP.POP.TOTL`) — for all countries over 1995–2021, cleans the result, and saves it as an `.rds` to avoid repeated API calls. Two countries missing from WDI entirely — Cook Islands (COK) and Niue (NIU) — are patched manually using GDP-per-capita × population figures hardcoded in the script before the cache is written, so the cache already includes them. A CEPII Gravity fallback is also coded in case the WDI download fails, though this is a last resort as CEPII's GDP and population series only extend to 2020, which would silently drop the 2021 cross-section. The cached object feeds the `gdp_acp`, `pop_acp`, `gdp_eu`, and `pop_eu` columns in the final panel; known gaps for Somalia (state collapse) and Eritrea (post-2012 reporting breakdown) are retained as `NA` rather than imputed, with PPML handling them by conditioning on observed trade flows and OLS dropping them automatically.

***

### baci_raw

![[baci_raw_cache_v3.rds]]


A cached intermediate generated by `01_build_panel.R` to avoid reloading the full BACI source files on every run. The full BACI HS92 V202601 dataset lives as 27 separate annual CSV files on disk (`BACI_HS92_Y{year}_V202601.csv`, one per year 1995–2021), each containing millions of rows at the product level — one row per exporter–importer–HS6 product combination. On first run, the script reads each annual file, immediately drops the product dimension by summing trade values across all HS codes within each country-pair-year, and saves the collapsed result as a single `.rds`; on subsequent runs it skips the 27-file loop entirely and loads this one object instead. The cache therefore contains all-country-pair totals with the 6-digit product detail discarded — EU–ACP filtering happens downstream in the same script.