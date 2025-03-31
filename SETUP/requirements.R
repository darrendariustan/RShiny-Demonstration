# R packages required for the road accident analysis dashboard

# Set CRAN repository
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Define required packages (temporarily removing map packages)
required_packages <- c(
  "shiny",
  "shinydashboard",
  "ggplot2",
  "plotly",
  "DT",
  "viridis",
  "heatmaply",
  "scales",
  "dplyr",
  "tidyr"
)

# Install packages
for (pkg in required_packages) {
  message("Installing: ", pkg)
  install.packages(pkg)
}

message("Done installing packages")