suppressPackageStartupMessages({
  library(Matrix)
  library(data.table)
})

# reading the M matrix
M <- readRDS("data/WMB_ATLAS_10X_V3.rds")
set.seed(42)
M <- M[, sample(1:ncol(M), 10000), drop=FALSE]
Sample_vec <- sub("^.{17}(.*$)", "\\1", colnames(M))

# legacy GEDI
    system.time({
    library(GEDI)
    model_legacy <- new("GEDI")
    model_legacy$setup(Samples = Sample_vec, M = M, K =10)
    model_legacy$initialize.LVs(randomSeed = 42, multimodal = FALSE)
    model_legacy$optimize(iterations = 200, track_internval = 1, multimodal = FALSE)
    })
# Save the model
    saveRDS(model_legacy, file = file.path("legacy_gedi_model.rds"))

