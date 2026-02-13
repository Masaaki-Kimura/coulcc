program test_coulcc
  use iso_fortran_env, only: real64
  use mod_coulcc, only: coulcc
  implicit none

  type(coulcc) :: cc

  ! character for function name
  character(len=33), parameter :: func_name(0:3) = [ &
     'Coulomb                          ', &
     'spherical Bessel function (j & y)', &
     'Bessel function (J & Y)          ', &
     'modified Bessel function (I & K) ' ]
  ! parameter for COULCC
  integer, parameter :: nl = 1     ! number of ranks to compute
  ! parameter for x grid
  real(real64), parameter :: xmin = 0.00_real64    ! minimum x value
  real(real64), parameter :: xmax = 5.00_real64    ! maximum x value
  integer, parameter  :: npts = 21                 ! number of points
  real(real64), parameter :: xstep = (xmax - xmin)/(npts-1) ! step size

  ! local variables
  integer :: kfn, i, iell
  real(real64) :: ell, eta, theta, x
  complex(real64) :: xx
  complex(real64) :: fc(nl), gc(nl), fcp(nl), gcp(nl), sig(nl)
  character(len=256) :: arg
    
  if(command_argument_count() /= 4) then
    write(*,*) "Usage: ./test_coulcc kfn ell eta theta"
    write(*,*) " kfn: 1=spherical Bessel jn, yn"
    write(*,*) "      2=Bessel Jv, Yv"
    write(*,*) "      3=modified Bessel Iv, Kv"
    write(*,*) "   0,-1=Coulomb functions F,G"
    write(*,*) "ell: orbital angular momentum (real64, >=0)"
    write(*,*) "eta: Sommerfeld parameter"
    write(*,*) "theta: phase of complex factor exp(i*theta) multiplied to x"
    stop
  end if


  call get_command_argument(1, arg); if (len_trim(arg)==0) stop "Missing kfn"
  read(arg,*) kfn
  if(kfn < 0 .or. kfn > 3) stop "kfn must be 0,1,2, or 3"
  call get_command_argument(2, arg); if (len_trim(arg)==0) stop "Missing ell"
  read(arg,*) ell;   iell = int(ell)
  if (ell < 0) stop "ell must be >= 0"
  call get_command_argument(3, arg); if (len_trim(arg)==0) stop "Missing eta"
  read(arg,*) eta
  call get_command_argument(4, arg); if (len_trim(arg)==0) stop "Missing theta"
  read(arg,*) theta
  

  ! --- Main loop ---
  write(*,'(A,I0,A)') "# kfn= ", kfn, " : "//trim(adjustl(func_name(kfn)))
  write(*,'(a,f6.2,a,I0)') "# ell= ",ell, ", iell= ", iell
  write(*,'(a,f6.2)') "# eta= ", eta
  write(*,'(a,f6.2)') "# theta= ", theta
  write(*,'(A)') "#  x        Re(xx)   Im(xx)  FC(x)           GC(x)           " &
            //"Re(FC(xx))      Im(FC(xx))      Re(GC(xx))      Im(GC(xx))"

  do i = 1, npts
    x  = xmin + (i-1)*xstep
    xx = exp(cmplx(0.0_real64, theta, real64)) * x

    if(kfn == 1) then    ! test of spherical_jn & spherical_yn (kfn = 1)
      write(*,'(3f9.4, 6es16.8, 4f6.2)') &
        x, real(xx), aimag(xx), cc%spherical_jn(iell, x), cc%spherical_yn(iell, x), &
        real(cc%spherical_jn(iell,xx)), aimag(cc%spherical_jn(iell,xx)), &
        real(cc%spherical_yn(iell,xx)), aimag(cc%spherical_yn(iell,xx)), &
        real(cc%spherical_jn(iell,xx)) - real(cc%spherical_jne(iell,xx))*exp(abs(aimag(xx))), &
        aimag(cc%spherical_jn(iell,xx)) - aimag(cc%spherical_jne(iell,xx))*exp(abs(aimag(xx))), &
        real(cc%spherical_yn(iell,xx)) - real(cc%spherical_yne(iell,xx))*exp(abs(aimag(xx))), &
        aimag(cc%spherical_yn(iell,xx)) - aimag(cc%spherical_yne(iell,xx))*exp(abs(aimag(xx)))
    end if

    if(kfn == 2) then  ! test of jv & yv (kfn = 2)
      write(*,'(3f9.4, 6es16.8, 4f6.2)') &
          x, real(xx), aimag(xx), cc%jv(ell, x), cc%yv(ell, x), &
          real(cc%jv(ell,xx)), aimag(cc%jv(ell,xx)), &
          real(cc%yv(ell,xx)), aimag(cc%yv(ell,xx)), &
          real(cc%jv(ell,xx)) - real(cc%jve(ell,xx))*exp(abs(aimag(xx))), &
          aimag(cc%jv(ell,xx)) - aimag(cc%jve(ell,xx))*exp(abs(aimag(xx))), &
          real(cc%yv(ell,xx)) - real(cc%yve(ell,xx))*exp(abs(aimag(xx))), &
          aimag(cc%yv(ell,xx)) - aimag(cc%yve(ell,xx))*exp(abs(aimag(xx)))
    end if

    if(kfn == 3) then ! test of iv & kv (kfn = 3)
      write(*,'(3f9.4, 6es16.8, 4f6.2)') &
          x, real(xx), aimag(xx), cc%iv(ell, x), cc%kv(ell, x), &
          real(cc%iv(ell,xx)), aimag(cc%iv(ell,xx)), &
          real(cc%kv(ell,xx)), aimag(cc%kv(ell,xx)), &
          real(cc%iv(ell,xx)) - real(cc%ive(ell,xx))*exp(abs(dble(xx))), &
          aimag(cc%iv(ell,xx)) - aimag(cc%ive(ell,xx))*exp(abs(dble(xx))), &
          real(cc%kv(ell,xx)) - real(cc%kve(ell,xx))*exp(-dble(xx)), &
          aimag(cc%kv(ell,xx)) - aimag(cc%kve(ell,xx))*exp(-dble(xx))
    end if

    if(kfn == 0) then ! test of Coulomb functions F & G (kfn = 0)
      write(*,'(3f9.4, 6es16.8, 4f6.2)') &
          x, real(xx), aimag(xx), cc%coulombf(iell, eta, x), cc%coulombg(iell, eta, x), &
          real(cc%coulombf(iell, eta,xx)), aimag(cc%coulombf(iell, eta,xx)), &
          real(cc%coulombg(iell, eta,xx)), aimag(cc%coulombg(iell, eta,xx)), &
          real(cc%coulombf(iell, eta,xx)) - real(cc%coulombfe(iell, eta,xx))*exp(abs(aimag(xx))), &
          aimag(cc%coulombf(iell, eta,xx)) -aimag(cc%coulombfe(iell, eta,xx))*exp(abs(aimag(xx))), &
          real(cc%coulombg(iell, eta,xx)) - real(cc%coulombge(iell, eta,xx))*exp(abs(aimag(xx))), &
          aimag(cc%coulombg(iell, eta,xx)) - aimag(cc%coulombge(iell, eta,xx))*exp(abs(aimag(xx)))

    end if

  end do

end program test_coulcc
