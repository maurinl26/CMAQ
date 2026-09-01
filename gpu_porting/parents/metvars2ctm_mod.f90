MODULE metvars2ctm_mod
  IMPLICIT NONE

  ! Paramètres locaux pour remplacer les dépendances
  INTEGER, PARAMETER :: ncols_x = 100, nrows_x = 100, metlay = 30
  CHARACTER(LEN=16), PARAMETER :: pname = 'metvars2ctm'

  ! Tableaux locaux (simplifiés)
  REAL :: xtempm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xpressm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xdensm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: x3htm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: x3htf(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xdx3htm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xdx3htf(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xwhat(ncols_x, nrows_x, metlay) = 0.0

CONTAINS

  SUBROUTINE metvars2ctm_gpu()
    USE layht_mod, ONLY: layht_gpu
    USE vertnhy_wrf_mod, ONLY: vertnhy_wrf_gpu
    IMPLICIT NONE
    INTEGER :: c, r, k

    PRINT *, "🚀 Exécution de metvars2ctm_gpu..."

    !$acc data copyin(ncols_x, nrows_x, metlay) &
    !$acc      copy(xtempm, xpressm, xdensm, x3htm, x3htf, xdx3htm, xdx3htf, xwhat)
    
    ! Appel des routines GPU
    CALL layht_gpu(1, metlay, 1, metlay)
    CALL vertnhy_wrf_gpu()
    
    ! Boucles de traitement (simplifiées)
    !$acc parallel loop collapse(2) default(present)
    DO c = 1, ncols_x
      DO r = 1, nrows_x
        ! Calcul de la densité (XDENSM)
        DO k = 1, metlay
          xdensm(c, r, k) = xpressm(c, r, k) / (287.05 * xtempm(c, r, k))
        ENDDO
      ENDDO
    ENDDO
    !$acc end parallel loop
    
    !$acc end data
    
    PRINT *, "✅ metvars2ctm_gpu exécutée avec succès !"
  END SUBROUTINE metvars2ctm_gpu

END MODULE metvars2ctm_mod