https://scholar.google.com/citations?user=JsnqRNoAAAAJ&hl=en

## [Multilateral trade agreements in Africa](https://link.springer.com/article/10.1007/s10101-015-0167-8)

The argument of long-term economies of scale (or dynamic effects) also has some flaws. First of all, even if we were to unite all sub-Saharan markets, the combined GDP would still be small, especially given the size of the African continent. For instance, in 2009 the combined GDP of all sub-Saharan countries roughly equaled that of the state of New York. Secondly, to fully integrate a slew of problems would have to be conquered: different languages, currencies, rules and regulations, practically non-existent transnational transportation facilities, etc. Circumventing or breaking down these barriers to trade is extremely expensive in time, money and human capital (Foroutan and Pritchett [1993](https://link.springer.com/article/10.1007/s10101-015-0167-8#ref-CR11 "Foroutan F, Pritchett L (1993) Intra-sub-saharan african trade: is it too little? J Afr Econ 2(1):74–105")). In short, the cost of attaining the level of integration that is needed to produce economies of scale outweighs its benefits in the short and medium-long term.

To exacerbate the problem, the distribution of the benefits of bilateral trade liberalization is highly uneven. Most agreements are dominated by a _hegemon_: a country whose GDP is the multiple of that of other members, that is more industrialized, has higher tariff rates and often is the sole producer (Carrere [2004](https://link.springer.com/article/10.1007/s10101-015-0167-8#ref-CR6 "Carrere C (2004) African regional agreements: impact on trade with or without currency unions. J Afr Econ 13(2):199–239")). As a result, trade diversion will be high with most benefits accruing to the hegemon, leaving the smaller partner countries to pay for its increase in welfare. Furthermore, the location theory of Krugman and Venables ([1989](https://link.springer.com/article/10.1007/s10101-015-0167-8#ref-CR18 "Krugman P, Venables AJ (1989) Integration and the competitiveness of the peripheral industry. Centre for Economic Policy Research CEPR discussion paper 363")) predicts that removing barriers to trade in this setting will lead firms to relocate to the biggest market, especially when those barriers are taken down gradually. Combining distributional effects with the limited impact on trade and growth means that regional integration in Africa becomes a near zero-sum game. That these distributional problems are not without consequences, was all too clear in the East African Community (EAC) where they led to its dismantlement in 1977.


This dataset was used to create two dependent variables to be used in the unilateral and bilateral regressions. RIAuni_x,t indicates whether country _x_ signed an agreement in year _t_ or any of the previous 4 years. This indicator was constructed in 5 years intervals from 1885 to 2010, for a total of 318 observations. On average, 34 % of the countries signed an agreement within a 5 years interval, more or less equally divided over the 25 years of the sample.

RIAbi^b_a signals whether countries _a_ and _b_ are members of any of the listed agreements in the year 2010. Because the index is symmetrical, each country-couple is covered once giving us 53 x 53/2 = 1378 observations. Because of the plethora of African trade agreements, half of the countries-couples covered are members of the same agreement.

### **Results (detailed):**

- **Unilateral regressions (RIAuni_x,t):**
    
    - Countries with **higher corruption scores** were more likely to sign RIAs.
        
    - Economic size and GDP per capita had a weaker effect than corruption or geography.
        
    - Countries geographically closer to partners, sharing borders or in the same region, were more likely to participate.
        
    - Overall, **about 34% of countries** signed an agreement in any 5-year interval; this proportion was stable across time.
        
- **Bilateral regressions (RIAbi^b_a):**
    
    - Pairs of countries were more likely to be in the same agreement if:
        
        - They shared borders or were geographically close.
            
        - At least one country had a larger GDP (hegemon effect).
            
        - Corruption increased the likelihood, supporting the rent-seeking hypothesis.
            
    - Trade diversion effects are evident: **smaller or peripheral countries** often gain less or even pay costs for the welfare increase of the dominant partner.
        
    - The results reinforce the **zero-sum nature** of African RIAs under imperfect integration conditions.
        
- **Implications for African RIAs:**
    
    - Integration is **not automatically welfare-improving**.
        
    - Structural, geographic, and political factors strongly condition who benefits.
        
    - Rent-seeking behavior may explain why agreements persist even when economic benefits are limited.

**How this paper informs your project:**

1. **Control variables and mechanisms:**
    
    - Include **geography (distance, borders)** and **economic size (GDP)** in your regression, similar to how the African study controls for these in RIA participation.
        
    - Consider **institutional quality or corruption proxies** in ACP countries as determinants of willingness to integrate; rent-seeking might distort the expected linear relationship.
        
2. **Variable design:**
    
    - Use a **unilateral indicator**: whether an ACP country participates in an EU trade agreement or preferential arrangement (like EPA, Cotonou Agreement).
        
    - Use a **bilateral indicator**: EU-ACP country pairs to study trade flows, analogous to RIAbi^b_a.
        
    - Dependent variable: **trade flow magnitude** between EU and ACP country.
        
    - Independent variable: **openness to trade integration**, which could be a binary or index measure.
        
3. **Expected results / hypotheses:**
    
    - There may **not be a strict linear relationship** because trade benefits could be concentrated in larger ACP economies or certain sectors, similar to African RIAs where distribution is uneven.
        
    - Structural and political factors might **moderate the relationship**, so including covariates is essential.
        
4. **Potential methods:**
    
    - Replicate the regression framework:
        
        - **Unilateral regression** → ACP country decision to join EU integration measures.
            
        - **Bilateral regression** → Trade flows between EU and ACP country, conditional on membership in agreements.
            
    - Explore **interaction terms** between GDP or corruption and openness to test non-linear effects.

- **H1:** Trade flows between the EU and ACP countries **increase with openness to trade integration**
    
- **H2:** The relationship may **not be strictly linear** due to:
    
    - Economic size differences between ACP countries.
        
    - Sectoral concentration of trade.
        
    - Institutional or rent-seeking factors.
        
- **H3:** Geography and economic size **moderate** the effect of openness on trade flows.


### Dataset Construction

- **Unilateral indicator (Openness_x,t):**
    
    - ACP country _x_ participates in a trade agreement or preferential integration scheme in year _t_.
        
    - Could be binary (0 = not participating, 1 = participating) or an index of integration depth (e.g., tariff reduction coverage).
        
- **Bilateral indicator (TradePair^b_a):**
    
    - EU country _a_ and ACP country _b_ trade flows in year _t_.
        
    - Dependent variable: trade volume ($), could be logged to normalize.
        
    - Independent variable: bilateral openness or integration participation.
        
- **Covariates (from African RIA study analogues):**
    
    - **Geography:** distance, shared borders, regional clustering.
        
    - **Economic size:** GDP of ACP country, GDP of EU partner.
        
    - **Institutional quality:** corruption indices, governance indicators.
        
    - **Time dummies:** control for global trade trends.
        
- **Observation structure:**
    
    - Unilateral: ACP country × year.
        
    - Bilateral: EU country × ACP country × year.
        

---

### Regression Design

- **Unilateral regression (country-level openness):**
    
    `Openness_x,t = α + β1*GDP_x,t + β2*Corruption_x,t + β3*Distance_to_EU + ε_x,t`
    
    - Tests determinants of ACP countries’ participation in EU integration measures.
        
- **Bilateral regression (trade flows):**
    
    `TradeFlow_a,b,t = α + β1*Openness_b,t + β2*GDP_b,t + β3*GDP_a,t + β4*Distance_a,b + β5*Corruption_b,t + ε_a,b,t`
    
    - Tests whether trade flows **linearly respond** to ACP openness.
        
    - Can include **interaction terms** (e.g., Openness × GDP, Openness × Corruption) to capture potential non-linearities.
        
- **Expected results based on African RIA analogues:**
    
    - Trade flows may **increase with openness**, but the effect could be **concentrated in larger ACP countries**.
        
    - Corruption or weak governance may distort the expected linear relationship.
        
    - Distance and structural factors will likely remain strong predictors of trade intensity.
        

---

### Key Lessons from African RIA Study

- **Corruption increases likelihood of participation**, even when welfare gains are limited.
    
- **Geography and economic size dominate** as determinants of integration outcomes.
    
- **Distribution of benefits is uneven**; smaller countries often subsidize gains for larger members.
    
- **Integration can be zero-sum** without careful design (e.g., East African Community dismantlement in 1977).
    
- **Implication for EU-ACP:** Expect **heterogeneous effects** across ACP countries; linear assumptions should be tested.
    
### Visualization / Table Ideas

#### Scatterplot: Trade Flows vs Openness

|X-axis|Y-axis|Points|Color / Shape|
|---|---|---|---|
|Openness index (0–1) or binary (0/1)|Trade flow volume ($, logged)|Each ACP country in a given year|Optional: color by GDP size or region|

**Purpose:**

- See whether trade flows **increase linearly** with openness.
    
- Identify **outliers** (e.g., very open but low trade, or small GDP but high trade).
    
- Optional: add a **trend line** (linear or LOESS) to test linearity.
    

---

#### Interaction Scatterplot (Optional)

|X-axis|Y-axis|Color|Shape|
|---|---|---|---|
|Openness index|Trade flow|GDP category (high/low)|Corruption level (high/low)|

**Purpose:**

- Check for **heterogeneous effects**.
    
- E.g., small, highly corrupt countries may not see trade increases despite openness.
    

---

#### Table: Summary Statistics

|Variable|Mean|Std. Dev|Min|Max|Notes|
|---|---|---|---|---|---|
|Trade flow (log $)|…|…|…|…|EU-ACP bilateral trade|
|Openness index|…|…|0|1|ACP participation in agreements|
|GDP ACP|…|…|…|…|Country size|
|GDP EU|…|…|…|…|Partner size|
|Distance|…|…|…|…|Distance between EU-ACP pair|
|Corruption index|…|…|…|…|Institutional quality|

**Purpose:**

- Quick overview of **distribution of variables**.
    
- Helps identify data gaps or outliers.
    

---

### Suggested Figure Labels for Obsidian

`# Figure 1: EU-ACP Trade Flows vs ACP Openness # X-axis: Openness index (0–1) # Y-axis: Trade flow volume (log $) # Trend line: Linear regression or LOESS  # Figure 2 (optional): Interaction by GDP size # Points colored by GDP (high/low), shape by corruption (high/low)`

### Regression Design

- **Unilateral regression (country-level openness):**
Openness_x,t = α + β1*GDP_x,t + β2*Corruption_x,t + β3*Distance_to_EU + ε_x,t
- **Bilateral regression (trade flows):**
TradeFlow_a,b,t = α + β1*Openness_b,t + β2*GDP_b,t + β3*GDP_a,t + β4*Distance_a,b + β5*Corruption_b,t + ε_a,b,t


Figure 1: EU-ACP Trade Flows vs ACP Openness
X-axis: Openness index (0–1)
Y-axis: Trade flow volume (log $)
Trend line: Linear regression or LOESS
Figure 2 (optional): Interaction by GDP size
Points colored by GDP (high/low), shape by corruption (high/low)



## [Gravity, globalization and time-varying heterogeneity](https://www.sciencedirect.com/science/article/pii/S0014292124000084#section-cited-by)

## [Regional trade liberalisation](https://www.elgaronline.com/edcollchap-oa/book/9781800373747/book-part-9781800373747-10.xml)

## [Annual Bilateral Migration Data](https://data.mendeley.com/datasets/cpt3nh6jct/1)

## [Measuring Actual Economic Integration: A Bayesian State-Space Approach](https://link.springer.com/chapter/10.1007/978-3-319-50860-3_16)

scott baier