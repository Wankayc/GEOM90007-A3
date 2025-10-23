server <- function(input, output, session) {
  
  # Rule-based approach for determining Personality based on categories
  user_behavior <- reactiveValues(
    category_clicks = list(
      accommodation = 0,
      transport = 0,
      attractions = 0,
      arts_culture = 0,
      food_drink = 0,
      heritage = 0,
      leisure = 0,
      public_service = 0,
      shopping = 0,
      health_services = 0
    ),
    current_personality = "Melbourne Explorer"
  )
  
  # Show app content when data is loaded
  observe({
    # Wait for your main datasets to load
    req(theme_data)  # Your main dataset
    
    # Hide loading screen and show app
    runjs('
      document.getElementById("loading-screen").style.display = "none";
      document.getElementById("app-content").style.display = "block";
    ')
  })
  
  # Render Tab UI
  output$weather_ui <- renderUI({ 
    source("ui/ui_weather.R", local = TRUE)$value 
  })
  
  output$map_ui <- renderUI({ 
    source("ui/ui_map.R", local = TRUE)$value 
  })
  
  output$summary_ui <- renderUI({ 
    source("ui/ui_summary.R", local = TRUE)$value 
  })
  
  # Load all server logic
  source("server/server_wordcloud.R", local = TRUE)
  source("server/server_weather.R", local = TRUE)
  source("server/server_map.R", local = TRUE)
  source("server/server_summary.R", local = TRUE)
  
  summary_server(input, output, session, user_behavior)
}