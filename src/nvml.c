/*
Copyright (c) 2025 Mohammad Amin Zadenoori
Copyright (c) 2025 Gabriele Sales

This software is licensed under the Artistic License 2.0.
*/

#include <R.h>
#include <Rinternals.h>
#include <nvml.h>

SEXP nvml_init_c(void) {
    nvmlReturn_t result = nvmlInit_v2();
    return ScalarInteger((int)result);
}

SEXP nvml_shutdown_c(void) {
    nvmlReturn_t result = nvmlShutdown();
    return ScalarInteger((int)result);
}

SEXP nvml_device_count_c(void) {
    unsigned int count = 0;
    nvmlReturn_t result = nvmlDeviceGetCount(&count);
    if (result != NVML_SUCCESS) {
        return ScalarInteger(-(int)result);
    }
    return ScalarInteger((int)count);
}

SEXP nvml_get_metrics_c(SEXP device_index_sexp) {
    int device_index = asInteger(device_index_sexp);
    if (device_index < 0) {
        return ScalarInteger(-NVML_ERROR_INVALID_ARGUMENT);
    }

    unsigned int count = 0;
    nvmlReturn_t result = nvmlDeviceGetCount(&count);
    if (result != NVML_SUCCESS) {
        return ScalarInteger(-(int)result);
    }

    if (device_index >= count) {
        return ScalarInteger(-NVML_ERROR_INVALID_ARGUMENT);
    }

    nvmlDevice_t device;
    result = nvmlDeviceGetHandleByIndex(device_index, &device);
    if (result != NVML_SUCCESS) {
        return ScalarInteger(-(int)result);
    }

    nvmlUtilization_t utilization = {NA_INTEGER, NA_INTEGER};
    unsigned int temp = NA_INTEGER;
    unsigned int power = NA_INTEGER;
    nvmlMemory_t memory_info = {0};

    result = nvmlDeviceGetUtilizationRates(device, &utilization);
    if (result != NVML_SUCCESS) {
        utilization.gpu = NA_INTEGER;
        utilization.memory = NA_INTEGER;
    }

    result = nvmlDeviceGetTemperature(device, NVML_TEMPERATURE_GPU, &temp);
    if (result != NVML_SUCCESS) {
        temp = NA_INTEGER;
    }

    result = nvmlDeviceGetPowerUsage(device, &power);
    if (result != NVML_SUCCESS) {
        power = NA_INTEGER;
    }

    result = nvmlDeviceGetMemoryInfo(device, &memory_info);
    if (result != NVML_SUCCESS) {
        memory_info.used = NA_REAL;
        memory_info.total = NA_REAL;
    }

    SEXP metrics = PROTECT(allocVector(VECSXP, 6));
    SEXP names   = PROTECT(allocVector(STRSXP, 6));

    SET_STRING_ELT(names, 0, mkChar("gpu_util"));
    SET_STRING_ELT(names, 1, mkChar("mem_util"));
    SET_STRING_ELT(names, 2, mkChar("temperature"));
    SET_STRING_ELT(names, 3, mkChar("power_usage"));
    SET_STRING_ELT(names, 4, mkChar("memory_used"));
    SET_STRING_ELT(names, 5, mkChar("memory_total"));

    SET_VECTOR_ELT(metrics, 0, ScalarInteger(utilization.gpu));
    SET_VECTOR_ELT(metrics, 1, ScalarInteger(utilization.memory));
    SET_VECTOR_ELT(metrics, 2, ScalarInteger(temp));
    SET_VECTOR_ELT(metrics, 3, ScalarInteger(power));
    SET_VECTOR_ELT(metrics, 4, ScalarReal((double) memory_info.used));
    SET_VECTOR_ELT(metrics, 5, ScalarReal((double)memory_info.total));

    setAttrib(metrics, R_NamesSymbol, names);
    UNPROTECT(2);
    return metrics;
}

SEXP nvml_error_string_c(SEXP err_code_sexp) {
    if (!isInteger(err_code_sexp) && !isReal(err_code_sexp)) {
        Rf_error("nvml_error_string_c: err_code must be an integer");
    }
    int err_code = asInteger(err_code_sexp);
    const char *msg = nvmlErrorString((nvmlReturn_t) err_code);
    if (msg == NULL) {
        msg = "Unknown NVML error";
    }
    return mkString(msg);
}

static const R_CallMethodDef callMethods[] = {
    {"nvml_init_c",          (DL_FUNC) &nvml_init_c,          0},
    {"nvml_shutdown_c",      (DL_FUNC) &nvml_shutdown_c,      0},
    {"nvml_device_count_c",  (DL_FUNC) &nvml_device_count_c,  0},
    {"nvml_get_metrics_c",   (DL_FUNC) &nvml_get_metrics_c,   1},
    {"nvml_error_string_c",  (DL_FUNC) &nvml_error_string_c,  1},
    {NULL, NULL, 0}
};

void R_init_CudaMon(DllInfo *dll) {
    R_registerRoutines(dll, NULL, callMethods, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
