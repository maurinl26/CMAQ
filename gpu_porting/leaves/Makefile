# Makefile pour compiler les routines GPU (feuilles)

.PHONY: all clean

FC = nvfortran
FFLAGS = -acc -gpu=cc80 -Minfo=accel

# Routines à compiler
ROUTINES = vertnhy_wrf layht getpblht

all: $(ROUTINES)

# Règles de compilation pour chaque routine
vertnhy_wrf: driver_vertnhy
	@echo "✅ vertnhy_wrf compilé"

layht: driver_layht
	@echo "✅ layht compilé"

getpblht: driver_getpblht
	@echo "✅ getpblht compilé"

# Règles génériques pour les drivers
%: %.o
	$(FC) $(FFLAGS) $< -o $@

%.o: %.f90
	$(FC) $(FFLAGS) -c $< -o $@

clean:
	rm -f $(ROUTINES) *.o *.mod