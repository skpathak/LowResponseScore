library(leaflet)
library(RColorBrewer)
library(scales)
library(lattice)
library(dplyr)
library(formattable)

function(input, output, session) {
        
        ## Interactive Map ###########################################
        
        # Create the map
        output$map <- renderLeaflet({
                selectedBorough <- allegheny_blockgroups_muncipals %>% filter(Municipality == input$borough)
                leaflet() %>%
                        addTiles(
                                urlTemplate = "//{s}.tiles.mapbox.com/v3/jcheng.map-5ebohr46/{z}/{x}/{y}.png",
                                attribution = 'Maps by <a href="http://www.mapbox.com/">Mapbox</a>'
                        ) %>% 
                        setView(lng = mean(as.numeric(selectedBorough$INTPTLON), na.rm = TRUE), 
                                lat = mean(as.numeric(selectedBorough$INTPTLAT), na.rm = TRUE), 
                                zoom = 13)
        })
        
        # Precalculate the breaks we'll need for the two histograms
        lrsBreaks <- hist(plot = FALSE, allegheny_blockgroups_muncipals$Low_Response_Score, breaks = 20)$breaks
        
        output$histPDBVar <- renderPlot({
                hist(allegheny_blockgroups_muncipals$Low_Response_Score,
                     breaks = lrsBreaks,
                     main = "Low Response Score",
                     xlab = "Low Response Score",
                     xlim = range(allegheny_blockgroups_muncipals$Low_Response_Score, na.rm = TRUE),
                     col = '#00DD00',
                     border = 'white')
        })
        
        output$scatterPDBVar <- renderPlot({
                print(xyplot(pct_Prs_Blw_Pov_Lev_ACS_10_14 ~ Low_Response_Score, data = allegheny_blockgroups_muncipals, 
                             xlim = range(allegheny_blockgroups_muncipals$Low_Response_Score),
                             ylim = range(allegheny_blockgroups_muncipals$pct_Prs_Blw_Pov_Lev_ACS_10_14)))
        })
        
        # This observer is responsible for maintaining the circles and legend,
        # according to the variables the user has chosen to map to color and size.
        observe({
                colorBy <- input$pdbvars
                borough <- input$borough
                
                colorName <- names(pdb.var.names)[pdb.var.names == colorBy]
                
                selectedBorough <- allegheny_blockgroups_muncipals %>% filter(Municipality == borough)
                
                colorData <- selectedBorough[[colorBy]]
                pal <- colorBin("viridis", colorData, 7, pretty = FALSE)
                
                leafletProxy("map", data = selectedBorough) %>%
                        clearShapes() %>%
                        addPolygons(color = "#444444", weight = 1, smoothFactor = 0.5,
                                    opacity = 1.0, fillOpacity = 0.5,
                                    fillColor = pal(colorData), layerId=~GEOID,
                                    highlightOptions = highlightOptions(color = "white", weight = 2,
                                                                        bringToFront = TRUE))%>%
                        addLegend("bottomleft", pal=pal, values=colorData, title=colorName,
                                  layerId="colorLegend")
        })
        
        # Show a popup at the given location
        showBoroughcodePopup <- function(id, lat, lng) {
                selectedBorough <- allegheny_blockgroups_muncipals %>% filter(GEOID == id)
                content <- as.character(tagList(
                        tags$h4("Low Response Score:", as.integer(selectedBorough$Low_Response_Score)),
                        tags$strong(HTML(sprintf("%s, %s %s",
                                                 selectedBorough$Municipality, selectedBorough$tract, selectedBorough$block_group
                        )))
                ))
                leafletProxy("map") %>% addPopups(lng, lat, content, layerId = id)
        }
        
        # When map is clicked, show a popup with city info
        observe({
                leafletProxy("map") %>% clearPopups()
                event <- input$map_shape_click
                if (is.null(event))
                        return()
                
                isolate({
                        showBoroughcodePopup(event$id, event$lat, event$lng)
                })
        })
        
        
        ## Data Explorer ###########################################
        
        observe({
                boroughs <- if (is.null(input$boroughTable)) character(0) else {
                        filter(allegheny_blockgroups_muncipals, Municipality %in% input$boroughTable) %>%
                                `$`('Municipality') %>%
                                unique() %>%
                                sort()
                }
                stillSelected <- isolate(input$boroughTable[input$boroughTable %in% boroughs])
                updateSelectInput(session, "boroughTable", choices = borough_names,
                                  selected = stillSelected)
        })
        
        observe({
                if (is.null(input$goto))
                        return()
                isolate({
                        map <- leafletProxy("map")
                        map %>% clearPopups()
                        dist <- 0.5
                        geoid <- input$goto$id
                        lat <- input$goto$lat
                        lng <- input$goto$lng
                        showBoroughcodePopup(geoid, lat, lng)
                        map %>% fitBounds(lng - dist, lat - dist, lng + dist, lat + dist)
                })
        })
        
        output$pdbtable <- DT::renderDataTable({
                df <- cleantable %>%
                        filter(
                                is.null(input$boroughTable) | Municipality %in% input$boroughTable
                        ) #%>%
                        #mutate(Action = paste('<a class="go-map" href="" data-lat="', lat, '" data-long="', lng, '" data-zip="', geoid, '"><i class="fa fa-crosshairs"></i></a>', sep=""))
                #action <- DT::dataTableAjax(session, df)
                DT:::DT2BSClass(c('compact', 'cell-border'))
                DT::datatable(df) #, options = list(ajax = list(url = action)), escape = FALSE)
                
                # formattable(df, list(
                #         Municipality = color_tile("white", "orange"),
                #         area(col = c("`Low Response Rate`", "`Renter Occupied Units`")) ~ normalize_bar("pink", 0.2)
                # ))
        })
}
