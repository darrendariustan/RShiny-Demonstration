# R packages required for the road accident analysis dashboard

# Define required packages
required_packages <- c(
  # Core Shiny packages
  "shiny",
  "shinydashboard",
  
  # Data visualization and interaction
  "ggplot2",
  "plotly",
  "DT",
  "leaflet",
  "leaflet.extras",
  "viridis",
  "heatmaply",
  "scales",
  
  # Data manipulation 
  "dplyr"
)

# First, install all missing packages
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing package: ", pkg)
    install.packages(pkg, repos = "https://cran.rstudio.com/")
  }
}

# Then, try to load all packages
for (pkg in required_packages) {
  message("Loading package: ", pkg)
  library(pkg, character.only = TRUE)
}

message("\nAll required packages installed and loaded successfully.\n")