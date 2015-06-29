#!/usr/bin/Rscript
library("RgoogleMaps")
library("rjson")
library("png")

colorize <- function(percentage) {
	alpha = 1.0
	
	#stark frequentiert ist rot
	percentage = min(c(100.0, percentage))
	h = (240.0 / 360) - ((240.0 + 110) / 360) * (percentage / 100.0)
	h = max(c(h, 0))

	m = hsv(h,1,1,alpha)
	return (m)
}


# Holen der Karte von NY mittels RgoogleMap Library falls PNG nicht existiert
lat = c(40.495, 40.92)
lon = c(-74.255, -73.7)
center = c(mean(lat),mean(lon));
zoom <- min(MaxZoom(range(lat), range(lon)));

fileName="data_agg_1.txt"
fd=file(fileName,open="r")
print("importing json")
data <- lapply(readLines(fd), fromJSON)
print("json loaded into memory")


for(y in 2010:2013) {
for(m in 1:12) {
	title <- sprintf("NY-HM-%d-%02d.png", y, m)
	print(paste("generating", title))

	png(title, width=400, height=400)
	NY <- GetMap(center=center, zoom=11, destfile="NY.png");
	lonv   <- vector(mode="numeric", length=0)
	latv   <- vector(mode="numeric", length=0)
	countv <- vector(mode="numeric", length=0)
	colorv <- vector(mode="numeric", length=0)
	#
	for (line in 1:length(data)) {
		if(data[[line]]$attributes$count < 20)
			next
		if(data[[line]]$attributes$year != y)
			next
		if(data[[line]]$attributes$month != m)
			next
		count <- data[[line]]$attributes$count
		longtitude <- mean(c(data[[line]]$geometry$rings[[1]][[1]][1],data[[line]]$geometry$rings[[1]][[3]][1]))
		lattitude <-  mean(c(data[[line]]$geometry$rings[[1]][[1]][2],data[[line]]$geometry$rings[[1]][[3]][2]))
		lonv <- c(lonv, longtitude)
		latv <- c(latv, lattitude)
		countv <- c(countv, count)
	}
	logc <- log(countv)
	max_logc <- max(logc) - 2
	min_logc <- min(logc)

	for(c in 1:length(countv)) {
		colorv <- c(colorv, colorize(100 * (logc[c] - min_logc) / max_logc))
	}
	PlotOnStaticMap(NY,cex = 0.28, pch = 15, col=colorv, lat=latv, lon=lonv, FUN = points, add=FALSE)
	dev.off()
}
}
close(fd)
