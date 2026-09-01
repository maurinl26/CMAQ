MODULE getpblht_mod
  IMPLICIT NONE

  ! Paramètres locaux
  INTEGER, PARAMETER :: ncols_x = 100, nrows_x = 100, metlay = 30
  REAL, PARAMETER :: rib_crit = 0.25
  REAL :: xpbl(ncols_x, nrows_x) = 0.0
  REAL :: xthetav(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xwvapor(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xuu(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xvv(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xzf(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xdzf(ncols_x, nrows_x, metlay) = 0.0

CONTAINS

  SUBROUTINE getpblht_gpu
    IMPLICIT NONE
    INTEGER :: c, r, k
    REAL :: rib, rib_prev, thetav1, thetav2, wind1, wind2, z1, z2, dz

    !$acc data copy(xpbl) copyin(xthetav, xwvapor, xuu, xvv, xzf, xdzf)
    !$acc parallel loop collapse(2) default(present)
    DO c = 1, ncols_x
      DO r = 1, nrows_x
        xpbl(c, r) = 0.0
        rib_prev = 0.0
        
        !$acc loop seq
        ribloop: DO k = 1, metlay-1
          ! Calcul de la température virtuelle (THETAV)
          thetav1 = xthetav(c, r, k) * (1.0 + 0.608 * xwvapor(c, r, k))
          thetav2 = xthetav(c, r, k+1) * (1.0 + 0.608 * xwvapor(c, r, k+1))
          
          ! Calcul de la vitesse du vent (WIND)
          wind1 = SQRT(xuu(c, r, k)**2 + xvv(c, r, k)**2)
          wind2 = SQRT(xuu(c, r, k+1)**2 + xvv(c, r, k+1)**2)
          
          ! Calcul du nombre de Richardson (RIB)
          z1 = xzf(c, r, k)
          z2 = xzf(c, r, k+1)
          dz = xdzf(c, r, k)
          
          rib = 9.81 * (thetav2 - thetav1) * dz / &
                (0.5 * (thetav1 + thetav2) * (wind2 - wind1 + 0.01)**2)
          
          ! Détermination de la hauteur de la PBL
          IF (rib > rib_crit) THEN
            xpbl(c, r) = z1 + (rib_crit - rib_prev) * (z2 - z1) / (rib - rib_prev)
            EXIT ribloop
          ENDIF
          rib_prev = rib
        ENDDO ribloop
      ENDDO
    ENDDO
    !$acc end parallel loop
    !$acc end data
  END SUBROUTINE getpblht_gpu

END MODULE getpblht_mod