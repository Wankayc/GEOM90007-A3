# Map tab server logic

# Toggle all buttons for checkboxes
observeEvent(input$toggle_lines, {
  if(length(input$transport_lines) > 0) {
    # If any are selected, turn all OFF
    updateAwesomeCheckboxGroup(session, "transport_lines", selected = character(0))
  } else {
    # If none are selected, turn all ON
    updateAwesomeCheckboxGroup(session, "transport_lines", selected = c("train_lines", "tram_lines", "bus_lines", "skybus_lines"))
  }
})

observeEvent(input$toggle_stops, {
  if(length(input$transport_stops) > 0) {
    # If any are selected, turn all OFF
    updateAwesomeCheckboxGroup(session, "transport_stops", selected = character(0))
  } else {
    # If none are selected, turn all ON
    updateAwesomeCheckboxGroup(session, "transport_stops", selected = c("train_stops", "tram_stops", "bus_stops"))
  }
})

# Update location choices - COMMENTED OUT DATA-DEPENDENT PART
observe({
  # Use static choices instead of data-dependent ones
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
})

# Main map observer - SIMPLIFIED
observe({
  map_proxy <- leafletProxy("transport_map") %>% 
    clearShapes() %>%
    clearMarkers() %>%
    clearControls()
  
  # Comment out data-dependent layer additions
  # map_proxy <- add_transport_lines(map_proxy, shared$datasets$preprocessed_data, input$transport_lines)
  # map_proxy <- add_transport_stops(map_proxy, shared$datasets$preprocessed_data, input$transport_stops)
  
  # Add simple demo markers based on checkboxes
  if ("train_lines" %in% input$transport_lines) {
    map_proxy <- map_proxy %>%
      addMarkers(lng = 144.9631, lat = -37.8136, popup = "Demo Train Station")
  }
  
  # Build active groups and add layer control
  active_groups <- build_active_groups(input$transport_lines, input$transport_stops)
  
  if (length(active_groups) > 0) {
    map_proxy %>%
      addLayersControl(
        overlayGroups = active_groups,
        options = layersControlOptions(collapsed = FALSE)
      )
  }
})

# Simple Map Tab
output$simple_map <- renderLeaflet({
  leaflet() %>%
    addTiles() %>%
    setView(lng = 144.9631, lat = -37.8136, zoom = 13)
})

observeEvent(input$map_zoom, {
  leafletProxy("simple_map") %>%
    setView(lng = 144.9631, lat = -37.8136, zoom = input$map_zoom)
})

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

# Static value boxes
output$melbourne_info <- renderValueBox({
  valueBox("Demo", "Basic Map", icon = icon("map"), color = "blue")
})

output$city_center <- renderValueBox({
  valueBox("CBD", "Melbourne", icon = icon("bullseye"), color = "green")
})

output$map_status <- renderValueBox({
  valueBox("Ready", "Data loading disabled", icon = icon("layer-group"), color = "purple")
})

# Dynamic value boxes - SIMPLIFIED
output$total_stops <- renderValueBox({
  valueBox("8191", "Total Stops", icon = icon("map-marker"), color = "blue")
})

output$train_stops <- renderValueBox({
  valueBox("704", "Train Stops", icon = icon("train"), color = "green")
})

output$tram_stops <- renderValueBox({
  valueBox("1601", "Tram Stops", icon = icon("subway"), color = "orange")
})

output$bus_stops <- renderValueBox({
  valueBox("5874", "Bus Stops", icon = icon("bus"), color = "red")
})

# Route info using function - SIMPLIFIED
output$route_info <- renderUI({
  HTML("
    <h4>Interactive Transport Explorer</h4>
    <p><strong>Demo Mode:</strong> Data loading disabled</p>
    <p>Use checkboxes to toggle demo layers</p>
    <p><strong>Coverage Radius (when enabled):</strong></p>
    <ul>
      <li>Routes: 10km from Melbourne CBD</li>
      <li>Stops: 15km from Melbourne CBD</li>
    </ul>
  ")
})