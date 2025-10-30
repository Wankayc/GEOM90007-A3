<<<<<<< Updated upstream
# ============================================================================
# server/server_map.R - Map Tab Server Logic
# Complete implementation with all features
# ============================================================================

# Toggle places button
observeEvent(input$toggle_places, {
  if(length(input$place_types) > 0) {
    updateAwesomeCheckboxGroup(session, "place_types", selected = character(0))
  } else {
    updateAwesomeCheckboxGroup(session, "place_types", selected = c("cafe", "restaurant", "park", "toilet", "bbq", "bar", "shopping"))
  }
})

# Update location choices
observe({
  locations <- c("Flinders Street Station", "Southern Cross Station", "Melbourne Central")
  
  updatePickerInput(
    session, 
    "start_location",
    choices = locations,
    selected = "Flinders Street Station"
  )
  
  updatePickerInput(
    session, 
    "end_location",
    choices = locations,
    selected = "Southern Cross Station"
  )
}) # <<< FIX: This block was not closed correctly.
=======
# Map Tab Server Logic

# ---------- Helper Functions -------------------------------------------------

`%||%` <- function(a, b) if (is.null(a)) b else a

filter_by_operating_hours_csv <- function(df) {
  if (is.null(df) || !nrow(df)) return(df)
  if (!("opening_time" %in% names(df)) || !("closing_time" %in% names(df))) return(df)
  
  rng <- tryCatch(input$time_filter %||% c(0, 24), error = function(e) c(0, 24))
  include_unknown <- tryCatch(isTRUE(input$include_unknown_hours), error = function(e) TRUE)
  range_min <- as.integer(rng[1] * 60L)
  range_max <- as.integer(rng[2] * 60L)
  
  to_minutes_one <- function(x) {
    if (is.na(x)) return(NA_integer_)
    
    s <- gsub("[\\s\\r\\n\\t]+", "", as.character(x))
    
    if (identical(s, "") || tolower(s) %in% c("na","nan","none")) return(NA_integer_)
    if (grepl("^[0-9]+(\\.[0-9]+)?$", s)) return(NA_integer_)
    
    parts <- strsplit(s, ":", fixed = TRUE)[[1]]
    h <- suppressWarnings(as.integer(parts[1]))
    m <- if (length(parts) > 1) suppressWarnings(as.integer(parts[2])) else 0L
    if (is.na(h) || is.na(m) || h < 0L || h > 24L || m < 0L || m > 59L) return(NA_integer_)
    
    if (h == 24L && m == 0L) return(23L*60L + 59L)
    h*60L + m
  }
  
  to_minutes <- function(v) vapply(v, to_minutes_one, integer(1))
  
  df$open_min  <- to_minutes(df$opening_time)
  df$close_min <- to_minutes(df$closing_time)
  
  keep <- logical(nrow(df))
  
  for (i in seq_len(nrow(df))) {
    o <- df$open_min[i]
    c <- df$close_min[i]
    
    if (is.na(o) || is.na(c)) {
      keep[i] <- include_unknown
      next
    }
    
    if (c >= o) {
      coverage <- (o <= range_min) && (c >= range_max)
      keep[i] <- coverage
    } else {
      if (range_max > range_min) {
        keep[i] <- FALSE
      } else {
        keep[i] <- TRUE
      }
    }
  }
  
  df[keep, , drop = FALSE]
}

# ---------- Constants --------------------------------------------------------

MODE_COLORS <- list(
  driving = "#2ca02c",
  transit = "#1f77b4", 
  walking = "#ff7f0e",
  bicycling = "#9467bd"
)

STYLE_JSON_STRING <- '[
  {"featureType":"road.highway","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"road.arterial","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
  {"featureType":"poi","stylers":[{"visibility":"on"}]},
  {"featureType":"poi.business","stylers":[{"visibility":"on"}]}
]'

# ---------- Reactive Values -------------------------------------------------
>>>>>>> Stashed changes

# Initialize map state
map_rv <- reactiveValues(
  start = NULL,
  end = NULL,
  picking_mode = NULL,
  search_results = NULL,
  route_summaries = list(),
<<<<<<< Updated upstream
  default_places = NULL,
  filtered_places = NULL
)

# ===== RENDER GOOGLE MAP =====
=======
  filtered_places = NULL,
  all_locations = NULL,
  selected_location = NULL,
  current_display_data = NULL,
  display_source = NULL
)

# ---------- Map Rendering ---------------------------------------------------

