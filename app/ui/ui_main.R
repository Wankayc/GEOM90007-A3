source("ui/ui_wordcloud.R")
# Main UI
ui <- navbarPage(
  title = "GEOM90007 Assignment 3",
  id = "nav",
  # header = setUpTableauInShiny(),
  theme = shinythemes::shinytheme("flatly"),
  useShinyjs(),
  
  tabPanel("Word Cloud", icon = icon("cloud"), uiOutput("wordcloud_ui")),
  tabPanel("Weather Summary", icon = icon("sun"), uiOutput("weather_ui")),
  tabPanel("Map", icon = icon("map"), uiOutput("map_ui")),
  tabPanel("Summary", icon = icon("chart-bar"), uiOutput("summary_ui")),
  
  # Use the tabs from ui_wordcloud
  ui_wordcloud,    # From ui_wordcloud.R
  sub_cloud_tab    # From ui_wordcloud.R
)