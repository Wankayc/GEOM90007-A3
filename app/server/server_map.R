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
=======
# Initialize map state
map_rv <- reactiveValues(
  start = NULL,
  end = NULL,
  picking_mode = NULL,
  search_results = NULL,
  route_summaries = list(),
  default_places = NULL,
  filtered_places = NULL
)

# ===== RENDER GOOGLE MAP =====
output$google_map <- renderGoogle_map({
  google_map(
    key = GOOGLE_MAPS_API_KEY,
    location = c(-37.8136, 144.9631),
    zoom = 13,
    search_box = FALSE,
    libraries = "places",
    event_return_type = "list"
  )
})

# ===== INITIALIZE DEFAULT PLACES =====
observe({
  req(input$transport_map_bounds)
  
  map_proxy <- leafletProxy("transport_map") %>% 
    clearShapes() %>%
    clearMarkers() %>%
    clearControls()
=======
  if (exists("DEFAULT_PLACES")) {
    map_rv$default_places <- DEFAULT_PLACES
    map_rv$filtered_places <- DEFAULT_PLACES
  }
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
  }
}, once = TRUE)

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
  places <- map_rv$filtered_places
  
  if (is.null(places) || nrow(places) == 0) {
    google_map_update('google_map') %>%
      clear_markers(layer_id = 'default_places')
    return()
  }
  
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
observeEvent(input$search_places, {
  req(input$search_text)
  
  center <- if (!is.null(map_rv$start)) {
    c(as.numeric(map_rv$start['lat']), as.numeric(map_rv$start['lng']))
  } else {
    c(-37.8136, 144.9631)
  }
  
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
  
  if (is.null(result$results) || nrow(result$results) == 0) {
    showNotification("No results found", type = "warning")
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
    
    if (inherits(direction, 'try-error') || 
        is.null(direction$routes) || 
        length(direction$routes) == 0) {
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
      leg <- legs[[1]][[1]]
      route_summaries[[mode]] <- list(
        distance_km = round(as.numeric(leg$distance$value) / 1000, 1),
        duration_min = round(as.numeric(leg$duration$value) / 60)
      )
    }
  }
  
  map_rv$route_summaries <- route_summaries
  
  if (length(route_summaries) > 0) {
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
>>>>>>> 25c4df9 (Map Page and Server Function - v1)
})

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
<<<<<<< HEAD

observeEvent(input$reset_map, {
  updateSliderInput(session, "map_zoom", value = 12)
})

# Transport Map
output$transport_map <- renderLeaflet({
  leaflet() %>%
    addTiles() %>%
    setView(lng = 144.9631, lat = -37.8136, zoom = 13) %>%
    addMarkers(lng = 144.9631, lat = -37.8136, popup = "Melbourne CBD")
})

observeEvent(input$calculate_route, {
  showNotification("Route calculation feature to be implemented", type = "message")
})
=======
>>>>>>> 25c4df9 (Map Page and Server Function - v1)
