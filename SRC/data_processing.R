# Load libraries one by one to ensure proper loading
if(!require(maps)) install.packages("maps")
library(readr)
library(dplyr)
library(tidyr)
library(ggplot2)
library(tidyverse)
library(maps)

set.seed(123)

#### Load and Clean Data ####
accidents <- read_csv("DATA/road_accident_dataset.csv")

# 1. Region Mapping
country_to_region <- data.frame(
  Country = c("USA", "UK", "Canada", "India", "China", "Japan", "Russia", "Brazil", "Germany", "Australia"),
  Region = c("North America", "Europe", "North America", "Asia", "Asia", "Asia", 
             "Asia", "South America", "Europe", "Oceania")
)

accidents <- accidents %>%
  select(-Region) %>%  
  left_join(country_to_region, by = "Country")

# 2. Accident Severity Calculation
accidents <- accidents %>%
  select(-'Accident Severity', everything()) %>%
  mutate(
    Total_Harm = `Number of Injuries` + 5 * `Number of Fatalities`,
    Accident_Severity = case_when(
      Total_Harm == 0 ~ "Minor",
      Total_Harm <= quantile(Total_Harm, 0.25, na.rm = TRUE) ~ "Moderate",
      Total_Harm <= quantile(Total_Harm, 0.50, na.rm = TRUE) ~ "Serious",
      Total_Harm <= quantile(Total_Harm, 0.75, na.rm = TRUE) ~ "Severe",
      TRUE ~ "Critical"
    )
  ) %>%
  select(-Total_Harm)

# 3. Speed Limits
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

accidents <- accidents %>%
  mutate(Full_Road_Type = paste(`Urban/Rural`, `Road Type`)) %>%
  left_join(speed_limits, by = c("Country", "Full_Road_Type")) %>%
  mutate(`Speed Limit` = Speed_Limit_kmh) %>%
  select(-Speed_Limit_kmh, -Full_Road_Type)

# 4. Population Density
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

accidents <- accidents %>%
  group_by(Country, `Urban/Rural`) %>%
  mutate(`Population Density` = runif(n(), 
         min = density_ranges[[Country]][[`Urban/Rural`]][1], 
         max = density_ranges[[Country]][[`Urban/Rural`]][2])) %>%
  ungroup()

#### Feature Engineering ####

# 1. Accident Severity Metrics
accidents <- accidents %>%
  mutate(
    Fatality_Rate = `Number of Fatalities` / (`Number of Injuries` + `Number of Fatalities`),
    Severity_Score = Fatality_Rate + (`Number of Injuries` / `Number of Vehicles Involved`),
    
    # External Conditions
    Bad_Weather_Impact = ifelse(`Weather Conditions` %in% c("Snowy", "Rainy", "Foggy"), 1, 0),
    Visibility_Score = 1 - (`Visibility Level` / max(`Visibility Level`, na.rm = TRUE)),
    
    # Road Conditions
    Road_Condition_Score = case_when(
      `Road Condition` == "Dry" ~ 0,
      `Road Condition` == "Wet" ~ 1,
      `Road Condition` == "Snow-covered" ~ 2,
      `Road Condition` == "Icy" ~ 3,
      TRUE ~ NA_real_
    ),
    
    # Composite Scores
    Road_Hazard_Score = 0.4 * Road_Condition_Score + 0.3 * Bad_Weather_Impact + 0.3 * `Speed Limit`,
    
    # Driver Demographics
    Age_Risk_Group = case_when(
      `Driver Age Group` %in% c("<18", "18-25") ~ "Young",
      `Driver Age Group` %in% c("26-40", "41-60") ~ "Middle-aged",
      `Driver Age Group` %in% c("61+") ~ "Senior",
      TRUE ~ NA_character_
    ),
    
    # Risk Factors
    DUI_Risk = ifelse(`Driver Alcohol Level` > mean(`Driver Alcohol Level`, na.rm = TRUE), 1, 0),
    Total_Accident_Cost = `Economic Loss` + `Medical Cost`,
    Emergency_Response_Efficiency = `Number of Fatalities` / `Emergency Response Time`,
    
    # Temporal Features
    Season = case_when(
      Month %in% c("December", "January", "February") ~ "Winter",
      Month %in% c("March", "April", "May") ~ "Spring",
      Month %in% c("June", "July", "August") ~ "Summer",
      Month %in% c("September", "October", "November") ~ "Fall",
      TRUE ~ NA_character_
    ),
    Weekend_Accident = ifelse(`Day of Week` %in% c("Saturday", "Sunday"), 1, 0),
    Urban_High_Risk_Zone = ifelse(`Urban/Rural` == "Urban" & 
                                 `Traffic Volume` > mean(`Traffic Volume`, na.rm = TRUE), 1, 0)
  )

#### Geographic Coordinates Generation ####
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
    # For USA, restrict to continental US
    if(country == "USA") {
      bounds <- bounds %>%
        filter(lat >= 25 & lat <= 50 & long >= -125 & long <= -65)
    }
    
    country_bounds[[country]] <- list(
      min_lat = min(bounds$lat),
      max_lat = max(bounds$lat),
      min_lon = min(bounds$long),
      max_lon = max(bounds$long)
    )
  } else {
    # Use fallback coordinates if country not found
    fallback <- fallback_coords %>% filter(country_name == country)
    if(nrow(fallback) > 0) {
      country_bounds[[country]] <- list(
        min_lat = fallback$lat - 5,
        max_lat = fallback$lat + 5,
        min_lon = fallback$lon - 5,
        max_lon = fallback$lon + 5
      )
    }
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

# Export processed dataset
save(accidents, file = "DATA/processed_accidents.Rdata")
write.csv(accidents, "DATA/accidents_final.csv", row.names = FALSE)

# Print summary
cat("Dataset processed and saved successfully!\n")
cat("Number of records:", nrow(accidents), "\n")
cat("Number of features:", ncol(accidents), "\n")