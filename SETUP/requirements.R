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

# Check and install missing packages
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cran.rstudio.com/")
    cat(paste0("Installed package: ", pkg, "\n"))
  } else {
    cat(paste0("Package already installed: ", pkg, "\n"))
  }
}

# Load all required packages
invisible(lapply(required_packages, library, character.only = TRUE))

cat("\nAll required packages installed and loaded.\n")