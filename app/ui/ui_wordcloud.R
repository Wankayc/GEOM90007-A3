# JavaScript for collapsible functionality
collapsible_js <- tags$script(HTML("
  $(document).ready(function() {
    // Main cloud page toggle
    $('#dataSourceToggleMain').click(function() {
      $(this).toggleClass('active');
      $('#dataSourceContentMain').toggleClass('show');
    });
    
    // Sub cloud page toggle
    $('#dataSourceToggleSub').click(function() {
      $(this).toggleClass('active');
      $('#dataSourceContentSub').toggleClass('show');
    });
  });
"))

# Additional CSS for collapsible button
collapsible_css <- tags$style(HTML("
  /* Collapsible data source button styles */
  .wordcloud-container-wrapper {
    position: relative;
  }
  .data-source-toggle {
    position: absolute !important;
    bottom: 15px;
    left: 15px;
    background: rgba(255, 255, 255, 0.95);
    border: none;
    color: #036B55;
    width: 28px;
    height: 28px;
    min-width: 28px;
    padding: 0;
    border-radius: 50%;
    font-size: 14px;
    cursor: pointer;
    transition: all 0.3s ease;
    display: flex;
    align-items: center;
    justify-content: center;
    z-index: 100;
    box-shadow: 0 2px 6px rgba(0,0,0,0.2);
  }
  .data-source-toggle:hover {
    background: #036B55;
    color: white;
    transform: scale(1.1);
  }
  .data-source-toggle i {
    transition: transform 0.3s ease;
  }
  .data-source-toggle.active {
    background: #036B55;
    color: white;
  }
  .data-source-content {
    position: absolute;
    bottom: 55px;
    left: 15px;
    max-width: 350px;
    max-height: 0;
    overflow: hidden;
    transition: max-height 0.3s ease;
    background: white;
    padding: 0;
    border-radius: 8px;
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
    z-index: 99;
  }
  .data-source-content.show {
    max-height: 200px;
    padding: 12px 15px;
    border: 1px solid #e0e0e0;
  }
  .data-source-content p {
    color: #666;
    font-size: 13px;
    line-height: 1.6;
    margin: 0;
  }
  .data-source-content a {
    color: #036B55;
    text-decoration: none;
    font-weight: 600;
  }
  .data-source-content a:hover {
    text-decoration: underline;
  }
"))

# Heading spacing CSS (unify title/subtitle gaps)
heading_spacing_css <- tags$style(HTML("
  /* 只负责主标题与其后第一段副标题之间的间距；不影响其他部分 */
  h2.section-lead { margin: 0 0 8px 0 !important; }
  p.section-desc { margin: 0 0 16px 0 !important; }
"))

# Get unique theme values from theme_data for UI radio buttons
themes_available <- sort(unique(theme_data$Theme[!is.na(theme_data$Theme)]))

# Main Word Cloud page
main_cloud_tab <- tabPanel(
  title='Explore by Category',
  collapsible_css,
  collapsible_js,
  heading_spacing_css,  # << 新增：统一主/副标题间距
  div(class='page-wrap',
      h2(class='section-lead', 'Explore Melbourne by Category'),
      p(class='section-desc', style='color:#666; font-size:14px; margin-bottom:16px; line-height:1.6;',
        'Click on any category below to discover Melbourne\'s top-rated places.'
      ),
      div(class='main-cloud-container wordcloud-container-wrapper',
          tableauPublicViz(
            id='mainCloudViz',
            url='https://public.tableau.com/views/Theme_Cloud/PickaThemetoStartExploring?:toolbar=no&:showVizHome=no',
            height="80vh"
          ),
          # Info button - bottom left corner
          tags$button(
            id='dataSourceToggleMain',
            class='data-source-toggle',
            title='About this data',
            tags$i(class='fa fa-info', style='font-style: normal;')
          ),
          # Collapsible content
          div(id='dataSourceContentMain',
              class='data-source-content',
              tags$p(
                'Data source: ',
                tags$a('Melbourne Open Data Portal',
                       href='https://data.melbourne.vic.gov.au/',
                       target='_blank')
              )
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
               h2(class='section-lead sub-cloud-title', 'Highlights in This Category'),
               p(class='section-desc sub-cloud-desc', style='color:#666; font-size:14px; line-height:1.6; margin-bottom:16px;',
                 'Click on any attraction type to view the highest-rated places.'
               ),
               div(class='wordcloud-container-wrapper',
                   div(class='full-bleed',
                       tableauPublicViz(
                         id='subCloudViz',
                         url='https://public.tableau.com/views/Sub_Theme_Cloud/TopHighlightsinThisTheme?:toolbar=no&:showVizHome=no',
                         height="60vh"
                       )
                   ),
                   # Info button - bottom left corner
                   tags$button(
                     id='dataSourceToggleSub',
                     class='data-source-toggle',
                     title='About this data',
                     tags$i(class='fa fa-info', style='font-style: normal;')
                   ),
                   # Collapsible content
                   div(id='dataSourceContentSub',
                       class='data-source-content',
                       tags$p(
                         'Data source: ',
                         tags$a('Melbourne Open Data Portal',
                                href='https://data.melbourne.vic.gov.au/',
                                target='_blank')
                       )
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

# Return both tabs as a list
list(
  main_cloud_tab,
  sub_cloud_tab
)

