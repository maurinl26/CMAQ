# Makefile pour compiler les routines parentes GPU

.PHONY: all clean

FC = gfortran  # Utiliser gfortran pour la vérification CPU

# Modules des feuilles
LEAVES = ../leaves/vertnhy_wrf_mod.f90 ../leaves/layht_mod.f90 ../leaves/getpblht_mod.f90 ../leaves/bcldprc_ak_mod.f90

all: dynflds_gpu

# Règle pour compiler les modules des feuilles
../leaves/%.o: ../leaves/%.f90
	$(FC) -c $< -o $@ -J.

# Règle pour dynflds_gpu
dynflds_gpu.o: dynflds_isolated.f90
	$(FC) -c $< -o $@ -J.

main.o: main.f90
	$(FC) -c $< -o $@ -J.

dynflds_gpu: main.o dynflds_gpu.o $(LEAVES:.f90=.o)
	$(FC) -o $@ $^ -J.

clean:
	rm -f *.o *.mod dynflds_gpu