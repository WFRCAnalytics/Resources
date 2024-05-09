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
    radioButtons("segmentSelect", "Choose Geography:",
                 choices = list("Sample Segment Group" = "sampleSegment",
                                "Area of Interest" = "areaInterest"),
                 selected = "sampleSegment"),
    uiOutput("dynamicSelect"),
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
  
  output$loadingMessage <- renderUI({
    if (is.null(selectedSampleSegment())) {
      div(style = "color: red; font-weight: bold;", "Please wait while data loads...")
    } else {
      NULL  # No message if the condition is met
    }
  })
  
  # Define reactive values
  selectedSampleSegment <- reactiveVal()
  filterTextSampleSegment <- reactiveVal()
  
  # Render UI based on user selection
  output$dynamicSelect <- renderUI({
    if(input$segmentSelect == "sampleSegment") {
      selectInput("groupSampleSegment", "Sample Segment Group:",
                  choices = setNames(labelsSampleSegmentGroups$value, labelsSampleSegmentGroups$label))
    } else {
      selectInput("areaInterest", "Area of Interest:",
                  choices = setNames(labelsAreaInterest$value, labelsAreaInterest$label))
    }
  })
  
  # Observe changes in segment selection
  observeEvent(input$groupSampleSegment, {
    selectedSampleSegment(input$groupSampleSegment)
    filterTextSampleSegment(paste("Sample Segment: ", labelsSampleSegmentGroups$label[labelsSampleSegmentGroups$value == input$groupSampleSegment]))
  })
  
  observeEvent(input$areaInterest, {
    selectedSampleSegment(input$areaInterest)
    filterTextSampleSegment(paste("Area of Interest: ", labelsAreaInterest$label[labelsAreaInterest$value == input$areaInterest]))
  })
  
  
  # Handle the methodology modal dialog
  observeEvent(input$showMethodology, {
    showModal(modalDialog(
      title = "Methodology",
      tags$p("The trip-length distributions were generated from the trip distance field in the trip table as recorded in the Household Travel Survey using the following steps:"),
      tags$p(tags$b("Prepare distance bins")),
      tags$p("A view was created that contains starting bin values for bin sizes of 1/2 mile, 1 mile and 5 miles from 0 to 100 using QUERY 1."),
      tags$p(tags$b("Prepare grouping tables")),
      tags$p("Five separate views were created to further group values from 5 key dimensions to the data: sample segment (geography and population), household number of workers, household number of vehicles, trip travel mode type, and trip type (purpose). The only grouping added to the current survey breakdown was an 'All' group that includes all possible values for each respective field. The 'All' group uses an attribute value of -1 to not overlap with existing attribute values. An example SQL for number of vehicles is shown in QUERY 2."),
      tags$p(tags$b("Prepare main query")),
      tags$p("The main query was created using the household table and the trip table joined on the hh_id field. The view for distance bins is included with a condition that the trip.distance_miles is greater than or equal to the binStart value and less than binStart + binSize. The five views for groupings are also added by using key values to link the tables. The trip_weight and number of records is aggregated for each combination of bin size and key dimension using their respective group fields. Resulting record counts in the numTripRecords field were used to judge rough accuracy of the query structure. See QUERY 3."),
      tags$p(tags$b("Calculate histogram distribution and cumulative distribution")),
      tags$p("A jupyter notebook was used to calculate a histogram (percentage) distribution and cumulative distribution for each combination of bin size and key dimension. The notebook can be found in this repo: https://github.com/WFRCAnalytics/Resources/blob/master/R-Shiny/2023-utah-household-travel-survey-trip-length-distribution/dataprep/trip-distance-distribution.ipynb"),
      
      tags$h4("QUERY 1"),
      tags$p(
        HTML('
<pre style="background-color: #f5f5f5; padding: 10px; border-radius: 5px; border: 1px solid #ccc; font-family: monospace;">
  <code>
-- Create list of numbers that will be filtered below by MOD function
-- Generate a series of numbers from 0 to 995, incrementing by 5
WITH NumberSeries AS (
  SELECT num
  FROM UNNEST(GENERATE_ARRAY(0, 995, 5)) AS num
)

-- Half-mile bin size
SELECT
  0.5 AS binSize,
  num / 10.0 AS binStart
FROM NumberSeries
WHERE MOD(num, 5) = 0 AND num / 10.0 < 100

UNION ALL

-- 1-mile bin size
SELECT
  1.0 AS binSize,
  num / 10.0 AS binStart
FROM NumberSeries
WHERE MOD(num, 10) = 0 AND num / 10.0 < 100

UNION ALL

-- 5-mile bin size
SELECT
  5.0 AS binSize,
  num / 10.0 AS binStart
FROM NumberSeries
WHERE MOD(num, 50) = 0 AND num / 10.0 < 100

ORDER BY
  binSize, binStart;
  </code>
</pre>
        ')
      ),
      tags$h4("QUERY 2"),
      tags$p(
        HTML('
<pre style="background-color: #f5f5f5; padding: 10px; border-radius: 5px; border: 1px solid #ccc; font-family: monospace;">
  <code>
--Each individual value is given its own groupNumVehicles value equivalent to its num_vehicles attribute value
SELECT
  CAST(value AS INT64) AS num_vehicles,
  CAST(value AS INT64) AS groupNumVehicles,
  label AS groupNumVehiclesLabel
FROM
  `confidential-2023-utah-hts.20230313.value_labels`
WHERE
  table = "hh" AND 
  variable = "num_vehicles"

UNION ALL

--An ALL group is added with each num_vehicles attribute value as a record and a common groupNumVehicles value of -1 (to not overlap with values created from existing num_vehicles attribute values above  )
SELECT
  CAST(value AS INT64) AS num_workers,
  -1 AS groupNumVehicles,
  "All Number of Vehicles" AS groupNumVehiclesLabel
FROM
  `confidential-2023-utah-hts.20230313.value_labels`
WHERE
  table = "hh" AND 
  variable = "num_vehicles"

ORDER BY
  groupNumVehicles, num_vehicles
  </code>
</pre>
           ')
      ),
      tags$h4("QUERY 3"),
      tags$p(
        HTML('
<pre style="background-color: #f5f5f5; padding: 10px; border-radius: 5px; border: 1px solid #ccc; font-family: monospace;">
<code>
SELECT
  bins.binSize,
  bins.binStart,
  gSs.groupSampleSegmentLabel,
  gNw.groupNumWorkers,
  gNv.groupNumVehicles,
  gTt.groupTripType,
  gMtb.groupModeTypeBroad,
  COUNT(*) as numTripRecords,
  SUM(trip.trip_weight) AS sumTripWeight
FROM
  `confidential-2023-utah-hts.20230313._vDistanceBinsBySize` as bins,
  `confidential-2023-utah-hts.20230313.hh` as hh,
  `confidential-2023-utah-hts.20230313.trip` as trip,
  `confidential-2023-utah-hts.groupings.groupSampleSegment` as gSs,
  `confidential-2023-utah-hts.groupings.groupNumWorkers` as gNw,
  `confidential-2023-utah-hts.groupings.groupNumVehicles` as gNv,
  `confidential-2023-utah-hts.groupings.groupModeTypeBroad` as gMtb,
  `confidential-2023-utah-hts.groupings.groupTripType` as gTt
WHERE
  trip.distance_miles &gt;= bins.binStart AND
  trip.distance_miles &lt; bins.binStart + bins.binSize AND
  hh.sample_segment = gSs.sample_segment AND
  hh.hh_id = trip.hh_id AND
  hh.num_workers = gNw.num_workers AND
  hh.num_vehicles = gNv.num_vehicles AND
  trip.trip_type = gTt.trip_type AND
  trip.mode_type_broad = gMtb.mode_type_broad
GROUP BY
  bins.binSize,
  bins.binStart,
  gSs.groupSampleSegmentLabel,
  gNw.groupNumWorkers,
  gNv.groupNumVehicles,
  gTt.groupTripType,
  gMtb.groupModeTypeBroad
</code>
</pre>'
        )
      ),
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
    req(selectedSampleSegment())  # Ensure data is selected before plotting

    # Simulate data retrieval and processing
    Sys.sleep(2)  # Simulate data processing time
    
    # Placeholder data processing; actual logic should match your data structure and needs
    filtered_data <- data %>%
      filter(groupSampleSegment == selectedSampleSegment(),
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
    req(filterTextSampleSegment())  # Ensure data is selected before plotting
    paste("\n",
          "Current Filter:",
          paste0("\u00A0\u00A0\u00A0", filterTextSampleSegment()),
          paste0("\u00A0\u00A0\u00A0Travel Mode: ", labelsModeTypeBroad$label[labelsModeTypeBroad$value == input$groupModeTypeBroad]),
          paste0("\u00A0\u00A0\u00A0Trip Type: ", labelsTripType$label[labelsTripType$value == input$groupTripType]),
          paste0("\u00A0\u00A0\u00A0Number of Vehicles: ", labelsNumVehicles$label[labelsNumVehicles$value == input$groupNumVehicles]),
          paste0("\u00A0\u00A0\u00A0Number of Workers: ", labelsNumWorkers$label[labelsNumWorkers$value == input$groupNumWorkers]),
          sep = "\n")
  })
  
  
  
  output$dataTable <- renderTable({
    req(selectedSampleSegment())  # Ensure data is selected before plotting
    
    # Placeholder for your data table logic
    filtered_data <- data %>%
      filter(groupSampleSegment == selectedSampleSegment(),
             groupNumWorkers == input$groupNumWorkers,
             groupNumVehicles == input$groupNumVehicles,
             groupTripType == input$groupTripType,
             groupModeTypeBroad == input$groupModeTypeBroad,
             binSize == numeric_binSize)%>%
      select(binStart, numTripRecords, sumTripWeight, pctTripWeight, cumPctTripWeight)  # Selecting specific columns
    
    # Display the filtered and selected data
    filtered_data
  })
  
})
}

shinyApp(ui = ui, server = server)
