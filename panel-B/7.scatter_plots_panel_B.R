#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(data.table)
  library(Matrix)
  library(reshape2)
  library(png)
})


model_new <- readRDS("new_gedi_model.rds")
model_legacy <- readRDS("legacy_gedi_model.rds")

# ZDB calculations
ZD_new <- model_new$params$Z %*% Diagonal(x = model_new$params$D)
ZDB_new <- do.call(cbind, lapply(model_new$params$Bi, function(Bi) ZD_new %*% Bi))
ZDB_new_plus_o <- ZDB_new + model_new$params$o

getZDB.gedi <- function(object) {
  ZDB <- do.call(cbind, object$aux$ZDBi)
  rownames(ZDB) <- object$aux$geneIDs
  colnames(ZDB) <- object$aux$cellIDs
  return(ZDB)
}

ZDB_legacy <- getZDB.gedi(model_legacy)
ZDB_legacy_plus_o <- ZDB_legacy + model_legacy$params$o

# QiDBi calculations
Qi_new <- lapply(model_new$params$Q, function(Qi) Qi %*% Diagonal(x = model_new$params$D))
QiDBi_new <- do.call(cbind, lapply(seq_along(Qi_new), function(i) Qi_new[[i]] %*% model_new$params$Bi[[i]]))
QiDBi_legacy <- do.call(cbind, model_legacy$aux$QiDBi)

create_hybrid_scatter <- function(vec1, vec2, output_path, xlab, ylab, 
                                  xlim = NULL, ylim = NULL, 
                                  width = 6, height = 6, 
                                  nbin = 1024, dpi = 800) {
  
  valid_idx <- !is.na(vec1) & !is.na(vec2) & is.finite(vec1) & is.finite(vec2)
  vec1 <- vec1[valid_idx]
  vec2 <- vec2[valid_idx]
  
  if (is.null(xlim)) xlim <- quantile(vec1, probs = c(0.001, 0.999))
  if (is.null(ylim)) ylim <- quantile(vec2, probs = c(0.001, 0.999))
  
  idx <- vec1 >= xlim[1] & vec1 <= xlim[2] & vec2 >= ylim[1] & vec2 <= ylim[2]
  vec1_filtered <- vec1[idx]
  vec2_filtered <- vec2[idx]
  
  cor_val <- cor(vec1_filtered, vec2_filtered)
  n_filtered <- length(vec1_filtered)
  
  blue_pal <- colorRampPalette(c("white", "lightblue", "blue", "darkblue", "#000033"))
  
  bw_x <- diff(xlim) / (nbin * 0.5)
  bw_y <- diff(ylim) / (nbin * 0.5)
  
  temp_png <- tempfile(fileext = ".png")
  png(temp_png, width = width * dpi, height = height * dpi, res = dpi, 
      type = "cairo", antialias = "none")
  par(mar = c(0, 0, 0, 0))
  smoothScatter(vec1_filtered, vec2_filtered, nrpoints = 0, colramp = blue_pal, 
                axes = FALSE, xlim = xlim, ylim = ylim, nbin = nbin,
                bandwidth = c(bw_x, bw_y), xlab = "", ylab = "")
  dev.off()
  
  raster_img <- readPNG(temp_png)
  
  pdf(output_path, width = width, height = height)
  par(family = "serif", mar = c(4.5, 4.5, 2, 1.5), 
      mgp = c(2.8, 0.7, 0), las = 1, cex.lab = 1.2, cex.axis = 1.1)
  
  plot.new()
  plot.window(xlim = xlim, ylim = ylim)
  rasterImage(raster_img, xlim[1], ylim[1], xlim[2], ylim[2], interpolate = FALSE)
  
  box(lwd = 1.5)
  axis(1, lwd = 1.5, lwd.ticks = 1.2)
  axis(2, lwd = 1.5, lwd.ticks = 1.2)
  title(xlab = xlab, ylab = ylab)
  
  legend_x <- xlim[1] + diff(xlim) * 0.05
  legend_y <- ylim[2] - diff(ylim) * 0.05
  
  text(legend_x, legend_y, 
       labels = bquote(italic(r) == .(sprintf("%.4f", cor_val))),
       pos = 4, cex = 1.2, font = 2)
  
  text(legend_x, legend_y - diff(ylim) * 0.08,
       labels = bquote(italic(n) == .(format(n_filtered, big.mark = ","))),
       pos = 4, cex = 1.0)
  
  dev.off()
  unlink(temp_png)
  
  invisible(list(correlation = cor_val, n_filtered = n_filtered))
}

create_hybrid_scatter(as.vector(ZDB_legacy), as.vector(ZDB_new), 
                     file.path(save.dir, "ZDB_comparison.pdf"), 
                     "Legacy Model", "New Model",
                     xlim = c(-1, 1), ylim = c(-1, 1))

create_hybrid_scatter(as.vector(ZDB_legacy_plus_o), as.vector(ZDB_new_plus_o),
                     file.path(save.dir, "ZDB_plus_o_comparison.pdf"), 
                     "Legacy Model", "New Model")

create_hybrid_scatter(as.vector(QiDBi_legacy), as.vector(QiDBi_new),
                     file.path(save.dir, "QiDBi_comparison.pdf"), 
                     "Legacy Model", "New Model")
