from setuptools import setup
from Cython.Build import cythonize
import numpy as np

setup(
    name="cugraph_wrapper",
    ext_modules=cythonize("cugraph_wrapper.pyx"),
    include_dirs=[np.get_include(), "/usr/local/cuda/include"],
    library_dirs=["/usr/local/cuda/lib64"],
    libraries=["cugraph"],
    extra_compile_args=["-O3", "-std=c++17"],
    extra_link_args=["-lcudart"],
)