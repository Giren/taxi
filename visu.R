#!/usr/bin/Rscript
library("RgoogleMaps")
library("png")

rows <- 15
cols <- 15
lat = c(40.495, 40.92)
lon = c(-74.255, -73.7)
center = c(mean(lat),mean(lon));
zoom <- min(MaxZoom(range(lat), range(lon)));
NY <- GetMap(center=center, zoom=zoom, destfile="NY.png");
#NY <- GetMap(center="New York City", zoom=10);
makeTransparent <- function(image, factor) {
	t <- matrix(rgb(image[,,1],image[,,2],image[,,3],image[,,4] * factor), nrow=dim(image)[1])
	return (t)
}

plot(c(0,rows), c(0,cols), type = "n", xaxt = "n", yaxt = "n", xlab = "", ylab = "")

ny <- readPNG("NY.png")
img <- makeTransparent(image=ny, factor=1.0)
rasterImage(img, 0, 0, rows, cols)

img <- makeTransparent(image=ny, factor=0.8)
rasterImage(img, 0, 0, 10, 10)
#PlotOnStaticMap(NY)
