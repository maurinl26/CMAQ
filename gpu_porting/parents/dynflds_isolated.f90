MODULE dynflds_mod
  IMPLICIT NONE

  ! Paramètres locaux pour remplacer mcipparm
  INTEGER, PARAMETER :: ncols_x = 100, nrows_x = 100, metlay = 30

CONTAINS

  SUBROUTINE dynflds_gpu()
    USE bcldprc_ak_mod, ONLY: bcldprc_ak_gpu
    USE metvars2ctm_mod, ONLY: metvars2ctm_gpu
    USE pblsup_mod, ONLY: pblsup_gpu
    IMPLICIT NONE

    PRINT *, "🚀 Exécution de dynflds_gpu..."

    !$acc data copyin(ncols_x, nrows_x, metlay)
    
    ! Appels aux routines parentes GPU
    CALL metvars2ctm_gpu()
    CALL pblsup_gpu()
    CALL bcldprc_ak_gpu()
    
    !$acc end data
    
    PRINT *, "✅ dynflds_gpu exécutée avec succès !"
  END SUBROUTINE dynflds_gpu

END MODULE dynflds_mod