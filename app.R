library(shiny)
library(shinydashboard)
library(car)
library(dplyr)
library(plotly)
library(lubridate)
library(forecast)
library(leaflet)
library(knitr)
library(rmarkdown)

ui=dashboardPage(
    dashboardHeader(title='Supermarket Sales'),
    dashboardSidebar(
        sidebarMenu(
            menuItem('About Dashboard', tabName='About', icon=icon('book')),
            menuItem('Dashboard', tabName='Dashboard', icon=icon('dashboard')),
            menuItem('Predicting Revenue', tabName='Predict', 
                     icon=icon('funnel-dollar'))
        )
    ),
    dashboardBody(
        tabItems(
            tabItem(tabName='About',
                box(uiOutput('about_shiny'),
                    width=12)),
            tabItem(tabName='Dashboard',
                fluidRow(
                    box(plotlyOutput('plot1', height=400)),
                    box(plotlyOutput('plot2', height=400))),
                fluidRow(
                    box(h3('City locations in Myanmar:'), 
                        leafletOutput('map', height=400)),
                    box(plotlyOutput('plot3', height=400))),
                fluidRow(
                    box(plotlyOutput('plot4', height=400)),
                    box(plotlyOutput('plot5', height=400)))),
            tabItem(tabName='Predict',
                fluidRow(
                    box(selectInput('cityChoice', 'Select City:', 
                                    c('Mandalay'='Mandalay', 
                                      'Naypyitaw'='Naypyitaw', 
                                      'Yangon'='Yangon'))),
                    box(selectInput('productChoice', 'Select Product:',
                                    c('Electronic'='Electronic accessories',
                                      'Fashion'='Fashion accessories',
                                      'Food & Beverage'='Food and beverages',
                                      'Health & Beauty'='Health and beauty',
                                      'Home & Lifestyle'='Home and lifestyle',
                                      'Sports & Travel'='Sports and travel')))),
                fluidRow(
                    box(checkboxInput('memberCheck', 'Check if Member', value=TRUE)),
                    box(sliderInput('unitPrice', 'What\'s the products unit price?',
                                    min=10, max=100, value=25, step=0.1))),
                fluidRow(
                    box(sliderInput('quantityCount', 
                                    'How many items did the customer buy?',
                                    min=1, max=10, value=5)),
                    box(selectInput('paymentChoice', 'Select paymnet method:',
                                    c('Cash'='Cash', 
                                      'Credit Card'='Credit card',
                                      'Ewallet'='Ewallet')))),
                fluidRow(
                    box(sliderInput('ratingChoice', 
                                    'What rating did the customer give?',
                                    min=4, max=10, value=5, step=0.1)),
                    box(selectInput('genderChoice', 'Select Customer Gender:',
                                    c('Male'='Male',
                                      'Female'='Female'))),
                    box(h3('Predicted revenue in Burmese kyat:'),
                        textOutput('pred1')
                        )
                )
            )
        )
    )
)

