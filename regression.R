library(plyr)

data <- read.table("4zone_data.csv", sep=",")
names(data) = c("zone","year","month", "weekofyear", "weekday", "hour","count")
data <- arrange(data, year, month, weekofyear, weekday, hour)

germanMonthNames <- c("Jan.", "Febr.", "März", "Apr.", "Mai", "Juni", "Juli", "Aug.", "Sept.", "Okt.", "Nov.", "Dez.")


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

from <- 15
to <- 18
for(zone in 1:4) {
print(paste("zone", zone))
for(month in 1:12) {
cat(paste("\tmonth", month, "\n"))
for(weekday in 1:7) {
	maxY <- 0
	filename <- sprintf("zone-%02d-month-%02d-weekday-%d.png", zone, month, weekday)
	png(filename,width=700,height=550)

	d   <- data[data["zone"] == zone & (data["hour"] >= from & data["hour"] <= to) & data["weekday"] == weekday & (data["month"] >= month & data["month"] <= month) & data["year"] < 2013,]
	d13 <- data[data["zone"] == zone & (data["hour"] >= from & data["hour"] <= to) & data["weekday"] == weekday & (data["month"] >= month & data["month"] <= month),]

	maxY <- max(maxY,data[data["zone"] == zone & (data["hour"] >= from & data["hour"] <= to) & (data["month"] >= month & data["month"] <= month),]$count)

	d <- ddply(d,.(year,weekofyear),colwise(mean))
	d13 <- ddply(d13,.(year,weekofyear),colwise(mean))

	maxX <- nrow(d13)
	labels <- sprintf("%s %d KW %02d", germanMonthNames[d13$month], d13$year, d13$weekofyear)

	d <- d$count
	d13 <- d13$count
	
	x <- 1:length(d)
	y <- d
	fit <- lm(y ~ x)

	alpha <- 0.05
	intervall <- qt(1-alpha/2,length(d))*sd(d)/sqrt(length(d))

	par(oma = c(4, 1, 1, 1))
	plot(x,y,ylab="Anzahl", xlab="", xaxt="n", ylim=c(1,maxY),xlim=c(1,maxX), panel.first=
		c(abline(lm((y - intervall) ~ x), col="blue", lty=3, lwd=2),
		abline(lm((y + intervall) ~ x), col="blue", lty=3, lwd=2),
		abline(fit, col="red")),
		pch=21,
		col="black",
		bg="white",
		cex=1.3
	)
	axis(1, at=1:maxX, labels=labels, las=2)

	legend("bottomright", c("2010-2012", "2013"), xpd = TRUE, horiz = TRUE, inset = c(0, 0), bty = "y", pch=c(21, 21), col=c("black"), pt.bg=c("white", "green"), cex=1.3)

	x13 <- seq(length(d) + 1, length(d13))
	points(x=x13,y=d13[x13], col="black", bg="green", cex=1.3, pch=21)

	dev.off()
}
}
}
