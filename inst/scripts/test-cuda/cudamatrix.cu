#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include <cuda_runtime.h>
#include <time.h>
#include <stdlib.h>

#define ROWS 1000
#define COLS 1000
#define DEFAULT_ITERATIONS 10

__global__ void matrixMultiplyKernel(const int *A, const int *B, int *C, int m, int n, int k) {
    int row = blockIdx.y * blockDim.y + threadIdx.y;
    int col = blockIdx.x * blockDim.x + threadIdx.x;

    if (row < m && col < n) {
        int sum = 0;
        for (int i = 0; i < k; i++) {
            sum += A[row * k + i] * B[col * k + i];
        }
        C[row * n + col] = sum;
    }
}

static void initializeMatrix(int *matrix, int rows, int cols) {
    for (int i = 0; i < rows * cols; i++) {
        matrix[i] = (rand() % 256) - 128;
    }
}

extern "C" SEXP cuda_matrix_multiply(SEXP iterations) {
    int num_iterations = asInteger(iterations);
    if (num_iterations <= 0) {
        num_iterations = DEFAULT_ITERATIONS;
    }

    srand((unsigned int)time(NULL));

    int m = ROWS;
    int k = COLS;
    int n = COLS;

    size_t size_A = (size_t)m * k * sizeof(int);
    size_t size_B = (size_t)m * k * sizeof(int);
    size_t size_C = (size_t)k * n * sizeof(int);

    int *h_A = (int*)malloc(size_A);
    int *h_B = (int*)malloc(size_B);
    int *h_C = (int*)malloc(size_C);

    if (!h_A || !h_B || !h_C) {
        free(h_A); free(h_B); free(h_C);
        error("Host memory allocation failed");
    }

    int *d_A = NULL, *d_B = NULL, *d_C = NULL;
    cudaError_t err;

    err = cudaMalloc((void**)&d_A, size_A);
    if (err != cudaSuccess) error("cudaMalloc d_A failed: %s", cudaGetErrorString(err));

    err = cudaMalloc((void**)&d_B, size_B);
    if (err != cudaSuccess) error("cudaMalloc d_B failed: %s", cudaGetErrorString(err));

    err = cudaMalloc((void**)&d_C, size_C);
    if (err != cudaSuccess) error("cudaMalloc d_C failed: %s", cudaGetErrorString(err));

    dim3 blockDim(16, 16);
    dim3 gridDim((n + blockDim.x - 1) / blockDim.x,
                 (k + blockDim.y - 1) / blockDim.y);

    clock_t start = clock();

    for (int iter = 0; iter < num_iterations; iter++) {
        // Rprintf("Iteration %d/%d\n", iter + 1, num_iterations);

        initializeMatrix(h_A, m, k);
        initializeMatrix(h_B, m, k);

        err = cudaMemcpy(d_A, h_A, size_A, cudaMemcpyHostToDevice);
        if (err != cudaSuccess) error("cudaMemcpy A failed: %s", cudaGetErrorString(err));

        err = cudaMemcpy(d_B, h_B, size_B, cudaMemcpyHostToDevice);
        if (err != cudaSuccess) error("cudaMemcpy B failed: %s", cudaGetErrorString(err));

        matrixMultiplyKernel<<<gridDim, blockDim>>>(d_B, d_A, d_C, k, n, m);

        err = cudaGetLastError();
        if (err != cudaSuccess) error("Kernel launch failed: %s", cudaGetErrorString(err));

        err = cudaDeviceSynchronize();
        if (err != cudaSuccess) error("Device sync failed: %s", cudaGetErrorString(err));

        err = cudaMemcpy(h_C, d_C, size_C, cudaMemcpyDeviceToHost);
        if (err != cudaSuccess) error("cudaMemcpy C failed: %s", cudaGetErrorString(err));
    }

    clock_t end = clock();
    double total_time_ms = ((double)(end - start)) / CLOCKS_PER_SEC * 1000.0;

    SEXP result = PROTECT(allocVector(REALSXP, 1));
    SEXP names  = PROTECT(allocVector(STRSXP, 1));
    REAL(result)[0] = total_time_ms;
    SET_STRING_ELT(names, 0, mkChar("total_time_ms"));
    setAttrib(result, R_NamesSymbol, names);

    cudaFree(d_A);
    cudaFree(d_B);
    cudaFree(d_C);
    free(h_A);
    free(h_B);
    free(h_C);

    UNPROTECT(2);
    return result;
}

static const R_CallMethodDef CallEntries[] = {
    {"cuda_matrix_multiply", (DL_FUNC) &cuda_matrix_multiply, 1},
    {NULL, NULL, 0}
};

extern "C" void R_init_cudamatrix(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
