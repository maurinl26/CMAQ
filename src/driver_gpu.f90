! Driver — runs `update_vx` then `update_sigma` on a deterministic
! input grid and prints the resulting field values to stdout in a
! machine-readable form: one line per probe point, two columns
! `(i, j) value`.
!
! Same driver is linked against original.f90 and openacc.f90 so the
! pytest harness can diff the two stdout streams.

program wave_driver
  use module_kernels_gpu, only: update_vx_gpu, update_sigma_gpu
  implicit none

  integer, parameter :: nx = 64, ny = 64, nsteps = 20
  real(8), parameter :: dx = 1.0d-2, dy = 1.0d-2
  real(8) :: vx(nx, ny), vy(nx, ny), sigma_xx(nx, ny)
  integer :: i, j, step

  ! ── Deterministic initial fields ─────────────────────────────────────
  ! A smooth Gaussian bump in sigma_xx + a small constant background in
  ! the velocity fields. Reproducible, no PRNG, no floating-point
  ! ordering sensitivity at init.
  do j = 1, ny
    do i = 1, nx
      sigma_xx(i, j) = exp(-((dble(i - nx/2)**2 + dble(j - ny/2)**2) / 50.0d0))
      vx(i, j) = 1.0d-3
      vy(i, j) = 1.0d-3
    end do
  end do

  ! ── Time-step loop ───────────────────────────────────────────────────
  !$acc data copy(vx, vy, sigma_xx)
  do step = 1, nsteps
    call update_vx_gpu(vx, sigma_xx, dx, nx, ny)
    call update_sigma_gpu(sigma_xx, vx, vy, dx, dy, nx, ny)
  end do
  !$acc end data

  ! ── Probe points — written to stdout, parsed by pytest ──────────────
  ! Chosen so they exercise both interior + near-boundary cells.
  do j = 1, 8
    do i = 1, 8
      write(*, '(I0, " ", I0, " ", ES24.17)') &
        4 + 8 * (i - 1), 4 + 8 * (j - 1), &
        sigma_xx(4 + 8 * (i - 1), 4 + 8 * (j - 1))
    end do
  end do

end program wave_driver
