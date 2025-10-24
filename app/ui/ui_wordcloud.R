# Global page CSS styling (custom layout, colors, fonts)
page_css <- tags$head(
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

# Get unique theme values from theme_data for UI radio buttons
themes_available <- sort(unique(theme_data$Theme[!is.na(theme_data$Theme)]))

# Main Word Cloud page
main_cloud_tab <- tabPanel(
  title='Explore by Category',
  div(class='page-wrap',
      h2('Explore Melbourne by Category'),
      p(style='color:#666; font-size:14px; margin-bottom:16px; line-height:1.6;',
        'Click on any category below to discover Melbourne\'s top-rated places. ',
        'Data source: ',
        tags$a('Melbourne Open Data Portal',
               href='https://data.melbourne.vic.gov.au/',
               target='_blank', style='color:#036B55;')
      ),
      div(class='main-cloud-container',
          tableauPublicViz(
            id='mainCloudViz',
            url='https://public.tableau.com/views/Theme_Cloud/PickaThemetoStartExploring?:toolbar=no&:showVizHome=no',
            height="80vh"
          )
      )
  )
)

# Sub Word Cloud + Ranking page
sub_cloud_tab <- tabPanel(
  title='Popular Attractions',
  div(class='page-wrap',
      fluidRow(
        column(width = 9,
               h2(class='sub-cloud-title', 'Highlights in This Category'),
               p(class='sub-cloud-desc', style='color:#666; font-size:14px; line-height:1.6;',
                 'Click on any attraction type to view the highest-rated places. ',
                 'Data source: ',
                 tags$a('Melbourne Open Data Portal',
                        href='https://data.melbourne.vic.gov.au/',
                        target='_blank', style='color:#036B55;')
               ),
               div(class='full-bleed',
                   tableauPublicViz(
                     id='subCloudViz',
                     url='https://public.tableau.com/views/Sub_Theme_Cloud/TopHighlightsinThisTheme?:toolbar=no&:showVizHome=no',
                     height="60vh"
                   )
               )
        ),
        column(width = 3,
               div(class='card',
                   h4('Theme'),
                   div(class = "radio-scroll",
                       radioButtons('themeSingle', NULL,
                                    choices = themes_available,
                                    selected = ifelse("Leisure" %in% themes_available,
                                                      "Leisure", themes_available[1]),
                                    inline = FALSE)
                   ),
                   span(class='help-note', 'Choose one theme to update the word cloud and the rankings.')
               )
        )
      ),
      hr(style='border:0; border-top:3px solid #036B55; margin:20px 0 15px 0;'),
      fluidRow(
        column(width = 9,
               # Added button before the ranking chart
               div(style='margin-bottom: 15px;',
                   h2('Top Rated Places by Google Reviews', style='display:inline-block; margin-right:20px;'),
                   actionButton('showMapBtn', 
                                'View on Map',
                                icon = icon('map-marker-alt'),
                                style = 'background-color:#036B55; color:white; padding:8px 20px; border:none; border-radius:5px; font-size:14px; font-weight:600; cursor:pointer; vertical-align:middle;')
               ),
               girafeOutput('plot_ranking', height='95vh')
        ),
        column(width = 3,
               div(class='card',
                   h4('Show top'),
                   selectInput('topN', NULL,
                               choices = c('5' = 5, '10' = 10, '15' = 15, '20' = 20),
                               selected = 10, width = '100%'),
                   hr(style='border-color:#036B55; margin:15px 0;'),
                   p('Number of top-rated places to display',
                     style='color:#666; font-size:11px; line-height:1.3;')
               )
        )
      )
  )
)


list(
  main_cloud_tab,
  sub_cloud_tab
)