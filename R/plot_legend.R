
.get.leg.coords <- function(x) {

	if (is.null(x$leg$ext)) {
		ext <- unlist(x$ext)
		xmin <- x$ext[1]
		xmax <- x$ext[2]
		ymin <- x$ext[3]
		ymax <- x$ext[4]
	} else {
		p <- as.vector(x$leg$ext)
		xmin <- p[1]
		xmax <- p[2]
		ymin <- p[3]
		ymax <- p[4]
		#ymin <- max(ymin, ext["ymin"])
		#ymax <- min(ymax, ext["ymax"])
	}

	if (is.null(x$leg$shrink)) {
		leg.shrink <- c(0,0)
	} else { 
		leg.shrink <- rep_len(x$leg$shrink,2)
	}
	if (!is.null(x$leg$main)) {
		n <- length(x$leg$main)		
		leg.shrink[2] <- max(x$leg$shrink[2], (.05*n)) 
	}

	yd <- ymax - ymin
	ymin <- ymin + yd * leg.shrink[1]
	ymax <- ymax - yd * leg.shrink[2]
    dx <- xmax - xmin
	dy <- ymax - ymin

	x$leg$ext <- data.frame(xmin=xmin, xmax=xmax, ymin=ymin, ymax=ymax, dx=dx, dy=dy)
	x
}


.line.usr <- function(line, side) {
## https://stackoverflow.com/questions/30765866/get-margin-line-locations-in-log-space/30835971#30835971

	lh <- graphics::par("cin")[2] * graphics::par("cex") * graphics::par("lheight")
	x_off <- diff(graphics::grconvertX(c(0, lh), "inches", "npc"))
	y_off <- diff(graphics::grconvertY(c(0, lh), "inches", "npc"))
	if (side == 1) {
		graphics::grconvertY(-line * y_off, "npc", "user")
	} else if (side ==2) {
		graphics::grconvertX(-line * x_off, "npc", "user")
	} else if (side ==3) {
		graphics::grconvertY(1 + line * y_off, "npc", "user")
	} else {
		graphics::grconvertX(1 + line * x_off, "npc", "user")
	}
}

.get.leg.extent <- function(x) {
	usr <- graphics::par("usr")
	dxy <- graphics::par("cxy") * graphics::par("cex")	
	loc <- x$leg$loc
	p <- NULL
	if (is.character(loc)) {
		if (loc == "right") {
			p <- c(usr[2]+dxy[1], usr[2]+2*dxy[1], usr[3], usr[4])
		} else if (loc == "left") {
			s <- .line.usr(trunc(graphics::par("mar")[2]), 2)
			p <- c(s+4*dxy[1], s+5*dxy[1], usr[3], usr[4])
		} else if (loc == "bottom") {
			s <- .line.usr(trunc(graphics::par("mar")[1]), 1)
			p <- c(usr[1], usr[2], s+2*dxy[2], s+3*dxy[2])
		} else if (loc == "top") {
			p <- c(usr[1], usr[2], usr[4]+dxy[2], usr[4]+2*dxy[2])
		} else {
			stop(loc)
		}
	}
	x$leg$ext <- p
	x$leg$user <- FALSE
	.get.leg.coords(x)
}





.leg.main <- function(x) {
	leg <- x$leg
    if (!is.null(leg$title)) {
		e <- leg$ext
		n <- length(leg$title)
		ymax <- e$ymax + 0.05 * e$dy
			
		for (i in 1:n) {
			if (x$leg$loc == "right") {
				text(x=e$xmax, y=ymax+(n-i)*0.05* e$dy,
					labels = leg$title[i], cex = leg$title.cex, xpd=TRUE)
			} else if (x$leg$loc == "left") {
				text(x=e$xmin, y=ymax+(n-i)*0.05* e$dy,
					labels = leg$title[i], cex = leg$title.cex, xpd=TRUE)
			} else {
				ymax <- e$ymax + 2*e$dy
				text(x=(e$xmin+e$xmax)/2, y=ymax+(n-i)*0.05* e$dy,
					labels = leg$title[i], cex = leg$title.cex, xpd=TRUE)				
			}
		}
	}
	x
}


