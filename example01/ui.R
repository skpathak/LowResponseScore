library(leaflet)

navbarPage(title=div("Planing Database: Hard to Count"),  id="nav",
           tabPanel("Interactive map",
                    div(class="outer",
                        tags$head(
                                # Include our custom CSS
                                includeCSS("styles.css"),
                                includeScript("gomap.js")
                        ),
                        
                        # If not using custom CSS, set height of leafletOutput to a number instead of percent
                        leafletOutput("map", width="100%", height="100%"),
                        # Shiny versions prior to 0.11 should use class = "modal" instead.
                        absolutePanel(id = "controls", class = "panel panel-default", fixed = TRUE,
                                      draggable = TRUE, top = 60, left = "auto", right = 20, bottom = "auto",
                                      width = 330, height = "auto",
                                      HTML('<button data-toggle="collapse" data-target="#demo" id="togglebutton">Plot Variables</button>'),
                                      tags$div(id = 'demo',  class="collapse in",
                                      h2("Low Response Score", id = "panelhead"),
                                      
                                      selectInput("pdbvars", "Planing Variables", pdb.var.names),
                                      selectInput("borough", "Borough Name", borough_names, selected = "Wilkinsburg"),
                                      #box(title = "Box title", height = 300, "Box content"),
                                      plotOutput("histPDBVar", height = 200),
                                      plotOutput("scatterPDBVar", height = 250)
                        )),
                        
                        tags$div(id="cite",
                                 'Data compiled for ', tags$em('Coming Apart: The State of White America, 1960–2010'), ' by Charles Murray (Crown Forum, 2012).'
                        )
                    )
           ),
           
           tabPanel("Data explorer",
                    fluidRow(
                            column(6,
                                   selectInput("boroughTable", "Borough", c("All borough"=""), multiple=TRUE)
                            )
                    ),
                    hr(),
                    DT::dataTableOutput("pdbtable")
           ),
           
           conditionalPanel("false", icon("crosshair"))
)
