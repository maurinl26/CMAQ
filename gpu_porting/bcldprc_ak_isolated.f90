MODULE bcldprc_ak_mod
  IMPLICIT NONE

  ! Paramètres locaux pour remplacer les dépendances
  INTEGER, PARAMETER :: metlay = 30, ncols_x = 100, nrows_x = 100
  REAL, PARAMETER :: stdtemp = 273.15, rdgas = 287.05, cpd = 1005.0, lv0 = 2.5e6
  REAL, PARAMETER :: mwwat = 18.015, mwair = 28.964
  REAL, PARAMETER :: mvoma = mwwat / mwair  ! 0.622015

  ! Tableaux locaux (simplifiés pour le portage)
  REAL :: xtempm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xpresm(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xwvapor(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xdx3htf(ncols_x, nrows_x, metlay) = 0.0
  REAL :: x3htf(ncols_x, nrows_x, metlay) = 0.0
  REAL :: xpbl(ncols_x, nrows_x) = 0.0
  REAL :: xwbar(ncols_x, nrows_x) = 0.0
  REAL :: xcldbot(ncols_x, nrows_x) = 0.0
  REAL :: xcldtop(ncols_x, nrows_x) = 0.0
  REAL :: xcfract(ncols_x, nrows_x) = 0.0

CONTAINS

  ! Fonctions externes (simplifiées)
  REAL FUNCTION e_aerk(t)
    REAL, INTENT(IN) :: t
    e_aerk = 611.2 * EXP(17.67 * (t - 273.15) / (t - 29.65))
  END FUNCTION e_aerk

  REAL FUNCTION qsat(es, p)
    REAL, INTENT(IN) :: es, p
    qsat = mvoma * es / (p - es)
  END FUNCTION qsat

  ! Routine principale (extraite de bcldprc_ak.f90)
  SUBROUTINE bcldprc_ak_gpu
    IMPLICIT NONE
    INTEGER :: c, r, k, kmx, kct, kbase, ktop, itr, iflag
    REAL :: cbase, ccmax, ccov(metlay), dp, dtdp, es, frac, pbar, pbase, plcl, qlcl, qs
    REAL :: qwat, qwsa, rh, rhc, sg1, sumz, tad, tbar, tbase, tlcl, twc, wl, wtbar, x1

    ! Initialisation
    xwbar = 0.0
    xcldbot = 0.0
    xcldtop = 0.0
    xcfract = 0.0

    !$acc data copy(xwbar, xcldbot, xcldtop, xcfract) &
    !$acc      copyin(xtempm, xpresm, xwvapor, xdx3htf, x3htf, xpbl)
    
    DO c = 1, ncols_x
      DO r = 1, nrows_x
        kmx = 1
        ccov = 0.0

        !$acc parallel loop seq
        DO k = 1, metlay
          es = e_aerk(xtempm(c,r,k) - stdtemp)
          qs = qsat(es, xpresm(c,r,k))
          rh = xwvapor(c,r,k) / qs
          rh = MIN(rh, 1.0)

          IF (x3htf(c,r,k-1) < xpbl(c,r)) THEN
            rhc = 0.98
            kmx = k
            IF (rh > rhc) THEN
              ccov(k) = 0.34 * (rh - rhc) / (1.0 - rhc)
            ELSE
              ccov(k) = 0.0
            ENDIF
          ELSE
            sg1 = xpresm(c,r,k) / xpresm(c,r,kmx)
            rhc = 1.0 - (2.0 * sg1 * (1.0 - sg1) * (1.0 + 1.732 * (sg1 - 0.5)))
            IF (rh > rhc) THEN
              ccov(k) = ((rh - rhc) / (1.0 - rhc))**2
            ELSE
              ccov(k) = 0.0
            ENDIF
          ENDIF
          ccov(k) = MAX(MIN(ccov(k), 1.0), 0.0)
        ENDDO
        !$acc end parallel

        ! Déterminer le sommet et la base du nuage
        kct = 0
        kbase = 0
        ktop = 0
        ccmax = 0.0

        DO k = 2, metlay-1
          IF (ccov(k) > ccmax) THEN
            ccmax = ccov(k)
            kct = k
          ENDIF
        ENDDO

        frac = 0.0
        cbase = 0.0
        ctop = 0.0
        wtbar = 0.0
        sumz = 0.0

        IF (ccmax < 0.01) THEN
          xcldtop(c,r) = 0.0
          xcldbot(c,r) = 0.0
          CYCLE
        ENDIF

        ! Recherche du sommet et de la base
        top: DO k = kct, metlay
          ktop = k - 1
          IF (ccov(k) < 0.5 * ccmax) EXIT top
        ENDDO top

        bottom: DO k = kct, 1, -1
          kbase = k + 1
          IF (ccov(k) < 0.5 * ccmax) EXIT bottom
        ENDDO bottom

        DO k = 1, ktop
          IF (k < kbase) cbase = cbase + xdx3htf(c,r,k)
          ctop = ctop + xdx3htf(c,r,k)
        ENDDO

        xcldtop(c,r) = ctop
        xcldbot(c,r) = cbase

        ! Calcul de l'eau liquide
        plcl = xpresm(c,r,kbase-1)
        tlcl = (plcl - xpresm(c,r,kbase)) / (xpresm(c,r,kbase-1) - xpresm(c,r,kbase)) * &
               (xtempm(c,r,kbase-1) - xtempm(c,r,kbase)) + xtempm(c,r,kbase)
        es = e_aerk(tlcl - stdtemp)
        qlcl = qsat(es, plcl)

        iflag = 0
        pbase = plcl
        tbase = tlcl

        !$acc parallel loop seq
        DO k = kbase, ktop
          dp = pbase - xpresm(c,r,k)
          pbar = pbase - dp / 2.0
          tbar = tbase

          DO itr = 1, 5
            es = e_aerk(tbar - stdtemp)
            qs = qsat(es, pbar)
            x1 = lv0 * qs / (rdgas * tbar)
            dtdp = rdgas * tbar / pbar / cpd * ((1.0 + x1) / (1.0 + mvoma * lv0 / cpd / tbar * x1))
            tad = tbase - dp * dtdp
            tbar = (tad + tbase) * 0.5
          ENDDO

          tad = MAX(tad, 150.0)
          IF (tad > xtempm(c,r,k)) iflag = 1

          wl = 0.7 * EXP((xpresm(c,r,k) - plcl) / 8000.0) + 0.2
          es = e_aerk(tad - stdtemp)
          qwsa = qsat(es, xpresm(c,r,k))
          qwat = wl * (qlcl - qwsa)
          qwat = MAX(qwat, 0.0)

          twc = qwat * xpresm(c,r,k) * 1.0e3 / rdgas / xtempm(c,r,k)
          wtbar = wtbar + twc * xdx3htf(c,r,k)
          frac = frac + ccov(k) * xdx3htf(c,r,k)
          sumz = sumz + xdx3htf(c,r,k)
          tbase = tad
          pbase = xpresm(c,r,k)
        ENDDO
        !$acc end parallel

        xcfract(c,r) = frac / sumz
        xwbar(c,r) = wtbar / sumz

        IF (xcfract(c,r) < 0.001) THEN
          xcldtop(c,r) = 0.0
          xcldbot(c,r) = 0.0
        ENDIF

        IF (xwbar(c,r) == 0.0) THEN
          xcldtop(c,r) = 0.0
          xcldbot(c,r) = 0.0
          xcfract(c,r) = 0.0
        ENDIF

        IF (iflag == 0) THEN
          wtbar = 0.0
          DO k = kbase, ktop
            twc = 0.05e3 * xwvapor(c,r,k) * xpresm(c,r,k) / rdgas / xtempm(c,r,k)
            wtbar = wtbar + twc * xdx3htf(c,r,k)
          ENDDO
          xwbar(c,r) = wtbar / sumz
        ENDIF
      ENDDO
    ENDDO
    !$acc end data
  END SUBROUTINE bcldprc_ak_gpu

END MODULE bcldprc_ak_mod