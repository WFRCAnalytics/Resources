# Load necessary libraries
library(shiny)
library(shinydashboard)
library(shinyjs)
library(shinyalert)
library(dplyr)
library(ggplot2)
library(tidyverse)

# Assuming functions.R is necessary and contains needed components
source("functions.R")

# Function to read HTML content and maintain formatting
readHtmlContent <- function(filepath) {
  # Read the file
  lines <- readLines(filepath, warn = FALSE)
  # Collapse into a single HTML string, preserving HTML structure
  htmlContent <- paste(lines, collapse = "\n")
  return(htmlContent)
}

ui <- dashboardPage(
  dashboardHeader(
    title = "Trip Length Distributions - 2023 Household Travel Survey",
    titleWidth = 600,
    tags$li(class = "dropdown",
            tags$a(href = "https://unifiedplan.org/household-travel-surveys/", target = "_blank",
                   "HTS Reference Material",
                   style = "float: right; font-size: 16px; padding: 15px;")
    ),
    tags$li(class = "dropdown",
            actionLink("showMethodology", "Methodology", icon = icon("book"),
                       style = "float: right; font-size: 16px; padding: 15px;")
    )
  ),
  dashboardSidebar(
    selectInput("groupSampleSegment", "Sample Segment Group:",
                choices = setNames(labelsSampleSegmentGroups$value, labelsSampleSegmentGroups$label)),
    selectInput("groupModeTypeBroad", "Travel Mode:",
                choices = setNames(labelsModeTypeBroad$value, labelsModeTypeBroad$label)),
    selectInput("groupTripType", "Trip Purpose:",
                choices = setNames(labelsTripType$value, labelsTripType$label)),
    selectInput("groupNumVehicles", "Household Number of Vehicles:",
                choices = setNames(labelsNumVehicles$value, labelsNumVehicles$label)),
    selectInput("groupNumWorkers", "Household Number of Workers:",
                choices = setNames(labelsNumWorkers$value, labelsNumWorkers$label)),
    selectInput("typeChart", "Type of Plot:",
                choices = c("Histogram" = "histogram", "Cumulative Distribution" = "cumulative", "Number of Records" = "records")),
    selectInput("binSize", "Bin Size:",
                choices = setNames(labelsBinSizes$value, labelsBinSizes$label)),
    selectInput("maxX", "Max X-axis Value:",
                choices = seq(5, 100, by = 5), 
                selected = 30)
  ),
  dashboardBody(
    uiOutput("loadingMessage"),
    tags$head(
      tags$style(HTML("
                .shiny-output-error-validation { color: red; }
                #container {
                    display: flex;
                    flex-wrap: wrap;
                }
                #dataPlot {
                    flex: 2 1 60%; /* flex-grow, flex-shrink, flex-basis */
                }
                #inputsContainer {
                    flex: 1 1 40%;
                    display: flex;
                    flex-direction: column;
                }
                #selectedInputs, #dataTable {
                    flex: 1;
                    padding-top: 20px; /* Add padding on top */
                    padding-bottom: 10px; /* Add padding on bottom */
                }
            "))
    ),
    div(id = "container",
        plotOutput("dataPlot"),
        div(id = "inputsContainer",
            textOutput("selectedInputs"),
            tableOutput("dataTable")
        )
    )
  )
)