.plot.cont.legend <- function(x, ...) {


	if (is.null(x$leg$ext)) {
		x <- .get.leg.extent(x)
	} else {
		x <- .get.leg.coords(x)	
	}

	cex <- x$leg$cex
	if (is.null(cex)) cex <- 1
	
	cols <- rev(x$cols)
	nc <- length(cols)

	zlim <- x$range
	zz <- x$leg$at
	if (is.null(zz)) {
		if (is.null(x$levels)){
			x$levels <- 5
		}
		zz <- pretty(zlim, n =(x$levels+1))	
		zz <- zz[zz >= zlim[1] & zz <= zlim[2]]
	}
	zztxt <- x$leg$labels
	if (is.null(zztxt)) {
		zztxt <- formatC(zz, digits=x$leg$digits, format = "f")
	}
	e <- x$leg$ext
	if (x$leg$loc %in% c("left", "right")) {
		Y <- seq(e$ymin, e$ymax, length.out=nc+1)
		graphics::rect(e$xmin, Y[-(nc + 1)], e$xmax, Y[-1], col=rev(cols), border=NA, xpd=NA)
		ypos <- e$ymin + (zz - zlim[1])/(zlim[2] - zlim[1]) * e$dy
		if (x$leg$loc == "right") {
			graphics::segments(e$xmin, ypos, e$xmax+e$dx*0.25, ypos, xpd=NA)
			text(e$xmax, ypos, zztxt, pos=4, xpd=NA, cex=cex, ...)
		} else {
			graphics::segments(e$xmin-e$dx*0.25, ypos, e$xmax, ypos, xpd=NA)
			text(e$xmin, ypos, zztxt, pos=2, xpd=NA, cex=cex, ...)
		}
	} else {
		X <- seq(e$xmin, e$xmax, length.out=nc+1)
		graphics::rect(X[-(nc + 1)], e$ymin, X[-1], e$ymax, col=rev(cols), border=NA, xpd=NA)
		xpos <- e$xmin + (zz - zlim[1])/(zlim[2] - zlim[1]) * e$dx
		if (x$leg$loc == "bottom") {
			graphics::segments(xpos, e$ymin-e$dy*0.25, xpos, e$ymax, xpd=NA)
			text(xpos, e$ymin, zztxt, pos=1, xpd=NA, cex=cex)
		} else {
			graphics::segments(xpos, e$ymin, xpos, e$ymax+e$dy*0.25, xpd=NA)
			text(xpos, e$ymax+e$dy*0.25, zztxt, pos=3, xpd=NA, cex=cex)
		}
	}	
	graphics::rect(e$xmin, e$ymin, e$xmax, e$ymax, border ="black", xpd=NA)
	
	x <- .leg.main(x)
	x
}	



.old.plot.class.legend <- function(x, 
	# catching
	y, xpd, title, lty, lwd, pch, angle, density, pt.bg, pt.cex, pt.lwd, seg.len, merge, trace, ...) {
	
	if (!is.null(x$leg$loc)) {
		leg <- graphics::legend(x$leg$loc, legend=x$leg$labels, fill=x$cols, title=x$leg$main$text, ...)	
	} else {
		if (length(x$leg$ext) == 2) {
			leg <- graphics::legend(x$leg$ext[1], x$leg$ext[2], legend=x$leg$labels, fill=x$cols, title=x$leg$main$text, xpd=TRUE, ...)
		} else if (length(x$leg$ext) == 4) {	
			leg <- graphics::legend(x$leg$ext[1], x$leg$ext[4], legend=x$leg$labels, fill=x$cols, xpd=TRUE, title=x$leg$main$text, ...)
		} else {
			stop(x$leg$ext)
		}
	}
	x$leg$legend <- leg
	x
}	



.plot.class.legend <- function(x, y, legend, fill, xpd=TRUE, ext=NULL, 
	# catching
	lty, lwd, pch, angle, density, pt.bg, pt.cex, pt.lwd, seg.len, merge, trace, ...) {

	#if (!is.null(ext)) {
		# do something better
	#}

	if (x == "top") {
		usr <- graphics::par("usr")
		x <- usr[c(2)]
		y <- usr[c(4)]
	}
	leg <- legend(x, y, legend, fill, xpd=xpd, ...)	
	return(leg)
}	

