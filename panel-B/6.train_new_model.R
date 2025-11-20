suppressPackageStartupMessages({
  library(Matrix)
  library(data.table)
})

# reading the M matrix
M <- readRDS("Data/WMB_ATLAS_10X_V3.rds")
set.seed(42)
M <- M[, sample(1:ncol(M), 10000), drop=FALSE]
Sample_vec <- sub("^.{17}(.*$)", "\\1", colnames(M))

# new GEDI
    library(gedi)
    set.seed(42)
    system.time({
    model_new <- CreateGEDIObject(Samples = Sample_vec, M = M, K = 10, num_threads= 32, verbose = 2)
    model_new <- model_new$train(iterations = 200) 
    })

# Save the model
    saveRDS(model_new, file = file.path("new_gedi_model.rds"))