server <- function(input, output, session) {
  # Display the alert when the app is opened
  shinyalert(
    text ="The 2023 Utah Moves household travel survey was designed and conducted for use in regional and statewide travel demand modeling. The sample size and frame is suitable for that purpose.
    \n Proper application of the dataset and use of this application is the responsibility of the user. In using the information or data herein, users assume the risk for relying on such data or information, and further agree to hold Utah's transportation agencies harmless for all liability of any accuracy or correctness of the information or data provided.
    \n Users are encouraged to contact analytics@wfrc.org with questions or to discuss proper uses and application of this data.",
    closeOnClickOutside = FALSE,
    closeOnEsc = FALSE,
    confirmButtonText = "I acknowledge and agree",
    confirmButtonCol = 'navy'
  )
  
  # Handle the methodology modal dialog
  observeEvent(input$showMethodology, {
    showModal(modalDialog(
      title = "Methodology",
      tags$p("The trip lengths described in this app are from the trip distances as reported in the Household Travel Survey's cleaned, weighted trip table delivered by RSG, the contractor for the survey project. The dataset has not been further post-processed with the exception that trips with a length longer than 100 miles have been excluded from this application/analysis."),
      tags$p("Trip length distributions were calculated using the following steps:"),
      tags$p(tags$b("Prepare distance bins")),
      tags$p("A view was created that contains starting bin values for bin sizes of 1/2 mile, 1 mile and 5 miles from 0 to 100 using QUERY 1."),
      tags$p(tags$b("Prepare grouping tables")),
      tags$p("Five separate views were created to further group values from 5 key dimensions to the data: sample segment (geography and population), household number of workers, household number of vehicles, trip travel mode type, and trip type (purpose). The only grouping added to the current survey breakdown was an 'All' group that includes all possible values for each respective field. The 'All' group uses an attribute value of -1 to not overlap with existing attribute values. An example SQL for number of vehicles is shown in QUERY 2."),
      tags$p(tags$b("Prepare main query")),
      tags$p("The main query was created using the household table and the trip table joined on the hh_id field. The view for distance bins is included with a condition that the trip.distance_miles is greater than or equal to the binStart value and less than binStart + binSize. The five views for groupings are also added by using key values to link the tables. The trip_weight and number of records is aggregated for each combination of bin size and key dimension using their respective group fields. Resulting record counts in the numTripRecords field were used to judge rough accuracy of the query structure. See QUERY 3."),
      tags$p(tags$b("Calculate histogram distribution and cumulative distribution")),
      tags$p("A jupyter notebook was used to calculate a histogram (percentage) distribution and cumulative distribution for each combination of bin size and key dimension. The notebook can be found in this repo: https://github.com/WFRCAnalytics/Resources/blob/master/R-Shiny/2023-utah-household-travel-survey-trip-length-distribution/dataprep/trip-distance-distribution.ipynb"),
      tags$h4("QUERY 1"),
      HTML(readHtmlContent("query1.html")),
      tags$h4("QUERY 2"),
      HTML(readHtmlContent("query2.html")),
      tags$h4("QUERY 3"),
      HTML(readHtmlContent("query3.html")),
      size = "l",
      easyClose = TRUE,
      footer = NULL
    ))
  })
  
  observe({
    # Convert inputs to numeric to avoid non-numeric errors
    numeric_binSize <- as.numeric(input$binSize)
    numeric_maxX <- as.numeric(input$maxX)
    
    # Handle plot rendering
    output$dataPlot <- renderPlot({
      # Placeholder data processing; actual logic should match your data structure and needs
      filtered_data <- data %>%
        filter(groupSampleSegment == input$groupSampleSegment,
               groupNumWorkers == input$groupNumWorkers,
               groupNumVehicles == input$groupNumVehicles,
               groupTripType == input$groupTripType,
               groupModeTypeBroad == input$groupModeTypeBroad,
               binSize == numeric_binSize)
      
      lowerlimit <- -0.5 * numeric_binSize
      
      if (input$typeChart == "histogram") {
        ggplot(filtered_data, aes(x = binStart + numeric_binSize / 2, y = pctTripWeight)) +
          geom_bar(stat = "identity", position = "dodge", fill = "steelblue", width = numeric_binSize) +
          scale_x_continuous(limits = c(lowerlimit, numeric_maxX + numeric_binSize / 2),
                             breaks = seq(0, numeric_maxX, by = 5)) +
          labs(title = "Trip Length Histogram",
               x = "Distance (miles)",
               y = "Percentage")
      } else if (input$typeChart == "records") {
        ggplot(filtered_data, aes(x = binStart + numeric_binSize / 2, y = numTripRecords)) +
          geom_bar(stat = "identity", position = "dodge", fill = "steelblue", width = numeric_binSize) +
          scale_x_continuous(limits = c(lowerlimit, numeric_maxX + numeric_binSize / 2),
                             breaks = seq(0, numeric_maxX, by = 5)) +
          labs(title = "Number of Records by Bin",
               x = "Distance (miles)",
               y = "Records")
      } else {
        ggplot(filtered_data, aes(x = binStart, y = cumPctTripWeight)) +
          geom_line() +
          scale_x_continuous(limits = c(lowerlimit, numeric_maxX),
                             breaks = seq(0, numeric_maxX, by = 5)) +
          labs(title = "Trip Length Cumulative Distribution",
               x = "Distance (miles)",
               y = "Cumulative Percentage")
      }
    })
    
    output$selectedInputs <- renderText({
      paste("\n",
            "Current Filter:",
            paste0("\u00A0\u00A0\u00A0Sample Segment Group: ", labelsSampleSegmentGroups$label[labelsSampleSegmentGroups$value == input$groupSampleSegment]),
            paste0("\u00A0\u00A0\u00A0Travel Mode: ", labelsModeTypeBroad$label[labelsModeTypeBroad$value == input$groupModeTypeBroad]),
            paste0("\u00A0\u00A0\u00A0Trip Type: ", labelsTripType$label[labelsTripType$value == input$groupTripType]),
            paste0("\u00A0\u00A0\u00A0Number of Vehicles: ", labelsNumVehicles$label[labelsNumVehicles$value == input$groupNumVehicles]),
            paste0("\u00A0\u00A0\u00A0Number of Workers: ", labelsNumWorkers$label[labelsNumWorkers$value == input$groupNumWorkers]),
            sep = "\n")
    })
    
    output$dataTable <- renderTable({
      # Placeholder for your data table logic
      filtered_data <- data %>%
        filter(groupSampleSegment == input$groupSampleSegment,
               groupNumWorkers == input$groupNumWorkers,
               groupNumVehicles == input$groupNumVehicles,
               groupTripType == input$groupTripType,
               groupModeTypeBroad == input$groupModeTypeBroad,
               binSize == numeric_binSize) %>%
        select(binStart, numTripRecords, sumTripWeight, pctTripWeight, cumPctTripWeight)  # Selecting specific columns
      
      # Display the filtered and selected data
      filtered_data
    })
  })
}

shinyApp(ui = ui, server = server)
