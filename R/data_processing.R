# Data processing functions
calculate_distance_from_cbd <- function(data) {
  data$distance_from_cbd <- as.numeric(st_distance(data, MELBOURNE_CBD))
  data$distance_km <- data$distance_from_cbd / 1000
  return(data)
}

filter_by_radius <- function(data, radius_km) {
  data_within_radius <- data %>% filter(distance_km <= radius_km)
  message("✓ Data within ", radius_km, "km radius: ", nrow(data_within_radius))
  return(data_within_radius)
}

process_transport_lines <- function(ptv_lines) {
  if (is.null(ptv_lines)) return(FALSE)
  
  # Calculate distances and filter
  ptv_lines <- calculate_distance_from_cbd(ptv_lines)
  ptv_lines_within_radius <- filter_by_radius(ptv_lines, 10)
  
  # Check mode distribution
  mode_counts <- ptv_lines_within_radius %>%
    st_drop_geometry() %>%
    count(MODE) %>%
    arrange(desc(n))
  
  message("Routes within 10km radius:")
  for(i in 1:nrow(mode_counts)) {
    message("  ", mode_counts$MODE[i], ": ", mode_counts$n[i], " routes")
  }
  
  # Store routes for main modes
  main_modes <- c("METRO TRAIN", "METRO TRAM", "METRO BUS", "SKYBUS")
  
  for (mode in main_modes) {
    mode_data <- ptv_lines_within_radius %>% filter(MODE == mode)
    
    if (nrow(mode_data) > 0) {
      assign(paste0(tolower(sub(" ", "_", mode))), mode_data, envir = preprocessed_data)
      message("✓ ", mode, ": ", nrow(mode_data), " routes (within 10km)")
    } else {
      empty_sf <- st_sf(
        MODE = character(), SHORT_NAME = character(), LONG_NAME = character(), 
        geometry = st_sfc(crs = 4326)
      )
      assign(paste0(tolower(sub(" ", "_", mode))), empty_sf, envir = preprocessed_data)
      message("✗ ", mode, ": No routes within 10km radius")
    }
  }
  
  message("✓ Radius-based transport lines processed successfully")
  return(TRUE)
}

process_transport_stops <- function(stops_data) {
  if (is.null(stops_data)) return(NULL)
  
  # Calculate distances and filter
  stops_data <- calculate_distance_from_cbd(stops_data)
  stops_within_radius <- filter_by_radius(stops_data, 15)
  
  # Extract coordinates and basic info
  stops_coords <- st_coordinates(stops_within_radius)
  
  # Create stops data frame
  all_stops <- data.frame(
    lon = stops_coords[, "X"],
    lat = stops_coords[, "Y"],
    distance_km = stops_within_radius$distance_km,
    stringsAsFactors = FALSE
  )
  
  # Add location name
  if ("STOP_NAME" %in% names(stops_within_radius)) {
    all_stops$location <- stops_within_radius$STOP_NAME
  } else if ("stop_name" %in% names(stops_within_radius)) {
    all_stops$location <- stops_within_radius$stop_name
  } else {
    all_stops$location <- paste("Stop", 1:nrow(stops_coords))
  }
  
  # Classify stop types
  all_stops <- classify_stop_types(all_stops, stops_within_radius)
  
  # Split by type and add styling
  train_stops <- all_stops %>% filter(type == "Train") %>% add_stop_styling("red", 4)
  tram_stops <- all_stops %>% filter(type == "Tram") %>% add_stop_styling("blue", 3)
  bus_stops <- all_stops %>% filter(type == "Bus") %>% add_stop_styling("green", 2)
  
  # Store stops
  preprocessed_data$train_stops <- train_stops
  preprocessed_data$tram_stops <- tram_stops
  preprocessed_data$bus_stops <- bus_stops
  
  message("✓ Stops within radius processed: ", nrow(all_stops))
  message("  - Train stops: ", nrow(train_stops))
  message("  - Tram stops: ", nrow(tram_stops))
  message("  - Bus stops: ", nrow(bus_stops))
  
  return(all_stops)
}

classify_stop_types <- function(all_stops, stops_within_radius) {
  if ("MODE" %in% names(stops_within_radius)) {
    all_stops$type <- case_when(
      grepl("train|rail", stops_within_radius$MODE, ignore.case = TRUE) ~ "Train",
      grepl("tram", stops_within_radius$MODE, ignore.case = TRUE) ~ "Tram",
      grepl("bus", stops_within_radius$MODE, ignore.case = TRUE) ~ "Bus",
      TRUE ~ "Other"
    )
  } else {
    # Classify based on distance from CBD
    all_stops$type <- case_when(
      all_stops$distance_km < 3 ~ "Train",
      all_stops$distance_km < 6 ~ "Tram",
      TRUE ~ "Bus"
    )
  }
  return(all_stops)
}

add_stop_styling <- function(stops_df, color, size) {
  stops_df$icon_color <- color
  stops_df$size <- size
  return(stops_df)
}