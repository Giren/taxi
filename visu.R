#!/usr/bin/Rscript
library("RgoogleMaps")
library("rjson")
library("png")

colorize <- function(percentage) {
	# Prozentwert auf 100 limitieren
	percentage = min(c(100.0, percentage))

	# Farbgrade bestimmen
	h = (240.0 / 360) - ((240.0 + 110) / 360) * (percentage / 100.0)
	h = max(c(h, 0))

	m = hsv(h,1,1,1)
	return (m)
}


# Holen der Karte von NY mittels RgoogleMap Library falls PNG nicht existiert
lat = c(40.495, 40.92)
lon = c(-74.255, -73.7)
center = c(mean(lat),mean(lon));
zoom <- min(MaxZoom(range(lat), range(lon)));
threshold < 20

# Daten in den Arbeitsspeicher laden
fileName="data_agg_1.txt"
fd=file(fileName,open="r")
print("importing json")
data <- lapply(readLines(fd), fromJSON)
print("json loaded into memory")


for(year in 2010:2013) {
for(month in 1:12) {
	# dynamisch Titel generieren
	title <- sprintf("NY-HM-%d-%02d.png", year, month)
	print(paste("generating", title))

	# Device erstellen (png) und die Karte von New York holen
	png(title, width=400, height=400)
	NY <- GetMap(center=center, zoom=11, destfile="NY.png");

	# Leere Vectoren erstellen: Longtitude, Lattitude, Counts, Colors
	lons   <- vector(mode="numeric", length=0)
	lats   <- vector(mode="numeric", length=0)
	counts <- vector(mode="numeric", length=0)
	colors <- vector(mode="numeric", length=0)

	# Daten des Jahres und Monats sammeln
	for (line in 1:length(data)) {
		if(data[[line]]$attributes$count < threshold)
			next
		if(data[[line]]$attributes$year != year)
			next
		if(data[[line]]$attributes$month != month)
			next
		count <- data[[line]]$attributes$count
		longtitude <- mean(c(data[[line]]$geometry$rings[[1]][[1]][1],data[[line]]$geometry$rings[[1]][[3]][1]))
		lattitude <-  mean(c(data[[line]]$geometry$rings[[1]][[1]][2],data[[line]]$geometry$rings[[1]][[3]][2]))
		lons <- c(lons, longtitude)
		lats <- c(lats, lattitude)
		counts <- c(counts, count)
	}
	# Counts logarithmisch machen
	logc <- log(counts)
	max_logc <- max(logc) - 2
	min_logc <- min(logc)

	# Farbvector erstellen der den Counts entspricht
	for(c in 1:length(counts)) {
		colors <- c(colors, colorize(100 * (logc[c] - min_logc) / max_logc))
	}

	# Plotten	
	PlotOnStaticMap(NY,cex = 0.28, pch = 15, col=colorv, lat=latv, lon=lonv, FUN = points, add=FALSE)
	dev.off()
}
}
close(fd)
