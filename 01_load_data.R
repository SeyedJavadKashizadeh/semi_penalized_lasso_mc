# --------------------------------------------------------------------------
# Step 1: Set your data path (edit this)
# --------------------------------------------------------------------------
data_path <- "enter/your/path"    # <-- change to your folder
file_name <- "lasso_logit.dta"    # or change to any valid file

# --------------------------------------------------------------------------
# Step 2: Load dataset (assumes .dta file)
# --------------------------------------------------------------------------
library(haven)
library(dplyr)

dataset_original <- read_dta(file.path(data_path, file_name)) %>%
  arrange(id, time)  # optional sorting, adjust to your own variable names

# --------------------------------------------------------------------------
# Step 3: Select variables to keep
# --------------------------------------------------------------------------

# (a) Manually list some known variables you want to include
manual_vars <- c("var1", "var2")   # <--- replace with your key covariates

# (b) Use grep to include all variables that start with 'x'
x_vars <- grep("^x", names(dataset_original), value = TRUE)

# (c) Combine manually listed and pattern-matched variables
keep_vars <- c(manual_vars, x_vars)

# --------------------------------------------------------------------------
# Step 4: Subset the dataset to keep only selected variables
# --------------------------------------------------------------------------
dataset <- dataset_original[, keep_vars]

# --------------------------------------------------------------------------
# Step 5: Define the variables you want to EXCLUDE from penalization
# (these will have penalty factor = 0 in glmnet)
# --------------------------------------------------------------------------
notpenalized_vars <- c("nonpen_var1", "nonpen_var2")  # <--- replace with your own
