# Seoul Bike-Sharing Demand Analysis

Predicting hourly bike-sharing demand in Seoul from weather and date/time features, using R (`tidyverse`, `tidymodels`, `glmnet`) for data collection, wrangling, exploratory data analysis, and iterative regression modeling.

## Project Overview

This project investigates how weather conditions and time-related factors (hour of day, season, holiday) drive hourly bike-rental demand in Seoul, and builds a series of increasingly sophisticated linear regression models to predict `RENTED_BIKE_COUNT`. The analysis moves from raw data collection through EDA-driven hypothesis generation to a final tuned model, benchmarking each modeling decision against R-squared and RMSE on a held-out test set.

**Goal:** Identify the strongest predictors of bike-sharing demand and build an interpretable, well-validated regression model that generalizes to unseen data.

## Data Source

- Weather and rental-count data collected via web scraping (HTML table parsing) and API requests, then exported to CSV.
- A cleaned, min-max normalized version of the dataset (used for modeling) is sourced from the [IBM Skills Network Seoul Bike Sharing dataset](https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/seoul_bike_sharing_converted_normalized.csv).
- ~1 year of hourly records, including weather variables (temperature, humidity, wind speed, visibility, dew point temperature, solar radiation, rainfall, snowfall) and date/time variables (hour, season, holiday, functioning day).

## Pipeline

### 1. Data Collection
- Retrieved weather and rental-demand data via HTTP requests to a public API, authenticated with an API key.
- Parsed the JSON response, stored fields in vectors, and exported the assembled dataset to CSV for downstream analysis.

### 2. Data Wrangling
Performed with `dplyr` and regular expressions to improve data quality:
- Detected and handled missing values — predictor variables were **min-max normalized** rather than dropped (`drop_na()` was reserved for the response variable only), since scaling all predictors to a comparable range prevents variables with naturally larger magnitudes from dominating the model and degrading accuracy.
- Converted `HOUR` into an ordered categorical factor (0–23) and `DATE` into proper date format.
- Standardized column names and created dummy variables for categorical predictors.

### 3. Exploratory Data Analysis
Combined **SQL queries (via `RSQLite`, `dbGetQuery()`)** with `ggplot2` visualizations to surface patterns in seasonality, weather sensitivity, and demand distribution.

**Key EDA findings:**
- Demand rises with temperature, but **temperature alone doesn't explain demand** — fall shows higher average demand than spring despite similar average temperatures, an early signal that other factors (comfort variables like solar radiation and dew point, or extreme-weather barriers like snowfall) also matter.
- Winter demand is **low and stable** (smallest standard deviation); summer demand is **high and volatile** (largest standard deviation and highest peaks).
- Rainfall correlates with demand but is not the dominant barrier — summer has both the highest rainfall total and the highest demand. **Snowfall is the stronger barrier**: heavy snowfall days coincide with sharply reduced usage, though the small sample (27 snow days/year) limits statistical confidence.
- A time-series scatter plot of demand vs. date confirms the seasonal pattern: low/stable demand in Jan–Mar, peak and highly dispersed demand in May–Aug, and elevated-but-declining demand in Sep–Nov.
- Coloring the same plot by hour of day reveals that daily demand rhythm (low overnight, peak 10am–7pm) **doesn't shift across seasons** — the annual peak is the product of summer *and* afternoon hours occurring together, not either factor alone.
- The distribution of `RENTED_BIKE_COUNT` is **right-skewed** (a floor effect at zero compresses the left tail): typical hourly demand sits around 200–300 rentals, with high-demand hours (summer afternoons) forming a thin, long tail.
- Faceting temperature vs. demand by season (colored by hour) shows demand concentrates in the 20–30°C range and falls off outside it — but the *same* temperature produces very different demand depending on season and hour (e.g., 0–5°C appears in both spring and winter, but winter demand stays low regardless). This reveals that **temperature and season are highly collinear** (each season maps to a narrow temperature band), and that **hour of day is a stronger driver than temperature alone** — peak demand requires summer *and* the evening commute window (5–7pm) simultaneously.
- Seasonal boxplots of hour vs. demand show consistent evening peaks (5–7pm) across all four seasons, likely commute-driven, along with season-specific outlier patterns (e.g., unusually low daytime values in fall, possibly linked to holiday travel).

