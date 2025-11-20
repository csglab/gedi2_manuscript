library(gedi)
file_dirs <- list.files("Data/Allen-brain-10X-V3/", full.names = TRUE)

high_variable_genes <- readRDS("Data/high_variable_genes_vector.rds")
M_expression_matrix <- c()
metadata <- c()

for(i in 1:length(file_dirs)){
  
  file_dir <- file_dirs[i]
  cat("reading file", file_dir, "\n")
  matrix_expression <- gedi::read_h5ad(file_dir, return_metadata = TRUE)
  metadata_temp <- matrix_expression$obs
  invisible(gc())
  cell_barcode <- paste0(matrix_expression$obs$cell_barcode, "-", matrix_expression$obs$library_label)
  dimnames(matrix_expression$X) <- list(matrix_expression$var$gene_identifier, cell_barcode)
  M_expression_matrix <- cbind(M_expression_matrix, matrix_expression$X[high_variable_genes, ,drop=FALSE])
  metadata <- rbind(metadata, metadata_temp)
  print(dim(M_expression_matrix))
  invisible(gc())
  cat("done!\n")
}

saveRDS(M_expression_matrix, "WMB_ATLAS_10X_V3.rds")
# saveRDS(metadata, "WMB_ATLAS_10X_V3_metadata.rds") #optional

