server <- function(input, output, session) {
  
  # Render UI for each tab
  output$wordcloud_ui <- renderUI({ 
    source("ui/ui_wordcloud.R", local = TRUE)$value 
  })
  
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
}