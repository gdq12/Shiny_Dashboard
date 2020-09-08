Summary
-------

The purpose is to take a brief look at data from
[kaggle](https://www.kaggle.com/aungpyaeap/supermarket-sales),
supermarket sales from 3 locations in Myanmar, and build a regression
model to later be implemented ina shiny app.

Getting the Data
----------------

``` r
library(dplyr)
library(lubridate)
library(car)
```

``` r
supermarket=read.csv('supermarket_sales.csv')

#supermarket=supermarket %>% subset(select=-c(gross.margin.percentage, gross.income)) %>% mutate(Time2=paste(Date, Time)) %>% mutate(Time2=parse_date_time(Time2, orders="m/d/Y H:M")) %>% subset(select=-c(Date, Time))

supermarket=supermarket %>% subset(select=-c(gross.margin.percentage, gross.income)) %>% mutate(Date2=paste(Date, Time)) %>% mutate(Date2=parse_date_time(Date2, orders="m/d/Y H:M")) %>% mutate(Time2=hm(Time)) %>% subset(select=-c(Date, Time))

str(supermarket)
```

    'data.frame':   1000 obs. of  15 variables:
     $ Invoice.ID   : chr  "750-67-8428" "226-31-3081" "631-41-3108" "123-19-1176" ...
     $ Branch       : chr  "A" "C" "A" "A" ...
     $ City         : chr  "Yangon" "Naypyitaw" "Yangon" "Yangon" ...
     $ Customer.type: chr  "Member" "Normal" "Normal" "Member" ...
     $ Gender       : chr  "Female" "Female" "Male" "Male" ...
     $ Product.line : chr  "Health and beauty" "Electronic accessories" "Home and lifestyle" "Health and beauty" ...
     $ Unit.price   : num  74.7 15.3 46.3 58.2 86.3 ...
     $ Quantity     : int  7 5 7 8 7 7 6 10 2 3 ...
     $ Tax.5.       : num  26.14 3.82 16.22 23.29 30.21 ...
     $ Total        : num  549 80.2 340.5 489 634.4 ...
     $ Payment      : chr  "Ewallet" "Cash" "Credit card" "Ewallet" ...
     $ cogs         : num  522.8 76.4 324.3 465.8 604.2 ...
     $ Rating       : num  9.1 9.6 7.4 8.4 5.3 4.1 5.8 8 7.2 5.9 ...
     $ Date2        : POSIXct, format: "2019-01-05 13:08:00" "2019-03-08 10:29:00" ...
     $ Time2        :Formal class 'Period' [package "lubridate"] with 6 slots
      .. ..@ .Data : num  0 0 0 0 0 0 0 0 0 0 ...
      .. ..@ year  : num  0 0 0 0 0 0 0 0 0 0 ...
      .. ..@ month : num  0 0 0 0 0 0 0 0 0 0 ...
      .. ..@ day   : num  0 0 0 0 0 0 0 0 0 0 ...
      .. ..@ hour  : num  13 10 13 20 10 18 14 11 17 13 ...
      .. ..@ minute: num  8 29 23 33 37 30 36 38 15 27 ...

Feature Selection
-----------------

1.  Must select features that are independent of all others. Current
    features:

<!-- -->

     [1] "Invoice.ID"    "Branch"        "City"          "Customer.type"
     [5] "Gender"        "Product.line"  "Unit.price"    "Quantity"     
     [9] "Tax.5."        "Total"         "Payment"       "cogs"         
    [13] "Rating"        "Date2"         "Time2"        

Here, Total will be identified as the dependent variable (*y*), and the
following will be considered as independent variables (*x*): Gender,
City, Product.line, Customer.type, Unit.price, Quantity, Payment,
Rating.

1.  Verify that there isn’t linear dependence between the features:

``` r
fit=lm(Total ~ factor(Gender) + City + Product.line + Customer.type + Unit.price + Quantity + Payment + Rating, data=supermarket)

alias(fit)
```

    Model :
    Total ~ factor(Gender) + City + Product.line + Customer.type + 
        Unit.price + Quantity + Payment + Rating

No complete or partial dependence was report, therefor no linear
dependence detected among the features.

1.  Examine each feature variability when correlated to the other
    features compared to when they are orthogonal:

``` r
sqrt(vif(fit))[,1]
```

    factor(Gender)           City   Product.line  Customer.type     Unit.price 
          1.009836       1.012011       1.020602       1.005552       1.002768 
          Quantity        Payment         Rating 
          1.006418       1.010795       1.003803 

There isn’t much variability in the results, but out of all of them,
Product.line showed the greatest variability.

Model Selection
---------------

Run ANOVA to determine which combination of features that contributes to
the best model:

``` r
fit=lm(Total ~ Gender, supermarket)
fit1=update(fit, Total ~ Gender + City+ Customer.type + Rating)
fit2=update(fit1, Total ~ Gender + City + Customer.type + Rating + Unit.price + Quantity + Payment)
fit3=update(fit2, Total ~ Gender + City + Customer.type + Rating + Unit.price + Quantity + Payment + Time2)
anova(fit, fit1, fit2, fit3)
```

    Analysis of Variance Table

    Model 1: Total ~ Gender
    Model 2: Total ~ Gender + City + Customer.type + Rating
    Model 3: Total ~ Gender + City + Customer.type + Rating + Unit.price + 
        Quantity + Payment
    Model 4: Total ~ Gender + City + Customer.type + Rating + Unit.price + 
        Quantity + Payment + Time2
      Res.Df      RSS Df Sum of Sq         F    Pr(>F)    
    1    998 60251438                                     
    2    994 60058772  4    192667    7.2531  9.32e-06 ***
    3    990  6574471  4  53484300 2013.4492 < 2.2e-16 ***
    4    990  6574471  0         0                        
    ---
    Signif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1

Based on the p-value for each nested model, fit2 model (Gender + City +
Customer.type + Rating + Unit.price + Quantity + Payment) has the
greatest impact on Total.
