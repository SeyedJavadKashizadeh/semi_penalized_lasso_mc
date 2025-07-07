#!/usr/bin/env Rscript

# Run modular Monte Carlo LASSO on Kuma

# Set working directory
setwd("directory similar to other modules")  



# Load necessary packages once
suppressPackageStartupMessages({
  library(haven)
  library(dplyr)
  library(Matrix)
  library(glmnet)
  library(doParallel)
  library(glmnet)
  library(foreach)
  library(doRNG) 
})

# Source modular parts
source("01_load_data.R")
source("02_build_matrix.R")
source("03_run_simulation.R")

