# Easily download the datasets:
url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/raw_bike_sharing_systems.csv"
download.file(url, destfile = "/Users/***/data source/raw_bike_sharing_systems.csv")
url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/raw_cities_weather_forecast.csv"
download.file(url, destfile = "/Users/***/raw_cities_weather_forecast.csv")
url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/raw_worldcities.csv"
download.file(url, destfile = "/Users/***/raw_worldcities.csv")
url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/raw_seoul_bike_sharing.csv"
download.file(url, destfile = "/Users/***/raw_seoul_bike_sharing.csv")


# Start Data Wrangling!!!!!!
library(tidyverse)

# 01 Standardize column_names:
# Call the local files in the Mac
dataset_lst <- c('/Users/***/raw_bike_sharing_systems.csv', 
                 '/Users/***/raw_seoul_bike_sharing.csv', 
                 '/Users/***/data source/raw_cities_weather_forecast.csv', 
                 '/Users/***/data source/raw_worldcities.csv')
for (dataset_name in dataset_lst){
  # Read each dataset
  dataset <- read_csv(dataset_name)
  # Standardize column names
  colnames(dataset) <- toupper(colnames(dataset))
  # Replace any white space separators by underscores
  colnames(dataset) <- str_replace_all(colnames(dataset), "\\s+", "_")
  
  # Save the dataset 
  write.csv(dataset, dataset_name, row.names=FALSE)

}
  
# Check the column_names
for (dataset_name in dataset_lst){
  # Read the file again
  dataset <- read_csv(dataset_name, show_col_types = FALSE)
  # Print the columns names
  cat("\n===================\n")
  cat("Checking Dataset:", dataset_name, "\n")
  cat("Column names:\n")
  print(colnames(dataset))
}

# 02 Standardize the values:
bike_sharing_df <- read_csv('/Users/***/raw_bike_sharing_systems.csv')
head(bike_sharing_df)
# Select the four columns
sub_bike_sharing_df <- bike_sharing_df %>% select(COUNTRY, CITY, SYSTEM, BICYCLES)
head(sub_bike_sharing_df)

# Check the types of each column
sub_bike_sharing_df %>% summary(class) 
tibble( # tibble = advanced df
  name=colnames(sub_bike_sharing_df),
  class=sapply(sub_bike_sharing_df, class) # sapply = simple apply
)

# Use grepl to search a string for non-digital characters
find_character <- function(strings) {
  grepl("[^0-9]", strings)
}

# Print the first 10 non-digital values in BICYCLES column
sub_bike_sharing_df %>% select(BICYCLES) %>% filter(find_character(BICYCLES)) %>% slice(0:10)

# Find all the reference links
# \\[ <==> [
reference_pattern <- "\\[[A-z0-9]+\\]"
find_ref_patt <- function(strings){
  grepl(reference_pattern, strings)
}
# Check
sub_bike_sharing_df %>% select(CITY) %>% filter(find_ref_patt(CITY)) %>% slice(0:10)
sub_bike_sharing_df %>% select(SYSTEM) %>% filter(find_ref_patt(SYSTEM)) %>% slice(0:10)

# Remove
remove_ref <- function(strings){
  reference_pattern <- "\\[[A-z0-9]+\\]"
  # Replace all matched substrings with a white space
  result <- str_replace_all(strings, reference_pattern, " ")
  # Trim result
  result <- str_trim(result)
  # return result
  return(result)
}

# Use the function above to remove
sub_bike_sharing_df %>% mutate(CITY=remove_ref(CITY), SYSTEM=remove_ref(SYSTEM))

# Check if all ref_patt are removed
sub_bike_sharing_df %>% select(CITY, SYSTEM) %>% filter(find_ref_patt(CITY) | find_ref_patt(SYSTEM))

# Extract the first digital substrings
extract_num <- function(columns){
  digital_pattern <- "[0-9]+"
  # Find the matching
  matched_str <- str_extract(columns, digital_pattern)
  # Convert to a numeric value
  result <- as.numeric(matched_str)
  return(result)
}

# Remove the matching
sub_bike_sharing_df <- sub_bike_sharing_df %>% mutate(BICYCLES=extract_num(BICYCLES))
# Check the descriptive statistics of the numeric BICYCLES column
summary(sub_bike_sharing_df$BICYCLES)
# Export as a csv file
write_csv(sub_bike_sharing_df, 
          "/Users/***/Cleaned_bike_sharing_systems.csv")





