# R packages required for the road accident analysis dashboard

# Set CRAN repository
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Define required packages
required_packages <- c(
  "shiny",
  "shinydashboard",
  "ggplot2",
  "plotly",
  "DT",
  "leaflet",
  "leaflet.extras",
  "viridis",
  "heatmaply",
  "scales",
  "dplyr",
  "tidyr"
)

# Install packages with binary preference
for (pkg in required_packages) {
  message("Installing: ", pkg)
  install.packages(pkg, type = "binary", quiet = TRUE)
}

message("Done installing packages")