>>>>>>> Stashed changes
output$google_map <- renderGoogle_map({
  google_map(
    key = GOOGLE_MAPS_API_KEY,
    location = c(-37.8136, 144.9631),
    zoom = 13,
    search_box = FALSE,
    libraries = "places",
<<<<<<< Updated upstream
    event_return_type = "list"
  )
})

# ===== BIND PLACES AUTOCOMPLETE =====
observeEvent(input$google_map_bounds, {
  session$sendCustomMessage('bindAutocomplete', list(
    ids = c('start_input', 'end_input', 'search_text')
  ))
  
  # Load default places after map is ready
  Sys.sleep(0.5)
  if (!is.null(map_rv$default_places)) {
    load_default_places()
=======
    event_return_type = "list",
    map_type_control = FALSE,
    styles = STYLE_JSON_STRING
  )
})

# ---------- Data Initialization ---------------------------------------------

observe({
  if (is.null(map_rv$all_locations) && exists("theme_data")) {
    map_rv$all_locations <- theme_data
    map_rv$filtered_places <- NULL
>>>>>>> Stashed changes
  }
}, once = TRUE)

<<<<<<< Updated upstream
# ===== TIME FILTER (RANGE SLIDER) =====
observeEvent(input$time_filter, {
  time_range <- input$time_filter
  time_min <- time_range[1]
  time_max <- time_range[2]
  
  if (!is.null(map_rv$default_places)) {
    filtered <- map_rv$default_places %>%
      filter(open_time <= time_max & close_time >= time_min)
    
    map_rv$filtered_places <- filtered
    load_default_places()
    
    showNotification(
      sprintf("Showing %d places open between %02d:00-%02d:00", 
              nrow(filtered), time_min, time_max),
      type = "message",
      duration = 2
    )
  }
})

# ===== LOAD DEFAULT PLACES FUNCTION =====
load_default_places <- function() {
=======
# ---------- Operating Hours Filter ------------------------------------------

observeEvent(list(input$time_filter, input$include_unknown_hours), {
  if (is.null(map_rv$current_display_data)) return()
  
  filtered_data <- filter_by_operating_hours_csv(map_rv$current_display_data)
  
  if (nrow(filtered_data) == 0) {
    google_map_update("google_map") %>%
      clear_markers(layer_id = "csv_places") %>%
      clear_markers(layer_id = "wordcloud_places") %>%
      clear_markers(layer_id = "search_results")
    
    showNotification(
      "No locations match the selected operating hours", 
      type = "warning", 
      duration = 3
    )
    return()
  }
  
  layer_id <- switch(
    map_rv$display_source,
    "wordcloud" = "wordcloud_places",
    "search" = "search_results",
    "category" = "csv_places",
    "csv_places"
  )
  
  display_data <- filtered_data %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude)) %>%
    dplyr::mutate(
      lat = as.numeric(Latitude),
      lng = as.numeric(Longitude),
      name = as.character(Name)
    ) %>%
    dplyr::select(name, lat, lng)
  
  google_map_update("google_map") %>%
    clear_markers(layer_id = "csv_places") %>%
    clear_markers(layer_id = "wordcloud_places") %>%
    clear_markers(layer_id = "search_results") %>%
    add_markers(
      data = display_data,
      lat = "lat",
      lon = "lng",
      id = "name",
      layer_id = layer_id,
      update_map_view = FALSE
    )
  
  showNotification(
    sprintf("Showing %d locations (after hours filter)", nrow(display_data)),
    type = "message",
    duration = 2
  )
}, ignoreInit = TRUE, ignoreNULL = FALSE)

# ---------- Map Reset Functionality -----------------------------------------

observeEvent(input$reset_map, {
  google_map_update("google_map") %>%
    clear_markers(layer_id = "csv_places") %>%
    clear_markers(layer_id = "wordcloud_places") %>%
    clear_markers(layer_id = "search_results") %>%
    clear_markers(layer_id = "route_markers") %>%
    clear_markers(layer_id = "carousel_highlight") %>% 
    clear_polylines()
  
  map_rv$filtered_places <- NULL
  map_rv$selected_location <- NULL
  map_rv$current_display_data <- NULL
  map_rv$display_source <- NULL
  
  updateSelectInput(session, "category_filter", selected = "all")
  updateTextInput(session, "search_text", value = "")
  
  showNotification(
    "✓ Map reset. Please select a category to display locations.", 
    type = "message", 
    duration = 3
  )
})

