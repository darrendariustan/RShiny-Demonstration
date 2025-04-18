# Clear environment first
rm(list = ls())

# Load required libraries
library(shiny)
library(shinydashboard)
library(leaflet)
library(leaflet.extras)
library(dplyr)
library(ggplot2)
library(plotly)
library(viridis)
library(heatmaply)
library(scales)
library(DT)
library(tidyr)

# Load data - try multiple paths to be able to run the app locally and in the container
data_paths <- c(
  "/data/processed_accidents.Rdata",
  "DATA/processed_accidents.RData",
  "data/processed_accidents.Rdata"
)

bounds_paths <- c(
  "/data/country_bounds.RData",
  "DATA/country_bounds.RData",
  "data/country_bounds.RData"
)

data_loaded <- FALSE
bounds_loaded <- FALSE

for (path in data_paths) {
  tryCatch({
    load(path)
    print(paste("Successfully loaded data from:", path))
    data_loaded <- TRUE
    break
  }, error = function(e) {
    print(paste("Failed to load from:", path))
  })
}

for (path in bounds_paths) {
  tryCatch({
    load(path)
    print(paste("Successfully loaded bounds from:", path))
    bounds_loaded <- TRUE
    break
  }, error = function(e) {
    print(paste("Failed to load bounds from:", path))
  })
}

if (!data_loaded) {
  stop("Could not load data from any of the expected locations. Please ensure the data file exists in one of the following paths: ", 
       paste(data_paths, collapse = ", "))
}

# Clean up country names and ensure consistent format
accidents <- accidents %>%
  mutate(Country = trimws(Country))  # Remove any whitespace

# Print data info for debugging
print("Data loaded. Checking contents:")
print(dim(accidents))
print("Countries in dataset:")
print(sort(unique(accidents$Country)))

