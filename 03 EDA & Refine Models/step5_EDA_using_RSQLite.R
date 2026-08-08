install.packages("RSQLite")
library(RSQLite)

seoul_bikesharing_df <- read_csv("/Users/***/seoul_bike_sharing.csv")
cities_wf_df <- read_csv("/Users/***/data source/cities_weather_forecast.csv")
bikesharing_sys_df <- read_csv("/Users/***/bike_sharing_systems.csv")
world_cities_df <- read_csv("/Users/***/data source/world_cities.csv")

# Connection with SQLite database
conn <- dbConnect(RSQLite::SQLite(), "bike_sharing.db")

# Write 4 tables into SQLite
dbWriteTable(conn, "seoul_bikesharing", seoul_bikesharing_df, overwrite = TRUE)
dbWriteTable(conn, "cities_weather_forecast", cities_wf_df, overwrite = TRUE)
dbWriteTable(conn, "bike_sharing_systems", bikesharing_sys_df, overwrite = TRUE)
dbWriteTable(conn, "world_cities", world_cities_df, overwrite = TRUE)

# View the tables in the database
dbListTables(conn)

# Task1:
dbGetQuery(
  conn, 
  "SELECT COUNT(*) AS record_count 
  FROM seoul_bikesharing"
)

# Task2:
dbGetQuery(
  conn,
  "SELECT COUNT(*) AS operational_hours
  FROM seoul_bikesharing
  WHERE rented_bike_count != 0"
)

# Task3:
dbGetQuery(
  conn,
  "SELECT forecast_datetime AS weather_outlook
  FROM cities_weather_forecast
  WHERE city = 'Seoul'
  LIMIT 1"
)

# Task4:
dbGetQuery(
  conn,
  "SELECT DISTINCT seasons AS seasons
  FROM seoul_bikesharing"
)

# Task5:
summary(seoul_bikesharing_df$DATE)
# Change it to datetime format
dbGetQuery(
  conn,
  "SELECT MIN(
            CONCAT(SUBSTRING(date, 7,4), '-', SUBSTRING(date, 4,2), '-', SUBSTRING(date, 1,2))
            ) AS first_date,
          MAX(
            CONCAT(SUBSTRING(date, 7,4), '-', SUBSTRING(date, 4,2), '-', SUBSTRING(date, 1,2))
          ) AS last_date
  FROM seoul_bikesharing"
)

# Task6:
dbGetQuery(
  conn,
  "SELECT date, hour
  FROM seoul_bikesharing
  WHERE rented_bike_count = (SELECT MAX(rented_bike_count) 
                              FROM seoul_bikesharing)"
)

# Task7:
dbGetQuery(
  conn, 
  "SELECT seasons,
          AVG(temperature) AS hourly_temperature, 
          AVG(rented_bike_count) AS hourly_popularity
  FROM seoul_bikesharing
  GROUP BY seasons
  ORDER BY hourly_popularity DESC
  LIMIT 10"
)

# Task8:
dbGetQuery(
  conn,
  "SELECT seasons,
          AVG(rented_bike_count) AS hourly_bike_count,
          MIN(rented_bike_count) AS min_count,
          MAX(rented_bike_count) AS max_count,
          SQRT(AVG(rented_bike_count * rented_bike_count) - AVG(rented_bike_count) * AVG(rented_bike_count)) AS standard_deviation
  FROM seoul_bikesharing
  GROUP BY seasons"
)


# Task9: Weather Seasonality
dbGetQuery(
  conn,
  "SELECT seasons,
          AVG(rented_bike_count) AS avg_bike_cnt,
          AVG(temperature) AS avg_temp, 
          AVG(humidity) AS avg_hum, 
          AVG(wind_speed) AS avg_ws, 
          AVG(visibility) AS avg_vis, 
          AVG(dew_point_temperature) AS avg_dpt, 
          AVG(solar_radiation) AS avg_sr, 
          AVG(rainfall) AS avg_rainfall, 
          AVG(snowfall) AS avg_snowfall
  FROM seoul_bikesharing
  GROUP BY seasons
  ORDER BY avg_bike_cnt DESC
  "
)


# Task10:
dbGetQuery(
  conn, 
  "SELECT b.city, w.country, w.lat, w.lng, w.population, 
          SUM(bicycles) AS total_bikes
  FROM bike_sharing_systems b, world_cities w
  WHERE b.city = w.city_ascii
      AND b.city = 'Seoul'
  GROUP BY b.city, w.country, w.lat, w.lng, w.population
  "
)
# In SQL, implicit join -- "FROM table_x x,  table_y y" Then "WHERE x.~ = y.~"

# Task11:
dbGetQuery(
  conn,
  "SELECT b.city, b.country, CONCAT('(', w.lat, ',', w.lng, ')') AS coordinates,
          w.population, SUM(b.bicycles) AS total_bikes
  FROM bike_sharing_systems b
  JOIN world_cities w
    ON b.city = w.city_ascii
  GROUP BY b.city, b.country, coordinates,
          w.population
  HAVING total_bikes BETWEEN 15000 AND 20000
  "
)

# Finish connection
dbDisconnect(conn)







