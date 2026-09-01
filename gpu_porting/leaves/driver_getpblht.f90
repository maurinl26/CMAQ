PROGRAM driver_getpblht
  USE getpblht_mod, ONLY: getpblht_gpu
  IMPLICIT NONE

  ! Initialisation des tableaux (simplifiée)
  CALL init_arrays()

  ! Appel de la routine GPU
  PRINT *, "🚀 Exécution de getpblht_gpu...")
  CALL getpblht_gpu()
  PRINT *, "✅ Routine GPU exécutée avec succès !"

  ! Affichage des résultats
  PRINT *, "Premières valeurs de xpbl(1:5,1) : ", xpbl(1:5, 1)

CONTAINS

  SUBROUTINE init_arrays()
    USE getpblht_mod, ONLY: ncols_x, nrows_x, metlay, xthetav, xwvapor, xuu, xvv, xzf, xdzf
    IMPLICIT NONE
    INTEGER :: c, r, k

    ! Initialisation avec des valeurs arbitraires
    DO c = 1, ncols_x
      DO r = 1, nrows_x
        DO k = 1, metlay
          xthetav(c, r, k) = 300.0
          xwvapor(c, r, k) = 0.01
          xuu(c, r, k) = 10.0
          xvv(c, r, k) = 5.0
          xzf(c, r, k) = 100.0 * k
          xdzf(c, r, k) = 100.0
        ENDDO
      ENDDO
    ENDDO
  END SUBROUTINE init_arrays

END PROGRAM driver_getpblht