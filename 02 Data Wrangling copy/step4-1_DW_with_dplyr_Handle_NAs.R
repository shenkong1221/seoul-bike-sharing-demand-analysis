library(tidyverse)

seoul_bikesharing_df <- read_csv("/Users/***/raw_seoul_bike_sharing.csv")

# Quick NA values
summary(seoul_bikesharing_df)
dim(seoul_bikesharing_df)
# Drop NAs
seoul_bikesharing_df <- seoul_bikesharing_df %>% drop_na(RENTED_BIKE_COUNT)

# Check the summary
summary(seoul_bikesharing_df)
dim(seoul_bikesharing_df)

# Handling NAs in TEMPERATURE column
# Check the missing values
summary(seoul_bikesharing_df$TEMPERATURE)
seoul_bikesharing_df %>% filter(is.na(TEMPERATURE))

# Calculate the average temperature in Summer
# Check the summer value
unique(seoul_bikesharing_df$SEASONS)
seoul_bikesharing_df %>% filter(SEASONS == "Summer") %>% summarise(total_summer_rows = n(), temp_na = sum(is.na(TEMPERATURE)))
# Calc the average value
avg_summer_temp <- seoul_bikesharing_df %>% filter(SEASONS == "Summer") %>% 
                    summarise(avg=mean(TEMPERATURE, , na.rm = TRUE)) %>% pull(avg)
# Without pull() avg_summer_temp is a tibble
avg_summer_temp
# Replace NAs with avg_summer_temp
seoul_bikesharing_df <- seoul_bikesharing_df %>% 
                        mutate(TEMPERATURE=replace_na(TEMPERATURE, avg_summer_temp))
# Check the Na rows again
summary(seoul_bikesharing_df$TEMPERATURE)

# Export as a CSV file
write_csv(seoul_bikesharing_df, 
          "/Users/***/Cleaned_seoul_bike_sharing.csv")
  
  
  
