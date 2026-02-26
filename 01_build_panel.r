# =============================================================================
# EU-ACP GRAVITY PANEL: DATA PIPELINE
# =============================================================================
# Constructs a bilateral trade panel: 78 ACP countries x EU-27 x 1995-2021.
#
# Panel ends in 2021 because CEPII Gravity V202211 covers through 2021 at most.
# Extending to 2022 would silently drop the entire 2022 cross-section from
# estimation due to missing gravity covariates for all dyads in that year.
#
# Data sources:
#   - BACI HS92 V202601 (trade flows; annual files loaded for YEARS = 1995:2021)
#   - CEPII Gravity V202211 (distance, language, colonial tie, contiguity; through 2021)
#   - World Bank WDI (GDP, population; COK/NIU patched manually through 2021)
#
# EPA treatment:
#   Provisional-application dates verified against EUR-Lex primary sources.
#   Countries that signed but never applied, or never signed, receive epa = 0:
#     EAC (BDI/KEN/RWA/TZA/UGA): EU-EAC EPA never provisionally applied
#     HTI: signed Dec 2009, never applied
#     MWI, ZMB: never signed the ESA EPA
#     WSM: applied 31 Dec 2018 — excluded from EPA treatment (near-zero EU trade)
#     SLB: applied 17 May 2020 — excluded from EPA treatment (near-zero EU trade)
#     TLS, DJI, ERI, ETH, SDN, AGO, COD: never signed
#
# REC membership:
#   MRT: ECOWAS 1995-2000; unaffiliated 2001 onward (associate 2017 ≠ full member)
#   TLS: rec = NA pre-independence (1995-2001); PIF from 2002
#
# Missing data:
#   SOM/ERI GDP gaps: rows retained with gdp_acp = NA.
#   PPML handles these via conditioning on trade flows; OLS drops them.
#   SADC SACU IT Share gaps: imputed in script 02.
# =============================================================================

set.seed(42)
rm(list = ls())

library(tidyverse)
library(WDI)
library(fixest)

# =============================================================================
# 0. PATHS
# =============================================================================
BACI_DIR     <- "C:/Users/ndams/Documents/Erol/data/BACI_HS92_V202601/"
GRAVITY_FILE <- "C:/Users/ndams/Documents/Erol/Data/Gravity_rds_V202211/Gravity_V202211.rds"
DATA_DIR     <- "C:/Users/ndams/Documents/Erol/Data/"
OUT_DIR      <- "C:/Users/ndams/Documents/Erol/output/"

