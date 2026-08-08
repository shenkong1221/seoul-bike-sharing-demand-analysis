library(dplyr)
seoul_bikesharing_df <- read_csv("/Users/***/Cleaned2_seoul_bike_sharing.csv")

# Create min-max normalization function
min_max <- function(x){
  (x - min(x, na.rm = TRUE)) / 
    (max(x, na.rm = TRUE) - min(x, na.rm = TRUE))
}

# Apply min-max function on the columns above
seoul_bikesharing_df <- seoul_bikesharing_df %>%
                    mutate(
                      RENTED_BIKE_COUNT=min_max(RENTED_BIKE_COUNT),
                      TEMPERATURE=min_max(TEMPERATURE), 
                      HUMIDITY=min_max(HUMIDITY), 
                      WIND_SPEED=min_max(WIND_SPEED), 
                      VISIBILITY=min_max(VISIBILITY), 
                      DEW_POINT_TEMPERATURE=min_max(DEW_POINT_TEMPERATURE),
                      SOLAR_RADIATION=min_max(SOLAR_RADIATION), 
                      RAINFALL=min_max(RAINFALL), 
                      SNOWFALL=min_max(SNOWFALL)
                    )
# Check the summary -- min=0 & max=1
summary(seoul_bikesharing_df)

write_csv(seoul_bikesharing_df,
          "/Users/***/Cleaned3_seoul_bike_sharing.csv")

# Standardize the column names again
# Iterately read and standardize all the colnames
dataset_list <- c('/Users/***/Cleaned_seoul_bike_sharing.csv', 
                  '/Users/***/Cleaned2_seoul_bike_sharing.csv',
                  '/Users/***/Cleaned3_seoul_bike_sharing.csv'
)

for (dataset_name in dataset_list){
  # Read dataset
  dataset <- read_csv(dataset_name)
  # Standardized its columns:
  # Convert all columns names to uppercase
  names(dataset) <- toupper(names(dataset))
  # Replace any white space separators by underscore, using str_replace_all function
  names(dataset) <- str_replace_all(names(dataset), " ", "_")
  # Save the dataset back
  write.csv(dataset, dataset_name, row.names=FALSE)
}


