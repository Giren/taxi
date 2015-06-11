#!/usr/bin/Rscript
library("RgoogleMaps")
library("rjson")
library("png")

# Definition des Rasters
rows <- 200
cols <- 200

# Manipuliert den alpha-Kanal mit eines PNG's einem Faktor
makeTransparent <- function(image, factor) {
	t <- matrix(rgb(image[,,1],image[,,2],image[,,3],image[,,4] * factor), nrow=dim(image)[1])
	return (t)
}

# Generiert eine farbige 1*1 matrix aus einem Prozentwert
colorMatrix <- function(percentage) {
	if(percentage > 100) {
		percentage = 100
	}
	alpha = 0.5
	r = (        percentage) / 100
	g = (100 -   percentage) / 100
	b = (100 -   percentage) / 100
	m = rgb(r,0.5,b,alpha)
	return (m)
}


# Holen der Karte von NY mittels RgoogleMap Library falls PNG nicht existiert
lat = c(40.495, 40.92)
lon = c(-74.255, -73.7)
center = c(mean(lat),mean(lon));
zoom <- min(MaxZoom(range(lat), range(lon)));
NY <- GetMap(center=center, zoom=11, destfile="NY.png");

fileName="taxi_data.dat"
fd=file(fileName,open="r")

data <- lapply(readLines(fd), fromJSON)

lonv <- vector(mode="numeric", length=0)
latv <- vector(mode="numeric", length=0)
countv <- vector(mode="numeric", length=0)
colorv <- vector(mode="numeric", length=0)

for (line in 1:length(data)) {
        #print(data[[line]]$attributes$count)
	if(data[[line]]$attributes$count <20)
		next
	count <- data[[line]]$attributes$count
        longtitude <- mean(c(data[[line]]$geometry$rings[[1]][[1]][1],data[[line]]$geometry$rings[[1]][[3]][1]))
        lattitude <- mean(c(data[[line]]$geometry$rings[[1]][[1]][2],data[[line]]$geometry$rings[[1]][[3]][2]))
	lonv <- c(lonv, longtitude)
	latv <- c(latv, lattitude)
	countv <- c(countv, count)
}
mean <- mean(countv)
print(mean)
for(c in 1:length(countv)) {
	colorv <- c(colorv, colorMatrix(100 * countv[c] / mean))
}
tmp <- PlotOnStaticMap(NY,cex = 0.28, pch = 15, col=colorv, lat=latv, lon=lonv, FUN = points, add=FALSE)
close(fd)
