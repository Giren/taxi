library(plyr)

x <- 0:4
y <- c(1, -1, 1, -1, 1)
#y <- seq(0,100, by=.01)

data <- read.table("month.csv", sep=",")
names(data) = c("zone","year","month","count")
dataWeekday <- read.table("dayofweek.csv", sep=",")
names(dataWeekday) = c("zone","year","month", "weekday","count")
dataWeekday <- arrange(dataWeekday, year, month, weekday)
print(dataWeekday)


getParameter <- function(x,y) {
	if(length(x) == length(y)) {
		fit = lm(y ~ x)
		suppressWarnings(m <- summary(fit)$coefficients[2,1])
		suppressWarnings(b <- summary(fit)$coefficients[1,1])
	} else {
		m <- NULL
	}
	return(data.frame(m=m,b=b))
}
#plot(x,y,xlim=c(0,20))

#fit <- lm(y ~ x)
#abline(fit)
#p <- getParameter(x,y)

#points(x=5,y=(5*p["m"][1,1]+p["b"][1,1]))
data <- arrange(data, year, month)

data13 <- data$count[data["year"] < 2013]

dataFeb13 <- data$count[data["year"] < 2013 && data["month"] != 2]

#x <- data$month
x <- 1:48
y <- data$count
fit <- lm(y ~ x)

xFeb13 <- seq(1, length(dataFeb13))
yFeb13 <- dataFeb13 + c(500)
fitFeb13 <- lm(yFeb13 ~ xFeb13)


x13 <- seq(1, length(data13))
y13 <- data13
fit13 <- lm(y13 ~ x13)

p <- getParameter(x,y)
plot(x,y,xlim=c(1,49))
points(x=49,y=(49*p["m"][1,1]+p["b"][1,1]))

abline(fit, col="red")
abline(fit13, col="green")
abline(fitFeb13, col="blue")