# ---------- Marker Click Handling -------------------------------------------

observeEvent(input$google_map_marker_click, {
  click_data <- input$google_map_marker_click
  if (is.null(click_data)) return()
  
  location_data <- map_rv$all_locations %>%
    dplyr::filter(Name == click_data$id)
  
  if (nrow(location_data) == 0) {
    showNotification("Location data not found", type = "error", duration = 3)
    return()
  }
  
  location <- location_data[1, ]
  
  safe_extract <- function(value, default = "Unknown") {
    if (is.null(value) || length(value) == 0) return(default)
    char_value <- as.character(value)
    if (is.na(char_value) || char_value == "NA" || nchar(trimws(char_value)) == 0) {
      return(default)
    }
    return(char_value)
  }
  
  map_rv$selected_location <- list(
    name = safe_extract(location$Name, "Unknown Location"),
    lat = as.numeric(location$Latitude),
    lng = as.numeric(location$Longitude),
    rating = if("Google_Rating" %in% names(location)) safe_extract(location$Google_Rating, "N/A") else "N/A",
    opening = if("opening_time" %in% names(location)) safe_extract(location$opening_time, "Unknown") else "Unknown",
    closing = if("closing_time" %in% names(location)) safe_extract(location$closing_time, "Unknown") else "Unknown",
    theme = if("Theme" %in% names(location)) safe_extract(location$Theme, "Unknown") else "Unknown",
    sub_theme = if("Sub_Theme" %in% names(location)) safe_extract(location$Sub_Theme, "Unknown") else "Unknown"
  )
  
  showNotification(
    paste0("Selected: ", map_rv$selected_location$name),
    type = "message",
    duration = 2
  )
})

# ---------- Location Setting Functions --------------------------------------

observeEvent(input$set_as_start, {
  if (is.null(map_rv$selected_location)) {
    showNotification("Please click on a location on the map first", type = "warning", duration = 3)
    return()
  }
  
  map_rv$start <- c(
    lat = map_rv$selected_location$lat,
    lng = map_rv$selected_location$lng,
    name = map_rv$selected_location$name
  )
  
  updateTextInput(session, "start_input", value = as.character(map_rv$start["name"]))
  draw_start_end_markers()
  
  showNotification(paste0("✓ Start location set to: ", map_rv$selected_location$name), 
                   type = "message", duration = 3)
})

observeEvent(input$set_as_end, {
  if (is.null(map_rv$selected_location)) {
    showNotification("Please click on a location on the map first", type = "warning", duration = 3)
    return()
  }
  
  map_rv$end <- c(
    lat = map_rv$selected_location$lat,
    lng = map_rv$selected_location$lng,
    name = map_rv$selected_location$name
  )
  
  updateTextInput(session, "end_input", value = as.character(map_rv$end["name"]))
  draw_start_end_markers()
  
  showNotification(paste0("✓ End location set to: ", map_rv$selected_location$name), 
                   type = "message", duration = 3)
})

# ---------- Category Filter -------------------------------------------------

observeEvent(input$category_filter, {
  if (is.null(map_rv$all_locations)) return()
  category <- input$category_filter
  
  if (category == "all") {
    google_map_update("google_map") %>% clear_markers(layer_id = "csv_places")
    
    map_rv$filtered_places <- NULL
    map_rv$selected_location <- NULL
    map_rv$current_display_data <- NULL
    map_rv$display_source <- NULL
    
    showNotification(
      "Please select a specific category to view locations", 
      type = "message", 
      duration = 2
    )
    return()
  }
  
  map_rv$filtered_places <- dplyr::filter(map_rv$all_locations, Theme == category)
  map_rv$current_display_data <- map_rv$filtered_places
  map_rv$display_source <- "category"
  map_rv$selected_location <- NULL
  
  load_csv_places()
  
  showNotification(
    sprintf("Showing %d locations in %s", nrow(map_rv$filtered_places), category), 
    type = "message", 
    duration = 2
  )
}, ignoreInit = TRUE)

# ---------- CSV Places Loading ----------------------------------------------

load_csv_places <- function() {
>>>>>>> Stashed changes
  places <- map_rv$filtered_places
  
  if (is.null(places) || nrow(places) == 0) {
    google_map_update('google_map') %>%
      clear_markers(layer_id = 'default_places')
    return()
  }
  
<<<<<<< Updated upstream
  google_map_update('google_map') %>%
    clear_markers(layer_id = 'default_places') %>%
    add_markers(
      data = places,
      lat = 'lat',
      lon = 'lng',
      info_window = 'name',
      layer_id = 'default_places'
    )
}

