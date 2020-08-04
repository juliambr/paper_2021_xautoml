readProblem = function(data, job, lrn, ...) {

  task = readRDS(file.path(data, "task.rds"))

  learner = PROBLEMS[[lrn]]$learner
  ps = PROBLEMS[[lrn]]$ps
  obj = PROBLEMS[[lrn]]$obj

  list(
    task = task, 
    learner = learner,
    ps = ps 
  )
}


safeSetupRegistry = function(registry_name, overwrite, packages, def) {
  if (file.exists(registry_name)) {
    if (overwrite) {
      unlink(registry_name, recursive = TRUE)
      reg = makeExperimentRegistry(file.dir = registry_name, seed = 123L,
        packages = packages, source = def)
    } else {
      reg = loadRegistry(registry_name, writeable = TRUE)
    }
  } else {
      reg = makeExperimentRegistry(file.dir = registry_name, seed = 123L,
        packages = packages, source = def)
  }
  return(reg)
}


getGroundTruth = function(res, prob) {
  newdata = res[problem == prob & algorithm == "randomsearch", ]$result[[1]]
  newdata = newdata[[2]]$env$path
  return(newdata)
}

getPredictions = function(res, prob, newdata) {
  preds = lapply(models, function(x) {
    preds = predict(x, newdata = newdata)
    preds
  })
  return(preds)
}

getModels = function(res, prob) {
    ressub = res[problem == prob & algorithm == "mlrmbo", ]

    models = lapply(seq_len(nrow(ressub)), function(x) {
    modls = ressub[x, ]$result[[1]]$models
    if (length(modls) > 0)
      modls[[length(modls)]]
    else 
      NULL
  })
    return(models)
}

getTrainData = function(res, prob) {
    ressub = res[problem == prob & algorithm == "mlrmbo", ]

    dfs = lapply(seq_len(nrow(ressub)), function(x) {
      ressub[x, ]$result[[1]][[2]]$env$path
    })

    return(dfs)
}



getPerformance = function(res, prob) {
  ressub = res[problem == prob & algorithm == "mlrmbo", ]

  models = lapply(seq_len(nrow(ressub)), function(x) {
    modls = ressub[x, ]$result[[1]]$models
    if (length(modls) > 0)
      modls[[length(modls)]]
    else 
      NULL
  })

  newdata = getGroundTruth(res, prob)

  preds = getPredictions(res, prob, newdata)
  perfs = lapply(preds, performance)

  data.frame(job.id = ressub$job.id, mse = unlist(perfs))
}

plotPDPoverReplications = function(modellist, train_data_list, feature) {
    effectlist = lapply(seq_len(length(modellist)), function(i) {
      pred = Predictor$new(model = modellist[[i]], data = train_data_list[[i]])
      effects = FeatureEffect$new(predictor = pred, feature = feature, method = "pdp") 
      effects$plot() 
    })
    
    # Quick workaround for buidling the overlay
    pg = ggplot_build(effectlist[[1]])
    p1 = effectlist[[1]]    

    p = ggplot() + theme_bw()
    xlabel = effectlist[[1]]$labels$x
    ylabel = effectlist[[1]]$labels$y

    for (i in 1:length(effectlist)) {
      pg = ggplot_build(effectlist[[i]])
      p = p + geom_line(data = pg$data[[1]], aes(x = x, y = y), alpha = 0.2) 
      # p = p + ylim(pg$layout$panel_scales_y[[1]]$limits)
      p = p + xlab(xlabel) + ylab(ylabel) 
    }
    return(list(effectlist, p))
}