summary_server <- function(input, output, session, user_behavior) {
  
  # Create a reactive that tracks user behavior changes
  personality_data <- reactive({
    # Get the current click counts safely
    clicks <- list(
      accommodation = user_behavior$category_clicks$accommodation,
      transport = user_behavior$category_clicks$transport,
      attractions = user_behavior$category_clicks$attractions,
      arts_culture = user_behavior$category_clicks$arts_culture,
      food_drink = user_behavior$category_clicks$food_drink,
      heritage = user_behavior$category_clicks$heritage,
      leisure = user_behavior$category_clicks$leisure,
      public_service = user_behavior$category_clicks$public_service,
      shopping = user_behavior$category_clicks$shopping,
      health_services = user_behavior$category_clicks$health_services
    )
    
    # Calculate scores
    scores <- list(
      foodie = clicks$food_drink * 2,
      culture_seeker = clicks$arts_culture + clicks$heritage,
      nature_lover = clicks$attractions + clicks$leisure,
      urban_explorer = clicks$transport + clicks$shopping,
      wellness_enthusiast = clicks$health_services + clicks$leisure,
      practical_traveler = clicks$accommodation + clicks$public_service
    )
    
    max_score <- max(unlist(scores))
    dominant <- names(scores)[which.max(unlist(scores))]
    
    # Personality mapping
    total_clicks <- sum(unlist(clicks))
    if (total_clicks == 0) {
      # default
      list(
        type = "Melbourne Explorer",
        icon = icon("binoculars"),
        color = "#036B55", 
        description = "Start clicking categories to discover your Melbourne personality!"
      )
    } else if (max_score == 0 || is.na(max_score) || max_score < 1) {
      # Edge cases: no dominant personality or very low scores
      list(
        type = "Melbourne Explorer",
        icon = icon("compass"),
        color = "#036B55",
        description = "You're exploring everything! Click more to reveal your favorite side of Melbourne."
      )
    } else if (dominant == "foodie") {
      list(type = "Food Lover", icon = icon("coffee"), color = "#6f4e37", description = "You're always searching for the next great meal or perfect brew!")
    } else if (dominant == "culture_seeker") {
      list(type = "Culture Connoisseur", icon = icon("landmark"), color = "#4B0082", description = "You appreciate art, history, and cultural experiences!")
    } else if (dominant == "nature_lover") {
      list(type = "Nature Enthusiast", icon = icon("tree"), color = "#228B22", description = "You love exploring parks, gardens, and outdoor spaces!")
    } else if (dominant == "urban_explorer") {
      list(type = "Urban Adventurer", icon = icon("city"), color = "#4169E1", description = "You thrive in the city and love discovering urban gems!")
    } else if (dominant == "wellness_enthusiast") {
      list(type = "Wellness Seeker", icon = icon("heart"), color = "#FF6B6B", description = "You prioritize health and relaxation in your travels!")
    } else if (dominant == "practical_traveler") {
      list(type = "Practical Traveler", icon = icon("map-signs"), color = "#FF8C00", description = "You're organized and plan your trips carefully!")
    } else {
      # Default fallback
      list(
        type = "Melbourne Adventurer",
        icon = icon("star"),
        color = "#036B55",
        description = "You're discovering the many faces of Melbourne!"
      )
    }
  })
  
  # Outputs with safety checks
  output$personality_title <- renderText({
    data <- personality_data()
    if (is.null(data)) return("You are a Melbourne Explorer!")
    paste("You are a", data$type, "!")
  })
  
  output$personality_icon <- renderUI({
    data <- personality_data()
    if (is.null(data)) return(div(icon("binoculars"), style = "color: #036B55; font-size: 2.5em;"))
    div(style = paste0("color:", data$color, "; font-size: 2.5em;"),
        data$icon)
  })
  
  output$personality_description <- renderText({
    data <- personality_data()
    if (is.null(data)) return("Start clicking categories to discover your Melbourne personality!")
    data$description
  })
  
  output$debug_outputs <- renderText({
    clicks <- list(
      accommodation = user_behavior$category_clicks$accommodation,
      transport = user_behavior$category_clicks$transport,
      attractions = user_behavior$category_clicks$attractions,
      arts_culture = user_behavior$category_clicks$arts_culture,
      food_drink = user_behavior$category_clicks$food_drink,
      heritage = user_behavior$category_clicks$heritage,
      leisure = user_behavior$category_clicks$leisure,
      public_service = user_behavior$category_clicks$public_service,
      shopping = user_behavior$category_clicks$shopping,
      health_services = user_behavior$category_clicks$health_services
    )
    paste("Clicks:", paste(names(clicks), clicks, collapse = ", "))
  })
  
  # Placeholder handlers
  observeEvent(input$export_pdf, {
    showNotification("PDF export will be implemented soon!", type = "message")
  })
  
  observeEvent(input$prev_image, {
    showNotification("Previous image - carousel to be implemented")
  })
  
  observeEvent(input$next_image, {
    showNotification("Next image - carousel to be implemented") 
  })
}