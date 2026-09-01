MODULE pblsup_mod
  IMPLICIT NONE

  ! Paramètres locaux pour remplacer les dépendances
  INTEGER, PARAMETER :: ncols_x = 100, nrows_x = 100, metlay = 30, nummosaic = 10
  REAL, PARAMETER :: karman = 0.4, g = 9.81

  ! Tableaux locaux (simplifiés)
  REAL :: xwspd10(ncols_x, nrows_x) = 0.0
  REAL :: xwdir10(ncols_x, nrows_x) = 0.0
  REAL :: xpbl(ncols_x, nrows_x) = 0.0
  REAL :: xmol(ncols_x, nrows_x) = 0.0
  REAL :: xustar(ncols_x, nrows_x) = 0.0
  REAL :: xwstar(ncols_x, nrows_x) = 0.0
  REAL :: xznt(ncols_x, nrows_x) = 0.0
  REAL :: xtempm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xpressm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xwvapor(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xuu(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xvv(ncols_x, nrows_x, metlay) = 0.0
  REAL :: x3htm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xznt_mos(ncols_x, nrows_x, nummosaic) = 0.0

CONTAINS

  SUBROUTINE pblsup_gpu()
    USE getpblht_mod, ONLY: getpblht_gpu
    IMPLICIT NONE
    INTEGER :: c, r, k
    REAL :: uns, vns, ulev1, vlev1, theta1, theta2, ztemp, ustmos

    PRINT *, "🚀 Exécution de pblsup_gpu..."

    !$acc data copyin(ncols_x, nrows_x, metlay, nummosaic) &
    !$acc      copy(xwspd10, xwdir10, xpbl, xmol, xustar, xwstar, xznt, xznt_mos) &
    !$acc      copyin(xtempm, xpressm, xwvapor, xuu, xvv, x3htm)
    
    ! Appel des routines GPU
    CALL getpblht_gpu()
    
    ! Boucles de traitement (simplifiées)
    !$acc parallel loop collapse(2) default(present)
    DO c = 1, ncols_x
      DO r = 1, nrows_x
        ! Calcul de la vitesse du vent à 10m (simplifié)
        uns = xuu(c, r, 1)
        vns = xvv(c, r, 1)
        xwspd10(c, r) = SQRT(uns**2 + vns**2)
        xwdir10(c, r) = ATAN2(vns, uns) * 180.0 / 3.14159
        
        ! Calcul de la longueur de Monin-Obukhov (XMOL)
        xmol(c, r) = -xustar(c, r)**3 * xtempm(c, r, 1) / (karman * g * 0.1)
      ENDDO
    ENDDO
    !$acc end parallel loop
    
    !$acc end data
    
    PRINT *, "✅ pblsup_gpu exécutée avec succès !"
  END SUBROUTINE pblsup_gpu

END MODULE pblsup_mod