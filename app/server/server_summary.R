summary_server <- function(input, output, session, user_behavior, weather_module = NULL) {
  
  # Get weather data from the global environment or module
  weather_data <- reactive({
    if (exists("calendar_feed")) {
      calendar_feed
    } else {
      # Fallback data structure
      data.frame(
        date = as.Date(character()),
        tmin = numeric(),
        tmax = numeric(),
        rain = numeric(),
        pm25_mean = numeric(),
        averagewindspeed_bom = numeric(),
        sun = numeric(),
        pm10_mean = numeric(),
        stringsAsFactors = FALSE
      )
    }
  })
  
  # Get selected dates from weather module - default to current week if none selected
  selected_dates <- reactive({
    # Try to get dates from weather module first
    if (!is.null(weather_module)) {
      weather_dates <- weather_module$selected_dates()
      if (length(weather_dates) > 0) {
        return(weather_dates)
      }
    }
    
    # Fallback: try session userData
    if (!is.null(session$userData$weather_dates)) {
      return(session$userData$weather_dates)
    }
    
    # Default: use current week (today + next 6 days)
    today <- Sys.Date()
    seq(today, today + 6, by = "day")
  })
  
  # Simple wrapper that uses shared function
  get_weather_for_date_safe <- function(date) {
    tryCatch({
      get_weather_for_date(date, weather_data())
    }, error = function(e) {
      list(emoji = "⛅️", label = "Cloudy", temp_min = NA, temp_max = NA, rain = NA)
    })
  }
  
  # Track clicked day for carousel
  clicked_day <- reactiveVal(1)
  
  # Store itinerary data separately to prevent re-rendering
  itinerary_data <- reactiveValues(
    activities = list(),
    last_updated = NULL
  )
  
  # Update itinerary data only when dates or user behavior changes
  observe({
    dates <- selected_dates()
    if (length(dates) > 0) {
      activities_list <- lapply(dates, function(date) {
        tryCatch({
          get_activities_for_date(date, user_behavior)
        }, error = function(e) {
          list()
        })
      })
      itinerary_data$activities <- activities_list
      itinerary_data$last_updated <- Sys.time()
    }
  })
  
  # OPTION 1: Simplified itinerary showing only top activity per day
  output$itinerary_table <- renderUI({
    dates <- selected_dates()
    
    # Validate we have dates
    if (length(dates) == 0) {
      return(div("No dates selected", style = "color: #999; font-style: italic;"))
    }
    
    # Use stored activities to prevent re-rendering
    activities_list <- itinerary_data$activities
    
    tags$table(
      class = "itinerary-table simplified",
      tags$thead(
        tags$tr(
          lapply(seq_along(dates), function(i) {
            date <- dates[i]
            weather <- get_weather_for_date_safe(date)
            tags$th(
              `data-day` = i,
              class = paste("itinerary-day-header", if(i == clicked_day()) "active-day" else ""),
              style = "cursor: pointer; padding: 15px;",
              div(class = "weather-icon", weather$emoji),
              div(class = "day-date", format(date, "%A")),
              div(class = "date-number", format(date, "%d %b"))
            )
          })
        )
      ),
      tags$tbody(
        tags$tr(
          lapply(seq_along(dates), function(i) {
            date <- dates[i]
            activities <- if (length(activities_list) >= i) activities_list[[i]] else list()
            
            # Take only the first (top) activity
            top_activity <- if (length(activities) > 0) activities[[1]] else NULL
            
            tags$td(
              `data-day` = i,
              class = paste("itinerary-day-cell", if(i == clicked_day()) "active-day" else ""),
              style = "cursor: pointer; padding: 0;",
              if (!is.null(top_activity)) {
                div(
                  class = "top-activity",
                  div(class = "event-title", top_activity$name),
                  div(class = "event-time", top_activity$time),
                  div(class = "event-location", top_activity$location)
                )
              } else {
                div(
                  class = "no-activities",
                  "No activities planned",
                  style = "color: #999; font-style: italic; padding: 40px 20px;"
                )
              }
            )
          })
        )
      )
    )
  })
  
  # Observe day clicks for carousel - ONLY updates highlighting via JavaScript
  observeEvent(input$day_clicked, {
    clicked_day(input$day_clicked)
    cat("Day clicked:", input$day_clicked, "\n")
    
    # Update highlighting via JavaScript instead of re-rendering
    session$sendCustomMessage("highlight_day", input$day_clicked)
  })
  
  # Carousel data reactive - NOW RETURNS ALL RELATED PLACES
  carousel_data <- reactive({
    day <- clicked_day()
    cat("Carousel data requested for day:", day, "\n")
    
    dates <- selected_dates()
    if (length(dates) >= day) {
      date <- dates[day]
      
      # Use stored activities instead of re-fetching
      activities <- if (length(itinerary_data$activities) >= day) {
        itinerary_data$activities[[day]]
      } else {
        list()
      }
      
      cat("Activities found:", length(activities), "\n")
      
      if (length(activities) > 0) {
        # Get the main activity for that day
        main_activity <- activities[[1]]$name
        cat("Main activity:", main_activity, "\n")
        
        # Find related places from theme_data (excluding the main activity)
        related_places <- theme_data %>%
          filter(Name != main_activity) %>%
          # Find places with similar themes or categories
          mutate(
            is_related = grepl(main_activity, Name, ignore.case = TRUE) |
              Sub_Theme == activities[[1]]$location |
              Theme %in% get_related_themes(activities[[1]]$location)
          ) %>%
          filter(is_related) %>%
          head(9)  # Get up to 9 related places for 3 pages of 3 items
        
        cat("Related places found:", nrow(related_places), "\n")
        
        return(list(
          main_activity = main_activity,
          related_places = related_places,
          date = date,
          day_name = format(date, "%A")
        ))
      }
    }
    return(NULL)
  })
  
  # Helper function to get related themes
  get_related_themes <- function(location_desc) {
    theme_map <- list(
      "Park" = c("Parks & Gardens", "Leisure"),
      "Market" = c("Shopping", "Markets", "Food & Drink"),
      "Restaurant" = c("Food & Drink", "Entertainment"),
      "Cafe" = c("Food & Drink"),
      "Shopping" = c("Shopping", "Markets"),
      "Arts" = c("Arts & Culture", "Heritage"),
      "Entertainment" = c("Entertainment", "Arts & Culture")
    )
    
    for (key in names(theme_map)) {
      if (grepl(key, location_desc, ignore.case = TRUE)) {
        return(theme_map[[key]])
      }
    }
    return(c("Attractions", "Leisure"))  # Default fallback
  }
  
  # Carousel page management (each page shows 3 items)
  carousel_page <- reactiveVal(1)
  
  # Reset carousel when new day is clicked
  observeEvent(clicked_day(), {
    carousel_page(1)
    cat("Carousel page reset to 1\n")
  })
  
  # Calculate total pages
  total_pages <- reactive({
    data <- carousel_data()
    if (is.null(data) || nrow(data$related_places) == 0) return(1)
    ceiling(nrow(data$related_places) / 3)
  })
  
  # Get current page items (3 items per page)
  current_page_items <- reactive({
    data <- carousel_data()
    if (is.null(data) || nrow(data$related_places) == 0) return(NULL)
    
    current_page <- carousel_page()
    start_index <- (current_page - 1) * 3 + 1
    end_index <- min(start_index + 2, nrow(data$related_places))
    
    data$related_places[start_index:end_index, ]
  })
  
  # Carousel navigation
  observeEvent(input$carousel_prev, {
    current <- carousel_page()
    if (current > 1) {
      carousel_page(current - 1)
      cat("Carousel prev: page", current, "->", current - 1, "\n")
    }
  })
  
  observeEvent(input$carousel_next, {
    current <- carousel_page()
    if (current < total_pages()) {
      carousel_page(current + 1)
      cat("Carousel next: page", current, "->", current + 1, "\n")
    }
  })
  
  # Carousel output - NOW SHOWS 3 ITEMS PER PAGE
  output$activity_carousel <- renderUI({
    data <- carousel_data()
    
    if (is.null(data)) {
      return(div(
        class = "carousel-placeholder",
        h4("✨ Discover Related Places"),
        p("Click on any day in your itinerary to see places related to that day's main activity!")
      ))
    }
    
    if (nrow(data$related_places) == 0) {
      return(div(
        class = "no-related-places",
        h4("No related places found"),
        p("We couldn't find any related places for this activity")
      ))
    }
    
    current_items <- current_page_items()
    current_page <- carousel_page()
    total_pages_val <- total_pages()
    
    tagList(
      # Simple header showing what day was clicked
      div(
        class = "carousel-header",
        h4("💫 ", format(data$date, "%A"), " - ", format(data$date, "%d %B"))
      ),
      
      # The carousel itself with 3 items
      div(
        class = "carousel-container",
        
        # Carousel items container
        div(
          class = "carousel-items-container",
          lapply(1:nrow(current_items), function(i) {
            place <- current_items[i, ]
            
            # Format hours to 12-hour AM/PM format
            formatted_hours <- if (!is.na(place$opening_time) && !is.na(place$closing_time)) {
              open_time <- format(strptime(place$opening_time, "%H:%M"), "%I:%M %p")
              close_time <- format(strptime(place$closing_time, "%H:%M"), "%I:%M %p")
              paste(open_time, "-", close_time)
            } else {
              NULL
            }
            
            div(
              class = "carousel-item",
              h5(place$Name),
              div(class = "place-category", place$Theme, " • ", place$Sub_Theme),
              if (!is.na(place$Google_Rating)) {
                div(class = "place-rating", paste("⭐", round(place$Google_Rating, 1), "/5"))
              },
              if (!is.null(formatted_hours)) {
                div(class = "place-hours", formatted_hours)
              },
              if (!is.null(place$Business_address) && !is.na(place$Business_address) && place$Business_address != "") {
                div(class = "place-address", place$Business_address)
              }
            )
          })
        ),
        
        # Simple navigation
        div(
          class = "carousel-nav",
          actionButton("carousel_prev", "◀ Previous", 
                       class = "carousel-nav-button",
                       disabled = current_page == 1),
          span(class = "carousel-page-info",
               paste(current_page, "of", total_pages_val)),
          actionButton("carousel_next", "Next ▶", 
                       class = "carousel-nav-button",
                       disabled = current_page == total_pages_val)
        )
      )
    )
  })
  
  # Helper function for theme emojis
  get_theme_emoji <- function(theme) {
    emoji_map <- list(
      "Food & Drink" = "🍽️",
      "Parks & Gardens" = "🌳",
      "Arts & Culture" = "🎨",
      "Shopping" = "🛍️",
      "Attractions" = "🏛️",
      "Leisure" = "🎯",
      "Heritage" = "🏰",
      "Markets" = "🛒",
      "Entertainment" = "🎭"
    )
    return(emoji_map[[theme]] %||% "📍")
  }
  
  # Generate fun facts based on place type
  generate_fun_fact <- function(place) {
    facts <- list(
      "Food & Drink" = c(
        "💡 Local tip: Try their signature coffee blend!",
        "🍴 Popular dish: Ask for the daily special",
        "⏰ Best time: Avoid lunch rush at 12:30-1:30pm",
        "🌟 Hidden gem: Locals love their breakfast menu"
      ),
      "Parks & Gardens" = c(
        "🌼 Perfect for: Picnics and morning walks",
        "📸 Photo spot: Great for landscape photography",
        "🕊️ Wildlife: Look out for local bird species",
        "🌅 Best time: Golden hour for amazing photos"
      ),
      "Arts & Culture" = c(
        "🎭 Insider tip: Check for free guided tours",
        "📅 Current exhibit: Ask about temporary displays",
        "🖼️ Don't miss: The main gallery collection",
        "🎨 Local artists: Support local talent in gift shop"
      ),
      "Shopping" = c(
        "🛍️ Best finds: Look for local designer items",
        "💫 Hidden gems: Explore the smaller boutiques",
        "🕒 Quiet times: Weekday mornings are less crowded",
        "🎁 Souvenirs: Perfect for unique Melbourne gifts"
      )
    )
    
    theme_facts <- facts[[place$Theme]] %||% c(
      "🌟 Local favorite worth exploring!",
      "📅 Check online for current events",
      "💬 Visitors recommend planning 1-2 hours",
      "✨ Great spot to experience local culture"
    )
    
    return(sample(theme_facts, 1))
  }
  
  get_activities_for_date <- function(date, user_behavior) {
    activities <- list()
    
    tryCatch({
      # FIRST PRIORITY: Check if user has manually dragged activities for this date
      manual_activities <- list()
      if (!is.null(weather_module)) {
        manual_activities <- weather_module$get_activities_for_date(date)
      }
      
      # If user has manually selected activities, use those INSTEAD of personality recommendations
      if (length(manual_activities) > 0) {
        cat("Using manually selected activities for", as.character(date), "\n")
        return(manual_activities)
      }
      
      # Only proceed to personality-based recommendations if no manual activities
      day_of_week <- weekdays(date)
      weather <- get_weather_for_date_safe(date)
      
      # personality data retrieval
      personality_info <- personality_data()
      personality <- if (!is.null(personality_info) && !is.null(personality_info$type)) {
        personality_info$type
      } else {
        "Melbourne Explorer"
      }
      
      # Check if user has any clicks at all
      total_clicks <- 0
      if (!is.null(user_behavior) && !is.null(user_behavior$category_clicks)) {
        total_clicks <- sum(unlist(user_behavior$category_clicks), na.rm = TRUE)
      }
      
      # If user has no clicks, use DEFAULT activities from theme_data
      if (total_clicks == 0) {
        cat("No user data - using DEFAULT recommendations from theme_data for", as.character(date), "\n")
        
        # Get diverse activities from theme_data (no museums/hospitals/police stations)
        default_activities <- theme_data %>%
          filter(!Theme %in% c("Public Services", "Health Services", "Transport")) %>%
          filter(!grepl("museum|gallery|hospital|clinic|police|fire station", Name, ignore.case = TRUE)) %>%
          distinct(Name, .keep_all = TRUE) %>%
          sample_n(min(10, nrow(.)))  # Get 10 random diverse activities
        
        # Select 3 based on date for variety
        date_num <- as.numeric(date) %% nrow(default_activities)
        start_idx <- (date_num %% (nrow(default_activities) - 2)) + 1
        selected_places <- default_activities[start_idx:min(start_idx + 2, nrow(default_activities)), ]
        
      } else {
        # USER HAS DATA - Personality-based recommendations USING REAL theme_data
        cat("Using personality-based recommendations for", as.character(date), "\n")
        cat("Personality detected:", personality, "\n")
        
        # Use actual theme_data
        all_places <- theme_data %>%
          distinct(Name, .keep_all = TRUE)
        
        # Filter by personality type with date-based variation
        date_index <- which(selected_dates() == date)
        
        if (personality == "Urban Adventurer") {
          cat("Selecting urban activities for Urban Adventurer\n")
          selected_places <- all_places %>%
            filter(Theme %in% c("Attractions", "Shopping", "Food & Drink", "Arts & Culture", "Entertainment")) %>%
            filter(!grepl("fire station|police station|hospital|clinic", Name, ignore.case = TRUE)) %>%
            sample_n(min(3, nrow(.)))
          
        } else if (personality == "Practical Traveler") {
          cat("Selecting practical activities for Practical Traveler\n")
          selected_places <- all_places %>%
            filter(Theme %in% c("Shopping", "Food & Drink", "Attractions", "Transport", "Markets")) %>%
            filter(!grepl("fire station|police station|hospital|clinic|bus stop|train station", 
                          Name, ignore.case = TRUE)) %>%
            sample_n(min(3, nrow(.)))
          
        } else if (personality == "Wellness Seeker") {
          cat("Selecting wellness activities for Wellness Seeker\n")
          selected_places <- all_places %>%
            filter(Theme %in% c("Leisure", "Parks & Gardens", "Food & Drink", "Attractions")) %>%
            filter(!grepl("fire station|police station|hospital|clinic", Name, ignore.case = TRUE)) %>%
            sample_n(min(3, nrow(.)))
          
        } else if (personality == "Melbourne Explorer") {
          cat("Selecting diverse activities for Melbourne Explorer\n")
          selected_places <- all_places %>%
            filter(Theme %in% c("Arts & Culture", "Attractions", "Food & Drink", "Parks & Gardens", 
                                "Shopping", "Leisure", "Heritage", "Markets", "Entertainment")) %>%
            filter(!Theme %in% c("Transport", "Public Services", "Health Services")) %>%
            filter(!grepl("fire station|police station|hospital|clinic", Name, ignore.case = TRUE)) %>%
            sample_n(min(3, nrow(.)))
          
        } else if (personality == "Food Lover") {
          cat("Selecting food activities for Food Lover\n")
          selected_places <- all_places %>%
            filter(Theme == "Food & Drink") %>%
            sample_n(min(3, nrow(.)))
          
        } else if (personality == "Nature Enthusiast") {
          cat("Selecting outdoor activities for Nature Enthusiast\n")
          selected_places <- all_places %>%
            filter(Theme %in% c("Parks & Gardens", "Attractions", "Leisure")) %>%
            sample_n(min(3, nrow(.)))
          
        } else if (personality == "Culture Connoisseur") {
          cat("Selecting culture activities for Culture Connoisseur\n")
          selected_places <- all_places %>%
            filter(Theme %in% c("Arts & Culture", "Heritage", "Attractions")) %>%
            filter(!grepl("fire station|police station|hospital|clinic", Name, ignore.case = TRUE)) %>%
            sample_n(min(3, nrow(.)))
          
        } else {
          # Default for any other personality - safe tourist attractions only
          cat("Selecting safe default activities for", personality, "\n")
          selected_places <- all_places %>%
            filter(Theme %in% c("Arts & Culture", "Attractions", "Food & Drink", "Parks & Gardens", "Shopping")) %>%
            filter(!grepl("fire station|police station|hospital|clinic", Name, ignore.case = TRUE)) %>%
            sample_n(min(3, nrow(.)))
        }
      }
      
      # Convert selected places to activities
      if (nrow(selected_places) > 0) {
        activities <- lapply(1:nrow(selected_places), function(i) {
          place <- selected_places[i, ]
          
          place_name <- if (!is.null(place$Name)) place$Name else "Melbourne Activity"
          place_subtheme <- if (!is.null(place$Sub_Theme)) place$Sub_Theme else "Activity"
          place_rating <- if (!is.null(place$Google_Rating)) place$Google_Rating else NA
          
          # Create appropriate time slots based on place type and operating hours
          time_slot <- generate_time_slot(place, i)
          
          # Create location description
          location_desc <- place_subtheme
          if (!is.na(place_rating)) {
            location_desc <- paste(location_desc, "•", paste("⭐", round(place_rating, 1)))
          }
          
          list(
            name = place_name,
            time = time_slot,
            location = location_desc
          )
        })
      }
      
      return(activities)
      
    }, error = function(e) {
      cat("ERROR in get_activities_for_date:", e$message, "\n")
      cat("Date:", as.character(date), "Personality:", personality, "\n")
      
      # Fallback: get any 2 random activities from theme_data
      fallback_activities <- theme_data %>%
        filter(!Theme %in% c("Public Services", "Health Services")) %>%
        distinct(Name, .keep_all = TRUE) %>%
        sample_n(min(2, nrow(.)))
      
      if (nrow(fallback_activities) > 0) {
        return(lapply(1:nrow(fallback_activities), function(i) {
          place <- fallback_activities[i, ]
          list(
            name = place$Name,
            time = "10:00 AM - 5:00 PM",
            location = if (!is.null(place$Sub_Theme)) place$Sub_Theme else "Activity"
          )
        }))
      } else {
        # Ultimate fallback if theme_data is empty
        return(list(
          list(name = "Royal Botanic Gardens", time = "10:00 AM - 5:00 PM", location = "Park"),
          list(name = "Queen Victoria Market", time = "9:00 AM - 2:00 PM", location = "Market")
        ))
      }
    })
  }
  
  # Helper function to generate time slots based on place type and operating hours
  generate_time_slot <- function(place, index) {
    # Check if we have operating hours data
    has_hours <- !is.null(place$opening_time) && !is.na(place$opening_time) && 
      !is.null(place$closing_time) && !is.na(place$closing_time)
    
    if (has_hours) {
      # Use actual operating hours if available
      open_time <- format(strptime(place$opening_time, "%H:%M"), "%I:%M %p")
      close_time <- format(strptime(place$closing_time, "%H:%M"), "%I:%M %p")
      return(paste(open_time, "-", close_time))
    }
    
    # Fallback to intelligent time slots based on place type
    place_theme <- if (!is.null(place$Theme)) place$Theme else "Attractions"
    place_subtheme <- if (!is.null(place$Sub_Theme)) place$Sub_Theme else ""
    
    if (place_theme == "Food & Drink") {
      if (grepl("cafe|coffee|breakfast", place_subtheme, ignore.case = TRUE)) {
        time_slots <- c("7:00 AM - 9:00 AM", "9:00 AM - 11:00 AM", "3:00 PM - 5:00 PM")
      } else {
        time_slots <- c("12:00 PM - 2:00 PM", "1:00 PM - 3:00 PM", "6:00 PM - 8:00 PM", "7:00 PM - 9:00 PM")
      }
    } else if (place_theme == "Parks & Gardens") {
      time_slots <- c("6:00 AM - 9:00 AM", "10:00 AM - 12:00 PM", "2:00 PM - 4:00 PM", "4:00 PM - 6:00 PM")
    } else if (place_theme %in% c("Arts & Culture", "Heritage")) {
      time_slots <- c("10:00 AM - 12:00 PM", "11:00 AM - 1:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM")
    } else if (place_theme == "Shopping" || place_theme == "Markets") {
      time_slots <- c("9:00 AM - 11:00 AM", "10:00 AM - 12:00 PM", "2:00 PM - 4:00 PM", "3:00 PM - 5:00 PM")
    } else {
      # Default for attractions, leisure, etc.
      time_slots <- c("10:00 AM - 12:00 PM", "1:00 PM - 3:00 PM", "4:00 PM - 6:00 PM")
    }
    
    # Use index to pick different time slots for variety
    time_slot <- time_slots[(index - 1) %% length(time_slots) + 1]
    return(time_slot)
  }
  
  # Personality data with better validation
  personality_data <- reactive({
    tryCatch({
      # Validate user_behavior structure
      if (is.null(user_behavior) || is.null(user_behavior$category_clicks)) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("binoculars"),
          color = "#036B55", 
          description = "Start exploring Melbourne!"
        ))
      }
      
      # Get the current click counts safely
      clicks <- list(
        accommodation = user_behavior$category_clicks$accommodation %||% 0,
        transport = user_behavior$category_clicks$transport %||% 0,
        attractions = user_behavior$category_clicks$attractions %||% 0,
        arts_culture = user_behavior$category_clicks$arts_culture %||% 0,
        food_drink = user_behavior$category_clicks$food_drink %||% 0,
        heritage = user_behavior$category_clicks$heritage %||% 0,
        leisure = user_behavior$category_clicks$leisure %||% 0,
        public_service = user_behavior$category_clicks$public_service %||% 0,
        shopping = user_behavior$category_clicks$shopping %||% 0,
        health_services = user_behavior$category_clicks$health_services %||% 0
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
      
      # Safe max score calculation
      score_values <- unlist(scores)
      if (length(score_values) == 0 || all(is.na(score_values))) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("compass"),
          color = "#036B55",
          description = "You're exploring everything! Click more to reveal your favorite side of Melbourne."
        ))
      }
      
      max_score <- max(score_values, na.rm = TRUE)
      dominant <- names(scores)[which.max(score_values)]
      
      # Personality mapping
      total_clicks <- sum(unlist(clicks))
      if (total_clicks == 0) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("binoculars"),
          color = "#036B55", 
          description = "Start clicking categories to discover your Melbourne personality!"
        ))
      } else if (max_score == 0 || is.na(max_score) || max_score < 1) {
        return(list(
          type = "Melbourne Explorer",
          icon = icon("compass"),
          color = "#036B55",
          description = "You're exploring everything! Click more to reveal your favorite side of Melbourne."
        ))
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
        list(
          type = "Melbourne Adventurer",
          icon = icon("star"),
          color = "#036B55",
          description = "You're discovering the many faces of Melbourne!"
        )
      }
    }, error = function(e) {
      # Fallback if anything goes wrong
      return(list(
        type = "Melbourne Explorer",
        icon = icon("binoculars"),
        color = "#036B55",
        description = "Start exploring Melbourne!"
      ))
    })
  })
  
  # Personality outputs
  output$personality_title <- renderText({
    data <- personality_data()
    if (is.null(data)) return("You are a Melbourne Explorer!")
    paste("Based on your searches you are a", data$type, "!")
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
  
  # Placeholder handlers
  observeEvent(input$export_pdf, {
    showNotification("PDF export will be implemented soon!", type = "message")
  })
}