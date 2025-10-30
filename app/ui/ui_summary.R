<<<<<<< Updated upstream
div(id = "summary-tab-content",
    
    # Placeholder UI for summary tab
    tags$head(
      tags$style(HTML("
      #summary-tab-content {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        padding: 20px;
      }
=======
div(
  id = "summary-tab-content",
  
  tags$head(tags$style(
    HTML(
      "
        #summary-tab-content {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          padding: 20px;
        }
>>>>>>> Stashed changes

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

<<<<<<< Updated upstream
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
=======
        #summary-tab-content .itinerary-table.simplified {
          width: 100%;
          border-collapse: separate;
          border-spacing: 12px;
          font-size: 1.15rem;
        }

        #summary-tab-content .itinerary-table.simplified th {
          padding: 22px 18px;
          text-align: center;
          background: #f8f9fa;
          border-bottom: 2px solid #dee2e6;
          font-weight: 600;
          min-width: 160px;
          position: sticky;
          top: 0;
          z-index: 10;
          font-size: 1.1rem;
        }

        #summary-tab-content .itinerary-table.simplified td {
          padding: 0;
          text-align: center;
          vertical-align: top;
          border-bottom: 1px solid #e9ecef;
          min-width: 160px;
          height: 200px;
        }

        #summary-tab-content .itinerary-table.simplified .weather-icon {
          font-size: 2.2em;
          margin-bottom: 10px;
          color: #036B55;
        }
        #summary-tab-content .itinerary-table.simplified .day-date {
          font-weight: 700;
          font-size: 1.2em;
          margin-bottom: 6px;
          color: #036B55;
        }
        #summary-tab-content .itinerary-table.simplified .date-number {
          font-size: 1.05em;
          color: #6c757d;
          font-weight: 500;
        }

        #summary-tab-content .itinerary-table.simplified .top-activity {
          padding: 18px 16px;
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
          font-size: 1.15em;
          margin-bottom: 10px;
          color: #036B55;
          line-height: 1.3;
        }
        #summary-tab-content .itinerary-table.simplified .top-activity .event-time {
          font-size: 1.05em;
          color: #666;
          margin-bottom: 8px;
          font-weight: 600;
        }
        #summary-tab-content .itinerary-table.simplified .top-activity .event-location {
          font-size: 1em;
          color: #888;
          line-height: 1.4;
        }
        #summary-tab-content .itinerary-table.simplified .no-activities {
          padding: 40px 20px;
          text-align: center;
          font-size: 1.1rem;
          color: #999;
          font-style: italic;
        }

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

        #summary-tab-content .top-combined-section {
          background-color: #ffffff;
          border: 1px solid #dee2e6;
          border-radius: 15px;
          padding: 25px;
          margin-bottom: 20px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }

        #summary-tab-content .itinerary-day-header,
        #summary-tab-content .itinerary-day-cell {
          cursor: pointer;
          transition: all 0.2s ease;
        }
        #summary-tab-content .itinerary-day-header:hover,
        #summary-tab-content .itinerary-day-cell:hover {
          background-color: #f8f9fa;
          transform: translateY(-2px);
        }
        #summary-tab-content .itinerary-day-header:active,
        #summary-tab-content .itinerary-day-cell:active {
          transform: translateY(0);
        }

        /* Carousel */
        #summary-tab-content .carousel-section {
          margin-bottom: 20px;
        }

        #summary-tab-content .carousel-header {
          text-align: center;
          margin-bottom: 15px;
          padding: 15px;
          background: #f8f9fa;
          border-radius: 10px;
          border-left: 4px solid #036B55;
        }

        #summary-tab-content .carousel-header h4 {
          color: #036B55;
          margin: 0;
          font-size: 2rem;
          font-weight: 600;
        }

        #summary-tab-content .carousel-container {
          background: #ffffff;
          border: 1px solid #e9ecef;
          border-radius: 10px;
          padding: 20px;
          min-height: 350px;
        }

        #summary-tab-content .carousel-items-container {
          display: flex;
          gap: 15px;
          margin-bottom: 20px;
          min-height: 270px;
        }

        #summary-tab-content .carousel-item {
          flex: 1;
          background: #f8f9fa;
          border-radius: 8px;
          padding: 20px;
          border: 1px solid #e9ecef;
          text-align: left;
          display: flex;
          flex-direction: column;
          justify-content: flex-start;
          cursor: pointer;
          transition: all 0.3s ease;
          min-height: 280px;
        }

        #summary-tab-content .carousel-item:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 16px rgba(0,0,0,0.15);
        }

        #summary-tab-content .carousel-item h5 {
          color: #036B55;
          margin: 0 0 15px 0;
          font-size: 1.7rem;
          font-weight: 600;
          line-height: 1.3;
        }

        #summary-tab-content .carousel-item .place-category {
          color: #666;
          font-size: 1.5rem;
          margin-bottom: 15px;
          font-weight: 500;
        }

        #summary-tab-content .carousel-item .place-rating {
          color: #ffc107;
          font-size: 1.4rem;
          margin-bottom: 15px;
          font-weight: 600;
        }

        #summary-tab-content .carousel-item .place-hours {
          color: #888;
          font-size: 1.3rem;
          margin-bottom: 15px;
          font-weight: 500;
        }

        #summary-tab-content .carousel-item .place-address {
          color: #666;
          font-size: 1.2rem;
          line-height: 1.4;
          margin-top: auto;
        }

        #summary-tab-content .carousel-item .place-tips {
          margin-top: 15px;
          padding-top: 15px;
          border-top: 1px solid #e9ecef;
        }

        #summary-tab-content .carousel-item .place-tip {
          font-size: 1.3rem;
          color: #036B55;
          font-weight: 500;
          line-height: 1.4;
          margin: 0;
          padding: 10px 15px;
          background: rgba(3, 107, 85, 0.08);
          border-radius: 6px;
          border-left: 3px solid #036B55;
        }

        #summary-tab-content .carousel-item.primary-recommendation {
          border: 2px solid #036B55;
          background: linear-gradient(135deg, #f0f7f4 0%, #e8f4f0 100%);
          position: relative;
        }

        #summary-tab-content .carousel-item.primary-recommendation:before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          height: 4px;
          background: linear-gradient(90deg, #036B55, #028476);
        }

        #summary-tab-content .carousel-item.primary-recommendation:hover {
          transform: translateY(-5px) scale(1.02);
          box-shadow: 0 12px 20px rgba(3, 107, 85, 0.2);
        }

        #summary-tab-content .itinerary-table.simplified th.active-day,
        #summary-tab-content .itinerary-table.simplified td.active-day {
          background-color: #e8f5e8 !important;
          position: relative;
        }

        #summary-tab-content .itinerary-table.simplified th.active-day {
          border: 2px solid #28a745 !important;
          border-radius: 8px 8px 0 0;
        }

        #summary-tab-content .itinerary-table.simplified td.active-day {
          border: 2px solid #28a745 !important;
          border-top: none !important;
          border-radius: 0 0 8px 8px;
        }

        #summary-tab-content .itinerary-table.simplified th.active-day .top-activity,
        #summary-tab-content .itinerary-table.simplified td.active-day .top-activity {
          border-left: none !important;
        }

        #summary-tab-content .carousel-nav {
          display: flex;
          justify-content: center;
          align-items: center;
          gap: 15px;
          margin-top: 15px;
        }

        #summary-tab-content .carousel-nav-button {
          background: #036B55;
          color: white;
          border: none;
          border-radius: 5px;
          padding: 8px 16px;
          cursor: pointer;
          font-size: 0.9rem;
        }

        #summary-tab-content .carousel-nav-button:disabled {
          background: #ccc;
          cursor: not-allowed;
        }

        #summary-tab-content .carousel-page-info {
          color: #666;
          font-weight: 500;
          font-size: 0.9rem;
        }

        #summary-tab-content .carousel-placeholder {
          text-align: center;
          color: #666;
          padding: 50px 40px;
          background: #f8f9fa;
          border-radius: 10px;
          border: 2px dashed #dee2e6;
          min-height: 240px;
          display: flex;
          flex-direction: column;
          justify-content: center;
        }

        #summary-tab-content .carousel-placeholder h4 {
          color: #036B55;
          font-size: 1.4rem;
          margin-bottom: 15px;
        }

        #summary-tab-content .carousel-placeholder p {
          font-size: 1.1rem;
          margin-bottom: 10px;
          line-height: 1.5;
        }

        #summary-tab-content .carousel-placeholder ul {
          text-align: left;
          max-width: 400px;
          margin: 15px auto;
          font-size: 1rem;
        }

        #summary-tab-content .empty-itinerary-message {
          text-align: center;
          padding: 60px 40px;
          color: #666;
          background: #f8f9fa;
          border-radius: 10px;
          border: 2px dashed #dee2e6;
        }

        #summary-tab-content .empty-itinerary-message h3 {
          color: #036B55;
          font-size: 1.8rem;
          margin-bottom: 20px;
        }

        #summary-tab-content .empty-itinerary-message p {
          font-size: 1.2rem;
          margin-bottom: 15px;
        }

        #summary-tab-content .empty-itinerary-message ul {
          text-align: left;
          max-width: 500px;
          margin: 20px auto;
          font-size: 1.1rem;
        }

        #summary-tab-content .empty-itinerary-message li {
          margin-bottom: 8px;
          line-height: 1.4;
        }

        #summary-tab-content .select-dates-card {
          background-color: #ffffff;
          border: 1px solid #dee2e6;
          border-radius: 15px;
          padding: 60px 40px;
          margin-bottom: 25px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
          text-align: center;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          min-height: 450px;
        }

        #summary-tab-content .select-dates-card h4 {
          color: #036B55;
          font-size: 2.5rem;
          margin-bottom: 30px;
          font-weight: 700;
          text-align: center;
          width: 100%;
          line-height: 1.2;
        }

        #summary-tab-content .select-dates-card p {
          color: #666;
          font-size: 1.5rem;
          line-height: 1.6;
          margin-bottom: 25px;
          text-align: center;
          width: 100%;
          max-width: 700px;
          font-weight: 400;
        }

        #summary-tab-content .select-dates-card .instruction-list {
          text-align: center;
          max-width: 600px;
          margin: 35px auto;
          font-size: 1.4rem;
          width: 100%;
        }

        #summary-tab-content .select-dates-card .instruction-list ul {
          display: inline-block;
          text-align: left;
          margin: 0 auto;
          padding: 0;
          list-style: none;
        }

        #summary-tab-content .select-dates-card .instruction-list li {
          margin-bottom: 20px;
          line-height: 1.6;
          font-size: 1.3rem;
          color: #555;
          font-weight: 400;
          padding-left: 30px;
          position: relative;
        }

        #summary-tab-content .select-dates-card .instruction-list li:before {
          content: '•';
          color: #036B55;
          font-size: 2rem;
          position: absolute;
          left: 0;
          top: -2px;
        }

        #summary-tab-content .select-dates-card .instruction-list li:last-child {
          margin-bottom: 0;
        }
      "
    )
  ), tags$script(
    HTML(
      "
        $(document).on('click', '.itinerary-day-header, .itinerary-day-cell', function() {
          var dayIndex = $(this).data('day');
          Shiny.setInputValue('day_clicked', dayIndex);
        });

        $(document).on('click', '.carousel-item', function() {
          var placeName = $(this).data('place-name');
          var isPrimary = $(this).data('is-primary');

          Shiny.setInputValue('carousel_place_clicked', {
            name: placeName,
            is_primary: isPrimary,
            timestamp: new Date().getTime()
          });
        });
      "
    )
  )),
  
  # Title Section with Personality Card
  div(
    class = "title-section",
    div(
      class = "title-main",
      h2("Your Melbourne Exploration Summary", class = "main-title"),
      p(
        "Click categories in the 'Explore by Category' and 'Popular Attractions', and select dates in 'Weather Summary' to build your personalized itinerary.",
        class = "subtitle"
      )
    ),
    div(class = "title-personality", div(
      class = "personality-card",
      div(
        class = "personality-content",
        h3(textOutput("personality_title")),
        p(textOutput("personality_description"), class = "personality-description")
      ),
      div(uiOutput("personality_icon", class = "personality-icon"))
    ))
  ),
  
  # Itinerary and Carousel
  conditionalPanel(
    condition = "output.has_dates_selected",
    
    # Itinerary section
    div(
      class = "itinerary-section",
      h4("Your Recommended Itinerary"),
      p("Click on any day to discover related places!", style = "text-align: center; color: #666; margin-bottom: 15px;"),
      div(class = "itinerary-scroll-container", uiOutput("itinerary_table"))
    ),
    
    # Carousel section
    div(class = "top-combined-section", div(class = "carousel-section", uiOutput(
      "activity_carousel"
    )))
  ),
  
  # Instruction card when no dates selected
  conditionalPanel(condition = "!output.has_dates_selected", div(
    class = "select-dates-card",
    h4("📅 Plan Your Melbourne Adventure"),
    p("To get started with your personalized itinerary:"),
    div(class = "instruction-list", tags$ul(
      tags$li("Visit the Weather Summary tab to select your travel dates"),
      tags$li("Choose activities that interest you in the Explore tab"),
      tags$li("Your recommended itinerary will appear here automatically")
    )),
    p(
      "Once you've selected dates, you'll see daily recommendations that you can click to explore related places!"
    )
  ))
>>>>>>> Stashed changes
)