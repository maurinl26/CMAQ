PROGRAM driver_layht
  USE layht_mod, ONLY: layht_gpu
  IMPLICIT NONE

  ! Paramètres
  INTEGER, PARAMETER :: lbndf = 1, ubndf = 30, lbndm = 1, ubndm = 30

  ! Appel de la routine GPU
  PRINT *, "🚀 Exécution de layht_gpu...")
  CALL layht_gpu(lbndf, ubndf, lbndm, ubndm)
  PRINT *, "✅ Routine GPU exécutée avec succès !"

END PROGRAM driver_layht