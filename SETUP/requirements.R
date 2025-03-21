# R packages required for the traffic accidents analysis app

# Install required packages if not already installed
required_packages <- c(
  # Core packages
  "shiny",
  "shinydashboard",
  "tidyverse",
  "dplyr",
  "ggplot2",
  "DT",
  "tidyr",
  
  # Additional useful packages
  "plotly",        # For interactive plots
  "leaflet",       # For maps (if you plan to add map functionality)
  "shinyWidgets",  # For additional UI components
  "RColorBrewer",  # For color palettes
  "scales",        # For formatting numbers
  "lubridate"      # For date/time handling
)

# Function to install packages if not already installed
install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    install.packages(pkg, repos = "https://cran.rstudio.com/")
  }
}

# Install required packages
invisible(sapply(required_packages, install_if_missing))

# Print confirmation message
cat("All required packages installed.\n")