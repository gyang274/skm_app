# ui.R

shinyUI(navbarPage(
  
  title = "OWL: Optimal Warehouse Locator", id = "nav",

  tabPanel(
    
    title = "Analytic View",
           
    div(
      
      class = "main",
      
      tags$head(
        # include the custom CSS
        includeCSS("styles.css"),
        includeScript("gomap.js")
      ),
      
      leafletOutput(outputId = "map", width = "100%", height = "100%"),
      
      absolutePanel(
        id = "pan", class = "panel panel-default", fixed = TRUE, draggable = TRUE, 
        top = 70, left = "auto", right = 40, bottom = "auto", width = 400, height = "auto",
        
        HTML('<div align="center">'),
        h4("Optimization Objective"),
        HTML('</div>'),
        
        HTML('<div align="left">'),
        selectInput(inputId = "obj", label = "Minimize: ", choices = dobj[["nam"]]),
        selectInput(inputId = "wgt", label = "Weighted By: ", choices = dwgt[["nam"]]),
        selectInput(inputId = "pfx", label = "Prefixed On: ", choices = c("Prefixed On" = "", dsrc[["id"]]), multiple = TRUE),
        numericInput(inputId = "kwh", label = "Toward #WH: ", value = 10L, min = 1L, max = 51L),
        br(),
        numericInput(inputId = "nas", label = "Advanced Option - # Random Start: ", value = 100L, min = 1L, max = 1000L),
        HTML('</div>'),
        
        HTML('<div align="right">'),
        actionButton(inputId = "fnd", label = "Find Warehouse Locations"),
        HTML('</div>'),
        
        conditionalPanel(
          condition = "input.fnd",
          br(),
          br(),
          HTML('<div align="center">'),
          h4("Optimal Warehouse Locations"),
          HTML('</div>'),
          HTML('<div align="left">'),
          numericInput(inputId = "otk", label = "Optimality Rank: ", value = 1L, min = 1L, max = 1000L),
          selectInput(inputId = "oms", label = "Map Color Measure: ", choices = dobj[["nam"]]),
          HTML('</div>'),
          HTML('<div align="right">'),
          actionButton(inputId = "ovw", label = "View Warehouse Locations"),
          HTML('</div>')
        )
      ),
      
      conditionalPanel(
        condition = "input.fnd",
        absolutePanel(
          id = "cpan", class = "panel panel-default", fixed = TRUE, draggable = TRUE, 
          top = "auto", left = "auto", right = 540, bottom = 70, width = 200, height = "auto",
          DT::dataTableOutput("tbk")
        )
      ),
      
      conditionalPanel(
        condition = "input.fnd",
        absolutePanel(
          id = "cpan", class = "panel panel-default", fixed = TRUE, draggable = TRUE, 
          top = "auto", left = 40, right = "auto", bottom = 70, width = 200, height = "auto",
          DT::dataTableOutput("cpan_tb")
        )
      ),
      
      tags$div(
        
        id = "cite", tags$em('OWL: Optimal Warehouse Locator'), ' - a demonstration on the use case of ', tags$em('skm R package'), ' by ', tags$em('Guang Yang @gyang274.')
        
      )
      
    ),
    
    div(
      
      class = "msgs", textOutput(outputId = "msg")
      
    )
    
  ),

  tabPanel(
    
    title = "Data Explorer",
    
    fluidRow(
      
      h4("Explore U.S. ZIP2012 Data: "),
      
      column(
        
        width = 4L,
        
        selectInput(inputId = "pdeStt", label = "States: ", choices = c("All States" = "", dstt), multiple = TRUE)
        
      ),
      
      conditionalPanel(
        
        condition = "input.pdeStt",
        
        column(
          
          width = 4L,
          
          selectInput(inputId = "pdeCit", label = "Cities: ",  choices = c("All Cities" = ""), multiple = TRUE)
          
        )
        
      )
      
    ),
    
    fluidRow(
      
      column(
        
        width = 2L, actionButton(inputId = "shw", label = "Show Table")
        
      )
      
    ),
    
    hr(),
    
    DT::dataTableOutput("pdeDEV")
    
  ),
  
  tabPanel(
    
    title = "README",
    
    includeMarkdown("README.md")
    
  )
  
  # , conditionalPanel("false", icon("crosshair"))
  
))
