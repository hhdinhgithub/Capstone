library(jsonlite)
library(rjson)
library(dplyr)
library(ggplot2)
library(xtable)

setwd("~/CT/data")

loadData <- function(json) {
  lines <- readLines(json)
  json.lines <- lapply(1:length(lines), function(x) { fromJSON(lines[x])})
}

## Read checkin json file

checkin_json <- loadData("yelp_academic_dataset_checkin.json")

## Checkin count
for (i in 1:length(checkin_json)) {
  checkins <- sum(unlist(checkin_json[[i]][-(c(length(checkin_json[[i]]), length(checkin_json[[i]]) - 1))]))
  business_id <- checkin_json[[i]]$business_id
  
  checkin_json[[i]] <- list(business_id = business_id, checkins = checkins)
}
checkin_data <- data.frame(matrix(unlist(checkin_json), nrow = length(checkin_json), byrow = TRUE))
names(checkin_data) <- names(checkin_json[[1]])

##Load Business data

business_data <- stream_in(file("yelp_academic_dataset_business.json"))
#second time load from rds to save time
#business_data <- readRDS("biz.rds")

##Merge with Checkin data 
business_data <- merge(business_data, checkin_data, by = "business_id")

##Convert to right data type to be proceed
business_data$checkins <- as.numeric(as.character(business_data$checkins))
business_data$review_count <- as.numeric(as.character(business_data$review_count))
business_data$stars <- factor(business_data$stars)

saveRDS(business_data,"business_data.rds")
#business_data <- readRDS("business_data.rds")
business_data <- flatten(business_data)

business_data$full_address <- as.character(business_data$full_address)
#Sum up reviews and checkins
cities_data <-  business_data %>% group_by(city) %>% summarize(reviews = sum(review_count), 
                                                                 checkins = sum(checkins))

cities_data <- cities_data[with(cities_data, order(-checkins)), ]
cities_data$percentage <- (cities_data$reviews/cities_data$checkins)*100

knitr::kable(cities_data)[1:5]

head(cities_data,10)

##Find out the average star rating of each Business

plot1 <- ggplot(business_data, aes(x=stars ,y=log(checkins),fill=stars)) + 
  geom_boxplot(notch=F) + xlab("Average star rating") + ylab("Number of checkins") +
  ggtitle("Business Exploratory Data Analysis")  + theme_bw()

plot1

## get business for Las Vegas
las_business <- business_data[grep("Las Vegas",business_data$city),] #Las-Vegas

## select only Restaurants for Las Vegas
las_business_res <- las_business[grep("Restaurants",las_business$categories),]

plot2 <- ggplot(las_business_res, aes(x=stars ,y=log(checkins),fill=stars)) + 
  geom_boxplot(notch=F) + xlab("Average star rating") + ylab("Number of checkins") +
  ggtitle("Business Exploratory Data Analysis")  + theme_bw()

plot2

saveRDS(las_business_res,"las_business_res1.rds")

##Explore Business Attributes
las_business_res$good4kids <- as.numeric(las_business_res$`attributes.Good for Kids`)
las_business_res$good4groups <- as.numeric(las_business_res$`attributes.Good For Groups`)
las_business_res$pricerange <- las_business_res$`attributes.Price Range`
las_business_res$reservations <- as.numeric(las_business_res$`attributes.Takes Reservations`)
las_business_res$open24h <- as.numeric(las_business_res$`attributes.Open 24 Hours`)
##Convert logical to 0 and 1
las_business_res$good4kids[is.na(las_business_res$good4kids)] <- 0
las_business_res$good4groups[is.na(las_business_res$good4groups)] <- 0
las_business_res$pricerange[is.na(las_business_res$pricerange)] <- 0
las_business_res$reservations[is.na(las_business_res$reservations)] <- 0

saveRDS(las_business_res,"las_business_res.rds")
##Subset data for processing

las_business_res <- las_business_res[,c("business_id","full_address","categories","city","state",
                                        "name","review_count", "stars","checkins","good4kids","good4groups",
                                        "pricerange","reservations","open24h")]

##Read review data

review_data <- stream_in(file("yelp_academic_dataset_review.json"))
saveRDS(review_data,"review_data.rds")

## subset only review for Las Vegas restaurants business
las_review_res <- review_data[review_data$business_id %in% las_business_res$business_id, ]
saveRDS(las_review_res,"las_review_res.rds")

#las_review_res <- readRDS("las_review_res.rds")
las_review_res <- flatten(las_review_res)

## convert date to date type
las_review_res$date <- as.Date(las_review_res$date)

library(dplyr)
las_review_res_n <- las_review_res %>% group_by(business_id) %>% summarize(start_date=min(date), end_date=max(date), 
                                                          funny=sum(votes.funny), cool=sum(votes.cool), useful=sum(votes.useful))
las_review.res_n <- las_review_res_n[complete.cases(las_review_res_n),]

## calculate lifespan of restaurant, we take the last day (end_date) of review as date the restaurant is out of business
las_review_res_n$lifespan <- as.numeric(las_review_res_n$end_date - las_review_res_n$start_date)

final_business_data$open24h[is.na(las_business_res$open24h)] <- 0
###Marge with las_business_res and review to prepare a final data for regression
final_business_data <- merge(las_business_res, las_review_res_n, by = "business_id")

review_count_data <- final_business_data

review_count_data$ReviewCount = '<50'
review_count_data$ReviewCount[review_count_data$review_count > 50] = '50-200'
review_count_data$ReviewCount[review_count_data$review_count > 200] = '200-500'
review_count_data$ReviewCount[review_count_data$review_count > 500] = '500-1000'
review_count_data$ReviewCount[review_count_data$review_count > 1000] = '>1000'

qplot(data=review_count_data,checkins,review_count,color = ReviewCount) +
  xlab("checkins ") +
  ylab("Number of review count")

saveRDS(final_business_data,"final_business_data.rds")
#final_business_data <- readRDS("final_business_data.rds")

## get subset of final_business_data
regression_data <- final_business_data[,c("review_count", "stars","checkins","lifespan","good4kids","good4groups",
                                          "pricerange","reservations","open24h")]

regression_data$stars <- as.numeric(regression_data$stars)
## fit the model

full_model <- lm(checkins ~ ., data = regression_data)
summary(full_model)
best_model <- step(full_model, direction = "both")
summary(best_model)

##Corelation
cor(regression_data$review_count,regression_data$cool)
cor(regression_data$review_count,regression_data$useful)
cor(regression_data$review_count,regression_data$funny)

##Fitting model
fit1 <- lm(checkins ~ review_count + stars + good4groups, data = regression_data)
fit2 <- lm(checkins ~ review_count + stars + good4kids , data = regression_data)
fit8 <- lm(checkins ~ review_count + stars + pricerange , data = regression_data)

round(dfbetas(fit8)[1:10],3)
round(hatvalues(fit8)[1:10],3)

##summary best fit
summary(fit8)$coef
summary(fit8)

par(mfrow = c(2,2))
plot(fit8)

##Checking
confint(fit8)
vif(fit8)
