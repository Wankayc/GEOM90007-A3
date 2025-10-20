# Main Theme Cloud Tab 

# Commented out for now because you need to put 'tableau-in-shiny-v1.2.R' somewhere in the project files

ui_wordcloud <- tabPanel(
  title='Main Themes',
  h2('Main Theme Word Cloud'),
  p('Please click on the theme you want to explore in Melbourne', 
    style='color: #666; font-style: italic; margin-bottom: 10px;'),
  #tableauPublicViz(
  #  id='mainCloudViz',       
  #  url='https://public.tableau.com/views/mymaincloud/Maincloud',
  #  height="85vh"
 # )
)

# Sub Theme Cloud Tab
sub_cloud_tab <- tabPanel(
  title='Sub Themes',
  h2('Sub Theme Word Cloud'),
  p('Sub themes related to your selected main theme', 
    style='color: #666; font-style: italic; margin-bottom: 10px;'),
)
 # tableauPublicViz(
#    id='subCloudViz',       
#    url='https://public.tableau.com/views/mysubcloud/Subthemecloud',
#    height="85vh"
#  )