# Define UI
ui <- dashboardPage(
  skin = "black",
  dashboardHeader(title = "Traffic Accidents 🚘"),
  dashboardSidebar(
    # Dark theme for sidebar and header
    tags$head(
      tags$style(HTML("
        /* Dark theme for header */
        .skin-blue .main-header .logo,
        .skin-blue .main-header .navbar {
          background-color: #2c3e50 !important;
        }
        .skin-blue .main-header .logo:hover {
          background-color: #2c3e50 !important;
        }
        
        /* Dark theme for sidebar */
        .skin-blue .main-sidebar {
          background-color: #2c3e50 !important;
        }
        .skin-blue .sidebar a {
          color: #ffffff !important;
        }
        .skin-blue .sidebar-menu > li.active > a,
        .skin-blue .sidebar-menu > li:hover > a {
          background-color: #34495e !important;
        }
        
        /* White theme for content */
        .content-wrapper, .right-side {
          background-color: #ffffff !important;
        }
        .box {
          background-color: #ffffff !important;
          box-shadow: 0 1px 3px rgba(0,0,0,0.12);
        }

        /* Box header styling */
        .box.box-primary {
          border-top-color: #2c3e50 !important;
        }
        .box-header {
          background-color: #2c3e50 !important;
          color: #ffffff !important;
        }
        .box-header .box-title {
          color: #ffffff !important;
        }
      "))
    ),
    
    # Inputs with cleaned country names
    selectInput("country", "Select Country:", 
                choices = c("All", sort(unique(trimws(accidents$Country)))),
                selected = "Germany"),
    
    sliderInput("year_range", "Select Year Range:",
                min = min(accidents$Year, na.rm = TRUE),
                max = max(accidents$Year, na.rm = TRUE),
                value = c(max(accidents$Year, na.rm = TRUE) - 6, max(accidents$Year, na.rm = TRUE)),
                step = 1,
                sep = ""),
    
    checkboxGroupInput("severity", "Accident Severity:", 
                choices = c("Minor", "Moderate", "Serious", "Severe", "Critical"),
                selected = c("Moderate","Severe", "Critical")),
    
    checkboxGroupInput("weather", "Weather Condition:", 
                choices = unique(accidents$`Weather Conditions`),
                selected = unique(accidents$`Weather Conditions`)[1:4])
  ),
  dashboardBody(
    # Main KPIs Row
    fluidRow(
      valueBoxOutput("severity_score_box", width = 3),
      valueBoxOutput("fatality_rate_box", width = 3),
      valueBoxOutput("response_time_box", width = 3),
      valueBoxOutput("economic_impact_box", width = 3)
    ),
    # Main visualization rows
    fluidRow(
      box(title = "Accidents Over Time", status = "primary", solidHeader = TRUE,
          plotlyOutput("accident_trends"), width = 12)
    ),
    fluidRow(
      box(title = "Accident Location Heatmap", status = "primary", solidHeader = TRUE,
          leafletOutput("accident_map"), width = 12, height = 500)
    ),
    fluidRow(
      box(title = "Risk Factor Correlation with Severity", status = "primary", solidHeader = TRUE,
          plotlyOutput("risk_correlation"), width = 12)
    )
  )
)

# Define server
server <- function(input, output, session) {
  # Initialize cache
  filtered_data_cache <- reactiveVal(NULL)
  
  # Modified filtered data to handle 'All' selection
  filtered_data <- reactive({
    req(input$severity, input$weather)
    
    data <- accidents
    
    # Print debugging information
    print(paste("Selected country:", input$country))
    print(paste("Unique countries in data:", paste(unique(data$Country), collapse=", ")))
    print(paste("Number of rows before filtering:", nrow(data)))
    
    # Only filter by country if not "All"
    if(input$country != "All") {
      # Make sure we're matching the exact country name
      data <- data %>% 
        filter(Country == !!input$country)  # Use exact matching with !!
      print(paste("Number of rows after country filtering:", nrow(data)))
    }
    
    filtered <- data %>%
      filter(Year >= input$year_range[1],
             Year <= input$year_range[2],
             Accident_Severity %in% input$severity,
             `Weather Conditions` %in% input$weather)
    
    print(paste("Final number of rows after all filtering:", nrow(filtered)))
    
    # Update cache
    filtered_data_cache(filtered)
    filtered
  })
  
  # Clear cache when inputs change
  observe({
    input$country
    input$year_range
    input$severity
    input$weather
    filtered_data_cache(NULL)
  })
  
  # Add country bounds data
  country_bounds <- list(
    USA = list(min_lat = 25, max_lat = 50, min_lon = -125, max_lon = -65),
    UK = list(min_lat = 50, max_lat = 59, min_lon = -8, max_lon = 2),
    Canada = list(min_lat = 42, max_lat = 83, min_lon = -141, max_lon = -52),
    India = list(min_lat = 8, max_lat = 37, min_lon = 68, max_lon = 97),
    China = list(min_lat = 18, max_lat = 53, min_lon = 73, max_lon = 135),
    Japan = list(min_lat = 24, max_lat = 46, min_lon = 123, max_lon = 146),
    Russia = list(min_lat = 41, max_lat = 82, min_lon = 19, max_lon = 180),
    Brazil = list(min_lat = -34, max_lat = 6, min_lon = -74, max_lon = -34),
    Germany = list(min_lat = 47, max_lat = 55, min_lon = 6, max_lon = 15),
    Australia = list(min_lat = -44, max_lat = -10, min_lon = 113, max_lon = 154)
  )
  
  # Update map view based on selected country
  observe({
    if(input$country != "All" && !is.null(country_bounds[[input$country]])) {
      bounds <- country_bounds[[input$country]]
      leafletProxy("accident_map") %>%
        fitBounds(bounds$min_lon, bounds$min_lat, bounds$max_lon, bounds$max_lat)
    }
  })
  
  # KPI Outputs
  output$severity_score_box <- renderValueBox({
    avg_severity <- mean(filtered_data()$Severity_Score, na.rm = TRUE)
    valueBox(
      formatC(avg_severity, format = "f", digits = 2),
      "Avg. Severity Score",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$fatality_rate_box <- renderValueBox({
    fatality_rate <- mean(filtered_data()$Fatality_Rate, na.rm = TRUE) * 100
    valueBox(
      paste0(formatC(fatality_rate, format = "f", digits = 2), "%"),
      "Avg. Fatality Rate",
      icon = icon("heartbeat"),
      color = "maroon"
    )
  })
  
  output$response_time_box <- renderValueBox({
    avg_response <- mean(filtered_data()$`Emergency Response Time`, na.rm = TRUE)
    valueBox(
      paste0(formatC(avg_response, format = "f", digits = 2), " min"),
      "Avg. Response Time",
      icon = icon("ambulance"),
      color = "blue"
    )
  })
  
  output$economic_impact_box <- renderValueBox({
    total_cost <- sum(filtered_data()$Total_Accident_Cost, na.rm = TRUE)
    valueBox(
      dollar(total_cost),
      "Economic Impact",
      icon = icon("dollar-sign"),
      color = "green"
    )
  })
  
  # Accidents over time plot
  output$accident_trends <- renderPlotly({
    yearly_data <- filtered_data() %>%
      group_by(Year, Accident_Severity) %>%
      summarise(
        Count = n(),
        .groups = 'drop'
      ) %>%
      # Ensure Accident_Severity is a factor with the correct order
      mutate(Accident_Severity = factor(
        Accident_Severity,
        levels = c("Minor", "Moderate", "Serious", "Severe", "Critical")
      ))
    
    # Calculate overall yearly severity for the line
    yearly_severity <- filtered_data() %>%
      group_by(Year) %>%
      summarise(
        Avg_Severity = mean(Severity_Score, na.rm = TRUE),
        .groups = 'drop'
      )
    
    # Define fixed colors for severity levels with better visibility
    severity_colors <- c(
      "Minor" = "#91bfdb",      # Blue
      "Moderate" = "#4575b4",   # Darker blue
      "Serious" = "#fee090",    # Yellow
      "Severe" = "#fc8d59",     # Orange
      "Critical" = "#d73027"    # Red
    )
    
    # Create the stacked bar chart with line
    plot_ly() %>%
      add_bars(
        data = yearly_data,
        x = ~Year,
        y = ~Count,
        color = ~Accident_Severity,
        colors = severity_colors,
        name = ~Accident_Severity,
        hovertemplate = paste(
          "Year: %{x}<br>",
          "Severity: %{data.name}<br>",
          "Count: %{y}<br>",
          "<extra></extra>"
        )
      ) %>%
      add_trace(
        data = yearly_severity,
        x = ~Year,
        y = ~Avg_Severity,
        name = "Avg. Severity Score",
        type = "scatter",
        mode = "lines+markers",
        yaxis = "y2",
        line = list(color = "#2c3e50", width = 3),
        marker = list(color = "#2c3e50", size = 8),
        hovertemplate = paste(
          "Year: %{x}<br>",
          "Avg. Severity Score: %{y:.2f}<br>",
          "<extra></extra>"
        )
      ) %>%
      layout(
        barmode = "stack",
        xaxis = list(
          title = "Year",
          tickmode = "linear"
        ),
        yaxis = list(
          title = "Number of Accidents",
          side = "left"
        ),
        yaxis2 = list(
          title = "Average Severity Score",
          side = "right",
          overlaying = "y",
          range = c(0, max(yearly_severity$Avg_Severity, na.rm = TRUE) * 1.1)
        ),
        legend = list(
          title = list(text = "Accident Severity"),
          orientation = "h",   # Make legend horizontal
          x = 0.5,            # Center horizontally
          y = -0.2,           # Move below the plot
          xanchor = "center", # Center the legend
          traceorder = "reversed"  # This will reverse the legend order to match the stacking
        ),
        hovermode = "x unified",
        plot_bgcolor = "#ffffff",
        paper_bgcolor = "#ffffff",
        margin = list(b = 100)  # Add bottom margin to make room for the legend
      )
  })
  
  # Map visualization
  output$accident_map <- renderLeaflet({
    map_data <- filtered_data()
    
    if(nrow(map_data) == 0) {
      return(
        leaflet() %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          setView(lng = 0, lat = 0, zoom = 2) %>%
          addControl("No data available for the selected filters", position = "topright")
      )
    }
    
    leaflet(map_data) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addHeatmap(
        lng = ~Longitude,
        lat = ~Latitude,
        intensity = ~Severity_Score,
        blur = 20,
        max = max(map_data$Severity_Score),
        radius = 15
      ) %>%
      addCircleMarkers(
        lng = ~Longitude,
        lat = ~Latitude,
        radius = 3,
        color = "white",
        weight = 1,
        opacity = 0.5,
        fillColor = ~colorNumeric("viridis", domain = Severity_Score)(Severity_Score),
        fillOpacity = 0.7,
        popup = ~paste(
          "Severity Score:", round(Severity_Score, 2), "<br>",
          "Accident Severity:", Accident_Severity, "<br>",
          "Weather:", `Weather Conditions`, "<br>",
          "Fatality Rate:", round(Fatality_Rate * 100, 2), "%"
        ),
        clusterOptions = markerClusterOptions(
          maxClusterRadius = 50,
          spiderfyOnMaxZoom = TRUE
        )
      ) %>%
      addLegend(
        position = "bottomright",
        pal = colorNumeric("viridis", domain = map_data$Severity_Score),
        values = ~Severity_Score,
        title = "Accident Severity",
        opacity = 0.8
      )
  })
  
  # Risk correlation plot
  output$risk_correlation <- renderPlotly({
    risk_factors <- c(
      "Driver Age Group", "Bad_Weather_Impact", "Visibility_Score",
      "Road_Condition_Score", "Driver Alcohol Level", "Speed Limit"
    )
    
    corr_data <- data.frame(
      Factor = risk_factors[risk_factors %in% names(filtered_data())],
      stringsAsFactors = FALSE
    )
    
    if(nrow(corr_data) == 0) {
      return(plot_ly() %>% layout(title = "No correlation data available"))
    }
    
    corr_data$Correlation <- sapply(corr_data$Factor, function(f) {
      if(is.numeric(filtered_data()[[f]])) {
        cor(filtered_data()[[f]], filtered_data()$Severity_Score, 
            use = "pairwise.complete.obs")
      } else {
        0  # Default for non-numeric variables
      }
    })
    
    corr_data <- corr_data[order(-abs(corr_data$Correlation)), ]
    colors <- ifelse(corr_data$Correlation >= 0, "#1f77b4", "#d62728")
    
    plot_ly(
      data = corr_data,
      y = ~Factor,
      x = ~Correlation,
      type = "bar",
      orientation = "h",
      marker = list(color = colors),
      text = ~paste0(round(Correlation * 100, 1), "%"),
      hoverinfo = "text"
    ) %>%
      layout(
        xaxis = list(
          title = "Correlation with Severity Score",
          range = c(-1, 1),
          zeroline = TRUE,
          zerolinecolor = '#969696',
          zerolinewidth = 1
        ),
        yaxis = list(title = ""),
        plot_bgcolor = "#ffffff",
        paper_bgcolor = "#ffffff"
      )
  })
}

# Run the app
shinyApp(ui, server)