# ===== GEOLOCATION: MY LOCATION =====
=======
  places <- filter_by_operating_hours_csv(places)
  
  if (nrow(places) == 0) {
    google_map_update("google_map") %>% clear_markers(layer_id = "csv_places")
    showNotification("No locations match the selected operating hours", type = "warning", duration = 3)
    return()
  }
  
  places_clean <- places %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude)) %>%
    dplyr::mutate(
      lat  = as.numeric(Latitude),
      lng  = as.numeric(Longitude),
      name = as.character(Name)
    ) %>%
    dplyr::select(name, lat, lng)
  
  google_map_update("google_map") %>%
    clear_markers(layer_id = "csv_places") %>%
    add_markers(
      data = places_clean,
      lat = "lat",
      lon = "lng",
      id  = "name",
      layer_id = "csv_places",
      update_map_view = FALSE
    )
}

# ---------- Geolocation Handling --------------------------------------------

>>>>>>> Stashed changes
observeEvent(input$start_my_location, {
  showNotification(
    HTML("
      <b>Location Permission Required</b><br>
      <small>If denied: Use 'Pick on Map' or type address instead</small>
    "),
    type = "warning",
    duration = 6,
    id = "geo_warning"
  )
  
  session$sendCustomMessage('requestGeolocation', 
                            list(callback = 'start_geo_result'))
})

observeEvent(input$end_my_location, {
  showNotification(
    HTML("
      <b>Location Permission Required</b><br>
      <small>If denied: Use 'Pick on Map' or type address instead</small>
    "),
    type = "warning",
    duration = 6,
    id = "geo_warning"
  )
  
  session$sendCustomMessage('requestGeolocation', 
                            list(callback = 'end_geo_result'))
})

# Handle geolocation results
observeEvent(input$start_geo_result, {
  result <- input$start_geo_result
  removeNotification(id = "geo_warning")
  
  if (!is.null(result$error)) {
    showNotification(
      HTML(paste0(
        "<b>Geolocation Failed</b><br>",
        result$error, "<br>",
        "<small>Use 'Pick on Map' instead</small>"
      )),
      type = "error",
      duration = 6
    )
    return()
  }
  
  map_rv$start <- c(
    lat = result$lat, 
    lng = result$lng, 
    name = sprintf("My Location (%.4f, %.4f)", result$lat, result$lng)
  )
  
  updateTextInput(session, 'start_input', value = map_rv$start['name'])
  draw_start_end_markers()
  showNotification("✓ Start location set", type = "message", duration = 2)
})

observeEvent(input$end_geo_result, {
  result <- input$end_geo_result
  removeNotification(id = "geo_warning")
  
  if (!is.null(result$error)) {
    showNotification(
      HTML(paste0(
        "<b>Geolocation Failed</b><br>",
        result$error, "<br>",
        "<small>Use 'Pick on Map' instead</small>"
      )),
      type = "error",
      duration = 6
    )
    return()
  }
  
  map_rv$end <- c(
    lat = result$lat, 
    lng = result$lng, 
    name = sprintf("My Location (%.4f, %.4f)", result$lat, result$lng)
  )
  
  updateTextInput(session, 'end_input', value = map_rv$end['name'])
  draw_start_end_markers()
  showNotification("✓ End location set", type = "message", duration = 2)
})

<<<<<<< Updated upstream
# ===== AUTOCOMPLETE SELECTION =====
observeEvent(input$start_input_place, {
  place <- input$start_input_place
  if (is.null(place)) return()
  
  map_rv$start <- c(
    lat = place$lat,
    lng = place$lng,
    name = place$name
  )
  draw_start_end_markers()
  showNotification("Start location updated", type = "message", duration = 2)
})
=======
# ---------- Start/End Marker Drawing ----------------------------------------
>>>>>>> Stashed changes

observeEvent(input$end_input_place, {
  place <- input$end_input_place
  if (is.null(place)) return()
  
  map_rv$end <- c(
    lat = place$lat,
    lng = place$lng,
    name = place$name
  )
  draw_start_end_markers()
  showNotification("End location updated", type = "message", duration = 2)
})

# ===== PICK ON MAP - COMPLETE IMPLEMENTATION =====

# Start picking mode for START location
observeEvent(input$start_pick_map, {
  map_rv$picking_mode <- 'start'
  
  # Change cursor to crosshair
  runjs("document.getElementById('google_map').style.cursor = 'crosshair';")
  
  showNotification(
    HTML("<b>👆 Pick START Location</b><br>Click anywhere on the map"),
    type = "message", 
    duration = NULL,
    closeButton = TRUE,
    id = "picking_notification"
  )
})

# Start picking mode for END location
observeEvent(input$end_pick_map, {
  map_rv$picking_mode <- 'end'
  
  # Change cursor to crosshair
  runjs("document.getElementById('google_map').style.cursor = 'crosshair';")
  
  showNotification(
    HTML("<b>👆 Pick END Location</b><br>Click anywhere on the map"),
    type = "message", 
    duration = NULL,
    closeButton = TRUE,
    id = "picking_notification"
  )
})

# Handle map click events
observeEvent(input$google_map_click, {
  click <- input$google_map_click
  
  # Debug output
  cat("Map clicked:", click$lat, click$lon, "\n")
  
  # Exit if not in picking mode
  if (is.null(map_rv$picking_mode)) {
    return()
  }
  
  # Validate click data
  if (is.null(click) || is.null(click$lat) || is.null(click$lon)) {
    showNotification("Invalid click. Please try again.", type = "error")
    return()
  }
  
  # Create location data
  location <- c(
    lat = click$lat,
    lng = click$lon,
    name = sprintf("Selected (%.4f, %.4f)", click$lat, click$lon)
  )
  
  # Set start or end based on picking mode
  if (map_rv$picking_mode == 'start') {
    map_rv$start <- location
    updateTextInput(session, 'start_input', value = location['name'])
    showNotification(
      HTML(sprintf("<b>✓ Start Location Set</b><br>%s", location['name'])),
      type = "message",
      duration = 3
    )
  } else if (map_rv$picking_mode == 'end') {
    map_rv$end <- location
    updateTextInput(session, 'end_input', value = location['name'])
    showNotification(
      HTML(sprintf("<b>✓ End Location Set</b><br>%s", location['name'])),
      type = "message",
      duration = 3
    )
  }
  
  # Reset cursor
  runjs("document.getElementById('google_map').style.cursor = 'default';")
  
  # Clear picking mode
  map_rv$picking_mode <- NULL
  removeNotification(id = "picking_notification")
  
  # Update markers
  draw_start_end_markers()
}, ignoreNULL = FALSE, ignoreInit = TRUE)

# ===== DRAW START/END MARKERS =====
draw_start_end_markers <- function() {
<<<<<<< Updated upstream
  google_map_update('google_map') %>%
    clear_markers(layer_id = 'route_markers') %>%
    {
      map_obj <- .
      
      if (!is.null(map_rv$start)) {
        map_obj <- add_markers(
          map_obj,
          data = data.frame(
            lat = as.numeric(map_rv$start['lat']),
            lng = as.numeric(map_rv$start['lng'])
          ),
          lat = 'lat',
          lon = 'lng',
          info_window = map_rv$start['name'],
          marker_icon = list(
            url = "https://maps.google.com/mapfiles/ms/icons/green-dot.png"
          ),
          layer_id = 'route_markers'
        )
      }
      
      if (!is.null(map_rv$end)) {
        map_obj <- add_markers(
          map_obj,
          data = data.frame(
            lat = as.numeric(map_rv$end['lat']),
            lng = as.numeric(map_rv$end['lng'])
          ),
          lat = 'lat',
          lon = 'lng',
          info_window = map_rv$end['name'],
          marker_icon = list(
            url = "https://maps.google.com/mapfiles/ms/icons/red-dot.png"
          ),
          layer_id = 'route_markers'
        )
      }
      
      map_obj
    }
}

# ===== PLACES SEARCH =====
=======
  map_update <- google_map_update("google_map") %>% clear_markers(layer_id = "route_markers")
  
  if (!is.null(map_rv$start)) {
    map_update <- add_markers(
      map_update,
      data = data.frame(
        lat  = as.numeric(map_rv$start["lat"]),
        lng  = as.numeric(map_rv$start["lng"])
      ),
      lat = "lat", lon = "lng",
      marker_icon = list(url = "https://maps.google.com/mapfiles/ms/icons/green-dot.png"),
      layer_id = "route_markers", update_map_view = FALSE
    )
  }
  
  if (!is.null(map_rv$end)) {
    map_update <- add_markers(
      map_update,
      data = data.frame(
        lat  = as.numeric(map_rv$end["lat"]),
        lng  = as.numeric(map_rv$end["lng"])
      ),
      lat = "lat", lon = "lng",
      marker_icon = list(url = "https://maps.google.com/mapfiles/ms/icons/red-dot.png"),
      layer_id = "route_markers", update_map_view = FALSE
    )
  }
  
  map_update
}

# ---------- Search Functionality --------------------------------------------

>>>>>>> Stashed changes
observeEvent(input$search_places, {
  req(input$search_text)
  
<<<<<<< Updated upstream
  center <- if (!is.null(map_rv$start)) {
    c(as.numeric(map_rv$start['lat']), as.numeric(map_rv$start['lng']))
  } else {
    c(-37.8136, 144.9631)
  }
=======
  search_results_raw <- map_rv$all_locations %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude) &
                    (grepl(search_term, tolower(Name),       fixed = TRUE) |
                       grepl(search_term, tolower(Sub_Theme),  fixed = TRUE) |
                       grepl(search_term, tolower(Theme),      fixed = TRUE)))
>>>>>>> Stashed changes
  
  result <- try(
    google_places(
      search_string = input$search_text,
      location = center,
      radius = 1500,
      key = GOOGLE_MAPS_API_KEY,
      language = 'en'
    ),
    silent = TRUE
  )
  
  if (inherits(result, 'try-error')) {
    showNotification("Search failed. Please try again.", type = "error")
    return()
  }
  
<<<<<<< Updated upstream
  if (is.null(result$results) || nrow(result$results) == 0) {
    showNotification("No results found", type = "warning")
=======
  map_rv$current_display_data <- search_results_raw
  map_rv$display_source <- "search"
  
  search_results <- filter_by_operating_hours_csv(search_results_raw)
  
  if (nrow(search_results) == 0) {
    showNotification("No matching locations found (check operating hours filter)", type = "warning", duration = 3)
>>>>>>> Stashed changes
    return()
  }
  
  places_df <- result$results %>%
    mutate(
      lat = geometry$location$lat,
      lng = geometry$location$lng,
      name = as.character(name)
    ) %>%
    select(name, place_id, lat, lng) %>%
    head(15)
  
  map_rv$search_results <- places_df
  
  google_map_update('google_map') %>%
    clear_markers(layer_id = 'search_results') %>%
    add_markers(
<<<<<<< Updated upstream
      data = places_df,
      lat = 'lat',
      lon = 'lng',
      info_window = 'name',
      layer_id = 'search_results'
    )
  
  showNotification(sprintf("Found %d places", nrow(places_df)), type = "message")
})

