
View [[Results]]
## EPAs
[Current ACP-EU trade arrangements](https://eur-lex.europa.eu/EN/legal-content/glossary/african-caribbean-and-pacific-acp-group-of-states.html) are based upon **economic partnership agreements**. These link the EU to ACP countries in seven regional groupings. With that being said, there is not complete overlap between the regional structure of the OACPS and existing EPAs.

CEPii BACI and Gravity .csv's used for both the "x" and "y" of the project--intra-regional trade intensity, and trade flows with the EU.

Samoa Agreement countries were split up into regions based on the status of their economic partnerships, rather than how OACPS is split up. * Mauritania is part of ECOWAS still? PIF excludes Timor-Leste, and DR Congo moves from Central Africa (not a CEMAC member) to SADC.


## Note on regions

**CARICOM** is not equal to **CARIFORUM (Caribbean) region** in that Cuba and Dominican Republic are not members of CARICOM but one caveat is that both Cuba and Dominican Republic have FTAs with CARICOM within CARICOM

**ECOWAS** is missing Mauritania from the OACPS **West Africa** grouping, who left ECOWAS in 2000.

**CEMAC** is missing DR Congo from within **Central Africa**, who happens to be in **SADC** and **EAC**.

**Eastern and Southern Africa** members are all part of **COMESA**, while Comoros, Madagascar, Mauritius, Seychelles, Zambia, Zimbabwe also belong to **SADC**.

**East African community** members are all part of **EAC**, while Tanzania also participates in **SADC** and **COMESA**.

**Southern African development community** members are all part of **SADC**.

**PIF** is missing Timor-Leste from the **Pacific region**.




EU_ACP panel was created with Script_01, making 77 rows per EU country, for each year from 1995-2020. Gravity was made using the CEPii database, looking at colonial history, language...to relate * how similar countries are to each other within regions, or how similar countries are to the EU? Assumably the former.



1. Loads BACI trade data (1995-2020)
2. Constructs an intra-REC trade share variable
3. Extracts EU-ACP bilateral trade flows
4. Loads CEPII gravity covariates
5. Creates EPA treatment variables
6. Merges everything into a final panel



## Methodology Slides

![[Erol_Assignment__6 Methology Slides.pdf]]

![[Erol_Assignment__6 Methology Slides.tex]]


