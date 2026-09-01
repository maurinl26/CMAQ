MODULE layht_mod
  IMPLICIT NONE

  ! Paramètres locaux
  INTEGER, PARAMETER :: imax = 100, jmax = 100, kmax = 30
  REAL :: xdx3htf(imax, jmax, kmax) = 0.0
  REAL :: xdx3htm(imax, jmax, kmax) = 0.0
  REAL :: x3face(kmax) = 0.0
  REAL :: x3midl(kmax) = 0.0

CONTAINS

  SUBROUTINE layht_gpu(lbndf, ubndf, lbndm, ubndm)
    IMPLICIT NONE
    INTEGER, INTENT(IN) :: lbndf, ubndf, lbndm, ubndm
    INTEGER :: i, j, k

    !$acc data copy(xdx3htf, xdx3htm) copyin(x3face, x3midl)
    !$acc parallel loop collapse(2) default(present)
    DO i = 1, imax
      DO j = 1, jmax
        !$acc loop seq
        DO k = lbndf+1, ubndf
          xdx3htf(i, j, k) = x3face(k) - x3face(k-1)
        ENDDO
        
        !$acc loop seq
        DO k = lbndm+1, ubndm
          xdx3htm(i, j, k) = x3midl(k) - x3midl(k-1)
        ENDDO
      ENDDO
    ENDDO
    !$acc end parallel loop
    !$acc end data
  END SUBROUTINE layht_gpu

END MODULE layht_mod