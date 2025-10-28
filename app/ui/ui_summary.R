div(id = "summary-tab-content",
    
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
      
      /* RESPONSIVE ITINERARY - SCALES BASED ON CONTENT */
      #summary-tab-content .itinerary-scroll-container {
        width: 100%;
        overflow-x: auto;
        padding-bottom: 15px;
        border: 1px solid #e9ecef;
        border-radius: 10px;
        background: #fafafa;
        min-height: 280px;
      }
      
      /* Default table styling */
      #summary-tab-content .itinerary-table.simplified {
        width: 100%;
        border-collapse: separate;
        border-spacing: 12px;
        font-size: 1.05rem;
      }
      
      /* Header styling */
      #summary-tab-content .itinerary-table.simplified th {
        padding: 20px 16px;
        text-align: center;
        background: #f8f9fa;
        border-bottom: 2px solid #dee2e6;
        font-weight: 600;
        min-width: 160px;
        position: sticky;
        top: 0;
        z-index: 10;
      }
      
      /* Cell styling */
      #summary-tab-content .itinerary-table.simplified td {
        padding: 0;
        text-align: center;
        vertical-align: top;
        border-bottom: 1px solid #e9ecef;
        min-width: 160px;
        height: 200px;
      }
      
      /* Weather and day styling */
      #summary-tab-content .itinerary-table.simplified .weather-icon {
        font-size: 2em;
        margin-bottom: 8px;
        color: #036B55;
      }
      #summary-tab-content .itinerary-table.simplified .day-date {
        font-weight: 700;
        font-size: 1.1em;
        margin-bottom: 4px;
        color: #036B55;
      }
      #summary-tab-content .itinerary-table.simplified .date-number {
        font-size: 0.95em;
        color: #6c757d;
        font-weight: 500;
      }
      
      /* Activity styling with larger fonts */
      #summary-tab-content .itinerary-table.simplified .top-activity {
        padding: 16px 14px;
        background: #f0f7ff;
        border-radius: 10px;
        border-left: 4px solid #036B55;
        text-align: left;
        min-height: 150px;
        display: flex;
        flex-direction: column;
        justify-content: center;
        margin: 0 6px;
      }
      #summary-tab-content .itinerary-table.simplified .top-activity .event-title {
        font-weight: 700;
        font-size: 1.1em;
        margin-bottom: 10px;
        color: #036B55;
        line-height: 1.3;
      }
      #summary-tab-content .itinerary-table.simplified .top-activity .event-time {
        font-size: 1em;
        color: #666;
        margin-bottom: 8px;
        font-weight: 600;
      }
      #summary-tab-content .itinerary-table.simplified .top-activity .event-location {
        font-size: 0.95em;
        color: #888;
        line-height: 1.4;
      }
      #summary-tab-content .itinerary-table.simplified .no-activities {
        padding: 40px 20px;
        text-align: center;
        font-size: 1em;
        color: #999;
        font-style: italic;
      }

      /* Scrollbar styling */
      #summary-tab-content .itinerary-scroll-container::-webkit-scrollbar {
        height: 10px;
      }
      #summary-tab-content .itinerary-scroll-container::-webkit-scrollbar-track {
        background: #f1f1f1;
        border-radius: 5px;
        margin: 0 15px;
      }
      #summary-tab-content .itinerary-scroll-container::-webkit-scrollbar-thumb {
        background: #c1c1c1;
        border-radius: 5px;
      }
      #summary-tab-content .itinerary-scroll-container::-webkit-scrollbar-thumb:hover {
        background: #a8a8a8;
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
      
      /* Responsive behavior - only scroll when needed */
      @media (min-width: 1200px) {
        #summary-tab-content .itinerary-scroll-container {
          overflow-x: visible;
        }
        #summary-tab-content .itinerary-table.simplified {
          min-width: auto;
        }
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
    
    # Itinerary Section - Responsive scaling
    div(
      class = "itinerary-section",
      h4("Your Recommended Itinerary"),
      div(
        class = "itinerary-scroll-container",
        uiOutput("itinerary_table")
      )
    )
)