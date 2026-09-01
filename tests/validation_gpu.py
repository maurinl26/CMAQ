#!/usr/bin/env python3
"""
Script de validation pour comparer les sorties CPU et GPU des kernels de simulation sismique.

Ce script :
1. Compile les versions CPU et GPU du code.
2. Exécute les deux versions.
3. Compare les sorties pour valider la précision numérique.
4. Génère un rapport de performance.
"""

import subprocess
import os
import numpy as np
import argparse
import sys
from pathlib import Path


def compile_cpu_version():
    """Compile la version CPU du code."""
    print("🔧 Compilation de la version CPU...")
    try:
        subprocess.run([
            "gfortran", 
            "-O2", 
            "-o", "wave_driver_cpu", 
            "driver.f90", 
            "original.f90"
        ], check=True, cwd=".")
        print("✅ Compilation CPU réussie.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur lors de la compilation CPU : {e}")
        sys.exit(1)


def compile_gpu_version():
    """Compile la version GPU du code."""
    print("🔧 Compilation de la version GPU...")
    try:
        # Vérifier que les fichiers GPU existent
        gpu_module = Path("output/fortran_gpu/module_kernels_gpu.F90")
        if not gpu_module.exists():
            print("❌ Fichier GPU manquant : output/fortran_gpu/module_kernels_gpu.F90")
            sys.exit(1)
        
        # Compiler avec nvfortran
        subprocess.run([
            "nvfortran", 
            "-acc", 
            "-gpu=cc80",  # Architecture A100 (ajuster si nécessaire)
            "-o", "wave_driver_gpu", 
            "driver.f90", 
            "output/fortran_gpu/module_kernels_gpu.F90"
        ], check=True, cwd=".")
        print("✅ Compilation GPU réussie.")
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur lors de la compilation GPU : {e}")
        sys.exit(1)


def run_cpu_version():
    """Exécute la version CPU et retourne la sortie."""
    print("🚀 Exécution de la version CPU...")
    try:
        result = subprocess.run(
            "./wave_driver_cpu", 
            capture_output=True, 
            text=True, 
            check=True, 
            cwd="."
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur lors de l'exécution CPU : {e}")
        sys.exit(1)


def run_gpu_version():
    """Exécute la version GPU et retourne la sortie."""
    print("🚀 Exécution de la version GPU...")
    try:
        result = subprocess.run(
            "./wave_driver_gpu", 
            capture_output=True, 
            text=True, 
            check=True, 
            cwd="."
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ Erreur lors de l'exécution GPU : {e}")
        sys.exit(1)


def parse_output(output):
    """Parse la sortie du driver pour extraire les valeurs."""
    lines = output.strip().split("\n")
    data = []
    for line in lines:
        parts = line.split()
        i, j, value = int(parts[0]), int(parts[1]), float(parts[2])
        data.append((i, j, value))
    return np.array(data)


def compare_outputs(cpu_output, gpu_output, tolerance=1e-12):
    """Compare les sorties CPU et GPU."""
    print("🔍 Comparaison des résultats CPU/GPU...")
    
    # Extraire les valeurs
    cpu_data = parse_output(cpu_output)
    gpu_data = parse_output(gpu_output)
    
    # Vérifier la forme
    if cpu_data.shape != gpu_data.shape:
        print("❌ Les sorties CPU et GPU n'ont pas la même taille.")
        return False
    
    # Calculer les écarts
    diff = np.abs(cpu_data[:, 2] - gpu_data[:, 2])
    max_diff = np.max(diff)
    
    if max_diff > tolerance:
        print(f"❌ Écart maximal ({max_diff}) dépasse la tolérance ({tolerance}).")
        return False
    else:
        print(f"✅ Écart maximal ({max_diff}) dans la tolérance ({tolerance}).")
        return True


def main():
    parser = argparse.ArgumentParser(description="Validation des kernels CPU/GPU.")
    parser.add_argument(
        "--tolerance", 
        type=float, 
        default=1e-12, 
        help="Tolérance pour la comparaison des résultats (défaut: 1e-12)"
    )
    args = parser.parse_args()
    
    # Vérifier que nous sommes dans le bon répertoire
    os.chdir("/Users/loicmaurin/coding-agent/tests/fixtures/equivalence/wave_kernels")
    
    # Compiler les versions
    compile_cpu_version()
    compile_gpu_version()
    
    # Exécuter les versions
    cpu_output = run_cpu_version()
    gpu_output = run_gpu_version()
    
    # Comparer les résultats
    success = compare_outputs(cpu_output, gpu_output, args.tolerance)
    
    if success:
        print("🎉 Validation réussie : les résultats CPU et GPU sont identiques.")
    else:
        print("❌ Validation échouée : les résultats CPU et GPU diffèrent.")
        sys.exit(1)


if __name__ == "__main__":
    main()