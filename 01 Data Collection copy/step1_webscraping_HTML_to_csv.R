# Webscraping for Data collection:

library(rvest)
library(readr)

url <- "https://en.wikipedia.org/wiki/List_of_bicycle-sharing_systems"
page <- read_html(url)

page

# Find all the tables in that webpage
table_nodes <- html_elements(page, "table")
# Check the number of tables
length(table_nodes)

# Export each table using a for-loop
for (i in seq_along(table_nodes)){
  
  # Convert HTML table to dataframe
  df <- html_table(table_nodes[[i]], fill = TRUE)
  
  # Print summary
  cat("\n========= Table", i, "=========\n")
  print(summary(df))
  
  # Export as CSV
  write_csv(
    df,
    paste0("/Users/shenkong/Desktop/个人简历/项目/Weather_Bike-sharing/01 Data Collection/01 HTML raw data/raw_bike_sharing_sys_", i, ".csv")
  )
}

# Find the table for data step2 -- data wrangling
bike_raw <- html_table(
  table_nodes[[1]],
  fill = TRUE
)
head(bike_raw)
colnames(bike_raw)

