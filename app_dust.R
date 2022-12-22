# using plotly and magick to provide some dust-cleaning functions
# library(magrittr)
library(shiny)
library(magick)

## ui.R
ui <- fluidPage(
  shinyjs::useShinyjs(),
  titlePanel("Photo Duster", windowTitle = "Photo Duster"),
  verticalLayout(
    inputPanel(
      fileInput("file1", "Choose .jpg file", accept = ".jpg"),
      checkboxInput("showDust", "Show dust", TRUE),
      checkboxInput("showOriginal", "Show original", FALSE),
      sliderInput("zoom", "Image Zoom", min = 1, max = 400, 
                  value = 80, post = "%"),
      sliderInput("md_radius", "Md Radius", min = 2, max = 15,
                  value = 6, post = "px"),
      # this should force avoidance of whole numbers
      sliderInput("k_radius", "Kernel Radius", min = 1.0, max = 10.0,
                  value = 1.8, post = "px", step = 0.2),
      sliderInput("threshold", "Threshold", min = 1, max = 10,
                  value = 7, post = "%"),
      actionButton("reset", "Reset")
    ),
    fluidRow(
      shinydashboard::box(width = 12, 
                          style='width:600px;overflow-x: scroll;height:400px;overflow-y: scroll;',
                          plotOutput("p1", width = "100%")
      )),
    fluidRow(
      conditionalPanel(
        condition = "input.showOriginal",
        titlePanel("Original:"),
        shinydashboard::box(width = 12, 
                            style='width:600px;overflow-x: scroll;height:400px;overflow-y: scroll;',
                            plotOutput("p0", width = "100%"))
      )),
    fluidRow(
      conditionalPanel(
        condition = "input.showDust",
        titlePanel("Dust:"),
        shinydashboard::box(width = 12, 
                            style='width:600px;overflow-x: scroll;height:400px;overflow-y: scroll;',
                            plotOutput("pd", width = "100%"))
      ))
  )
)

img_list <- function(img){
  # return a list structure containing the image magick image
  w <- image_info(img)$width
  h <- image_info(img)$height
  list(
    img = img,
    w = w,
    h = h
  )
}

## server.R
server <- function(input, output, session){
  
  observeEvent(input$reset, {
    shinyjs::reset("zoom")
    shinyjs::reset("md_radius")
    shinyjs::reset("k_radius")
    shinyjs::reset("threshold")
  })
  
  #get image and its metadata
  i_raw <- reactive({
    i_file <- "data/Dust1_323x302.jpg" #default during development
    if (is.data.frame(input$file1)) i_file <- req(input$file1$datapath)
    # i_file <-  "data/Dust1_323x302.jpg"
    img <- image_read(i_file) |> 
      image_convert("png")
    
    img_list(img) #result
  })

  # a function factory to conveniently get out an images dimension
  img_dim_f <- function(parm, min_pix = 40) {
    function() {
      p <- 0
      i <- req(i_raw())
      if (isTruthy(i)) {
        if (isTruthy(i[[parm]])) {
          p <- i[[parm]]
        }
      }
      z <- req(input$zoom)
      # zoom, keep integer and not smaller than min_pix (some distortion possible)
      max(ceiling(p * z/100), min_pix)
    }
  }
  
  # i_renderPlot <- function(i_fn){
  #     renderPlot(
  #       expr = {
  #         i <- req(i_fn())
  #         img <- req(i$img)
  #         plot(img)
  #       },
  #       width = img_dim_f("w"),
  #       height = img_dim_f("h")
  #     )
  # }
  # 
  i_mask <- reactive({
    req(i_raw(), input$k_radius, input$threshold)
    i <- i_raw()
    # find peaks
    img <- i$img |> 
      image_morphology("bottomhat", stringr::str_c("disk:", 
                                                   round(input$k_radius, 1))) |> 
      image_threshold(threshold = stringr::str_c(input$threshold, "%"),
                      type = "white")
    
    img_list(img) #result
  })
  
  i_final <- reactive({
    req(i_raw(), i_mask(), input$md_radius)
    i <- i_raw()
    img1 <- i$img |> 
      # smoothing
      image_median(radius = input$md_radius) |> 
      # just the mask bit of this
      image_composite(i_mask()$img, operator = "CopyOpacity")
   # combine
    img <- i$img |>
      image_composite(img1, operator = "atop") 

    img_list(img) #result
  })

  # default params
  i_renderPlot <- function(...){renderPlot(..., width = img_dim_f("w"),
                                      height = img_dim_f("h"))}
    
  # graphical outputs
  output$p0 <- i_renderPlot({plot(i_raw()$img)})
  
  output$pd <- i_renderPlot({
    plot(i_mask()$img)
  })
  
  output$p1 <- i_renderPlot({
      plot(i_final()$img)
    })
  
  return(output)
}




### Run Application
shinyApp(ui, server, options = list("launch.browser" = TRUE))