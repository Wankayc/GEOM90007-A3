div(id = "summary-tab-content",
    
    # Placeholder UI for summary tab
    tags$head(
      tags$style(HTML("
      #summary-tab-content {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        padding: 20px;
      }

      #summary-tab-content .carousel-arrow {
        background: none;
        border: none;
        box-shadow: none;
        font-size: 2em;
        color: #343a40;
        cursor: pointer;
      }
      #summary-tab-content .export-button {
        background-color: #036B55;
        color: white;
        border: none;
        border-radius: 25px;
        padding: 12px 30px;
        text-align: center;
        cursor: pointer;
        display: inline-block;
        font-weight: 600;
        font-size: 1.1rem;
        transition: all 0.3s ease;
        margin: 15px 0;
      }
      #summary-tab-content .export-button:hover {
        background-color: #024d3d;
        transform: translateY(-2px);
        box-shadow: 0 4px 8px rgba(0,0,0,0.2);
      }
      
      #summary-tab-content .main-title {
        font-weight: 700;
        color: #036B55;
        margin-bottom: 12px;
        font-size: 2.8rem;
      }
      
      #summary-tab-content .subtitle {
        color: #666;
        font-size: 1.6rem;
        margin-bottom: 25px;
        line-height: 1.5;
        font-weight: 400;
      }

      #summary-tab-content .custom-card {
        background-color: #ffffff;
        border: 1px solid #dee2e6;
        color: #212529;
        border-radius: 15px;
        padding: 25px;
        margin-bottom: 25px;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      }
      
      #summary-tab-content .custom-card h4 {
        font-weight: 600;
        margin-bottom: 20px;
        color: #343a40;
        font-size: 1.4rem;
      }

      #summary-tab-content .carousel-content {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin: 15px 0;
      }

      #summary-tab-content .carousel-image {
        text-align: center;
        padding: 0 15px;
      }
      #summary-tab-content .carousel-image img {
        width: 100%;
        border-radius: 10px;
        height: 200px;
        object-fit: cover;
        box-shadow: 0 2px 8px rgba(0,0,0,0.15);
      }
      #summary-tab-content .carousel-image p {
        margin-top: 12px;
        font-weight: 600;
        color: #212529;
        font-size: 1.1rem;
      }

      #summary-tab-content .personality-card {
        background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
        border-radius: 15px;
        padding: 20px;
        border-left: 5px solid #036B55;
        display: flex;
        align-items: center;
        justify-content: space-between;
        height: 100%;
      }
      #summary-tab-content .personality-content {
        flex: 1;
      }
      #summary-tab-content .personality-card h3 {
        font-weight: 700;
        margin: 0 0 10px 0;
        color: #036B55;
        font-size: 1.8rem;
      }
      #summary-tab-content .personality-description {
        margin: 0;
        color: #666;
        font-size: 1rem;
        line-height: 1.4;
      }
      #summary-tab-content .personality-icon {
        font-size: 3em;
        color: #036B55;
        margin-left: 15px;
      }

      #summary-tab-content .title-section {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 25px;
      }
      #summary-tab-content .title-main {
        flex: 1;
      }
      #summary-tab-content .title-personality {
        width: 400px;
        margin-left: 30px;
      }

      #summary-tab-content .itinerary-section {
        background-color: #ffffff;
        border: 1px solid #dee2e6;
        border-radius: 15px;
        padding: 30px;
        margin-top: 25px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      }
      #summary-tab-content .itinerary-section h4 {
        font-weight: 600;
        margin-bottom: 25px;
        color: #343a40;
        font-size: 1.5rem;
        text-align: center;
      }
      #summary-tab-content .itinerary-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 6px;
        font-size: 1.05rem;
      }
      #summary-tab-content .itinerary-table th, 
      #summary-tab-content .itinerary-table td {
        background-color: #ffffff;
        border: 2px solid #dee2e6;
        color: #212529;
        text-align: center;
        vertical-align: top;
        padding: 15px;
        border-radius: 8px;
      }
      #summary-tab-content .itinerary-table th {
        font-weight: 600;
        padding-bottom: 20px;
        background-color: #f8f9fa;
      }
      #summary-tab-content .itinerary-table .weather-icon {
        font-size: 2.2em;
        margin-bottom: 10px;
        color: #036B55;
      }
      #summary-tab-content .itinerary-table .day-date {
        font-weight: bold;
        font-size: 1.1rem;
      }
      #summary-tab-content .itinerary-table td {
        height: 180px;
        vertical-align: top;
      }
      #summary-tab-content .itinerary-table .event-title {
        font-weight: bold;
        margin-bottom: 8px;
        font-size: 1.1rem;
        color: #036B55;
      }
      #summary-tab-content .itinerary-table .event-time {
        font-size: 1rem;
        color: #6c757d;
      }
      #summary-tab-content .itinerary-table .event-location {
        font-size: 0.95rem;
        color: #495057;
        margin-top: 5px;
      }

      /* Combined top section styling */
      #summary-tab-content .top-combined-section {
        background-color: #ffffff;
        border: 1px solid #dee2e6;
        border-radius: 15px;
        padding: 30px;
        margin-bottom: 30px;
        box-shadow: 0 2px 8px rgba(0,0,0,0.1);
      }
    "))
    ),
    
    # Title Section with Personality Card
    div(
      class = "title-section",
      div(
        class = "title-main",
        h2("Your Melbourne Exploration Summary", class = "main-title"),
        p("Explore different categories in other tabs to build your personalized recommendations and itinerary", 
          class = "subtitle")
      ),
      div(
        class = "title-personality",
        div(
          class = "personality-card",
          div(
            class = "personality-content",
            h3(textOutput("personality_title")),
            p(textOutput("personality_description"), class = "personality-description")
          ),
          div(
            uiOutput("personality_icon", class = "personality-icon")
          )
        )
      )
    ),
    
    # Combined Top Section - Full width carousel
    div(
      class = "top-combined-section",
      # Carousel Section - Full width
      div(
        class = "custom-card",
        h4("Recommended Places Based on Your Searches"),
        div(
          class = "carousel-content",
          actionButton("prev_image", icon("chevron-left"), class = "carousel-arrow"),
          div(
            style = "width: 100%;",
            fluidRow(
              column(4, class = "carousel-image",
                     tags$img(src = "https://www.onlymelbourne.com.au/wp-content/uploads/2023/10/melbourne-museum.jpg"), 
                     tags$p("Melbourne Museum")
              ),
              column(4, class = "carousel-image",
                     tags$img(src = "https://www.onlymelbourne.com.au/wp-content/uploads/2023/10/fitzroy-gardens.jpg"), 
                     tags$p("Appleseed Park")
              ),
              column(4, class = "carousel-image",
                     tags$img(src = "https://www.onlymelbourne.com.au/wp-content/uploads/2023/10/royal-exhibition-building.jpg"), 
                     tags$p("Royal Exhibition Building")
              )
            )
          ),
          actionButton("next_image", icon("chevron-right"), class = "carousel-arrow")
        )
      ),
      
      # Download Summary Button - Centered
      fluidRow(
        column(
          12,
          style = "text-align: center; margin-top: 10px;",
          actionButton("export_pdf", "Download Summary PDF", class = "export-button")
        )
      )
    ),
    
    # Itinerary Section - Full width and larger at bottom
    div(
      class = "itinerary-section",
      h4("Your Recommended Itinerary"),
      tags$table(
        class = "itinerary-table",
        tags$thead(
          tags$tr(
            tags$th(div(class = "weather-icon", icon("cloud-sun")), div(class = "day-date", "Monday"), div("24th Sep")),
            tags$th(div(class = "weather-icon", icon("sun")), div(class = "day-date", "Tuesday"), div("25th Sep")),
            tags$th(div(class = "weather-icon", icon("cloud-sun-rain")), div(class = "day-date", "Wednesday"), div("26th Sep")),
            tags$th(div(class = "weather-icon", icon("cloud-sun")), div(class = "day-date", "Thursday"), div("27th Sep")),
            tags$th(div(class = "weather-icon", icon("sun")), div(class = "day-date", "Friday"), div("28th Sep")),
            tags$th(div(class = "weather-icon", icon("cloud-showers-heavy")), div(class = "day-date", "Saturday"), div("29th Sep")),
            tags$th(div(class = "weather-icon", icon("cloud")), div(class = "day-date", "Sunday"), div("30th Sep"))
          )
        ),
        tags$tbody(
          tags$tr(
            tags$td(
              div(class = "event-title", "Brunetti Flinders Lane"), 
              div(class = "event-time", "12:00 PM"),
              div(class = "event-location", "Italian Cafe & Pastries")
            ),
            tags$td(
              div(class = "event-title", "Victoria Park"), 
              div(class = "event-time", "All Day"),
              div(class = "event-location", "Barbecue & Picnic Spot")
            ),
            tags$td(
              div(class = "event-title", "State Library Victoria"), 
              div(class = "event-time", "10:00 AM - 4:00 PM"),
              div(class = "event-location", "Historic Library & Exhibitions")
            ),
            tags$td(
              div(class = "event-title", "Fitzroy Gardens"), 
              div(class = "event-time", "All Day"),
              div(class = "event-location", "Botanical Gardens")
            ),
            tags$td(
              div(class = "event-title", "Italian Restaurant"), 
              div(class = "event-time", "6:00 PM"),
              div(class = "event-location", "Fine Dining Experience")
            ),
            tags$td(
              div(class = "event-title", "Queen Victoria Market"), 
              div(class = "event-time", "9:00 AM - 2:00 PM"),
              div(class = "event-location", "Local Market & Food Stalls")
            ),
            tags$td(
              div(class = "event-title", "Melbourne Museum"), 
              div(class = "event-time", "10:00 AM - 5:00 PM"),
              div(class = "event-location", "Cultural & Natural History")
            )
          )
        )
      )
    )
)