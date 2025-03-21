# Shiny app to display the results of the traffic accident analysis

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(DT)
library(tidyr)

# Flexible data loading - checks multiple possible paths
tryCatch({
  # Try different paths
  data_file <- "DATA/road_accident_dataset.csv"
  if (!file.exists(data_file)) {
    data_file <- "../DATA/road_accident_dataset.csv"
  }
  if (!file.exists(data_file)) {
    data_file <- "/data/road_accident_dataset.csv"
  }
  
  data <- read.csv(data_file)
  print(paste("Successfully loaded data from:", data_file))
}, error = function(e) {
  print(paste("Error loading data:", e$message))
})

# Define UI
ui <- dashboardPage(
  dashboardHeader(title = "Traffic Accidents Analysis"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Map View", tabName = "map", icon = icon("map")),
      menuItem("Data Table", tabName = "data_table", icon = icon("table")),
      menuItem("About", tabName = "about", icon = icon("info-circle"))
    )
  ),
  dashboardBody(
    tabItems(
      # Dashboard Tab
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("total_accidents", width = 4),
                valueBoxOutput("avg_injuries", width = 4),
                valueBoxOutput("avg_fatalities", width = 4)
              ),
              fluidRow(
                box(title = "Accidents by Country", status = "primary", solidHeader = TRUE,
                    plotOutput("country_plot"), width = 6),
                box(title = "Accidents by Severity", status = "primary", solidHeader = TRUE,
                    plotOutput("severity_plot"), width = 6)
              ),
              fluidRow(
                box(title = "Accidents by Month", status = "primary", solidHeader = TRUE,
                    plotOutput("month_plot"), width = 6),
                box(title = "Accidents by Weather Condition", status = "primary", solidHeader = TRUE,
                    plotOutput("weather_plot"), width = 6)
              )
      ),
      
      # Map Tab
      tabItem(tabName = "map",
              fluidRow(
                box(title = "Geographic Distribution", status = "primary", solidHeader = TRUE,
                    "This would show a map if we had geo coordinates", width = 12)
              )
      ),
      
      # Data Table Tab
      tabItem(tabName = "data_table",
              fluidRow(
                box(title = "Data Table", status = "primary", solidHeader = TRUE,
                    DT::dataTableOutput("table"), width = 12)
              )
      ),
      
      # About Tab
      tabItem(tabName = "about",
              fluidRow(
                box(title = "About This Dashboard", status = "info", solidHeader = TRUE,
                    "This dashboard analyzes traffic accident data from multiple countries. It provides insights into accident patterns, severity, and contributing factors.",
                    width = 12)
              )
      )
    )
  )
)

server <- function(input, output) {
  # Summary statistics
  output$total_accidents <- renderValueBox({
    valueBox(
      nrow(data), "Total Accidents",
      icon = icon("car-crash"), color = "blue"
    )
  })
  
  output$avg_injuries <- renderValueBox({
    valueBox(
      round(mean(data$`Number.of.Injuries`), 1), "Avg Injuries per Accident",
      icon = icon("hospital"), color = "yellow"
    )
  })
  
  output$avg_fatalities <- renderValueBox({
    valueBox(
      round(mean(data$`Number.of.Fatalities`), 1), "Avg Fatalities per Accident",
      icon = icon("skull-crossbones"), color = "red"
    )
  })
  
  # Country plot
  output$country_plot <- renderPlot({
    data %>%
      count(Country) %>%
      ggplot(aes(x = reorder(Country, n), y = n, fill = Country)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(x = NULL, y = "Number of Accidents") +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Severity plot
  output$severity_plot <- renderPlot({
    data %>%
      count(`Accident.Severity`) %>%
      ggplot(aes(x = `Accident.Severity`, y = n, fill = `Accident.Severity`)) +
      geom_bar(stat = "identity") +
      labs(x = "Severity", y = "Number of Accidents") +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Month plot
  output$month_plot <- renderPlot({
    # Convert Month to factor with proper order
    month_levels <- c("January", "February", "March", "April", "May", "June", 
                      "July", "August", "September", "October", "November", "December")
    
    data %>%
      count(Month) %>%
      mutate(Month = factor(Month, levels = month_levels)) %>%
      ggplot(aes(x = Month, y = n, fill = Month)) +
      geom_bar(stat = "identity") +
      labs(x = NULL, y = "Number of Accidents") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            legend.position = "none")
  })
  
  # Weather plot
  output$weather_plot <- renderPlot({
    data %>%
      count(`Weather.Conditions`) %>%
      ggplot(aes(x = reorder(`Weather.Conditions`, n), y = n, fill = `Weather.Conditions`)) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(x = NULL, y = "Number of Accidents") +
      theme_minimal() +
      theme(legend.position = "none")
  })
  
  # Data table
  output$table <- DT::renderDataTable({
    DT::datatable(data, options = list(pageLength = 10, scrollX = TRUE))
  })
}

# Run the app
shinyApp(ui = ui, server = server)