library(dplyr)
library(readr)

# EDA with plots
seoul_bikesharing_df <- read_csv("/Users/shenkong/Desktop/个人简历/项目/03 Weather_Bike-sharing/GitHub/03 EDA & Refine Models/data source/seoul_bike_sharing.csv")

# Standardize the dataset
summary(seoul_bikesharing_df$DATE)
seoul_bikesharing_df <- seoul_bikesharing_df %>% 
  mutate(DATE=as.Date(DATE, format = '%d/%m/%Y'))
# Convert HOUR into an ordered factor (categorical variable)
seoul_bikesharing_df <- seoul_bikesharing_df %>%
  mutate(HOUR=factor(HOUR,
                     levels = 0:23,
                     ordered=TRUE)
  )
class(seoul_bikesharing_df$HOUR)
# Check the structure of the dataframe
str(seoul_bikesharing_df)
# Check NAs
sum(is.na(seoul_bikesharing_df))
# Check the holiday percentage
unique(seoul_bikesharing_df$HOLIDAY)
num_holiday_cnt <- seoul_bikesharing_df %>% filter(HOLIDAY == "Holiday") %>% nrow()
holiday_pct <- paste0(
  round(num_holiday_cnt / nrow(seoul_bikesharing_df)* 100, 2),
  "%"
)
holiday_pct # = 4.82%

# Exactly one year of expected records
expected_records <- 365 * 24
expected_records
# Check the records of functioning days
unique(seoul_bikesharing_df$FUNCTIONING_DAY)
functioning_records <- seoul_bikesharing_df %>% filter(FUNCTIONING_DAY == "Yes") %>% nrow()
functioning_records
# Check the season column_names
unique(seoul_bikesharing_df$SEASONS)
# View seasonal total rainfall and snowfall
seasonal_weather <- seoul_bikesharing_df %>% group_by(SEASONS) %>% 
  summarise(total_rainfall=sum(RAINFALL, na.rm = TRUE), 
            total_snowfall=sum(SNOWFALL, na.rm = TRUE)
  )
seasonal_weather

# Start Data Visualization:
library(ggplot2)

# A scatter plot of rented_bike_count VS date
seoul_bikesharing_df %>% ggplot(aes(x=DATE, y=RENTED_BIKE_COUNT)) + 
  geom_point(alpha = 0.1) + 
  labs(title = "Rented Bike Count Over Time",
       x = "Date",
       y = "Rented bike count")

# Rented bike count vs date colored by HOUR 
seoul_bikesharing_df %>% ggplot(aes(DATE, RENTED_BIKE_COUNT, colour = HOUR)) +
  geom_point(alpha = 0.1) + 
  labs(title = "Rented Bike Count Over Time (Colored by Hour of Day)",
       x = "Date",
       y = "Rented bike count",
       colour = "Hour")

# A histogram overlaid with a kernel density curve
seoul_bikesharing_df %>% ggplot(aes(RENTED_BIKE_COUNT, y=after_stat(density))) +
  geom_histogram(colour = "black", fill = "white", bins = 15) +
  geom_density(colour = "red", alpha = 0.3) +
  labs(title = "Histogram of rented bike count with kernel density curve",
       x = "Rented Bike Count",
       y = "Density")

# Temp vs Rented_bike_cnt (by seasons)
seoul_bikesharing_df %>% ggplot(aes(TEMPERATURE, RENTED_BIKE_COUNT, color = HOUR)) + 
  geom_point(alpha = 0.2) +
  facet_wrap(~ SEASONS) + 
  labs(title = "Temperature vs Rented Bike Count by Season",
       x = "Temperature",
       y = "Rented bike count",
       color = "Hour")
# Sample size
seoul_bikesharing_df %>% group_by(SEASONS) %>% summarise(num_records = n()) # Not use nrow()

# Boxplots of HOUR vs Rented_bike_cnt by SEASONS
seoul_bikesharing_df %>% ggplot(aes(HOUR, RENTED_BIKE_COUNT)) + 
  geom_boxplot(colour = "steelblue", fill = "lightblue", 
               outlier.colour = "red") + 
  facet_wrap(~ SEASONS) + 
  labs(title = "Hour vs Rented Bike Count by Season",
       x = "Hour",
       y = "Rented bike count")

# Check daily rainfall and snowfall
seoul_bikesharing_df %>% group_by(DATE) %>% 
  summarise(daily_rf = sum(RAINFALL, na.rm = TRUE), 
            daily_sf = sum(SNOWFALL, na.rm = TRUE)
  )

# Check snowfall days
unique(seoul_bikesharing_df$SNOWFALL)
seoul_bikesharing_df %>% filter(SNOWFALL > 0) %>% 
  summarise(snowfall_days=n_distinct(DATE))

