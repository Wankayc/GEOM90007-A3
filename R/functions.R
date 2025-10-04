# Map creation functions
create_simple_map <- function(zoom_level = 13) {
  leaflet() %>%
    addTiles() %>%
    setView(lng = 144.9631, lat = -37.8136, zoom = zoom_level) %>%
    addMarkers(
      lng = 144.9631, lat = -37.8136,
      label = "Melbourne CBD"
    )
}

create_transport_map <- function() {
  leaflet() %>% 
    addProviderTiles(providers$CartoDB.Positron) %>%
    setView(lng = 144.9631, lat = -37.8136, zoom = 12) %>%
    addScaleBar(position = "bottomleft") %>%
    addControl(
      html = "<div style='background: white; padding: 10px; border-radius: 5px; border: 2px solid #007bff;'>
              <strong>🎯 Use sidebar checkboxes to toggle layers</strong>
             </div>",
      position = "topright"
    )
}

# Map layer functions
add_transport_lines <- function(map_proxy, preprocessed_data, selected_lines) {
  layer_config <- list(
    train_lines = list(
      data = preprocessed_data$metro_train,
      color = "#E41A1C", 
      weight = 3,
      group = "Train Lines",
      label_suffix = "Metro Train"
    ),
    tram_lines = list(
      data = preprocessed_data$metro_tram,
      color = "#377EB8", 
      weight = 2.5,
      group = "Tram Lines", 
      label_suffix = "Metro Tram"
    ),
    bus_lines = list(
      data = preprocessed_data$metro_bus,
      color = "#4DAF4A", 
      weight = 2,
      group = "Bus Lines",
      label_suffix = "Metro Bus"
    ),
    skybus_lines = list(
      data = preprocessed_data$skybus,
      color = "#984EA3", 
      weight = 3,
      group = "SkyBus",
      label_suffix = "SkyBus"
    )
  )
  
  for (line_type in selected_lines) {
    config <- layer_config[[line_type]]
    if (!is.null(config$data) && nrow(config$data) > 0) {
      map_proxy <- map_proxy %>%
        addPolylines(
          data = config$data,
          color = config$color,
          weight = config$weight,
          opacity = 0.8,
          label = ~paste(SHORT_NAME, "-", config$label_suffix),
          popup = ~paste("<b>", SHORT_NAME, "</b><br>", LONG_NAME),
          group = config$group,
          highlightOptions = highlightOptions(
            weight = config$weight + 2,
            color = "#000000",
            opacity = 1,
            bringToFront = TRUE
          )
        )
    }
  }
  
  return(map_proxy)
}

add_transport_stops <- function(map_proxy, preprocessed_data, selected_stops) {
  stop_config <- list(
    train_stops = list(
      data = preprocessed_data$train_stops,
      fill_color = "red",
      radius = 4,
      group = "Train Stops",
      label_prefix = "🚆",
      popup_suffix = "Train Station"
    ),
    tram_stops = list(
      data = preprocessed_data$tram_stops,
      fill_color = "blue", 
      radius = 3,
      group = "Tram Stops",
      label_prefix = "🚊", 
      popup_suffix = "Tram Stop"
    ),
    bus_stops = list(
      data = preprocessed_data$bus_stops,
      fill_color = "green",
      radius = 2,
      group = "Bus Stops", 
      label_prefix = "🚌",
      popup_suffix = "Bus Stop"
    )
  )
  
  for (stop_type in selected_stops) {
    config <- stop_config[[stop_type]]
    if (!is.null(config$data) && nrow(config$data) > 0) {
      map_proxy <- map_proxy %>%
        addCircleMarkers(
          data = config$data,
          lng = ~lon, lat = ~lat,
          radius = config$radius,
          color = "#FFFFFF",
          weight = ifelse(config$radius > 3, 1.5, 1),
          fillColor = config$fill_color,
          fillOpacity = 0.8,
          label = ~paste(config$label_prefix, location),
          popup = ~paste("<b>", location, "</b><br>", config$popup_suffix),
          group = config$group
        )
    }
  }
  
  return(map_proxy)
}

# Helper function for active groups
build_active_groups <- function(selected_lines, selected_stops) {
  active_groups <- c()
  
  line_groups <- list(
    train_lines = "Train Lines",
    tram_lines = "Tram Lines", 
    bus_lines = "Bus Lines",
    skybus_lines = "SkyBus"
  )
  
  stop_groups <- list(
    train_stops = "Train Stops",
    tram_stops = "Tram Stops",
    bus_stops = "Bus Stops"
  )
  
  for (line_type in selected_lines) {
    if (line_type %in% names(line_groups)) {
      active_groups <- c(active_groups, line_groups[[line_type]])
    }
  }
  
  for (stop_type in selected_stops) {
    if (stop_type %in% names(stop_groups)) {
      active_groups <- c(active_groups, stop_groups[[stop_type]])
    }
  }
  
  return(active_groups)
}

# Value box functions
create_transport_value_boxes <- function(preprocessed_data, project_data) {
  list(
    total_stops = list(
      value = ifelse(!is.null(project_data), nrow(project_data), "0"),
      subtitle = "Total Stops",
      icon = icon("map-marker"),
      color = "blue"
    ),
    train_stops = list(
      value = ifelse(!is.null(preprocessed_data$train_stops), nrow(preprocessed_data$train_stops), 0),
      subtitle = "Train Stops", 
      icon = icon("train"),
      color = "red"
    ),
    tram_stops = list(
      value = ifelse(!is.null(preprocessed_data$tram_stops), nrow(preprocessed_data$tram_stops), 0),
      subtitle = "Tram Stops",
      icon = icon("subway"), 
      color = "green"
    ),
    bus_stops = list(
      value = ifelse(!is.null(preprocessed_data$bus_stops), nrow(preprocessed_data$bus_stops), 0),
      subtitle = "Bus Stops",
      icon = icon("bus"),
      color = "purple"
    )
  )
}

# Route info function
create_route_info <- function(preprocessed_data, project_data) {
  train_count <- ifelse(!is.null(preprocessed_data$metro_train), nrow(preprocessed_data$metro_train), 0)
  tram_count <- ifelse(!is.null(preprocessed_data$metro_tram), nrow(preprocessed_data$metro_tram), 0)
  bus_count <- ifelse(!is.null(preprocessed_data$metro_bus), nrow(preprocessed_data$metro_bus), 0)
  skybus_count <- ifelse(!is.null(preprocessed_data$skybus), nrow(preprocessed_data$skybus), 0)
  total_stops <- ifelse(!is.null(project_data), nrow(project_data), 0)
  
  HTML(paste0("
    <h4>🎯 Interactive Transport Explorer</h4>
    <p><strong>Use checkboxes in sidebar to toggle layers ON/OFF</strong></p>
    
    <p><strong>Coverage Radius:</strong></p>
    <ul>
      <li>🚆 Routes: 10km from CBD</li>
      <li>📍 Stops: 15km from CBD</li>
    </ul>
    
    <p><strong>How to use:</strong></p>
    <ul>
      <li>✅ Check boxes to show layers</li>
      <li>❌ Uncheck boxes to hide layers</li>
      <li>🔄 Use 'Toggle All' buttons for bulk operations</li>
    </ul>
    
    <p><strong>Dataset Statistics:</strong></p>
    <ul>
      <li>🚆 Trains: ", train_count, " routes</li>
      <li>🚊 Trams: ", tram_count, " routes</li>
      <li>🚌 Buses: ", bus_count, " routes</li>
      <li>✈️ SkyBus: ", skybus_count, " routes</li>
      <li>📍 Stops: ", total_stops, " total</li>
    </ul>
  "))
}