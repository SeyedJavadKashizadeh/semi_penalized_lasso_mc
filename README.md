# Semi-Penalized LASSO with Monte Carlo Sub-Sampling for Variable Selection  

*A modular R pipeline for repeated LASSO estimation with selective penalization.*

---

## Overview
`semi_penalized_lasso_mc` is an **R-based, fully modular toolkit** that helps you discover stable, high-value predictors in high-dimensional data sets when

1. some covariates **must never be shrunk** (policy dummies, demographics, etc.),
2. each unit/ID appears **once** (no time series or panel structure). For panel dataset, we should collapse datset by ID.
3. Variable selection is sensitive to sample size and also any sample modification.

---


## 1  Monte Carlo Sub-Sampling

### Procedure
1. Randomly draw `m` unique IDs from `N` (with replacement).  
2. Fit semi-penalized LASSO on that subsample.  
3. Record which penalized variables survive (non-zero).  
4. Repeat for `B` iterations (`B = 500 – 5000`).


We choose λ along the `glmnet` path that yields a share of non-zero coefficients between *min* and *max* (default 5 %–50 %); if none qualify we pick the closest to a *target* sparsity (default 25 %).

---

## 2  One Row per ID Requirement
The current pipeline assumes **one observation per `id`**.  
For panel data, first aggregate to a single row (e.g., last period or summary stats).

---

## 3 Parallelization 

This pipeline is fully parallelized.

### Parallel Monte Carlo LASSO

- Each Monte Carlo iteration is run independently using a `foreach` loop.
- Parallel execution is handled by `doParallel`.
- A fixed random seed is passed through `doRNG`, ensuring deterministic results.



## 6  Key Features

| Feature | Description |
|---------|-------------|
| **Modular design** | `01_load_data.R`, `02_build_matrix.R`, `03_run_simulation.R`, orchestrated by `main.R`. |
| **Penalty factors** | Automatic 0/1 vector for fixed vs. penalized blocks. |
| **Sparse matrices** | Utilises `Matrix` + `glmnet` for memory-efficient high-dim X. |
| **Reproducible parallelism** | `foreach` + `doParallel` + `doRNG` ensures identical runs. |
| **Flexible λ-selection** | User sets sparsity band, path length, convergence tolerances. |
| **Top-survivor report** | Outputs frequency table of most-selected variables. |

---
