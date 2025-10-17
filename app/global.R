# global.R - Central communication hub for the entire app

# Load required libraries
library(shiny)
library(shinythemes)
library(leaflet)
library(shinyWidgets)
library(shinydashboard) 
library(dplyr)
library(ggplot2)
library(sf)
library(here)
library(bslib)
library(sortable)
library(lubridate)
library(tidyr)
library(readr)
library(stringr)
library(later)
library('shinyjs')

# Load the GEOM90007 Tableau in Shiny library
source('tableau-in-shiny-v1.2.R')

# Load existing setup and data processing
# source(here::here("R", "setup.R"))
# source(here::here("R", "data_import.R"))
# source(here::here("R", "data_processing.R"))
# source(here::here("R", "functions.R"))

# Pre-processed data storage
# preprocessed_data <- new.env()

# Melbourne CBD coordinates
MELBOURNE_CBD <- st_sfc(st_point(c(144.9631, -37.8136)), crs = 4326)

# Store data in non-reactive variables first
project_data_value <- NULL
preprocessed_data_value <- NULL # preprocessed_data
data_loaded_value <- TRUE  # Set to TRUE since we're not loading data

# Load and process data - COMMENTED OUT
# message("Loading radius-based transport dataset...")
# raw_lines <- load_ptv_lines()
# raw_stops <- load_transport_stops()
# success <- process_transport_lines(raw_lines)
# project_data_value <- process_transport_stops(raw_stops)

# if (success && !is.null(project_data_value)) {
#   message("RADIUS-BASED transport dataset loaded successfully!")
#   data_loaded_value <- TRUE
#   
#   # Debugging info
#   train_count <- nrow(preprocessed_data_value$metro_train)
#   tram_count <- nrow(preprocessed_data_value$metro_tram)
#   bus_count <- nrow(preprocessed_data_value$metro_bus)
#   skybus_count <- nrow(preprocessed_data_value$skybus)
#   total_stops <- nrow(project_data_value)
#   
#   message("RADIUS-BASED DATASET SUMMARY:")
#   message("=======================================")
#   message("COVERAGE RADIUS:")
#   message("  🚆 Routes: 10km from Melbourne CBD")
#   message("  📍 Stops: 15km from Melbourne CBD")
#   message("")
#   message("ROUTES (within 10km radius):")
#   message("  - Metro Train: ", train_count, " routes")
#   message("  - Metro Tram: ", tram_count, " routes") 
#   message("  - Metro Bus: ", bus_count, " routes")
#   message("  - SkyBus: ", skybus_count, " routes")
#   message("")
#   message("STOPS (within 15km radius):")
#   message("  - Train stops: ", nrow(preprocessed_data_value$train_stops))
#   message("  - Tram stops: ", nrow(preprocessed_data_value$tram_stops))
#   message("  - Bus stops: ", nrow(preprocessed_data_value$bus_stops))
#   message("  - TOTAL: ", total_stops, " stops")
#   message("=======================================")
#   
# } else {
#   message("Radius-based data loading failed")
# }

# Central reactive values for cross-tab communication
shared <- reactiveValues(
  # Tab navigation
  navigate_to_tab = NULL,
  
  # Data selections (each tab can read/write)
  selections = list(
    wordcloud = list(
      selected_restaurant = NULL,
      selected_category = NULL
    ),
    weather = list(
      selected_date = NULL,
      selected_metric = "temperature"
    ),
    map = list(
      selected_location = NULL,
      view_state = list(zoom = 13, center = c(-37.8136, 144.9631))
    ),
    summary = list(
      time_range = NULL,
      filters = list()
    )
  ),
  
  # Shared datasets - populated from non-reactive variables
  datasets = list(
    restaurants = NULL,
    weather_data = NULL,
    transport_data = NULL,
    preprocessed_data = preprocessed_data_value,
    project_data = project_data_value
  ),
  
  # Cross-tab events (for triggering actions)
  events = reactiveValues(
    restaurant_selected = NULL,
    location_changed = NULL,
    date_range_updated = NULL,
    filters_applied = NULL
  ),
  
  # App state
  data_loaded = data_loaded_value,
  loading_message = "Data loading disabled for development"
)

# Helper functions for cross-tab communication
navigate_to_tab <- function(tab_name, session) {
  updateNavbarPage(session, "nav", selected = tab_name)
}

set_selection <- function(tab, key, value) {
  shared$selections[[tab]][[key]] <- value
}

get_selection <- function(tab, key) {
  shared$selections[[tab]][[key]]
}

trigger_event <- function(event_name, data = NULL) {
  shared$events[[event_name]] <- data
}

# Data access helpers
get_transport_data <- function() {
  if (shared$data_loaded) {
    return(shared$datasets$project_data)
  } else {
    return(NULL)
  }
}

get_preprocessed_data <- function() {
  if (shared$data_loaded) {
    return(shared$datasets$preprocessed_data)
  } else {
    return(NULL)
  }
}