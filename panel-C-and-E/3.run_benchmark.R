suppressPackageStartupMessages({
  library(Matrix)
  library(data.table)
  library(rsvd)
  library(R6)
})



args <- commandArgs(trailingOnly = TRUE)

method <- args[1]
thread <- as.numeric(args[2])  # Convert to numeric for thread count
number_of_cells <- as.numeric(args[3])  # Convert to numeric for number of cells

cat("Method:", method, "\n")
cat("Threads:", thread, "\n")
cat("Number of cells:", number_of_cells, "\n") 

# reading the file
M <- readRDS("Data/WMB_ATLAS_10X_V3.rds")

set.seed(42)
select_vector <- sample(1:ncol(M), number_of_cells)
M <- M[, select_vector, drop=FALSE]

Sample_vec <- sub("^.*_(.*$)", "\\1", colnames(M))
table(Sample_vec) |> length()

if(method == "1"){
  library(GEDI)
  set.seed(42)
  model <- new("GEDI")
  model$setup(Samples = Sample_vec, M = M, K =10)
  model$initialize.LVs(randomSeed = 42, multimodal = FALSE)
  model$optimize(iterations = 100, track_internval = 50, multimodal = FALSE)
} else {
  library(gedi)
  set.seed(42)
  model <- CreateGEDIObject(Samples = Sample_vec, M = M, K = 10, verbose = 1, num_threads = thread)
  model <- model$train(iterations = 100, track_interval = 50)
  }
