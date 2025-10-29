# global.R - FIXED VERSION with detailed debugging
# 修复：正确处理缺失列，避免NA覆盖有效数据

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
library(googleway)
library(ggiraph)

source(here("app", "tableau-in-shiny-v1.2.R"))

# read and clean data in wordcloud
landmarks <- read.csv(here('data', 'landmarks.csv'), stringsAsFactors = FALSE)
cafe_restaurant <- read.csv(here('data', 'cafe_and_restaurant_2023.csv'), stringsAsFactors = FALSE)
barbecues <- read.csv(here('data', 'barbecues.csv'), stringsAsFactors = FALSE)

cat("\n=== BEFORE CLEANING ===\n")
cat("Landmarks columns:", paste(names(landmarks), collapse=", "), "\n")
cat("Cafe/Restaurant columns:", paste(names(cafe_restaurant), collapse=", "), "\n")
cat("Barbecues columns:", paste(names(barbecues), collapse=", "), "\n")

# Check if opening_time exists
cat("\nChecking for opening_time column:\n")
cat("Landmarks has 'opening_time':", "opening_time" %in% names(landmarks), "\n")
cat("Cafe/Restaurant has 'opening_time':", "opening_time" %in% names(cafe_restaurant), "\n")
cat("Barbecues has 'opening_time':", "opening_time" %in% names(barbecues), "\n")

# Sample data from cafe_restaurant BEFORE cleaning
if ("opening_time" %in% names(cafe_restaurant)) {
  cat("\nSample opening_time from cafe_restaurant (BEFORE cleaning):\n")
  print(head(cafe_restaurant$opening_time, 10))
}

clean_data <- function(df) {
  df %>%
    rename_with(~gsub('\\.', '_', .), everything()) %>%  # 先替换点号为下划线
    rename_with(~gsub('\\s+', '_', .), everything())      # 再替换空格为下划线
}

landmarks <- clean_data(landmarks)
cafe_restaurant <- clean_data(cafe_restaurant)
barbecues <- clean_data(barbecues)

cat("\n=== AFTER CLEANING ===\n")
cat("Landmarks columns:", paste(names(landmarks), collapse=", "), "\n")
cat("Cafe/Restaurant columns:", paste(names(cafe_restaurant), collapse=", "), "\n")
cat("Barbecues columns:", paste(names(barbecues), collapse=", "), "\n")

# Check again after cleaning
cat("\nChecking for opening_time column (AFTER cleaning):\n")
cat("Landmarks has 'opening_time':", "opening_time" %in% names(landmarks), "\n")
cat("Cafe/Restaurant has 'opening_time':", "opening_time" %in% names(cafe_restaurant), "\n")
cat("Barbecues has 'opening_time':", "opening_time" %in% names(barbecues), "\n")

# Sample data from cafe_restaurant AFTER cleaning
if ("opening_time" %in% names(cafe_restaurant)) {
  cat("\nSample opening_time from cafe_restaurant (AFTER cleaning):\n")
  print(head(cafe_restaurant$opening_time, 10))
  cat("Class:", class(cafe_restaurant$opening_time), "\n")
  cat("Non-NA count:", sum(!is.na(cafe_restaurant$opening_time)), "\n")
}

# merge data together (be tolerant of missing columns in individual CSVs)
canonical_cols <- c(
  "Name", "Latitude", "Longitude", "Theme", "Sub_Theme",
  "Google_Maps_Rating", "Business_address", "opening_time", "closing_time"
)

