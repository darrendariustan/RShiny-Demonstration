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
  "dplyr",
  "tidyr"
)

# Set CRAN repository
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Install all required packages
for (pkg in required_packages) {
  message("Checking package: ", pkg)
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing package: ", pkg)
    tryCatch({
      install.packages(pkg, quiet = TRUE)
      if (!requireNamespace(pkg, quietly = TRUE)) {
        stop(paste("Failed to install package:", pkg))
      }
    }, error = function(e) {
      message("Error installing ", pkg, ": ", e$message)
      stop(e)
    })
  } else {
    message("Package already installed: ", pkg)
  }
}

message("\nAll required packages installed successfully.\n")