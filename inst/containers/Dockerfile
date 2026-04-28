FROM nvidia/cuda:13.1.1-devel-ubuntu24.04

ENV LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    PATH=/usr/local/bin:${PATH} \
    RETICULATE_PYTHON=/usr/bin/python3 \
    DEBIAN_FRONTEND=noninteractive

WORKDIR /opt/CudaMon

COPY . /opt/CudaMon

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        gfortran \
        git \
        make \
        pkg-config \
        libcurl4-openssl-dev \
        libssl-dev \
        libxml2-dev \
        libgit2-dev \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libpcre2-dev \
        python3 \
        python3-dev \
        python3-pip \
        r-base \
        r-base-dev \
        r-cran-roxygen2 \
        r-cran-ggplot2 \
        r-cran-processx \
        r-cran-testthat \
        r-cran-reticulate; \
    rm -rf /var/lib/apt/lists/*; \
    python3 -m pip install --break-system-packages --no-cache-dir numpy torch; \
    R -q -e "roxygen2::roxygenise('/opt/CudaMon')"; \
    R CMD INSTALL --preclean /opt/CudaMon; \
    R -q -e "library(reticulate); py_config()"; \
    R -q -e "library(reticulate); torch <- import('torch'); print(torch\$cuda\$is_available())"