# ===== CALCULATE ROUTES =====
observeEvent(input$get_directions, {
  req(map_rv$start, map_rv$end)
  
  google_map_update('google_map') %>%
    clear_polylines()
  
  modes <- input$travel_modes
  if (length(modes) == 0) modes <- 'driving'
=======
      data = search_results,
      lat = "lat", lon = "lng",
      id  = "name",
      layer_id = "search_results",
      marker_icon = list(url = "https://maps.google.com/mapfiles/ms/icons/blue-dot.png")
    )
  
  showNotification(sprintf("Found %d matching locations (after hours filter)", nrow(search_results)), 
                   type = "message", duration = 3)
})

# ---------- Wordcloud Integration -------------------------------------------

observeEvent(map_refresh_trigger(), {
  sub_theme <- selected_sub_theme_for_map()
  if (is.null(sub_theme) || sub_theme == "") return()
  
  if (!exists("theme_data")) {
    showNotification("Data not loaded", type = "error", duration = 3)
    return()
  }
  
  top_places_data <- NULL
  if (exists("top_places_for_map") && is.function(top_places_for_map)) {
    top_places_data <- top_places_for_map()
  }
  
  places_raw <- if (!is.null(top_places_data) && nrow(top_places_data) > 0) {
    top_places_data
  } else {
    dplyr::filter(theme_data, Sub_Theme == sub_theme)
  }
  
  map_rv$current_display_data <- places_raw
  map_rv$display_source <- "wordcloud"
  
  places <- filter_by_operating_hours_csv(places_raw)
  
  if (nrow(places) == 0) {
    showNotification(paste0("No locations found for: ", sub_theme, " (check operating hours filter)"), 
                     type = "warning", duration = 3)
    return()
  }
  
  places <- places %>%
    dplyr::filter(!is.na(Latitude) & !is.na(Longitude)) %>%
    dplyr::mutate(
      lat  = as.numeric(Latitude),
      lng  = as.numeric(Longitude),
      name = as.character(Name)
    ) %>%
    dplyr::select(name, lat, lng)
  
  google_map_update("google_map") %>%
    clear_markers(layer_id = "wordcloud_places") %>%
    add_markers(
      data = places,
      lat = "lat", lon = "lng",
      id  = "name",
      layer_id = "wordcloud_places",
      update_map_view = FALSE
    )
  
  map_rv$filtered_places <- places_raw
  
  showNotification(paste0("✓ Showing ", nrow(places), " places: ", sub_theme, " (after hours filter)"), 
                   type = "message", duration = 3)
}, ignoreNULL = TRUE, ignoreInit = TRUE)

