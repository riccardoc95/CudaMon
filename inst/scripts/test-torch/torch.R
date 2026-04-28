RUN_GPU_JOB <- TRUE
PERIOD <- 1
TRAINING_EPOCHS <- 5000L
INFERENCE_EPOCHS <- 10000L

init_torch_model <- function() {
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("The reticulate package is required.", call. = FALSE)
  }

  torch <- reticulate::import("torch")
  if (!isTRUE(torch$cuda$is_available())) {
    stop("Torch CUDA is not available.", call. = FALSE)
  }

  nn <- torch$nn
  optim <- torch$optim

  batch_size <- 128L
  input_dim <- 1024L
  hidden_dim <- 1024L
  output_dim <- 128L

  model <- nn$Sequential(
    nn$Linear(input_dim, hidden_dim),
    nn$ReLU(),
    nn$Linear(hidden_dim, hidden_dim),
    nn$ReLU(),
    nn$Linear(hidden_dim, output_dim)
  )$to("cuda")

  optimizer <- optim$Adam(model$parameters(), lr = 1e-3)
  loss_fn <- nn$MSELoss()

  list(
    torch = torch,
    model = model,
    optimizer = optimizer,
    loss_fn = loss_fn,
    batch_size = batch_size,
    input_dim = input_dim,
    output_dim = output_dim
  )
}

run_torch_training_job <- function(epochs) {
  cfg <- init_torch_model()
  torch <- cfg$torch
  model <- cfg$model
  optimizer <- cfg$optimizer
  loss_fn <- cfg$loss_fn

  for (step in seq_len(as.integer(epochs))) {
    x <- torch$randn(tuple(cfg$batch_size, cfg$input_dim), device = "cuda")
    y <- torch$randn(tuple(cfg$batch_size, cfg$output_dim), device = "cuda")

    optimizer$zero_grad()
    pred <- model(x)
    loss <- loss_fn(pred, y)
    loss$backward()
    optimizer$step()

    if (step %% 10L == 0L) {
      torch$cuda$synchronize()
    }
  }

  torch$cuda$synchronize()
  invisible(NULL)
}

run_torch_inference_job <- function(epochs) {
  cfg <- init_torch_model()
  torch <- cfg$torch
  model <- cfg$model
  no_grad <- torch$no_grad()

  no_grad$`__enter__`()
  on.exit(no_grad$`__exit__`(NULL, NULL, NULL), add = TRUE)

  for (step in seq_len(as.integer(epochs))) {
    x <- torch$randn(tuple(cfg$batch_size, cfg$input_dim), device = "cuda")
    pred <- model(x)
    invisible(pred)

    if (step %% 10L == 0L) {
      torch$cuda$synchronize()
    }
  }

  torch$cuda$synchronize()
  invisible(NULL)
}

library(CudaMon)

sampler <- cm_start(
  path_prefix = "torch_test",
  period = PERIOD,
  pid = Sys.getpid(),
  include_descendants = TRUE
)
#on.exit(cm_stop(sampler), add = TRUE)

if (isTRUE(RUN_GPU_JOB)) {
  cm_timestamp(sampler, "training")
  run_torch_training_job(TRAINING_EPOCHS)
  cm_timestamp(sampler, "inference")
  run_torch_inference_job(INFERENCE_EPOCHS)
} else {
  Sys.sleep(5)
}

cm_stop(sampler)
session <- cm_parser(sampler)

print(session)

cat("paths\n")
print(session$paths)

show_file <- function(path, label) {
  cat(label, "exists:", file.exists(path), "\n")
  if (!file.exists(path)) {
    return(invisible(NULL))
  }

  info <- file.info(path)
  cat(label, "size:", info$size, "\n")
  cat(label, "contents\n")
  cat(paste(readLines(path, warn = FALSE), collapse = "\n"), "\n")
}

show_file(session$paths$device_metrics, "device_metrics file")
show_file(session$paths$compute_processes, "compute_processes file")
show_file(session$paths$events, "events file")
show_file(session$paths$log, "sampler log file")


cat("RUN_GPU_JOB:", RUN_GPU_JOB, "\n")
cat("device_metrics\n")
print(session$device_metrics)
cat("compute_processes\n")
print(session$compute_processes)


library(ggplot2)
p <- cm_plot_usage(session, tz = "Europe/Rome")
ggsave("torch_test_usage.png", p, width = 10, height = 6, dpi = 150)