dir.create(paste0(OUT_DIR, "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(paste0(OUT_DIR, "tables"),  recursive = TRUE, showWarnings = FALSE)

YEARS <- 1995:2021  # CEPII Gravity V202211 covers through 2021; 2022 dropped

# =============================================================================
# 1. EU MEMBERSHIP (time-varying via enlargement table)
# =============================================================================
EU_ISO3 <- c(
  "AUT","BEL","BGR","HRV","CYP","CZE","DNK","EST","FIN","FRA","DEU","GRC",
  "HUN","IRL","ITA","LVA","LTU","LUX","MLT","NLD","POL","PRT","ROU","SVK",
  "SVN","ESP","SWE"
)

EU_ENLARGEMENT <- tribble(
  ~eu_iso3, ~eu_entry_year,
  "CYP", 2004L, "CZE", 2004L, "EST", 2004L, "HUN", 2004L,
  "LVA", 2004L, "LTU", 2004L, "MLT", 2004L, "POL", 2004L,
  "SVK", 2004L, "SVN", 2004L, "BGR", 2007L, "ROU", 2007L,
  "HRV", 2013L
)

# =============================================================================
# 2. REC MEMBERSHIP — 78 Cotonou ACP countries
# =============================================================================
REC_MEMBERSHIP_STATIC <- tribble(
  ~iso3,  ~rec,

  # ECOWAS — 15 permanent ACP members (MRT handled separately)
  "BEN","ECOWAS",  "BFA","ECOWAS",  "CPV","ECOWAS",  "CIV","ECOWAS",
  "GHA","ECOWAS",  "GIN","ECOWAS",  "GNB","ECOWAS",  "LBR","ECOWAS",
  "MLI","ECOWAS",  "NER","ECOWAS",  "NGA","ECOWAS",  "SEN","ECOWAS",
  "SLE","ECOWAS",  "GMB","ECOWAS",  "TGO","ECOWAS",

  # Central Africa (CEMAC-6 + STP)
  "CMR","Central Africa",  "CAF","Central Africa",  "TCD","Central Africa",
  "COG","Central Africa",  "GAB","Central Africa",  "GNQ","Central Africa",
  "STP","Central Africa",

  # SADC EPA group (AGO and COD retain SADC REC for IT Share; epa = 0)
  "AGO","SADC",  "BWA","SADC",  "COD","SADC",  "SWZ","SADC",
  "LSO","SADC",  "MOZ","SADC",  "NAM","SADC",  "ZAF","SADC",

  # EAC (epa = 0 throughout — EU-EAC EPA never provisionally applied 1995-2022)
  "BDI","EAC",  "KEN","EAC",  "RWA","EAC",  "TZA","EAC",  "UGA","EAC",

  # COMESA / ESA EPA group
  "COM","COMESA",  "DJI","COMESA",  "ERI","COMESA",  "ETH","COMESA",
  "MDG","COMESA",  "MWI","COMESA",  "MUS","COMESA",  "SOM","COMESA",
  "SYC","COMESA",  "SDN","COMESA",  "ZMB","COMESA",  "ZWE","COMESA",

  # CARIFORUM (HTI signed Dec 2009 but never applied; epa = 0)
  "ATG","CARIFORUM",  "BHS","CARIFORUM",  "BRB","CARIFORUM",  "BLZ","CARIFORUM",
  "DMA","CARIFORUM",  "DOM","CARIFORUM",  "GRD","CARIFORUM",  "GUY","CARIFORUM",
  "HTI","CARIFORUM",  "JAM","CARIFORUM",  "KNA","CARIFORUM",  "LCA","CARIFORUM",
  "SUR","CARIFORUM",  "TTO","CARIFORUM",  "VCT","CARIFORUM",

  # PIF — 14 static Pacific ACP states (TLS handled separately)
  # WSM (EPA 31 Dec 2018) and SLB (EPA 17 May 2020) are within the panel
  # but excluded from EPA treatment due to near-zero EU bilateral trade.
  # Both are retained in PIF for IT Share calculation.
  "COK","PIF",  "FJI","PIF",  "KIR","PIF",  "MHL","PIF",  "FSM","PIF",
  "NRU","PIF",  "NIU","PIF",  "PLW","PIF",  "PNG","PIF",  "WSM","PIF",
  "SLB","PIF",  "TON","PIF",  "TUV","PIF",  "VUT","PIF"
)

# MRT: ECOWAS 1995-2000; associate agreement Aug 2017 is not full membership
MRT_REC <- bind_rows(
  tibble(iso3 = "MRT", year = 1995:2000,       rec = "ECOWAS"),
  tibble(iso3 = "MRT", year = 2001:max(YEARS), rec = NA_character_)
)

# TLS: pre-independence rows retained with rec = NA; PIF from 2002
TLS_REC <- bind_rows(
  tibble(iso3 = "TLS", year = 1995:2001,       rec = NA_character_),
  tibble(iso3 = "TLS", year = 2002:max(YEARS), rec = "PIF")
)

ACP_ISO3   <- c(unique(REC_MEMBERSHIP_STATIC$iso3), "MRT", "TLS")
REC_LEVELS <- c("ECOWAS","Central Africa","SADC","EAC","COMESA","CARIFORUM","PIF")

stopifnot(length(ACP_ISO3) == 78)
message("ACP universe: 78 Cotonou signatories confirmed.")

REC_LOOKUP <- REC_MEMBERSHIP_STATIC |>
  mutate(year = list(YEARS)) |>
  unnest(year) |>
  bind_rows(MRT_REC |> filter(year %in% YEARS)) |>
  bind_rows(TLS_REC |> filter(year %in% YEARS))

# =============================================================================
# 3. EPA DATES — verified provisional-application dates from EUR-Lex
# =============================================================================
EPA_DATES <- tribble(
  ~iso3,  ~epa_date,

  # Central Africa
  "CMR",  as.Date("2014-08-04"),

  # West Africa stepping-stone EPAs
  "CIV",  as.Date("2016-09-03"),
  "GHA",  as.Date("2016-12-15"),

  # ESA EPA (MDG/MUS/SYC/ZWE only; MWI and ZMB never signed)
  "MDG",  as.Date("2012-05-14"),
  "MUS",  as.Date("2012-05-14"),
  "SYC",  as.Date("2012-05-14"),
  "ZWE",  as.Date("2012-05-14"),
  "COM",  as.Date("2019-02-07"),

  # SADC EPA (MOZ joined later: 4 Feb 2018)
  "BWA",  as.Date("2016-10-10"),
  "LSO",  as.Date("2016-10-10"),
  "NAM",  as.Date("2016-10-10"),
  "SWZ",  as.Date("2016-10-10"),
  "ZAF",  as.Date("2016-10-10"),
  "MOZ",  as.Date("2018-02-04"),

  # CARIFORUM — 14 applying members (HTI excluded)
  "ATG",  as.Date("2008-12-29"),  "BHS",  as.Date("2008-12-29"),
  "BRB",  as.Date("2008-12-29"),  "BLZ",  as.Date("2008-12-29"),
  "DMA",  as.Date("2008-12-29"),  "DOM",  as.Date("2008-12-29"),
  "GRD",  as.Date("2008-12-29"),  "GUY",  as.Date("2008-12-29"),
  "JAM",  as.Date("2008-12-29"),  "KNA",  as.Date("2008-12-29"),
  "LCA",  as.Date("2008-12-29"),  "VCT",  as.Date("2008-12-29"),
  "SUR",  as.Date("2008-12-29"),  "TTO",  as.Date("2008-12-29"),

  # Pacific
  "PNG",  as.Date("2009-12-20"),
  "FJI",  as.Date("2014-07-28")
  # WSM and SLB excluded from EPA treatment (see header notes)
)

stopifnot(all(as.integer(format(EPA_DATES$epa_date, "%Y")) >= min(YEARS)))
message("EPA date range check passed.")

# =============================================================================
# 4. BACI TRADE FLOWS (with annual-file cache)
# =============================================================================
baci_cache <- paste0(DATA_DIR, "baci_raw_cache_v3.rds")

baci_cc <- read_csv(file.path(BACI_DIR, "country_codes_V202601.csv"),
                    col_types = cols(.default = "c")) |>
  select(numeric_code = country_code, iso3 = country_iso3)

if (file.exists(baci_cache)) {
  message("Loading BACI from cache...")
  baci <- readRDS(baci_cache)
} else {
  message("Loading BACI (", min(YEARS), "-", max(YEARS), ") from annual files...")
  baci_raw <- map_dfr(YEARS, function(yr) {
    f <- file.path(BACI_DIR, paste0("BACI_HS92_Y", yr, "_V202601.csv"))
    if (!file.exists(f)) { message("  Missing: ", f); return(NULL) }
    read_csv(f, col_types = cols(t="i", i="c", j="c", k="c", v="d", q="d")) |>
      select(t, i, j, v) |>
      group_by(t, i, j) |>
      summarise(v = sum(v, na.rm = TRUE), .groups = "drop")
  })

  baci <- baci_raw |>
    left_join(baci_cc, by = c("i" = "numeric_code")) |> rename(iso3_exp = iso3) |>
    left_join(baci_cc, by = c("j" = "numeric_code")) |> rename(iso3_imp = iso3) |>
    filter(!is.na(iso3_exp), !is.na(iso3_imp)) |>
    rename(year = t, trade_value = v) |>
    select(year, iso3_exp, iso3_imp, trade_value)

  saveRDS(baci, baci_cache)
  message("BACI cached: ", baci_cache)
}

message("BACI: ", nrow(baci), " country-pair-year obs")

# =============================================================================
# 5. INTRA-REC TRADE SHARE AND INTENSITY
#    MRT: ECOWAS pairs for 1995-2000 only
#    TLS: PIF pairs from 2002 only
# =============================================================================
message("Computing intra-REC trade share...")

rec_pairs_static <- REC_MEMBERSHIP_STATIC |>
  inner_join(REC_MEMBERSHIP_STATIC, by = "rec", suffix = c("_i","_j")) |>
  filter(iso3_i != iso3_j) |>
  select(iso3_reporter = iso3_i, iso3_partner = iso3_j)

ecowas_members <- REC_MEMBERSHIP_STATIC |> filter(rec == "ECOWAS") |> pull(iso3)
rec_pairs_mrt <- bind_rows(
  expand_grid(year = 1995:2000, iso3_reporter = "MRT",          iso3_partner = ecowas_members),
  expand_grid(year = 1995:2000, iso3_reporter = ecowas_members, iso3_partner = "MRT")
)

pif_members_static <- REC_MEMBERSHIP_STATIC |> filter(rec == "PIF") |> pull(iso3)
rec_pairs_tls <- bind_rows(
  expand_grid(year = 2002:max(YEARS), iso3_reporter = "TLS",              iso3_partner = pif_members_static),
  expand_grid(year = 2002:max(YEARS), iso3_reporter = pif_members_static, iso3_partner = "TLS")
)

acp_total_exports <- baci |>
  filter(iso3_exp %in% ACP_ISO3) |>
  group_by(year, iso3 = iso3_exp) |>
  summarise(total_exports = sum(trade_value, na.rm = TRUE), .groups = "drop")

acp_total_imports <- baci |>
  filter(iso3_imp %in% ACP_ISO3) |>
  group_by(year, iso3 = iso3_imp) |>
  summarise(total_imports = sum(trade_value, na.rm = TRUE), .groups = "drop")

intra_exp_static <- baci |>
  inner_join(rec_pairs_static,
             by = c("iso3_exp" = "iso3_reporter", "iso3_imp" = "iso3_partner")) |>
  group_by(year, iso3 = iso3_exp) |>
  summarise(intra_exports = sum(trade_value, na.rm = TRUE), .groups = "drop")

intra_imp_static <- baci |>
  inner_join(rec_pairs_static,
             by = c("iso3_imp" = "iso3_reporter", "iso3_exp" = "iso3_partner")) |>
  group_by(year, iso3 = iso3_imp) |>
  summarise(intra_imports = sum(trade_value, na.rm = TRUE), .groups = "drop")

intra_exp_mrt <- baci |>
  inner_join(rec_pairs_mrt,
             by = c("year", "iso3_exp" = "iso3_reporter", "iso3_imp" = "iso3_partner")) |>
  filter(iso3_exp == "MRT") |>
  group_by(year, iso3 = iso3_exp) |>
  summarise(intra_exports = sum(trade_value, na.rm = TRUE), .groups = "drop")

intra_imp_mrt <- baci |>
  inner_join(rec_pairs_mrt,
             by = c("year", "iso3_imp" = "iso3_reporter", "iso3_exp" = "iso3_partner")) |>
  filter(iso3_imp == "MRT") |>
  group_by(year, iso3 = iso3_imp) |>
  summarise(intra_imports = sum(trade_value, na.rm = TRUE), .groups = "drop")

intra_exp_tls <- baci |>
  inner_join(rec_pairs_tls,
             by = c("year", "iso3_exp" = "iso3_reporter", "iso3_imp" = "iso3_partner")) |>
  filter(iso3_exp == "TLS") |>
  group_by(year, iso3 = iso3_exp) |>
  summarise(intra_exports = sum(trade_value, na.rm = TRUE), .groups = "drop")

intra_imp_tls <- baci |>
  inner_join(rec_pairs_tls,
             by = c("year", "iso3_imp" = "iso3_reporter", "iso3_exp" = "iso3_partner")) |>
  filter(iso3_imp == "TLS") |>
  group_by(year, iso3 = iso3_imp) |>
  summarise(intra_imports = sum(trade_value, na.rm = TRUE), .groups = "drop")

intra_exp_all <- bind_rows(intra_exp_static, intra_exp_mrt, intra_exp_tls)
intra_imp_all <- bind_rows(intra_imp_static, intra_imp_mrt, intra_imp_tls)

world_totals <- baci |>
  group_by(year) |>
  summarise(world_trade = sum(trade_value, na.rm = TRUE), .groups = "drop")

acp_years <- expand_grid(iso3 = ACP_ISO3, year = YEARS)

intra_rec_share <- acp_years |>
  left_join(acp_total_exports, by = c("iso3","year")) |>
  left_join(acp_total_imports, by = c("iso3","year")) |>
  left_join(intra_exp_all,     by = c("iso3","year")) |>
  left_join(intra_imp_all,     by = c("iso3","year")) |>
  left_join(REC_LOOKUP,        by = c("iso3","year")) |>
  mutate(
    across(c(total_exports, total_imports, intra_exports, intra_imports),
           ~replace_na(.x, 0)),
    total_trade = total_exports + total_imports,
    intra_trade = intra_exports + intra_imports,
    it_share    = if_else(!is.na(rec) & total_trade > 0,
                          intra_trade / total_trade, NA_real_)
  )

rec_totals <- intra_rec_share |>
  filter(!is.na(rec)) |>
  group_by(rec, year) |>
  summarise(rec_total_trade = sum(total_trade, na.rm = TRUE), .groups = "drop")

intra_rec_share <- intra_rec_share |>
  left_join(world_totals, by = "year") |>
  left_join(rec_totals,   by = c("rec","year")) |>
  mutate(
    rec_world_share = if_else(world_trade > 0,
                              rec_total_trade / world_trade, NA_real_),
    it_intensity    = if_else(!is.na(rec_world_share) & rec_world_share > 0,
                              it_share / rec_world_share, NA_real_),
    rec             = factor(rec, levels = REC_LEVELS)
  ) |>
  select(iso3, year, rec, it_share, it_intensity, total_trade, intra_trade)

message("IT share computed: ", nrow(intra_rec_share), " ACP country-years")

# =============================================================================
# 6. EU-ACP BILATERAL TRADE
# =============================================================================
message("Extracting EU-ACP bilateral flows...")

eu_acp_trade <- baci |>
  filter(
    (iso3_exp %in% EU_ISO3 & iso3_imp %in% ACP_ISO3) |
    (iso3_exp %in% ACP_ISO3 & iso3_imp %in% EU_ISO3)
  ) |>
  mutate(
    eu_iso3   = if_else(iso3_exp %in% EU_ISO3,  iso3_exp, iso3_imp),
    acp_iso3  = if_else(iso3_exp %in% ACP_ISO3, iso3_exp, iso3_imp),
    direction = if_else(iso3_exp %in% EU_ISO3, "EU_to_ACP", "ACP_to_EU")
  ) |>
  group_by(year, eu_iso3, acp_iso3, direction) |>
  summarise(trade_value = sum(trade_value, na.rm = TRUE), .groups = "drop")

eu_acp_wide <- eu_acp_trade |>
  pivot_wider(names_from = direction, values_from = trade_value, values_fill = 0) |>
  mutate(total_bilateral = EU_to_ACP + ACP_to_EU)

dyad_grid <- expand_grid(year = YEARS, eu_iso3 = EU_ISO3, acp_iso3 = ACP_ISO3) |>
  left_join(EU_ENLARGEMENT, by = "eu_iso3") |>
  filter(is.na(eu_entry_year) | year >= eu_entry_year) |>
  select(-eu_entry_year)

eu_acp_panel <- dyad_grid |>
  left_join(eu_acp_wide, by = c("year","eu_iso3","acp_iso3")) |>
  mutate(across(c(EU_to_ACP, ACP_to_EU, total_bilateral), ~replace_na(.x, 0)))

message("EU-ACP panel: ", nrow(eu_acp_panel), " dyad-year obs")

# =============================================================================
# 7. CEPII GRAVITY — structural variables
# =============================================================================
message("Loading CEPII gravity...")

gravity_full <- readRDS(GRAVITY_FILE)

gravity_structural <- gravity_full |>
  select(iso3_o, iso3_d, year, distcap, comlang_off, contig, col_dep_ever) |>
  mutate(across(distcap, as.numeric),
         across(c(comlang_off, contig, col_dep_ever), as.integer)) |>
  rename(eu_iso3    = iso3_o,  acp_iso3 = iso3_d,
         distance   = distcap, lang     = comlang_off,
         contiguity = contig,  colonial = col_dep_ever) |>
  filter(eu_iso3 %in% EU_ISO3, acp_iso3 %in% ACP_ISO3, year %in% YEARS) |>
  group_by(eu_iso3, acp_iso3, year) |>
  arrange(desc(!is.na(distance))) |>
  slice(1) |>
  ungroup()

message("Gravity structural: ", nrow(gravity_structural), " records")

# =============================================================================
# 8. GDP AND POPULATION — WDI (COK/NIU manual patches; CEPII fallback)
# =============================================================================
# Note: CEPII Gravity V202211 GDP/pop covers only through 2020.
# WDI is the primary source for all panel years (1995-2021);
# CEPII is used only as a fallback if the WDI download fails.

wdi_cache <- paste0(DATA_DIR, "wdi_gdp_pop_cache_v3.rds")

# Cook Islands: GDP per capita (current USD) x population, 1995-2021
cok_gdp_pc <- c(6500,6527,6080,5471,6070,6307,6893,8107,11093,12916,
                13164,13480,14628,14108,13085,14184,15581,16952,16427,18221,
                17320,17878,20274,21855,22121,18116,18500)
cok_pop    <- c(19200,19200,19100,18900,18700,18600,18027,18200,18500,18900,
                19200,19342,19400,19400,19300,17800,17459,17600,17500,17400,
                17500,17434,17500,17500,17500,17500,17450)
stopifnot(length(cok_gdp_pc) == length(YEARS))
cok_data <- tibble(iso3 = "COK", year = YEARS,
                   gdp_wdi = cok_gdp_pc * cok_pop, pop_wdi = cok_pop)

# Niue: GDP per capita x population, 1995-2021
niu_gdp_pc <- c(2900,3100,3300,3100,3000,2800,3100,3400,3900,4800,
                5800,6100,7200,8100,8000,8500,10200,11200,12300,13500,
                13500,14500,15200,16200,16800,14900,15500)
niu_pop    <- c(2500,2300,2200,2100,2000,1900,1800,1700,1650,1600,
                1580,1560,1530,1520,1510,1500,1490,1480,1470,1470,
                1620,1620,1620,1620,1620,1620,1620)
stopifnot(length(niu_gdp_pc) == length(YEARS))
niu_data <- tibble(iso3 = "NIU", year = YEARS,
                   gdp_wdi = niu_gdp_pc * niu_pop, pop_wdi = niu_pop)

download_wdi <- function(cache_path, max_retries = 3) {
  for (attempt in 1:max_retries) {
    tryCatch({
      message("Attempt ", attempt, "/", max_retries, " to download WDI...")
      old_opts <- options(timeout = 300)
      on.exit(options(old_opts), add = TRUE)

      wdi_raw <- WDI(
        country   = "all",
        indicator = c(gdp_wdi = "NY.GDP.MKTP.CD", pop_wdi = "SP.POP.TOTL"),
        start = min(YEARS), end = max(YEARS),
        extra = TRUE
      )

      wdi_clean <- wdi_raw |>
        filter(region != "Aggregates", !is.na(iso3c)) |>
        select(iso3 = iso3c, year, gdp_wdi, pop_wdi)

      wdi_all <- bind_rows(wdi_clean, cok_data, niu_data) |>
        distinct(iso3, year, .keep_all = TRUE)

      saveRDS(wdi_all, cache_path)
      message("WDI cached: ", cache_path)
      return(wdi_all)
    }, error = function(e) {
      message("Attempt ", attempt, " failed: ", e$message)
      if (attempt < max_retries) Sys.sleep(5)
    })
  }
  return(NULL)
}

if (!file.exists(wdi_cache)) {
  message("WDI cache not found. Downloading...")
  wdi_all <- download_wdi(wdi_cache)
} else {
  message("WDI loaded from cache.")
  wdi_all <- readRDS(wdi_cache)
}

# CEPII fallback — only if WDI download failed; covers through 2020 only
if (is.null(wdi_all)) {
  warning("WDI download failed. Falling back to CEPII GDP/pop (coverage through 2020 only).")
  gravity_gdp_pop <- gravity_full |>
    select(iso3_o, iso3_d, year, gdp_o, gdp_d, pop_o, pop_d) |>
    mutate(across(c(gdp_o, gdp_d, pop_o, pop_d), as.numeric)) |>
    filter(iso3_o %in% EU_ISO3, iso3_d %in% ACP_ISO3, year %in% YEARS) |>
    rename(eu_iso3 = iso3_o, acp_iso3 = iso3_d,
           gdp_eu_cepii = gdp_o, gdp_acp_cepii = gdp_d,
           pop_eu_cepii = pop_o, pop_acp_cepii = pop_d) |>
    group_by(eu_iso3, acp_iso3, year) |>
    slice(1) |>
    ungroup()
  eu_gdp  <- gravity_gdp_pop |>
    select(iso3 = eu_iso3,  year, gdp_wdi = gdp_eu_cepii, pop_wdi = pop_eu_cepii) |>
    distinct(iso3, year, .keep_all = TRUE)
  acp_gdp <- gravity_gdp_pop |>
    select(iso3 = acp_iso3, year, gdp_wdi = gdp_acp_cepii, pop_wdi = pop_acp_cepii) |>
    distinct(iso3, year, .keep_all = TRUE)
  wdi_all <- bind_rows(eu_gdp, acp_gdp) |>
    distinct(iso3, year, .keep_all = TRUE) |>
    mutate(gdp_wdi = as.numeric(gdp_wdi), pop_wdi = as.numeric(pop_wdi))
  message("Using CEPII GDP/pop for ", nrow(wdi_all), " observations.")
}

wdi_all <- wdi_all |> distinct(iso3, year, .keep_all = TRUE)

# Coverage diagnostic — expected gaps: SOM (state collapse), ERI (post-2012), TLS (pre-2002)
wdi_acp_coverage <- wdi_all |>
  filter(iso3 %in% ACP_ISO3) |>
  group_by(iso3) |>
  summarise(n_gdp = sum(!is.na(gdp_wdi)), .groups = "drop") |>
  filter(n_gdp < length(YEARS))

if (nrow(wdi_acp_coverage) > 0) {
  message("ACP countries with incomplete GDP series (expected: SOM, ERI, TLS pre-2002):")
  print(wdi_acp_coverage)
  message("  Rows retained; gdp_acp = NA. PPML conditions on trade flows; OLS drops them.")
}

# =============================================================================
# 9. EPA TREATMENT
# =============================================================================
epa_panel <- expand_grid(acp_iso3 = ACP_ISO3, year = YEARS) |>
  left_join(EPA_DATES |> rename(acp_iso3 = iso3), by = "acp_iso3") |>
  mutate(
    epa       = if_else(!is.na(epa_date) &
                          year >= as.integer(format(epa_date, "%Y")), 1L, 0L),
    epa_years = if_else(epa == 1L,
                        year - as.integer(format(epa_date, "%Y")), NA_integer_)
  ) |>
  select(acp_iso3, year, epa, epa_years)

# =============================================================================
# 10. BUILD FINAL PANEL
# =============================================================================
message("Building final panel...")

panel <- eu_acp_panel |>
  left_join(gravity_structural, by = c("eu_iso3","acp_iso3","year")) |>
  left_join(wdi_all |> rename(acp_iso3 = iso3, gdp_acp = gdp_wdi, pop_acp = pop_wdi),
            by = c("acp_iso3","year")) |>
  left_join(wdi_all |> rename(eu_iso3  = iso3, gdp_eu  = gdp_wdi, pop_eu  = pop_wdi),
            by = c("eu_iso3","year")) |>
  left_join(epa_panel,                          by = c("acp_iso3","year")) |>
  left_join(intra_rec_share |> rename(acp_iso3 = iso3), by = c("acp_iso3","year")) |>
  mutate(
    pair_id       = paste(eu_iso3, acp_iso3, sep = "_"),
    ln_trade      = if_else(total_bilateral > 0, log(total_bilateral), NA_real_),
    ln_gdp_eu     = log(gdp_eu),
    ln_gdp_acp    = log(gdp_acp),
    ln_dist       = log(distance),
    exporter_year = paste(eu_iso3,  year, sep = "_"),
    importer_year = paste(acp_iso3, year, sep = "_"),
    tls_pre_indep = (acp_iso3 == "TLS" & year < 2002)
  )

message("Panel: ", nrow(panel), " obs | ",
        n_distinct(panel$pair_id), " dyads | ",
        n_distinct(panel$acp_iso3), " ACP | ",
        round(100 * mean(panel$total_bilateral == 0), 1), "% zero trade")

# =============================================================================
# 11. VALIDATION
# =============================================================================
stopifnot(n_distinct(panel$acp_iso3) == 78)
stopifnot(n_distinct(panel$eu_iso3)  <= 27)

# EPA integrity checks
stopifnot(panel |> filter(rec == "EAC")                         |> pull(epa) |> max() == 0)
stopifnot(panel |> filter(acp_iso3 == "HTI")                    |> pull(epa) |> max() == 0)
stopifnot(panel |> filter(acp_iso3 %in% c("MWI","ZMB"))         |> pull(epa) |> max() == 0)
message("EPA integrity checks passed (EAC, HTI, MWI, ZMB all epa = 0).")

# Duplicate check
dup_check <- panel |> count(eu_iso3, acp_iso3, year) |> filter(n > 1)
if (nrow(dup_check) > 0) {
  stop("DUPLICATES IN FINAL PANEL: ", nrow(dup_check), " eu-acp-year combos.")
}
message("No duplicates — panel is unique at eu x acp x year.")

# Missing data summary
panel |>
  summarise(
    pct_miss_it   = round(100 * mean(is.na(it_share)), 1),
    pct_miss_gdp  = round(100 * mean(is.na(gdp_acp)), 1),
    pct_miss_dist = round(100 * mean(is.na(distance)), 1),
    pct_zero      = round(100 * mean(total_bilateral == 0), 1),
    n             = n()
  ) |>
  print()

# =============================================================================
# 12. SUMMARY STATISTICS BY REC
# =============================================================================
rec_summary <- panel |>
  filter(!is.na(it_share), !is.na(rec)) |>
  distinct(acp_iso3, year, rec, it_share) |>
  group_by(rec) |>
  summarise(
    n_countries = n_distinct(acp_iso3),
    n_cy        = n(),
    mean_it     = round(mean(it_share, na.rm = TRUE), 4),
    sd_it       = round(sd(it_share,   na.rm = TRUE), 4),
    .groups     = "drop"
  ) |>
  arrange(desc(mean_it))

print(rec_summary)
write_csv(rec_summary, paste0(OUT_DIR, "tables/rec_it_share_summary.csv"))

# =============================================================================
# 13. SAVE
# =============================================================================
message("Saving panel...")
saveRDS(panel, paste0(DATA_DIR, "eu_acp_panel_v3.rds"))
write_csv(panel, paste0(DATA_DIR, "eu_acp_panel_v3.csv"))
message("Done. Panel saved as .rds and .csv.")

