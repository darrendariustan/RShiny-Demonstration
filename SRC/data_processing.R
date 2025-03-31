# Load libraries one by one to ensure proper loading
if(!require(maps)) install.packages("maps")
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(tidyverse)
library(maps)

set.seed(123)

#### Load the dataset
accidents <- read_csv("DATA/road_accident_dataset.csv")

# Cleaning the data
# 1. CORRECTING COUNTRY AND REGION
# Define the mapping of countries to regions
country_to_region <- data.frame(
  Country = c("USA", "UK", "Canada", "India", "China", "Japan", "Russia", "Brazil", "Germany", "Australia"),
  Region = c("North America", "Europe", "North America", "Asia", "Asia", "Asia", 
             "Asia", "South America", "Europe", "Oceania")
)

# Correct the Region column using left_join to avoid duplicate columns
accidents <- accidents %>%
  select(-Region) %>%  # Remove old Region column
  left_join(country_to_region, by = "Country")

#2. CORRECTING ACCIDENT SEVERITY (through number of injuries and fatalities)

# Remove the existing Accident_Severity column if it exists
accidents <- select(accidents, -'Accident Severity', everything())

# Calculate total impact per accident
accidents <- accidents %>%
  mutate(Total_Harm = `Number of Injuries` + 5 * `Number of Fatalities`)  # Weight fatalities more

# Define severity levels using quartiles
quartiles <- quantile(accidents$Total_Harm, probs = c(0.25, 0.50, 0.75), na.rm = TRUE)

accidents <- accidents %>%
  mutate(Accident_Severity = case_when(
    Total_Harm == 0 ~ "Minor",
    Total_Harm <= quartiles[1] ~ "Moderate",
    Total_Harm <= quartiles[2] ~ "Serious",
    Total_Harm <= quartiles[3] ~ "Severe",
    TRUE ~ "Critical")
    )

# Drop the Total_Harm column if no longer needed
accidents <- select(accidents, -c(Total_Harm, 'Accident Severity'))

#3.CORRECTING SPEED LIMITS (using Urban/Rural and Road Type) 
# Create Full_Road_Type by combining "Urban/Rural" and "Road Type"
accidents <- accidents %>%
  mutate(Full_Road_Type = paste(`Urban/Rural`, `Road Type`))

# Define speed limits based on country and road type
speed_limits <- data.frame(
  Country = rep(c("USA", "UK", "Canada", "India", "China", "Japan", "Russia", "Brazil", "Germany", "Australia"), each = 6),
  Full_Road_Type = rep(c("Urban Street", "Urban Main Road", "Urban Highway", 
                         "Rural Street", "Rural Main Road", "Rural Highway"), times = 10),
  Speed_Limit_kmh = c(
    48, 56, 89, 72, 89, 113,    # USA
    48, 64, 113, 97, 97, 113,   # UK
    50, 60, 100, 80, 100, 110,  # Canada
    50, 60, 80, 80, 100, 120,   # India
    50, 60, 100, 80, 100, 120,  # China
    40, 50, 80, 60, 80, 100,    # Japan
    60, 80, 110, 90, 110, 130,  # Russia
    40, 60, 80, 60, 80, 110,    # Brazil
    50, 60, 130, 100, 100, 130, # Germany
    50, 60, 100, 80, 100, 110   # Australia
  )
)

# Create Full_Road_Type in accidents
accidents <- accidents %>%
  mutate(Full_Road_Type = paste(`Urban/Rural`, `Road Type`))

# Merge speed limits into the dataset
accidents <- accidents %>%
  left_join(speed_limits, by = c("Country", "Full_Road_Type"))

# Update the Speed Limit column
accidents <- accidents %>%
  mutate(`Speed Limit` = Speed_Limit_kmh) %>%
  select(-Speed_Limit_kmh,-Full_Road_Type)  # Remove the temporary column


#4. POPULATION DENSITY

# Create lookup tables for min and max values by country and area type
density_ranges <- list(
  USA = list(Urban = c(1500, 5000), Rural = c(5, 200)),
  UK = list(Urban = c(3500, 6000), Rural = c(50, 500)),
  Canada = list(Urban = c(1000, 4000), Rural = c(1, 150)),
  India = list(Urban = c(8000, 30000), Rural = c(100, 2000)),
  China = list(Urban = c(4000, 25000), Rural = c(30, 1000)),
  Japan = list(Urban = c(6000, 15000), Rural = c(50, 800)),
  Russia = list(Urban = c(1500, 4000), Rural = c(1, 100)),
  Brazil = list(Urban = c(2000, 8000), Rural = c(5, 500)),
  Germany = list(Urban = c(3000, 7000), Rural = c(50, 700)),
  Australia = list(Urban = c(1000, 3500), Rural = c(1, 100))
)

# Generate the population density column in one vectorized operation
accidents <- accidents %>%
  group_by(Country, `Urban/Rural`) %>%
  mutate(`Population Density` = runif(n(), 
                                     min = density_ranges[[Country]][[`Urban/Rural`]][1], 
                                     max = density_ranges[[Country]][[`Urban/Rural`]][2])) %>%
  ungroup()

#### Feature Engineering

# 1. ACCIDENT SEVERITY
# Fatality Rate
accidents <- accidents %>%
  mutate(Fatality_Rate = `Number of Fatalities` / (`Number of Injuries` + `Number of Fatalities`))

# Severity Score 
accidents <- accidents %>%
  mutate(Severity_Score = Fatality_Rate + 
         (`Number of Injuries` / `Number of Vehicles Involved`))

# 2. EXTERNAL CONDITIONS
# Bad Weather Impact
accidents <- accidents %>%
  mutate(Bad_Weather_Impact = ifelse(`Weather Conditions` %in% c("Snowy", "Rainy", "Foggy"), 1, 0))

