# Setup script for initially setting up the benchmarks 

library(batchtools)

source("benchmarks/mlp/2_mbo_runs/config.R")
source("benchmarks/helper_experiments.R")
source("benchmarks/helper_evaluation.R")

lapply(packages, require, character.only = TRUE)


# --- 1. SETUP REGISTRY ---

reg = safeSetupRegistry(registry_name, OVERWRITE, packages, "benchmarks/mlp/2_mbo_runs/config.R")

# --- 2. ADD PROBLEMS, ALGORITHMS, EXPERIMENTS ---

for (i in seq_len(length(tasks))) {
  addProblem(
    name = tasks[i], 
    data = file.path("data", "runs", "mlp_results", tasks[i], "0_objective"),
    reg = reg
  )
}

for (i in 1:length(ALGORITHMS)) {
  addAlgorithm(name = names(ALGORITHMS)[i], reg = reg, fun = ALGORITHMS[[i]]$fun)  
}

addExperiments(
  reg = reg, 
  algo.designs = ades, 
  repls = 30L)


