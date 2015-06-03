#!/usr/bin/Rscript
library("RgoogleMaps")
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
	alpha = 0.5
	r = (        percentage) / 100
	g = (100 -   percentage) / 100
	m = matrix(rgb(r,g,0,alpha), nrow=1)
	return (m)
}


# Holen der Karte von NY mittels RgoogleMap Library falls PNG nicht existiert
if(!file.exists("NY.png")) {
	lat = c(40.495, 40.92)
	lon = c(-74.255, -73.7)
	center = c(mean(lat),mean(lon));
	zoom <- min(MaxZoom(range(lat), range(lon)));
	NY <- GetMap(center=center, zoom=zoom, destfile="NY.png");
}

# Karte von NY randlos zeichnen 
par(mar=rep(0, 4))
plot(c(0,rows), c(0,cols), xaxs = "i", yaxs = "i", type = "n", xaxt = "n", yaxt = "n", xlab = "", ylab = "")

# Prozentzahlen zum Testen generieren
rnds <- runif(rows * cols, 0.0, 100.0)
for(i in seq(1,rows*10)) {
	rnds[i] <- 0.0
}
for(i in seq(rows*10,rows*(cols-1))) {
	rnds[i] <- 100.0
}

ny <- readPNG("NY.png")
img <- makeTransparent(image=ny, factor=1.0)
rasterImage(img, 0, 0, rows, cols)

old <- 0.0
count <- 1
similar <- 0
for (r in 1:rows) {
	for (c in 1:cols) {
		if((rnds[count] == old) & (c < cols)) {
			similar <- similar+1
		} else {
			img <- colorMatrix(old)
			rasterImage(img, r-1, c-similar-1, r, c)

			similar <- 0
		}
		old <- rnds[count]
		count <- count + 1
	}
}
