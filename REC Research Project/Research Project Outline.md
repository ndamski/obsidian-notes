## **Intro**

Regional trade agreements have long been studied using [[Gravity, globalization and time-varying heterogeneity]] to estimate their average trade effects. Seminal contributions by [[Jeffrey A. Frankel]] and [[Shang-Jin Wei]] framed regional integration as either a “building block” or “stumbling block” for global trade, while subsequent large-scale panel estimations by [[Andrew Rose]] quantified the trade-creating effects of regional trade agreements. More recent structural gravity approaches following [[Robert C. Feenstra]] emphasize consistent estimation under multilateral resistance.

Yet this literature largely treats regional agreements as binary institutional treatments. In particular, little attention has been paid to whether the trade effects of North–South agreements depend on the internal institutional depth of Southern partners.

This paper examines whether the trade effects of European Union preferential agreements with African, Caribbean, and Pacific (ACP) countries vary systematically with the depth of regional integration within ACP regional economic communities (RECs). Specifically, I test whether deeper South–South integration amplifies the trade response to EU Economic Partnership Agreements (EPAs).

I construct a continuous index of REC institutional depth and interact it with EPA implementation in a structural gravity framework estimated using PPML with exporter-year and importer-year fixed effects. The results speak directly to the building-block hypothesis by asking not whether regionalism increases trade on average, but whether internal integration conditions the effectiveness of external liberalization.

For this study, I will draw on multiple international datasets to construct a panel of EU–ACP country-year observations capturing trade flows, foreign direct investment (FDI), and macroeconomic covariates. Bilateral trade in goods will primarily come from the IMF’s International Trade in Goods (IMTS) database, which reports partner-country trade values, and will be supplemented with CEPII’s BACI dataset for harmonized trade flows and bilateral gravity variables such as distance, contiguity, common language, and colonial ties. Bilateral trade in services will be explored using the BiTS dataset, while EU–ACP FDI stocks and positions will be drawn from the IMF’s Direct Investment Positions by Counterpart Economy (CDIS) and Portfolio Investment Positions (CPIS) datasets. Aggregate macroeconomic indicators, including GDP and population, will be obtained from the World Bank’s World Development Indicators. Additional trade and tariff information may be drawn from COMTRADE and WITS to validate the treatment effects of preferential access under the European Union Economic Partnership Agreements (EPAs).

The construction of the main explanatory variables involves coding both the timing of EPA implementation and the depth of regional economic integration within ACP countries. EPA timing will be captured as a country- or regional-level dummy that switches on when a specific EPA enters into force, allowing for staggered treatment analysis. Regional Economic Community (REC) depth will be captured using a continuous institutional index, ranging from minimal integration (free trade agreements or partial scope arrangements) to deep integration (fully operational customs unions or common markets). Coding rules will address overlapping REC memberships by assigning the country-year observation the maximum integration depth, or using alternative weighting schemes where appropriate. Standard gravity covariates, including bilateral distance, contiguity, common language, and colonial ties, will be included to control for structural determinants of trade.

While the data sources and coding methodology are defined, the final **time frame, list of ACP countries, and REC coverage** have not yet been finalized. These decisions will depend on the availability of consistent trade, FDI, and macroeconomic data across the relevant periods, as well as the timing of EPA implementation and the operational status of the various RECs. Once finalized, the panel will be structured to facilitate estimation using a PPML gravity framework, with exporter-year and importer-year fixed effects to control for country-specific and multilateral resistance factors, and will allow for the key interaction between EPA implementation and REC depth to assess whether the internal integration of ACP partners conditions the trade and investment effects of EU preferential agreements.


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


