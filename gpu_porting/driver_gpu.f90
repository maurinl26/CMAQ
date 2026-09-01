PROGRAM driver_gpu
  USE bcldprc_ak_mod, ONLY: bcldprc_ak_gpu
  IMPLICIT NONE

  ! Initialisation des tableaux (simplifiée)
  CALL init_arrays()

  ! Appel de la routine GPU
  PRINT *, "🚀 Exécution de bcldprc_ak_gpu...")
  CALL bcldprc_ak_gpu()
  PRINT *, "✅ Routine GPU exécutée avec succès !"

  ! Affichage des résultats
  PRINT *, "Premières valeurs de xwbar(1:5,1) : ", xwbar(1:5, 1)

CONTAINS

  SUBROUTINE init_arrays()
    USE bcldprc_ak_mod, ONLY: ncols_x, nrows_x, metlay, xtempm, xpresm, xwvapor, xdx3htf, x3htf, xpbl
    IMPLICIT NONE
    INTEGER :: c, r, k
    
    ! Initialisation avec des valeurs arbitraires
    DO c = 1, ncols_x
      DO r = 1, nrows_x
        DO k = 1, metlay
          xtempm(c,r,k) = 280.0 + 5.0 * k
          xpresm(c,r,k) = 100000.0 - 1000.0 * k
          xwvapor(c,r,k) = 0.01
          xdx3htf(c,r,k) = 100.0
          x3htf(c,r,k) = 1000.0 + 10.0 * k
        ENDDO
        xpbl(c,r) = 1500.0
      ENDDO
    ENDDO
  END SUBROUTINE init_arrays

END PROGRAM driver_gpu