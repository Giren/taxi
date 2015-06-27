library(plyr)
#taxi.data_prog_final.zone_id,taxi.data_prog_final.year,taxi.data_prog_final.month,taxi.data_prog_final.weekofyear,taxi.data_prog_final.dayofweek,taxi.data_prog_final.hourofday,taxi.data_prog_final.count

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

#points(x=tx,y=(tx*p["m"][1,1]+p["b"][1,1]))

m <- 8

for(w in 1:7) {
	filename <- paste("weekday_", w, ".png")
	png(filename,width=700,height=350)

	d   <- data$count[data["zone"] == 3 & (data["hour"] >= 15 & data["hour"] <= 15) & data["weekday"] == w & (data["month"] >= m & data["month"] <= m) & data["year"] < 2013]
	d13 <- data$count[data["zone"] == 3 & (data["hour"] >= 15 & data["hour"] <= 15) & data["weekday"] == w & (data["month"] >= m & data["month"] <= m)]

	print(d)
	
	x <- 1:length(d)
	y <- d
	fit <- lm(y ~ log(x))
	print(summary(fit))

#	p <- getParameter(x,y)
	plot(x,y,xlim=c(1,length(d13)))
#
	abline(fit, col="red")
	tx <- length(d) + (length(d13) - length(d)) %/% 2
#	#points(x=tx,y=(tx*p["m"][1,1]+p["b"][1,1]))
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
#print(data)
#
#	rm(x)
#	rm(y)
#	rm(fit)
#	rm(d)
#	dev.off()
#}
