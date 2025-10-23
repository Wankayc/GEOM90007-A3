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
        background-color: #e9ecef;
        color: #343a40;
        border: 1px solid #ced4da;
        border-radius: 25px;
        padding: 10px 20px;
        text-align: center;
        cursor: pointer;
        margin-bottom: 25px;
        display: inline-block;
        font-weight: normal;
        font-size: 1rem;
      }
      
      #summary-tab-content .main-title {
        font-weight: 700;
        color: #343a40;
        margin-bottom: 25px;
      }

      #summary-tab-content .custom-card {
        background-color: #ffffff;
        border: 1px solid #dee2e6;
        color: #212529;
        border-radius: 15px;
        padding: 20px;
        margin-bottom: 25px;
      }
      
      #summary-tab-content .custom-card h4 {
        font-weight: 600;
        margin-bottom: 20px;
        color: #343a40;
      }

      #summary-tab-content .carousel-content {
        display: flex;
        align-items: center;
        justify-content: space-between;
      }

      #summary-tab-content .carousel-image {
        text-align: center;
        padding: 0 10px;
      }
      #summary-tab-content .carousel-image img {
        width: 100%;
        border-radius: 10px;
        height: 150px;
        object-fit: cover;
      }
      #summary-tab-content .carousel-image p {
        margin-top: 10px;
        font-weight: 500;
        color: #212529;
      }

      #summary-tab-content .itinerary-table {
        width: 100%;
        border-collapse: separate;
        border-spacing: 4px;
      }
      #summary-tab-content .itinerary-table th, 
      #summary-tab-content .itinerary-table td {
        background-color: #ffffff;
        border: 1px solid #dee2e6;
        color: #212529;
        text-align: center;
        vertical-align: top;
        padding: 10px;
      }
      #summary-tab-content .itinerary-table th {
        font-weight: normal;
        padding-bottom: 15px;
      }
      #summary-tab-content .itinerary-table .weather-icon {
        font-size: 2em;
        margin-bottom: 8px;
        color: #495057;
      }
      #summary-tab-content .itinerary-table .day-date {
        font-weight: bold;
      }
      #summary-tab-content .itinerary-table td {
        height: 150px;
      }
      #summary-tab-content .itinerary-table .event-title {
        font-weight: bold;
        margin-bottom: 5px;
      }
      #summary-tab-content .itinerary-table .event-time {
        font-size: 0.9em;
        color: #6c757d;
      }

      #summary-tab-content .personality-card {
        background-color: #ffffff;
        color: #282c34;
        border-radius: 25px;
        padding: 20px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 25px;
        border: 1px solid #dee2e6;
        transition: all 0.3s ease;
      }
      #summary-tab-content .personality-card h4 {
        font-weight: bold;
        margin: 0 0 8px 0;
      }
      #summary-tab-content .personality-card .personality-icon {
        font-size: 2.5em;
        transition: all 0.3s ease;
      }
      #summary-tab-content .personality-description {
        margin: 0;
        color: #666;
        font-size: 0.9em;
        line-height: 1.4;
      }

      #summary-tab-content .pdf-preview {
        background-color: #f8f9fa;
        border: 1px dashed #ced4da;
        border-radius: 15px;
        height: 460px;
        padding: 15px;
        color: #495057;
        overflow-y: auto;
      }
      #summary-tab-content .pdf-preview h5 {
        font-weight: 600;
        color: #343a40;
        border-bottom: 1px solid #dee2e6;
        padding-bottom: 10px;
        margin-bottom: 10px;
      }
      #summary-tab-content .pdf-preview p {
        font-size: 0.9em;
        line-height: 1.6;
      }
    "))
    ),
    
    h2("Your Melbourne Exploration Summary", class = "main-title"),
    
    fluidRow(
      column(
        8,
        div(
          class = "custom-card",
          h4("Places to visit based on your searches"),
          div(
            class = "carousel-content",
            actionButton("prev_image", icon("chevron-left"), class = "carousel-arrow"),
            div(
              style="width: 100%;",
              fluidRow(
                column(4, class="carousel-image",
                       tags$img(src = "https://www.onlymelbourne.com.au/wp-content/uploads/2023/10/melbourne-museum.jpg"), 
                       tags$p("Melbourne Museum")
                ),
                column(4, class="carousel-image",
                       tags$img(src = "https://www.onlymelbourne.com.au/wp-content/uploads/2023/10/fitzroy-gardens.jpg"), 
                       tags$p("Appleseed Park")
                ),
                column(4, class="carousel-image",
                       tags$img(src = "https://www.onlymelbourne.com.au/wp-content/uploads/2023/10/royal-exhibition-building.jpg"), 
                       tags$p("Royal Exhibition Building")
                )
              )
            ),
            actionButton("next_image", icon("chevron-right"), class = "carousel-arrow")
          )
        ),
        
        h4("Suggested Itinerary", style = "font-weight: 600; margin-bottom: 20px; margin-top: 10px; color: #343a40;"),
        tags$table(
          class = "itinerary-table",
          tags$thead(
            tags$tr(
              tags$th(div(class="weather-icon", icon("cloud-sun")), div(class="day-date", "Monday"), div("24th Sep")),
              tags$th(div(class="weather-icon", icon("sun")), div(class="day-date", "Tuesday")),
              tags$th(div(class="weather-icon", icon("cloud-sun-rain")), div(class="day-date", "Wednesday")),
              tags$th(div(class="weather-icon", icon("cloud-sun")), div(class="day-date", "Thursday")),
              tags$th(div(class="weather-icon", icon("sun")), div(class="day-date", "Friday")),
              tags$th(div(class="weather-icon", icon("cloud-showers-heavy")), div(class="day-date", "Saturday")),
              tags$th(div(class="weather-icon", icon("cloud")), div(class="day-date", "Sunday"))
            )
          ),
          tags$tbody(
            tags$tr(
              tags$td(div(class="event-title", "Brunetti Flinders Lane"), div(class="event-time", "12am")),
              tags$td(div(class="event-title", "Victoria Park"), div(class="event-time", "(barbecue spot)")),
              tags$td(div(class="event-title", "State Library")),
              tags$td(),
              tags$td(div(class="event-title", "Italian Restaurant"), div(class="event-time", "6pm")),
              tags$td(),
              tags$td()
            )
          )
        )
      ),
      
      column(
        4,
        # Personality Card
        div(
          class = "personality-card",
          style = "display: flex; align-items: center; justify-content: space-between; min-height: 120px;",
          div(
            style = "flex: 1;",
            h4(textOutput("personality_title", inline = TRUE)),
            p(textOutput("personality_description"), class = "personality-description")
          ),
          div(
            uiOutput("personality_icon")
          )
        ),
        
        actionButton("export_pdf", "Export itinerary as pdf", class = "export-button"),
        
        div(
          class = "pdf-preview",
          h5("Itinerary pdf preview"),
          tags$p(strong("Monday:"), " 12:00 AM - Brunetti Flinders Lane"),
          tags$p(strong("Tuesday:"), " All Day - Victoria Park (barbecue spot)"),
          tags$p(strong("Wednesday:"), " All Day - State Library"),
          tags$p(strong("Friday:"), " 6:00 PM - Italian Restaurant")
        )
      )
    )
)