# Makefile pour compiler le kernel GPU de CMAQ

.PHONY: all gpu clean

FC = nvfortran
FFLAGS = -acc -gpu=cc80 -Minfo=accel

all: gpu

gpu: driver_gpu

# Compiler le module puis le driver
module_kernels_gpu.o: bcldprc_ak_isolated.f90
	$(FC) $(FFLAGS) -c $< -o $@

driver_gpu: driver_gpu.f90 module_kernels_gpu.o
	$(FC) $(FFLAGS) $^ -o $@

clean:
	rm -f driver_gpu *.o *.mod