#!/bin/bash
# Script pour installer les dépendances GPU sur une machine distante Linux (Ubuntu 22.04)

# Mettre à jour les paquets
sudo apt-get update -y
sudo apt-get upgrade -y

# Installer les dépendances système
sudo apt-get install -y \
    build-essential \
    python3-dev \
    python3-pip \
    python3-venv \
    git \
    wget \
    cmake \
    libopenmpi-dev \
    openmpi-bin

# Installer NVIDIA HPC SDK (CUDA 12.3)
wget https://developer.download.nvidia.com/hpc-sdk/23.11/nvhpc_2023_2311_Linux_x86_64_cuda_12.3.tar.gz
tar -xzvf nvhpc_2023_2311_Linux_x86_64_cuda_12.3.tar.gz
cd nvhpc_2023_2311_Linux_x86_64_cuda_12.3
sudo ./install
cd ..
rm -rf nvhpc_2023_2311_Linux_x86_64_cuda_12.3*

# Configurer l'environnement
echo "export PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/23.11/compilers/bin:\$PATH" >> ~/.bashrc
echo "export LD_LIBRARY_PATH=/opt/nvidia/hpc_sdk/Linux_x86_64/23.11/compilers/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc
source ~/.bashrc

# Installer cuGraphs et RAPIDS
pip3 install --extra-index-url=https://pypi.nvidia.com \
    cugraph-cu12==23.12.* \
    cuml-cu12==23.12.* \
    cudf-cu12==23.12.* \
    numpy \
    cython

# Installer les dépendances Python pour le wrapper
pip3 install setuptools wheel