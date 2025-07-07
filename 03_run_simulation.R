# --------------------------------------------------------------------------
# 0. Setup: Unique IDs and Global Controls
# --------------------------------------------------------------------------

unique_ids <- unique(dataset$id)  # replace 'id' 

# ---- MAIN CONTROL SETTINGS -----------------------------------------------
n_iter               <- 5000     # Number of Monte Carlo iterations
n_cores              <- 32       # Number of CPU cores to use
set.seed(42)                     # Reproducibility

# ---- SAMPLING PARAMETERS -------------------------------------------------
subsample_length     <- 10000    # Number of unique IDs per iteration

# ---- LAMBDA SEARCH BOUNDS -----------------------------------------------
lambda_lower         <- 1e-2     # Lower bound for lambda
lambda_upper         <- 1e2      # Upper bound for lambda (corrected typo from 'lambda_higer')

# ---- SURVIVOR FRACTION RULES --------------------------------------------
min_survivor_frac    <- 0.05     # Minimum % of non-zero coefficients
max_survivor_frac    <- 0.50     # Maximum % of non-zero coefficients
target_survivor_frac <- 0.25     # Target % if bounds not satisfied

# ---- LASSO TUNING PARAMETERS --------------------------------------------
nlambda_val          <- 100      # Number of lambdas to evaluate
thresh_val           <- 1e-5     # Convergence threshold for glmnet
maxit_val            <- 5e5      # Max iterations for glmnet solver


# --------------------------------------------------------------------------
# 1. Initialize Parallel Backend
# --------------------------------------------------------------------------

library(doParallel)
library(doRNG)

cl <- makeCluster(n_cores)
registerDoParallel(cl)
registerDoRNG(42)  # consistent RNG in parallel loops


# --------------------------------------------------------------------------
# 2. Monte Carlo Simulation Loop
# --------------------------------------------------------------------------

library(foreach)
library(glmnet)
library(Matrix)

all_survivors <- foreach(i = 1:n_iter, .combine = c,
                         .packages = c("glmnet", "Matrix")) %dopar% {
                           
                           # ---- 1. Subsample borrowers by ID -------------------------------------
                           sampled_ids  <- sample(unique_ids, subsample_length)
                           rows_to_keep <- nsmoid_clean %in% sampled_ids
                           x_sample     <- x_sparse[rows_to_keep, ]
                           y_sample     <- y_clean[rows_to_keep]
                           
                           # ---- 2. Fit LASSO model -----------------------------------------------
                           fit <- glmnet(x_sample, y_sample,
                                         family         = "gaussian",
                                         alpha          = 1,
                                         penalty.factor = penalty_factors_full,
                                         nlambda        = nlambda_val,
                                         thresh         = thresh_val,
                                         maxit          = maxit_val)
                           
                           # ---- 3. Choose lambda with desired sparsity ---------------------------
                           nz <- colSums(fit$beta != 0)  # number of non-zero coefficients
                           p  <- nrow(fit$beta)          # total number of coefficients
                           
                           ok <- which(nz >= min_survivor_frac * p & nz <= max_survivor_frac * p)
                           k  <- if (length(ok)) sample(ok, 1) else which.min(abs(nz - target_survivor_frac * p))
                           
                           lambda_val <- fit$lambda[k]
                           print(paste("Iteration", i, "-> Lambda:", lambda_val))
                           
                           # ---- 4. Extract non-zero variable names -------------------------------
                           coefs         <- as.matrix(coef(fit, s = lambda_val))[-1, , drop = FALSE]
                           survivor_vars <- colnames(x_merged)[coefs != 0]
                           
                           # ---- 5. Map dummies back to original base variables -------------------
                           map_back_to_original <- function(dummy_names, base_vars) {
                             sapply(dummy_names, function(d) {
                               hits <- base_vars[startsWith(d, base_vars)]
                               if (length(hits)) hits[which.max(nchar(hits))] else NA_character_
                             })
                           }
                           
                           survivor_base <- unique(map_back_to_original(survivor_vars, penalized_vars))
                           
                           return(survivor_base)
                         }


# --------------------------------------------------------------------------
# 3. Cleanup and Aggregate Results
# --------------------------------------------------------------------------

stopCluster(cl)  # shut down workers

# ---- Aggregate most common survivor variables ---------------------------
survivor_counts <- sort(table(all_survivors), decreasing = TRUE)
top_20 <- head(survivor_counts, 20)

print(top_20)

# Optionally save:
# write.table(top_20, file = "output/top20_survivors.txt", sep = "\t")
