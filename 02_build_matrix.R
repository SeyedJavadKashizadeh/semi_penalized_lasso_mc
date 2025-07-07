# ----------------------------- 1. Define variable groups -----------------------------

# ‘penalized_vars’  → everything except: (i) variables you do NOT want penalised,
#                      and (ii) the response variable itself
penalized_vars <- setdiff(names(dataset), c(notpenalized_vars, "depvar"))

# Which of those penalised variables are *continuous* and should stay numeric?
penalized_continuous_vars <- c("cont_var1", "cont_var2")   # <--- replace

# The remaining penalised variables are treated as *categorical* (factor) dummies
penalized_categorical_vars <- setdiff(penalized_vars, penalized_continuous_vars)

# Ensure all categorical candidates are encoded as factors
dataset[penalized_categorical_vars] <- lapply(dataset[penalized_categorical_vars], as.factor)


# ----------------------------- 2. Split data blocks ----------------------------------

# Response
y <- as.numeric(dataset$depvar)

# Everything except the response
dataset_x <- dataset[, setdiff(names(dataset), "depvar")]

# Separate blocks we will later re-assemble
dataset_penalized_cat <- dataset[, penalized_categorical_vars, drop = FALSE]
dataset_penalized_num <- dataset[, penalized_continuous_vars, drop = FALSE]
dataset_notpenalized  <- dataset[, notpenalized_vars,          drop = FALSE]


# ----------------------------- 3. Clean categorical block ----------------------------

# Drop factors with <2 levels (degenerate) …
problematic_vars <- sapply(dataset_penalized_cat, function(x) length(levels(x)) < 2)
dataset_penalized_cat <- dataset_penalized_cat[, !problematic_vars, drop = FALSE]

# … and factors containing any NA rows (glmnet cannot handle missing dummies)
dataset_penalized_cat <- dataset_penalized_cat[, colSums(is.na(dataset_penalized_cat)) == 0]


# ----------------------------- 4. Dummy-code categoricals ----------------------------

# model.matrix() creates one-hot dummies without an intercept (-1)
x_penalized_cat <- model.matrix(~ . - 1,
                                data       = dataset_penalized_cat,
                                contrasts.arg = lapply(dataset_penalized_cat, contrasts),
                                na.action  = na.pass)   # keep row order even if NAs elsewhere


# ----------------------------- 5. Merge all design blocks ----------------------------

x_merged <- as.matrix(cbind(
  dataset_notpenalized,      # fixed covariates (penalty = 0)
  dataset_penalized_num,     # continuous penalised covariates
  x_penalized_cat            # dummy matrix for penalised categoricals
))


# ----------------------------- 6. Row filtering & final y ----------------------------

rows_to_keep <- complete.cases(x_merged)     # drop any row with NA in *any* column
x_merged <- x_merged[rows_to_keep, ]
y_clean  <- y[rows_to_keep]

# Example: keep an ID column aligned with the cleaned rows (optional)
id_clean <- dataset$id_var[rows_to_keep]


# ----------------------------- 7. Convert to sparse matrix ---------------------------

# Sparse format is memory-efficient and required by glmnet for large X
x_sparse <- Matrix::Matrix(x_merged, sparse = TRUE)


# ----------------------------- 8. Penalty-factor vector ------------------------------

# Number of columns by block
n_nonpenalized         <- ncol(dataset_notpenalized)
n_penalized_continuous <- ncol(dataset_penalized_num)
n_penalized_categorical<- ncol(x_penalized_cat)

# penalty_factors_full: 0  → coefficients *not* penalised
#                       1  → coefficients penalised by LASSO
penalty_factors_full <- c(
  rep(0, n_nonpenalized),
  rep(1, n_penalized_continuous + n_penalized_categorical)
)

# ----------------------------------------------------------------------
# x_sparse, y_clean, penalty_factors_full are now ready for glmnet()
# ----------------------------------------------------------------------
