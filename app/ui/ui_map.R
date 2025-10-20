# Map Tab - Advanced Google Maps with Places & Autocomplete
tabPanel(
  "Map",
  icon = icon("map"),
  
  # Custom CSS
  tags$head(
    tags$style(HTML('
      #google_map_wrapper { height: calc(100vh - 140px); position: relative; }
      .map-legend { 
        position: absolute; 
        bottom: 20px; 
        left: 20px; 
        z-index: 1000; 
        background: white; 
        border-radius: 8px; 
        padding: 12px 16px; 
        box-shadow: 0 2px 10px rgba(0,0,0,0.2);
        max-width: 280px;
      }
      .legend-item { 
        display: flex; 
        align-items: center; 
        gap: 10px; 
        margin: 6px 0;
        font-size: 13px;
      }
      .legend-swatch { 
        width: 16px; 
        height: 16px; 
        border-radius: 3px; 
      }
      .btn-location { margin: 5px 2px; }
    '))
  ),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      h4(icon("clock"), " Operating Hours Filter"),
      sliderInput(
        "time_filter",
        "Show places open between:",
        min = 0,
        max = 24,
        value = c(7, 23),
        step = 1,
        post = ":00",
        dragRange = TRUE
      ),
      helpText("Drag to filter places by operating hours range"),
      
      # Search Section
      h4(icon("search"), " Search Places"),
      textInput("search_text", NULL, placeholder = "Coffee, museum, restaurant..."),
      actionButton("search_places", "Find Places", class = "btn btn-primary btn-block", icon = icon("search")),
      helpText("Search within 1.5km of start point or map center"),
      
      hr(),
      
      # Route Planning Section
      h4(icon("route"), " Route Planning"),
      
      tags$label("Start Location", class = "control-label"),
      textInput("start_input", NULL, placeholder = "Type address or place name"),
      div(
        style = "display: flex; gap: 5px; margin-bottom: 10px;",
        actionButton("start_my_location", "📍 My Location", 
                     class = "btn btn-sm btn-outline-secondary btn-location"),
        actionButton("start_pick_map", "🖱️ Pick on Map", 
                     class = "btn btn-sm btn-outline-info btn-location")
      ),
      
      tags$label("End Location", class = "control-label"),
      textInput("end_input", NULL, placeholder = "Type address or place name"),
      div(
        style = "display: flex; gap: 5px; margin-bottom: 10px;",
        actionButton("end_my_location", "📍 My Location", 
                     class = "btn btn-sm btn-outline-secondary btn-location"),
        actionButton("end_pick_map", "🖱️ Pick on Map", 
                     class = "btn btn-sm btn-outline-info btn-location")
      ),
      
      checkboxGroupInput(
        "travel_modes",
        "Travel Modes (compare multiple)",
        choices = c(
          "Driving" = "driving",
          "Transit" = "transit",
          "Walking" = "walking",
          "Cycling" = "bicycling"
        ),
        selected = c("driving", "transit"),
        inline = TRUE
      ),
      
      actionButton("get_directions", "Get Directions", 
                   class = "btn btn-success btn-block", 
                   icon = icon("directions")),
      
      hr(),
      
      # Layers Section
      h4(icon("layer-group"), " Map Layers"),
      checkboxGroupInput(
        "map_layers",
        NULL,
        choices = c(
          "Train Lines" = "train",
          "Tram Lines" = "tram",
          "Bus Lines" = "bus"
        ),
        inline = TRUE
      ),
      helpText("Toggle transport layers (demo)")
    ),
    
    mainPanel(
      width = 9,
      div(
        id = "google_map_wrapper",
        google_mapOutput("google_map", height = "100%"),
        
        # Floating Route Summary Legend
        div(
          class = "map-legend",
          h5(style = "margin: 0 0 10px 0; font-weight: 600;", "Route Summary"),
          div(class = "legend-item",
              span(class = "legend-swatch", 
                   style = "background: #2ca02c;"),
              span("Driving")),
          div(class = "legend-item",
              span(class = "legend-swatch", 
                   style = "background: #1f77b4;"),
              span("Transit")),
          div(class = "legend-item",
              span(class = "legend-swatch", 
                   style = "background: #ff7f0e;"),
              span("Walking")),
          div(class = "legend-item",
              span(class = "legend-swatch", 
                   style = "background: #9467bd;"),
              span("Cycling")),
          tags$hr(style = "margin: 10px 0;"),
          htmlOutput("route_summary_text")
        )
      )
    )
  ),
  
  # JavaScript for Places Autocomplete & Geolocation
  tags$script(HTML("
    // Browser Geolocation
    Shiny.addCustomMessageHandler('requestGeolocation', function(config) {
      if (!navigator.geolocation) {
        Shiny.setInputValue(config.callback, {
          error: 'Geolocation not supported'
        }, { priority: 'event' });
        return;
      }
    
    navigator.geolocation.getCurrentPosition(
      function(position) {
        Shiny.setInputValue(config.callback, {
          lat: position.coords.latitude,
          lng: position.coords.longitude,
          accuracy: position.coords.accuracy,
          timestamp: Date.now()
        }, { priority: 'event' });
      },
      function(error) {
          var errorMsg = 'Unknown error';
          switch(error.code) {
            case error.PERMISSION_DENIED:
              errorMsg = 'Permission denied. Please allow location access in your browser.';
              break;
            case error.POSITION_UNAVAILABLE:
              errorMsg = 'Position unavailable';
              break;
            case error.TIMEOUT:
              errorMsg = 'Request timeout';
              break;
      }
        
          Shiny.setInputValue(config.callback, {
            error: errorMsg
          }, { priority: 'event' });
        },
        { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
      );
    });
  "))
)
