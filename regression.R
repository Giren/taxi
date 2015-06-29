library(plyr)

data <- read.table("4zone_data.csv", sep=",")
names(data) = c("zone","year","month", "weekofyear", "weekday", "hour","count")
data <- arrange(data, year, month, weekofyear, weekday, hour)


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

von <- 15
bis <- 18
for(month in 1:12) {
for(zone in 1:4) {
for(w in 1:7) {
	filename <- sprintf("zone-%02d-month-%02d-weekday-%d.png", zone, month, w)
	png(filename,width=700,height=350)

	d   <- data[data["zone"] == zone & (data["hour"] >= von & data["hour"] <= bis) & data["weekday"] == w & (data["month"] >= month & data["month"] <= month) & data["year"] < 2013,]
	d13 <- data[data["zone"] == zone & (data["hour"] >= von & data["hour"] <= bis) & data["weekday"] == w & (data["month"] >= month & data["month"] <= month),]

	d <- ddply(d,.(year,weekofyear),colwise(mean))
	d13 <- ddply(d13,.(year,weekofyear),colwise(mean))
	print(d)
	print(d13)

	d <- d$count
	d13 <- d13$count
	
	x <- 1:length(d)
	y <- d
	fit <- lm(y ~ x)
	print(summary(fit))

#	p <- getParameter(x,y)
	plot(x,y,ylim=c(1,max(d13)),xlim=c(1,length(d13)))

	abline(fit, col="red")
	tx <- length(d) + (length(d13) - length(d)) %/% 2
#	points(x=tx,y=(tx*p["m"][1,1]+p["b"][1,1]))
#	print(d13[tx])
	
	x13 <- seq(length(d) + 1, length(d13))
	points(x=x13,y=d13[x13], col="green", cex=c(2), pch=19)


	print("Quantile: ")
	alpha <- 0.05
	quantile <- qt(1-alpha/2, length(d))
	print(quantile)

	print("Standardabweichung: ")
	std_error <- sd(d)
	print(std_error)

	print("Intervall: ")
	intervall <- qt(1-alpha/2,length(d))*sd(d)/sqrt(length(d))
	print(intervall)

	abline(lm((y - intervall) ~ x), col="blue")
	abline(lm((y + intervall) ~ x), col="blue")

	dev.off()
	print(d)
}
}
}