# Poor Visibility Score
max_visibility <- max(accidents$`Visibility Level`, na.rm = TRUE)
accidents <- accidents %>%
  mutate(Visibility_Score = 1 - (`Visibility Level` / max_visibility))

# ROAD HAZARDS
# Assign numerical scores to each road condition
road_condition_scores <- c("Dry" = 0, "Wet" = 1, "Snow-covered" = 2, "Icy" = 3)

# Add the numerical scores to the dataframe using a case_when statement
accidents <- accidents %>%
  mutate(Road_Condition_Score = case_when(
    `Road Condition` == "Dry" ~ 0,
    `Road Condition` == "Wet" ~ 1,
    `Road Condition` == "Snow-covered" ~ 2,
    `Road Condition` == "Icy" ~ 3,
    TRUE ~ NA_real_
  ))

# Calculate the Road Hazard Score
accidents <- accidents %>%
  mutate(Road_Hazard_Score = 0.4 * Road_Condition_Score + 0.3 * Bad_Weather_Impact + 0.3 * `Speed Limit`)

# 3. DRIVER BEHAVIOUR
# Age_Risk_Group
accidents <- accidents %>%
  mutate(Age_Risk_Group = case_when(
    `Driver Age Group` %in% c("<18", "18-25") ~ "Young",
    `Driver Age Group` %in% c("26-40", "41-60") ~ "Middle-aged",
    `Driver Age Group` %in% c("61+") ~ "Senior",
    TRUE ~ NA_character_
  ))

# DUI Risk
# Calculate the average Driver Alcohol Level
average_alcohol_level <- mean(accidents$`Driver Alcohol Level`, na.rm = TRUE)

# Use the average alcohol level as the threshold for DUI Risk feature
accidents <- accidents %>%
  mutate(DUI_Risk = ifelse(`Driver Alcohol Level` > average_alcohol_level, 1, 0))

# 4. ECONOMIC AND LOSS
# Total Accident Cost
accidents <- accidents %>%
  mutate(Total_Accident_Cost = `Economic Loss` + `Medical Cost`)

# Emergency Response Efficiency
accidents <- accidents %>%
  mutate(Emergency_Response_Efficiency = `Number of Fatalities` / `Emergency Response Time`)

# 5.TEMPORAL
# Season
accidents <- accidents %>%
  mutate(Season = case_when(
    Month %in% c("December", "January", "February") ~ "Winter",
    Month %in% c("March", "April", "May") ~ "Spring",
    Month %in% c("June", "July", "August") ~ "Summer",
    Month %in% c("September", "October", "November") ~ "Fall",
    TRUE ~ NA_character_
  ))

# Weekend Accident
accidents <- accidents %>%
  mutate(Weekend_Accident = ifelse(`Day of Week` %in% c("Saturday", "Sunday"), 1, 0))

# Urban Risk Zones
# Calculate the average traffic volume
average_traffic_volume <- mean(accidents$`Traffic Volume`, na.rm = TRUE)

accidents <- accidents %>%
  mutate(Urban_High_Risk_Zone = ifelse(`Urban/Rural` == "Urban" & `Traffic Volume` > average_traffic_volume, 1, 0))

# Print a confirmation message
cat("Dataset processed and saved successfully!\n")
cat("Number of records:", nrow(accidents), "\n")
cat("Number of features:", ncol(accidents), "\n")

# Get country boundaries
world_map <- map_data("world")

# Create country mapping
country_mapping <- c(
  "USA" = "USA", 
  "UK" = "UK", 
  "Canada" = "Canada", 
  "India" = "India", 
  "China" = "China", 
  "Japan" = "Japan", 
  "Russia" = "Russia",
  "Brazil" = "Brazil", 
  "Germany" = "Germany", 
  "Australia" = "Australia"
)

# Fallback coordinates for countries not found
fallback_coords <- tibble(
  country_name = c("USA", "UK", "Canada", "India", "China", "Japan", "Russia", "Brazil", "Germany", "Australia"),
  lat = c(39.8, 54.6, 56.1, 20.6, 35.9, 36.2, 61.5, -14.2, 51.1, -25.3),
  lon = c(-98.6, -3.4, -106.3, 79.0, 104.2, 138.3, 105.3, -51.9, 10.4, 133.8)
)

# First, find the bounding boxes for each country once
country_bounds <- list()
for (country in names(country_mapping)) {
  map_country <- country_mapping[country]
  bounds <- world_map %>% filter(region == map_country)
  
  if(nrow(bounds) > 0) {
    country_bounds[[country]] <- list(
      min_lat = min(bounds$lat),
      max_lat = max(bounds$lat),
      min_lon = min(bounds$long),
      max_lon = max(bounds$long)
    )
  }
}

# Process coordinates by group
accidents <- accidents %>%
  group_by(Country) %>%
  mutate(
    Latitude = case_when(
      Country %in% names(country_bounds) ~ runif(n(), 
                                               country_bounds[[first(Country)]]$min_lat, 
                                               country_bounds[[first(Country)]]$max_lat),
      TRUE ~ fallback_coords$lat[match(Country, fallback_coords$country_name)]
    ),
    Longitude = case_when(
      Country %in% names(country_bounds) ~ runif(n(), 
                                               country_bounds[[first(Country)]]$min_lon, 
                                               country_bounds[[first(Country)]]$max_lon),
      TRUE ~ fallback_coords$lon[match(Country, fallback_coords$country_name)]
    )
  ) %>%
  ungroup()

# Export the cleaned and feature-engineered dataset as an .Rdata file
save(accidents, file = "DATA/processed_accidents.Rdata")
write.csv(accidents, "DATA/accidents_final.csv", row.names = FALSE)