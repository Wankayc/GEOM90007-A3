div(
  id = "summary-tab-content",
  
  tags$head(tags$style(
    HTML(
      "
        #summary-tab-content {
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          padding: 20px;
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
          margin-bottom: 25px;
          box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        #summary-tab-content .itinerary-section h4 {
          font-weight: 600;
          margin-bottom: 25px;
          color: #343a40;
          font-size: 1.8rem;
          text-align: center;
        }

        /* Itinerary */
        #summary-tab-content .itinerary-scroll-container {
          width: 100%;
          overflow-x: auto;
          padding-bottom: 15px;
          border: 1px solid #e9ecef;
          border-radius: 10px;
          background: #fafafa;
          min-height: 280px;
        }

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
)