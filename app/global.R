# global.R - Central communication hub for the entire app

# Load required libraries
library(shiny)
library(shinythemes)
library(shinyjs)
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
library(googleway)

# Load the GEOM90007 Tableau in Shiny library
# source('tableau-in-shiny-v1.2.R') @Jiujiu you need to make sure this file exists within one of the folders

# Google Maps API Key
GOOGLE_MAPS_API_KEY <- Sys.getenv("GOOGLE_MAPS_API_KEY")
if (GOOGLE_MAPS_API_KEY == "") {
  GOOGLE_MAPS_API_KEY <- "AIzaSyCJ6vbSvUKeJS22fXE8qtr43P219eceeio"
  warning("建議在 ~/.Renviron 設定 GOOGLE_MAPS_API_KEY")
}

# 路線顏色配置
MODE_COLORS <- c(
  driving = "#2ca02c",
  transit = "#1f77b4", 
  walking = "#ff7f0e",
  bicycling = "#9467bd"
)

# Melbourne CBD coordinates
MELBOURNE_CBD <- st_sfc(st_point(c(144.9631, -37.8136)), crs = 4326)

# 預設地點資料（墨爾本知名地點）
DEFAULT_PLACES <- data.frame(
  name = c(
    # Cafes
    "Degraves Espresso Bar",
    "Brother Baba Budan",
    "Market Lane Coffee",
    "Pellegrini's Espresso Bar",
    "Hopetoun Tea Rooms",
    "Seven Seeds Coffee",
    
    # Restaurants
    "Chin Chin Restaurant",
    "Cumulus Inc.",
    "Supernormal",
    "MoVida",
    "The European",
    
    # Parks
    "Fitzroy Gardens",
    "Carlton Gardens",
    "Alexandra Gardens",
    "Royal Botanic Gardens",
    "Flagstaff Gardens"
  ),
  type = c(
    rep("cafe", 6),
    rep("restaurant", 5),
    rep("park", 5)
  ),
  lat = c(
    # Cafes
    -37.8154, -37.8163, -37.8141, -37.8102, -37.8159, -37.8049,
    # Restaurants
    -37.8081, -37.8117, -37.8118, -37.8150, -37.8152,
    # Parks
    -37.8142, -37.8047, -37.8256, -37.8304, -37.8108
  ),
  lng = c(
    # Cafes
    144.9686, 144.9652, 144.9654, 144.9628, 144.9692, 144.9584,
    # Restaurants
    144.9646, 144.9658, 144.9674, 144.9654, 144.9688,
    # Parks
    144.9799, 144.9711, 144.9748, 144.9803, 144.9557
  ),
  icon = c(
    rep("☕", 6),
    rep("🍽️", 5),
    rep("🌳", 5)
  ),
  # 營業時間（24小時制）
  open_time = c(
    rep(7, 6),   # Cafes open at 7am
    rep(12, 5),  # Restaurants open at 12pm
    rep(6, 5)    # Parks open at 6am
  ),
  close_time = c(
    rep(17, 6),  # Cafes close at 5pm
    rep(23, 5),  # Restaurants close at 11pm
    rep(20, 5)   # Parks close at 8pm
  ),
  stringsAsFactors = FALSE
)


# Store data in non-reactive variables first
project_data_value <- NULL
preprocessed_data_value <- NULL
data_loaded_value <- TRUE

# Central reactive values for cross-tab communication
shared <- reactiveValues(
  navigate_to_tab = NULL,
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
      view_state = list(
        zoom = 13,
        center = c(-37.8136, 144.9631)
      ),
      start = NULL,
      end = NULL,
      picking = NULL
    ),
    summary = list(
      time_range = NULL,
      filters = list()
    )
  ),
  datasets = list(
    restaurants = NULL,
    weather_data = NULL,
    transport_data = NULL,
    preprocessed_data = preprocessed_data_value
  ),
  data_loaded = data_loaded_value
)

# Helper functions for cross-tab communication
get_restaurant_data <- function() {
  shared$datasets$restaurants
}

get_weather_data <- function() {
  shared$datasets$weather_data
}

get_transport_data <- function() {
  shared$datasets$transport_data
}
