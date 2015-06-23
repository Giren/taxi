library(plyr)

x <- 0:4
y <- c(1, -1, 1, -1, 1)
#y <- seq(0,100, by=.01)

data <- read.table("dayofweek.csv", sep=",")
names(data) = c("zone","year","month", "weekday","count")
data <- arrange(data, year, month, weekday)


getParameter <- function(x,y) {
	if(length(x) == length(y)) {
		fit = lm(y ~ x)
		suppressWarnings(m <- summary(fit)$coefficients[2,1])
		suppressWarnings(b <- summary(fit)$coefficients[1,1])
	} else {
		m <- NULL
		return(m)
	}
	return(data.frame(m=m,b=b))
}

d <- data$count[data["weekday"] == 1]
x <- 1:length(d)
y <- d
fit <- lm(y ~ x)

p <- getParameter(x,y)
#plot(x,y,xlim=c(1,length(d)+1))
#tx <- 337
#points(x=tx,y=(tx*p["m"][1,1]+p["b"][1,1]))

#abline(fit, col="red")
for(w in 1:7) {
	filename <- paste("weekday_", w, ".png")
	png(filename)
	d <- data$count[data["weekday"] == w]
	x <- 1:length(d)
	y <- d
	fit <- lm(y ~ x)
	plot(x,y,xlim=c(1,length(d)+1))
	abline(fit, col="red")
	rm(x)
	rm(y)
	rm(fit)
	rm(d)
	dev.off()
}
