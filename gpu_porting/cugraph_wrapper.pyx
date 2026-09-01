# cython: language_level=3
# distutils: libraries = cugraph
# distutils: include_dirs = /usr/local/cuda/include
# distutils: library_dirs = /usr/local/cuda/lib64

import numpy as np
cimport numpy as np
from libc.stdlib cimport malloc, free
from libc.stdio cimport printf
from cugraph.bindings cimport cugraph as c_cugraph

# Wrapper pour orchestrer les kernels GPU via cuGraphs
cdef class CUGraphWrapper:
    cdef c_cugraph.CUGraph* graph
    cdef c_cugraph.CUGraphExec* graph_exec
    cdef bint is_initialized

    def __cinit__(self):
        self.graph = <c_cugraph.CUGraph*>malloc(sizeof(c_cugraph.CUGraph))
        self.graph_exec = <c_cugraph.CUGraphExec*>malloc(sizeof(c_cugraph.CUGraphExec))
        self.is_initialized = False
        c_cugraph.cugraphCreate(self.graph)

    def __dealloc__(self):
        if self.is_initialized:
            c_cugraph.cugraphDestroy(self.graph)
            c_cugraph.cugraphExecDestroy(self.graph_exec)
        free(self.graph)
        free(self.graph_exec)

    def add_kernel(self, kernel_name: str, grid_dim: tuple, block_dim: tuple, args: dict):
        """Ajoute un kernel CUDA au graphe cuGraphs."""
        if not self.is_initialized:
            raise RuntimeError("CUGraphWrapper not initialized. Call initialize() first.")

        # Convertir les arguments en pointeurs void*
        cdef void** kernel_args = <void**>malloc(len(args) * sizeof(void*))
        cdef int i = 0
        for key, value in args.items():
            if isinstance(value, np.ndarray):
                kernel_args[i] = <void*>value.data
            else:
                kernel_args[i] = <void*>&value
            i += 1

        # Créer un nœud pour le kernel
        cdef c_cugraph.CUGraphNode* node
        c_cugraph.cugraphAddKernelNode(
            self.graph,
            kernel_name.encode('utf-8'),
            grid_dim,
            block_dim,
            kernel_args,
            len(args),
            &node
        )
        free(kernel_args)

    def initialize(self):
        """Finalise la création du graphe et prépare l'exécution."""
        c_cugraph.cugraphInstantiate(self.graph, self.graph_exec)
        self.is_initialized = True

    def execute(self):
        """Exécute le graphe cuGraphs."""
        if not self.is_initialized:
            raise RuntimeError("CUGraphWrapper not initialized. Call initialize() first.")
        c_cugraph.cugraphLaunch(self.graph_exec)