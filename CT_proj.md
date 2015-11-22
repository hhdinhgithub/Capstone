
Capstone Project
========================================================
author: Dinh Huy Hoang
date: 18th Nov 2015


<style>

/* slide titles */
.reveal h3 { 
  font-size: 50px;
  color: blue;
}

/* heading for slides with two hashes ## */
.reveal .slides section .slideContent h2 {
   font-size: 50px;
   font-weight: bold;
   color: green;
}

/* ordered and unordered list styles */
.reveal ul, 
.reveal ol {
    font-size: 25px;
    color: black;
    list-style-type: square;
}

</style>

## Check-ins Restaurants in Las Vegas city base on number of reviews, stars and its price range


Question
=======================================================
- Question: **Can number of reviews, average star and its price range decide the checkins customers of a restaurant in Las Vegas - one of top tourist destinations in the United States?**
- *Numbers of checkins customers will decide the sustainability of a restaurant* - more customers it means the business will be sustainable and success.
- Methods
  - Load, Merge, Transform Yelp data and subset data for Restaurant in Las Vegas
  - Exploratory Restaurant Data Analysis 
  - Build the **Multiple Linear Regression** model to find the relationship and Conclusions



Yelp Data and Exploratory Restaurant Data
========================================================
- The Yelp Dataset is Q3 2015 and store in json format
- In this report, we need **Review data**:1569264 reviews, **Business data**:61184 businesses, and **Checkin data**:45166 checkins(Over time for each of the 61K businesses)
- Load, Merge checkins, Business, Review data (by business id) and transform it
- Subset for Restaurant Data in Las Vegas
![plot of chunk unnamed-chunk-1](CT_proj-figure/unnamed-chunk-1-1.png) 
- The above plot is very encouraging that there is a strong relationship between number of **reviews vs checkins** 

Build the Multiple Linear Regression
========================================================
$$
Y_i =  \beta_1 X_{1i} + \beta_2 X_{2i} + \ldots +
\beta_{p} X_{pi} + \epsilon_{i} 
= \sum_{k=1}^p X_{ik} \beta_j + \epsilon_{i}
$$

- Where $\beta_{n}$ slopes, $X{ni}$ are variables and $\epsilon_{i}$ residuals which are normally distributed 
- The Selection Strategy: Use use stepwise function and select a good model 
(checkins ~ review_count + stars + good4kids + good4groups + pricerange)
- Further test and Remove good4kids and good4groups as it has high standard error 
- Final regression model (checkins ~ review_count + stars + pricerange)
- The Result of regression model is
$$
C_i =  62.18709 + 2.67446 * R{i} + 22.15197 * S{i} - 93.19717 * P{i}
$$
Where: $C{i}$ is checkins(customer) of ${i}$ restaurant, $R{i}$ is review_count of each restaurant, $S{i}$ is star of each restaurant, $P{i}$ is price range

Conclusion
========================================================
- There is strong relationship between checkin customers and reviews, star rating and its price range to answer to the primary question of interest, both qualitatively and quantitatively





```r
confint(fit8)
```

```
                   2.5 %    97.5 %
(Intercept)    17.489040 106.88513
review_count    2.631827   2.71709
stars          15.232721  29.07123
pricerange   -106.848941 -79.54541
```
- With 95% confidence, Reviews increase results in a 2.631827 to 2.71709, increase in total checkins, holding other variables fixed. And other intervals also can be interpreted similarly.

Thank You.
