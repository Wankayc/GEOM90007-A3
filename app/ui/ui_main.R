
# Main UI
ui <- navbarPage(
  title = "GEOM90007 Assignment 3",
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
  
  tabPanel("Weather Summary", icon = icon("sun"), uiOutput("weather_ui")),
  tabPanel("Map", icon = icon("map"), uiOutput("map_ui")),
  tabPanel("Summary", icon = icon("chart-bar"), uiOutput("summary_ui"))
)