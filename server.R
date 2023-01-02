# using plotly and magick to provide some dust-cleaning functions
library(shiny)
library(magick)

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
    # shinyjs::reset("zoom")
    shinyjs::reset("trim")
    shinyjs::reset("k_radius")
    shinyjs::reset("threshold")
    shinyjs::reset("md_radius")
    shinyjs::reset("f_radius")
  })
  
  #get image and its metadata
  i_raw <- reactive({
    req(input$file1)
    # i_file <- "data/Dust1_323x302.jpg" #default during development
    if (is.data.frame(input$file1)) i_file <- req(input$file1$datapath)
    # i_file <-  "data/Dust1_323x302.jpg"
    img <- image_read(i_file) |> 
      image_convert("png")
    
    # cat(file=stderr(), input$file1$datapath, input$file1$name)
    img_list(img) #result
  })

  # first remove any unwanted border
  i_trim <- reactive({
    req(i_raw(), input$trim)
    img <- i_raw()$img |> 
      # trim black edges (not just black due to jpeg)
      image_trim(fuzz = input$trim) 
    img_list(img)
  })
  
  # smoothed image, for filling in with
  i_md <- reactive({
    req(i_trim(), input$md_radius)
    img <- i_trim()$img |> 
      # smoothing
      image_median(radius = input$md_radius)  
    img_list(img)
  })
  
  # a function factory to conveniently get out an images dimension
  img_dim_f <- function(parm, min_pix = 40) {
    function() {
      p <- 0
      i <- req(i_trim())
      if (isTruthy(i)) {
        if (isTruthy(i[[parm]])) {
          p <- i[[parm]]
        }
      }
      # scale is fit image to window height
      sc <- 400/i$h #400 pix is height defined above
      # zoom is user-selected magnification
      z <- req(input$zoom)
      # zoom, keep integer and not smaller than min_pix (some distortion possible)
      max(ceiling(p * sc * z/100), min_pix)
    }
  }
  
  # create the dust mask
  i_mask <- reactive({
    req(i_trim(), input$k_radius, input$threshold, input$f_radius)
    # find peaks
    img <- i_trim()$img |> 
      image_morphology("bottomhat", stringr::str_c("disk:", 
                                                   round(as.numeric(input$k_radius), 1))) |> 
      image_threshold(threshold = stringr::str_c(input$threshold, "%"),
                      type = "white") |> 
      # dilate by a pixel. default rectangle is a 3x3-pixel square
      image_morphology("dilate", stringr::str_c("disk:", 
                                                round(as.numeric(input$f_radius), 1)))
    
    img_list(img) #result
  })
  
  i_final <- reactive({
    req(i_trim(), i_md(), i_mask())
    img1 <- i_md()$img |> 
      # just the mask bit of this
      image_composite(i_mask()$img, operator = "CopyOpacity")
   # combine
    img <- i_trim()$img |>
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
  
  output$download <- downloadHandler(
    filename = function() {
      paste0(stringr::str_remove(input$file1$name, ".jpg|.tif|.png"), "_dusted.", input$download_type)
    },
    content = function(file) {
      image_write(i_final()$img, file, format = input$download_type)
    }
  )
  
  return(output)
}


### Run Application
# shinyApp(ui, server, options = list("launch.browser" = TRUE))