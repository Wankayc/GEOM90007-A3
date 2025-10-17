# Map tab server logic

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
})

# Main map observer
observe({
  req(input$transport_map_bounds)
  
  map_proxy <- leafletProxy("transport_map") %>% 
    clearShapes() %>%
    clearMarkers() %>%
    clearControls()
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