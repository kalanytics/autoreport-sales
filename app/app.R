library(shiny)
library(shinyWidgets)
library(tidyverse)

raw <- read_csv(here::here("data/supermarket_sales - Sheet1.csv")) %>% 
  mutate(Date = lubridate::mdy(Date))

ui <- fluidPage(
  title = "Auto Report",
  tags$div(class = "container", style = "text-align:center;",
           h1("Supermarket Report Generator"), tags$br()),
  
  tags$div(class = "container", style = "background-color: #F8f8f8; padding: 20px;",
           h3("Choose Your Inputs"),
           tags$br(),
           pickerInput(
             inputId = "idCity",
             label = "Pick Branch", 
             choices = raw$City %>% unique()
           ), tags$br(),
           
           dateInput(
             "idStart",
             "Pick Starting Date",
             value = raw$Date %>% min(),
             min = raw$Date %>% min(), 
             max = raw$Date %>% max()
           ), tags$br(),
           
           dateInput(
             "idEnd",
             "Pick End Date",
             value = raw$Date %>% max(),
             min = raw$Date %>% min(), 
             max = raw$Date %>% max()
           ), tags$br(),
           
           downloadButton("reportHTML", 
                          "Generate Interactive HTML Report", 
                          style = "width:100%;"), tags$br(), tags$br(),
           
           downloadButton("reportPDF", 
                          "Generate PDF Report", 
                          style = "width:100%;")
           ),
  
  tags$div(class = "container", style = "padding: 15px;",
           p("Dataset Source :", tags$a("kaggle/aungpyaetap", href = "https://www.kaggle.com/aungpyaeap/supermarket-sales")))
  
)

server <- function(input, output, session) {
  
  output$reportHTML <- downloadHandler(
    filename =  "report.html",
    
    content = function(file) {
      # Copy the report file to a temporary directory before processing it, in
      # case we don't have write permissions to the current working dir (which
      # can happen when deployed).
      tempReport <- file.path(tempdir(), "template1.Rmd")
      file.copy("template1.Rmd", tempReport, overwrite = TRUE)
      
      # Set up parameters to pass to Rmd document
      params <- list(
        startDate = input$idStart,
        endDate = input$idEnd,
        branch = input$idCity
      )
      
      # Knit the document, passing in the `params` list, and eval it in a
      # child of the global environment (this isolates the code in the document
      # from the code in this app).
      rmarkdown::render(tempReport, output_file = file,
                        params = params,
                        envir = new.env(parent = globalenv())
      )
    }
  )
  
  output$reportPDF <- downloadHandler(
    filename =  "report.pdf",
    content = function(file) {
      tempReport <- file.path(tempdir(), "template1.Rmd")
      file.copy("template1.Rmd", tempReport, overwrite = TRUE)
      
      params <- list(
        startDate = input$idStart,
        endDate = input$idEnd,
        branch = input$idCity
      )
      
      html_fn <- rmarkdown::render(tempReport,  params = params,
                                   envir = new.env(parent = globalenv()))
      
      pagedown::chrome_print(html_fn, file)
    }
  )
  
}

shinyApp(ui, server)