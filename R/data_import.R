# Data loading functions
load_ptv_lines <- function() {
  file_path <- here("data", "raw", "Public Transport Lines.geojson")
  
  tryCatch({
    message("Loading transport lines data...")
    ptv_lines <- st_read(file_path, quiet = TRUE) %>%
      select(MODE, SHORT_NAME, LONG_NAME, geometry)
    ptv_lines <- st_transform(ptv_lines, crs = 4326)
    message("✓ Transport lines data loaded")
    return(ptv_lines)
  }, error = function(e) {
    message("✗ Error loading transport lines: ", e$message)
    return(NULL)
  })
}

load_transport_stops <- function() {
  file_path <- here("data", "raw", "Public Transport Stops.geojson")
  
  if (!file.exists(file_path)) {
    message("✗ Transport stops file not found")
    return(NULL)
  }
  
  tryCatch({
    message("Loading transport stops data...")
    stops_data <- st_read(file_path, quiet = TRUE)
    stops_data <- st_transform(stops_data, crs = 4326)
    message("✓ Transport stops data loaded")
    return(stops_data)
  }, error = function(e) {
    message("✗ Error loading transport stops: ", e$message)
    return(NULL)
  })
}