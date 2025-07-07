#!/bin/bash
#SBATCH --job-name=mc_lasso
#SBATCH --output=logs/mc_lasso_%j.out
#SBATCH --error=logs/mc_lasso_%j.err
#SBATCH --time=04:00:00
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=120G
#SBATCH --mail-type=FAIL

module purge
module load R/4.3.2   # or whatever version Kuma has

# Prevent nested parallelism (OpenMP / MKL)
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

# Use your R package library
export R_LIBS_USER=$HOME/.R/kuma-lib

cd /home/kashizad/R_lasso_logit

Rscript run_montecarlo_kuma.R
