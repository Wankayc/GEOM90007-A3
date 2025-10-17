ui <- navbarPage(
  title = "GEOM90007 Assignment 3",
  id = "nav",
  header=setUpTableauInShiny(),
  theme = shinythemes::shinytheme("flatly"),
  
  useShinyjs(),
  
  tabPanel("Word Cloud", icon = icon("cloud"), uiOutput("wordcloud_ui")),
  tabPanel("Weather Summary", icon = icon("sun"), uiOutput("weather_ui")),
  tabPanel("Map", icon = icon("map"), uiOutput("map_ui")),
  tabPanel("Summary", icon = icon("chart-bar"), uiOutput("summary_ui")),
  main_cloud_tab,
  sub_cloud_tab
)