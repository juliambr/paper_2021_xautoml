# Setup script for initially setting up the benchmarks 

library(batchtools)

source("benchmarks/synthetic/config.R")
source("benchmarks/helper_experiments.R")

lapply(packages, require, character.only = TRUE)


# --- 1. SETUP REGISTRY ---

reg = safeSetupRegistry(registry_name, OVERWRITE, packages, "benchmarks/synthetic/config.R")


# --- 2. ADD PROBLEMS, ALGORITHMS, EXPERIMENTS ---

for (i in seq_len(length(tasks))) {
  
  for (j in seq_len(length(dimensions))) {

    subpath = file.path("data", "runs", "synthetic", paste0(tasks[i], dimensions[j], "D"), "0_objective")

    if (!dir.exists(subpath))
      dir.create(file.path(subpath), recursive = TRUE)

    if (!file.exists(file.path(subpath, "obj.rds"))) {
      
      obj = makeSingleObjectiveFunction(name = paste0("StyblinskiTang", dimensions[j], "D"), fn = function(x) {
              1 / 2 * sum(x^4 - 16 * x^2 + 5 * x)
          }, 
          par.set = makeParamSet(makeNumericVectorParam(id = "x", len = dimensions[j], lower = - 5, upper = 5)), 
          global.opt.params = rep(-2.9035, dimensions[j])
      )

      saveRDS(obj, file.path(subpath, "obj.rds"))
    }

    addProblem(
      name = paste0(tasks[i], dimensions[j], "D"), 
      data = subpath, 
      reg = reg
    )
  } 
}

for (i in 1:length(ALGORITHMS)) {
  addAlgorithm(name = names(ALGORITHMS)[i], reg = reg, fun = ALGORITHMS[[i]]$fun)  
}

addExperiments(
  reg = reg, 
  algo.designs = ades, 
  repls = 30L)