# ---------- Directions Calculation ------------------------------------------

observeEvent(input$get_directions, {
  if (is.null(map_rv$start) || is.null(map_rv$end)) {
    showNotification(
      HTML("<b>Missing Location</b><br>Please set both start and end locations"),
      type = "error", duration = 4
    )
    return()
  }
  
  if (is.null(GOOGLE_MAPS_API_KEY) || GOOGLE_MAPS_API_KEY == "") {
    showNotification(
      HTML("<b>API Key Error</b><br>Google Maps API key is not configured properly"),
      type = "error", duration = 6
    )
    return()
  }
  
  google_map_update("google_map") %>% clear_polylines()
  
  modes <- input$travel_modes
  if (length(modes) == 0) modes <- "driving"
>>>>>>> Stashed changes
  
  route_summaries <- list()
  
  for (mode in modes) {
    direction <- try(
      google_directions(
        origin = c(as.numeric(map_rv$start['lat']), 
                   as.numeric(map_rv$start['lng'])),
        destination = c(as.numeric(map_rv$end['lat']), 
                        as.numeric(map_rv$end['lng'])),
        mode = mode,
        key = GOOGLE_MAPS_API_KEY,
        simplify = TRUE
      ),
      silent = TRUE
    )
    
<<<<<<< Updated upstream
    if (inherits(direction, 'try-error') || 
        is.null(direction$routes) || 
        length(direction$routes) == 0) {
=======
    if (inherits(direction, "try-error")) {
      errors[[mode]] <- as.character(direction)
      next
    }
    
    if (is.null(direction$routes) || length(direction$routes) == 0) {
      errors[[mode]] <- "No routes available"
>>>>>>> Stashed changes
      next
    }
    
    polyline <- direction$routes$overview_polyline$points
    
    google_map_update('google_map') %>%
      add_polylines(
        polyline = polyline,
        stroke_weight = 5,
        stroke_colour = MODE_COLORS[[mode]],
        stroke_opacity = 0.8,
        layer_id = paste0('route_', mode)
      )
    
    legs <- direction$routes$legs
    if (!is.null(legs) && length(legs) > 0) {
<<<<<<< Updated upstream
      leg <- legs[[1]][[1]]
      route_summaries[[mode]] <- list(
        distance_km = round(as.numeric(leg$distance$value) / 1000, 1),
        duration_min = round(as.numeric(leg$duration$value) / 60)
      )
=======
      leg <- legs[[1]]
      
      distance_value <- tryCatch(as.numeric(leg$distance$value), error = function(e) NA)
      duration_value <- tryCatch(as.numeric(leg$duration$value), error = function(e) NA)
      
      if (!is.na(distance_value) && !is.na(duration_value)) {
        route_summaries[[mode]] <- list(
          distance_km  = round(distance_value / 1000, 1),
          duration_min = round(duration_value / 60)
        )
      }
>>>>>>> Stashed changes
    }
  }
  
  map_rv$route_summaries <- route_summaries
  
  if (length(route_summaries) > 0) {
<<<<<<< Updated upstream
=======
    showNotification(sprintf("✓ Calculated %d route(s)", length(route_summaries)), 
                     type = "message", duration = 3)
  } else {
    error_details <- if (length(errors) > 0) paste("<br><small>", names(errors)[1], ":", errors[[1]], "</small>") else ""
>>>>>>> Stashed changes
    showNotification(
      sprintf("✓ Calculated %d route(s)", length(route_summaries)),
      type = "message",
      duration = 3
    )
  } else {
    showNotification(
      "❌ No routes found. Check your locations.",
      type = "error",
      duration = 5
    )
  }
<<<<<<< Updated upstream
})
=======
}, ignoreInit = TRUE)