# min-max normalization
min_max <- function(x){
  (x - min(x, na.rm = TRUE)) / 
    (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

# Build a prediction model: Baseline LM
library(tidyverse)
library(tidymodels)
library(stringr)
url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/seoul_bike_sharing_converted_normalized.csv"
seoul_bikesharing_cn_df <- read_csv(url)

# Remove the useless cols
seoul_bikesharing_cn_df <- 
  seoul_bikesharing_cn_df %>% select(- DATE, - FUNCTIONING_DAY)

# Train/Test Split
set.seed(1) # To keep result fixed
data_split <- initial_split(seoul_bikesharing_cn_df, prop = 4/5) 
# 80% of data is training data, 20% of data is testing data
train_data <- training(data_split)
test_data <- testing(data_split)

# Build a model using weather variable only
lm_weather_model <- linear_reg(mode = "regression", engine = "lm")
# Fit the model
lm_weather_fit <- lm_weather_model %>% 
  fit(RENTED_BIKE_COUNT ~ TEMPERATURE + HUMIDITY + WIND_SPEED + VISIBILITY + DEW_POINT_TEMPERATURE + SOLAR_RADIATION + RAINFALL + SNOWFALL,
      data = train_data) 
lm_weather_fit
tidy(lm_weather_fit)

# A model using all variables
lm_all_model <- linear_reg() %>% set_engine("lm")
lm_all_fit <- lm_all_model %>% 
  fit(RENTED_BIKE_COUNT ~ ., # . means all the variables
      data = train_data)
tidy(lm_all_fit)

# Actual vs predicted bike-sharing count data frames
pred_weather <- predict(lm_weather_fit, new_data = test_data)$.pred
truth_weather <- test_data$RENTED_BIKE_COUNT
# Combine as a df
p_t_weather_df <- data.frame(estimate = pred_weather,
                             truth = truth_weather)
p_t_weather_df


pred_all <- predict(lm_all_fit, new_data = test_data)$.pred
truth_all <- test_data$RENTED_BIKE_COUNT
p_t_all_df <- data.frame(estimate = pred_all,
                         truth = truth_all)
p_t_all_df

# Test two models -- Using R-square and RMSE
rsq_weather <- rsq(p_t_weather_df, estimate = estimate, truth = truth)
rsq_all <- rsq(p_t_all_df, estimate = estimate, truth = truth)

rmse_weather <- rmse(p_t_weather_df, estimate = estimate, truth = truth)
rmse_all <- rmse(p_t_all_df, estimate = estimate, truth = truth)

comparison_tibble <- tibble(
  metric = c("rsq_weather", "rsq_all", "rmse_weather", "rmse_all"),
  value = c(rsq_weather$.estimate, rsq_all$.estimate, 
            rmse_weather$.estimate, rmse_all$.estimate)
)
comparison_tibble

# Feature Engineering -- Feature Importance
abs_coeff_list <- tidy(lm_all_fit) %>% 
  select(term, estimate) %>% 
  filter(!is.na(estimate)) %>%
  mutate(estimate = abs(estimate)) %>%
  arrange(desc(estimate))
abs_coeff_list
# Create a waterfall graph to visualize the list above
abs_coeff_waterfall <- abs_coeff_list %>% 
  ggplot(aes(estimate, reorder(term, estimate))) + 
  geom_bar(stat = "identity", fill = "mediumpurple") +
  labs(title = "Variable Importance (All Variables Model)",
       x = "Coefficient Estimate",
       y = "Variable")
abs_coeff_waterfall

glimpse(seoul_bikesharing_cn_df)

# Overview the relationship between temp vs rented_bike_count through a scatter plot
seoul_bikesharing_cn_df %>% 
  ggplot(aes(TEMPERATURE, RENTED_BIKE_COUNT)) +
  geom_point(alpha = 0.1)

# Plot the higher order polynomial fits
ggplot(data=train_data, aes(RAINFALL, RENTED_BIKE_COUNT)) + 
  geom_point(alpha = 0.1) + 
  geom_smooth(method = "lm", formula = y ~ x, color = "mediumpurple") +
  geom_smooth(method = "lm", formula = y ~ poly(x, 2), color = "pink") + 
  geom_smooth(method = "lm", formula = y ~ poly(x, 4), color = "yellowgreen") +
  geom_smooth(method = "lm", formula = y ~ poly(x, 6), color = "lightblue")

# Fit the model with higher order polynomial terms
library(yardstick)

results_list <- list()

for (d in 1:6) {
  # Use train_data to build a linear model
  model <- lm(RENTED_BIKE_COUNT ~ poly(RAINFALL, d), data = train_data)
  # Use test_data to test the results
  pred <- predict(model, newdata = test_data)
  results_list[[d]] <- tibble(
    degree = d,
    rmse = rmse_vec(test_data$RENTED_BIKE_COUNT, pred),
    rsq = rsq_vec(test_data$RENTED_BIKE_COUNT, pred)
  )
}

degree_results <- bind_rows(results_list)
degree_results

# Check the polynomial order of Rainfall/Humid/Dew_point_temp/18/19/Temp
po_rf <- 4
po_humi <- 2
po_dew_point_temp <- 3
po_temp <- 4

# Build a model with higher order polynomial terms on some important variables
lm_poly_model <- RENTED_BIKE_COUNT ~ . - 
  RAINFALL - HUMIDITY - DEW_POINT_TEMPERATURE - TEMPERATURE + 
  poly(RAINFALL, 4) + poly(HUMIDITY, 2) + 
  poly(DEW_POINT_TEMPERATURE, 3) + poly(TEMPERATURE, 4) 

# Use train_data to fit the model above
lm_poly_fit <- lm(lm_poly_model, data = train_data)

# Make prediction on test_data using poly model
pred_poly <- predict(lm_poly_fit, newdata = test_data)
truth_poly <- test_data$RENTED_BIKE_COUNT
# Convert all negative prediction results to zero, because we can not have negative rented bike counts
pred_poly[pred_poly < 0] <- 0

# Calculate R-squared and RMSE for the test results generated by ploy model
p_t_poly_df <- tibble(estimate = pred_poly,
                      truth = truth_poly)
p_t_poly_df

rsq_poly <- rsq(p_t_poly_df, estimate = estimate, truth = truth)
rmse_poly <- rmse(p_t_poly_df, estimate = estimate, truth = truth)

comparison2_tibble <- tibble(
  metric = c("rsq_all", "rsq_poly", "rmse_all", "rmse_poly"),
  value = c(rsq_all$.estimate, rsq_poly$.estimate, 
            rmse_all$.estimate, rmse_poly$.estimate)
)
comparison2_tibble


# Build a model with interaction terms on previous poly model
lm_pi_model <- RENTED_BIKE_COUNT ~ . - 
  RAINFALL - HUMIDITY - DEW_POINT_TEMPERATURE - TEMPERATURE + 
  poly(RAINFALL, 4) + poly(HUMIDITY, 2) + 
  poly(DEW_POINT_TEMPERATURE, 3) + poly(TEMPERATURE, 4) +
  RAINFALL:HUMIDITY + HUMIDITY:TEMPERATURE + TEMPERATURE:RAINFALL

# Use train_data to fit the model above
lm_pi_fit <- lm(lm_pi_model, data = train_data)
# Print the model summary
summary(lm_pi_fit)

# Make prediction on test_data using poly model
pred_pi <- predict(lm_pi_fit, newdata = test_data)
truth_pi <- test_data$RENTED_BIKE_COUNT
# Convert all negative prediction results to zero, because we can not have negative rented bike counts
pred_pi[pred_pi < 0] <- 0

# Calculate R-squared and RMSE for the test results generated by ploy model
p_t_pi_df <- tibble(estimate = pred_pi,
                    truth = truth_pi)
p_t_pi_df

rsq_pi <- rsq(p_t_pi_df, estimate = estimate, truth = truth)
rmse_pi <- rmse(p_t_pi_df, estimate = estimate, truth = truth)

comparison3_tibble <- tibble(
  metric = c("rsq_poly", "rsq_pi", "rmse_poly", "rmse_pi"),
  value = c(rsq_poly$.estimate, rsq_pi$.estimate, 
            rmse_poly$.estimate, rmse_pi$.estimate)
)
comparison3_tibble


# Transfer to a more advanced engine
library(glmnet)

lm_glmnet <- linear_reg(penalty = tune(),
                        mixture = tune()) %>% set_engine("glmnet")

# Find the best penalty-mixture combination
# Cross validation:
set.seed(12)
cv_folds <- vfold_cv(train_data, v = 5)
# Grid search:
glmnet_grid <- grid_regular(
  penalty(range = c(-4, 4)),
  mixture(range = c(0, 1)),
  levels = 5
)
tune_results <- tune_grid(
  lm_glmnet,
  preprocessor = lm_pi_model,
  resamples = cv_folds,
  grid = glmnet_grid,
  metrics = metric_set(rsq, rmse)
)
best_parameters <- select_best(tune_results, metric = "rmse")
cat("Best Parameters: \n")
best_parameters
# Lock the best parameters
lm_glmnet_best_spec <- finalize_model(lm_glmnet, best_parameters)

lm_glmnet_fit <- fit(lm_glmnet_best_spec, 
                     formula = lm_pi_model,
                     data = train_data)
summary(lm_glmnet_fit$fit)

pred_regu <- predict(lm_glmnet_fit, new_data = test_data)$.pred
truth_regu <- test_data$RENTED_BIKE_COUNT

p_t_regu_df <- tibble(estimate = pred_regu, truth = truth_regu)
p_t_regu_df

rsq_regu <- rsq(p_t_regu_df, estimate = estimate, truth = truth)
rmse_regu <- rmse(p_t_regu_df, estimate = estimate, truth = truth)

comparison4_tibble <- tibble(
  metric = c("rsq_pi", "rsq_regu", "rmse_pi", "rmse_regu"),
  value = c(rsq_pi$.estimate, rsq_regu$.estimate, 
            rmse_pi$.estimate, rmse_regu$.estimate)
)
comparison4_tibble
# Adding regularization would reduce the model performance

# Create a Q-Q plot generated by the best model 
# -- A model with interaction terms and polynomial terms
ggplot() +
  stat_qq(aes(sample=truth_poly), color = "yellowgreen") +
  stat_qq(aes(sample=pred_poly), color = "pink")




