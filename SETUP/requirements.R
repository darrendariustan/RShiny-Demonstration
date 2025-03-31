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

# Function to install a package and its dependencies
install_package_with_deps <- function(pkg) {
  message("Checking package: ", pkg)
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message("Installing package: ", pkg)
    tryCatch({
      # Get package dependencies
      deps <- tools::package_dependencies(pkg, recursive = TRUE)
      if (!is.null(deps[[pkg]])) {
        message("Installing dependencies for ", pkg, ": ", paste(deps[[pkg]], collapse = ", "))
        install.packages(deps[[pkg]], quiet = TRUE)
      }
      
      # Install the package itself
      install.packages(pkg, quiet = TRUE)
      
      # Verify installation
      if (!requireNamespace(pkg, quietly = TRUE)) {
        stop(paste("Failed to install package:", pkg))
      }
      message("Successfully installed ", pkg)
    }, error = function(e) {
      message("Error installing ", pkg, ": ", e$message)
      stop(e)
    })
  } else {
    message("Package already installed: ", pkg)
  }
}

# Install packages in order
for (pkg in required_packages) {
  install_package_with_deps(pkg)
}

message("\nAll required packages installed successfully.\n")