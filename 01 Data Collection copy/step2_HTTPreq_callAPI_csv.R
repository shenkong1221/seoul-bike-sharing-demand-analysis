# My generated API key: 5bef2e1d48e674dc8daeb58a2a43b2bd
# Use HTTP requests to call APIs and collect real-time data

library(httr)
# URL for current weather API
current_weather_url <- 'https://api.openweathermap.org/data/2.5/weather'
# Enter personal OpenWeather API key:
api_key <- "****5e374****afb12a2***"
# Hold URL parameters in a list
current_query <- list(q="Seoul", appid = api_key, units = "metric")
# Make a HTTP request to call API
response <- GET(current_weather_url, query = current_query)
# Check the response type (JSON format):
http_type(response)
# Read the JSON HTTP response
json_result <- content(response, as = "parsed")
class(json_result)
json_result

# Create enough empty vectors to hold data temporarily
city <- c()
weather <- c()
visibility <- c()
temp <- c()
temp_min <- c()
temp_max <- c()
pressure <- c()
humidity <- c()
wind_speed <- c()
wind_deg <- c()
forecast_datetime <- c()
season <- c()

# Assign the values in the json_result list into different vectors
get_weather_forecast_by_cities <- function(city_names){
  df <- data.frame()
  for (city_name in city_names){
  # Forcast API URL
  forecast_url <- 'https://api.openweathermap.org/data/2.5/forecast'
  # Create a list of URL parameters
  forecast_query <- list(q = city_name, appid = api_key, units = "metric")
  # Make a HTTP request to call API
  response <- GET(forecast_url, query = forecast_query)
  # Convert response into JSON list
  json_list <- content(response, as = "parsed")
  results <- json_list$list
  
  # Loop the json result
  for (result in results){
    # Add the values into the df
    city <- c(city, json_list$city$name)
    
    weather <- c(weather, result$weather[[1]]$main)
    visibility <- c(visibility, result$visibility)
    temp <- c(temp, result$main$temp)
    temp_min <- c(temp_min, result$main$temp_min)
    temp_max <- c(temp_max, result$main$temp_max)
    pressure <- c(pressure, result$main$pressure)
    humidity <- c(humidity, result$main$humidity)
    wind_speed <- c(wind_speed, result$wind$speed)
    wind_deg <- c(wind_deg, result$wind$deg)
    forecast_datetime <- c(forecast_datetime, result$dt_txt)
    season <- c(season, "Autumn") # Our current season
    }  
  }
  
  # Combine all vectors as columns
  df <- data.frame(city,
                   weather,
                   visibility,
                   temp,
                   temp_min,
                   temp_max,
                   pressure,
                   humidity,
                   wind_speed,
                   wind_deg,
                   forecast_datetime,
                   season)
  # Return the dataframe
  return(df)
}

# Complete and call that function with a list of cities
cities <- c("Seoul", "Washington, D.C.", "Paris", "Suzhou")
four_cities_weather_df <- get_weather_forecast_by_cities(cities)

# Export as a csv file
write.csv(four_cities_weather_df, "/Users/***/4_cities_weather_forecast.csv", row.names=FALSE)

# Download several datasets

# Download some general city information such as name and locations
url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/raw_worldcities.csv"
# download the file
download.file(url, destfile = "/Users/***/raw_worldcities.csv")

# Download a specific hourly Seoul bike sharing demand dataset
url <- "https://cf-courses-data.s3.us.cloud-object-storage.appdomain.cloud/IBMDeveloperSkillsNetwork-RP0321EN-SkillsNetwork/labs/datasets/raw_seoul_bike_sharing.csv"
# download the file
download.file(url, destfile = "/Users/***/raw_seoul_bike_sharing.csv")


