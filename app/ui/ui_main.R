# Main UI
ui <- tagList(
  # Loading screen - appears first to allow dataset to be loaded 
  # Otherwise there will be errors when users click before fully loaded
  div(
    id = "loading-screen",
    style = "position: fixed; top: 0; left: 0; width: 100%; height: 100%; background: white; z-index: 9999; display: flex; justify-content: center; align-items: center; flex-direction: column;",
    div(
      style = "text-align: center;",
      h2("Melbourne Explorer", style = "color: #036B55; margin-bottom: 20px;"),
      h4("Loading amazing places in Melbourne..."),
      div(style = "margin: 30px 0;", icon("spinner", class = "fa-spin fa-3x", style = "color: #036B55;")),
      p("Please wait while we prepare your personalized Melbourne experience")
    )
  ),
  
  # Main app content - hidden initially
  div(
    id = "app-content",
    style = "display: none;",  # Hidden until data loads
    navbarPage(
      title = "Melbourne Explorer",
      id = "nav",
      theme = shinythemes::shinytheme("flatly"),
      useShinyjs(),
      
      header = tagList(
        setUpTableauInShiny(),
        tags$head(
          tags$style(HTML("
            .page-wrap { max-width: 95vw; margin: 0 auto; padding: 0 20px; }
            .page-wrap h2 { color:#036B55; font-weight:700; margin:10px 0 12px 0; text-align:left; }
            .card { padding:15px; background:#f8f9fa; border-radius:8px; }
            .card h4 { color:#036B55; margin-bottom:12px; font-size:15px; font-weight:700; }
            .radio-scroll { max-height: 260px; overflow:auto; padding-right:4px; }
            .radio-scroll .radio { margin-bottom:6px; }
            .help-note { color:#666; font-size:11px; line-height:1.3; margin-top:8px; display:block; }
            .sub-cloud-title { margin-bottom: 2px !important; }
            .sub-cloud-desc { margin-bottom: 4px !important; }
            .full-bleed { margin-left: -20px; margin-right: -20px; width: calc(100% + 40px); }
            .full-bleed > * { width: 100% !important; display:block; }
            .main-cloud-container { max-width: 90%; margin: 0 auto; }
          "))
        )
      ),
      
      # Load two word cloud tabs
      source("ui/ui_wordcloud.R", local = TRUE)$value[[1]],
      source("ui/ui_wordcloud.R", local = TRUE)$value[[2]],
      
      # Rest of the tabs
      tabPanel("Weather Summary", icon = icon("sun"), uiOutput("weather_ui")),
      tabPanel("Map", icon = icon("map"), uiOutput("map_ui")),
      tabPanel("Summary", icon = icon("chart-bar"), uiOutput("summary_ui"))
    )
  )
)