normalize_columns <- function(df, source_name = "unknown") {
  cat("\n📊 Normalizing:", source_name, "\n")
  cat("   Input rows:", nrow(df), "\n")
  cat("   Input columns:", paste(names(df), collapse=", "), "\n")
  
  # First select existing columns safely
  df_sel <- dplyr::select(df, any_of(canonical_cols))
  cat("   Selected columns:", paste(names(df_sel), collapse=", "), "\n")
  
  # Check opening_time BEFORE adding missing columns
  if ("opening_time" %in% names(df_sel)) {
    cat("   ✓ Has opening_time in selected:", sum(!is.na(df_sel$opening_time)), "non-NA values\n")
    cat("   Sample values:", paste(head(df_sel$opening_time, 5), collapse=", "), "\n")
  }
  
  # Add missing columns as NA to satisfy bind_rows
  missing_cols <- setdiff(canonical_cols, names(df_sel))
  if (length(missing_cols) > 0) {
    cat("   Missing columns (will add as NA):", paste(missing_cols, collapse=", "), "\n")
    for (col in missing_cols) {
      df_sel[[col]] <- NA_character_  # ⭐ 使用 NA_character_ 而不是 NA
    }
  }
  
  # Ensure expected types
  if ("Google_Maps_Rating" %in% names(df_sel)) {
    df_sel$Google_Maps_Rating <- as.character(df_sel$Google_Maps_Rating)
  } else {
    df_sel$Google_Maps_Rating <- NA_character_
  }
  if (!("Business_address" %in% names(df_sel))) {
    df_sel$Business_address <- NA_character_
  }
  
  # ⭐ IMPORTANT: Ensure opening_time and closing_time are character type
  if ("opening_time" %in% names(df_sel)) {
    df_sel$opening_time <- as.character(df_sel$opening_time)
  }
  if ("closing_time" %in% names(df_sel)) {
    df_sel$closing_time <- as.character(df_sel$closing_time)
  }
  
  # Check AFTER normalization
  if ("opening_time" %in% names(df_sel)) {
    cat("   ✓ After normalization - opening_time non-NA:", sum(!is.na(df_sel$opening_time) & df_sel$opening_time != "NA"), "\n")
  }
  
  cat("   Output rows:", nrow(df_sel), "\n")
  df_sel
}

cat("\n=== NORMALIZING DATA ===\n")
landmarks_norm <- normalize_columns(landmarks, "landmarks")
cafe_norm <- normalize_columns(cafe_restaurant, "cafe_restaurant")
barbecues_norm <- normalize_columns(barbecues, "barbecues")

cat("\n=== BEFORE BIND_ROWS ===\n")
cat("Cafe opening_time sample:\n")
print(head(cafe_norm$opening_time, 10))
cat("Class:", class(cafe_norm$opening_time), "\n")

theme_data <- bind_rows(
  landmarks_norm,
  cafe_norm,
  barbecues_norm
)

cat("\n=== AFTER BIND_ROWS ===\n")
cat("theme_data opening_time sample:\n")
print(head(theme_data$opening_time, 10))
cat("Class:", class(theme_data$opening_time), "\n")

theme_data <- theme_data %>%
  mutate(Google_Rating = suppressWarnings(as.numeric(Google_Maps_Rating)))

# Detailed statistics
cat("\n=== FINAL STATISTICS ===\n")
cat("✓ Loaded theme_data with", nrow(theme_data), "locations\n")

n_valid_opening <- sum(!is.na(theme_data$opening_time) & 
                         theme_data$opening_time != "NA" & 
                         nzchar(theme_data$opening_time))
n_valid_closing <- sum(!is.na(theme_data$closing_time) & 
                         theme_data$closing_time != "NA" & 
                         nzchar(theme_data$closing_time))
n_valid_both <- sum(!is.na(theme_data$opening_time) & 
                      !is.na(theme_data$closing_time) &
                      theme_data$opening_time != "NA" & 
                      theme_data$closing_time != "NA" &
                      nzchar(theme_data$opening_time) & 
                      nzchar(theme_data$closing_time))

cat("✓ With valid opening_time:", n_valid_opening, "\n")
cat("✓ With valid closing_time:", n_valid_closing, "\n")
cat("✓ With BOTH valid times:", n_valid_both, "\n")

# By Theme
cat("\n📊 By Theme:\n")
stats_by_theme <- theme_data %>%
  group_by(Theme) %>%
  summarise(
    total = n(),
    with_hours = sum(!is.na(opening_time) & !is.na(closing_time) &
                       opening_time != "NA" & closing_time != "NA" &
                       nzchar(opening_time) & nzchar(closing_time)),
    .groups = 'drop'
  )
print(stats_by_theme)

# Sample with valid hours
if (n_valid_both > 0) {
  cat("\n📋 Sample locations WITH hours:\n")
  sample_with <- theme_data %>%
    filter(!is.na(opening_time) & !is.na(closing_time) &
             opening_time != "NA" & closing_time != "NA" &
             nzchar(opening_time) & nzchar(closing_time))
  print(head(sample_with[, c("Name", "Theme", "opening_time", "closing_time")], 10))
}

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