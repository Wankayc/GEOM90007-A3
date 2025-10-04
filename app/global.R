# Load setup
source(here::here("R", "setup.R"))

# Load data functions
source(here::here("R", "data_import.R"))
source(here::here("R", "data_processing.R"))

# Pre-processed data storage
preprocessed_data <- new.env()

# Load functions for server
source(here::here("R", "functions.R"))

# Melbourne CBD coordinates
MELBOURNE_CBD <- st_sfc(st_point(c(144.9631, -37.8136)), crs = 4326)

# Load and process data
message("Loading radius-based transport dataset...")

# Load raw data
raw_lines <- load_ptv_lines()
raw_stops <- load_transport_stops()

# Process data
success <- process_transport_lines(raw_lines)
project_data <- process_transport_stops(raw_stops)

if (success && !is.null(project_data)) {
  message("ADIUS-BASED transport dataset loaded successfully!")
  
  # Debugging
  train_count <- nrow(preprocessed_data$metro_train)
  tram_count <- nrow(preprocessed_data$metro_tram)
  bus_count <- nrow(preprocessed_data$metro_bus)
  skybus_count <- nrow(preprocessed_data$skybus)
  total_stops <- nrow(project_data)
  
  message("RADIUS-BASED DATASET SUMMARY:")
  message("=======================================")
  message("COVERAGE RADIUS:")
  message("  🚆 Routes: 10km from Melbourne CBD")
  message("  📍 Stops: 15km from Melbourne CBD")
  message("")
  message("ROUTES (within 10km radius):")
  message("  - Metro Train: ", train_count, " routes")
  message("  - Metro Tram: ", tram_count, " routes") 
  message("  - Metro Bus: ", bus_count, " routes")
  message("  - SkyBus: ", skybus_count, " routes")
  message("")
  message("STOPS (within 15km radius):")
  message("  - Train stops: ", nrow(preprocessed_data$train_stops))
  message("  - Tram stops: ", nrow(preprocessed_data$tram_stops))
  message("  - Bus stops: ", nrow(preprocessed_data$bus_stops))
  message("  - TOTAL: ", total_stops, " stops")
  message("=======================================")
  
} else {
  message("Radius-based data loading failed")
}