## **Intro**

Regional trade agreements have long been studied using [[Gravity, globalization and time-varying heterogeneity]] to estimate their average trade effects. Seminal contributions by [[Jeffrey A. Frankel]] and [[Shang-Jin Wei]] framed regional integration as either a “building block” or “stumbling block” for global trade, while subsequent large-scale panel estimations by [[Andrew Rose]] quantified the trade-creating effects of regional trade agreements. More recent structural gravity approaches following [[Robert C. Feenstra]] emphasize consistent estimation under multilateral resistance.

Yet this literature largely treats regional agreements as binary institutional treatments. In particular, little attention has been paid to whether the trade effects of North–South agreements depend on the internal institutional depth of Southern partners.

This paper examines whether the trade effects of European Union preferential agreements with African, Caribbean, and Pacific (ACP) countries vary systematically with the depth of regional integration within ACP regional economic communities (RECs). Specifically, I test whether deeper South–South integration amplifies the trade response to EU Economic Partnership Agreements (EPAs).

For this study, I will draw on multiple international datasets to construct a panel of EU–ACP country-year observations capturing trade flows, foreign direct investment (FDI), and macroeconomic covariates. Bilateral trade in goods will primarily come from the IMF’s International Trade in Goods (IMTS) database, which reports partner-country trade values, and will be supplemented with CEPII’s BACI dataset for harmonized trade flows and bilateral gravity variables such as distance, contiguity, common language, and colonial ties. Bilateral trade in services will be explored using the BiTS dataset, while EU–ACP FDI stocks and positions will be drawn from the IMF’s Direct Investment Positions by Counterpart Economy (CDIS) and Portfolio Investment Positions (CPIS) datasets. Aggregate macroeconomic indicators, including GDP and population, will be obtained from the World Bank’s World Development Indicators. Additional trade and tariff information may be drawn from COMTRADE and WITS to validate the treatment effects of preferential access under the European Union Economic Partnership Agreements (EPAs).

While the data sources and coding methodology are defined, the final **time frame, list of ACP countries, and REC coverage** have not yet been finalized. These decisions will depend on the availability of consistent trade, FDI, and macroeconomic data across the relevant periods, as well as the timing of EPA implementation and the operational status of the various RECs. Once finalized, the panel will be structured to facilitate estimation using a PPML gravity framework, with exporter-year and importer-year fixed effects to control for country-specific and multilateral resistance factors, and will allow for the key interaction between EPA implementation and REC depth to assess whether the internal integration of ACP partners conditions the trade and investment effects of EU preferential agreements.

### Integration data

The first is **intra-REC trade share** — the UNU-CRIS formula you already have: (X_ii + M_ii) / (X_i. + M_i.). For each ACP country-year, this gives you the share of its total trade that flows to other REC members. It's continuous, it varies by country _and_ year, it requires no researcher judgment, and it's directly observable from BACI data. This is essentially what Standaert is implicitly measuring when he talks about de facto integration — countries that are actually integrated trade a lot with each other.

The second is **intra-REC trade intensity** — the second UNU-CRIS formula, which corrects the trade share for the REC's size relative to world trade. This is more sophisticated because a large REC will mechanically show high intra-regional shares even without deep integration.

Your research question is whether ACP countries that are more open to regional integration get more out of their EU EPA. If you use the trade share measure, you're testing exactly that — countries that actually trade with their neighbours, not just countries that signed a treaty saying they would. It also sidesteps the entire overlapping membership problem entirely, since the trade share is computed at the country level regardless of which REC it belongs to.

The one genuine concern is **endogeneity** — intra-REC trade share and EU-ACP trade flows might both be driven by a third factor (say, good institutions or low trade costs generally), so the interaction term EPA × IntraRECShare might be picking up something else. But this is manageable with your fixed effects structure, and it's a cleaner endogeneity problem to discuss than the measurement validity problem with the coding approach.

#### R application

Full R pipeline for constructing intra-REC trade share and gravity panel:

