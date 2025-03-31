# Clear environment first
rm(list = ls())

# Install required packages if not already installed
if (!require("shiny")) install.packages("shiny")
if (!require("shinydashboard")) install.packages("shinydashboard") 
if (!require("leaflet")) install.packages("leaflet")
if (!require("leaflet.extras")) install.packages("leaflet.extras")
if (!require("dplyr")) install.packages("dplyr")
if (!require("ggplot2")) install.packages("ggplot2")
if (!require("plotly")) install.packages("plotly")
if (!require("viridis")) install.packages("viridis")
if (!require("heatmaply")) install.packages("heatmaply")
if (!require("scales")) install.packages("scales")
if (!require("DT")) install.packages("DT")

# Load all required libraries
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

# Load data
load("DATA/processed_accidents.RData")

# Print data info for debugging
print("Data loaded. Checking contents:")
print(dim(accidents))
print("Countries in dataset:")
print(sort(unique(accidents$Country)))

# Define UI
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Road Safety Analytics"),
  dashboardSidebar(
    # Dark theme for sidebar
    tags$style(HTML("
      .main-sidebar { background-color: #2c3e50 !important; }
      .main-header .logo { background-color: #2c3e50 !important; }
      .main-header .navbar { background-color: #2c3e50 !important; }
      .sidebar a { color: #ffffff !important; }
    ")),
    
    # Inputs
    selectInput("country", "Select Country:", 
                choices = sort(unique(accidents$Country)),
                selected = "USA"),
    
    sliderInput("year_range", "Select Year Range:",
                min = min(accidents$Year, na.rm = TRUE),
                max = max(accidents$Year, na.rm = TRUE),
                value = c(min(accidents$Year, na.rm = TRUE), max(accidents$Year, na.rm = TRUE)),
                step = 1,
                sep = ""),
    
    checkboxGroupInput("severity", "Accident Severity:", 
                choices = unique(accidents$Accident_Severity),
                selected = unique(accidents$Accident_Severity)[1]),
    
    checkboxGroupInput("weather", "Weather Condition:", 
                choices = unique(accidents$`Weather Conditions`),
                selected = unique(accidents$`Weather Conditions`)[1])
  ),
  dashboardBody(
    # White background for main content
    tags$style(HTML("
      .content-wrapper, .right-side { background-color: #ffffff; }
      .box { background-color: #ffffff !important; }
    ")),
    
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
  # Debug output for countries
  output$debug_countries <- renderPrint({
    cat("Available countries:\n")
    print(unique(accidents$Country))
  })
  
  # Modified filtered data to handle 'All' selection
  filtered_data <- reactive({
    req(input$severity, input$weather)
    
    data <- accidents
    
    if(input$country != "All") {
      data <- data %>% filter(Country == input$country)
    }
    
    data %>%
      filter(Year >= input$year_range[1],
             Year <= input$year_range[2],
             Accident_Severity %in% input$severity,
             `Weather Conditions` %in% input$weather)
  })
  
  # Add country bounds data
  country_bounds <- list(
    USA = list(min_lat = 25, max_lat = 50, min_lon = -125, max_lon = -65),
    UK = list(min_lat = 50, max_lat = 59, min_lon = -8, max_lon = 2)
  )
  
  # KPI Outputs
  output$severity_score_box <- renderValueBox({
    avg_severity <- mean(filtered_data()$Severity_Score, na.rm = TRUE)
    valueBox(
      formatC(avg_severity, format = "f", digits = 2),
      "Severity Score",
      icon = icon("exclamation-triangle"),
      color = "red"
    )
  })
  
  output$fatality_rate_box <- renderValueBox({
    fatality_rate <- mean(filtered_data()$Fatality_Rate, na.rm = TRUE) * 100
    valueBox(
      paste0(formatC(fatality_rate, format = "f", digits = 2), "%"),
      "Fatality Rate",
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
      group_by(Year) %>%
      summarise(
        Count = n(),
        Fatality_Rate = mean(Fatality_Rate, na.rm = TRUE) * 100
      )
    
    plot_ly() %>%
      add_bars(
        data = yearly_data,
        x = ~Year,
        y = ~Count,
        name = "Number of Accidents",
        marker = list(color = "#1f77b4")
      ) %>%
      add_trace(
        data = yearly_data,
        x = ~Year,
        y = ~Fatality_Rate,
        name = "Fatality Rate (%)",
        type = "scatter",
        mode = "lines+markers",
        yaxis = "y2",
        line = list(color = "#e74c3c", width = 3),
        marker = list(color = "#e74c3c", size = 8)
      ) %>%
      layout(
        xaxis = list(title = "Year", tickmode = "linear"),
        yaxis = list(title = "Number of Accidents", side = "left"),
        yaxis2 = list(
          title = "Fatality Rate (%)",
          side = "right",
          overlaying = "y",
          range = c(0, max(yearly_data$Fatality_Rate, na.rm = TRUE) * 1.1)
        ),
        legend = list(x = 0.1, y = 1),
        hovermode = "x unified",
        plot_bgcolor = "#ffffff",
        paper_bgcolor = "#ffffff"
      )
  })
  
  # Map visualization
  output$accident_map <- renderLeaflet({
    map_data <- filtered_data()
    bounds <- country_bounds[[input$country]]
    
    if(nrow(map_data) == 0 || is.null(bounds)) {
      return(
        leaflet() %>%
          addProviderTiles(providers$CartoDB.Positron) %>%
          setView(lng = 0, lat = 0, zoom = 2) %>%
          addControl("No data available for the selected filters", position = "topright")
      )
    }
    
    leaflet(map_data) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      fitBounds(
        lng1 = bounds$min_lon,
        lat1 = bounds$min_lat,
        lng2 = bounds$max_lon,
        lat2 = bounds$max_lat
      ) %>%
      addCircleMarkers(
        lng = ~Longitude,
        lat = ~Latitude,
        radius = ~sqrt(Severity_Score) * 2,
        fillColor = ~colorNumeric("viridis", domain = Severity_Score)(Severity_Score),
        color = "white",
        weight = 1,
        opacity = 0.8,
        fillOpacity = 0.8,
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