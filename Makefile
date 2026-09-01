# Makefile pour CMAQ GPU

.PHONY: all cpu gpu clean

all: cpu gpu

cpu:
	gfortran -O2 -o wave_driver_cpu src/driver_gpu.f90 tests/fixtures/equivalence/wave_kernels/original.f90

gpu:
	nvfortran -acc -gpu=cc80 -o wave_driver_gpu src/driver_gpu.f90 src/gpu_kernels/module_kernels_gpu.F90

clean:
	rm -f wave_driver_cpu wave_driver_gpu