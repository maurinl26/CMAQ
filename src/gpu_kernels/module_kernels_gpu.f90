SUBROUTINE update_vx_gpu (vx, sigma_xx, dx, nx, ny)
  REAL(KIND=8), INTENT(INOUT) :: vx(nx, ny)
  REAL(KIND=8), INTENT(IN) :: sigma_xx(nx, ny)
  REAL(KIND=8), INTENT(IN) :: dx
  INTEGER, INTENT(IN) :: nx, ny
  INTEGER :: i, j
  !$acc parallel loop collapse(2) default(present)
  DO j=2,ny
    DO i=2,nx
      vx(i, j) = vx(i, j) + (sigma_xx(i, j) - sigma_xx(i - 1, j)) / dx
    END DO
  END DO
  !$acc end parallel loop
END SUBROUTINE update_vx_gpu

SUBROUTINE update_sigma_gpu (sigma_xx, vx, vy, dx, dy, nx, ny)
  REAL(KIND=8), INTENT(INOUT) :: sigma_xx(nx, ny)
  REAL(KIND=8), INTENT(IN) :: vx(nx, ny), vy(nx, ny)
  REAL(KIND=8), INTENT(IN) :: dx, dy
  INTEGER, INTENT(IN) :: nx, ny
  INTEGER :: i, j
  !$acc parallel loop collapse(2) default(present)
  DO j=2,ny - 1
    DO i=2,nx - 1
      sigma_xx(i, j) = sigma_xx(i, j) + (vx(i + 1, j) - vx(i, j)) / dx + (vy(i, j + 1) - vy(i, j)) / dy
    END DO
  END DO
  !$acc end parallel loop
END SUBROUTINE update_sigma_gpu