**EDA conclusion:** The relationship between temperature and demand is positive but non-linear; hour of day is a strong independent driver; peak demand results from multiple conditions overlapping rather than any single variable; and temperature/season exhibit multicollinearity that must be accounted for in modeling.

### 4. Predictive Modeling
Built and iteratively refined a series of linear regression models using `tidymodels`, evaluating each on a held-out test set (80/20 split, `set.seed(1)` for reproducibility).

**Step 1 — Baseline models.** Compared a weather-only model against a full-variable model (weather + date/time). The full-variable model performed meaningfully better, confirming that date/time variables add real predictive value. Coefficient inspection (valid for direct comparison since all predictors are normalized to the same scale) identified `RAINFALL`, `HUMIDITY`, `DEW_POINT_TEMPERATURE`, and `TEMPERATURE` as the most influential predictors. (Note: `SOLAR_RADIATION` showed a counter-intuitive negative coefficient — a multicollinearity artifact, since `TEMPERATURE` absorbs most of solar radiation's explanatory power, not evidence that sunnier weather reduces demand.)

**Step 2 — Polynomial terms.** Added higher-order polynomial terms for the four most important variables to capture non-linear relationships, selecting the polynomial degree per variable (up to degree 6) based on the largest simultaneous RMSE decrease and R² increase on test data, while visually checking for overfitting (widening confidence bands at higher orders).

**Step 3 — Interaction terms.** Added pairwise interactions (`RAINFALL:HUMIDITY`, `HUMIDITY:TEMPERATURE`, `TEMPERATURE:RAINFALL`) to capture secondary effects between weather variables, improving both R² and RMSE further without overfitting.

**Step 4 — Regularization.** Attempted to control the growing model complexity by switching to a `glmnet` engine with penalty/mixture hyperparameters tuned via 5-fold cross-validation and grid search. This step **reduced test performance** rather than improving it — a useful negative result showing that more advanced techniques don't always outperform a well-specified linear model.

**Model comparison:**

| Model | R-squared | RMSE |
|---|---|---|
| Weather-only linear model | 0.425 | 493 |
| Full-variable linear model | 0.655 | 382 |
| + Interaction terms | 0.741 | 332 |
| **+ Polynomial terms (Best Model)** | **0.745** | **329** |
| + Regularization (glmnet) | 0.693 | 380 |

The best model — full variables with polynomial terms on rainfall, humidity, dew point temperature, and temperature, plus pairwise interaction terms — **explains 74.5% of the variance in hourly demand and cuts RMSE by ~33% relative to the weather-only baseline (493 → 329)**.

**Residual diagnostics.** A Q-Q plot comparing the best model's predictions against actual test-set values shows near-perfect alignment in the low-demand tail, slight overestimation in the mid-demand range, and a **systematic underestimation of peak (high-demand) hours** — indicating the model struggles most with the extreme summer-afternoon-commute demand spikes identified in the EDA.

## Key Takeaways

- **Hour of day is a stronger and more independent driver of demand than temperature.**
- **Temperature and season are collinear**, not independent predictors — modeling decisions need to account for this rather than treating each as an isolated effect.
- Peak demand is a **multiplicative, multi-condition phenomenon** (summer × afternoon commute), not explained by any single feature.
- Non-linear terms (polynomials) and pairwise interactions meaningfully improved predictive accuracy without overfitting; regularization did not.
- The final model's main weakness is **underestimating peak demand**, suggesting future work should focus on better capturing high-demand extremes (e.g., via non-linear models like random forests, or explicit peak-hour interaction terms).

## Tech Stack

- **Language:** R
- **Data wrangling:** `dplyr`, `stringr`, regular expressions
- **Modeling:** `tidymodels`, `glmnet`
- **Model evaluation:** `yardstick` (R², RMSE)
- **Database querying:** `RSQLite`
- **Visualization:** `ggplot2`

## Repository Structure

```
├── Seoul_Bike-sharing_Demand_Analysis.R   # Full analysis: EDA + modeling pipeline
├── data/                                   # Raw and cleaned datasets
├── outputs/                                # Exported plots and result tables
└── README.md
```

## Future Work

- Explore non-linear/ensemble models (e.g., random forest, gradient boosting) to better capture peak-demand extremes.
- Incorporate explicit hour × season interaction terms, given the identified multiplicative effect.
- Extend the snowfall-demand analysis with additional years of data to improve statistical confidence given the limited (27-day) sample.
