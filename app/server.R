# server.R - Fully refactored with functions
server <- function(input, output, session) {
  
  # Track loading state
  loading_state <- reactiveVal(TRUE)
  
  # Hide loading screen when data is ready
  observe({
    if (exists("preprocessed_data") && !is.null(project_data)) {
      Sys.sleep(1)
      loading_state(FALSE)
    }
  })
  
  # Loading screen UI
  output$loading_screen <- renderUI({
    if (loading_state()) {
      div(
        id = "loading-screen",
        style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: white; z-index: 9999; display: flex; flex-direction: column; justify-content: center; align-items: center;",
        div(
          style = "text-align: center;",
          h3("Loading Melbourne Transport Map", style = "color: #007bff; margin-bottom: 20px;"),
          div(
            style = "border: 5px solid #f3f3f3; border-top: 5px solid #007bff; border-radius: 50%; width: 50px; height: 50px; animation: spin 1s linear infinite; margin-bottom: 20px;"
          ),
          p("Loading data within radius of Melbourne CBD...", style = "color: #666;"),
          p("This should only take a moment", style = "color: #999; font-size: 0.9em;")
        )
      )
    }
  })
  
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
  
  # Main map observer - REFACTORED WITH FUNCTIONS
  observe({
    req(exists("preprocessed_data"))
    if (loading_state()) return()
    
    map_proxy <- leafletProxy("transport_map") %>% 
      clearShapes() %>%
      clearMarkers() %>%
      clearControls()
    
    # Add layers using functions
    map_proxy <- add_transport_lines(map_proxy, preprocessed_data, input$transport_lines)
    map_proxy <- add_transport_stops(map_proxy, preprocessed_data, input$transport_stops)
    
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
    create_simple_map(input$map_zoom)
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
    create_transport_map()
  })
  
  observeEvent(input$calculate_route, {
    showNotification("Route calculation feature to be implemented", type = "message")
  })
  
  # Static value boxes
  output$melbourne_info <- renderValueBox({
    valueBox("Radius", "10km Routes", icon = icon("circle"), color = "blue")
  })
  
  output$city_center <- renderValueBox({
    valueBox("CBD", "Center", icon = icon("bullseye"), color = "green")
  })
  
  output$map_status <- renderValueBox({
    valueBox("Ready", "Use checkboxes to show layers", icon = icon("layer-group"), color = "purple")
  })
  
  # Dynamic value boxes using functions
  value_box_config <- reactive({
    create_transport_value_boxes(preprocessed_data, project_data)
  })
  
  output$total_stops <- renderValueBox({
    config <- value_box_config()$total_stops
    valueBox(config$value, config$subtitle, config$icon, config$color)
  })
  
  output$train_stops <- renderValueBox({
    config <- value_box_config()$train_stops
    valueBox(config$value, config$subtitle, config$icon, config$color)
  })
  
  output$tram_stops <- renderValueBox({
    config <- value_box_config()$tram_stops
    valueBox(config$value, config$subtitle, config$icon, config$color)
  })
  
  output$bus_stops <- renderValueBox({
    config <- value_box_config()$bus_stops
    valueBox(config$value, config$subtitle, config$icon, config$color)
  })
  
  # Route info using function
  output$route_info <- renderUI({
    create_route_info(preprocessed_data, project_data)
  })
}