MODULE dynflds_mod
  IMPLICIT NONE

  ! Paramètres locaux pour remplacer mcipparm
  INTEGER, PARAMETER :: ncols_x = 100, nrows_x = 100, metlay = 30

CONTAINS

  SUBROUTINE dynflds_gpu()
    USE bcldprc_ak_mod, ONLY: bcldprc_ak_gpu
    USE vertnhy_wrf_mod, ONLY: vertnhy_wrf_gpu
    USE layht_mod, ONLY: layht_gpu
    USE getpblht_mod, ONLY: getpblht_gpu
    IMPLICIT NONE

    PRINT *, "🚀 Exécution de dynflds_gpu..."

    !$acc data copyin(ncols_x, nrows_x, metlay)
    
    ! Appels aux routines GPU
    CALL vertnhy_wrf_gpu()
    CALL layht_gpu(1, metlay, 1, metlay)
    CALL getpblht_gpu()
    CALL bcldprc_ak_gpu()
    
    !$acc end data
    
    PRINT *, "✅ dynflds_gpu exécutée avec succès !"
  END SUBROUTINE dynflds_gpu

END MODULE dynflds_mod