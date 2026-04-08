R_LIBS_USER=~/R/library
R -q -e 'install.packages("roxygen2")'
R -q -e 'roxygen2::roxygenise()'
R CMD INSTALL .

R -q -e "library(CudaMon)"
R -q -e "library(CudaMon); nvml_is_available()"
R -q -e "library(CudaMon); nvml_device_count()"

R -q -e "library(CudaMon); nvml_list_devices()"
R -q -e "library(CudaMon); nvml_get_metrics(0)"


# Example script --------------------
library(CudaMon)

sampler <- nvml_sample_start(
  path_prefix = "my_run",
  period = 1,
  pid = Sys.getpid(),
  include_descendants = TRUE
)

# on.exit(nvml_sample_stop(sampler), add = TRUE)

# Work
Sys.sleep(10)

nvml_sample_stop(sampler)

session <- nvml_sample_read(sampler)

print(session)
print(session$device_metrics)
print(session$compute_processes)

# -----------------------------------


# Install and test ------------------
R -q -e 'install.packages("reticulate")'
R -q -e 'if (!requireNamespace("roxygen2", quietly = TRUE)) install.packages("roxygen2")'
R -q -e 'roxygen2::roxygenise()'
R CMD INSTALL .

R -q -e "library(CudaMon); nvml_is_available()"
R -q -e "library(reticulate); py_config()"
R -q -e "library(reticulate); torch <- import('torch'); torch\$cuda\$is_available()"

R -q -e "source('tests/manual/torch.R')"
