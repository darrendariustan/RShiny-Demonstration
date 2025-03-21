# Shiny app to display the results of the traffic accident analysis

library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(DT)

# Load the data
data <- load("DATA/accidents_cleaned.RData")

# Define UI

ui <- dashboardPage(
  dashboardHeader(title = "Traffic Accidents Analysis"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Table", tabName = "data_table", icon = icon("table"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "dashboard",
              fluidRow(
                box(plotOutput("plot1", height = 250)),
                box(
                  title = "Number of Accidents by Month",
                  status = "primary",
                  solidHeader = TRUE,
                  collapsible = TRUE,
                  plotOutput("plot2")
                )
              )
      ),
      tabItem(tabName = "data_table",
              fluidRow(
                box(
                  title = "Data Table",
                  status = "primary",
                  solidHeader = TRUE,
                  collapsible = TRUE,
                  DT::dataTableOutput("table")
                )
              )
      )
    )
  )
)