server=function(input, output){
    supermarket=read.csv('supermarket_sales.csv')
    supermarket=supermarket %>% 
        subset(select=-c(gross.margin.percentage, gross.income)) %>% 
        mutate(Date2=paste(Date, Time)) %>% 
        mutate(Date2=parse_date_time(Date2, orders="m/d/Y H:M")) %>% 
        mutate(Time2=hm(Time)) %>% 
        subset(select=-c(Date, Time))
    
    myanmar_df=data.frame(City=c('Mandalay', 'Naypyitaw', 'Yangon'),
                          lat=c(21.9588, 19.7633, 16.8409),
                          lng=c(96.0891, 96.0785, 96.1735))
    
    supermarket1=supermarket %>% 
        group_by(City, Date2) %>% 
        summarize(Rating.city=mean(Rating))
    
    char_layout=list(type='buttons',
                     x=0, y=1.30,
                     buttons=list(list(method='relayout',
                                       args=list('barmode', 'group'),
                                       label='non-stack'),
                                  list(method='relayout',
                                       args=list('barmode', 'stack'),
                                       label='stack')))
    normal=list(
        x=supermarket1$Date2,
        y=supermarket1$Rating.city,
        xref='x', yref='y')
    
    filter=list(
        x=supermarket1$Date2,
        y=ma(supermarket1$Rating.city, order=7),
        xref='x', yref='y')
    
    updatemenus=list(
        list(
            active=-1,
            type='buttons',
            buttons=list(
                list(
                    label='Normal',
                    method='update',
                    args=list(list(visible=c(FALSE,FALSE,FALSE,TRUE,TRUE,TRUE)),
                              list(title='Normal Timecourse',
                                   annotations=list(normal)))),
                list(
                    label='Filter',
                    method='update',
                    args=list(list(visible=c(TRUE,TRUE,TRUE,FALSE,FALSE,FALSE)),
                              list(title='Filtered Timecourse',
                                   annotations=list(filter)))))))
    fit=lm(Total ~ factor(Gender) + 
               City + Product.line + Customer.type + 
               Unit.price + Quantity + Payment + Rating, data=supermarket)
    
    output$about_shiny=renderUI({
        rmarkdown::render(input='about_shiny.Rmd',
                          output_format=html_document(self_contained=T),
                          output_file='about_shiny.html')
        shiny::includeHTML('about_shiny.html')
    })
    
    output$plot1=renderPlotly({supermarket %>% 
        group_by(City, Customer.type) %>% 
        summarize(Revenue=sum(Total)) %>% 
        plot_ly(x=~City, y=~Revenue, color=~Customer.type, type='bar') %>% 
        layout(updatemenus=list(char_layout), barmode='group', 
               title='Revenue by Membership') %>%
        config(modeBarButtons=list(list('resetScale2d'), 
                                   list('zoomIn2d'), list('zoomOut2d')))
    })
    output$plot2=renderPlotly({supermarket %>% 
            group_by(City, Payment) %>% 
            summarize(Revenue=sum(Total)) %>% 
            plot_ly(x=~City, y=~Revenue, color=~Payment, type='bar') %>% 
            layout(updatemenus=list(char_layout), barmode='group', 
                   title='Revenue by Payment Form') %>%
            config(modeBarButtons=list(list('resetScale2d'), 
                                       list('zoomIn2d'), list('zoomOut2d')))
    })
    output$map=renderLeaflet({myanmar_df %>% 
            leaflet() %>% 
            addTiles() %>% 
            addMarkers(label=~City)
    })
    output$plot3=renderPlotly({
        fig1=supermarket %>% 
            mutate(Month=month(Date2, label=T)) %>% 
            group_by(Product.line, Gender, Month) %>% 
            summarize(Revenue=mean(Total)) %>% 
            subset(Gender=="Female") %>% 
            plot_ly(x=~Month, y=~Revenue, color=~Product.line, type='bar') %>% 
            layout(annotations=list(x=0, y=1.05, xanchor="middle", 
                                    yanchor="top", text="Female", 
                                    showarrow=F, xref="paper", yref="paper"), 
                   updatemenus=list(char_layout), barmode='group')
        fig2=supermarket %>% 
            mutate(Month=month(Date2, label=T)) %>% 
            group_by(Product.line, Gender, Month) %>% 
            summarize(Revenue=mean(Total)) %>% 
            subset(Gender=="Male") %>% 
            plot_ly(x=~Month, y=~Revenue, color=~Product.line, type='bar') %>% 
            layout(annotations=list(x=1, y=1.05, xanchor="middle", 
                                    yanchor="top", text="Male", 
                                    showarrow=F, xref="paper", yref="paper"), 
                   updatemenus=list(char_layout), barmode='group')
        fig3=subplot(style(fig1, showlegend=F), fig2, shareY=T) %>%
                layout(title='Product Revenue by Gender') %>% 
                config(modeBarButtons=list(list('resetScale2d'), 
                                           list('zoomIn2d'), list('zoomOut2d')))
        fig3
    })
    output$plot4=renderPlotly({plot_ly(alpha=0.6) %>% 
            add_histogram(x=supermarket[supermarket$Gender=="Female",]$Rating, 
                          name="Female") %>% 
            add_histogram(x=supermarket[supermarket$Gender=="Male",]$Rating, 
                          name="Male") %>% 
            layout(barmode='overlay', xaxis=list(title="Rating"), 
                   yaxis=list(title='Frequency'), title='Ratings by Gender') %>%
            config(modeBarButtons=list(list('resetScale2d'), 
                                       list('zoomIn2d'), list('zoomOut2d')))
    })
    output$plot5=renderPlotly({supermarket1 %>% 
            plot_ly(color=~City, type='scatter', mode='lines') %>%
            add_lines(x=~Date2, y=~Rating.city) %>% 
            add_lines(x=~Date2, y=~ma(Rating.city, order=7)) %>% 
            layout(title='Ratings over time', showlegend=TRUE, 
                   updatemenus=updatemenus, xaxis=list(title='Time'), 
                   yaxis=list(title='Rating')) %>%
            config(modeBarButtons=list(list('resetScale2d'), 
                                       list('zoomIn2d'), list('zoomOut2d')))
    })
    modelPred=reactive({
        City=input$cityChoice
        Product=input$productChoice
        Membership=input$memberCheck
        Unit=input$unitPrice
        Quantity=input$quantityCount
        Payment=input$paymentChoice
        Rating=input$ratingChoice
        Gender=input$genderChoice
        predict(fit, newdata=data.frame(Gender=Gender,
                                        City=City,
                                        Product.line=Product ,
                                        Customer.type=ifelse(Membership,
                                                             'Member', 'Normal'),
                                        Unit.price=Unit,
                                        Quantity=Quantity,
                                        Payment=Payment,
                                        Rating=Rating))
    })
    output$pred1=renderText({modelPred()})
}

shinyApp(ui, server)