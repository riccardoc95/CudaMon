nvcc -Xcompiler "-fPIC" -shared -o cudamatrix.so cudamatrix.cu \
  -I"$(R RHOME)/include" \
  -L"$(R RHOME)/lib" -lR
