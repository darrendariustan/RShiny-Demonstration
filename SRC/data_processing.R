## Script to pre-process accidents data and export to visualize in the dashboard

library(dplyr)

# Load the data
data <- read.csv("DATA/road_accident_dataset.csv")

# Pre-process the data
glimpse(data)

# Export the pre-processed data as rdata

save(data, file = "DATA/accidents_cleaned.RData")