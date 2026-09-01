module gpu_kernels_mod
    use iso_c_binding, only: c_int, c_float, c_loc, c_f_pointer
    implicit none

    ! Paramètres globaux (à remplacer par des arguments dans une version finale)
    integer, parameter :: ncols_x = 400, nrows_x = 300
    integer, parameter :: nz = 50

    ! Interface pour le wrapper cuGraphs
    interface
        subroutine cugraph_wrapper_init() bind(C, name="cugraph_wrapper_init")
            use iso_c_binding
        end subroutine cugraph_wrapper_init

        subroutine cugraph_wrapper_add_kernel(kernel_name, grid_dim, block_dim, args) bind(C, name="cugraph_wrapper_add_kernel")
            use iso_c_binding
            character(kind=c_char), dimension(*), intent(in) :: kernel_name
            integer(c_int), dimension(3), intent(in) :: grid_dim, block_dim
            type(c_ptr), value, intent(in) :: args
        end subroutine cugraph_wrapper_add_kernel

        subroutine cugraph_wrapper_execute() bind(C, name="cugraph_wrapper_execute")
            use iso_c_binding
        end subroutine cugraph_wrapper_execute
    end interface

    ! Structures pour les arguments des kernels
    type :: vertnhy_args
        real(c_float), dimension(:,:,:), pointer :: xwhat, xdgwrf, xpres
        integer(c_int) :: nz
    end type vertnhy_args

    type :: layht_args
        real(c_float), dimension(:,:,:), pointer :: xwhat, xdgwrf, xpres
        integer(c_int) :: nz
    end type layht_args

    type :: getpblht_args
        real(c_float), dimension(:,:), pointer :: xpblht
        real(c_float), dimension(:,:,:), pointer :: xwhat, xpres
        integer(c_int) :: nz
    end type getpblht_args

    type :: bcldprc_args
        real(c_float), dimension(:,:,:), pointer :: xcldod, xcldwtr
        real(c_float), dimension(:,:,:), pointer :: xwhat, xpres
        integer(c_int) :: nz
    end type bcldprc_args

contains
    subroutine run_gpu_kernels()
        use vertnhy_wrf_mod, only: vertnhy_wrf_gpu
        use layht_mod, only: layht_gpu
        use getpblht_mod, only: getpblht_gpu
        use bcldprc_ak_mod, only: bcldprc_ak_gpu
        
        type(vertnhy_args), target :: args_vertnhy
        type(layht_args), target :: args_layht
        type(getpblht_args), target :: args_getpblht
        type(bcldprc_args), target :: args_bcldprc
        
        ! Initialiser les arguments (exemple)
        allocate(args_vertnhy%xwhat(ncols_x, nrows_x, nz))
        allocate(args_vertnhy%xdgwrf(ncols_x, nrows_x, nz))
        allocate(args_vertnhy%xpres(ncols_x, nrows_x, nz))
        args_vertnhy%nz = nz
        
        allocate(args_layht%xwhat(ncols_x, nrows_x, nz))
        allocate(args_layht%xdgwrf(ncols_x, nrows_x, nz))
        allocate(args_layht%xpres(ncols_x, nrows_x, nz))
        args_layht%nz = nz
        
        allocate(args_getpblht%xpblht(ncols_x, nrows_x))
        allocate(args_getpblht%xwhat(ncols_x, nrows_x, nz))
        allocate(args_getpblht%xpres(ncols_x, nrows_x, nz))
        args_getpblht%nz = nz
        
        allocate(args_bcldprc%xcldod(ncols_x, nrows_x, nz))
        allocate(args_bcldprc%xcldwtr(ncols_x, nrows_x, nz))
        allocate(args_bcldprc%xwhat(ncols_x, nrows_x, nz))
        allocate(args_bcldprc%xpres(ncols_x, nrows_x, nz))
        args_bcldprc%nz = nz
        
        ! Initialiser le wrapper cuGraphs
        call cugraph_wrapper_init()
        
        ! Ajouter les kernels au graphe cuGraphs
        call cugraph_wrapper_add_kernel("vertnhy_wrf_gpu", [ncols_x, nrows_x, 1], [32, 32, 1], c_loc(args_vertnhy))
        call cugraph_wrapper_add_kernel("layht_gpu", [ncols_x, nrows_x, 1], [32, 32, 1], c_loc(args_layht))
        call cugraph_wrapper_add_kernel("getpblht_gpu", [ncols_x, nrows_x, 1], [32, 32, 1], c_loc(args_getpblht))
        call cugraph_wrapper_add_kernel("bcldprc_ak_gpu", [ncols_x, nrows_x, 1], [32, 32, 1], c_loc(args_bcldprc))
        
        ! Exécuter le graphe cuGraphs
        call cugraph_wrapper_execute()
        
        ! Libérer la mémoire
        deallocate(args_vertnhy%xwhat, args_vertnhy%xdgwrf, args_vertnhy%xpres)
        deallocate(args_layht%xwhat, args_layht%xdgwrf, args_layht%xpres)
        deallocate(args_getpblht%xpblht, args_getpblht%xwhat, args_getpblht%xpres)
        deallocate(args_bcldprc%xcldod, args_bcldprc%xcldwtr, args_bcldprc%xwhat, args_bcldprc%xpres)
    end subroutine run_gpu_kernels
end module gpu_kernels_mod