# ---------- UI Output Components --------------------------------------------
>>>>>>> Stashed changes

# ===== ROUTE SUMMARY OUTPUT =====
output$route_summary_text <- renderUI({
  summaries <- map_rv$route_summaries
  
  if (length(summaries) == 0) {
    return(HTML('<span style="color:#999; font-size: 12px;">Set start & end, then click "Get Directions"</span>'))
  }
  
  summary_html <- lapply(names(summaries), function(mode) {
    info <- summaries[[mode]]
    mode_label <- switch(
      mode,
      driving = "🚗 Driving",
      transit = "🚌 Transit",
      walking = "🚶 Walking",
      bicycling = "🚴 Cycling",
      mode
    )
    glue::glue(
      '<div style="margin: 5px 0; font-size: 13px;">',
      '<b>{mode_label}</b><br>',
      '{info$distance_km} km · {info$duration_min} min',
      '</div>'
    )
  })
  
  HTML(paste(summary_html, collapse = ''))
})

<<<<<<< Updated upstream
# ===== MAP LAYERS TOGGLE =====
observeEvent(input$map_layers, {
  if (length(input$map_layers) > 0) {
    showNotification(
      sprintf("Layers: %s", paste(input$map_layers, collapse = ", ")),
      type = "message",
      duration = 2
    )
  }
})
=======
output$location_count <- renderUI({
  count <- if (!is.null(map_rv$filtered_places)) nrow(map_rv$filtered_places) else 0
  
  color <- if (count == 0) "#999" else "#007bff"
  message <- if (count == 0) "No locations displayed" else "locations displayed"
  
  HTML(sprintf(
    '<div style="padding: 10px; background: #f8f9fa; border-radius: 5px; margin-top: 10px; text-align: center;">
       <strong style="font-size: 16px; color: %s;">%d</strong>
       <br><small style="color: #666;">%s</small>
     </div>', color, count, message))
})

output$selected_location_card <- renderUI({
  if (is.null(map_rv$selected_location)) return(NULL)
  
  loc <- map_rv$selected_location
  
  div(
    style = "margin-top: 15px; padding: 15px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.15); color: white;",
    
    h5(
      style = "margin: 0 0 10px 0; font-weight: bold; font-size: 16px;",
      icon("map-marker-alt"), " Selected Location"
    ),
    
    div(
      style = "font-size: 15px; font-weight: 600; margin-bottom: 12px; padding-bottom: 10px; border-bottom: 1px solid rgba(255,255,255,0.3);",
      loc$name
    ),
    
    div(
      style = "font-size: 13px; line-height: 1.8;",
      
      div(
        style = "margin-bottom: 6px;",
        icon("tag"), " ",
        tags$strong("Category: "), 
        if (!is.null(loc$theme) && !is.na(loc$theme) && 
            loc$theme != "Unknown" && nzchar(loc$theme)) {
          loc$theme
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      ),
      
      div(
        style = "margin-bottom: 6px;",
        icon("info-circle"), " ",
        tags$strong("Type: "), 
        if (!is.null(loc$sub_theme) && !is.na(loc$sub_theme) && 
            loc$sub_theme != "Unknown" && nzchar(loc$sub_theme)) {
          loc$sub_theme
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      ),
      
      div(
        style = "margin-bottom: 6px;",
        icon("star"), " ",
        tags$strong("Rating: "),
        if (!is.null(loc$rating) && !is.na(loc$rating) && 
            loc$rating != "N/A" && loc$rating != "NA" && nzchar(loc$rating)) {
          loc$rating
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      ),
      
      div(
        style = "margin-bottom: 6px;",
        icon("clock"), " ",
        tags$strong("Hours: "),
        if (!is.null(loc$opening) && !is.na(loc$opening) && 
            loc$opening != "Unknown" && nzchar(loc$opening)) {
          paste0(loc$opening, " - ", loc$closing)
        } else {
          tags$span(style = "color: rgba(255,255,255,0.7); font-style: italic;", "Not Available")
        }
      )
    ),
    
    div(
      style = "margin-top: 12px; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.3); font-size: 12px; font-style: italic; opacity: 0.9;",
      icon("hand-point-down"), " Use buttons below to set as Start or End"
    )
  )
})
>>>>>>> Stashed changes