Each BACI file is a CSV for one year with columns for exporter (`i`), importer (`j`), product code (`k`), trade value (`v`), and quantity (`q`). [European Parliament](https://www.europarl.europa.eu/thinktank/en/document/EPRS_BRI\(2023\)757563) And importantly, BACI doesn't record zero trade flows [EU Trade](https://policy.trade.ec.europa.eu/development-and-sustainability/economic-partnerships_en) — which matters for how we handle zeros in the panel. Let me now write the full R pipeline.

**`01_build_panel.R` — Data pipeline**

The key section is Step 2, which constructs the intra-REC trade share directly from BACI using the UNU-CRIS formula from your own notes: `(intra-REC exports + imports) / (total exports + imports)`. It also computes IT Intensity, which adjusts for the REC's share of world trade. Everything gets merged into a single panel dataset at the EU-member × ACP-country × year level, with zeros explicitly included for country pairs that didn't trade in a given year — those zeros matter for PPML.

**`02_estimate_gravity.R` — Estimation**

Runs five models in sequence: baseline PPML without the openness variable, PPML with IT share alone, the main interaction specification (EPA × IT Share — this is your key coefficient), an IT Intensity robustness check, and an OLS comparison on log trade. At the bottom it computes the marginal effect of the EPA at different percentiles of IT share, which is a clean way to present your main result — something like "for countries at the median intra-REC trade share, having an EPA increases EU trade by X%, but for countries at the 75th percentile of openness the effect is Y%."

**Before you run it, you need three things downloaded:**

1. BACI HS07 from cepii.fr — pick HS2007 revision, download the full zip, point `BACI_DIR` at the folder
2. CEPII Gravity dataset (flat file version) from the same site — point `GRAVITY_FILE` at it
3. WDI pulls automatically via the `WDI` package — just run `install.packages("WDI")` if you don't have it
## **Data Sources and Methodological Approach for EU–ACP Trade & FDI Study**

### **1. Trade Data**

[IMF Datasets](https://data.imf.org/en/Datasets#t=coveo117bcfc4&sort=%40idata_publication_date%20descending)
[Global Trade Data. WTO](https://globaltradedata.wto.org/resource-library)
[OECD](https://data-explorer.oecd.org/?fs[0]=Topic%2C1%7CTrade%23TRD%23%7CTrade%20in%20goods%20and%20services%23TRD_GDS%23&pg=0&bp=true&snb=30)
[[UN Trade and Development (UNCTAD)]]
[[Global Trade Analysis Project]]


**a) [[IMF International Trade in Goods (IMTS)]]**

- **Coverage:** Bilateral trade in goods by partner country, nominal values.
    
- **Use:** Main dependent variable for EU imports from ACP countries.
    
- **Strength:** High-frequency bilateral detail; consistent with standard gravity analyses.
    
- **Considerations:** Some gaps in early years for small ACP states; may need interpolation or aggregation by regional partner.
    

**b) CEPII BACI / GeoDist / Gravity Datasets**
[DBNomics/CEPII](https://db.nomics.world/CEPII)
[CEPII Databases](https://www.cepii.fr/CEPII/en/bdd_modele/bdd_modele.asp)


- **Coverage:** Harmonized bilateral trade flows (HS6, SITC) from COMTRADE; includes distance, contiguity, colonial ties, language.
    
- **Use:** Covariates in gravity models; supports PPML estimation.
    
- **Strength:** Standardized, internationally cited, facilitates multilateral resistance term computation.
    

**c) [[Bilateral Trade in Services Research Dataset (BiTS)]]**

- **Coverage:** EU–ACP bilateral services trade.
    
- **Use:** Secondary dependent variable or robustness check.
    
- **Considerations:** Sparse for small Pacific/Caribbean ACP states; may aggregate by service categories.
    

**d) [[World Bank WITS]]**

- **Coverage:** Detailed trade flows and tariff schedules.
    
- **Use:** Preferential margin measurement, EPA treatment validation.
    
- **Strength:** Allows construction of actual preference margins (MFN – EPA applied tariff).
    

---

### **2. Investment & FDI Data**

**a) [[IMF Direct Investment Positions by Counterpart Economy (CDIS)]]**

- **Coverage:** Bilateral FDI stocks (positions) by reporting and partner country.
    
- **Use:** Secondary dependent variable; tests whether REC depth influences EU FDI in ACP.
    
- **Considerations:** Annual stocks rather than flows; may combine with flow data if needed.
    

**b) [[IMF Portfolio Investment Positions by Counterpart Economy (CPIS)]]**

- **Coverage:** EU holdings in ACP sovereign debt/equity.
    
- **Use:** Robustness check for financial integration; complements FDI analysis.
    

**c) [[Balance of Payments and International Investment Position Statistics (BOP/IIP)]]**

- **Coverage:** Aggregate external accounts.
    
- **Use:** Cross-check trade and FDI data; compute net investment positions, current account statistics.
    

---

### **3. Country- & REC-Level Covariates**

[Regional Trade Agreements Database](https://rtais.wto.org/UI/PublicAllRTAList.aspx)


**a) CEPII GeoDist / Gravity dataset**

- **Distance, contiguity, common language, colonial link** – standard gravity controls.
    

**b) World Bank World Development Indicators (WDI)**

- **GDP, population, macro indicators** – control for economic size and market potential.
    
- **Use:** Could supplement exporter/importer-year fixed effects or compute per capita controls.
    

**c) CEPII RTA / REC Typology Dataset**

- **Coverage:** Comprehensive coding of REC membership and integration depth.
    
- **Use:** Construct REC depth index (0–4), capturing legal and de facto institutional depth.
    

---

### **4. Methodological Approach for Data Selection**

1. **Define Unit of Analysis:**
    
    - Bilateral country-year (ACP country ↔ EU member).
        
    - Aggregate to EU if robustness check desired.
        
2. **Time Frame:**
    
    - Trade: 2000–2025 (pre/post EPA).
        
    - FDI: 2000–2025 (consistent with CDIS data).
        
3. **EPA Treatment Variable Construction:**
    
    - Dummy = 1 when EPA enters into force for the country or regional group, 0 before.
        
    - Preferential tariff margin (MFN – EPA) as robustness measure.
        
4. **REC Depth Index:**
    
    - 0–4 scale based on institutional depth (FTA, CU, CET, Common Market).
        
    - Handle overlapping memberships by coding **highest depth per country-year** or weighting.
        
5. **Gravity Covariates:**
    
    - Distance, contiguity, common language, colonial link.
        
    - Fixed effects: exporter-year + importer-year.
        
6. **Data Integration Steps for R:**
    
    - Merge IMF, CEPII, COMTRADE/WITS, and World Bank indicators by ISO country codes + year.
        
    - Ensure consistent units (USD, millions or thousands).
        
    - Create interaction variable: EPA×RECDepthEPA \times RECDepthEPA×RECDepth.
        
    - Construct panel for PPML estimation (trade levels) or log-differences (trade growth).

## **Other Literature**

[Saving, investment, and capital mobility among OECD countries](https://link.springer.com/article/10.1007/BF01886897)

**[[African Research]]**

[[Gravity, globalization and time-varying heterogeneity]]


