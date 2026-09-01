MODULE vertnhy_wrf_mod
  IMPLICIT NONE

  ! Paramètres locaux pour remplacer les dépendances
  INTEGER, PARAMETER :: metlay = 30, ncols_x = 100, nrows_x = 100
  REAL, PARAMETER :: giwrf = 1.0 / 9.81
  REAL, SAVE :: ddx2, ddy2
  LOGICAL, SAVE :: firsttime = .TRUE.

  ! Tableaux locaux (simplifiés)
  REAL, SAVE, ALLOCATABLE :: wght_bot(:), wght_top(:)
  REAL, SAVE :: xx3face(metlay), xx3midl(metlay)
  REAL :: xwhat(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xuu(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xvv(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xmapc(ncols_x, nrows_x) = 0.0
  REAL :: xmapr(ncols_x, nrows_x) = 0.0
  REAL :: xmapc2(ncols_x, nrows_x) = 0.0
  REAL :: xmapr2(ncols_x, nrows_x) = 0.0
  REAL :: x3midl(metlay) = 0.0
  REAL :: x3face(metlay) = 0.0
  REAL :: xphm(ncols_x, nrows_x, metlay) = 0.0

CONTAINS

  SUBROUTINE vertnhy_wrf_gpu
    IMPLICIT NONE
    INTEGER :: cm1, col, cp1, lp1, lvl, row, rm1
    REAL :: dphidx, dphidy, dx, dy, ji, mogn, ufcrs, vfcrs

    ! Initialisation des tableaux (simplifiée)
    IF (firsttime) THEN
      ALLOCATE(wght_bot(metlay), wght_top(metlay))
      dx = 1000.0  ! Valeur arbitraire pour xcell_gd
      dy = 1000.0  ! Valeur arbitraire pour ycell_gd
      ddx2 = 0.5 / dx
      ddy2 = 0.5 / dy

      !$acc parallel loop
      DO lvl = 1, metlay-1
        wght_top(lvl) = (xx3face(lvl) - xx3midl(lvl)) / (xx3midl(lvl+1) - xx3midl(lvl))
        wght_bot(lvl) = 1.0 - wght_top(lvl)
      ENDDO
      !$acc end parallel loop

      wght_bot(metlay) = 1.0
      wght_top(metlay) = 0.0
      firsttime = .FALSE.
    ENDIF

    !$acc data copy(xwhat) copyin(xuu, xvv, xmapc, xmapr, xmapc2, xmapr2, xphm, x3midl, x3face)
    !$acc parallel loop collapse(2) default(present)
    DO row = 1, nrows_x
      DO col = 1, ncols_x
        cm1 = MAX(col - 1, 1)
        cp1 = MIN(col + 1, ncols_x)
        rm1 = MAX(row - 1, 1)
        rp1 = MIN(row + 1, nrows_x)

        !$acc loop seq
        DO lvl = 1, metlay-1
          ! Calcul des gradients de géopotentiel
          dphidx = (xphm(cp1, row, lvl) - xphm(cm1, row, lvl)) * ddx2
          dphidy = (xphm(col, rp1, lvl) - xphm(col, rm1, lvl)) * ddy2

          ! Interpolation des composantes du vent
          ufcrs = 0.5 * (xuu(col, row, lvl) + xuu(col, row, lvl+1))
          vfcrs = 0.5 * (xvv(col, row, lvl) + xvv(col, row, lvl+1))

          ! Calcul de la vitesse verticale (XWHAT)
          ji = xmapc(col, row) * xmapr(col, row)
          mogn = 0.5 * (xmapc2(col, row) + xmapr2(col, row))
          xwhat(col, row, lvl) = -giwrf * (ufcrs * ji * dphidx + vfcrs * ji * dphidy) + &
                                  (wght_bot(lvl) * x3midl(lvl) + wght_top(lvl) * x3midl(lvl+1))
        ENDDO
        !$acc end loop
      ENDDO
    ENDDO
    !$acc end parallel loop
    !$acc end data
  END SUBROUTINE vertnhy_wrf_gpu

END MODULE vertnhy_wrf_mod