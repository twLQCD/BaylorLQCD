! THIS IS SBR.FOO

!----------------Changes made to the module-----------------------
! July 5th, 2007 changes made by Abdou to include the 4 componetnts
! of the point split axial current in the loop calculations.
!
! In twAverage:
! -



 
! NOTE to Dean~ I need to make sure that each mudelta in 
!               cfgspropsmain.f90 is what I expect and then 
!               check that the looping I have allready put in
!               works (2/4/05)


!***********************************************************************
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
! File SING (Version of Sept, 2002)
!   Quark propagator computation using the conjugate-gradient algorithm
!     on an odd-even checkerboard.
!   Although the inversion is done for an incomplete axial gauge,
!     the quark propagators are transformed back to the original gauge.
!   The source can be smeared.
!   Pion smeared (sst=100) and unsmeared (sst=200) zero-momentum
!     sources also implemented. That's the reason for this new version.
!   This is the chemical potential version on the UY. Came
!     from nsmear2.f.
!   This came from CHEMUY. Is a little more efficient in time, memory.
!   This came from CHEMUY2.f in order to put in the Z(2) noise, put
!     in better conv. criterion (criter2) and print out values of
!     xlam8, xlam3.
!   This came from CHEMUY3.f in order to possibly
!     input 'xxxxxxxx' for 'oldgauge'. 
!   Keh-Fei Z(2) method (one column).
!   Changes done to run on sif.
!   More changes made to put in the measurement of operators.
!     These modifications coded by B. Lindsay, modified by WW.
!     This version for Z(2) sources. Note: The b and e smearing
!     algorithm here doesn't work. Also changed to read oldgauge
!     gauge configs.(vfile) if desired.
!   Made for Australia trip; puts in second order subtraction.
!   Made for Pisa trip; implements automated higher order subtractions.
!     This part does the subtraction**2 for use in milan2.f.
!   From milan1.f to go to 10th order in subtraction.
!   From rome2.f at NCSA in order to go to 20^3x32 lattices and to
!     put in momentum measurements.
!   From sing.f to test it for certain fake gauge field configs.
!
! ***
! In the following, all file names may be changed in a consistent manner
! ***
!
! 1) edit globally to choose values for parameters nx,ny,nz,nut,nt,nmin,
!      (where nx,ny,nz,nut,nt are even and nmin is the minimum of
!      {nx+1,ny+1,nz+1,nt}), and iterdim (where iterdim > itermax)
!      (parameters nd=4,nc=3,nri=2 are fixed).
! 2) compile with
!      "cft77 i=smear, b=bsmear, e=1"
! 3) load with
!      "ldr bin=bsmear, x=xsmear, lib=(fortlib,baselib,omnilib,mathlib)"
! __________________________
! | ufile='iamgauge'
! | sfile='iamsubtr'
! | xkappa=0.152
! | nois=10000
! |$end of namelist
! --------------------------

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************
!***********************************************************************
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
! This is the MAIN program.
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!


!     integer timeArray1(3), timeArray2(3)
       
!     call itime(timeArray1)     ! Get the current time

!     call itime(timeArray2)     ! Get the current time
!     print *, "Run time =", timeArray2(1)-timeArray1(1), "hours,",&
!      timeArray2(2)-timeArray1(2), "minutes,",&
!      timeArray2(3)-timeArray1(3), "seconds"

     module vevbleft   

     use commonkind
     use input1
     use input2
     use input5b
     use seed
     use sub
     use operator
     use gaugelinks

     implicit none 
     private

     include 'mpif.h'

! Define access to subroutines

     public :: twvev, twAverage, INPUT, UINIT, changevector,  &
               opwrite, printarray1, printarray2, printarray3,&
               printarray4,printarray5, printlog, changenoise,  &
               UINIT2, twAverage_axial

     private :: Subtract, Multiply, Calc1, ScalarCalc, currentCalc,&
                gammaCurrentCalc, GammaMultiply, writeops, check4entry, &
                vv,atoc, currentCalc2, gather, gamma5vector,currentCalc2_axial, &
                GammaMultiplyP, GammaMultiplyM,gammaCurrentCalcP,gammaCurrentCalcM,&
                currentCalc2P,currentCalc2M,currentCalc2_axialP,currentCalc2_axialM

     contains

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************
!***********************************************************************
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
      Subroutine INPUT(delta,MRT,myid)
!
! This subroutine reads in input parameters from namelist,
!   and does some consistency checks on them.
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
!

     use commonkind
!    use input1
     use input2
     use input5a
     use input5b
     use seed

 
     real(kind=KR),    intent(in)              :: delta
     integer(kind=KI), intent(in)              :: myid,MRT
     integer(kind=KI)                          :: nois,ierr

!
!   print *, "myid=", myid

     if (myid==0) then
       write(6,*) "(Perturbative Subtraction for Discon loops, Version of December 2004 )"
!
     read(5,9187) sfile
!     read(5,9188) xkappa
!     read(5,9189) fixbc
      read(5,9190) nois
      read(5,9200) iseed(1)
      read(5,9200) iseed(2)
      read(5,9200) iseed(3)
      read(5,9200) iseed(4)
! echo
      write(6,9187) sfile
!     write(6,9188) xkappa
!     write(6,9189) fixbc
      write(6,9190) nois
      write(6,9200) iseed(1)
      write(6,9200) iseed(2)
      write(6,9200) iseed(3)
      write(6,9200) iseed(4)
    endif ! myid

!   call MPI_BCAST(xkappa,1,MRT,0,MPI_COMM_WORLD,ierr)
!   call MPI_BCAST(fixbc,1,MPI_LOGICAL,0,MPI_COMM_WORLD,ierr) 
 
!     delta=0.5_KR
!     cosd=cos(delta)
!     sind=sin(delta)
!     xkappa=xkappa*cosd
!
!     if (myid==0) then
!       print *, "xkappa =", xkappa
!     endif
     

 9187 format(a8)
 9188 format(f5.3)
 9189 format(l5)
 9190 format(i6)
 9200 format(i8)
!
!
      RETURN
      END Subroutine INPUT
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************
!***********************************************************************
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx

      Subroutine UINIT(usp,uss,fixbc,rwdir,myid)
!
      ! use input1
      use input5a
!     use gaugelinks

      real(kind=KR),    intent(inout), dimension(nxyzt,nri,nc,nc)   :: usp
      real(kind=KR),    intent(inout), dimension(nxyzt,3,nri,nc,nc) :: uss
      character(len=*), intent(in),    dimension(:)                 :: rwdir
      integer(kind=KI), intent(in)                                  :: myid                 
      logical,          intent(in)                                  :: fixbc

      integer, parameter                                            :: nxyzut=8*nxyz
      integer(kind=KI)                                              :: jd,jc1,jc2,jri,&
                                                                       ix,iy,iz,it,inor,&
                                                                       iex,iey,iez,jjkkll,&
                                                                       io8 ,iwalt
      integer(kind=KI)                                              :: rank,bufsizes(1),ierr,&
                                                                       uspcount,usscount
      real(kind=KR)                                                 :: twopi,tx
      real(kind=KR),dimension(nxyzt)                                :: u
      real(kind=KR),dimension(nxyzut)                               :: ut
      logical                                                       :: true,false
      complex(kind=KR)  :: dphase,cphase

! Do the gaugelinks for 0-process and then Bcast them to "everyone" else


!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
!
! *** LINK ****
      twopi=8.0_KR*atan(1.0_KR)
      tx=4.0_KR
      uss=0.0_KR
      usp=0.0_KR

      do jc2=1,nc
        do jc1=1,nc
           inor=0

           do it=1,nt
              do iz=1,nz
                 do iy=1,ny
                    do ix=1,nx
                       inor = inor + 1

                       if (jc1 /= jc2) then
                       !  uss(inor, 1, 1, jc1, jc2) = real((jc1-jc2)/twopi,KR)
                       !  uss(inor, 1, 1, jc1, jc2) = 1.0_KR
                          uss(inor, 1, 2, jc1, jc2) = 0.0_KR

                       !  uss(inor, 2, 1, jc1, jc2) = real((jc1-jc2)/twopi,KR)
                       !  uss(inor, 2, 1, jc1, jc2) = 1.0_KR
                          uss(inor, 2, 2, jc1, jc2) = 0.0_KR

                       !  uss(inor, 3, 1, jc1, jc2) = real((jc1-jc2)/twopi,KR)
                       !  uss(inor, 3, 1, jc1, jc2) = 1.0_KR
                          uss(inor, 3, 2, jc1, jc2) = 0.0_KR

                       !  usp(inor, 1, jc1, jc2) = 1.0_KR
                          usp(inor, 2, jc1, jc2) = 0.0_KR
                       else
                          uss(inor, 1, 1, jc1, jc2)=cos((twopi*((it+ix+iy+iz)**1.5))/tx)
                          uss(inor, 1, 2, jc1, jc2)=sin((twopi*(it+ix+iy+iz)**1.5)/tx)

                          uss(inor, 2, 1, jc1, jc2)=cos((twopi*(it+ix+iy+iz)**1.5)/tx)
                          uss(inor, 2, 2, jc1, jc2)=sin((twopi*(it+ix+iy+iz)**1.5)/tx)

                          uss(inor, 3, 1, jc1, jc2)=cos((twopi*(it+ix+iy+iz)**1.5)/tx)
                          uss(inor, 3, 2, jc1, jc2)=sin((twopi*(it+ix+iy+iz)**1.5)/tx)
 
                          usp(inor, 1, jc1, jc2) = 1.0_KR
                          usp(inor, 2, jc1, jc2) = 0.0_KR
                       endif

                    enddo ! ix
                 enddo ! iy
              enddo ! iz
           enddo ! it

        enddo ! jc1
      enddo ! jc2
     
      call printlog("CHANGE u's BACK", myid, rwdir)

      END Subroutine UINIT
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx

      Subroutine UINIT2(usp,uss,fixbc,myid)
!
!     use input1
      use input5a
!     use gaugelinks

      real(kind=KR), intent(inout), dimension(:,:,:,:)       :: usp
      real(kind=KR), intent(inout), dimension(:,:,:,:,:)     :: uss
!      real(kind=KR), intent(inout), dimension(nxyzt,nri,nc,nc)       :: usp
!      real(kind=KR), intent(inout), dimension(nxyzt,3,nri,nc,nc)     :: uss
      integer(kind=KI), intent(in)                                 :: myid                 
     logical,       intent(in)                                    :: fixbc

      integer, parameter                                           :: nxyzut=8*nxyz
      integer(kind=KI)                                             :: jd,jc1,jc2,jri,&
								      ix,iy,iz,it,inor,&
								      iex,iey,iez,jjkkll,&
								      io8 ,iwalt
      integer(kind=KI)                                             :: rank,bufsizes(1),ierr,&
                                                                      uspcount,usscount
      real(kind=KR)                                                :: twopi,tx
      real(kind=KR),dimension(nxyzt)                               :: u
      real(kind=KR),dimension(nxyzut)                              :: ut
      logical                                                      :: true,false

! Do the gaugelinks for 0-process and then Bcast them to "everyone" else


!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
	io8=-1
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
! x_direction
      jd=1
!
! input u
      rank=1
      bufsizes(1)=nxyzut
	twopi=8.*atan(1.)
!	tt=float(nt)
	tx=4.
      DO jc2=1,nc
	DO jc1=1,nc
		  DO jri=1,nri
!           io8=io8+1
!           CALL RDABS(8,u,nxyzut,nxyzut*io8)
!           CALL IOCHECK(8)
!           call getwa(ufile,u,nxyzut*io8+1,nxyzut)
!           ret=dsgdata(ufile,rank,bufsizes,ut)
!           if(ret.eq.-1) then
!	    write(6,44) ufile,rank,bufsizes(1)
!	    write(6,45) jri,jc1,jc2
!44	    format(a8/i8/i8)
!45	    format(//3i8)
!	    stop 1
!	    endif
!
	    inor=0
	    IF(jc1.ne.jc2) THEN
	      DO it=1,nt
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=0.
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
!
	    ELSE
!
	    if(jri.eq.1) then
	      DO it=1,nt
!	xt=float(it)
!       xxx=cos((twopi*xt)/tt)
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=cos((twopi*(it+ix+iy+iz)**1.5)/tx)
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
	    else
	      DO it=1,nt
!	xt=float(it)
!       xxx=sin((twopi*xt)/tt)
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=sin((twopi*(it+ix+iy+iz)**1.5)/tx)
		    ENDDO
		  ENDDO
		ENDDO 
	      ENDDO
	    endif
	  ENDIF
!
! fill reordered array for time 2 to 31
!         inor=0
!         DO 5 jut=1,nut
!         DO 5 jz=1,nz
!         DO 5 jy=1,ny
!         DO 5 jx=1,nx
!         inor=inor+1
!         iper=inor+nxyz
!         u(iper)=ut(inor)
!   5     CONTINUE
! fill reordered array at time 1 with link at 30 and at time 32 with 1.
!         inor=0
!         DO 501 jz=1,nz
!         DO 501 jy=1,ny
!         DO 501 jx=1,nx
!         inor=inor+1
!         iper=inor+(nut-1)*nxyz
!         u(inor)=ut(iper)
!         iper=inor+(nt-1)*nxyz
!         u(iper)=ut(inor)
! 501     CONTINUE
!
       do jjkkll=1,nxyzt
	 uss(jjkkll,1,jri,jc1,jc2)=u(jjkkll)
       enddo ! jjkkll
!
!       DO 171 jt=1,nut
!         IF(nt.gt.nut.and.(nut+jt).le.nt) THEN
!           DO 17 jxyz=1,nxyz
!             u(jxyz+nxyz*(nut+jt-1))=u(jxyz+nxyz*(jt-1))
!17         CONTINUE
!         ENDIF
!171    CONTINUE
!
	  enddo ! jri
	enddo ! jc1
      enddo ! jc2
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
! y_direction
      jd=2
!
      DO jc2=1,nc
	DO jc1=1,nc
	  DO jri=1,nri
!       io8=io8+1
!       CALL RDABS(8,u,nxyzut,nxyzut*io8)
!       CALL IOCHECK(8)
!       call getwa(ufile,u,nxyzut*io8+1,nxyzut)
!       ret=dsgdata(ufile,rank,bufsizes,ut)
!       if(ret.eq.-1) stop 2
!
	    inor=0
	    IF(jc1.ne.jc2) THEN
	      DO it=1,nt
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=0.
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
!
	    ELSE
!
	   if(jri.eq.1) then
	     DO it=1,nt
!       xt=float(it)
!       xxx=cos((twopi*xt)/tt)
	       DO iz=1,nz
		 DO iy=1,ny
		   DO ix=1,nx
		     inor=inor+1
		     u(inor)=cos((twopi*(it+ix+iy+iz)**1.5)/tx)
		   ENDDO
		 ENDDO
	       ENDDO
	     ENDDO
	   else
	     DO it=1,nt
!       xt=float(it)
!       xxx=sin((twopi*xt)/tt)
	       DO iz=1,nz
		 DO iy=1,ny
		   DO ix=1,nx
		     inor=inor+1
		     u(inor)=sin((twopi*(it+ix+iy+iz)**1.5)/tx)
		   ENDDO
		 ENDDO
	       ENDDO
	     ENDDO
	   endif
	 ENDIF
!
! fill reordered array for time 2 to 31
!         inor=0
!         DO 6 jut=1,nut
!         DO 6 jz=1,nz
!         DO 6 jy=1,ny
!         DO 6 jx=1,nx
!         inor=inor+1
!         iper=inor+nxyz
!         u(iper)=ut(inor)
!   6     CONTINUE
! fill reordered array at time 1 with link at 30 and at time 32 with 1.
!         inor=0
!         DO 601 jz=1,nz
!         DO 601 jy=1,ny
!         DO 601 jx=1,nx
!         inor=inor+1
!         iper=inor+(nut-1)*nxyz
!         u(inor)=ut(iper)
!         iper=inor+(nt-1)*nxyz
!         u(iper)=ut(inor)
! 601     CONTINUE
!
       do jjkkll=1,nxyzt
	 uss(jjkkll,2,jri,jc1,jc2)=u(jjkkll)
       enddo! jjkkll
!
!       DO 271 jt=1,nut
!         IF(nt.gt.nut.and.(nut+jt).le.nt) THEN
!           DO 27 jxyz=1,nxyz
!             u(jxyz+nxyz*(nut+jt-1))=u(jxyz+nxyz*(jt-1))
!27         CONTINUE
!         ENDIF
!271    CONTINUE
!
	  enddo ! jri
	enddo ! jc1
      enddo ! jc2
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
! z_direction
      jd=3
!
      DO jc2=1,nc
	DO jc1=1,nc
	  DO jri=1,nri
!       io8=io8+1
!       CALL RDABS(8,u,nxyzut,nxyzut*io8)
!       CALL IOCHECK(8)
!       call getwa(ufile,u,nxyzut*io8+1,nxyzut)
!       ret=dsgdata(ufile,rank,bufsizes,ut)
!       if(ret.eq.-1) stop 3
!
	    inor=0
	    IF(jc1.ne.jc2) THEN
	      DO it=1,nt
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=0.
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
!
	    ELSE
!
	    if(jri.eq.1) then
	      DO it=1,nt
!       xt=float(it)
!       xxx=cos((twopi*xt)/tt)
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=cos((twopi*(it+ix+iy+iz)**1.5)/tx)
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
	    else
	      DO it=1,nt
!       xt=float(it)
!       xxx=sin((twopi*xt)/tt)
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=sin((twopi*(it+ix+iy+iz)**1.5)/tx)
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
	    endif
	  ENDIF
!
! fill reordered array for time 2 to 31
!         inor=0
!         DO 7 jut=1,nut
!         DO 7 jz=1,nz
!         DO 7 jy=1,ny
!         DO 7 jx=1,nx
!         inor=inor+1
!         iper=inor+nxyz
!         u(iper)=ut(inor)
!   7     CONTINUE
! fill reordered array at time 1 with link at 30 and at time 32 with 1.
!         inor=0
!         DO 701 jz=1,nz
!         DO 701 jy=1,ny
!         DO 701 jx=1,nx
!         inor=inor+1
!         iper=inor+(nut-1)*nxyz
!         u(inor)=ut(iper)
!         iper=inor+(nt-1)*nxyz
!         u(iper)=ut(inor)
! 701     CONTINUE
!
       do jjkkll=1,nxyzt
	 uss(jjkkll,3,jri,jc1,jc2)=u(jjkkll)
       enddo ! jjkkll
!
!       DO 371 jt=1,nut
!         IF(nt.gt.nut.and.(nut+jt).le.nt) THEN
!           DO 37 jxyz=1,nxyz
!             u(jxyz+nxyz*(nut+jt-1))=u(jxyz+nxyz*(jt-1))
!37         CONTINUE
!         ENDIF
!371    CONTINUE
!
	    enddo ! jri
	  enddo ! jc1
	enddo ! jc2
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
! t_direction
      jd=4
!
      DO jc2=1,nc
	DO jc1=1,nc
	  DO jri=1,nri
!       io8=io8+1
!       CALL RDABS(8,u,nxyzut,nxyzut*io8)
!       CALL IOCHECK(8)
!       call getwa(ufile,u,nxyzut*io8+1,nxyzut)
!       ret=dsgdata(ufile,rank,bufsizes,ut)
!       if(ret.eq.-1) stop 4
!
	    inor=0
	    IF(jc1.ne.jc2) THEN
	      DO it=1,nt
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=0.
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
!
	    ELSE
!
	    if(jri.eq.1) then
	      DO it=1,nt
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=1.
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
	    else
	      DO it=1,nt
		DO iz=1,nz
		  DO iy=1,ny
		    DO ix=1,nx
		      inor=inor+1
		      u(inor)=0.
		    ENDDO
		  ENDDO
		ENDDO
	      ENDDO
	    endif
	  ENDIF
!
! fill reordered array for time 2 to 31
!         inor=0
!         DO 8 jut=1,nut
!         DO 8 jz=1,nz
!         DO 8 jy=1,ny
!         DO 8 jx=1,nx
!         inor=inor+1
!         iper=inor+nxyz
!         u(iper)=ut(inor)
!   8     CONTINUE
! fill reordered array at time 1 with link at 30 and at time 32 with 1.
!         inor=0
!         DO 801 jz=1,nz
!         DO 801 jy=1,ny
!         DO 801 jx=1,nx
!         inor=inor+1
!         iper=inor+(nut-1)*nxyz
!         u(inor)=ut(iper)
!         iper=inor+(nt-1)*nxyz
!         u(iper)=ut(inor)
! 801     CONTINUE
!
       do jjkkll=1,nxyzt
         usp(jjkkll,jri,jc1,jc2)=u(jjkkll)
       enddo ! jjkkll 
!
!       DO 471 jt=1,nut
!         IF(nt.gt.nut.and.(nut+jt).le.nt) THEN
!           DO 47 jxyz=1,nxyz
!             u(jxyz+nxyz*(nut+jt-1))=u(jxyz+nxyz*(jt-1))
!47         CONTINUE
!         ENDIF
!471    CONTINUE
!
! Put in time BC's.
!
      if (fixbc.eqv.(.false.)) then
!     if (.not.fixbc) then
      do iez=1,nz
        do iey=1,ny
          do iex=1,nx
            iwalt=iex+(iey-1)*nx+(iez-1)*nx*ny+(nt-1)*nxyz
            usp(iwalt,jri,jc1,jc2)=-usp(iwalt,jri,jc1,jc2)
          enddo ! iex
        enddo ! iey
      enddo ! iez
      else if (fixbc.eqv.(.true.)) then
!     else if (fixbc) then
      do iez=1,nz
        do iey=1,ny
          do iex=1,nx
            iwalt=iex+(iey-1)*nx+(iez-1)*nx*ny+(nt-1)*nxyz
            usp(iwalt,jri,jc1,jc2)=0.
          enddo ! iex
        enddo ! iey
      enddo ! iez
      endif
!
            enddo ! jri
          enddo ! jc1
        enddo ! jc2
!

     

      END Subroutine UINIT2
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************
!.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
!
      Subroutine twvev(Jvev,delta,io,kappa,upart,dobndry,numprocs,&
                        MRT,rwdir,myid,nsub,nmom,nop,shiftnum,ntmqcd,ir)
!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
  !use input1
   use input2
   use input5b
   use seed
!  use sub
   use operator
!  use gaugelinks

   integer(kind=KI), intent(in)                                            :: nsub,nmom,nop 

   real(kind=KR),    intent(out),    dimension(2,nt,6,nmom,nop)            :: Jvev 
   real(kind=KR),    intent(in),     dimension(18,ntotal,4,2,16)           :: upart
   integer(kind=KI), intent(in),     dimension(3)                          :: io
   real(kind=KR),    intent(in)                                            :: kappa
   real(kind=KR),    intent(in)                                            :: delta 
   integer(kind=KI), intent(in)                                            :: dobndry
   integer(kind=KI), intent(in)                                            :: numprocs, myid, ir
   integer(kind=KI), intent(in)                                            :: shiftnum
   integer(kind=KI), intent(in)                                            :: MRT
   integer(kind=KI), intent(in)                                            :: ntmqcd
   character(len=*), intent(in),     dimension(:)                          :: rwdir

!   real(kind=KR),                    dimension(18,ntotal,4,2,16)           :: utemp
   real(kind=KR),allocatable,        dimension(:,:,:,:,:)           :: utemp
   real(kind=KR)                                                           :: xkappa
   integer(kind=KI),                 dimension(1)                          :: bufsizes
   integer(kind=KI)                                                        :: rank
   integer(kind=KI),                 dimension(9)                          :: imv
   integer(kind=KI)                                                        :: kc,kd
   real(kind=KR),                    dimension(2,nt,6,nmom,nop)         :: Jvevtemp
   real(kind=KR),                    dimension(0:3)                        :: xrr2,xri2,xps2,&
                                                                              xpi2,xsj1pr,xsj1pi,&
                                                                              xsj2pr,xsj2pi,xsj3pr,&
                                                                              xsj3pi,xpsur,xpsui
   real(kind=KR),                    dimension(0:3)                   :: xrr2temp,xri2temp,xps2temp,&
                                                                         xpi2temp,xsj1prtemp,xsj1pitemp,&
                                                                         xsj2prtemp,xsj2pitemp,xsj3prtemp,&
                                                                         xsj3pitemp,xpsurtemp,xpsuitemp
   real(kind=KR), allocatable,       dimension(:,:,:)                 :: z2i,z3i
!   real(kind=KR),       dimension(nxyzt,nc,nd)                 :: z2i,z3i
!  real(kind=KR),        dimension(nxyzt,nc,nd)                 :: z2i

   real(kind=KR),                    dimension(2)                     :: sbr,sbi
   real(kind=KR),                    dimension(nxyzt)                 :: s0,s1,pscalar
   real(kind=KR),                    dimension(nsav,0:3)              :: op,oa,oe   
   real(kind=KR),                    dimension(nsav,nt,5,0:1)         :: oper,oab,oeb,opertemp   
!   real(kind=KR),                    dimension(nxyzt,4)               :: ffac,fas1,fas2,fas3
   real(kind=KR), allocatable,       dimension(:,:)                   :: ffac,fas1,fas2,fas3
   real(kind=KR),                    dimension(6)                     :: xk
   real(kind=KR)                                                      :: pmom1,pmom2,pmom3
   real(kind=KR)                                                      :: dx,dy,dz
   real(kind=KR)                                                      :: xnl
!   character(len=8)                                                   :: sfile
   integer(kind=KI)                                                   :: itr,itimz,imom
   integer(kind=KI)                                                   :: ihere,leftx,rightx,lefty,righty,&
                                                                         leftz,rightz,leftt,rightt,&
                                                                         ahere,ax,ay,az,at,md,&
                                                                         bx,by,bz,bt,proc
   integer(kind=KI)                                                   :: isx,isy,isz
   integer(kind=KI)                                                   :: ixx,iyy,izz,ittt
   integer(kind=KI)                                                   :: tempx,tempy,tempz,temptplus,&
                                                                         temptminus 
   integer(kind=KI)                                                   :: isb,isp
   integer(kind=KI)                                                   :: im,imm,iop,ix,i
   integer(kind=KI)                                                   :: counter
   integer(kind=KI)                                                   :: idirac,icolor,jc,jd,jri,is,ii,ih
   integer(kind=KI)                                                   :: type
   logical                                                            :: fixbc
   logical                                                    :: true,false
   integer(kind=KI)                                                   :: iblock,ieo,j,&
                                                                         kc1,kc2,isite,ixyz,site,inps
   integer(kind=KI)                                                   :: ieo1,ieo2,itbit,itbit2,&
                                                                         ixbit,ixbit2,ixbit3,&
                                                                         iybit,iybit2,izbit,izbit2,&
                                                                         iblbit
   integer(kind=KI)                                                   :: ierr
   integer(kind=KI)                                                   :: opercount,Jvevcount,count
   integer(kind=KI),                 dimension(4)                     :: np,ip
   real(kind=KR), allocatable,       dimension(:,:,:,:,:)             :: uss !,usstemp
   real(kind=KR), allocatable,       dimension(:,:,:,:)               :: usp !,usptemp
!    real(kind=KR),        dimension(nxyzt,3,2,nc,nc)                   :: uss 
!    real(kind=KR),        dimension(nxyzt,2,nc,nc)                     :: usp 
   !real(kind=KR),                    dimension(9,ntotal,3,2,16)       :: rtempuss, itempuss
   !real(kind=KR),                    dimension(9,ntotal,1,2,16)       :: rtempusp, itempusp

   integer(kind=KI),                 dimension(4)                     :: cd, sign
   real(kind=KR) :: guy

   integer(kind=KI) :: ipos,icolor1,icolor2,ltime,utime,usub
   real(kind=KR), dimension(0:3) :: whatever,ever,ever2

   allocate(uss(nxyzt,3,2,nc,nc))
   allocate(usp(nxyzt,2,nc,nc))
   allocate(utemp(18,ntotal,4,2,16)) 



   counter = 0
!     Random noise vectors are not used in this exact calculation.

! These subroutines are in directory ./qqcd/cfgsprops/quark/common. They 
! allocate memory for the unit vector z2 and the subtraction level
! arrays.


    if (myid==0) then
     call printlog("Entering twvev", myid, rwdir)
    endif 

     call allocatesubs
     call allocatez2
!    call allocateus 


! Variables that don't occur often are allocated/deallocated locally.

! NOTE~ some of the variables are not dealloacted. This is to save time
!       in the overall program runtime. Variables that are going to be needed
!       many times are left in the heap and are not deallocated and then  
!       realloacted (you may see this structure in the above subroutines).

     allocate(ffac(nxyzt,4))
     allocate(fas1(nxyzt,4))
     allocate(fas2(nxyzt,4))
     allocate(fas3(nxyzt,4))

!    allocate(uss(nxyzt,3,nri,nc,nc))
!    allocate(usp(nxyzt,nri,nc,nc))

     allocate(z2i(nxyzt,nc,nd))
     allocate(z3i(nxyzt,nc,nd))

     if(myid==0) then     
      open(unit=8,file="TWVEV.LOG", action="write",form="formatted",status="old",position="append")
     endif
     !Abdou changed to
     !open(unit=8,file=trim(rwdir)//"TWVEV.LOG", action="write",form="formatted",status="old",position="append")

     ffac = 0.0_KR
     fas1 = 0.0_KR
     fas2 = 0.0_KR
     fas3 = 0.0_KR

     opertemp=0.0_KR
     xrr2=0.0_KR
     xri2=0.0_KR
     xps2=0.0_KR
     xpi2=0.0_KR
     xpsur=0.0_KR
     xpsui=0.0_KR
     xsj1pr=0.0_KR
     xsj1pi=0.0_KR
     xsj2pr=0.0_KR
     xsj2pi=0.0_KR
     xsj3pr=0.0_KR
     xsj3pi=0.0_KR
     xrr2temp=0.0_KR
     xri2temp=0.0_KR
     xps2temp=0.0_KR
     xpi2temp=0.0_KR
     xpsurtemp=0.0_KR
     xpsuitemp=0.0_KR
     xsj1prtemp=0.0_KR
     xsj1pitemp=0.0_KR
     xsj2prtemp=0.0_KR
     xsj2pitemp=0.0_KR
     xsj3prtemp=0.0_KR
     xsj3pitemp=0.0_KR

! Zero out the operators that are passed out to the discon-loop program
     Jvev = 0.0_KR
     Jvevtemp=0.0_KR

! Initializations for the gamma5 matrix multiplcation for the pseudo-scalar
     cd(1:4)   = (/ 3, 4, 1, 2 /)
     sign(1:4) = (/ 1, 1, -1, -1 /)

!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
	 
!     Determine boundry conditions depending on the value of dobndry

     if (dobndry==1) then
	 fixbc=.true.
     else
         fixbc=.false.
     endif ! dobndry

!     if (nps/=1) then
!         call MPI_BCAST(fixbc,8,MPI_LOGICAL,0,MPI_COMM_WORLD,ierr)
!     endif ! nps/=1

	      
!     Set up quantities needed for momentum analysis.
!     Need to define lowest momentum in each lattice direction for anisotropic lattice

     pmom1=8.0_KR*atan(1.0_KR)/nx
     pmom2=8.0_KR*atan(1.0_KR)/ny
     pmom3=8.0_KR*atan(1.0_KR)/nz
	  
     do itr=1,nt
	itimz=(itr-1)*nxyz
	do isz=1,nz
	   dz=dble(isz-io(3))*pmom3
	   do isy=1,ny
	      dy=dble(isy-io(2))*pmom2
	      do isx=1,nx
	         dx=dble(isx-io(1))*pmom1
	         isp=isx+(isy-1)*nx+(isz-1)*nx*ny+itimz
	 
	         ffac(isp,1)=(cos(dx)+cos(dy)+cos(dz))/3.0_KR
	         fas1(isp,1)=sin(dx)
	         fas2(isp,1)=sin(dy)
	         fas3(isp,1)=sin(dz)
	 
	         ffac(isp,2)=(cos(dx)*cos(dy)+cos(dx)*cos(dz)+cos(dy)*cos(dz))/3.0_KR
	         fas1(isp,2)=sin(dx)*(cos(dy)+cos(dz))/2.0_KR
	         fas2(isp,2)=sin(dy)*(cos(dx)+cos(dz))/2.0_KR
	         fas3(isp,2)=sin(dz)*(cos(dx)+cos(dy))/2.0_KR
	 
	         ffac(isp,3)=cos(dx)*cos(dy)*cos(dz)
	         fas1(isp,3)=sin(dx)*cos(dy)*cos(dz)
	         fas2(isp,3)=sin(dy)*cos(dx)*cos(dz)
	         fas3(isp,3)=sin(dz)*cos(dx)*cos(dy)
	 
	         ffac(isp,4)=(cos(2.0_KR*dx)+cos(2.0_KR*dy)+cos(2.0_KR*dz))/3.0_KR
	         fas1(isp,4)=sin(2.0_KR*dx)
	         fas2(isp,4)=sin(2.0_KR*dy)
	         fas3(isp,4)=sin(2.0_KR*dz)
	 
	      enddo ! isx  
	   enddo ! isy  
	enddo ! isz  
     enddo ! itr  
	 

     z2=0.0_KR
     z2i=0.0_KR
     z3=0.0_KR
     z3i=0.0_KR

     psir=0.0_KR
     psii=0.0_KR
     sb1r=0.0_KR
     sb1i=0.0_KR
     sb2r=0.0_KR
     sb2i=0.0_KR
     sb3r=0.0_KR
     sb3i=0.0_KR
     sb4r=0.0_KR
     sb4i=0.0_KR
     sb5r=0.0_KR
     sb5i=0.0_KR
     sb6r=0.0_KR
     sb6i=0.0_KR

     uss=0.0_KR
     usp=0.0_KR

!     Identify the location of my process
!     The main loop over all lattice sites and dirac and color indices

     call utouss(upart,uss,usp,numprocs,MRT,myid)

! NOTE~ The  subrouitne UINIT is used for debugging only. It allows specific creation
!       of simple gagauelinks. 


!    if (myid==0) then
!        call UINIT(usp,uss,fixbc,rwdir,myid)
!     endif
              

! Zero out time edge for process zero before BCAST to 
! MPI_COMM_WORLD.

!  call printlog("Took out usp=0 in VEV!!",myid,rwdir)
!  if (.false.) then
     if (fixbc) then
       if (myid==0) then
         do izz = 1,nz
            do iyy = 1,ny
               do ixx = 1,nx
                  ipos = ixx + nx*(iyy-1) + nx*ny*(izz-1) + nx*ny*nz*(nt-1)
                     do icolor1 = 1,nc
                        do icolor2 = 1,nc
                           usp(ipos,:,icolor1,icolor2)= 0.0_KR
                        enddo ! icolor2
                     enddo ! icolor1
               enddo ! ixx
            enddo ! iyy
         enddo ! izz
       endif ! myid
     endif ! fixbc
! endif ! .false.
	      
     if (nps/=1) then
         count=(nxyzt*3*nri*nc*nc)
	 call MPI_BCAST(uss(1,1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
	 count=(nxyzt*nri*nc*nc)
	 call MPI_BCAST(usp(1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
     endif ! nps


!     do is = 1,nshifts

! Define the rotation variables cosd, sind.

      cosd=cos(delta)
      sind=sin(delta)
  if (myid.eq.0) print *,'HERE IS DELTA',delta
      xkappa=kappa*cosd

      if(myid==0) then
        print *, "kappa,xkappa=", kappa,xkappa
        print *, "cosd,sind=", cosd,sind
       endif ! myid
! kappa values for subtration levels. 

! ABDOU ~ One way to do "multi-mass vev" is to add an index on kappa -> kappa(i)
!         and just pass in the array with all loop kappa values instead of looping
!         over masses (as I did, opps)

      xk(1)=xkappa
      xk(2)=xkappa**2
      xk(3)=xkappa**3 ! lowest order for currents
      xk(4)=xkappa**4 ! lowest order for scalar and pseudo-scalar
      xk(5)=xkappa**5 ! highest order for currents
      xk(6)=xkappa**6 ! highest order for scalar and pseudo-scalar 


! WARNING WARNING WARNING WARNING WARNING WARNING
! We have restricted the time steps in the perturbative
! construction of the vev's in order to save time 7-16-05.

       ltime=1
       utime=nt
       counter=0


!      do ittt=1,nt
       do ittt=ltime,utime
          do izz=1,nz
             do iyy=1,ny
               do ixx=1,nx
! Temporary replacement
!      do ittt=4,4
!         do izz=1,1
!            do iyy=1,1
!              do ixx=1,1

! Translate coordinates realtive to ihere to single array index

                   ihere=ixx+nx*(iyy-1)+nx*ny*(izz-1)+nx*ny*nz*(ittt-1)

                   if (mod(ihere-1,numprocs) == myid) then
 		       do idirac=1,nd
 			  do icolor=1,nc
! Temporary replacement
!                      do idirac=1,1
!                         do icolor=1,1
                          counter = counter + 1

!     The "z2" array is zero everywhere except at the current iteration
!     of the main loop.

!     Multipication of overall cos(delta) done at intilization of unit vector.
!     Setting up random noise vectors, not used in this exact calculation

                          z2(ihere,icolor,idirac) = 1.0_KR
                          z3(ihere,icolor,idirac) = cosd*z2(ihere,icolor,idirac)

! Dean - Multiply z2 here by (1 +- i gamma_5) (I think)
                          !call gamma5vector(z3,ihere,icolor,ntmqcd,myid)

! Dean - Have to change the following multiplications to take into
! account that z3 is no longer a point vector

! I am getting rid of the initial rotation at the beginning.
! It is correct to actually do it at the end with the present
! version of GammaMultiply. -WW

if(.false.) then
                             sbr(1) = z3(ihere,icolor,1)
                             sbr(2) = z3(ihere,icolor,2)
                             z3(ihere,icolor,1) = cosd*z3(ihere,icolor,1) - sind*z3(ihere,icolor,3)
                             z3(ihere,icolor,2) = cosd*z3(ihere,icolor,2) - sind*z3(ihere,icolor,4)
                             z3(ihere,icolor,3) = cosd*z3(ihere,icolor,3) + sind*sbr(1)
                             z3(ihere,icolor,4) = cosd*z3(ihere,icolor,4) + sind*sbr(2)
endif ! false

!                            if (myid==0) print "(i5,i3,4es17.10)", ihere, icolor, z3(ihere,icolor,:)
!                            if (counter > 1000) then
!                               call printlog("Just finshed the loops, STOPPING!",myid,rwdir)
!                               call MPI_BARRIER(MPI_COMM_WORLD,ierr)
!                               stop
!                            endif ! check


!     The "sb*" arrays are now reset to zero in a more efficient way
!     at the end of the main loop.

!     This section is to do the first order subtraction from
!     the quark propagator.
!
!     The "Multiply" subroutine generates the next subtraction level
!     from the last one.
!     At first order, "sb1r" and "sb1i" are generated from "z2" and "z2i".
!     "Multiply" actually computes the effect that one element of "z2" and
!     "z2i" has on "sb1r" and "sb1i".  Thus, "Multiply" must be called
!     once for every nonzero point of "z2" and "z2i".


                             Call GammaMultiply(sb1r,sb1i,z3,z3i,ixx,iyy,izz,&
                                        ittt,usp,uss,fixbc,ir,myid)
!
!     Do second order
!
      md=1

      do bx=-md,md
	 do by=-(md-abs(bx)),md-abs(bx)
	    do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
	       bt=md-abs(bx)-abs(by)-abs(bz)
	       tempx = ixx+bx 
	       tempy = iyy+by
	       tempz = izz+bz 
	       temptplus = ittt+bt 

               Call GammaMultiply(sb2r,sb2i,sb1r,sb1i,tempx,tempy,tempz,&
                                  temptplus,usp,uss,fixbc,ir,myid)

		 if (bt/=0) then
		     tempx = ixx+bx 
		     tempy = iyy+by 
		     tempz = izz+bz 
		     temptminus=ittt-bt
		     Call GammaMultiply(sb2r,sb2i,sb1r,sb1i,tempx,tempy,tempz,&
		 	 		 temptminus,usp,uss,fixbc,ir,myid)
		 end if ! (bt/=0)
	      end do ! bz
	   end do ! by
        end do ! bx

!     Do third order

        Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,ixx,iyy,izz,&
                           ittt,usp,uss,fixbc,ir,myid)

        md=2

	do bx=-md,md
           do by=-(md-abs(bx)),md-abs(bx)
              do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
		 bt=md-abs(bx)-abs(by)-abs(bz)

		 ax=ixx+bx
		 ay=iyy+by
		 az=izz+bz
		 at=ittt+bt

		 ax=mod(ax-1+nx,nx)+1
		 ay=mod(ay-1+ny,ny)+1
		 az=mod(az-1+nz,nz)+1
		 at=mod(at-1+nt,nt)+1

		 ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		 tempx = ixx+bx 
		 tempy = iyy+by 
		 tempz = izz+bz 
		 temptplus = ittt+bt 

                 Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,tempx,tempy,tempz,&
					temptplus,usp,uss,fixbc,ir,myid)

		 if (bt/=0) then
		     at=ittt-bt
		     at=mod(at-1+nt,nt)+1

		     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		     tempx = ixx+bx 
		     tempy = iyy+by 
		     tempz = izz+bz 
		     temptminus=ittt-bt

		     Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,tempx,tempy,tempz,&
			                    temptminus,usp,uss,fixbc,ir,myid)
		 end if ! bt

	       end do ! bz
            end do ! by
         end do ! bx


!     Do fourth order


         md=1

	 do bx=-md,md
            do by=-(md-abs(bx)),md-abs(bx)
	       do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
		  bt=md-abs(bx)-abs(by)-abs(bz)

		  ax=ixx+bx
		  ay=iyy+by
		  az=izz+bz
		  at=ittt+bt

		  ax=mod(ax-1+nx,nx)+1
		  ay=mod(ay-1+ny,ny)+1
		  az=mod(az-1+nz,nz)+1
		  at=mod(at-1+nt,nt)+1

		  ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		  tempx = ixx+bx 
		  tempy = iyy+by 
		  tempz = izz+bz 
		  temptplus = ittt+bt 

	          Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
					 temptplus,usp,uss,fixbc,ir,myid)

		  if (bt/=0) then
		      at=ittt-bt
		      at=mod(at-1+nt,nt)+1
		      ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		      tempx = ixx+bx 
		      tempy = iyy+by 
		      tempz = izz+bz 
		      temptminus=ittt-bt

	              Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
			              	     temptminus,usp,uss,fixbc,ir,myid)
		  end if ! bt

               end do ! bz
            end do ! by
	 end do ! bx

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order terms have been removed for
! nsub==4. I am also allowed to remove the md=3 part of 4th order.
! Done to save time before Dublin conference. 7-16-05


	     md=3

	     do bx=-md,md
		do by=-(md-abs(bx)),md-abs(bx)
	           do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
		      bt=md-abs(bx)-abs(by)-abs(bz)

		      ax=ixx+bx
		      ay=iyy+by
		      az=izz+bz
		      at=ittt+bt

		      ax=mod(ax-1+nx,nx)+1
		      ay=mod(ay-1+ny,ny)+1
		      az=mod(az-1+nz,nz)+1
		      at=mod(at-1+nt,nt)+1

		      ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		      tempx = ixx+bx 
		      tempy = iyy+by 
		      tempz = izz+bz 
		      temptplus = ittt+bt 

	              Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
			                     temptplus,usp,uss,fixbc,ir,myid)

		      if (bt/=0) then
		          at=ittt-bt
		          at=mod(at-1+nt,nt)+1
		          ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		          tempx = ixx+bx 
		          tempy = iyy+by 
		          tempz = izz+bz 
		          temptminus=ittt-bt

			  Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
			                      temptminus,usp,uss,fixbc,ir,myid)
		      end if ! bt
		   end do ! bz
		 end do ! by
	       end do ! bx



!     Do fifth order (relevant points)
!

	      Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,ixx,iyy,izz,&
			           	   ittt,usp,uss,fixbc,ir,myid)

	       md=2

	       do bx=-md,md
	          do by=-(md-abs(bx)),md-abs(bx)
		     do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
		        bt=md-abs(bx)-abs(by)-abs(bz)

		        ax=ixx+bx
		        ay=iyy+by
		        az=izz+bz
		        at=ittt+bt

		        ax=mod(ax-1+nx,nx)+1
		        ay=mod(ay-1+ny,ny)+1
		        az=mod(az-1+nz,nz)+1
		        at=mod(at-1+nt,nt)+1

		        ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		        tempx = ixx+bx 
		        tempy = iyy+by 
		        tempz = izz+bz 
		        temptplus = ittt+bt 

			 Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
				               temptplus,usp,uss,fixbc,ir,myid)


		        if (bt/=0) then
		            at=ittt-bt
		            at=mod(at-1+nt,nt)+1
		            ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		            tempx = ixx+bx 
		            tempy = iyy+by 
		            tempz = izz+bz 
		            temptminus=ittt-bt

			    Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
				                    temptminus,usp,uss,fixbc,ir,myid)
		        end if ! bt

		     end do ! bz
		  end do ! by
	       end do ! bx


!     Do sixth order (relevant points)

	       md=1

	       do bx=-md,md
	          do by=-(md-abs(bx)),md-abs(bx)
		     do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
		        bt=md-abs(bx)-abs(by)-abs(bz)

		        ax=ixx+bx
		        ay=iyy+by
		        az=izz+bz
		        at=ittt+bt

		        ax=mod(ax-1+nx,nx)+1
		        ay=mod(ay-1+ny,ny)+1
		        az=mod(az-1+nz,nz)+1
		        at=mod(at-1+nt,nt)+1

		        ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		        tempx = ixx+bx 
		        tempy = iyy+by 
		        tempz = izz+bz 
		        temptplus = ittt+bt 

			Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
				               temptplus,usp,uss,fixbc,ir,myid)


		        if (bt/=0) then
		            at=ittt-bt
		            at=mod(at-1+nt,nt)+1
		            ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

		            tempx = ixx+bx 
		            tempy = iyy+by 
		            tempz = izz+bz 
		            temptminus=ittt-bt

			    Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
			                           temptminus,usp,uss,fixbc,ir,myid)
		      end if ! bt
		   end do ! bz
		end do ! by
	     end do ! bx

         !   if (myid==0) print "(i5,i3,4es17.10)", ihere, icolor, sb4r(ihere,icolor,:)
         !   if (counter > 1000) then
         !      call printlog("Just finshed the loops, STOPPING(SB)!",myid,rwdir)
         !      call MPI_BARRIER(MPI_COMM_WORLD,ierr)
         !      stop
         !   endif ! check

!
! ####################################################################
!

	 leftx=mod((ixx-1)-1+nx,nx)+1
	 rightx=mod((ixx+1)-1+nx,nx)+1
	 lefty=mod((iyy-1)-1+ny,ny)+1
	 righty=mod((iyy+1)-1+ny,ny)+1
	 leftz=mod((izz-1)-1+nz,nz)+1
	 rightz=mod((izz+1)-1+nz,nz)+1
	 leftt=mod((ittt-1)-1+nt,nt)+1
	 rightt=mod((ittt+1)-1+nt,nt)+1
	
!     Translate coordinates to single array index

	 leftx=leftx+(iyy-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
	 rightx=rightx+(iyy-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
	 lefty=ixx+(lefty-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
	 righty=ixx+(righty-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
	 leftz=ixx+(iyy-1)*nx+(leftz-1)*nx*ny+(ittt-1)*nx*ny*nz
	 rightz=ixx+(iyy-1)*nx+(rightz-1)*nx*ny+(ittt-1)*nx*ny*nz
	 leftt=ixx+(iyy-1)*nx+(izz-1)*nx*ny+(leftt-1)*nx*ny*nz
	 rightt=ixx+(iyy-1)*nx+(izz-1)*nx*ny+(rightt-1)*nx*ny*nz

! This is the end. in twvev

! Let's think about this.. Let's do the (1+- gamma_5) multiplication here

           !if (myid==0) print "(a25,i5,i3,4es17.10)", "printing sb4r before::",ihere,icolor,sb4r(ihere,icolor,:)
           !call printlog("Stopping SB!",myid,rwdir)
           !call MPI_BARRIER(MPI_COMM_WORLD,ierr)
           !stop

         !if (myid==0) print *, ":ntmqcd:", ntmqcd
         !call MPI_BARRIER(MPI_COMM_WORLD,ierr)
         !stop

if (.false.) then
         do jc=1,nc
            call gamma5vector(sb3r,ihere,jc,ntmqcd,myid)
            call gamma5vector(sb3r,leftx,jc,ntmqcd,myid)
            call gamma5vector(sb3r,rightx,jc,ntmqcd,myid)
            call gamma5vector(sb3r,lefty,jc,ntmqcd,myid)
            call gamma5vector(sb3r,righty,jc,ntmqcd,myid)
            call gamma5vector(sb3r,leftz,jc,ntmqcd,myid)
            call gamma5vector(sb3r,rightz,jc,ntmqcd,myid)
            call gamma5vector(sb3r,leftt,jc,ntmqcd,myid)
            call gamma5vector(sb3r,rightt,jc,ntmqcd,myid)
 
            if (jc==icolor) then
               call gamma5vector(sb4r,ihere,jc,ntmqcd,myid)
            endif

            call gamma5vector(sb5r,ihere,jc,ntmqcd,myid)
            call gamma5vector(sb5r,leftx,jc,ntmqcd,myid)
            call gamma5vector(sb5r,rightx,jc,ntmqcd,myid)
            call gamma5vector(sb5r,lefty,jc,ntmqcd,myid)
            call gamma5vector(sb5r,righty,jc,ntmqcd,myid)
            call gamma5vector(sb5r,leftz,jc,ntmqcd,myid)
            call gamma5vector(sb5r,rightz,jc,ntmqcd,myid)
            call gamma5vector(sb5r,leftt,jc,ntmqcd,myid)
            call gamma5vector(sb5r,rightt,jc,ntmqcd,myid)

            if (jc.eq.icolor) then
               call gamma5vector(sb6r,ihere,jc,ntmqcd,myid)
            endif

            call gamma5vector(sb3i,ihere,jc,ntmqcd,myid)
            call gamma5vector(sb3i,leftx,jc,ntmqcd,myid)
            call gamma5vector(sb3i,rightx,jc,ntmqcd,myid)
            call gamma5vector(sb3i,lefty,jc,ntmqcd,myid)
            call gamma5vector(sb3i,righty,jc,ntmqcd,myid)
            call gamma5vector(sb3i,leftz,jc,ntmqcd,myid)
            call gamma5vector(sb3i,rightz,jc,ntmqcd,myid)
            call gamma5vector(sb3i,leftt,jc,ntmqcd,myid)
            call gamma5vector(sb3i,rightt,jc,ntmqcd,myid)

            if (jc==icolor) then
               call gamma5vector(sb4i,ihere,jc,ntmqcd,myid)
            endif

            call gamma5vector(sb5i,ihere,jc,ntmqcd,myid)
            call gamma5vector(sb5i,leftx,jc,ntmqcd,myid)
            call gamma5vector(sb5i,rightx,jc,ntmqcd,myid)
            call gamma5vector(sb5i,lefty,jc,ntmqcd,myid)
            call gamma5vector(sb5i,righty,jc,ntmqcd,myid)
            call gamma5vector(sb5i,leftz,jc,ntmqcd,myid)
            call gamma5vector(sb5i,rightz,jc,ntmqcd,myid)
            call gamma5vector(sb5i,leftt,jc,ntmqcd,myid)
            call gamma5vector(sb5i,rightt,jc,ntmqcd,myid)
 
            if (jc.eq.icolor) then
               call gamma5vector(sb6i,ihere,jc,ntmqcd,myid)
            endif
         enddo ! jc
 endif ! .false.
         ! if (myid==0) print "(a16,i5,i3,4es17.10)", "printing sb4r::",ihere,icolor,sb4r(ihere,icolor,:)



! This is where I will try putting in the rotations at the end.
! Note all processors are working on their part before the
! data is combined. This is in twvev. -WW


                imv(1)=ihere
                imv(2)=leftx
                imv(3)=rightx
                imv(4)=lefty
                imv(5)=righty
                imv(6)=leftz
                imv(7)=rightz
                imv(8)=leftt
                imv(9)=rightt

                do ii = 1,9
                 ih = imv(ii)
                 do jc = 1,nc
! sb1r,i case
                     sbr(1) = sb1r(ih,jc,1)
                     sbr(2) = sb1r(ih,jc,2)

                     sb1r(ih,jc,1) = cosd*sb1r(ih,jc,1) - sind*sb1r(ih,jc,3)
                     sb1r(ih,jc,2) = cosd*sb1r(ih,jc,2) - sind*sb1r(ih,jc,4)
                     sb1r(ih,jc,3) = cosd*sb1r(ih,jc,3) + sind*sbr(1)
                     sb1r(ih,jc,4) = cosd*sb1r(ih,jc,4) + sind*sbr(2)

                     sbi(1) = sb1i(ih,jc,1)
                     sbi(2) = sb1i(ih,jc,2)

                     sb1i(ih,jc,1) = cosd*sb1i(ih,jc,1) - sind*sb1i(ih,jc,3)
                     sb1i(ih,jc,2) = cosd*sb1i(ih,jc,2) - sind*sb1i(ih,jc,4)
                     sb1i(ih,jc,3) = cosd*sb1i(ih,jc,3) + sind*sbi(1)
                     sb1i(ih,jc,4) = cosd*sb1i(ih,jc,4) + sind*sbi(2)

! sb2r,i case
                     sbr(1) = sb2r(ih,jc,1)
                     sbr(2) = sb2r(ih,jc,2)

                     sb2r(ih,jc,1) = cosd*sb2r(ih,jc,1) - sind*sb2r(ih,jc,3)
                     sb2r(ih,jc,2) = cosd*sb2r(ih,jc,2) - sind*sb2r(ih,jc,4)
                     sb2r(ih,jc,3) = cosd*sb2r(ih,jc,3) + sind*sbr(1)
                     sb2r(ih,jc,4) = cosd*sb2r(ih,jc,4) + sind*sbr(2)

                     sbi(1) = sb2i(ih,jc,1)
                     sbi(2) = sb2i(ih,jc,2)

                     sb2i(ih,jc,1) = cosd*sb2i(ih,jc,1) - sind*sb2i(ih,jc,3)
                     sb2i(ih,jc,2) = cosd*sb2i(ih,jc,2) - sind*sb2i(ih,jc,4)
                     sb2i(ih,jc,3) = cosd*sb2i(ih,jc,3) + sind*sbi(1)
                     sb2i(ih,jc,4) = cosd*sb2i(ih,jc,4) + sind*sbi(2)

! sb3r,i case
                     sbr(1) = sb3r(ih,jc,1)
                     sbr(2) = sb3r(ih,jc,2)

                     sb3r(ih,jc,1) = cosd*sb3r(ih,jc,1) - sind*sb3r(ih,jc,3)
                     sb3r(ih,jc,2) = cosd*sb3r(ih,jc,2) - sind*sb3r(ih,jc,4)
                     sb3r(ih,jc,3) = cosd*sb3r(ih,jc,3) + sind*sbr(1)
                     sb3r(ih,jc,4) = cosd*sb3r(ih,jc,4) + sind*sbr(2)

                     sbi(1) = sb3i(ih,jc,1)
                     sbi(2) = sb3i(ih,jc,2)

                     sb3i(ih,jc,1) = cosd*sb3i(ih,jc,1) - sind*sb3i(ih,jc,3)
                     sb3i(ih,jc,2) = cosd*sb3i(ih,jc,2) - sind*sb3i(ih,jc,4)
                     sb3i(ih,jc,3) = cosd*sb3i(ih,jc,3) + sind*sbi(1)
                     sb3i(ih,jc,4) = cosd*sb3i(ih,jc,4) + sind*sbi(2)

! sb4r,i case
                     sbr(1) = sb4r(ih,jc,1)
                     sbr(2) = sb4r(ih,jc,2)

                     sb4r(ih,jc,1) = cosd*sb4r(ih,jc,1) - sind*sb4r(ih,jc,3)
                     sb4r(ih,jc,2) = cosd*sb4r(ih,jc,2) - sind*sb4r(ih,jc,4)
                     sb4r(ih,jc,3) = cosd*sb4r(ih,jc,3) + sind*sbr(1)
                     sb4r(ih,jc,4) = cosd*sb4r(ih,jc,4) + sind*sbr(2)

                     sbi(1) = sb4i(ih,jc,1)
                     sbi(2) = sb4i(ih,jc,2)

                     sb4i(ih,jc,1) = cosd*sb4i(ih,jc,1) - sind*sb4i(ih,jc,3)
                     sb4i(ih,jc,2) = cosd*sb4i(ih,jc,2) - sind*sb4i(ih,jc,4)
                     sb4i(ih,jc,3) = cosd*sb4i(ih,jc,3) + sind*sbi(1)
                     sb4i(ih,jc,4) = cosd*sb4i(ih,jc,4) + sind*sbi(2)

! sb5r,i case
                     sbr(1) = sb5r(ih,jc,1)
                     sbr(2) = sb5r(ih,jc,2)

                     sb5r(ih,jc,1) = cosd*sb5r(ih,jc,1) - sind*sb5r(ih,jc,3)
                     sb5r(ih,jc,2) = cosd*sb5r(ih,jc,2) - sind*sb5r(ih,jc,4)
                     sb5r(ih,jc,3) = cosd*sb5r(ih,jc,3) + sind*sbr(1)
                     sb5r(ih,jc,4) = cosd*sb5r(ih,jc,4) + sind*sbr(2)

                     sbi(1) = sb5i(ih,jc,1)
                     sbi(2) = sb5i(ih,jc,2)

                     sb5i(ih,jc,1) = cosd*sb5i(ih,jc,1) - sind*sb5i(ih,jc,3)
                     sb5i(ih,jc,2) = cosd*sb5i(ih,jc,2) - sind*sb5i(ih,jc,4)
                     sb5i(ih,jc,3) = cosd*sb5i(ih,jc,3) + sind*sbi(1)
                     sb5i(ih,jc,4) = cosd*sb5i(ih,jc,4) + sind*sbi(2)

! ssb6r,i case
                     sbr(1) = sb6r(ih,jc,1)
                     sbr(2) = sb6r(ih,jc,2)

                     sb6r(ih,jc,1) = cosd*sb6r(ih,jc,1) - sind*sb6r(ih,jc,3)
                     sb6r(ih,jc,2) = cosd*sb6r(ih,jc,2) - sind*sb6r(ih,jc,4)
                     sb6r(ih,jc,3) = cosd*sb6r(ih,jc,3) + sind*sbr(1)
                     sb6r(ih,jc,4) = cosd*sb6r(ih,jc,4) + sind*sbr(2)

                     sbi(1) = sb6i(ih,jc,1)
                     sbi(2) = sb6i(ih,jc,2)

                     sb6i(ih,jc,1) = cosd*sb6i(ih,jc,1) - sind*sb6i(ih,jc,3)
                     sb6i(ih,jc,2) = cosd*sb6i(ih,jc,2) - sind*sb6i(ih,jc,4)
                     sb6i(ih,jc,3) = cosd*sb6i(ih,jc,3) + sind*sbi(1)
                     sb6i(ih,jc,4) = cosd*sb6i(ih,jc,4) + sind*sbi(2)
                 enddo ! jc
                enddo ! ii


	 do jd=1,nd
	    do jri=1,nri
	       do jc=1,nc
                  
            !     if (nsub==0) usub=0
            !     if (nsub==4) then
            !         usub = 0
            !     elseif (nsub==6) then
            !         usub = 1
            !     endif ! nsub
            !    do isb=0,usub

         	  do isb=0,1
		     IF (jri.eq.1) THEN
		         if (isb.eq.0) then

! ABDOU ~ probably need to introduce a mass loop that goes over the new xk(i,j) variable in here. 

! Note there are "jump back" terms in the twisted case for both local and nonlocal operators.

                            if (abs(delta) .gt. 1.E-12 ) then
                             s0(ihere)= xk(1)*sb1r(ihere,jc,jd)+(xk(3))*sb3r(ihere,jc,jd)
                             s0(leftx)= xk(1)*sb1r(leftx,jc,jd)+(xk(3))*sb3r(leftx,jc,jd)
                             s0(rightx)=xk(1)*sb1r(rightx,jc,jd)+(xk(3))*sb3r(rightx,jc,jd)
                             s0(lefty)= xk(1)*sb1r(lefty,jc,jd)+(xk(3))*sb3r(lefty,jc,jd)
                             s0(righty)=xk(1)*sb1r(righty,jc,jd)+(xk(3))*sb3r(righty,jc,jd)
                             s0(leftz)= xk(1)*sb1r(leftz,jc,jd)+(xk(3))*sb3r(leftz,jc,jd)
                             s0(rightz)=xk(1)*sb1r(rightz,jc,jd)+(xk(3))*sb3r(rightz,jc,jd)
                             s0(leftt)= xk(1)*sb1r(leftt,jc,jd)+(xk(3))*sb3r(leftt,jc,jd)
                             s0(rightt)=xk(1)*sb1r(rightt,jc,jd)+(xk(3))*sb3r(rightt,jc,jd)
                            else
			     s0(ihere)=(xk(3))*sb3r(ihere,jc,jd)                                         
			     s0(leftx)=(xk(3))*sb3r(leftx,jc,jd)                                         
			     s0(rightx)=(xk(3))*sb3r(rightx,jc,jd)
			     s0(lefty)=(xk(3))*sb3r(lefty,jc,jd)
			     s0(righty)=(xk(3))*sb3r(righty,jc,jd)                                       
			     s0(leftz)=(xk(3))*sb3r(leftz,jc,jd)
			     s0(rightz)=(xk(3))*sb3r(rightz,jc,jd)                                       
			     s0(leftt)=(xk(3))*sb3r(leftt,jc,jd)
			     s0(rightt)=(xk(3))*sb3r(rightt,jc,jd)                                       
                            endif ! delta

       			     if (jc==icolor) then
                              if (abs(delta) .gt. 1.E-12 ) then
                                 s1(ihere)      = xk(2)*sb2r(ihere,jc,jd)+xk(4)*sb4r(ihere,jc,jd)
                                 pscalar(ihere) = sign(jd)*(xk(2)*sb2i(ihere,jc,cd(jd))+xk(4)*sb4i(ihere,jc,cd(jd)))
                              else
                                 s1(ihere)      = xk(4)*sb4r(ihere,jc,jd)
                                 pscalar(ihere) = sign(jd)*xk(4)*sb4i(ihere,jc,cd(jd))
                              endif ! delta
			     endif

		         else if(isb.eq.1) then    

			     s0(ihere)=(xk(5))*sb5r(ihere,jc,jd)
			     s0(leftx)=(xk(5))*sb5r(leftx,jc,jd)
			     s0(rightx)=(xk(5))*sb5r(rightx,jc,jd)
			     s0(lefty)=(xk(5))*sb5r(lefty,jc,jd)
			     s0(righty)=(xk(5))*sb5r(righty,jc,jd)
			     s0(leftz)=(xk(5))*sb5r(leftz,jc,jd)
			     s0(rightz)=(xk(5))*sb5r(rightz,jc,jd)
			     s0(leftt)=(xk(5))*sb5r(leftt,jc,jd)
			     s0(rightt)=(xk(5))*sb5r(rightt,jc,jd)
			     if (jc.eq.icolor) then
			         s1(ihere)=(xk(6))*sb6r(ihere,jc,jd)
                                 pscalar(ihere) = sign(jd)*xk(6)*sb6i(ihere,jc,cd(jd))
			     endif

		         endif
		     ELSE
		        if (isb.eq.0) then
                           if (abs(delta) .gt. 1.E-12 ) then
                            s0(ihere)= xk(1)*sb1i(ihere,jc,jd)+(xk(3))*sb3i(ihere,jc,jd)
                            s0(leftx)= xk(1)*sb1i(leftx,jc,jd)+(xk(3))*sb3i(leftx,jc,jd)
                            s0(rightx)=xk(1)*sb1i(rightx,jc,jd)+(xk(3))*sb3i(rightx,jc,jd)
                            s0(lefty)= xk(1)*sb1i(lefty,jc,jd)+(xk(3))*sb3i(lefty,jc,jd)
                            s0(righty)=xk(1)*sb1i(righty,jc,jd)+(xk(3))*sb3i(righty,jc,jd)
                            s0(leftz)= xk(1)*sb1i(leftz,jc,jd)+(xk(3))*sb3i(leftz,jc,jd)
                            s0(rightz)=xk(1)*sb1i(rightz,jc,jd)+(xk(3))*sb3i(rightz,jc,jd)
                            s0(leftt)= xk(1)*sb1i(leftt,jc,jd)+(xk(3))*sb3i(leftt,jc,jd)
                            s0(rightt)=xk(1)*sb1i(rightt,jc,jd)+(xk(3))*sb3i(rightt,jc,jd)
                           else
             	            s0(ihere)=(xk(3))*sb3i(ihere,jc,jd)
			    s0(leftx)=(xk(3))*sb3i(leftx,jc,jd)
			    s0(rightx)=(xk(3))*sb3i(rightx,jc,jd)
			    s0(lefty)=(xk(3))*sb3i(lefty,jc,jd)
			    s0(righty)=(xk(3))*sb3i(righty,jc,jd)
			    s0(leftz)=(xk(3))*sb3i(leftz,jc,jd)
			    s0(rightz)=(xk(3))*sb3i(rightz,jc,jd)
			    s0(leftt)=(xk(3))*sb3i(leftt,jc,jd)
			    s0(rightt)=(xk(3))*sb3i(rightt,jc,jd)
                           endif ! delta

			    if (jc.eq.icolor) then
                             if (abs(delta) .gt. 1.E-12 ) then
                                s1(ihere)      = xk(2)*sb2i(ihere,jc,jd)+xk(4)*sb4i(ihere,jc,jd)
                                pscalar(ihere) = -sign(jd)*(xk(2)*sb2r(ihere,jc,cd(jd))+xk(4)*sb4r(ihere,jc,cd(jd)))
                              else
                                s1(ihere)      = xk(4)*sb4i(ihere,jc,jd)
                                pscalar(ihere) = -sign(jd)*xk(4)*sb4r(ihere,jc,cd(jd))
                              endif ! delta
			    endif

		        else if(isb.eq.1) then

			    s0(ihere)=(xk(5))*sb5i(ihere,jc,jd)
			    s0(leftx)=(xk(5))*sb5i(leftx,jc,jd)
			    s0(rightx)=(xk(5))*sb5i(rightx,jc,jd)
			    s0(lefty)=(xk(5))*sb5i(lefty,jc,jd)
			    s0(righty)=(xk(5))*sb5i(righty,jc,jd)
			    s0(leftz)=(xk(5))*sb5i(leftz,jc,jd)
			    s0(rightz)=(xk(5))*sb5i(rightz,jc,jd)
			    s0(leftt)=(xk(5))*sb5i(leftt,jc,jd)
			    s0(rightt)=(xk(5))*sb5i(rightt,jc,jd)
		            if (jc.eq.icolor) then
			        s1(ihere)=(xk(6))*sb6i(ihere,jc,jd)
! pscalar is no longer a propagator. The gamma_5 mult has been done outside of
! scalarCalc for simplicity.
                                pscalar(ihere) = -sign(jd)*xk(6)*sb6r(ihere,jc,cd(jd))
		            endif

		       endif ! isb
		   ENDIF ! real/imag
! So that the traces are the same as the "Old" program for  comparison we 
! use gammaCurrentCalc


                   call gammaCurrentCalc(s0,jd,icolor,jc,jri,ihere,&
                                         leftx,rightx,lefty,righty,leftz,&
                                         rightz,leftt,rightt,ittt,usp,uss,fixbc,ir,myid)

!                  call currentCalc(s0,jd,icolor,jc,jri,ihere,&
!                                   leftx,rightx,lefty,righty,leftz,&
!                                   rightz,leftt,rightt,usp,uss,myid)

		   if (jc==icolor) then
		        call scalarCalc(s1,jd,jc,jri,ihere,1,myid)
                        call scalarCalc(pscalar,jd,jc,jri,ihere,2,myid)
		   endif

     if (.false.) then
             if (jc==icolor .and. jri==1 .and. isb==0) then
               if (myid==0) print "(i5,2i3,1es17.10)", ihere, icolor,jd, psir(ihere)
             endif ! check color
            !if (counter > 1000) then
             if (counter > 200) then
                call printlog("Just finshed the loops, STOPPING (SB)!",myid,rwdir)
                call MPI_BARRIER(MPI_COMM_WORLD,ierr)
                stop
             endif ! check
     endif ! .false.

!                   if (jc==icolor) then
!                      if (jri==1) then
!                         psir(ihere) = 0.0
!                         psii(ihere) = 0.0
!                         psir(ihere) = s1(ihere)*z2(ihere,icolor,jd)
!                      endif
!                      if (jri==2) then
!                         psir(ihere) = 0.0
!                         psii(ihere) = 0.0
!                         psii(ihere) = s1(ihere)*z2(ihere,icolor,jd)
!              	       endif
!	      ! call scalarCalc(s1,jd,icolor,jri,ihere,1)
!                     ! call scalarCalc(pscalar,jd,icolor,jri,ihere,2)
!	  !endif
!

!  xrr2(isb)=xrr2(isb)+rhor(ihere)
!  xrr2(isb)=xrr2(isb)+rhor(leftt)
!  xri2(isb)=xri2(isb)+rhoi(ihere)
!  xri2(isb)=xri2(isb)+rhoi(leftt)

                   if (ittt.ne.ltime) then
                       xrr2(isb)=xrr2(isb)+rhor(leftt)
                       xri2(isb)=xri2(isb)+rhoi(leftt)
                   endif ! ittt.ne.ltime
 
                   if (ittt.ne.utime) then
                       xrr2(isb)=xrr2(isb)+rhor(ihere)
                       xri2(isb)=xri2(isb)+rhoi(ihere)
                   endif ! ittt.ne.ltime

! Only do psibar*psi once when jc=icolor

		   if (jc==icolor) then
                       xps2(isb)  = xps2(isb)  + psir(ihere)
		       xpi2(isb)  = xpi2(isb)  + psii(ihere)
                       xpsur(isb) = xpsur(isb) + psur(ihere)
                       xpsui(isb) = xpsui(isb) + psui(ihere)
		   endif


		   xsj1pr(isb)=xsj1pr(isb)+j1pr(leftx)
		   xsj1pr(isb)=xsj1pr(isb)+j1pr(ihere)      
		   xsj1pi(isb)=xsj1pi(isb)+j1pi(leftx)
		   xsj1pi(isb)=xsj1pi(isb)+j1pi(ihere)  


		   xsj2pr(isb)=xsj2pr(isb)+j2pr(lefty)
		   xsj2pr(isb)=xsj2pr(isb)+j2pr(ihere)      
		   xsj2pi(isb)=xsj2pi(isb)+j2pi(lefty)
		   xsj2pi(isb)=xsj2pi(isb)+j2pi(ihere) 

		   xsj3pr(isb)=xsj3pr(isb)+j3pr(leftz)
		   xsj3pr(isb)=xsj3pr(isb)+j3pr(ihere)      
		   xsj3pi(isb)=xsj3pi(isb)+j3pi(leftz)
		   xsj3pi(isb)=xsj3pi(isb)+j3pi(ihere) 

!     Momentum analysis

                   opertemp(1,ittt,1,isb)=opertemp(1,ittt,1,isb)+&
                                          rhor(ihere)
                   opertemp(1,modulo((ittt-1)-1,nt)+1,1,isb)=&
                   opertemp(1,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                          rhor(leftt)
 
                   opertemp(2,ittt,1,isb)=opertemp(2,ittt,1,isb)+&
                                          rhoi(ihere)
                   opertemp(2,modulo((ittt-1)-1,nt)+1,1,isb)=&
                   opertemp(2,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                          rhoi(leftt)



! These are the scalor operators...

		   if (jc.eq.icolor) then
    		       opertemp(3,ittt,1,isb)=opertemp(3,ittt,1,isb)+&
		               	              psir(ihere)

		       opertemp(4,ittt,1,isb)=opertemp(4,ittt,1,isb)+&
		                              psii(ihere)
		   endif

		   opertemp(5,ittt,1,isb)=opertemp(5,ittt,1,isb)+&
				      j1pr(ihere)+&
				      j1pr(leftx)

		   opertemp(6,ittt,1,isb)=opertemp(6,ittt,1,isb)+&
				      j1pi(ihere)+&
				      j1pi(leftx)

                  ! if (ittt==2) then
                  !    call MPI_BARRIER(MPI_COMM_WORLD,ierr)
                  !    stop
                  ! endif
 
		   opertemp(7,ittt,1,isb)=opertemp(7,ittt,1,isb)+&
				      j2pr(ihere)+&
				      j2pr(lefty)

		   opertemp(8,ittt,1,isb)=opertemp(8,ittt,1,isb)+&
				      j2pi(ihere)+&
				      j2pi(lefty)

		   opertemp(9,ittt,1,isb)=opertemp(9,ittt,1,isb)+&
				      j3pr(ihere)+&
				      j3pr(leftz)

		   opertemp(10,ittt,1,isb)=opertemp(10,ittt,1,isb)+&
				       j3pi(ihere)+&
				       j3pi(leftz)

                   if (jc.eq.icolor) then
                       opertemp(11,ittt,1,isb)=opertemp(11,ittt,1,isb)+&
                                              psur(ihere)

                       opertemp(12,ittt,1,isb)=opertemp(12,ittt,1,isb)+&
                                              psui(ihere)
                   endif

		   do ix=2,5

                      opertemp(1,ittt,ix,isb)=opertemp(1,ittt,ix,isb)+&
                                              rhor(ihere)*ffac(ihere,ix-1)
                      opertemp(1,modulo((ittt-1)-1,nt)+1,ix,isb)=&
                      opertemp(1,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                              rhor(leftt)*ffac(leftt,ix-1)

                      opertemp(2,ittt,ix,isb)=opertemp(2,ittt,ix,isb)+&
                                              rhoi(ihere)*ffac(ihere,ix-1)
                      opertemp(2,modulo((ittt-1)-1,nt)+1,ix,isb)=&
                      opertemp(2,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                              rhoi(leftt)*ffac(leftt,ix-1)

! These are the scalor operators...

		     if (jc.eq.icolor) then
		       opertemp(3,ittt,ix,isb)=opertemp(3,ittt,ix,isb)+&
					   psir(ihere)*ffac(ihere,ix-1)

		       opertemp(4,ittt,ix,isb)=opertemp(4,ittt,ix,isb)+&
					   psii(ihere)*ffac(ihere,ix-1)
		     endif

		     opertemp(5,ittt,ix,isb)=opertemp(5,ittt,ix,isb)+&
					 j1pi(ihere)*fas3(ihere,ix-1)+&
					 j1pi(leftx)*fas3(leftx,ix-1)

		     opertemp(6,ittt,ix,isb)=opertemp(6,ittt,ix,isb)+&
					 j2pi(ihere)*fas1(ihere,ix-1)+&
					 j2pi(lefty)*fas1(lefty,ix-1)

		     opertemp(7,ittt,ix,isb)=opertemp(7,ittt,ix,isb)+&
					 j3pi(ihere)*fas2(ihere,ix-1)+&
					 j3pi(leftz)*fas2(leftz,ix-1)

		     opertemp(8,ittt,ix,isb)=opertemp(8,ittt,ix,isb)+&
					 j1pi(ihere)*fas2(ihere,ix-1)+&
					 j1pi(leftx)*fas2(leftx,ix-1)

		     opertemp(9,ittt,ix,isb)=opertemp(9,ittt,ix,isb)+&
					 j2pi(ihere)*fas3(ihere,ix-1)+&
					 j2pi(lefty)*fas3(lefty,ix-1)

		     opertemp(10,ittt,ix,isb)=opertemp(10,ittt,ix,isb)+&
					  j3pi(ihere)*fas1(ihere,ix-1)+&
					  j3pi(leftz)*fas1(leftz,ix-1)

                     if (jc.eq.icolor) then
                       opertemp(11,ittt,ix,isb)=opertemp(11,ittt,ix,isb)+&
                                           psur(ihere)*ffac(ihere,ix-1)

                       opertemp(12,ittt,ix,isb)=opertemp(12,ittt,ix,isb)+&
                                           psui(ihere)*ffac(ihere,ix-1)
                     endif

	! Need also 2-1, 3-2 and 1-3 combinations of directions
	! (fas things) and currents at this point according to
	! ahab7.f, which is used as a guide for coding the magnetic operators.
	! disco13.f seems to imply that only the ones using
	! the imaginary part of the currents need be kept.
	!
		     enddo ! ix
	!     End of momentum analysis


                    enddo ! isb
		   enddo ! jc
		 enddo ! jri 
	       enddo ! jd
                  !if(ittt==2) then
                  !   call MPI_BARRIER(MPI_COMM_WORLD,ierr)
                  !   stop
                  !endif


	!     write(6,*) 'out of 102 loop'

	      do jd=1,nd
		do jc=1,nc

          if(nsub==6) then
              md=6

              do bx=-md,md
                do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1

                       ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         sb6r(ahere,jc,jd)=0.0_KR
                         sb6i(ahere,jc,jd)=0.0_KR
                       if(bt/=0) then
        !            if(bt.ne.0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         sb6r(ahere,jc,jd)=0.0_KR
                         sb6i(ahere,jc,jd)=0.0_KR
                       end if


                   end do ! bz
                 end do ! by
               end do ! bx

              md=5

              do bx=-md,md
                do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1

                       ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         sb5r(ahere,jc,jd)=0.0_KR
                         sb5i(ahere,jc,jd)=0.0_KR
                       if(bt/=0) then
        !            if(bt.ne.0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         sb5r(ahere,jc,jd)=0.0_KR
                         sb5i(ahere,jc,jd)=0.0_KR
                       end if


                   end do ! bz
                 end do ! by
               end do ! bx

             endif ! nsub==6

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order zeroing has been commented out below for
! nsub==4. For nsub==6 you need to put back these values!

             md=4

             do bx=-md,md
		do by=-(md-abs(bx)),md-abs(bx)
		   do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
		      bt=md-abs(bx)-abs(by)-abs(bz)

		      ax=ixx+bx
		      ay=iyy+by
		      az=izz+bz
		      at=ittt+bt

		      ax=mod(ax-1+nx,nx)+1
		      ay=mod(ay-1+ny,ny)+1
		      az=mod(az-1+nz,nz)+1
		      at=mod(at-1+nt,nt)+1


		      ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

                      sb6r(ahere,jc,jd)=0.0_KR
                      sb6i(ahere,jc,jd)=0.0_KR
		      sb4r(ahere,jc,jd)=0.0_KR
		      sb4i(ahere,jc,jd)=0.0_KR

		      if (bt/=0) then
			  at=ittt-bt
			  at=mod(at-1+nt,nt)+1
			  ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                          sb6r(ahere,jc,jd)=0.0_KR
                          sb6i(ahere,jc,jd)=0.0_KR
			  sb4r(ahere,jc,jd)=0.0_KR
			  sb4i(ahere,jc,jd)=0.0_KR
		      end if ! bt/=0

		   end do ! bz
	        end do ! by
             end do ! bx


             md=3

	     do bx=-md,md
		do by=-(md-abs(bx)),md-abs(bx)
		   do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
		      bt=md-abs(bx)-abs(by)-abs(bz)

		      ax=ixx+bx
	              ay=iyy+by
	              az=izz+bz
		      at=ittt+bt

		      ax=mod(ax-1+nx,nx)+1
	              ay=mod(ay-1+ny,ny)+1
		      az=mod(az-1+nz,nz)+1
	              at=mod(at-1+nt,nt)+1

		      ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
		      sb3r(ahere,jc,jd)=0.0_KR
	              sb3i(ahere,jc,jd)=0.0_KR
                      sb5r(ahere,jc,jd)=0.0_KR
                      sb5i(ahere,jc,jd)=0.0_KR


	              if (bt/=0) then
			  at=ittt-bt
			  at=mod(at-1+nt,nt)+1
			  ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
			  sb3r(ahere,jc,jd)=0.0_KR                                                      
			  sb3i(ahere,jc,jd)=0.0_KR
                          sb5r(ahere,jc,jd)=0.0_KR                                                      
                          sb5i(ahere,jc,jd)=0.0_KR
		      end if

                   end do ! bz
		end do ! by
             end do ! bx

             md=2

	     do bx=-md,md
		do by=-(md-abs(bx)),md-abs(bx)
		   do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
	              do bt=-(md-abs(bx)-abs(by)-abs(bz)),md-abs(bx)-abs(by)-abs(bz)

			 ax=ixx+bx
			 ay=iyy+by
			 az=izz+bz
			 at=ittt+bt

			 ax=mod(ax-1+nx,nx)+1
			 ay=mod(ay-1+ny,ny)+1
			 az=mod(az-1+nz,nz)+1
			 at=mod(at-1+nt,nt)+1

			 ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
			 sb1r(ahere,jc,jd)=0.0_KR
			 sb1i(ahere,jc,jd)=0.0_KR
			 sb2r(ahere,jc,jd)=0.0_KR
			 sb2i(ahere,jc,jd)=0.0_KR
			 sb3r(ahere,jc,jd)=0.0_KR
			 sb3i(ahere,jc,jd)=0.0_KR
			 sb4r(ahere,jc,jd)=0.0_KR
			 sb4i(ahere,jc,jd)=0.0_KR
                         sb5r(ahere,jc,jd)=0.0_KR
                         sb5i(ahere,jc,jd)=0.0_KR
                         sb6r(ahere,jc,jd)=0.0_KR
                         sb6i(ahere,jc,jd)=0.0_KR

	              end do ! bt
		   end do ! bz
		end do ! by
	     end do ! bx

          end do ! jc
       end do ! jd

! This is the end of the big loops over the intial lattice point.

! Dean - make sure you colon out idirac on z2 now

       z2(ihere,icolor,idirac) = 0.0_KR ! This is for the Wilson case.
       z3(ihere,icolor,:) = 0.0_KR

                          enddo ! icolor
         	      enddo ! idirac
                  endif ! mod(numprocs)
	      enddo ! ixx
          enddo ! iyy
      enddo ! izz
  enddo ! ittt

	    
!
! Need to put the operators in Jvev to be passed into average..
! Dean - Need to save BOTH levels of VEVs for each of these
! 10 operators.


  do ittt = 1,nt
     if (nsub==4) then
         do imom=1,nmom
            Jvevtemp(1,ittt,4,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,6) = opertemp(12,ittt,imom,0)
         enddo ! imom
     elseif (nsub==6) then
! If nsub==6 then we need to have the first non-trival subtraction level
!            (kappa^4) along with the highest order (kappa^6)

         do imom=1,nmom
            Jvevtemp(1,ittt,4,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,4,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,4,imom,6) = opertemp(12,ittt,imom,0)

            Jvevtemp(1,ittt,6,imom,1) = opertemp(1,ittt,imom,1)
            Jvevtemp(2,ittt,6,imom,1) = opertemp(2,ittt,imom,1)
            Jvevtemp(1,ittt,6,imom,2) = opertemp(3,ittt,imom,1)
            Jvevtemp(2,ittt,6,imom,2) = opertemp(4,ittt,imom,1)
            Jvevtemp(1,ittt,6,imom,3) = opertemp(5,ittt,imom,1)
            Jvevtemp(2,ittt,6,imom,3) = opertemp(6,ittt,imom,1)
            Jvevtemp(1,ittt,6,imom,4) = opertemp(7,ittt,imom,1)
            Jvevtemp(2,ittt,6,imom,4) = opertemp(8,ittt,imom,1)
            Jvevtemp(1,ittt,6,imom,5) = opertemp(9,ittt,imom,1)
            Jvevtemp(2,ittt,6,imom,5) = opertemp(10,ittt,imom,1)
            Jvevtemp(1,ittt,6,imom,6) = opertemp(11,ittt,imom,1)
            Jvevtemp(2,ittt,6,imom,6) = opertemp(12,ittt,imom,1)
         enddo ! imom

     endif ! nsub
  enddo ! ittt

  if (nps/=1) then 
      opercount = (nsav*nt*5*2)
      call MPI_REDUCE(opertemp(1,1,1,0),oper(1,1,1,0),opercount,MRT,MPI_SUM,&
	              0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xrr2(0),xrr2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xri2(0),xri2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xps2(0),xps2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xpi2(0),xpi2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)

      call MPI_REDUCE(xpsur(0),xpsurtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xpsui(0),xpsuitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)


      call MPI_REDUCE(xsj1pr(0),xsj1prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj1pi(0),xsj1pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj2pr(0),xsj2prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj2pi(0),xsj2pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj3pr(0),xsj3prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj3pi(0),xsj3pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
  else
      oper=opertemp
      xpsurtemp=xpsur
      xpsuitemp=xpsui
      xrr2temp=xrr2
      xri2temp=xri2
      xps2temp=xps2
      xpi2temp=xpi2
      xsj1prtemp=xsj1pr
      xsj1pitemp=xsj1pi
      xsj2prtemp=xsj2pr
      xsj2pitemp=xsj2pi
      xsj3prtemp=xsj3pr
      xsj3pitemp=xsj3pi
  endif ! nps

!     if (myid==0) then
!           open(unit=8,file="TWVEV.LOG", action="write",form="formatted",status="old",position="append")
!           write(unit=8,fmt=*) oper(1,nt,:,1)
!           close(unit=8,status="keep")
!     endif
!      call MPI_BARRIER(MPI_COMM_WORLD,ierr)
!      stop


! This is probably not nesecarry, but I am going to zero out z2 before the subroutine
! exits to make sure that the TM-twist on the ends of the vev propagator are local only
! to this routine.

     z2 = 0.0_KR


! Write out results at the end.

 if (.false.) then
  if (myid==0) then
      op = 0.0_KR
      xnl=dble(nxyzt)

      do isb=0,1
         op(1,isb)=xkappa*xrr2temp(isb)/xnl
         op(2,isb)=xkappa*xri2temp(isb)/xnl
         op(3,isb)=xps2temp(isb)/xnl
	 op(4,isb)=xpi2temp(isb)/xnl
	 op(5,isb)=xkappa*xsj1prtemp(isb)/xnl
         op(6,isb)=xkappa*xsj1pitemp(isb)/xnl
         op(7,isb)=xkappa*xsj2prtemp(isb)/xnl
         op(8,isb)=xkappa*xsj2pitemp(isb)/xnl
         op(9,isb)=xkappa*xsj3prtemp(isb)/xnl
         op(10,isb)=xkappa*xsj3pitemp(isb)/xnl
         op(11,isb)=xpsurtemp(isb)/xnl
         op(12,isb)=xpsuitemp(isb)/xnl
      enddo ! isb
      if(myid==0) write(unit=8,fmt=*) "psibar-psi=", op(3,0)

!
 1205  format(///)
 1206  format(i6,d24.10,' +-',d24.10)
!1207  format(e24.10)
!
       oa(:,:)=0.0_KR
       oe(:,:)=0.0_KR
!
       oa(:,0)=oa(:,0)+op(:,0)
       oa(:,1)=oa(:,1)+op(:,0)+op(:,1)
!
!      open(7,file=sfile,form='formatted',status='new')
!      do 202 iop=1,nsav
!     do 202 isb=0,3
!     write(7,1207) oa(iop,isb)
! 202  continue
!
       write(6,*) 'isb=0 quantities'
       write(6,1205)

       do iop=1,nsav
         write(6,1206) iop,oa(iop,0),oe(iop,0)
       enddo ! iop
!
       write(6,1205)
       write(6,*) 'isb=1 quantities'
       write(6,1205)

       do iop=1,nsav
         write(6,1206) iop,oa(iop,1),oe(iop,1)
       enddo ! iop
!
!      write(6,*) 'isb=2 quantities'
!      write(6,1205)
!      do iop=1,nsav
!        write(6,1206) iop,oa(iop,2),oe(iop,2)
!      enddo ! iop
!
!      write(6,1205)
!      write(6,*) 'isb=3 quantities'
!      write(6,1205)

!      do iop=1,nsav
!        write(6,1206) iop,oa(iop,3),oe(iop,3)
!      enddo ! iop


!     write(6,*) 'near oabs'
!     New stuff from zzing.f

       do isb=0,1
         do ix=1,5
           do itr=1,nt
             do iop=1,nsav
               oab(iop,itr,ix,isb)=0.0_KR
               oeb(iop,itr,ix,isb)=0.0_KR
             enddo ! iop
           enddo ! itr
         enddo ! ix
       enddo ! isb
!
       do ix=1,5
         do itr=1,nt
           do iop=1,nsav
             oab(iop,itr,ix,0)=oab(iop,itr,ix,0)+&
                               oper(iop,itr,ix,0)
             oab(iop,itr,ix,1)=oab(iop,itr,ix,1)+&
                               oper(iop,itr,ix,0)+oper(iop,itr,ix,1)
           enddo ! iop
         enddo ! itr
       enddo ! ix


!

 1209  format(3i6,d24.10,' +-',d24.10)

       xnl=dble(nxyz)
       write(6,*) 'isb=3,4 quantities'
       write(6,1205)

       do ix=1,5
         do itr=1,nt
           do i=1,2
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,0)/xnl,&
                           oeb(i,itr,ix,0)/xnl
           end do ! i
           do i=3,4
             write(6,1209) i,itr,ix,oab(i,itr,ix,0)/xnl, &
                           oeb(i,itr,ix,0)/xnl
           end do ! i
           do i=5,10
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,0)/xnl,&
                           oeb(i,itr,ix,0)/xnl
           end do ! i
         enddo ! itr
       enddo ! ix

       write(6,*) 'isb=5,6 quantities'
       write(6,1205)

       do ix=1,5
         do itr=1,nt
           do i=1,2
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
           end do ! i
           do i=3,4
             write(6,1209) i,itr,ix,oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
           end do ! i
           do i=5,10
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
           end do ! i
         enddo ! itr
       enddo ! ix


      write(6,*) 'peace out-test'

!

  endif ! myid
 endif ! .false.

  if (nps/=1) then 

      Jvevcount = (2*nt*6*nmom*nop)
      call MPI_REDUCE(Jvevtemp(1,1,1,1,1),Jvev(1,1,1,1,1),Jvevcount,MRT,MPI_SUM,&
                      0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(Jvev(1,1,1,1,1),Jvevcount,MRT,0,MPI_COMM_WORLD,ierr)
  else
      Jvev=Jvevtemp
  endif ! nps

  if(myid==0) close(unit=8,status="keep")

  deallocate(ffac)
  deallocate(fas1)
  deallocate(fas2)
  deallocate(fas3)

! deallocate(uss)
! deallocate(usp)
  deallocate(z2i)
  deallocate(z3i)

! call deallocateus

  deallocate(utemp)
  deallocate(uss)
  deallocate(usp)


  end Subroutine twvev

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!
!
  Subroutine twAverage(Jvev,be,bo,xe,xo,delta,io,kappa,&
                       upart,dobndry,numprocs,MRT,myid,&
                       nsub,nmom,nop,noisenum,shiftnum,&
                       ntmqcd, rwdir, ir)

  use input2
  use input5b
  use seed
! use sub
  use operator

! use input1
! use gaugelinks

!  xe() and xo() contain the "raw" propagator for the disconnected valence quarks.

  real(kind=KR),    intent(out),    dimension(2,nt,6,nmom,nop)            :: Jvev
  real(kind=KR),    intent(inout),  dimension(18,ntotal,4,2,16)           :: upart
  real(kind=KR),    intent(inout),  dimension(6,ntotal,4,2,8)             :: be,bo

  character(len=*), intent(in),     dimension(:)                          :: rwdir
  integer(kind=KI), intent(in)                                            :: nsub,nmom,nop
  real(kind=KR),    intent(inout),     dimension(6,ntotal,4,2,8,1)        :: xe
  real(kind=KR),    intent(inout),     dimension(6,nvhalf,4,2,8,1)        :: xo
  integer(kind=KI), intent(in),     dimension(3)                          :: io
  real(kind=KR),    intent(in)                                            :: kappa
  real(kind=KR),    intent(in)                                            :: delta
  integer(kind=KI), intent(in)                                            :: dobndry
  integer(kind=KI), intent(in)                                            :: noisenum
  integer(kind=KI), intent(in)                                            :: shiftnum, ntmqcd
  integer(kind=KI), intent(in)                                            :: MRT
  integer(kind=KI), intent(in)                                            :: numprocs, myid, ir

!  real(kind=KR),                    dimension(18,ntotal,4,2,16)           :: utemp
  real(kind=KR),allocatable,        dimension(:,:,:,:,:)           :: utemp
  real(kind=KR)                                                           :: xkappa
  integer(kind=KI),                 dimension(1)                          :: bufsizes
  integer(kind=KI)                                                        :: rank
  integer(kind=KI),                 dimension(9)                          :: imv
  integer(kind=KI)                                                        :: kc,kd
  real(kind=KR),                    dimension(2,nt,6,nmom,nop) :: Jvevtemp
  real(kind=KR),                    dimension(0:3)                        :: xrr2,xri2,xps2,&
                                                                             xpi2,xsj1pr,xsj1pi,&
                                                                             xsj2pr,xsj2pi,xsj3pr,&
                                                                             xsj3pi,xpsur,xpsui
  real(kind=KR),                    dimension(0:3)                        :: xrr2temp,xri2temp,xps2temp,&
                                                                             xpi2temp,xsj1prtemp,xsj1pitemp,&
                                                                             xsj2prtemp,xsj2pitemp,xsj3prtemp,&
                                                                             xsj3pitemp,xpsurtemp,xpsuitemp

  real(kind=KR), allocatable,       dimension(:,:,:)                      :: z2i,z3i
  real(kind=KR), allocatable,       dimension(:,:,:)                      :: z2noise,z2inoise

  real(kind=KR), allocatable,       dimension(:,:,:,:)                    :: rpropagator,ipropagator

  real(kind=KR),                    dimension(2)                          :: sbr,sbi
  real(kind=KR),                    dimension(nxyzt)                      :: s0,s1,sprop,pscalar
  real(kind=KR),                    dimension(nsav,0:3)                   :: op,oa,oe
  real(kind=KR),                    dimension(nsav,nt,5,0:2)              :: oper,oab,oeb,opertemp
  real(kind=KR), allocatable,       dimension(:,:)                        :: ffac,fas1,fas2,fas3
  real(kind=KR),                    dimension(6)                          :: xk
  real(kind=KR)                                                           :: pmom1,pmom2,pmom3
  real(kind=KR)                                                           :: dx,dy,dz
  real(kind=KR)                                                           :: xnl
!  character(len=8)                                                        :: sfile
  integer(kind=KI)                                                        :: itr,itimz,imom
  integer(kind=KI)                                                        :: ihere,leftx,rightx,lefty,righty,&
                                                                             leftz,rightz,leftt,rightt,&
                                                                             ahere,ax,ay,az,at,md,&
                                                                             bx,by,bz,bt,proc
  integer(kind=KI)                                                        :: isx,isy,isz
  integer(kind=KI)                                                        :: ixx,iyy,izz,ittt
  integer(kind=KI)                                                        :: iy,iz,it,ixyzt
  integer(kind=KI)                                                        :: tempx,tempy,tempz,temptplus,&
                                                                             temptminus
  integer(kind=KI)                                                        :: isb,isp
  integer(kind=KI)                                                        :: im,imm,iop,ix,i
  integer(kind=KI)                                                        :: counter
  integer(kind=KI)                                                        :: idirac,icolor,jc,jd,jri,is
  integer(kind=KI)                                                        :: type
  logical                                                                 :: fixbc
  logical                                                                 :: true,false
  integer(kind=KI)                                                        :: iblock,ieo,j,&
                                                                             kc1,kc2,isite,ixyz,site,inps
  integer(kind=KI)                                                        :: ieo1,ieo2,itbit,itbit2,&
                                                                             ixbit,ixbit2,ixbit3,&
                                                                             iybit,iybit2,izbit,izbit2,&
                                                                             iblbit, ibleo
  integer(kind=KI)                                                        :: ierr 
  integer(kind=KI)                                                        :: opercount,Jvevcount,count
  integer(kind=KI),                 dimension(4)                          :: np,ip
  real(kind=KR), allocatable,       dimension(:,:,:,:,:)                  :: uss 
  real(kind=KR), allocatable,       dimension(:,:,:,:)                    :: usp 
!    real(kind=KR),        dimension(nxyzt,3,2,nc,nc)                   :: uss
!    real(kind=KR),        dimension(nxyzt,2,nc,nc)                     :: usp

  !real(kind=KR),                    dimension(9,ntotal,3,2,16)            :: rtempuss, itempuss
 ! real(kind=KR),                    dimension(9,ntotal,1,2,16)            :: rtempusp, itempusp

  integer(kind=KI)                                                        :: number,l,m,k,ipos,icolor1,icolor2
  integer(kind=KI)                                                        :: ltime,utime,usub

!  real(kind=KR),                    dimension(nxyzt,nc,nd)                :: ssb0r, ssb0i, ssb1r,ssb1i,ssb2r,ssb2i,&
!                                                                             ssb3r,ssb3i,ssb4r,ssb4i,&
!                                                                             ssb5r,ssb5i,ssb6r,ssb6i, total

  real(kind=KR), allocatable, dimension(:,:,:)                             :: ssb0r, ssb0i, ssb1r,ssb1i,ssb2r,ssb2i,&
                                                                             ssb3r,ssb3i,ssb4r,ssb4i,&
                                                                             ssb5r,ssb5i,ssb6r,ssb6i, total
! No more subs!!
! real(kind=KR),                    dimension(nxyzt,nc,nd)                :: z2sub, sub3r, sub3i, sub4r, sub4i,&
!                                                                            sub5r, sub5i, sub6r, sub6i 
  real(kind=KR),                    dimension(nxyzt,nc,nd)                :: z2sub

  integer(kind=KI)                                                        :: ic, id, index
  integer(kind=KI),                 dimension(4)                          :: cd, sign
  real(kind=KR)                                                           :: fac, xxr, xxi 
  real(kind=KR), dimension(0:3) :: whatever,ever
  real(kind=KR), dimension(nt,0:1):: ever2


 if(myid==0) print *, "Inside twAverage"

  allocate(ssb0r(nxyzt,nc,nd))
  allocate(ssb0i(nxyzt,nc,nd))
  allocate(ssb1r(nxyzt,nc,nd))
  allocate(ssb1i(nxyzt,nc,nd))
  allocate(ssb2r(nxyzt,nc,nd))
  allocate(ssb2i(nxyzt,nc,nd))
  allocate(ssb3r(nxyzt,nc,nd))
  allocate(ssb3i(nxyzt,nc,nd))
  allocate(ssb4r(nxyzt,nc,nd))
  allocate(ssb4i(nxyzt,nc,nd))
  allocate(ssb5r(nxyzt,nc,nd))
  allocate(ssb5i(nxyzt,nc,nd))
  allocate(ssb6r(nxyzt,nc,nd))
  allocate(ssb6i(nxyzt,nc,nd))
  allocate(total(nxyzt,nc,nd))



  allocate(utemp(18,ntotal,4,2,16))
  allocate(uss(nxyzt,3,2,nc,nc))
  allocate(usp(nxyzt,2,nc,nc))




  ever=0.0_KR
  ever2=0.0_KR
  whatever=0.0_KR
!
! This subroutine is in directory ./qqcd/cfgsprops/quark/common. It
! allocates memory for the unit vector z2.

  call allocatez2
  call allocatesubs
! call allocateus

! Variables that don't occur often are allocated/deallocated locally.

! NOTE~ some of the variables are not dealloacted. This is to save time
!       in the overall program runtime. Variables that are going to be needed
!       many times are left in the heap an not deallocated and then realloacted.
!       (you may see this structure in the above subroutines)

  allocate(ffac(nxyzt,4))
  allocate(fas1(nxyzt,4))
  allocate(fas2(nxyzt,4))
  allocate(fas3(nxyzt,4))

! allocate(uss(nxyzt,3,nri,nc,nc))
! allocate(usp(nxyzt,nri,nc,nc))

  allocate(rpropagator(nxyzt,nc,nd,1))
  allocate(ipropagator(nxyzt,nc,nd,1))

  allocate(z2i(nxyzt,nc,nd))
  allocate(z3i(nxyzt,nc,nd))
  allocate(z2noise(nxyzt,nc,nd))
  allocate(z2inoise(nxyzt,nc,nd))


     !if(myid==0) print *, "After making the ncessary allocations"

  ffac = 0.0_KR
  fas1 = 0.0_KR
  fas2 = 0.0_KR
  fas3 = 0.0_KR
  opertemp=0.0_KR
  xrr2=0.0_KR
  xri2=0.0_KR
  xps2=0.0_KR
  xpi2=0.0_KR
  xpsur=0.0_KR
  xpsui=0.0_KR
  xsj1pr=0.0_KR
  xsj1pi=0.0_KR
  xsj2pr=0.0_KR
  xsj2pi=0.0_KR
  xsj3pr=0.0_KR
  xsj3pi=0.0_KR
  xrr2temp=0.0_KR
  xri2temp=0.0_KR
  xps2temp=0.0_KR
  xpi2temp=0.0_KR
  xpsurtemp=0.0_KR
  xpsuitemp=0.0_KR
  xsj1prtemp=0.0_KR
  xsj1pitemp=0.0_KR
  xsj2prtemp=0.0_KR
  xsj2pitemp=0.0_KR
  xsj3prtemp=0.0_KR
  xsj3pitemp=0.0_KR

! Zero out the operators that are passed out to the discon-loop program

  Jvev = 0.0_KR
  Jvevtemp=0.0_KR

!  open(unit=8,file="TWVEV.LOG", action="write",form="formatted",status="old",position="append")
   if(myid==0) then
     open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",action="write",&
        form="formatted",position="append",status="old")
     close(unit=8,status="keep")
   endif


! Initializations for the gamma5 matrix multiplcation for the pseudo-scalar
  cd(1:4)   = (/ 3, 4, 1, 2 /)
  sign(1:4) = (/ 1, 1, -1, -1 /)

!     Determine boundry conditions depending on the value of dobndry

  if (dobndry==1) then
      fixbc=.true.
  else
      fixbc=.false.
  endif ! dobndry

!     Set up quantities needed for momentum analysis.
!     Need to define lowest momentum in each lattice direction for anisotropic lattice

  pmom1=8.0_KR*atan(1.0_KR)/nx
  pmom2=8.0_KR*atan(1.0_KR)/ny
  pmom3=8.0_KR*atan(1.0_KR)/nz

  do itr=1,nt
     itimz=(itr-1)*nxyz
     do isz=1,nz
        dz=dble(isz-io(3))*pmom3
        do isy=1,ny
           dy=dble(isy-io(2))*pmom2
           do isx=1,nx
              dx=dble(isx-io(1))*pmom1

              isp=isx+(isy-1)*nx+(isz-1)*nx*ny+itimz

              ffac(isp,1)=(cos(dx)+cos(dy)+cos(dz))/3.0_KR
              fas1(isp,1)=sin(dx)
              fas2(isp,1)=sin(dy)
              fas3(isp,1)=sin(dz)

              ffac(isp,2)=(cos(dx)*cos(dy)+cos(dx)*cos(dz)+cos(dy)*cos(dz))/3.0_KR
              fas1(isp,2)=sin(dx)*(cos(dy)+cos(dz))/2.0_KR
              fas2(isp,2)=sin(dy)*(cos(dx)+cos(dz))/2.0_KR
              fas3(isp,2)=sin(dz)*(cos(dx)+cos(dy))/2.0_KR

              ffac(isp,3)=cos(dx)*cos(dy)*cos(dz)
              fas1(isp,3)=sin(dx)*cos(dy)*cos(dz)
              fas2(isp,3)=sin(dy)*cos(dx)*cos(dz)
              fas3(isp,3)=sin(dz)*cos(dx)*cos(dy)

              ffac(isp,4)=(cos(2.0_KR*dx)+cos(2.0_KR*dy)+cos(2.0_KR*dz))/3.0_KR
              fas1(isp,4)=sin(2.0_KR*dx)
              fas2(isp,4)=sin(2.0_KR*dy)
              fas3(isp,4)=sin(2.0_KR*dz)

           enddo ! isx
        enddo ! isy
     enddo ! isz
  enddo ! itr

!     if (nps/=1) then
!       count=(nxyzt*4)
!       call MPI_BCAST(ffac(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!       call MPI_BCAST(fas1(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!       call MPI_BCAST(fas2(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!       call MPI_BCAST(fas3(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!     endif ! nps

  z2=0.0_KR
  z2i=0.0_KR
  z3=0.0_KR
  z3i=0.0_KR
! evenz2=0.0_KR
! oddz2=0.0_KR
  z2noise=0.0_KR
  z2inoise=0.0_KR

  sb1r=0.0_KR
  sb1i=0.0_KR
  sb2r=0.0_KR
  sb2i=0.0_KR
  sb3r=0.0_KR
  sb3i=0.0_KR
  sb4r=0.0_KR
  sb4i=0.0_KR
  sb5r=0.0_KR
  sb5i=0.0_KR
  sb6r=0.0_KR
  sb6i=0.0_KR

  ssb0r=0.0_KR
  ssb0i=0.0_KR
  ssb1r=0.0_KR
  ssb1i=0.0_KR
  ssb2r=0.0_KR
  ssb2i=0.0_KR
  ssb3r=0.0_KR
  ssb3i=0.0_KR
  ssb4r=0.0_KR
  ssb4i=0.0_KR
  ssb5r=0.0_KR
  ssb5i=0.0_KR
  ssb6r=0.0_KR
  ssb6i=0.0_KR

! These arrays are for the psuedoscalar
  z2sub = 0.0_KR 
! sub3r = 0.0_KR
! sub3i = 0.0_KR
! sub4r = 0.0_KR
! sub4i = 0.0_KR
! sub5r = 0.0_KR
! sub5i = 0.0_KR
! sub6r = 0.0_KR
! sub6i = 0.0_KR


!     Identify the location of my process
!     The main loop over all lattice sites and dirac and color indices

  call utouss(upart,uss,usp,numprocs,MRT,myid)


! NOTE~ The  subrouitne UINIT is used for debugging only. It allows specific creation
!       of simple gagauelinks. To execute UINIT, set the logical in the if statement
!       below to .true. (Should comment out subroutine utouss for effeciency)

  if (.false.) then
     call UINIT(usp,uss,fixbc,rwdir,myid)
  endif ! .false.

! Zero out the time edge for process zero before bcast to 
! MPI_COMM_WORLD.

! call printlog("Took out usp=0 in AVE!!",myid,rwdir)
! if (.false.) then
    if (fixbc) then
     if (myid==0) then
      do izz = 1,nz
         do iyy = 1,ny
            do ixx = 1,nx
               ipos = ixx + nx*(iyy-1) + nx*ny*(izz-1) + nx*ny*nz*(nt-1)
               do icolor1 = 1,nc
                  do icolor2 = 1,nc
                     usp(ipos,:,icolor1,icolor2)= 0.0_KR
                  enddo ! icolor2
               enddo ! icolor1
            enddo ! ixx
         enddo ! iyy
      enddo ! izz
    endif ! myid
  endif ! fixbc
!endif ! .false.

  if (nps/=1) then
      count=(nxyzt*3*nri*nc*nc)
      call MPI_BCAST(uss(1,1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
      count=(nxyzt*nri*nc*nc)
      call MPI_BCAST(usp(1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
  endif ! nps

! For the subroutine twaverage we must use the input vector of random z2 noise
!     instead of the unit vector z2 above.

  call changenoise(z2noise,z2inoise,be,bo,numprocs,MRT,myid)
  if(myid==0) call printlog("exiting changenoise", myid,rwdir)

  if (nps/=1) then
      count = nxyzt*nc*nd
      call MPI_BCAST(z2noise(1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
  endif ! nps

! For the subroutine twaverage we must change the input propagators to
! fit our program and then use them to determine the correct additions
! to the main signal.

! ATTENTION :: To keep the normalizations correct between the non-perturbative
!              propagator we need to multiply the incoming xe and xo solutions
!              by kappa**2. This will make the diagnoal term of the e/o propagator
!              1.
  
 
! ABDOU ~ need to change the last index on xe, xo so that they can be multi-massed.
!         Also, this routine takes substaintial computer time. There are two choices....
!         loop over the routine (slower but easier) or do it internally (harder put potentially faster)

  call changevector(rpropagator(:,:,:,1), ipropagator(:,:,:,1),xe(:,:,:,:,:,1),xo(:,:,:,:,:,1),numprocs,MRT,myid)
  if(myid==0) call printlog("exiting changevector", myid,rwdir)

  if (nps/=1) then
      count = nxyzt*nc*nd*1
      call MPI_BCAST(rpropagator(1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(ipropagator(1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
  endif ! nps

! Entering the loops over all spatial lattice points.

! do is = 1,nshifts

  cosd=cos(delta)
  sind=sin(delta)
  if (myid.eq.0) print *,'HERE IS DELTA2',delta
! stop

  xkappa=kappa*cosd

! ABDOU ~ Change these kappa values the same as in sburoutine twvev.

  xk(1)=xkappa
  xk(2)=xkappa**2
  xk(3)=xkappa**3
  xk(4)=xkappa**4
  xk(5)=xkappa**5
  xk(6)=xkappa**6


! WARNING WARNING WARNING WARNING WARNING WARNING
! We have restricted the time steps in the perturbative
! construction of the vev's in order to save time 7-16-05.

  ltime=1
  utime=nt

! Temp. false out of the perturbative part, which doesn't help
! with twisted scalar and pseudoscalar vevs.

if (.false.) then

  if (nsub/=0) then
      do ittt=ltime,utime
         do izz=1,nz
            do iyy=1,ny
               do ixx=1,nx
! Temp. changes
!     do ittt=4,4
!        do izz=1,1
!           do iyy=1,1
!              do ixx=1,1

!     A single index is used to specify a point in the lattice.
!     The mapping from a lattice site (x,y,z,t) to this single index is
!     index=x+(y-1)*nx+(z-1)*nx*ny+(t-1)*nx*ny*nz
!     "ihere" is the current lattice site from the main loop.

!     The "z2" array is zero everywhere (space-time) except at the current iteration
!     of the main loop.

                  ihere = ixx + nx*(iyy-1) + nx*ny*(izz-1) + nx*ny*nz*(ittt-1)
                  if (mod(ihere-1,numprocs) == myid) then


!     Multipication of overall cos(delta) done at intilization of input vector.
                  do idirac=1,nd
                     do icolor=1,nc
                        z2(ihere,icolor,idirac) = z2noise(ihere,icolor,idirac)
                        z3(ihere,icolor,idirac) = cosd*z2(ihere,icolor,idirac)
                     enddo ! icolor
                  enddo ! idirac

! I am getting rid of the initial rotation at the beginning.
! It is correct to actually do it at the end with the present
! version of GammaMultiply. -WW

if(.false.) then
                  do jc = 1,nc
                     sbr(1) = z3(ihere,jc,1)
                     sbr(2) = z3(ihere,jc,2)

                     z3(ihere,jc,1) = cosd*z3(ihere,jc,1) - sind*z3(ihere,jc,3)
                     z3(ihere,jc,2) = cosd*z3(ihere,jc,2) - sind*z3(ihere,jc,4)
                     z3(ihere,jc,3) = cosd*z3(ihere,jc,3) + sind*sbr(1)
                     z3(ihere,jc,4) = cosd*z3(ihere,jc,4) + sind*sbr(2)
                 enddo ! jc
endif ! false

!     The "sb*" arrays are now reset to zero in a more efficient way
!     at the end of the main loop.

!     This section is to do the first order subtraction from
!     the quark propagator.

!     The "Multiply" subroutine generates the next subtraction level
!     from the last one.
!     At first order, "sb1r" and "sb1i" are generated from "z2" and "z2i".
!     "Multiply" actually computes the effect that one element of "z2" and
!     "z2i" has on "sb1r" and "sb1i".  Thus, "Multiply" must be called
!     once for every nonzero point of "z2" and "z2i".

     Call GammaMultiply(sb1r,sb1i,z3,z3i,ixx,iyy,izz,&
                   ittt,usp,uss,fixbc,ir,myid)


!
!     Do second order
!
  md=1

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

            Call GammaMultiply(sb2r,sb2i,sb1r,sb1i,tempx,tempy,tempz,&
                        temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt
               Call GammaMultiply(sb2r,sb2i,sb1r,sb1i,tempx,tempy,tempz,&
                                   temptminus,usp,uss,fixbc,ir,myid)
           end if ! bt/=0

        end do ! bz
     end do ! by
  end do ! bx


!     Do third order

      Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,ixx,iyy,izz,&
                          ittt,usp,uss,fixbc,ir,myid)

  md=2

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! bt/=0
        end do ! bz
     end do ! by
  end do ! bx


!     Do fourth order


  md=1

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order terms have been removed for
! nsub==4. In addition, I am removing the md=3 part of 4th order.
! This will make only a partial subtraction on the noise for
! vectors, but not affect the subtraction to this order for the scalar.
! Done to save time before Dublin conference. 7-16-05

!         if(nsub==6) then

  md=3

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order terms have been removed for
! nsub==4.
! Done to save time before Dublin conference. 7-16-05

  if (nsub==6) then

!     Do fifth order (all points now)

      Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,ixx,iyy,izz,&
                              ittt,usp,uss,fixbc,ir,myid)

  md=2

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! This is an extension of the fifth order subtraction.

  md=4

  do bx=-md,md
     do by= -(md-abs(bx)),md-abs(bx)
        do bz= -(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx


!     Do sixth order (all points)

  md=1

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! This is an extension to sixth order.

  md=3

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

  md=5

   do bx=-md,md
     do by= -(md-abs(bx)),md-abs(bx)
        do bz= -(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

  endif ! nsub==6


! ####################################################################

! This is the end


  do jd=1,nd
     do jc=1,nc

        if (nsub==6) then

            md=6
            do bx=-md,md
               do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1

                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                     ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                     sb6r(ahere,jc,jd)=0.0_KR
                     sb6i(ahere,jc,jd)=0.0_KR
                     if (bt/=0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                         ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                         sb6r(ahere,jc,jd)=0.0_KR
                         sb6i(ahere,jc,jd)=0.0_KR
                     end if ! (bt/=0)
                  end do ! bz
               end do ! by
            end do ! bx

            md=5
            do bx=-md,md
               do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1

                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                     ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                     sb5r(ahere,jc,jd)=0.0_KR
                     sb5i(ahere,jc,jd)=0.0_KR
                     if (bt/=0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                         ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                         sb5r(ahere,jc,jd)=0.0_KR
                         sb5i(ahere,jc,jd)=0.0_KR
                     end if ! (bt/=0)
                  end do ! bz
               end do ! by
            end do ! bx

            md=4
            do bx=-md,md
               do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1


                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                     ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                     ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                     ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                     sb6r(ahere,jc,jd)=0.0_KR
                     sb6i(ahere,jc,jd)=0.0_KR
                     sb4r(ahere,jc,jd)=0.0_KR
                     sb4i(ahere,jc,jd)=0.0_KR
                     if (bt/=0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                         ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                         ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                         ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                         sb6r(ahere,jc,jd)=0.0_KR
                         sb6i(ahere,jc,jd)=0.0_KR
                         sb4r(ahere,jc,jd)=0.0_KR
                         sb4i(ahere,jc,jd)=0.0_KR
                     end if ! (bt/=0)
                  end do ! bz
               end do ! by
            end do ! bx

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order zeroing has been commented out below for
! nsub==4. For nsub==6 you need to put back these values!

       endif ! nsub==6

       md=3
       do bx=-md,md
          do by=-(md-abs(bx)),md-abs(bx)
              do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                 bt=md-abs(bx)-abs(by)-abs(bz)

                 ax=ixx+bx
                 ay=iyy+by
                 az=izz+bz
                 at=ittt+bt

                 ax=mod(ax-1+nx,nx)+1
                 ay=mod(ay-1+ny,ny)+1
                 az=mod(az-1+nz,nz)+1
                 at=mod(at-1+nt,nt)+1


                 ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                 ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                 ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                 ssb3r(ahere,jc,jd)=ssb3r(ahere,jc,jd)+sb3r(ahere,jc,jd)
                 ssb3i(ahere,jc,jd)=ssb3i(ahere,jc,jd)+sb3i(ahere,jc,jd)

                 sb5r(ahere,jc,jd)=0.0_KR
                 sb5i(ahere,jc,jd)=0.0_KR
                 sb3r(ahere,jc,jd)=0.0_KR
                 sb3i(ahere,jc,jd)=0.0_KR

                 if (bt/=0) then
                     at=ittt-bt
                     at=mod(at-1+nt,nt)+1
                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                     ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                     ssb3r(ahere,jc,jd)=ssb3r(ahere,jc,jd)+sb3r(ahere,jc,jd)
                     ssb3i(ahere,jc,jd)=ssb3i(ahere,jc,jd)+sb3i(ahere,jc,jd)

                     sb5r(ahere,jc,jd)=0.0_KR
                     sb5i(ahere,jc,jd)=0.0_KR
                     sb3r(ahere,jc,jd)=0.0_KR
                     sb3i(ahere,jc,jd)=0.0_KR

                 end if ! (bt/=0)
              end do ! bz
           end do ! by
        end do ! bx

        md=2
        do bx=-md,md
           do by=-(md-abs(bx)),md-abs(bx)
              do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                 bt=md-abs(bx)-abs(by)-abs(bz)
                !do bt=-(md-abs(bx)-abs(by)-abs(bz)),md-abs(bx)-abs(by)-abs(bz)

                    ax=ixx+bx
                    ay=iyy+by
                    az=izz+bz
                    at=ittt+bt

                    ax=mod(ax-1+nx,nx)+1
                    ay=mod(ay-1+ny,ny)+1
                    az=mod(az-1+nz,nz)+1
                    at=mod(at-1+nt,nt)+1

                    ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

                    ssb2r(ahere,jc,jd)=ssb2r(ahere,jc,jd)+sb2r(ahere,jc,jd)
                    ssb2i(ahere,jc,jd)=ssb2i(ahere,jc,jd)+sb2i(ahere,jc,jd)
                    ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                    ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                    ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                    ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)

                    sb2r(ahere,jc,jd)=0.0_KR
                    sb2i(ahere,jc,jd)=0.0_KR
                    sb4r(ahere,jc,jd)=0.0_KR
                    sb4i(ahere,jc,jd)=0.0_KR
                    sb6r(ahere,jc,jd)=0.0_KR
                    sb6i(ahere,jc,jd)=0.0_KR

                 if (bt/=0) then
                    at=ittt-bt
                    at=mod(at-1+nt,nt)+1
                    ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

                    ssb2r(ahere,jc,jd)=ssb2r(ahere,jc,jd)+sb2r(ahere,jc,jd)
                    ssb2i(ahere,jc,jd)=ssb2i(ahere,jc,jd)+sb2i(ahere,jc,jd)
                    ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                    ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                    ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                    ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)

                    sb2r(ahere,jc,jd)=0.0_KR
                    sb2i(ahere,jc,jd)=0.0_KR
                    sb4r(ahere,jc,jd)=0.0_KR
                    sb4i(ahere,jc,jd)=0.0_KR
                    sb6r(ahere,jc,jd)=0.0_KR
                    sb6i(ahere,jc,jd)=0.0_KR

                 end if ! (bt/=0)

                !end do ! bt
              end do ! bz
           end do ! by
        end do ! bx


        md=1
        do bx=-md,md
           do by=-(md-abs(bx)),md-abs(bx)
              do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                 do bt=-(md-abs(bx)-abs(by)-abs(bz)),md-abs(bx)-abs(by)-abs(bz)

                    ax=ixx+bx
                    ay=iyy+by
                    az=izz+bz
                    at=ittt+bt

                    ax=mod(ax-1+nx,nx)+1
                    ay=mod(ay-1+ny,ny)+1
                    az=mod(az-1+nz,nz)+1
                    at=mod(at-1+nt,nt)+1

                    ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

                    ssb1r(ahere,jc,jd)=ssb1r(ahere,jc,jd)+sb1r(ahere,jc,jd)
                    ssb1i(ahere,jc,jd)=ssb1i(ahere,jc,jd)+sb1i(ahere,jc,jd)
                    ssb3r(ahere,jc,jd)=ssb3r(ahere,jc,jd)+sb3r(ahere,jc,jd)
                    ssb3i(ahere,jc,jd)=ssb3i(ahere,jc,jd)+sb3i(ahere,jc,jd)
                    ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                    ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)

                    sb1r(ahere,jc,jd)=0.0_KR
                    sb1i(ahere,jc,jd)=0.0_KR
                    sb3r(ahere,jc,jd)=0.0_KR
                    sb3i(ahere,jc,jd)=0.0_KR
                    sb5r(ahere,jc,jd)=0.0_KR
                    sb5i(ahere,jc,jd)=0.0_KR

                 end do ! bt
              end do ! bz
           end do ! by
        end do ! bx

! What about md=0?????????????? This would add up contributions
! that get back to the origin, ihere. -WW

!       md=0
        ssb2r(ihere,jc,jd)=ssb2r(ihere,jc,jd)+sb2r(ihere,jc,jd)
        ssb4r(ihere,jc,jd)=ssb4r(ihere,jc,jd)+sb4r(ihere,jc,jd)
        ssb6r(ihere,jc,jd)=ssb6r(ihere,jc,jd)+sb6r(ihere,jc,jd)
        sb2r(ihere,jc,jd) = 0.0_KR
        sb4r(ihere,jc,jd) = 0.0_KR
        sb6r(ihere,jc,jd) = 0.0_KR
        ssb2i(ihere,jc,jd)=ssb2i(ihere,jc,jd)+sb2i(ihere,jc,jd)
        ssb4i(ihere,jc,jd)=ssb4i(ihere,jc,jd)+sb4i(ihere,jc,jd)
        ssb6i(ihere,jc,jd)=ssb6i(ihere,jc,jd)+sb6i(ihere,jc,jd)
        sb2i(ihere,jc,jd) = 0.0_KR
        sb4i(ihere,jc,jd) = 0.0_KR
        sb6i(ihere,jc,jd) = 0.0_KR


     end do ! jc
  end do ! jd


! This is the end of the big loops over the intial lattice point.

              z2(ihere,:,:) = 0.0_KR
              z3(ihere,:,:) = 0.0_KR

              endif ! mod(numprocs) ! PUT THIS IN!!!!!
           enddo ! ixx
        enddo ! iyy
     enddo ! izz
  enddo ! ittt



! This is where I will try putting in the rotations at the end.
! Note all processors are working on their part before the
! data is combined. -WW

                do ihere = 1, nx*ny*nz*nt
                 do jc = 1,nc
! ssb1r,i case
                     sbr(1) = ssb1r(ihere,jc,1)
                     sbr(2) = ssb1r(ihere,jc,2)

                     ssb1r(ihere,jc,1) = cosd*ssb1r(ihere,jc,1) - sind*ssb1r(ihere,jc,3)
                     ssb1r(ihere,jc,2) = cosd*ssb1r(ihere,jc,2) - sind*ssb1r(ihere,jc,4)
                     ssb1r(ihere,jc,3) = cosd*ssb1r(ihere,jc,3) + sind*sbr(1)
                     ssb1r(ihere,jc,4) = cosd*ssb1r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb1i(ihere,jc,1)
                     sbi(2) = ssb1i(ihere,jc,2)

                     ssb1i(ihere,jc,1) = cosd*ssb1i(ihere,jc,1) - sind*ssb1i(ihere,jc,3)
                     ssb1i(ihere,jc,2) = cosd*ssb1i(ihere,jc,2) - sind*ssb1i(ihere,jc,4)
                     ssb1i(ihere,jc,3) = cosd*ssb1i(ihere,jc,3) + sind*sbi(1)
                     ssb1i(ihere,jc,4) = cosd*ssb1i(ihere,jc,4) + sind*sbi(2)

! ssb2r,i case
                     sbr(1) = ssb2r(ihere,jc,1)
                     sbr(2) = ssb2r(ihere,jc,2)

                     ssb2r(ihere,jc,1) = cosd*ssb2r(ihere,jc,1) - sind*ssb2r(ihere,jc,3)
                     ssb2r(ihere,jc,2) = cosd*ssb2r(ihere,jc,2) - sind*ssb2r(ihere,jc,4)
                     ssb2r(ihere,jc,3) = cosd*ssb2r(ihere,jc,3) + sind*sbr(1)
                     ssb2r(ihere,jc,4) = cosd*ssb2r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb2i(ihere,jc,1)
                     sbi(2) = ssb2i(ihere,jc,2)

                     ssb2i(ihere,jc,1) = cosd*ssb2i(ihere,jc,1) - sind*ssb2i(ihere,jc,3)
                     ssb2i(ihere,jc,2) = cosd*ssb2i(ihere,jc,2) - sind*ssb2i(ihere,jc,4)
                     ssb2i(ihere,jc,3) = cosd*ssb2i(ihere,jc,3) + sind*sbi(1)
                     ssb2i(ihere,jc,4) = cosd*ssb2i(ihere,jc,4) + sind*sbi(2)

! ssb3r,i case
                     sbr(1) = ssb3r(ihere,jc,1)
                     sbr(2) = ssb3r(ihere,jc,2)

                     ssb3r(ihere,jc,1) = cosd*ssb3r(ihere,jc,1) - sind*ssb3r(ihere,jc,3)
                     ssb3r(ihere,jc,2) = cosd*ssb3r(ihere,jc,2) - sind*ssb3r(ihere,jc,4)
                     ssb3r(ihere,jc,3) = cosd*ssb3r(ihere,jc,3) + sind*sbr(1)
                     ssb3r(ihere,jc,4) = cosd*ssb3r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb3i(ihere,jc,1)
                     sbi(2) = ssb3i(ihere,jc,2)

                     ssb3i(ihere,jc,1) = cosd*ssb3i(ihere,jc,1) - sind*ssb3i(ihere,jc,3)
                     ssb3i(ihere,jc,2) = cosd*ssb3i(ihere,jc,2) - sind*ssb3i(ihere,jc,4)
                     ssb3i(ihere,jc,3) = cosd*ssb3i(ihere,jc,3) + sind*sbi(1)
                     ssb3i(ihere,jc,4) = cosd*ssb3i(ihere,jc,4) + sind*sbi(2)

! ssb4r,i case
                     sbr(1) = ssb4r(ihere,jc,1)
                     sbr(2) = ssb4r(ihere,jc,2)

                     ssb4r(ihere,jc,1) = cosd*ssb4r(ihere,jc,1) - sind*ssb4r(ihere,jc,3)
                     ssb4r(ihere,jc,2) = cosd*ssb4r(ihere,jc,2) - sind*ssb4r(ihere,jc,4)
                     ssb4r(ihere,jc,3) = cosd*ssb4r(ihere,jc,3) + sind*sbr(1)
                     ssb4r(ihere,jc,4) = cosd*ssb4r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb4i(ihere,jc,1)
                     sbi(2) = ssb4i(ihere,jc,2)

                     ssb4i(ihere,jc,1) = cosd*ssb4i(ihere,jc,1) - sind*ssb4i(ihere,jc,3)
                     ssb4i(ihere,jc,2) = cosd*ssb4i(ihere,jc,2) - sind*ssb4i(ihere,jc,4)
                     ssb4i(ihere,jc,3) = cosd*ssb4i(ihere,jc,3) + sind*sbi(1)
                     ssb4i(ihere,jc,4) = cosd*ssb4i(ihere,jc,4) + sind*sbi(2)

! ssb5r,i case
                     sbr(1) = ssb5r(ihere,jc,1)
                     sbr(2) = ssb5r(ihere,jc,2)

                     ssb5r(ihere,jc,1) = cosd*ssb5r(ihere,jc,1) - sind*ssb5r(ihere,jc,3)
                     ssb5r(ihere,jc,2) = cosd*ssb5r(ihere,jc,2) - sind*ssb5r(ihere,jc,4)
                     ssb5r(ihere,jc,3) = cosd*ssb5r(ihere,jc,3) + sind*sbr(1)
                     ssb5r(ihere,jc,4) = cosd*ssb5r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb5i(ihere,jc,1)
                     sbi(2) = ssb5i(ihere,jc,2)

                     ssb5i(ihere,jc,1) = cosd*ssb5i(ihere,jc,1) - sind*ssb5i(ihere,jc,3)
                     ssb5i(ihere,jc,2) = cosd*ssb5i(ihere,jc,2) - sind*ssb5i(ihere,jc,4)
                     ssb5i(ihere,jc,3) = cosd*ssb5i(ihere,jc,3) + sind*sbi(1)
                     ssb5i(ihere,jc,4) = cosd*ssb5i(ihere,jc,4) + sind*sbi(2)

! ssb6r,i case
                     sbr(1) = ssb6r(ihere,jc,1)
                     sbr(2) = ssb6r(ihere,jc,2)

                     ssb6r(ihere,jc,1) = cosd*ssb6r(ihere,jc,1) - sind*ssb6r(ihere,jc,3)
                     ssb6r(ihere,jc,2) = cosd*ssb6r(ihere,jc,2) - sind*ssb6r(ihere,jc,4)
                     ssb6r(ihere,jc,3) = cosd*ssb6r(ihere,jc,3) + sind*sbr(1)
                     ssb6r(ihere,jc,4) = cosd*ssb6r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb6i(ihere,jc,1)
                     sbi(2) = ssb6i(ihere,jc,2)

                     ssb6i(ihere,jc,1) = cosd*ssb6i(ihere,jc,1) - sind*ssb6i(ihere,jc,3)
                     ssb6i(ihere,jc,2) = cosd*ssb6i(ihere,jc,2) - sind*ssb6i(ihere,jc,4)
                     ssb6i(ihere,jc,3) = cosd*ssb6i(ihere,jc,3) + sind*sbi(1)
                     ssb6i(ihere,jc,4) = cosd*ssb6i(ihere,jc,4) + sind*sbi(2)
                 enddo ! jc
                enddo ! ihere

  
  total=0.0_KR
 
! Need to gather to data from each process.
! ATTENTION :: Now that ecah process has a "chunk" of the total contribution
!              of the perturbative propagator for each "ihere", we must
!              sum all contributions from each process. Each subtraction 
!              level calls MPI_ALLREDUCE to do this.

  if (nps /= 1) then
     count = nxyzt * nc * nd
     call MPI_ALLREDUCE(ssb1r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb1r = total
     call MPI_ALLREDUCE(ssb1i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb1i = total
     call MPI_ALLREDUCE(ssb2r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb2r = total
     call MPI_ALLREDUCE(ssb2i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb2i = total
     call MPI_ALLREDUCE(ssb3r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb3r = total
     call MPI_ALLREDUCE(ssb3i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb3i = total
     call MPI_ALLREDUCE(ssb4r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb4r = total
     call MPI_ALLREDUCE(ssb4i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb4i = total
     call MPI_ALLREDUCE(ssb5r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb5r = total
     call MPI_ALLREDUCE(ssb5i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb5i = total
     call MPI_ALLREDUCE(ssb6r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb6r = total
     call MPI_ALLREDUCE(ssb6i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb6i = total
  endif ! nps check

  endif ! (nsub/=0)

endif ! .false.

! End of large false out.


! We need to subrtact each subtraction level from the propagator
! that is non-trivial...for isb=0 (nsub=4) kappa^3, kappa^4 and
! for isb=1 (nsub=6) kappa^5, kappa^6.

! WARNING WARNING WARNING WARNING WARNING WARNING
! We have restricted the time steps in the perturbative
! construction of the vev's in order to save time 7-16-05.

  ! z2noise = cosd*z2noise
 

  do ittt=ltime,utime
     do izz=1,nz
        do iyy=1,ny
           do ixx=1,nx
              ihere=ixx+nx*(iyy-1)+nx*ny*(izz-1)+nx*ny*nz*(ittt-1)

if (myid==0) then
open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",action="write", &
form="formatted",status="old",position="append")
write(unit=8,fmt="(a6,i3,a7,i3,a6,i3,a6,i3,a9,i5)") "ittt: ", ittt, "  izz: ", izz, "  iyy: ", iyy, "  ixx: ",ixx,"  ihere: ",ihere
close(unit=8,status="keep")
endif
 

! Here is the debugging stuff for examining the perturbative and nonperturbative
! propagators. -WW

if(.false.) then
           if (myid.eq.0) then
   open(unit=99,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",action="write",&
        form="formatted",position="append",status="old")
            do idirac=1,nd
            do icolor=1,nc
            if (abs(z2noise(ihere,icolor,idirac)).gt.1.e-4) then
             write(unit=99,fmt="(a35,6i4,e24.16)") "idirac,icolor,ix,iy,iz,it,z2noise",idirac,icolor,ixx,iyy,izz,ittt,z2noise(ihere,icolor,idirac)
            endif
             enddo ! idirac
             enddo ! icolor

            do idirac=1,nd
            do icolor=1,nc
            if (abs(rpropagator(ihere,icolor,idirac,1)).gt.1.e-16.or.abs(ipropagator(ihere,icolor,idirac,1)).gt.1.e-16) then

             xxr = cosd*(cosd*z2noise(ihere,icolor,idirac)- sign(idirac)*sind*z2noise(ihere,icolor,cd(idirac))) & 
                           + xk(1)*ssb1r(ihere,icolor,idirac) + xk(2)*ssb2r(ihere,icolor,idirac)&
                           + xk(3)*ssb3r(ihere,icolor,idirac) + xk(4)*ssb4r(ihere,icolor,idirac)&
                           + xk(5)*ssb5r(ihere,icolor,idirac) + xk(6)*ssb6r(ihere,icolor,idirac)
             xxi =           xk(1)*ssb1i(ihere,icolor,idirac)&
                           + xk(2)*ssb2i(ihere,icolor,idirac) + xk(3)*ssb3i(ihere,icolor,idirac)&
                           + xk(4)*ssb4i(ihere,icolor,idirac) + xk(5)*ssb5i(ihere,icolor,idirac)&
                           + xk(6)*ssb6i(ihere,icolor,idirac)
             write(unit=99,fmt="(6i4,a6,2e24.16)") icolor,idirac,ixx,iyy,izz,ittt,"real",rpropagator(ihere,icolor,idirac,1), xxr
             write(unit=99,fmt="(6i4,a6,2e24.16)") icolor,idirac,ixx,iyy,izz,ittt,"imag",ipropagator(ihere,icolor,idirac,1), xxi
            endif
             enddo ! idirac
             enddo ! icolor
   close(unit=99, status="keep")
           endif ! myid
endif ! false

 
if (myid==0) then
open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",action="write", &
form="formatted",status="old",position="append")
write(unit=8,fmt="(a7,i8,a24,i8)") "ihere: ",ihere," mod(ihere-1,numprocs): ",mod(ihere-1,numprocs)
close(unit=8,status="keep")
endif
              if (mod(ihere-1,numprocs) == myid) then
                 do idirac=1,nd
                    do icolor=1,nc

  z2(ihere,icolor,idirac)        = z2noise(ihere,icolor,idirac)

! z2sub is the noise used to for the Imaginary part of the
! pseduo-scalar.
! Abdou - Do we need the factor of cosd?

  z2sub(ihere,icolor,cd(idirac)) = z2noise(ihere,icolor,cd(idirac))

  leftx=mod((ixx-1)-1+nx,nx)+1
  rightx=mod((ixx+1)-1+nx,nx)+1
  lefty=mod((iyy-1)-1+ny,ny)+1
  righty=mod((iyy+1)-1+ny,ny)+1
  leftz=mod((izz-1)-1+nz,nz)+1
  rightz=mod((izz+1)-1+nz,nz)+1
  leftt=mod((ittt-1)-1+nt,nt)+1
  rightt=mod((ittt+1)-1+nt,nt)+1

!     Translate coordinates to single array index

  leftx=leftx+(iyy-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  rightx=rightx+(iyy-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  lefty=ixx+(lefty-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  righty=ixx+(righty-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  leftz=ixx+(iyy-1)*nx+(leftz-1)*nx*ny+(ittt-1)*nx*ny*nz
  rightz=ixx+(iyy-1)*nx+(rightz-1)*nx*ny+(ittt-1)*nx*ny*nz
  leftt=ixx+(iyy-1)*nx+(izz-1)*nx*ny+(leftt-1)*nx*ny*nz
  rightt=ixx+(iyy-1)*nx+(izz-1)*nx*ny+(rightt-1)*nx*ny*nz

  imv(1)=ihere
  imv(2)=leftx
  imv(3)=rightx
  imv(4)=lefty
  imv(5)=righty
  imv(6)=leftz
  imv(7)=rightz
  imv(8)=leftt
  imv(9)=rightt


  jc=icolor
  jd=idirac

! These are the arrays used for the psuedo-scalar. The gamma5 multiplication below
! requires information about ALL 4 dirac sites.
! Dean: All the sub's need attention!!!

! sub3r(ihere,jc,idirac) = rpropagator(ihere,jc,cd(idirac),1) - z2sub(ihere,jc,cd(idirac)) &
!w  sub3r(ihere,jc,idirac) = rpropagator(ihere,jc,cd(idirac),1) &
!w                           - xk(1)*ssb1r(ihere,jc,cd(idirac)) - xk(2)*ssb2r(ihere,jc,cd(idirac))&
!w                           - xk(3)*ssb3r(ihere,jc,cd(idirac))
! Temp. change.
! sub3r(ihere,jc,idirac) = - xk(1)*ssb1r(ihere,jc,cd(idirac)) - xk(2)*ssb2r(ihere,jc,cd(idirac))&
!                          - xk(3)*ssb3r(ihere,jc,cd(idirac))

!w  sub3i(ihere,jc,idirac) = ipropagator(ihere,jc,cd(idirac),1) - xk(1)*ssb1i(ihere,jc,cd(idirac))&
!w                           - xk(2)*ssb2i(ihere,jc,cd(idirac)) - xk(3)*ssb3i(ihere,jc,cd(idirac))
! Temp. change.
! sub3i(ihere,jc,idirac) = - xk(1)*ssb1i(ihere,jc,cd(idirac)) - xk(2)*ssb2i(ihere,jc,cd(idirac))&
!                          - xk(3)*ssb3i(ihere,jc,cd(idirac))

! Making this non cumulative --!w

! Now that sub3 has been multiplied by gamma5, there is no need to use cd(idirac)
! when assigning sub4i because sub3 has been "gammified".
! The same is true of sub4i when assining sub5i and soforth.

!w  sub4r(ihere,jc,idirac) = sub3r(ihere,jc,idirac) - xk(4)*ssb4r(ihere,jc,cd(idirac))
!w  sub4i(ihere,jc,idirac) = sub3i(ihere,jc,idirac) - xk(4)*ssb4i(ihere,jc,cd(idirac))

!w  sub5r(ihere,jc,idirac) = sub4r(ihere,jc,idirac) - xk(5)*ssb5r(ihere,jc,cd(idirac))
!w  sub5i(ihere,jc,idirac) = sub4i(ihere,jc,idirac) - xk(5)*ssb5i(ihere,jc,cd(idirac))

!w  sub6r(ihere,jc,idirac) = sub5r(ihere,jc,idirac) - xk(6)*ssb6r(ihere,jc,cd(idirac))
!w  sub6i(ihere,jc,idirac) = sub5i(ihere,jc,idirac) - xk(6)*ssb6i(ihere,jc,cd(idirac))


!****ATTENTION*** Odd terms have been moved from plus to minus....02-17-06
!                 The cumulative subtracted propagator (ssbr and ssbi) are
!                 rewritten. Each order has knowledge of the previous one.

 
! The ssbr's and ssbi's have a spatial sum done above. It represents
!     all the contributions to a given ihere due to the multiplications
!     of GammaMultiply.

! ssb0r(ihere,jc,jd) = rpropagator(ihere,jc,jd,1) - cosd*z2(ihere,jc,jd) 
!w  ssb0r(ihere,jc,jd) = rpropagator(ihere,jc,jd,1)
! Temp. change to display perturbative result.
! ssb0r(ihere,jc,jd) = 0.0_KR
!w  ssb0i(ihere,jc,jd) = ipropagator(ihere,jc,jd,1) 
! Temp. change.
! ssb0i(ihere,jc,jd) = 0.0_KR

!w  ssb1r(ihere,jc,jd) = ssb0r(ihere,jc,jd) - xk(1)*ssb1r(ihere,jc,jd)
!w  ssb1i(ihere,jc,jd) = ssb0i(ihere,jc,jd) - xk(1)*ssb1i(ihere,jc,jd)

!w  ssb2r(ihere,jc,jd) = ssb1r(ihere,jc,jd) - xk(2)*ssb2r(ihere,jc,jd) 
!w  ssb2i(ihere,jc,jd) = ssb1i(ihere,jc,jd) - xk(2)*ssb2i(ihere,jc,jd) 

!w  ssb3r(ihere,jc,jd) = ssb2r(ihere,jc,jd) - xk(3)*ssb3r(ihere,jc,jd)
!w  ssb3i(ihere,jc,jd) = ssb2i(ihere,jc,jd) - xk(3)*ssb3i(ihere,jc,jd)

!w  ssb4r(ihere,jc,jd) = ssb3r(ihere,jc,jd) - xk(4)*ssb4r(ihere,jc,jd)
!w  ssb4i(ihere,jc,jd) = ssb3i(ihere,jc,jd) - xk(4)*ssb4i(ihere,jc,jd)

!w  ssb5r(ihere,jc,jd) = ssb4r(ihere,jc,jd) - xk(5)*ssb5r(ihere,jc,jd)
!w  ssb5i(ihere,jc,jd) = ssb4i(ihere,jc,jd) - xk(5)*ssb5i(ihere,jc,jd)

!w  if (nsub==6) then
!w      ssb6r(ihere,jc,jd) = ssb5r(ihere,jc,jd) - xk(6)*ssb6r(ihere,jc,jd)
!w      ssb6i(ihere,jc,jd) = ssb5i(ihere,jc,jd) - xk(6)*ssb6i(ihere,jc,jd)
!w  endif ! nsub
  
!
! Need to keep the unsubtracted propagator (nsub=1) kappa^0 which
! corresponds to (isb=0).


! Now do subtracted operator expectation values
   do jri=1,nri
     if (nsub==0) usub = 0
     if (nsub==4) usub = 1
     if (nsub==6) usub = 2

         do isb=0,usub
            IF (jri.eq.1) THEN
                if (isb.eq.0) then
!www                   sprop(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
!www                                    - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
                   sprop(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                    - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
                   pscalar(ihere) = sign(idirac)*ipropagator(ihere,icolor,cd(idirac),1)

                else if(isb.eq.1) then
! Putting in perturbative elements. This is 2nd order. This is wrong at this level for currents.
!www                   s0(ihere)   = xk(1)*ssb1r(ihere,icolor,idirac)+xk(3)*ssb3r(ihere,icolor,idirac)
!www                   s1(ihere)   = xk(2)*ssb2r(ihere,icolor,idirac)
!www                   pscalar(ihere) = xk(2)*sign(idirac)*ssb2i(ihere,icolor,cd(idirac))

                       s0(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) &
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac)
! Need to experiment with source terms below. -WW
                       s1(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) & 
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac) &
                                     - xk(4)*ssb4r(ihere,icolor,idirac) 
                       pscalar(ihere) = sign(idirac)*(ipropagator(ihere,icolor,cd(idirac),1) &
                                     -xk(1)*ssb1i(ihere,icolor,cd(idirac)) &
                                     -xk(2)*ssb2i(ihere,icolor,cd(idirac)) &
                                     -xk(3)*ssb3i(ihere,icolor,cd(idirac)) &
                                     -xk(4)*ssb4i(ihere,icolor,cd(idirac)))

!                   s0(ihere)      = ssb4r(ihere,icolor,idirac)
!w                    s0(ihere)      = ssb4r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))

!                   s1(ihere)      = ssb5r(ihere,icolor,idirac) + z2(ihere,icolor,idirac)
!w                    s1(ihere)      = ssb5r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
!                   s1(ihere)      = ssb5r(ihere,icolor,idirac)+cosd*sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))
!                   s1(ihere)      = ssb5r(ihere,icolor,idirac)
!w                    pscalar(ihere) = sign(idirac)*sub5i(ihere,icolor,idirac)

                else if(isb.eq.2) then
! Temp. change for 4th order.
!www                    s0(ihere)      = xk(5)*ssb5r(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    s1(ihere)      = xk(4)*ssb4r(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    pscalar(ihere) = xk(4)*sign(idirac)*ssb4i(ihere,icolor,cd(idirac))

                       s0(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) &
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac) &
                                     - xk(4)*ssb4r(ihere,icolor,idirac) &
                                     - xk(5)*ssb5r(ihere,icolor,idirac) &
                                     - xk(6)*ssb6r(ihere,icolor,idirac)
! Need to experiment with source terms below. -WW
                       s1(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) & 
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac) &
                                     - xk(4)*ssb4r(ihere,icolor,idirac) &
                                     - xk(5)*ssb5r(ihere,icolor,idirac) &
                                     - xk(6)*ssb6r(ihere,icolor,idirac)
                       pscalar(ihere) = sign(idirac)*(ipropagator(ihere,icolor,cd(idirac),1) &
                                     -xk(1)*ssb1i(ihere,icolor,cd(idirac)) &
                                     -xk(2)*ssb2i(ihere,icolor,cd(idirac)) &
                                     -xk(3)*ssb3i(ihere,icolor,cd(idirac)) &
                                     -xk(4)*ssb4i(ihere,icolor,cd(idirac)) &
                                     -xk(5)*ssb5i(ihere,icolor,cd(idirac)) &
                                     -xk(6)*ssb6i(ihere,icolor,cd(idirac)))

!                   s0(ihere)      = ssb6r(ihere,icolor,idirac)
!w                    s0(ihere)      = ssb6r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
! Temp. change for 6th order.
!ww                    s0(ihere)      = xk(5)*ssb5r(ihere,icolor,idirac)

!                   s1(ihere)      = ssb6r(ihere,icolor,idirac) + z2(ihere,icolor,idirac)
!w                    s1(ihere)      = ssb6r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
! Temp. change for 6th order.
!ww                    s1(ihere)      = xk(6)*ssb6r(ihere,icolor,idirac)

!                   s1(ihere)      = ssb6r(ihere,icolor,idirac)+cosd*sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))
!                   s1(ihere)      = ssb6r(ihere,icolor,idirac)
!w                    pscalar(ihere) = sign(idirac)*sub6i(ihere,icolor,idirac)
! Temp. change for 6th order.
!ww                    pscalar(ihere) = xk(6)*sign(idirac)*ssb6i(ihere,icolor,cd(idirac))

                endif ! isb
            ELSE
                if (isb.eq.0) then
                   sprop(ihere)   = ipropagator(ihere,icolor,idirac,1)
              pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
                               -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))
!www          pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
!www                           -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))

                else if(isb.eq.1) then
! Temp. change for 2nd order. Again, incorrect for currents.
!www                    s0(ihere)   = xk(1)*ssb1i(ihere,icolor,idirac)+xk(3)*ssb3i(ihere,icolor,idirac)
!www                    s1(ihere)   = xk(2)*ssb2i(ihere,icolor,idirac)
!www                    pscalar(ihere) = -sign(idirac)*xk(2)*ssb2r(ihere,icolor,cd(idirac))

                      s0(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac)
                      s1(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac) &
                                  -xk(4)*ssb4i(ihere,icolor,idirac)
! Need to experiment with source terms below. -WW
                 pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
                                  -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)) &
                                  -xk(1)*ssb1r(ihere,icolor,cd(idirac)) &
                                  -xk(2)*ssb2r(ihere,icolor,cd(idirac)) &
                                  -xk(3)*ssb3r(ihere,icolor,cd(idirac)) &
                                  -xk(4)*ssb4r(ihere,icolor,cd(idirac))) 

!w                    s0(ihere)      = ssb4i(ihere,icolor,idirac)

!w                    s1(ihere)      = ssb5i(ihere,icolor,idirac)

!                   pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac) + z2(ihere,icolor,cd(idirac)))
!w                    pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
!w                                     -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))

!                   pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac)-cosd*cosd*z2sub(ihere,icolor,cd(idirac)))
!                   pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac))

                else if(isb.eq.2) then
! Temp. change for 4th order.
!www                    s0(ihere)      = xk(5)*ssb5i(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    s1(ihere)      = xk(4)*ssb4i(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    pscalar(ihere) = -sign(idirac)*xk(4)*ssb4r(ihere,icolor,cd(idirac))

                      s0(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac) &
                                  -xk(4)*ssb4i(ihere,icolor,idirac) &
                                  -xk(5)*ssb5i(ihere,icolor,idirac) &
                                  -xk(6)*ssb6i(ihere,icolor,idirac)
                      s1(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac) &
                                  -xk(4)*ssb4i(ihere,icolor,idirac) &
                                  -xk(5)*ssb5i(ihere,icolor,idirac) &
                                  -xk(6)*ssb6i(ihere,icolor,idirac) 
! Need to experiment with source terms below. -WW
                 pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
                                  -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)) &
                                  -xk(1)*ssb1r(ihere,icolor,cd(idirac)) &
                                  -xk(2)*ssb2r(ihere,icolor,cd(idirac)) &
                                  -xk(3)*ssb3r(ihere,icolor,cd(idirac)) &
                                  -xk(4)*ssb4r(ihere,icolor,cd(idirac)) &
                                  -xk(5)*ssb5r(ihere,icolor,cd(idirac)) &
                                  -xk(6)*ssb6r(ihere,icolor,cd(idirac)))

!w                    s0(ihere)      = ssb6i(ihere,icolor,idirac)
! Temp. change for 6th order.
!ww                    s0(ihere)      = xk(5)*ssb5i(ihere,icolor,idirac)

!w                    s1(ihere)      = ssb6i(ihere,icolor,idirac)
! Temp. change for 6th order.
!ww                    s1(ihere)      = xk(6)*ssb6i(ihere,icolor,idirac) 

!                   pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac) + z2(ihere,icolor,cd(idirac)))
!w                    pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
!w                                     -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))
! Temp. change for 6th order.
!ww                    pscalar(ihere) = -xk(6)*sign(idirac)*ssb6r(ihere,icolor,cd(idirac)) 

!                   pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac)-cosd*cosd*z2sub(ihere,icolor,cd(idirac)))
!                   pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac))

                endif ! isb
            ENDIF ! (jri.eq.1)

            if (isb==0) then
! Calculate the operators for the raw propagator.
                call currentCalc2(sprop,idirac,icolor,jri,ihere,&
                                  leftx,rightx,lefty,righty,leftz,rightz,&
                                  leftt,rightt,ittt,usp,uss,z2noise,rwdir,ir,myid)
                call scalarCalc(sprop,idirac,icolor,jri,ihere,1,myid)
                call scalarCalc(pscalar,idirac,icolor,jri,ihere,2,myid)

            else ! (isb==0)
! Calculate the operators for first non-trivial and highest order subtraction
! levels.

                call currentCalc2(s0,idirac,icolor,jri,ihere,&
                                  leftx,rightx,lefty,righty,leftz,rightz,&
                                  leftt,rightt,ittt,usp,uss,z2noise,rwdir,ir,myid)
                call scalarCalc(s1,idirac,icolor,jri,ihere,1,myid)
                call scalarCalc(pscalar,idirac,icolor,jri,ihere,2,myid)


            endif ! (isb==0)
            if (ittt.ne.ltime) then
                xrr2(isb)=xrr2(isb)+rhor(leftt)
                xri2(isb)=xri2(isb)+rhoi(leftt)
            endif ! ittt utime

            if (ittt.ne.utime) then
                xrr2(isb)=xrr2(isb)+rhor(ihere)
                xri2(isb)=xri2(isb)+rhoi(ihere)
            endif ! ittt ltime

! Only do psibar*psi once when jc=icolor

            xps2(isb)=xps2(isb)+psir(ihere)
            xpi2(isb)=xpi2(isb)+psii(ihere)

            xpsur(isb)=xpsur(isb)+psur(ihere)
            xpsui(isb)=xpsui(isb)+psui(ihere)

            xsj1pr(isb)=xsj1pr(isb)+j1pr(leftx)
            xsj1pr(isb)=xsj1pr(isb)+j1pr(ihere)
            xsj1pi(isb)=xsj1pi(isb)+j1pi(leftx)
            xsj1pi(isb)=xsj1pi(isb)+j1pi(ihere)

            xsj2pr(isb)=xsj2pr(isb)+j2pr(lefty)
            xsj2pr(isb)=xsj2pr(isb)+j2pr(ihere)
            xsj2pi(isb)=xsj2pi(isb)+j2pi(lefty)
            xsj2pi(isb)=xsj2pi(isb)+j2pi(ihere)

            xsj3pr(isb)=xsj3pr(isb)+j3pr(leftz)
            xsj3pr(isb)=xsj3pr(isb)+j3pr(ihere)
            xsj3pi(isb)=xsj3pi(isb)+j3pi(leftz)
            xsj3pi(isb)=xsj3pi(isb)+j3pi(ihere)

!     Momentum analysis

            opertemp(1,ittt,1,isb)=opertemp(1,ittt,1,isb)+&
                                   rhor(ihere)
            opertemp(1,modulo((ittt-1)-1,nt)+1,1,isb)=&
            opertemp(1,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                   rhor(leftt)

            opertemp(2,ittt,1,isb)=opertemp(2,ittt,1,isb)+&
                                   rhoi(ihere)
            opertemp(2,modulo((ittt-1)-1,nt)+1,1,isb)=&
            opertemp(2,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                   rhoi(leftt)



! These are the scalor operators...
! NOTE (jc is allways equal to icolor here)

           !if (jc.eq.icolor) then
                opertemp(3,ittt,1,isb)=opertemp(3,ittt,1,isb)+&
                                       psir(ihere)
                opertemp(4,ittt,1,isb)=opertemp(4,ittt,1,isb)+&
                                       psii(ihere)
           !endif

            opertemp(5,ittt,1,isb)=opertemp(5,ittt,1,isb)+&
                                   j1pr(ihere)+&
                                   j1pr(leftx)

            opertemp(6,ittt,1,isb)=opertemp(6,ittt,1,isb)+&
                                   j1pi(ihere)+&
                                   j1pi(leftx)

            opertemp(7,ittt,1,isb)=opertemp(7,ittt,1,isb)+&
                                   j2pr(ihere)+&
                                   j2pr(lefty)

            opertemp(8,ittt,1,isb)=opertemp(8,ittt,1,isb)+&
                                   j2pi(ihere)+&
                                   j2pi(lefty)

            opertemp(9,ittt,1,isb)=opertemp(9,ittt,1,isb)+&
                                   j3pr(ihere)+&
                                   j3pr(leftz)

            opertemp(10,ittt,1,isb)=opertemp(10,ittt,1,isb)+&
                                    j3pi(ihere)+&
                                    j3pi(leftz)
            if (jc.eq.icolor) then
                opertemp(11,ittt,1,isb)=opertemp(11,ittt,1,isb)+&
                                       psur(ihere)
                opertemp(12,ittt,1,isb)=opertemp(12,ittt,1,isb)+&
                                       psui(ihere)
            endif

            do ix=2,5

               opertemp(1,ittt,ix,isb)=opertemp(1,ittt,ix,isb)+&
                                       rhor(ihere)*ffac(ihere,ix-1)
               opertemp(1,modulo((ittt-1)-1,nt)+1,ix,isb)=&
               opertemp(1,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                       rhor(leftt)*ffac(leftt,ix-1)

               opertemp(2,ittt,ix,isb)=opertemp(2,ittt,ix,isb)+&
                                       rhoi(ihere)*ffac(ihere,ix-1)
               opertemp(2,modulo((ittt-1)-1,nt)+1,ix,isb)=&
               opertemp(2,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                       rhoi(leftt)*ffac(leftt,ix-1)


! These are the scalor operators...
! NOTE (jc is allways equal to icolor here)

               if (jc.eq.icolor) then
                   opertemp(3,ittt,ix,isb)=opertemp(3,ittt,ix,isb)+&
                                           psir(ihere)*ffac(ihere,ix-1)

                   opertemp(4,ittt,ix,isb)=opertemp(4,ittt,ix,isb)+&
                                           psii(ihere)*ffac(ihere,ix-1)
               endif

               opertemp(5,ittt,ix,isb)=opertemp(5,ittt,ix,isb)+&
                                       j1pi(ihere)*fas3(ihere,ix-1)+&
                                       j1pi(leftx)*fas3(leftx,ix-1)

               opertemp(6,ittt,ix,isb)=opertemp(6,ittt,ix,isb)+&
                                       j2pi(ihere)*fas1(ihere,ix-1)+&
                                       j2pi(lefty)*fas1(lefty,ix-1)

               opertemp(7,ittt,ix,isb)=opertemp(7,ittt,ix,isb)+&
                                       j3pi(ihere)*fas2(ihere,ix-1)+&
                                       j3pi(leftz)*fas2(leftz,ix-1)

               opertemp(8,ittt,ix,isb)=opertemp(8,ittt,ix,isb)+&
                                       j1pi(ihere)*fas2(ihere,ix-1)+&
                                       j1pi(leftx)*fas2(leftx,ix-1)

               opertemp(9,ittt,ix,isb)=opertemp(9,ittt,ix,isb)+&
                                       j2pi(ihere)*fas3(ihere,ix-1)+&
                                       j2pi(lefty)*fas3(lefty,ix-1)

               opertemp(10,ittt,ix,isb)=opertemp(10,ittt,ix,isb)+&
                                       j3pi(ihere)*fas1(ihere,ix-1)+&
                                       j3pi(leftz)*fas1(leftz,ix-1)

               if (jc.eq.icolor) then
                   opertemp(11,ittt,ix,isb)=opertemp(11,ittt,ix,isb)+&
                                           psur(ihere)*ffac(ihere,ix-1)

                   opertemp(12,ittt,ix,isb)=opertemp(12,ittt,ix,isb)+&
                                           psui(ihere)*ffac(ihere,ix-1)
               endif

! Need also 2-1, 3-2 and 1-3 combinations of directions
! (fas things) and currents at this point according to
! ahab7.f, which is used as a guide for coding the magnetic operators.
! disco13.f seems to imply that only the ones using
! the imaginary part of the currents need be kept.
!
!     End of momentum analysis

            enddo ! ix
         enddo ! isb
      enddo ! jri

      z2(ihere,icolor,idirac) = 0.0_KR
      z2sub(ihere,icolor,cd(idirac)) = 0.0_KR

                    enddo ! icolor
                 enddo ! idirac
              endif ! mod(numprocs) ! Second mod!!!
           enddo ! ixx
        enddo ! iyy
     enddo ! izz
  enddo ! ittt

! Need to put the operators in Jvev to be passed into average..

  do ittt = 1,nt
     if (nsub==0) then
         do imom=1,nmom

! Jvevtemp(:,:,1,:,:) is the unsubtracted propagator
            Jvevtemp(1,ittt,1,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,6) = opertemp(12,ittt,imom,0)
         enddo ! imom
     elseif (nsub==4) then
         do imom=1,nmom

! Jvevtemp(:,:,1,:,:) is the unsubtracted propagator
            Jvevtemp(1,ittt,1,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,6) = opertemp(12,ittt,imom,0)

            Jvevtemp(1,ittt,4,imom,1) = opertemp(1,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,1) = opertemp(2,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,2) = opertemp(3,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,2) = opertemp(4,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,3) = opertemp(5,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,3) = opertemp(6,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,4) = opertemp(7,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,4) = opertemp(8,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,5) = opertemp(9,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,5) = opertemp(10,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,6) = opertemp(11,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,6) = opertemp(12,ittt,imom,1)
         enddo ! imom
     elseif (nsub==6) then

! If nsub==6 then we need to have the first non-trival subtraction level
! (kappa^4) along with the highest order (kappa^6)

         do imom=1,nmom

! Jvevtemp(:,:,1,:,:) is the unsubtracted propagator
            Jvevtemp(1,ittt,1,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,6) = opertemp(12,ittt,imom,0)

            Jvevtemp(1,ittt,4,imom,1) = opertemp(1,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,1) = opertemp(2,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,2) = opertemp(3,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,2) = opertemp(4,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,3) = opertemp(5,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,3) = opertemp(6,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,4) = opertemp(7,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,4) = opertemp(8,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,5) = opertemp(9,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,5) = opertemp(10,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,6) = opertemp(11,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,6) = opertemp(12,ittt,imom,1)

            Jvevtemp(1,ittt,6,imom,1) = opertemp(1,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,1) = opertemp(2,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,2) = opertemp(3,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,2) = opertemp(4,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,3) = opertemp(5,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,3) = opertemp(6,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,4) = opertemp(7,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,4) = opertemp(8,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,5) = opertemp(9,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,5) = opertemp(10,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,6) = opertemp(11,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,6) = opertemp(12,ittt,imom,2)
         enddo ! imom

     endif ! nsub
  enddo ! ittt

  if (nps/=1) then
      opercount = (nsav*nt*5*3)
      call MPI_REDUCE(opertemp(1,1,1,0),oper(1,1,1,0),opercount,MRT,MPI_SUM,&
                      0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xrr2(0),xrr2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xri2(0),xri2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xps2(0),xps2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xpi2(0),xpi2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)

      call MPI_REDUCE(xpsur(0),xpsurtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xpsui(0),xpsuitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)


      call MPI_REDUCE(xsj1pr(0),xsj1prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj1pi(0),xsj1pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj2pr(0),xsj2prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj2pi(0),xsj2pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj3pr(0),xsj3prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj3pi(0),xsj3pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
  else
      oper=opertemp
      xrr2temp=xrr2
      xri2temp=xri2
      xps2temp=xps2
      xpi2temp=xpi2
      xpsurtemp=xpsur
      xpsuitemp=xpsui
      xsj1prtemp=xsj1pr
      xsj1pitemp=xsj1pi
      xsj2prtemp=xsj2pr
      xsj2pitemp=xsj2pi
      xsj3prtemp=xsj3pr
      xsj3pitemp=xsj3pi
  endif ! nps
!     enddo ! is

  if (nps/=1) then
      Jvevcount = (2*nt*6*nmom*nop)
!     call MPI_REDUCE(Jvevtemp(1,1,1,1,1),Jvev(1,1,1,1,1),Jvevcount,MRT,MPI_SUM,&
!                     0,MPI_COMM_WORLD,ierr)
!     call MPI_BCAST(Jvev(1,1,1,1,1),Jvevcount,MRT,0,MPI_COMM_WORLD,ierr)
     call MPI_ALLREDUCE(Jvevtemp,Jvev,Jvevcount,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
  else
      Jvev=Jvevtemp
  endif ! (nps/=1)

     ! if(myid==0) close(unit=8,status="keep")

  deallocate(ffac)
  deallocate(fas1)
  deallocate(fas2)
  deallocate(fas3)

! deallocate(uss)
! deallocate(usp)

  deallocate(rpropagator)
  deallocate(ipropagator)

  deallocate(z2i)
  deallocate(z3i)
  deallocate(z2noise)
  deallocate(z2inoise)

  deallocate(uss)
  deallocate(usp)
  deallocate(utemp)


  deallocate(ssb0r)
  deallocate(ssb0i)
  deallocate(ssb1r)
  deallocate(ssb1i)
  deallocate(ssb2r)
  deallocate(ssb2i)
  deallocate(ssb3r)
  deallocate(ssb3i)
  deallocate(ssb4r)
  deallocate(ssb4i)
  deallocate(ssb5r)
  deallocate(ssb5i)
  deallocate(ssb6r)
  deallocate(ssb6i)
  deallocate(total)

! call deallocateus

  end Subroutine twAverage
!**********************************************************************


  Subroutine twAverage_axial(Jvev,be,bo,xe,xo,delta,io,kappa,&
                       upart,dobndry,numprocs,MRT,myid,&
                       nsub,nmom,nop,noisenum,shiftnum,&
                       ntmqcd, rwdir, ir)

  use input2
  use input5b
  use seed
!  use sub
  use operator

! use input1
! use gaugelinks

!  xe() and xo() contain the "raw" propagator for the disconnected valence quarks.

  real(kind=KR),    intent(out),    dimension(2,nt,6,nmom,nop)            :: Jvev
  real(kind=KR),    intent(inout),  dimension(18,ntotal,4,2,16)           :: upart
  real(kind=KR),    intent(inout),  dimension(6,ntotal,4,2,8)             :: be,bo

  character(len=*), intent(in),     dimension(:)                          :: rwdir
  integer(kind=KI), intent(in)                                            :: nsub,nmom,nop
  real(kind=KR),    intent(inout),     dimension(6,ntotal,4,2,8,1)        :: xe
  real(kind=KR),    intent(inout),     dimension(6,nvhalf,4,2,8,1)        :: xo
  integer(kind=KI), intent(in),     dimension(3)                          :: io
  real(kind=KR),    intent(in)                                            :: kappa
  real(kind=KR),    intent(in)                                            :: delta
  integer(kind=KI), intent(in)                                            :: dobndry
  integer(kind=KI), intent(in)                                            :: noisenum
  integer(kind=KI), intent(in)                                            :: shiftnum, ntmqcd
  integer(kind=KI), intent(in)                                            :: MRT
  integer(kind=KI), intent(in)                                            :: numprocs, myid, ir

!  real(kind=KR),                    dimension(18,ntotal,4,2,16)           :: utemp
  real(kind=KR),allocatable,         dimension(:,:,:,:,:)                  :: utemp
  real(kind=KR)                                                           :: xkappa
  integer(kind=KI),                 dimension(1)                          :: bufsizes
  integer(kind=KI)                                                        :: rank
  integer(kind=KI),                 dimension(9)                          :: imv
  integer(kind=KI)                                                        :: kc,kd
  real(kind=KR),                    dimension(2,nt,6,nmom,nop) :: Jvevtemp
  real(kind=KR),                    dimension(0:3)                        :: xrr2,xri2,xps2,&
                                                                             xpi2,xsj1pr,xsj1pi,&
                                                                             xsj2pr,xsj2pi,xsj3pr,&
                                                                             xsj3pi,xpsur,xpsui,&
                                                                             axrr2,axri2,&
                                                                          axsj1pr,axsj1pi,axsj2pr,axsj2pi,&
                                                                          axsj3pr,axsj3pi
  real(kind=KR),                    dimension(0:3)                        :: xrr2temp,xri2temp,xps2temp,&
                                                                             xpi2temp,xsj1prtemp,xsj1pitemp,&
                                                                             xsj2prtemp,xsj2pitemp,xsj3prtemp,&
                                                                             xsj3pitemp,xpsurtemp,xpsuitemp,&
                                                                             axrr2temp,axri2temp,&
                                                                             axsj1prtemp,axsj1pitemp,&
                                                                             axsj2prtemp,axsj2pitemp,&
                                                                             axsj3prtemp,axsj3pitemp


  real(kind=KR), allocatable,       dimension(:,:,:)                      :: z2i,z3i
  real(kind=KR), allocatable,       dimension(:,:,:)                      :: z2noise,z2inoise

  real(kind=KR), allocatable,       dimension(:,:,:,:)                    :: rpropagator,ipropagator

  real(kind=KR),                    dimension(2)                          :: sbr,sbi
  real(kind=KR),                    dimension(nxyzt)                      :: s0,s1,sprop,pscalar
  real(kind=KR),                    dimension(nsav,0:3)                   :: op,oa,oe
  real(kind=KR),                    dimension(nsav,nt,5,0:2)              :: oper,oab,oeb,opertemp
  real(kind=KR), allocatable,       dimension(:,:)                        :: ffac,fas1,fas2,fas3
  real(kind=KR),                    dimension(6)                          :: xk
  real(kind=KR)                                                           :: pmom1,pmom2,pmom3
  real(kind=KR)                                                           :: dx,dy,dz
  real(kind=KR)                                                           :: xnl
!  character(len=8)                                                        :: sfile
  integer(kind=KI)                                                        :: itr,itimz,imom
  integer(kind=KI)                                                        :: ihere,leftx,rightx,lefty,righty,&
                                                                             leftz,rightz,leftt,rightt,&
                                                                             ahere,ax,ay,az,at,md,&
                                                                             bx,by,bz,bt,proc
  integer(kind=KI)                                                        :: isx,isy,isz
  integer(kind=KI)                                                        :: ixx,iyy,izz,ittt
  integer(kind=KI)                                                        :: iy,iz,it,ixyzt
  integer(kind=KI)                                                        :: tempx,tempy,tempz,temptplus,&
                                                                             temptminus
  integer(kind=KI)                                                        :: isb,isp
  integer(kind=KI)                                                        :: im,imm,iop,ix,i
  integer(kind=KI)                                                        :: counter
  integer(kind=KI)                                                        :: idirac,icolor,jc,jd,jri,is
  integer(kind=KI)                                                        :: type
  logical                                                                 :: fixbc
  logical                                                                 :: true,false
  integer(kind=KI)                                                        :: iblock,ieo,j,&
                                                                             kc1,kc2,isite,ixyz,site,inps
  integer(kind=KI)                                                        :: ieo1,ieo2,itbit,itbit2,&
                                                                             ixbit,ixbit2,ixbit3,&
                                                                             iybit,iybit2,izbit,izbit2,&
                                                                             iblbit, ibleo
  integer(kind=KI)                                                        :: ierr 
  integer(kind=KI)                                                        :: opercount,Jvevcount,count
  integer(kind=KI),                 dimension(4)                          :: np,ip
  real(kind=KR), allocatable,       dimension(:,:,:,:,:)                  :: uss 
  real(kind=KR), allocatable,       dimension(:,:,:,:)                    :: usp 
!    real(kind=KR),        dimension(nxyzt,3,2,nc,nc)                   :: uss
!    real(kind=KR),        dimension(nxyzt,2,nc,nc)                     :: usp

  !real(kind=KR),                    dimension(9,ntotal,3,2,16)            :: rtempuss, itempuss
 ! real(kind=KR),                    dimension(9,ntotal,1,2,16)            :: rtempusp, itempusp

  integer(kind=KI)                                                        :: number,l,m,k,ipos,icolor1,icolor2
  integer(kind=KI)                                                        :: ltime,utime,usub

  real(kind=KR),                    dimension(nxyzt,nc,nd)                :: ssb0r, ssb0i, ssb1r,ssb1i,ssb2r,ssb2i,&
                                                                             ssb3r,ssb3i,ssb4r,ssb4i,&
                                                                             ssb5r,ssb5i,ssb6r,ssb6i, total
! No more subs!!
! real(kind=KR),                    dimension(nxyzt,nc,nd)                :: z2sub, sub3r, sub3i, sub4r, sub4i,&
!                                                                            sub5r, sub5i, sub6r, sub6i 
  real(kind=KR),                    dimension(nxyzt,nc,nd)                :: z2sub

  integer(kind=KI)                                                        :: ic, id, index
  integer(kind=KI),                 dimension(4)                          :: cd, sign
  real(kind=KR)                                                           :: fac, xxr, xxi 
  real(kind=KR), dimension(0:3) :: whatever,ever
  real(kind=KR), dimension(nt,0:1):: ever2

  allocate(uss(nxyzt,3,2,nc,nc))
  allocate(usp(nxyzt,2,nc,nc))
  allocate(utemp(18,ntotal,4,2,16))


  ever=0.0_KR
  ever2=0.0_KR
  whatever=0.0_KR
!
! This subroutine is in directory ./qqcd/cfgsprops/quark/common. It
! allocates memory for the unit vector z2.

  call allocatez2
  call allocatesubs
! call allocateus

! Variables that don't occur often are allocated/deallocated locally.

! NOTE~ some of the variables are not dealloacted. This is to save time
!       in the overall program runtime. Variables that are going to be needed
!       many times are left in the heap an not deallocated and then realloacted.
!       (you may see this structure in the above subroutines)

  allocate(ffac(nxyzt,4))
  allocate(fas1(nxyzt,4))
  allocate(fas2(nxyzt,4))
  allocate(fas3(nxyzt,4))

! allocate(uss(nxyzt,3,nri,nc,nc))
! allocate(usp(nxyzt,nri,nc,nc))

  allocate(rpropagator(nxyzt,nc,nd,1))
  allocate(ipropagator(nxyzt,nc,nd,1))

  allocate(z2i(nxyzt,nc,nd))
  allocate(z3i(nxyzt,nc,nd))
  allocate(z2noise(nxyzt,nc,nd))
  allocate(z2inoise(nxyzt,nc,nd))

  ffac = 0.0_KR
  fas1 = 0.0_KR
  fas2 = 0.0_KR
  fas3 = 0.0_KR
  opertemp=0.0_KR
  xrr2=0.0_KR
  xri2=0.0_KR
  xps2=0.0_KR
  xpi2=0.0_KR
  xpsur=0.0_KR
  xpsui=0.0_KR
  xsj1pr=0.0_KR
  xsj1pi=0.0_KR
  xsj2pr=0.0_KR
  xsj2pi=0.0_KR
  xsj3pr=0.0_KR
  xsj3pi=0.0_KR
  xrr2temp=0.0_KR
  xri2temp=0.0_KR
  xps2temp=0.0_KR
  xpi2temp=0.0_KR
  xpsurtemp=0.0_KR
  xpsuitemp=0.0_KR
  xsj1prtemp=0.0_KR
  xsj1pitemp=0.0_KR
  xsj2prtemp=0.0_KR
  xsj2pitemp=0.0_KR
  xsj3prtemp=0.0_KR
  xsj3pitemp=0.0_KR

! Zero out the operators that are passed out to the discon-loop program

  Jvev = 0.0_KR
  Jvevtemp=0.0_KR

!  open(unit=8,file="TWVEV.LOG", action="write",form="formatted",status="old",position="append")
   
     if(myid==0) then
      open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",action="write",&
        form="formatted",position="append",status="old")
      close(unit=8,status="keep")
     endif

! Initializations for the gamma5 matrix multiplcation for the pseudo-scalar
  cd(1:4)   = (/ 3, 4, 1, 2 /)
  sign(1:4) = (/ 1, 1, -1, -1 /)

!     Determine boundry conditions depending on the value of dobndry

  if (dobndry==1) then
      fixbc=.true.
  else
      fixbc=.false.
  endif ! dobndry

!     Set up quantities needed for momentum analysis.
!     Need to define lowest momentum in each lattice direction for anisotropic lattice

  pmom1=8.0_KR*atan(1.0_KR)/nx
  pmom2=8.0_KR*atan(1.0_KR)/ny
  pmom3=8.0_KR*atan(1.0_KR)/nz

  do itr=1,nt
     itimz=(itr-1)*nxyz
     do isz=1,nz
        dz=dble(isz-io(3))*pmom3
        do isy=1,ny
           dy=dble(isy-io(2))*pmom2
           do isx=1,nx
              dx=dble(isx-io(1))*pmom1

              isp=isx+(isy-1)*nx+(isz-1)*nx*ny+itimz

              ffac(isp,1)=(cos(dx)+cos(dy)+cos(dz))/3.0_KR
              fas1(isp,1)=sin(dx)
              fas2(isp,1)=sin(dy)
              fas3(isp,1)=sin(dz)

              ffac(isp,2)=(cos(dx)*cos(dy)+cos(dx)*cos(dz)+cos(dy)*cos(dz))/3.0_KR
              fas1(isp,2)=sin(dx)*(cos(dy)+cos(dz))/2.0_KR
              fas2(isp,2)=sin(dy)*(cos(dx)+cos(dz))/2.0_KR
              fas3(isp,2)=sin(dz)*(cos(dx)+cos(dy))/2.0_KR

              ffac(isp,3)=cos(dx)*cos(dy)*cos(dz)
              fas1(isp,3)=sin(dx)*cos(dy)*cos(dz)
              fas2(isp,3)=sin(dy)*cos(dx)*cos(dz)
              fas3(isp,3)=sin(dz)*cos(dx)*cos(dy)

              ffac(isp,4)=(cos(2.0_KR*dx)+cos(2.0_KR*dy)+cos(2.0_KR*dz))/3.0_KR
              fas1(isp,4)=sin(2.0_KR*dx)
              fas2(isp,4)=sin(2.0_KR*dy)
              fas3(isp,4)=sin(2.0_KR*dz)

           enddo ! isx
        enddo ! isy
     enddo ! isz
  enddo ! itr

!     if (nps/=1) then
!       count=(nxyzt*4)
!       call MPI_BCAST(ffac(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!       call MPI_BCAST(fas1(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!       call MPI_BCAST(fas2(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!       call MPI_BCAST(fas3(1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
!     endif ! nps

  z2=0.0_KR
  z2i=0.0_KR
  z3=0.0_KR
  z3i=0.0_KR
! evenz2=0.0_KR
! oddz2=0.0_KR
  z2noise=0.0_KR
  z2inoise=0.0_KR

  sb1r=0.0_KR
  sb1i=0.0_KR
  sb2r=0.0_KR
  sb2i=0.0_KR
  sb3r=0.0_KR
  sb3i=0.0_KR
  sb4r=0.0_KR
  sb4i=0.0_KR
  sb5r=0.0_KR
  sb5i=0.0_KR
  sb6r=0.0_KR
  sb6i=0.0_KR

  ssb0r=0.0_KR
  ssb0i=0.0_KR
  ssb1r=0.0_KR
  ssb1i=0.0_KR
  ssb2r=0.0_KR
  ssb2i=0.0_KR
  ssb3r=0.0_KR
  ssb3i=0.0_KR
  ssb4r=0.0_KR
  ssb4i=0.0_KR
  ssb5r=0.0_KR
  ssb5i=0.0_KR
  ssb6r=0.0_KR
  ssb6i=0.0_KR

! These arrays are for the psuedoscalar
  z2sub = 0.0_KR 
! sub3r = 0.0_KR
! sub3i = 0.0_KR
! sub4r = 0.0_KR
! sub4i = 0.0_KR
! sub5r = 0.0_KR
! sub5i = 0.0_KR
! sub6r = 0.0_KR
! sub6i = 0.0_KR


!     Identify the location of my process
!     The main loop over all lattice sites and dirac and color indices

  call utouss(upart,uss,usp,numprocs,MRT,myid)


! NOTE~ The  subrouitne UINIT is used for debugging only. It allows specific creation
!       of simple gagauelinks. To execute UINIT, set the logical in the if statement
!       below to .true. (Should comment out subroutine utouss for effeciency)

  if (.false.) then
     call UINIT(usp,uss,fixbc,rwdir,myid)
  endif ! .false.

! Zero out the time edge for process zero before bcast to 
! MPI_COMM_WORLD.

! call printlog("Took out usp=0 in AVE!!",myid,rwdir)
! if (.false.) then
    if (fixbc) then
     if (myid==0) then
      do izz = 1,nz
         do iyy = 1,ny
            do ixx = 1,nx
               ipos = ixx + nx*(iyy-1) + nx*ny*(izz-1) + nx*ny*nz*(nt-1)
               do icolor1 = 1,nc
                  do icolor2 = 1,nc
                     usp(ipos,:,icolor1,icolor2)= 0.0_KR
                  enddo ! icolor2
               enddo ! icolor1
            enddo ! ixx
         enddo ! iyy
      enddo ! izz
    endif ! myid
  endif ! fixbc
!endif ! .false.

  if (nps/=1) then
      count=(nxyzt*3*nri*nc*nc)
      call MPI_BCAST(uss(1,1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
      count=(nxyzt*nri*nc*nc)
      call MPI_BCAST(usp(1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
  endif ! nps

! For the subroutine twaverage we must use the input vector of random z2 noise
!     instead of the unit vector z2 above.

  call changenoise(z2noise,z2inoise,be,bo,numprocs,MRT,myid)
  call printlog("exiting changenoise", myid,rwdir)

  if (nps/=1) then
      count = nxyzt*nc*nd
      call MPI_BCAST(z2noise(1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
  endif ! nps

! For the subroutine twaverage we must change the input propagators to
! fit our program and then use them to determine the correct additions
! to the main signal.

! ATTENTION :: To keep the normalizations correct between the non-perturbative
!              propagator we need to multiply the incoming xe and xo solutions
!              by kappa**2. This will make the diagnoal term of the e/o propagator
!              1.
  
 
! ABDOU ~ need to change the last index on xe, xo so that they can be multi-massed.
!         Also, this routine takes substaintial computer time. There are two choices....
!         loop over the routine (slower but easier) or do it internally (harder put potentially faster)

  call changevector(rpropagator(:,:,:,1), ipropagator(:,:,:,1),xe(:,:,:,:,:,1),xo(:,:,:,:,:,1),numprocs,MRT,myid)
  call printlog("exiting changevector", myid,rwdir)

  if (nps/=1) then
      count = nxyzt*nc*nd*1
      call MPI_BCAST(rpropagator(1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
      call MPI_BCAST(ipropagator(1,1,1,1),count,MRT,0,MPI_COMM_WORLD,ierr)
  endif ! nps

! Entering the loops over all spatial lattice points.

! do is = 1,nshifts

  cosd=cos(delta)
  sind=sin(delta)
  if (myid.eq.0) print *,'HERE IS DELTA2',delta
! stop

  xkappa=kappa*cosd

! ABDOU ~ Change these kappa values the same as in sburoutine twvev.

  xk(1)=xkappa
  xk(2)=xkappa**2
  xk(3)=xkappa**3
  xk(4)=xkappa**4
  xk(5)=xkappa**5
  xk(6)=xkappa**6


! WARNING WARNING WARNING WARNING WARNING WARNING
! We have restricted the time steps in the perturbative
! construction of the vev's in order to save time 7-16-05.

  ltime=1
  utime=nt

! Temp. false out of the perturbative part, which doesn't help
! with twisted scalar and pseudoscalar vevs.

! Put the subtraction part back in. -Abdou


if (.false.) then

  if (nsub/=0) then
      do ittt=ltime,utime
         do izz=1,nz
            do iyy=1,ny
               do ixx=1,nx
! Temp. changes
!     do ittt=4,4
!        do izz=1,1
!           do iyy=1,1
!              do ixx=1,1

!     A single index is used to specify a point in the lattice.
!     The mapping from a lattice site (x,y,z,t) to this single index is
!     index=x+(y-1)*nx+(z-1)*nx*ny+(t-1)*nx*ny*nz
!     "ihere" is the current lattice site from the main loop.

!     The "z2" array is zero everywhere (space-time) except at the current iteration
!     of the main loop.

                  ihere = ixx + nx*(iyy-1) + nx*ny*(izz-1) + nx*ny*nz*(ittt-1)
                  if (mod(ihere-1,numprocs) == myid) then


!     Multipication of overall cos(delta) done at intilization of input vector.
                  do idirac=1,nd
                     do icolor=1,nc
                        z2(ihere,icolor,idirac) = z2noise(ihere,icolor,idirac)
                        z3(ihere,icolor,idirac) = cosd*z2(ihere,icolor,idirac)
                     enddo ! icolor
                  enddo ! idirac

! I am getting rid of the initial rotation at the beginning.
! It is correct to actually do it at the end with the present
! version of GammaMultiply. -WW

if(.false.) then
                  do jc = 1,nc
                     sbr(1) = z3(ihere,jc,1)
                     sbr(2) = z3(ihere,jc,2)

                     z3(ihere,jc,1) = cosd*z3(ihere,jc,1) - sind*z3(ihere,jc,3)
                     z3(ihere,jc,2) = cosd*z3(ihere,jc,2) - sind*z3(ihere,jc,4)
                     z3(ihere,jc,3) = cosd*z3(ihere,jc,3) + sind*sbr(1)
                     z3(ihere,jc,4) = cosd*z3(ihere,jc,4) + sind*sbr(2)
                 enddo ! jc
endif ! false

!     The "sb*" arrays are now reset to zero in a more efficient way
!     at the end of the main loop.

!     This section is to do the first order subtraction from
!     the quark propagator.

!     The "Multiply" subroutine generates the next subtraction level
!     from the last one.
!     At first order, "sb1r" and "sb1i" are generated from "z2" and "z2i".
!     "Multiply" actually computes the effect that one element of "z2" and
!     "z2i" has on "sb1r" and "sb1i".  Thus, "Multiply" must be called
!     once for every nonzero point of "z2" and "z2i".

     Call GammaMultiply(sb1r,sb1i,z3,z3i,ixx,iyy,izz,&
                   ittt,usp,uss,fixbc,ir,myid)


!
!     Do second order
!
  md=1

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

            Call GammaMultiply(sb2r,sb2i,sb1r,sb1i,tempx,tempy,tempz,&
                        temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt
               Call GammaMultiply(sb2r,sb2i,sb1r,sb1i,tempx,tempy,tempz,&
                                   temptminus,usp,uss,fixbc,ir,myid)
           end if ! bt/=0

        end do ! bz
     end do ! by
  end do ! bx


!     Do third order

      Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,ixx,iyy,izz,&
                          ittt,usp,uss,fixbc,ir,myid)

  md=2

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb3r,sb3i,sb2r,sb2i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! bt/=0
        end do ! bz
     end do ! by
  end do ! bx


!     Do fourth order


  md=1

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order terms have been removed for
! nsub==4. In addition, I am removing the md=3 part of 4th order.
! This will make only a partial subtraction on the noise for
! vectors, but not affect the subtraction to this order for the scalar.
! Done to save time before Dublin conference. 7-16-05

!         if(nsub==6) then

  md=3

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb4r,sb4i,sb3r,sb3i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order terms have been removed for
! nsub==4.
! Done to save time before Dublin conference. 7-16-05

  if (nsub==6) then

!     Do fifth order (all points now)

      Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,ixx,iyy,izz,&
                              ittt,usp,uss,fixbc,ir,myid)

  md=2

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! This is an extension of the fifth order subtraction.

  md=4

  do bx=-md,md
     do by= -(md-abs(bx)),md-abs(bx)
        do bz= -(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb5r,sb5i,sb4r,sb4i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx


!     Do sixth order (all points)

  md=1

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

! This is an extension to sixth order.

  md=3

  do bx=-md,md
     do by=-(md-abs(bx)),md-abs(bx)
        do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

  md=5

   do bx=-md,md
     do by= -(md-abs(bx)),md-abs(bx)
        do bz= -(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
           bt=md-abs(bx)-abs(by)-abs(bz)

           ax=ixx+bx
           ay=iyy+by
           az=izz+bz
           at=ittt+bt

           ax=mod(ax-1+nx,nx)+1
           ay=mod(ay-1+ny,ny)+1
           az=mod(az-1+nz,nz)+1
           at=mod(at-1+nt,nt)+1

           ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

           tempx = ixx+bx
           tempy = iyy+by
           tempz = izz+bz
           temptplus = ittt+bt

           Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                   temptplus,usp,uss,fixbc,ir,myid)

           if (bt/=0) then
               at=ittt-bt
               at=mod(at-1+nt,nt)+1
               ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

               tempx = ixx+bx
               tempy = iyy+by
               tempz = izz+bz
               temptminus=ittt-bt

               Call GammaMultiply(sb6r,sb6i,sb5r,sb5i,tempx,tempy,tempz,&
                                       temptminus,usp,uss,fixbc,ir,myid)
           end if ! (bt/=0)
        end do ! bz
     end do ! by
  end do ! bx

  endif ! nsub==6


! ####################################################################

! This is the end


  do jd=1,nd
     do jc=1,nc

        if (nsub==6) then

            md=6
            do bx=-md,md
               do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1

                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                     ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                     sb6r(ahere,jc,jd)=0.0_KR
                     sb6i(ahere,jc,jd)=0.0_KR
                     if (bt/=0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                         ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                         sb6r(ahere,jc,jd)=0.0_KR
                         sb6i(ahere,jc,jd)=0.0_KR
                     end if ! (bt/=0)
                  end do ! bz
               end do ! by
            end do ! bx

            md=5
            do bx=-md,md
               do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1

                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                     ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                     sb5r(ahere,jc,jd)=0.0_KR
                     sb5i(ahere,jc,jd)=0.0_KR
                     if (bt/=0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                         ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                         sb5r(ahere,jc,jd)=0.0_KR
                         sb5i(ahere,jc,jd)=0.0_KR
                     end if ! (bt/=0)
                  end do ! bz
               end do ! by
            end do ! bx

            md=4
            do bx=-md,md
               do by=-(md-abs(bx)),md-abs(bx)
                  do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                     bt=md-abs(bx)-abs(by)-abs(bz)

                     ax=ixx+bx
                     ay=iyy+by
                     az=izz+bz
                     at=ittt+bt

                     ax=mod(ax-1+nx,nx)+1
                     ay=mod(ay-1+ny,ny)+1
                     az=mod(az-1+nz,nz)+1
                     at=mod(at-1+nt,nt)+1


                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                     ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                     ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                     ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                     sb6r(ahere,jc,jd)=0.0_KR
                     sb6i(ahere,jc,jd)=0.0_KR
                     sb4r(ahere,jc,jd)=0.0_KR
                     sb4i(ahere,jc,jd)=0.0_KR
                     if (bt/=0) then
                         at=ittt-bt
                         at=mod(at-1+nt,nt)+1
                         ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                         ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                         ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)
                         ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                         ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                         sb6r(ahere,jc,jd)=0.0_KR
                         sb6i(ahere,jc,jd)=0.0_KR
                         sb4r(ahere,jc,jd)=0.0_KR
                         sb4i(ahere,jc,jd)=0.0_KR
                     end if ! (bt/=0)
                  end do ! bz
               end do ! by
            end do ! bx

! WARNING, WARNING, WARNING, WARNING !!!!!
! The fifth and sixth order zeroing has been commented out below for
! nsub==4. For nsub==6 you need to put back these values!

       endif ! nsub==6

       md=3
       do bx=-md,md
          do by=-(md-abs(bx)),md-abs(bx)
              do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                 bt=md-abs(bx)-abs(by)-abs(bz)

                 ax=ixx+bx
                 ay=iyy+by
                 az=izz+bz
                 at=ittt+bt

                 ax=mod(ax-1+nx,nx)+1
                 ay=mod(ay-1+ny,ny)+1
                 az=mod(az-1+nz,nz)+1
                 at=mod(at-1+nt,nt)+1


                 ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                 ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                 ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                 ssb3r(ahere,jc,jd)=ssb3r(ahere,jc,jd)+sb3r(ahere,jc,jd)
                 ssb3i(ahere,jc,jd)=ssb3i(ahere,jc,jd)+sb3i(ahere,jc,jd)

                 sb5r(ahere,jc,jd)=0.0_KR
                 sb5i(ahere,jc,jd)=0.0_KR
                 sb3r(ahere,jc,jd)=0.0_KR
                 sb3i(ahere,jc,jd)=0.0_KR

                 if (bt/=0) then
                     at=ittt-bt
                     at=mod(at-1+nt,nt)+1
                     ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
                     ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                     ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)
                     ssb3r(ahere,jc,jd)=ssb3r(ahere,jc,jd)+sb3r(ahere,jc,jd)
                     ssb3i(ahere,jc,jd)=ssb3i(ahere,jc,jd)+sb3i(ahere,jc,jd)

                     sb5r(ahere,jc,jd)=0.0_KR
                     sb5i(ahere,jc,jd)=0.0_KR
                     sb3r(ahere,jc,jd)=0.0_KR
                     sb3i(ahere,jc,jd)=0.0_KR

                 end if ! (bt/=0)
              end do ! bz
           end do ! by
        end do ! bx

        md=2
        do bx=-md,md
           do by=-(md-abs(bx)),md-abs(bx)
              do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                 bt=md-abs(bx)-abs(by)-abs(bz)
                !do bt=-(md-abs(bx)-abs(by)-abs(bz)),md-abs(bx)-abs(by)-abs(bz)

                    ax=ixx+bx
                    ay=iyy+by
                    az=izz+bz
                    at=ittt+bt

                    ax=mod(ax-1+nx,nx)+1
                    ay=mod(ay-1+ny,ny)+1
                    az=mod(az-1+nz,nz)+1
                    at=mod(at-1+nt,nt)+1

                    ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

                    ssb2r(ahere,jc,jd)=ssb2r(ahere,jc,jd)+sb2r(ahere,jc,jd)
                    ssb2i(ahere,jc,jd)=ssb2i(ahere,jc,jd)+sb2i(ahere,jc,jd)
                    ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                    ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                    ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                    ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)

                    sb2r(ahere,jc,jd)=0.0_KR
                    sb2i(ahere,jc,jd)=0.0_KR
                    sb4r(ahere,jc,jd)=0.0_KR
                    sb4i(ahere,jc,jd)=0.0_KR
                    sb6r(ahere,jc,jd)=0.0_KR
                    sb6i(ahere,jc,jd)=0.0_KR

                 if (bt/=0) then
                    at=ittt-bt
                    at=mod(at-1+nt,nt)+1
                    ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

                    ssb2r(ahere,jc,jd)=ssb2r(ahere,jc,jd)+sb2r(ahere,jc,jd)
                    ssb2i(ahere,jc,jd)=ssb2i(ahere,jc,jd)+sb2i(ahere,jc,jd)
                    ssb4r(ahere,jc,jd)=ssb4r(ahere,jc,jd)+sb4r(ahere,jc,jd)
                    ssb4i(ahere,jc,jd)=ssb4i(ahere,jc,jd)+sb4i(ahere,jc,jd)
                    ssb6r(ahere,jc,jd)=ssb6r(ahere,jc,jd)+sb6r(ahere,jc,jd)
                    ssb6i(ahere,jc,jd)=ssb6i(ahere,jc,jd)+sb6i(ahere,jc,jd)

                    sb2r(ahere,jc,jd)=0.0_KR
                    sb2i(ahere,jc,jd)=0.0_KR
                    sb4r(ahere,jc,jd)=0.0_KR
                    sb4i(ahere,jc,jd)=0.0_KR
                    sb6r(ahere,jc,jd)=0.0_KR
                    sb6i(ahere,jc,jd)=0.0_KR

                 end if ! (bt/=0)

                !end do ! bt
              end do ! bz
           end do ! by
        end do ! bx


        md=1
        do bx=-md,md
           do by=-(md-abs(bx)),md-abs(bx)
              do bz=-(md-abs(bx)-abs(by)),md-abs(bx)-abs(by)
                 do bt=-(md-abs(bx)-abs(by)-abs(bz)),md-abs(bx)-abs(by)-abs(bz)

                    ax=ixx+bx
                    ay=iyy+by
                    az=izz+bz
                    at=ittt+bt

                    ax=mod(ax-1+nx,nx)+1
                    ay=mod(ay-1+ny,ny)+1
                    az=mod(az-1+nz,nz)+1
                    at=mod(at-1+nt,nt)+1

                    ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

                    ssb1r(ahere,jc,jd)=ssb1r(ahere,jc,jd)+sb1r(ahere,jc,jd)
                    ssb1i(ahere,jc,jd)=ssb1i(ahere,jc,jd)+sb1i(ahere,jc,jd)
                    ssb3r(ahere,jc,jd)=ssb3r(ahere,jc,jd)+sb3r(ahere,jc,jd)
                    ssb3i(ahere,jc,jd)=ssb3i(ahere,jc,jd)+sb3i(ahere,jc,jd)
                    ssb5r(ahere,jc,jd)=ssb5r(ahere,jc,jd)+sb5r(ahere,jc,jd)
                    ssb5i(ahere,jc,jd)=ssb5i(ahere,jc,jd)+sb5i(ahere,jc,jd)

                    sb1r(ahere,jc,jd)=0.0_KR
                    sb1i(ahere,jc,jd)=0.0_KR
                    sb3r(ahere,jc,jd)=0.0_KR
                    sb3i(ahere,jc,jd)=0.0_KR
                    sb5r(ahere,jc,jd)=0.0_KR
                    sb5i(ahere,jc,jd)=0.0_KR

                 end do ! bt
              end do ! bz
           end do ! by
        end do ! bx

! What about md=0?????????????? This would add up contributions
! that get back to the origin, ihere. -WW

!       md=0
        ssb2r(ihere,jc,jd)=ssb2r(ihere,jc,jd)+sb2r(ihere,jc,jd)
        ssb4r(ihere,jc,jd)=ssb4r(ihere,jc,jd)+sb4r(ihere,jc,jd)
        ssb6r(ihere,jc,jd)=ssb6r(ihere,jc,jd)+sb6r(ihere,jc,jd)
        sb2r(ihere,jc,jd) = 0.0_KR
        sb4r(ihere,jc,jd) = 0.0_KR
        sb6r(ihere,jc,jd) = 0.0_KR
        ssb2i(ihere,jc,jd)=ssb2i(ihere,jc,jd)+sb2i(ihere,jc,jd)
        ssb4i(ihere,jc,jd)=ssb4i(ihere,jc,jd)+sb4i(ihere,jc,jd)
        ssb6i(ihere,jc,jd)=ssb6i(ihere,jc,jd)+sb6i(ihere,jc,jd)
        sb2i(ihere,jc,jd) = 0.0_KR
        sb4i(ihere,jc,jd) = 0.0_KR
        sb6i(ihere,jc,jd) = 0.0_KR


     end do ! jc
  end do ! jd


! This is the end of the big loops over the intial lattice point.

              z2(ihere,:,:) = 0.0_KR
              z3(ihere,:,:) = 0.0_KR

              endif ! mod(numprocs) ! PUT THIS IN!!!!!
           enddo ! ixx
        enddo ! iyy
     enddo ! izz
  enddo ! ittt



! This is where I will try putting in the rotations at the end.
! Note all processors are working on their part before the
! data is combined. -WW

                do ihere = 1, nx*ny*nz*nt
                 do jc = 1,nc
! ssb1r,i case
                     sbr(1) = ssb1r(ihere,jc,1)
                     sbr(2) = ssb1r(ihere,jc,2)

                     ssb1r(ihere,jc,1) = cosd*ssb1r(ihere,jc,1) - sind*ssb1r(ihere,jc,3)
                     ssb1r(ihere,jc,2) = cosd*ssb1r(ihere,jc,2) - sind*ssb1r(ihere,jc,4)
                     ssb1r(ihere,jc,3) = cosd*ssb1r(ihere,jc,3) + sind*sbr(1)
                     ssb1r(ihere,jc,4) = cosd*ssb1r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb1i(ihere,jc,1)
                     sbi(2) = ssb1i(ihere,jc,2)

                     ssb1i(ihere,jc,1) = cosd*ssb1i(ihere,jc,1) - sind*ssb1i(ihere,jc,3)
                     ssb1i(ihere,jc,2) = cosd*ssb1i(ihere,jc,2) - sind*ssb1i(ihere,jc,4)
                     ssb1i(ihere,jc,3) = cosd*ssb1i(ihere,jc,3) + sind*sbi(1)
                     ssb1i(ihere,jc,4) = cosd*ssb1i(ihere,jc,4) + sind*sbi(2)

! ssb2r,i case
                     sbr(1) = ssb2r(ihere,jc,1)
                     sbr(2) = ssb2r(ihere,jc,2)

                     ssb2r(ihere,jc,1) = cosd*ssb2r(ihere,jc,1) - sind*ssb2r(ihere,jc,3)
                     ssb2r(ihere,jc,2) = cosd*ssb2r(ihere,jc,2) - sind*ssb2r(ihere,jc,4)
                     ssb2r(ihere,jc,3) = cosd*ssb2r(ihere,jc,3) + sind*sbr(1)
                     ssb2r(ihere,jc,4) = cosd*ssb2r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb2i(ihere,jc,1)
                     sbi(2) = ssb2i(ihere,jc,2)

                     ssb2i(ihere,jc,1) = cosd*ssb2i(ihere,jc,1) - sind*ssb2i(ihere,jc,3)
                     ssb2i(ihere,jc,2) = cosd*ssb2i(ihere,jc,2) - sind*ssb2i(ihere,jc,4)
                     ssb2i(ihere,jc,3) = cosd*ssb2i(ihere,jc,3) + sind*sbi(1)
                     ssb2i(ihere,jc,4) = cosd*ssb2i(ihere,jc,4) + sind*sbi(2)

! ssb3r,i case
                     sbr(1) = ssb3r(ihere,jc,1)
                     sbr(2) = ssb3r(ihere,jc,2)

                     ssb3r(ihere,jc,1) = cosd*ssb3r(ihere,jc,1) - sind*ssb3r(ihere,jc,3)
                     ssb3r(ihere,jc,2) = cosd*ssb3r(ihere,jc,2) - sind*ssb3r(ihere,jc,4)
                     ssb3r(ihere,jc,3) = cosd*ssb3r(ihere,jc,3) + sind*sbr(1)
                     ssb3r(ihere,jc,4) = cosd*ssb3r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb3i(ihere,jc,1)
                     sbi(2) = ssb3i(ihere,jc,2)

                     ssb3i(ihere,jc,1) = cosd*ssb3i(ihere,jc,1) - sind*ssb3i(ihere,jc,3)
                     ssb3i(ihere,jc,2) = cosd*ssb3i(ihere,jc,2) - sind*ssb3i(ihere,jc,4)
                     ssb3i(ihere,jc,3) = cosd*ssb3i(ihere,jc,3) + sind*sbi(1)
                     ssb3i(ihere,jc,4) = cosd*ssb3i(ihere,jc,4) + sind*sbi(2)

! ssb4r,i case
                     sbr(1) = ssb4r(ihere,jc,1)
                     sbr(2) = ssb4r(ihere,jc,2)

                     ssb4r(ihere,jc,1) = cosd*ssb4r(ihere,jc,1) - sind*ssb4r(ihere,jc,3)
                     ssb4r(ihere,jc,2) = cosd*ssb4r(ihere,jc,2) - sind*ssb4r(ihere,jc,4)
                     ssb4r(ihere,jc,3) = cosd*ssb4r(ihere,jc,3) + sind*sbr(1)
                     ssb4r(ihere,jc,4) = cosd*ssb4r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb4i(ihere,jc,1)
                     sbi(2) = ssb4i(ihere,jc,2)

                     ssb4i(ihere,jc,1) = cosd*ssb4i(ihere,jc,1) - sind*ssb4i(ihere,jc,3)
                     ssb4i(ihere,jc,2) = cosd*ssb4i(ihere,jc,2) - sind*ssb4i(ihere,jc,4)
                     ssb4i(ihere,jc,3) = cosd*ssb4i(ihere,jc,3) + sind*sbi(1)
                     ssb4i(ihere,jc,4) = cosd*ssb4i(ihere,jc,4) + sind*sbi(2)

! ssb5r,i case
                     sbr(1) = ssb5r(ihere,jc,1)
                     sbr(2) = ssb5r(ihere,jc,2)

                     ssb5r(ihere,jc,1) = cosd*ssb5r(ihere,jc,1) - sind*ssb5r(ihere,jc,3)
                     ssb5r(ihere,jc,2) = cosd*ssb5r(ihere,jc,2) - sind*ssb5r(ihere,jc,4)
                     ssb5r(ihere,jc,3) = cosd*ssb5r(ihere,jc,3) + sind*sbr(1)
                     ssb5r(ihere,jc,4) = cosd*ssb5r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb5i(ihere,jc,1)
                     sbi(2) = ssb5i(ihere,jc,2)

                     ssb5i(ihere,jc,1) = cosd*ssb5i(ihere,jc,1) - sind*ssb5i(ihere,jc,3)
                     ssb5i(ihere,jc,2) = cosd*ssb5i(ihere,jc,2) - sind*ssb5i(ihere,jc,4)
                     ssb5i(ihere,jc,3) = cosd*ssb5i(ihere,jc,3) + sind*sbi(1)
                     ssb5i(ihere,jc,4) = cosd*ssb5i(ihere,jc,4) + sind*sbi(2)

! ssb6r,i case
                     sbr(1) = ssb6r(ihere,jc,1)
                     sbr(2) = ssb6r(ihere,jc,2)

                     ssb6r(ihere,jc,1) = cosd*ssb6r(ihere,jc,1) - sind*ssb6r(ihere,jc,3)
                     ssb6r(ihere,jc,2) = cosd*ssb6r(ihere,jc,2) - sind*ssb6r(ihere,jc,4)
                     ssb6r(ihere,jc,3) = cosd*ssb6r(ihere,jc,3) + sind*sbr(1)
                     ssb6r(ihere,jc,4) = cosd*ssb6r(ihere,jc,4) + sind*sbr(2)

                     sbi(1) = ssb6i(ihere,jc,1)
                     sbi(2) = ssb6i(ihere,jc,2)

                     ssb6i(ihere,jc,1) = cosd*ssb6i(ihere,jc,1) - sind*ssb6i(ihere,jc,3)
                     ssb6i(ihere,jc,2) = cosd*ssb6i(ihere,jc,2) - sind*ssb6i(ihere,jc,4)
                     ssb6i(ihere,jc,3) = cosd*ssb6i(ihere,jc,3) + sind*sbi(1)
                     ssb6i(ihere,jc,4) = cosd*ssb6i(ihere,jc,4) + sind*sbi(2)
                 enddo ! jc
                enddo ! ihere

  
  total=0.0_KR
 
! Need to gather to data from each process.
! ATTENTION :: Now that ecah process has a "chunk" of the total contribution
!              of the perturbative propagator for each "ihere", we must
!              sum all contributions from each process. Each subtraction 
!              level calls MPI_ALLREDUCE to do this.

  if (nps /= 1) then
     count = nxyzt * nc * nd
     call MPI_ALLREDUCE(ssb1r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb1r = total
     call MPI_ALLREDUCE(ssb1i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb1i = total
     call MPI_ALLREDUCE(ssb2r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb2r = total
     call MPI_ALLREDUCE(ssb2i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb2i = total
     call MPI_ALLREDUCE(ssb3r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb3r = total
     call MPI_ALLREDUCE(ssb3i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb3i = total
     call MPI_ALLREDUCE(ssb4r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb4r = total
     call MPI_ALLREDUCE(ssb4i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb4i = total
     call MPI_ALLREDUCE(ssb5r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb5r = total
     call MPI_ALLREDUCE(ssb5i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb5i = total
     call MPI_ALLREDUCE(ssb6r,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb6r = total
     call MPI_ALLREDUCE(ssb6i,total,count,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
     ssb6i = total
  endif ! nps check

  endif ! (nsub/=0)

endif ! .false.

! End of large false out.


! We need to subrtact each subtraction level from the propagator
! that is non-trivial...for isb=0 (nsub=4) kappa^3, kappa^4 and
! for isb=1 (nsub=6) kappa^5, kappa^6.

! WARNING WARNING WARNING WARNING WARNING WARNING
! We have restricted the time steps in the perturbative
! construction of the vev's in order to save time 7-16-05.

  ! z2noise = cosd*z2noise
 

  do ittt=ltime,utime
     do izz=1,nz
        do iyy=1,ny
           do ixx=1,nx
 
              ihere=ixx+nx*(iyy-1)+nx*ny*(izz-1)+nx*ny*nz*(ittt-1)

! Here is the debugging stuff for examining the perturbative and nonperturbative
! propagators. -WW

if(.false.) then
           if (myid.eq.0) then
   open(unit=99,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",action="write",&
        form="formatted",position="append",status="old")
            do idirac=1,nd
            do icolor=1,nc
            if (abs(z2noise(ihere,icolor,idirac)).gt.1.e-4) then
             write(unit=99,fmt="(a35,6i4,e24.16)") "idirac,icolor,ix,iy,iz,it,z2noise",idirac,icolor,ixx,iyy,izz,ittt,z2noise(ihere,icolor,idirac)
            endif
             enddo ! idirac
             enddo ! icolor

            do idirac=1,nd
            do icolor=1,nc
            if (abs(rpropagator(ihere,icolor,idirac,1)).gt.1.e-16.or.abs(ipropagator(ihere,icolor,idirac,1)).gt.1.e-16) then

             xxr = cosd*(cosd*z2noise(ihere,icolor,idirac)- sign(idirac)*sind*z2noise(ihere,icolor,cd(idirac))) & 
                           + xk(1)*ssb1r(ihere,icolor,idirac) + xk(2)*ssb2r(ihere,icolor,idirac)&
                           + xk(3)*ssb3r(ihere,icolor,idirac) + xk(4)*ssb4r(ihere,icolor,idirac)&
                           + xk(5)*ssb5r(ihere,icolor,idirac) + xk(6)*ssb6r(ihere,icolor,idirac)
             xxi =           xk(1)*ssb1i(ihere,icolor,idirac)&
                           + xk(2)*ssb2i(ihere,icolor,idirac) + xk(3)*ssb3i(ihere,icolor,idirac)&
                           + xk(4)*ssb4i(ihere,icolor,idirac) + xk(5)*ssb5i(ihere,icolor,idirac)&
                           + xk(6)*ssb6i(ihere,icolor,idirac)
             write(unit=99,fmt="(6i4,a6,2e24.16)") icolor,idirac,ixx,iyy,izz,ittt,"real",rpropagator(ihere,icolor,idirac,1), xxr
             write(unit=99,fmt="(6i4,a6,2e24.16)") icolor,idirac,ixx,iyy,izz,ittt,"imag",ipropagator(ihere,icolor,idirac,1), xxi
            endif
             enddo ! idirac
             enddo ! icolor
   close(unit=99, status="keep")
           endif ! myid
endif ! false

 
              if (mod(ihere-1,numprocs) == myid) then
                 do idirac=1,nd
                    do icolor=1,nc

  z2(ihere,icolor,idirac)        = z2noise(ihere,icolor,idirac)

! z2sub is the noise used to for the Imaginary part of the
! pseduo-scalar.
! Abdou - Do we need the factor of cosd?

  z2sub(ihere,icolor,cd(idirac)) = z2noise(ihere,icolor,cd(idirac))

  leftx=mod((ixx-1)-1+nx,nx)+1
  rightx=mod((ixx+1)-1+nx,nx)+1
  lefty=mod((iyy-1)-1+ny,ny)+1
  righty=mod((iyy+1)-1+ny,ny)+1
  leftz=mod((izz-1)-1+nz,nz)+1
  rightz=mod((izz+1)-1+nz,nz)+1
  leftt=mod((ittt-1)-1+nt,nt)+1
  rightt=mod((ittt+1)-1+nt,nt)+1

!     Translate coordinates to single array index

  leftx=leftx+(iyy-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  rightx=rightx+(iyy-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  lefty=ixx+(lefty-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  righty=ixx+(righty-1)*nx+(izz-1)*nx*ny+(ittt-1)*nx*ny*nz
  leftz=ixx+(iyy-1)*nx+(leftz-1)*nx*ny+(ittt-1)*nx*ny*nz
  rightz=ixx+(iyy-1)*nx+(rightz-1)*nx*ny+(ittt-1)*nx*ny*nz
  leftt=ixx+(iyy-1)*nx+(izz-1)*nx*ny+(leftt-1)*nx*ny*nz
  rightt=ixx+(iyy-1)*nx+(izz-1)*nx*ny+(rightt-1)*nx*ny*nz

  imv(1)=ihere
  imv(2)=leftx
  imv(3)=rightx
  imv(4)=lefty
  imv(5)=righty
  imv(6)=leftz
  imv(7)=rightz
  imv(8)=leftt
  imv(9)=rightt


  jc=icolor
  jd=idirac

! These are the arrays used for the psuedo-scalar. The gamma5 multiplication below
! requires information about ALL 4 dirac sites.
! Dean: All the sub's need attention!!!

! sub3r(ihere,jc,idirac) = rpropagator(ihere,jc,cd(idirac),1) - z2sub(ihere,jc,cd(idirac)) &
!w  sub3r(ihere,jc,idirac) = rpropagator(ihere,jc,cd(idirac),1) &
!w                           - xk(1)*ssb1r(ihere,jc,cd(idirac)) - xk(2)*ssb2r(ihere,jc,cd(idirac))&
!w                           - xk(3)*ssb3r(ihere,jc,cd(idirac))
! Temp. change.
! sub3r(ihere,jc,idirac) = - xk(1)*ssb1r(ihere,jc,cd(idirac)) - xk(2)*ssb2r(ihere,jc,cd(idirac))&
!                          - xk(3)*ssb3r(ihere,jc,cd(idirac))

!w  sub3i(ihere,jc,idirac) = ipropagator(ihere,jc,cd(idirac),1) - xk(1)*ssb1i(ihere,jc,cd(idirac))&
!w                           - xk(2)*ssb2i(ihere,jc,cd(idirac)) - xk(3)*ssb3i(ihere,jc,cd(idirac))
! Temp. change.
! sub3i(ihere,jc,idirac) = - xk(1)*ssb1i(ihere,jc,cd(idirac)) - xk(2)*ssb2i(ihere,jc,cd(idirac))&
!                          - xk(3)*ssb3i(ihere,jc,cd(idirac))

! Making this non cumulative --!w

! Now that sub3 has been multiplied by gamma5, there is no need to use cd(idirac)
! when assigning sub4i because sub3 has been "gammified".
! The same is true of sub4i when assining sub5i and soforth.

!w  sub4r(ihere,jc,idirac) = sub3r(ihere,jc,idirac) - xk(4)*ssb4r(ihere,jc,cd(idirac))
!w  sub4i(ihere,jc,idirac) = sub3i(ihere,jc,idirac) - xk(4)*ssb4i(ihere,jc,cd(idirac))

!w  sub5r(ihere,jc,idirac) = sub4r(ihere,jc,idirac) - xk(5)*ssb5r(ihere,jc,cd(idirac))
!w  sub5i(ihere,jc,idirac) = sub4i(ihere,jc,idirac) - xk(5)*ssb5i(ihere,jc,cd(idirac))

!w  sub6r(ihere,jc,idirac) = sub5r(ihere,jc,idirac) - xk(6)*ssb6r(ihere,jc,cd(idirac))
!w  sub6i(ihere,jc,idirac) = sub5i(ihere,jc,idirac) - xk(6)*ssb6i(ihere,jc,cd(idirac))


!****ATTENTION*** Odd terms have been moved from plus to minus....02-17-06
!                 The cumulative subtracted propagator (ssbr and ssbi) are
!                 rewritten. Each order has knowledge of the previous one.

 
! The ssbr's and ssbi's have a spatial sum done above. It represents
!     all the contributions to a given ihere due to the multiplications
!     of GammaMultiply.

! ssb0r(ihere,jc,jd) = rpropagator(ihere,jc,jd,1) - cosd*z2(ihere,jc,jd) 
!w  ssb0r(ihere,jc,jd) = rpropagator(ihere,jc,jd,1)
! Temp. change to display perturbative result.
! ssb0r(ihere,jc,jd) = 0.0_KR
!w  ssb0i(ihere,jc,jd) = ipropagator(ihere,jc,jd,1) 
! Temp. change.
! ssb0i(ihere,jc,jd) = 0.0_KR

!w  ssb1r(ihere,jc,jd) = ssb0r(ihere,jc,jd) - xk(1)*ssb1r(ihere,jc,jd)
!w  ssb1i(ihere,jc,jd) = ssb0i(ihere,jc,jd) - xk(1)*ssb1i(ihere,jc,jd)

!w  ssb2r(ihere,jc,jd) = ssb1r(ihere,jc,jd) - xk(2)*ssb2r(ihere,jc,jd) 
!w  ssb2i(ihere,jc,jd) = ssb1i(ihere,jc,jd) - xk(2)*ssb2i(ihere,jc,jd) 

!w  ssb3r(ihere,jc,jd) = ssb2r(ihere,jc,jd) - xk(3)*ssb3r(ihere,jc,jd)
!w  ssb3i(ihere,jc,jd) = ssb2i(ihere,jc,jd) - xk(3)*ssb3i(ihere,jc,jd)

!w  ssb4r(ihere,jc,jd) = ssb3r(ihere,jc,jd) - xk(4)*ssb4r(ihere,jc,jd)
!w  ssb4i(ihere,jc,jd) = ssb3i(ihere,jc,jd) - xk(4)*ssb4i(ihere,jc,jd)

!w  ssb5r(ihere,jc,jd) = ssb4r(ihere,jc,jd) - xk(5)*ssb5r(ihere,jc,jd)
!w  ssb5i(ihere,jc,jd) = ssb4i(ihere,jc,jd) - xk(5)*ssb5i(ihere,jc,jd)

!w  if (nsub==6) then
!w      ssb6r(ihere,jc,jd) = ssb5r(ihere,jc,jd) - xk(6)*ssb6r(ihere,jc,jd)
!w      ssb6i(ihere,jc,jd) = ssb5i(ihere,jc,jd) - xk(6)*ssb6i(ihere,jc,jd)
!w  endif ! nsub
  
!
! Need to keep the unsubtracted propagator (nsub=1) kappa^0 which
! corresponds to (isb=0).


! Now do subtracted operator expectation values
   do jri=1,nri
     if (nsub==0) usub = 0
     if (nsub==4) usub = 1
     if (nsub==6) usub = 2

         do isb=0,usub
            IF (jri.eq.1) THEN
                if (isb.eq.0) then
!www                   sprop(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
!www                                    - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
                   sprop(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                    - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
                   pscalar(ihere) = sign(idirac)*ipropagator(ihere,icolor,cd(idirac),1)

                else if(isb.eq.1) then
! Putting in perturbative elements. This is 2nd order. This is wrong at this level for currents.
!www                   s0(ihere)   = xk(1)*ssb1r(ihere,icolor,idirac)+xk(3)*ssb3r(ihere,icolor,idirac)
!www                   s1(ihere)   = xk(2)*ssb2r(ihere,icolor,idirac)
!www                   pscalar(ihere) = xk(2)*sign(idirac)*ssb2i(ihere,icolor,cd(idirac))

                       s0(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) &
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac)
! Need to experiment with source terms below. -WW
                       s1(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) & 
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac) &
                                     - xk(4)*ssb4r(ihere,icolor,idirac) 
                       pscalar(ihere) = sign(idirac)*(ipropagator(ihere,icolor,cd(idirac),1) &
                                     -xk(1)*ssb1i(ihere,icolor,cd(idirac)) &
                                     -xk(2)*ssb2i(ihere,icolor,cd(idirac)) &
                                     -xk(3)*ssb3i(ihere,icolor,cd(idirac)) &
                                     -xk(4)*ssb4i(ihere,icolor,cd(idirac)))

!                   s0(ihere)      = ssb4r(ihere,icolor,idirac)
!w                    s0(ihere)      = ssb4r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))

!                   s1(ihere)      = ssb5r(ihere,icolor,idirac) + z2(ihere,icolor,idirac)
!w                    s1(ihere)      = ssb5r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
!                   s1(ihere)      = ssb5r(ihere,icolor,idirac)+cosd*sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))
!                   s1(ihere)      = ssb5r(ihere,icolor,idirac)
!w                    pscalar(ihere) = sign(idirac)*sub5i(ihere,icolor,idirac)

                else if(isb.eq.2) then
! Temp. change for 4th order.
!www                    s0(ihere)      = xk(5)*ssb5r(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    s1(ihere)      = xk(4)*ssb4r(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    pscalar(ihere) = xk(4)*sign(idirac)*ssb4i(ihere,icolor,cd(idirac))

                       s0(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) &
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac) &
                                     - xk(4)*ssb4r(ihere,icolor,idirac) &
                                     - xk(5)*ssb5r(ihere,icolor,idirac) &
                                     - xk(6)*ssb6r(ihere,icolor,idirac)
! Need to experiment with source terms below. -WW
                       s1(ihere)   = rpropagator(ihere,icolor,idirac,1)-cosd*(cosd*z2(ihere,icolor,idirac) &
                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))) & 
                                     - xk(1)*ssb1r(ihere,icolor,idirac) &
                                     - xk(2)*ssb2r(ihere,icolor,idirac) &
                                     - xk(3)*ssb3r(ihere,icolor,idirac) &
                                     - xk(4)*ssb4r(ihere,icolor,idirac) &
                                     - xk(5)*ssb5r(ihere,icolor,idirac) &
                                     - xk(6)*ssb6r(ihere,icolor,idirac)
                       pscalar(ihere) = sign(idirac)*(ipropagator(ihere,icolor,cd(idirac),1) &
                                     -xk(1)*ssb1i(ihere,icolor,cd(idirac)) &
                                     -xk(2)*ssb2i(ihere,icolor,cd(idirac)) &
                                     -xk(3)*ssb3i(ihere,icolor,cd(idirac)) &
                                     -xk(4)*ssb4i(ihere,icolor,cd(idirac)) &
                                     -xk(5)*ssb5i(ihere,icolor,cd(idirac)) &
                                     -xk(6)*ssb6i(ihere,icolor,cd(idirac)))

!                   s0(ihere)      = ssb6r(ihere,icolor,idirac)
!w                    s0(ihere)      = ssb6r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
! Temp. change for 6th order.
!ww                    s0(ihere)      = xk(5)*ssb5r(ihere,icolor,idirac)

!                   s1(ihere)      = ssb6r(ihere,icolor,idirac) + z2(ihere,icolor,idirac)
!w                    s1(ihere)      = ssb6r(ihere,icolor,idirac)-cosd*(cosd*z2(ihere,icolor,idirac) &
!w                                     - sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac)))
! Temp. change for 6th order.
!ww                    s1(ihere)      = xk(6)*ssb6r(ihere,icolor,idirac)

!                   s1(ihere)      = ssb6r(ihere,icolor,idirac)+cosd*sign(idirac)*sind*z2sub(ihere,icolor,cd(idirac))
!                   s1(ihere)      = ssb6r(ihere,icolor,idirac)
!w                    pscalar(ihere) = sign(idirac)*sub6i(ihere,icolor,idirac)
! Temp. change for 6th order.
!ww                    pscalar(ihere) = xk(6)*sign(idirac)*ssb6i(ihere,icolor,cd(idirac))

                endif ! isb
            ELSE
                if (isb.eq.0) then
                   sprop(ihere)   = ipropagator(ihere,icolor,idirac,1)
              pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
                               -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))
!www          pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
!www                           -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))

                else if(isb.eq.1) then
! Temp. change for 2nd order. Again, incorrect for currents.
!www                    s0(ihere)   = xk(1)*ssb1i(ihere,icolor,idirac)+xk(3)*ssb3i(ihere,icolor,idirac)
!www                    s1(ihere)   = xk(2)*ssb2i(ihere,icolor,idirac)
!www                    pscalar(ihere) = -sign(idirac)*xk(2)*ssb2r(ihere,icolor,cd(idirac))

                      s0(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac)
                      s1(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac) &
                                  -xk(4)*ssb4i(ihere,icolor,idirac)
! Need to experiment with source terms below. -WW
                 pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
                                  -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)) &
                                  -xk(1)*ssb1r(ihere,icolor,cd(idirac)) &
                                  -xk(2)*ssb2r(ihere,icolor,cd(idirac)) &
                                  -xk(3)*ssb3r(ihere,icolor,cd(idirac)) &
                                  -xk(4)*ssb4r(ihere,icolor,cd(idirac))) 

!w                    s0(ihere)      = ssb4i(ihere,icolor,idirac)

!w                    s1(ihere)      = ssb5i(ihere,icolor,idirac)

!                   pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac) + z2(ihere,icolor,cd(idirac)))
!w                    pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
!w                                     -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))

!                   pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac)-cosd*cosd*z2sub(ihere,icolor,cd(idirac)))
!                   pscalar(ihere) = -sign(idirac)*(sub5r(ihere,icolor,idirac))

                else if(isb.eq.2) then
! Temp. change for 4th order.
!www                    s0(ihere)      = xk(5)*ssb5i(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    s1(ihere)      = xk(4)*ssb4i(ihere,icolor,idirac)
! Temp. change for 4th order.
!www                    pscalar(ihere) = -sign(idirac)*xk(4)*ssb4r(ihere,icolor,cd(idirac))

                      s0(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac) &
                                  -xk(4)*ssb4i(ihere,icolor,idirac) &
                                  -xk(5)*ssb5i(ihere,icolor,idirac) &
                                  -xk(6)*ssb6i(ihere,icolor,idirac)
                      s1(ihere) = ipropagator(ihere,icolor,idirac,1) &
                                  -xk(1)*ssb1i(ihere,icolor,idirac) &
                                  -xk(2)*ssb2i(ihere,icolor,idirac) &
                                  -xk(3)*ssb3i(ihere,icolor,idirac) &
                                  -xk(4)*ssb4i(ihere,icolor,idirac) &
                                  -xk(5)*ssb5i(ihere,icolor,idirac) &
                                  -xk(6)*ssb6i(ihere,icolor,idirac) 
! Need to experiment with source terms below. -WW
                 pscalar(ihere) = -sign(idirac)*(rpropagator(ihere,icolor,cd(idirac),1)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
                                  -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)) &
                                  -xk(1)*ssb1r(ihere,icolor,cd(idirac)) &
                                  -xk(2)*ssb2r(ihere,icolor,cd(idirac)) &
                                  -xk(3)*ssb3r(ihere,icolor,cd(idirac)) &
                                  -xk(4)*ssb4r(ihere,icolor,cd(idirac)) &
                                  -xk(5)*ssb5r(ihere,icolor,cd(idirac)) &
                                  -xk(6)*ssb6r(ihere,icolor,cd(idirac)))

!w                    s0(ihere)      = ssb6i(ihere,icolor,idirac)
! Temp. change for 6th order.
!ww                    s0(ihere)      = xk(5)*ssb5i(ihere,icolor,idirac)

!w                    s1(ihere)      = ssb6i(ihere,icolor,idirac)
! Temp. change for 6th order.
!ww                    s1(ihere)      = xk(6)*ssb6i(ihere,icolor,idirac) 

!                   pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac) + z2(ihere,icolor,cd(idirac)))
!w                    pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac)-cosd*(cosd*z2sub(ihere,icolor,cd(idirac)) &
!w                                     -sign(cd(idirac))*sind*z2(ihere,icolor,idirac)))
! Temp. change for 6th order.
!ww                    pscalar(ihere) = -xk(6)*sign(idirac)*ssb6r(ihere,icolor,cd(idirac)) 

!                   pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac)-cosd*cosd*z2sub(ihere,icolor,cd(idirac)))
!                   pscalar(ihere) = -sign(idirac)*(sub6r(ihere,icolor,idirac))

                endif ! isb
            ENDIF ! (jri.eq.1)

            if (isb==0) then
! Calculate the operators for the raw propagator.
                call currentCalc2(sprop,idirac,icolor,jri,ihere,&
                                  leftx,rightx,lefty,righty,leftz,rightz,&
                                  leftt,rightt,ittt,usp,uss,z2noise,rwdir,ir,myid)


                call currentCalc2_axial(pscalar,idirac,icolor,jri,ihere,&
                                  leftx,rightx,lefty,righty,leftz,rightz,&
                                  leftt,rightt,ittt,usp,uss,z2noise,rwdir,ir,myid)
                call scalarCalc(sprop,idirac,icolor,jri,ihere,1,myid)
                call scalarCalc(pscalar,idirac,icolor,jri,ihere,2,myid)

            else ! (isb==0)
! Calculate the operators for first non-trivial and highest order subtraction
! levels.

                call currentCalc2(s0,idirac,icolor,jri,ihere,&
                                  leftx,rightx,lefty,righty,leftz,rightz,&
                                  leftt,rightt,ittt,usp,uss,z2noise,rwdir,ir,myid)

                call currentCalc2_axial(pscalar,idirac,icolor,jri,ihere,&
                                  leftx,rightx,lefty,righty,leftz,rightz,&
                                  leftt,rightt,ittt,usp,uss,z2noise,rwdir,ir,myid)

                call scalarCalc(s1,idirac,icolor,jri,ihere,1,myid)
                call scalarCalc(pscalar,idirac,icolor,jri,ihere,2,myid)


            endif ! (isb==0)
            if (ittt.ne.ltime) then
                xrr2(isb)=xrr2(isb)+rhor(leftt)
                xri2(isb)=xri2(isb)+rhoi(leftt)

                axrr2(isb)=axrr2(isb)+arhor(leftt)
                axri2(isb)=axri2(isb)+arhoi(leftt)
            endif ! ittt utime

            if (ittt.ne.utime) then
                xrr2(isb)=xrr2(isb)+rhor(ihere)
                xri2(isb)=xri2(isb)+rhoi(ihere)

                axrr2(isb)=axrr2(isb)+arhor(ihere)
                axri2(isb)=axri2(isb)+arhoi(ihere)
            endif ! ittt ltime

! Only do psibar*psi once when jc=icolor

            xps2(isb)=xps2(isb)+psir(ihere)
            xpi2(isb)=xpi2(isb)+psii(ihere)

            xpsur(isb)=xpsur(isb)+psur(ihere)
            xpsui(isb)=xpsui(isb)+psui(ihere)

            xsj1pr(isb)=xsj1pr(isb)+j1pr(leftx)
            xsj1pr(isb)=xsj1pr(isb)+j1pr(ihere)
            xsj1pi(isb)=xsj1pi(isb)+j1pi(leftx)
            xsj1pi(isb)=xsj1pi(isb)+j1pi(ihere)

            xsj2pr(isb)=xsj2pr(isb)+j2pr(lefty)
            xsj2pr(isb)=xsj2pr(isb)+j2pr(ihere)
            xsj2pi(isb)=xsj2pi(isb)+j2pi(lefty)
            xsj2pi(isb)=xsj2pi(isb)+j2pi(ihere)

            xsj3pr(isb)=xsj3pr(isb)+j3pr(leftz)
            xsj3pr(isb)=xsj3pr(isb)+j3pr(ihere)
            xsj3pi(isb)=xsj3pi(isb)+j3pi(leftz)
            xsj3pi(isb)=xsj3pi(isb)+j3pi(ihere)

            axsj1pr(isb)=axsj1pr(isb)+aj1pr(leftx)
            axsj1pr(isb)=axsj1pr(isb)+aj1pr(ihere)
            axsj1pi(isb)=axsj1pi(isb)+aj1pi(leftx)
            axsj1pi(isb)=axsj1pi(isb)+aj1pi(ihere)

            axsj2pr(isb)=axsj2pr(isb)+aj2pr(lefty)
            axsj2pr(isb)=axsj2pr(isb)+aj2pr(ihere)
            axsj2pi(isb)=axsj2pi(isb)+aj2pi(lefty)
            axsj2pi(isb)=axsj2pi(isb)+aj2pi(ihere)

            axsj3pr(isb)=axsj3pr(isb)+aj3pr(leftz)
            axsj3pr(isb)=axsj3pr(isb)+aj3pr(ihere)
            axsj3pi(isb)=axsj3pi(isb)+aj3pi(leftz)
            axsj3pi(isb)=axsj3pi(isb)+aj3pi(ihere)

!     Momentum analysis

            opertemp(1,ittt,1,isb)=opertemp(1,ittt,1,isb)+&
                                   rhor(ihere)
            opertemp(1,modulo((ittt-1)-1,nt)+1,1,isb)=&
            opertemp(1,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                   rhor(leftt)

            opertemp(2,ittt,1,isb)=opertemp(2,ittt,1,isb)+&
                                   rhoi(ihere)
            opertemp(2,modulo((ittt-1)-1,nt)+1,1,isb)=&
            opertemp(2,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                   rhoi(leftt)


            opertemp(13,ittt,1,isb)=opertemp(13,ittt,1,isb)+&
                                   arhor(ihere)
            opertemp(13,modulo((ittt-1)-1,nt)+1,1,isb)=&
            opertemp(13,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                   arhor(leftt)

            opertemp(14,ittt,1,isb)=opertemp(14,ittt,1,isb)+&
                                   arhoi(ihere)
            opertemp(14,modulo((ittt-1)-1,nt)+1,1,isb)=&
            opertemp(14,modulo((ittt-1)-1,nt)+1,1,isb)+&
                                   arhoi(leftt)


! These are the scalor operators...
! NOTE (jc is allways equal to icolor here)

           !if (jc.eq.icolor) then
                opertemp(3,ittt,1,isb)=opertemp(3,ittt,1,isb)+&
                                       psir(ihere)
                opertemp(4,ittt,1,isb)=opertemp(4,ittt,1,isb)+&
                                       psii(ihere)
           !endif

            opertemp(5,ittt,1,isb)=opertemp(5,ittt,1,isb)+&
                                   j1pr(ihere)+&
                                   j1pr(leftx)

            opertemp(6,ittt,1,isb)=opertemp(6,ittt,1,isb)+&
                                   j1pi(ihere)+&
                                   j1pi(leftx)

            opertemp(7,ittt,1,isb)=opertemp(7,ittt,1,isb)+&
                                   j2pr(ihere)+&
                                   j2pr(lefty)

            opertemp(8,ittt,1,isb)=opertemp(8,ittt,1,isb)+&
                                   j2pi(ihere)+&
                                   j2pi(lefty)

            opertemp(9,ittt,1,isb)=opertemp(9,ittt,1,isb)+&
                                   j3pr(ihere)+&
                                   j3pr(leftz)

            opertemp(10,ittt,1,isb)=opertemp(10,ittt,1,isb)+&
                                    j3pi(ihere)+&
                                    j3pi(leftz)


            opertemp(15,ittt,1,isb)=opertemp(15,ittt,1,isb)+&
                                   aj1pr(ihere)+&
                                   aj1pr(leftx)

            opertemp(16,ittt,1,isb)=opertemp(16,ittt,1,isb)+&
                                   aj1pi(ihere)+&
                                   aj1pi(leftx)

            opertemp(17,ittt,1,isb)=opertemp(17,ittt,1,isb)+&
                                   aj2pr(ihere)+&
                                   aj2pr(lefty)

            opertemp(18,ittt,1,isb)=opertemp(18,ittt,1,isb)+&
                                   aj2pi(ihere)+&
                                   aj2pi(lefty)

            opertemp(19,ittt,1,isb)=opertemp(19,ittt,1,isb)+&
                                   aj3pr(ihere)+&
                                   aj3pr(leftz)

            opertemp(20,ittt,1,isb)=opertemp(20,ittt,1,isb)+&
                                    aj3pi(ihere)+&
                                    aj3pi(leftz)

            if (jc.eq.icolor) then
                opertemp(11,ittt,1,isb)=opertemp(11,ittt,1,isb)+&
                                       psur(ihere)
                opertemp(12,ittt,1,isb)=opertemp(12,ittt,1,isb)+&
                                       psui(ihere)
            endif

            do ix=2,5

               opertemp(1,ittt,ix,isb)=opertemp(1,ittt,ix,isb)+&
                                       rhor(ihere)*ffac(ihere,ix-1)
               opertemp(1,modulo((ittt-1)-1,nt)+1,ix,isb)=&
               opertemp(1,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                       rhor(leftt)*ffac(leftt,ix-1)

               opertemp(2,ittt,ix,isb)=opertemp(2,ittt,ix,isb)+&
                                       rhoi(ihere)*ffac(ihere,ix-1)
               opertemp(2,modulo((ittt-1)-1,nt)+1,ix,isb)=&
               opertemp(2,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                       rhoi(leftt)*ffac(leftt,ix-1)

               opertemp(13,ittt,ix,isb)=opertemp(13,ittt,ix,isb)+&
                                       arhor(ihere)*ffac(ihere,ix-1)
               opertemp(13,modulo((ittt-1)-1,nt)+1,ix,isb)=&
               opertemp(13,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                       arhor(leftt)*ffac(leftt,ix-1)

               opertemp(14,ittt,ix,isb)=opertemp(14,ittt,ix,isb)+&
                                       arhoi(ihere)*ffac(ihere,ix-1)
               opertemp(14,modulo((ittt-1)-1,nt)+1,ix,isb)=&
               opertemp(14,modulo((ittt-1)-1,nt)+1,ix,isb)+&
                                       arhoi(leftt)*ffac(leftt,ix-1)


! These are the scalor operators...
! NOTE (jc is allways equal to icolor here)

               if (jc.eq.icolor) then
                   opertemp(3,ittt,ix,isb)=opertemp(3,ittt,ix,isb)+&
                                           psir(ihere)*ffac(ihere,ix-1)

                   opertemp(4,ittt,ix,isb)=opertemp(4,ittt,ix,isb)+&
                                           psii(ihere)*ffac(ihere,ix-1)
               endif

               opertemp(5,ittt,ix,isb)=opertemp(5,ittt,ix,isb)+&
                                       j1pi(ihere)*fas3(ihere,ix-1)+&
                                       j1pi(leftx)*fas3(leftx,ix-1)

               opertemp(6,ittt,ix,isb)=opertemp(6,ittt,ix,isb)+&
                                       j2pi(ihere)*fas1(ihere,ix-1)+&
                                       j2pi(lefty)*fas1(lefty,ix-1)

               opertemp(7,ittt,ix,isb)=opertemp(7,ittt,ix,isb)+&
                                       j3pi(ihere)*fas2(ihere,ix-1)+&
                                       j3pi(leftz)*fas2(leftz,ix-1)

               opertemp(8,ittt,ix,isb)=opertemp(8,ittt,ix,isb)+&
                                       j1pi(ihere)*fas2(ihere,ix-1)+&
                                       j1pi(leftx)*fas2(leftx,ix-1)

               opertemp(9,ittt,ix,isb)=opertemp(9,ittt,ix,isb)+&
                                       j2pi(ihere)*fas3(ihere,ix-1)+&
                                       j2pi(lefty)*fas3(lefty,ix-1)

               opertemp(10,ittt,ix,isb)=opertemp(10,ittt,ix,isb)+&
                                       j3pi(ihere)*fas1(ihere,ix-1)+&
                                       j3pi(leftz)*fas1(leftz,ix-1)


               opertemp(15,ittt,ix,isb)=opertemp(15,ittt,ix,isb)+&
                                       aj1pi(ihere)*fas3(ihere,ix-1)+&
                                       aj1pi(leftx)*fas3(leftx,ix-1)

               opertemp(16,ittt,ix,isb)=opertemp(16,ittt,ix,isb)+&
                                       aj2pi(ihere)*fas1(ihere,ix-1)+&
                                       aj2pi(lefty)*fas1(lefty,ix-1)

               opertemp(17,ittt,ix,isb)=opertemp(17,ittt,ix,isb)+&
                                       aj3pi(ihere)*fas2(ihere,ix-1)+&
                                       aj3pi(leftz)*fas2(leftz,ix-1)

               opertemp(18,ittt,ix,isb)=opertemp(18,ittt,ix,isb)+&
                                       aj1pi(ihere)*fas2(ihere,ix-1)+&
                                       aj1pi(leftx)*fas2(leftx,ix-1)

               opertemp(19,ittt,ix,isb)=opertemp(19,ittt,ix,isb)+&
                                       aj2pi(ihere)*fas3(ihere,ix-1)+&
                                       aj2pi(lefty)*fas3(lefty,ix-1)

               opertemp(20,ittt,ix,isb)=opertemp(20,ittt,ix,isb)+&
                                       aj3pi(ihere)*fas1(ihere,ix-1)+&
                                       aj3pi(leftz)*fas1(leftz,ix-1)


               if (jc.eq.icolor) then
                   opertemp(11,ittt,ix,isb)=opertemp(11,ittt,ix,isb)+&
                                           psur(ihere)*ffac(ihere,ix-1)

                   opertemp(12,ittt,ix,isb)=opertemp(12,ittt,ix,isb)+&
                                           psui(ihere)*ffac(ihere,ix-1)
               endif

! Need also 2-1, 3-2 and 1-3 combinations of directions
! (fas things) and currents at this point according to
! ahab7.f, which is used as a guide for coding the magnetic operators.
! disco13.f seems to imply that only the ones using
! the imaginary part of the currents need be kept.
!
!     End of momentum analysis

            enddo ! ix
         enddo ! isb
      enddo ! jri

      z2(ihere,icolor,idirac) = 0.0_KR
      z2sub(ihere,icolor,cd(idirac)) = 0.0_KR

                    enddo ! icolor
                 enddo ! idirac
              endif ! mod(numprocs) ! Second mod!!!
           enddo ! ixx
        enddo ! iyy
     enddo ! izz
  enddo ! ittt

! Need to put the operators in Jvev to be passed into average..

  do ittt = 1,nt
     if (nsub==0) then
         do imom=1,nmom

! Jvevtemp(:,:,1,:,:) is the unsubtracted propagator
            Jvevtemp(1,ittt,1,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,6) = opertemp(12,ittt,imom,0)

            Jvevtemp(1,ittt,1,imom,7) = opertemp(13,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,7) = opertemp(14,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,8) = opertemp(15,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,8) = opertemp(16,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,9) = opertemp(17,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,9) = opertemp(18,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,10) = opertemp(19,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,10) = opertemp(20,ittt,imom,0)
         enddo ! imom
     elseif (nsub==4) then
         do imom=1,nmom

! Jvevtemp(:,:,1,:,:) is the unsubtracted propagator
            Jvevtemp(1,ittt,1,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,6) = opertemp(12,ittt,imom,0)

            Jvevtemp(1,ittt,1,imom,7) = opertemp(13,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,7) = opertemp(14,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,8) = opertemp(15,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,8) = opertemp(16,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,9) = opertemp(17,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,9) = opertemp(18,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,10) = opertemp(19,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,10) = opertemp(20,ittt,imom,0)




            Jvevtemp(1,ittt,4,imom,1) = opertemp(1,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,1) = opertemp(2,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,2) = opertemp(3,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,2) = opertemp(4,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,3) = opertemp(5,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,3) = opertemp(6,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,4) = opertemp(7,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,4) = opertemp(8,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,5) = opertemp(9,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,5) = opertemp(10,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,6) = opertemp(11,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,6) = opertemp(12,ittt,imom,1)


            Jvevtemp(1,ittt,1,imom,7) = opertemp(13,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,7) = opertemp(14,ittt,imom,1)
            Jvevtemp(1,ittt,1,imom,8) = opertemp(15,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,8) = opertemp(16,ittt,imom,1)
            Jvevtemp(1,ittt,1,imom,9) = opertemp(17,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,9) = opertemp(18,ittt,imom,1)
            Jvevtemp(1,ittt,1,imom,10) = opertemp(19,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,10) = opertemp(20,ittt,imom,1)

         enddo ! imom
     elseif (nsub==6) then

! If nsub==6 then we need to have the first non-trival subtraction level
! (kappa^4) along with the highest order (kappa^6)

         do imom=1,nmom

! Jvevtemp(:,:,1,:,:) is the unsubtracted propagator
            Jvevtemp(1,ittt,1,imom,1) = opertemp(1,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,1) = opertemp(2,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,2) = opertemp(3,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,2) = opertemp(4,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,3) = opertemp(5,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,3) = opertemp(6,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,4) = opertemp(7,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,4) = opertemp(8,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,5) = opertemp(9,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,5) = opertemp(10,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,6) = opertemp(11,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,6) = opertemp(12,ittt,imom,0)

            Jvevtemp(1,ittt,1,imom,7) = opertemp(13,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,7) = opertemp(14,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,8) = opertemp(15,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,8) = opertemp(16,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,9) = opertemp(17,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,9) = opertemp(18,ittt,imom,0)
            Jvevtemp(1,ittt,1,imom,10) = opertemp(19,ittt,imom,0)
            Jvevtemp(2,ittt,1,imom,10) = opertemp(20,ittt,imom,0)




            Jvevtemp(1,ittt,4,imom,1) = opertemp(1,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,1) = opertemp(2,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,2) = opertemp(3,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,2) = opertemp(4,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,3) = opertemp(5,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,3) = opertemp(6,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,4) = opertemp(7,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,4) = opertemp(8,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,5) = opertemp(9,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,5) = opertemp(10,ittt,imom,1)
            Jvevtemp(1,ittt,4,imom,6) = opertemp(11,ittt,imom,1)
            Jvevtemp(2,ittt,4,imom,6) = opertemp(12,ittt,imom,1)


            Jvevtemp(1,ittt,1,imom,7) = opertemp(13,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,7) = opertemp(14,ittt,imom,1)
            Jvevtemp(1,ittt,1,imom,8) = opertemp(15,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,8) = opertemp(16,ittt,imom,1)
            Jvevtemp(1,ittt,1,imom,9) = opertemp(17,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,9) = opertemp(18,ittt,imom,1)
            Jvevtemp(1,ittt,1,imom,10) = opertemp(19,ittt,imom,1)
            Jvevtemp(2,ittt,1,imom,10) = opertemp(20,ittt,imom,1)



            Jvevtemp(1,ittt,6,imom,1) = opertemp(1,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,1) = opertemp(2,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,2) = opertemp(3,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,2) = opertemp(4,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,3) = opertemp(5,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,3) = opertemp(6,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,4) = opertemp(7,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,4) = opertemp(8,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,5) = opertemp(9,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,5) = opertemp(10,ittt,imom,2)
            Jvevtemp(1,ittt,6,imom,6) = opertemp(11,ittt,imom,2)
            Jvevtemp(2,ittt,6,imom,6) = opertemp(12,ittt,imom,2)


            Jvevtemp(1,ittt,1,imom,7) = opertemp(13,ittt,imom,2)
            Jvevtemp(2,ittt,1,imom,7) = opertemp(14,ittt,imom,2)
            Jvevtemp(1,ittt,1,imom,8) = opertemp(15,ittt,imom,2)
            Jvevtemp(2,ittt,1,imom,8) = opertemp(16,ittt,imom,2)
            Jvevtemp(1,ittt,1,imom,9) = opertemp(17,ittt,imom,2)
            Jvevtemp(2,ittt,1,imom,9) = opertemp(18,ittt,imom,2)
            Jvevtemp(1,ittt,1,imom,10) = opertemp(19,ittt,imom,2)
            Jvevtemp(2,ittt,1,imom,10) = opertemp(20,ittt,imom,2)


         enddo ! imom

     endif ! nsub
  enddo ! ittt

  if (nps/=1) then
      opercount = (nsav*nt*5*3)
      call MPI_REDUCE(opertemp(1,1,1,0),oper(1,1,1,0),opercount,MRT,MPI_SUM,&
                      0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xrr2(0),xrr2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xri2(0),xri2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)


      call MPI_REDUCE(axrr2(0),axrr2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(axri2(0),axri2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)

      call MPI_REDUCE(xps2(0),xps2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xpi2(0),xpi2temp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)

      call MPI_REDUCE(xpsur(0),xpsurtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xpsui(0),xpsuitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)


      call MPI_REDUCE(xsj1pr(0),xsj1prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj1pi(0),xsj1pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj2pr(0),xsj2prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj2pi(0),xsj2pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj3pr(0),xsj3prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(xsj3pi(0),xsj3pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)


      call MPI_REDUCE(axsj1pr(0),axsj1prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(axsj1pi(0),axsj1pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(axsj2pr(0),axsj2prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(axsj2pi(0),axsj2pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(axsj3pr(0),axsj3prtemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)
      call MPI_REDUCE(axsj3pi(0),axsj3pitemp(0),4,MRT,MPI_SUM,0,MPI_COMM_WORLD,ierr)

  else
      oper=opertemp
      xrr2temp=xrr2
      xri2temp=xri2
      axrr2temp=axrr2
      axri2temp=axri2
      xps2temp=xps2
      xpi2temp=xpi2
      xpsurtemp=xpsur
      xpsuitemp=xpsui
      xsj1prtemp=xsj1pr
      xsj1pitemp=xsj1pi
      xsj2prtemp=xsj2pr
      xsj2pitemp=xsj2pi
      xsj3prtemp=xsj3pr
      xsj3pitemp=xsj3pi

      axsj1prtemp=axsj1pr
      axsj1pitemp=axsj1pi
      axsj2prtemp=axsj2pr
      axsj2pitemp=axsj2pi
      axsj3prtemp=axsj3pr
      axsj3pitemp=axsj3pi
  endif ! nps
!     enddo ! is

  if (nps/=1) then
      Jvevcount = (2*nt*6*nmom*nop)
!     call MPI_REDUCE(Jvevtemp(1,1,1,1,1),Jvev(1,1,1,1,1),Jvevcount,MRT,MPI_SUM,&
!                     0,MPI_COMM_WORLD,ierr)
!     call MPI_BCAST(Jvev(1,1,1,1,1),Jvevcount,MRT,0,MPI_COMM_WORLD,ierr)
     call MPI_ALLREDUCE(Jvevtemp,Jvev,Jvevcount,MRT,MPI_SUM,MPI_COMM_WORLD,ierr)
  else
      Jvev=Jvevtemp
  endif ! (nps/=1)

  close(unit=8,status="keep")

  deallocate(ffac)
  deallocate(fas1)
  deallocate(fas2)
  deallocate(fas3)

! deallocate(uss)
! deallocate(usp)

  deallocate(rpropagator)
  deallocate(ipropagator)

  deallocate(z2i)
  deallocate(z3i)
  deallocate(z2noise)
  deallocate(z2inoise)

  deallocate(utemp)
  deallocate(uss)
  deallocate(usp)
! call deallocateus

  end Subroutine twAverage_axial
!**********************************************************************

  Subroutine Subtract(sb2r,sb2i,sb1r,sb1i)

!
!   use gaugelinks

  integer(kind=KI)                                  :: kcsrx,kc,kd
  integer(kind=KI)                                  :: isp,ind1,ind2,ind3
  integer(kind=KI)                                  :: ist,ix,iy,iz,itt
  real(kind=KR), dimension(nxyzt,nc,nd)             :: sb1r,sb1i,sb2r,sb2i

  real(kind=KR), allocatable, dimension(:,:,:,:,:)  :: uss
  real(kind=KR), allocatable, dimension(:,:,:,:)    :: usp

!
  DO kd=1,nd
     DO kc=1,nc

! Point-split J_4 (4-direction)
	      IF(kd.eq.1.or.kd.eq.2) THEN
	       do kcsrx=1,nc
		 do itt=1,nt
		   do isp=1,nx*ny*nz
		     ind2=isp+(itt-1)*nx*ny*nz
		     ind3=ind2+nx*ny*nz
		     if(itt.eq.nt) ind3=isp
		       sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			  +2.*usp(ind2,1,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			  -2.*usp(ind2,2,kc,kcsrx)*sb1i(ind3,kcsrx,kd)
		       sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			  +2.*usp(ind2,2,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			  +2.*usp(ind2,1,kc,kcsrx)*sb1i(ind3,kcsrx,kd)
		   enddo ! isp
		 enddo ! itt
	       enddo ! kcsrx
	      ELSE IF(kd.eq.3.or.kd.eq.4) THEN
	       do kcsrx=1,nc
		 do itt=1,nt
		   do isp=1,nxyz
		     ind2=isp+(itt-1)*nx*ny*nz
		     ind1=ind2-nx*ny*nz
		     if(itt.eq.1) ind1=isp+(nt-1)*nx*ny*nz
		       sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			 +2.*usp(ind1,1,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			 +2.*usp(ind1,2,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
		     sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			 -2.*usp(ind1,2,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			 +2.*usp(ind1,1,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
		   enddo ! isp
		 enddo ! itt
	       enddo ! kcsrx
	      ENDIF
! Point-split J_1 (1-direction)
! Diagonal part
		do kcsrx=1,nc
		  do ist=1,nt*nz*ny
		    do ix=1,nx
		      ind2=ix+(ist-1)*nx
		      ind1=ind2-1
		      ind3=ind2+1
		      if(ix.eq.1) ind1=ind1+nx
			if(ix.eq.nx) ind3=ind3-nx
			  sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			   +uss(ind2,1,1,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			   +uss(ind1,1,1,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			   -uss(ind2,1,2,kc,kcsrx)*sb1i(ind3,kcsrx,kd)&
			   +uss(ind1,1,2,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
			  sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			   +uss(ind2,1,2,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			   -uss(ind1,1,2,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			   +uss(ind2,1,1,kc,kcsrx)*sb1i(ind3,kcsrx,kd)&
			   +uss(ind1,1,1,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
		    enddo ! ix 
		  enddo ! ist
		enddo ! kcsrx
! Off-diagonal J_1 part
		do kcsrx=1,nc
		  do ist=1,nt*nz*ny
		    do ix=1,nx
		      ind2=ix+(ist-1)*nx
		      ind1=ind2-1
		      ind3=ind2+1
		      if(ix.eq.1) ind1=ind1+nx
			if(ix.eq.nx) ind3=ind3-nx
			  sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			   +uss(ind2,1,1,kc,kcsrx)*sb1r(ind3,kcsrx,5-kd)&
			   -uss(ind1,1,1,kcsrx,kc)*sb1r(ind1,kcsrx,5-kd)&
			   -uss(ind2,1,2,kc,kcsrx)*sb1i(ind3,kcsrx,5-kd)&
			   -uss(ind1,1,2,kcsrx,kc)*sb1i(ind1,kcsrx,5-kd)
			  sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			   +uss(ind2,1,2,kc,kcsrx)*sb1r(ind3,kcsrx,5-kd)&
			   +uss(ind1,1,2,kcsrx,kc)*sb1r(ind1,kcsrx,5-kd)&
			   +uss(ind2,1,1,kc,kcsrx)*sb1i(ind3,kcsrx,5-kd)&
			   -uss(ind1,1,1,kcsrx,kc)*sb1i(ind1,kcsrx,5-kd)
		    enddo ! ix
		  enddo ! ist
		enddo ! kcsrx
! Point-split J_2 (2-direction)
! Diagonal part
		do kcsrx=1,nc
		  do ist=1,nt*nz
		    do iy=1,nx*ny
		      ind2=iy+(ist-1)*nx*ny
		      ind1=ind2-nx
		      ind3=ind2+nx
		      if(iy-nx.lt.1) ind1=ind1+nx*ny
			if(iy+nx.gt.nx*ny) ind3=ind3-nx*ny
			  sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			   +uss(ind2,2,1,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			   +uss(ind1,2,1,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			   -uss(ind2,2,2,kc,kcsrx)*sb1i(ind3,kcsrx,kd)&
			   +uss(ind1,2,2,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
			  sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			   +uss(ind2,2,2,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			   -uss(ind1,2,2,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			   +uss(ind2,2,1,kc,kcsrx)*sb1i(ind3,kcsrx,kd)&
			   +uss(ind1,2,1,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
		    enddo ! ix
		  enddo ! ist
		enddo ! kcsrx
! Off-diagonal J_2 part
	       IF(mod(kd,2).eq.1) THEN
		 do kcsrx=1,nc
		   do ist=1,nt*nz
		     do iy=1,nx*ny
		       ind2=iy+(ist-1)*nx*ny
		       ind1=ind2-nx
		       ind3=ind2+nx
		       if(iy-nx.lt.1) ind1=ind1+nx*ny
			 if(iy+nx.gt.nx*ny) ind3=ind3-nx*ny
			   sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			    +uss(ind2,2,2,kc,kcsrx)*sb1r(ind3,kcsrx,5-kd)&
			    +uss(ind1,2,2,kcsrx,kc)*sb1r(ind1,kcsrx,5-kd)&
			    +uss(ind2,2,1,kc,kcsrx)*sb1i(ind3,kcsrx,5-kd)&
			    -uss(ind1,2,1,kcsrx,kc)*sb1i(ind1,kcsrx,5-kd)
			   sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			    -uss(ind2,2,1,kc,kcsrx)*sb1r(ind3,kcsrx,5-kd)&
			    +uss(ind1,2,1,kcsrx,kc)*sb1r(ind1,kcsrx,5-kd)&
			    +uss(ind2,2,2,kc,kcsrx)*sb1i(ind3,kcsrx,5-kd)&
			    +uss(ind1,2,2,kcsrx,kc)*sb1i(ind1,kcsrx,5-kd)
		      enddo ! ix
		    enddo ! ist
		  enddo ! kcsrx
	       ELSE IF(mod(kd,2).eq.0) THEN
		 do kcsrx=1,nc
		   do ist=1,nt*nz
		     do iy=1,nx*ny
		       ind2=iy+(ist-1)*nx*ny
		       ind1=ind2-nx
		       ind3=ind2+nx
		       if(iy-nx.lt.1) ind1=ind1+nx*ny
			 if(iy+nx.gt.nx*ny) ind3=ind3-nx*ny
			   sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			    -uss(ind2,2,2,kc,kcsrx)*sb1r(ind3,kcsrx,5-kd)&
			    -uss(ind1,2,2,kcsrx,kc)*sb1r(ind1,kcsrx,5-kd)&
			    -uss(ind2,2,1,kc,kcsrx)*sb1i(ind3,kcsrx,5-kd)&
			    +uss(ind1,2,1,kcsrx,kc)*sb1i(ind1,kcsrx,5-kd)
			   sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			    +uss(ind2,2,1,kc,kcsrx)*sb1r(ind3,kcsrx,5-kd)&
			    -uss(ind1,2,1,kcsrx,kc)*sb1r(ind1,kcsrx,5-kd)&
			    -uss(ind2,2,2,kc,kcsrx)*sb1i(ind3,kcsrx,5-kd)&
			    -uss(ind1,2,2,kcsrx,kc)*sb1i(ind1,kcsrx,5-kd)
		     enddo ! ix
		   enddo ! ist
		 enddo ! kcsrx
	       ENDIF
! Point-split J_3 (3-direction)
! Diagonal J_3 part
	       do kcsrx=1,nc
		 do ist=1,nt
		   do iz=1,nx*ny*nz
		     ind2=iz+(ist-1)*nx*ny*nz
		     ind1=ind2-nx*ny
		     ind3=ind2+nx*ny
		     if(iz-nx*ny.lt.1) ind1=ind1+nx*ny*nz
		       if(iz+nx*ny.gt.nx*ny*nz) ind3=ind3-nx*ny*nz
			 sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			  +uss(ind2,3,1,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			  +uss(ind1,3,1,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			  -uss(ind2,3,2,kc,kcsrx)*sb1i(ind3,kcsrx,kd)&
			  +uss(ind1,3,2,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
			 sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			  +uss(ind2,3,2,kc,kcsrx)*sb1r(ind3,kcsrx,kd)&
			  -uss(ind1,3,2,kcsrx,kc)*sb1r(ind1,kcsrx,kd)&
			  +uss(ind2,3,1,kc,kcsrx)*sb1i(ind3,kcsrx,kd)&
			  +uss(ind1,3,1,kcsrx,kc)*sb1i(ind1,kcsrx,kd)
		     enddo ! ix
		   enddo ! ist
		 enddo ! kcsrx
! Off-diagonal J_3 part
	      IF(mod(kd,2).eq.1) THEN
	       do kcsrx=1,nc
		 do ist=1,nt
		   do iz=1,nx*ny*nz
		     ind2=iz+(ist-1)*nx*ny*nz
		     ind1=ind2-nx*ny
		     ind3=ind2+nx*ny
		     if(iz-nx*ny.lt.1) ind1=ind1+nx*ny*nz
		       if(iz+nx*ny.gt.nx*ny*nz) ind3=ind3-nx*ny*nz
			 sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			  +uss(ind2,3,1,kc,kcsrx)*sb1r(ind3,kcsrx,3/kd)&
			  -uss(ind1,3,1,kcsrx,kc)*sb1r(ind1,kcsrx,3/kd)&
			  -uss(ind2,3,2,kc,kcsrx)*sb1i(ind3,kcsrx,3/kd)&
			  -uss(ind1,3,2,kcsrx,kc)*sb1i(ind1,kcsrx,3/kd)
			 sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			  +uss(ind2,3,2,kc,kcsrx)*sb1r(ind3,kcsrx,3/kd)&
			  +uss(ind1,3,2,kcsrx,kc)*sb1r(ind1,kcsrx,3/kd)&
			  +uss(ind2,3,1,kc,kcsrx)*sb1i(ind3,kcsrx,3/kd)&
			  -uss(ind1,3,1,kcsrx,kc)*sb1i(ind1,kcsrx,3/kd)
		   enddo ! ix
		 enddo ! ist
	       enddo ! kcsrx
	      ELSE IF(mod(kd,2).eq.0) THEN
	       do kcsrx=1,nc
		 do ist=1,nt
		   do iz=1,nx*ny*nz
		     ind2=iz+(ist-1)*nx*ny*nz
		     ind1=ind2-nx*ny
		     ind3=ind2+nx*ny
		     if(iz-nx*ny.lt.1) ind1=ind1+nx*ny*nz
		       if(iz+nx*ny.gt.nx*ny*nz) ind3=ind3-nx*ny*nz
			 sb2r(ind2,kc,kd)=sb2r(ind2,kc,kd)&
			  -uss(ind2,3,1,kc,kcsrx)*sb1r(ind3,kcsrx,8/kd)&
			  +uss(ind1,3,1,kcsrx,kc)*sb1r(ind1,kcsrx,8/kd)&
			  +uss(ind2,3,2,kc,kcsrx)*sb1i(ind3,kcsrx,8/kd)&
			  +uss(ind1,3,2,kcsrx,kc)*sb1i(ind1,kcsrx,8/kd)
			 sb2i(ind2,kc,kd)=sb2i(ind2,kc,kd)&
			  -uss(ind2,3,2,kc,kcsrx)*sb1r(ind3,kcsrx,8/kd)&
			  -uss(ind1,3,2,kcsrx,kc)*sb1r(ind1,kcsrx,8/kd)&
			  -uss(ind2,3,1,kc,kcsrx)*sb1i(ind3,kcsrx,8/kd)&
			  +uss(ind1,3,1,kcsrx,kc)*sb1i(ind1,kcsrx,8/kd)
		   enddo ! ix
		 enddo ! ist
	       enddo ! kcsrx
	      ENDIF
	      
	      enddo ! kc
	      enddo ! kd
	!
  RETURN
  END Subroutine Subtract

!
!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!

  Subroutine Multiply(sb2r,sb2i,sbxr,sbxi,&
                      ax,ay,az,at,ac,ad,usp,uss,fixbc,myid)


  use input2
  use multstorage

! use input1
! use gaugelinks

  real(kind=KR),    intent(in),    dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),    dimension(:,:,:,:,:)             :: uss
  real(kind=KR),    intent(in),    dimension(nxyzt,nc,nd)           :: sbxr,sbxi
  integer(kind=KI), intent(in)                                      :: myid
  real(kind=KR),    intent(inout), dimension(nxyzt,nc,nd)           :: sb2r,sb2i
  logical,  intent(in)                                      :: fixbc
  real(kind=KR),                   dimension(2)                     :: sbr,sbi
  integer(kind=KI)                                            :: ax,ay,az,at,ac,ad
  integer(kind=KI)                                                  :: ahere,leftx,rightx,&
					                               lefty,righty,leftz,rightz,&
								       leftt,rightt
  integer(kind=KI)                                                  :: im,imm,kc,kd,ierr
  integer(kind=KI),                dimension(9)                     :: imv
  logical                                                           :: false,true

  call allocatemults

! NOTE: This subroutine, Multiply uses a different
!       representation for the off-diagonal elements of the
!       operators. The other representation is found in
!       subroutine CurrentCalc.

! This rouinte calculates the operators using the propagator
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

!     Impose periodic boundary conditions

  ax=mod(ax-1+nx,nx)+1
  ay=mod(ay-1+ny,ny)+1
  az=mod(az-1+nz,nz)+1
  at=mod(at-1+nt,nt)+1

  leftx=mod((ax-1)-1+nx,nx)+1
  rightx=mod((ax+1)-1+nx,nx)+1
  lefty=mod((ay-1)-1+ny,ny)+1
  righty=mod((ay+1)-1+ny,ny)+1
  leftz=mod((az-1)-1+nz,nz)+1
  rightz=mod((az+1)-1+nz,nz)+1
  leftt=mod((at-1)-1+nt,nt)+1
  rightt=mod((at+1)-1+nt,nt)+1

! Translate coordinates to single array index
	     
  ahere=ax+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz

  multsb1r(ahere,ac,:)=0.0_KR
  multsb1i(ahere,ac,:)=0.0_KR 
  multsb1r(ahere,ac,ad)=sbxr(ahere,ac,ad)
  multsb1i(ahere,ac,ad)=sbxi(ahere,ac,ad)

  sbr(1) = multsb1r(ahere,ac,1)
  sbi(1) = multsb1i(ahere,ac,1)
  sbr(2) = multsb1r(ahere,ac,2)
  sbi(2) = multsb1i(ahere,ac,2)

  multsb1r(ahere,ac,1) = cosd*multsb1r(ahere,ac,1)-sind*multsb1r(ahere,ac,3)
  multsb1i(ahere,ac,1) = cosd*multsb1i(ahere,ac,1)-sind*multsb1i(ahere,ac,3)
  multsb1r(ahere,ac,2) = cosd*multsb1r(ahere,ac,2)-sind*multsb1r(ahere,ac,4)
  multsb1i(ahere,ac,2) = cosd*multsb1i(ahere,ac,2)-sind*multsb1i(ahere,ac,4)

  multsb1r(ahere,ac,3) = cosd*multsb1r(ahere,ac,3)+sind*sbr(1)
  multsb1i(ahere,ac,3) = cosd*multsb1i(ahere,ac,3)+sind*sbi(1)
  multsb1r(ahere,ac,4) = cosd*multsb1r(ahere,ac,4)+sind*sbr(2)
  multsb1i(ahere,ac,4) = cosd*multsb1i(ahere,ac,4)+sind*sbi(2)

  leftx=leftx+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
  rightx=rightx+(ay-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
  lefty=ax+(lefty-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
  righty=ax+(righty-1)*nx+(az-1)*nx*ny+(at-1)*nx*ny*nz
  leftz=ax+(ay-1)*nx+(leftz-1)*nx*ny+(at-1)*nx*ny*nz
  rightz=ax+(ay-1)*nx+(rightz-1)*nx*ny+(at-1)*nx*ny*nz
  leftt=ax+(ay-1)*nx+(az-1)*nx*ny+(leftt-1)*nx*ny*nz
  rightt=ax+(ay-1)*nx+(az-1)*nx*ny+(rightt-1)*nx*ny*nz

  imv(1) = ahere
  imv(2) = leftx
  imv(3) = rightx
  imv(4) = lefty
  imv(5) = righty
  imv(6) = leftz
  imv(7) = rightz
  imv(8) = leftt
  imv(9) = rightt

  if ((ad==1).or.(ad==3)) then
      do kd=1,3,2
         do kc=1,nc

!     Point-split J_4 (4-direction)
            if (fixbc.eqv.(.false.)) then
	        IF (kd.eq.1 .or. kd.eq.2) THEN
		    sb2r(leftt,kc,kd)=sb2r(leftt,kc,kd)&
		   +2.0_KR*usp(leftt,1,kc,ac)*multsb1r(ahere,ac,kd)&
		   -2.0_KR*usp(leftt,2,kc,ac)*multsb1i(ahere,ac,kd)

		    sb2i(leftt,kc,kd)=sb2i(leftt,kc,kd)&
		   +2.0_KR*usp(leftt,2,kc,ac)*multsb1r(ahere,ac,kd)&
		   +2.0_KR*usp(leftt,1,kc,ac)*multsb1i(ahere,ac,kd)

	        ELSE IF(kd.eq.3 .or. kd.eq.4) THEN
		    sb2r(rightt,kc,kd)=sb2r(rightt,kc,kd)&
		   +2.0_KR*usp(ahere,1,ac,kc)*multsb1r(ahere,ac,kd)&
	  	   +2.0_KR*usp(ahere,2,ac,kc)*multsb1i(ahere,ac,kd)

		    sb2i(rightt,kc,kd)=sb2i(rightt,kc,kd)&
		   -2.0_KR*usp(ahere,2,ac,kc)*multsb1r(ahere,ac,kd)&
		   +2.0_KR*usp(ahere,1,ac,kc)*multsb1i(ahere,ac,kd)
	        END IF
	    else ! fixbc
  	        IF ((kd.eq.1 .or. kd.eq.2).and.(at.ne.1)) THEN
		    sb2r(leftt,kc,kd)=sb2r(leftt,kc,kd)&	
		   +2.0_KR*usp(leftt,1,kc,ac)*multsb1r(ahere,ac,kd)&
		   -2.0_KR*usp(leftt,2,kc,ac)*multsb1i(ahere,ac,kd)

		    sb2i(leftt,kc,kd)=sb2i(leftt,kc,kd)&
		   +2.0_KR*usp(leftt,2,kc,ac)*multsb1r(ahere,ac,kd)&
		   +2.0_KR*usp(leftt,1,kc,ac)*multsb1i(ahere,ac,kd)

	      ELSE IF((kd.eq.3 .or. kd.eq.4).and.(at.ne.nt)) THEN
		    sb2r(rightt,kc,kd)=sb2r(rightt,kc,kd)&
		   +2.0_KR*usp(ahere,1,ac,kc)*multsb1r(ahere,ac,kd)&
		   +2.0_KR*usp(ahere,2,ac,kc)*multsb1i(ahere,ac,kd)

		    sb2i(rightt,kc,kd)=sb2i(rightt,kc,kd)&
		   -2.0_KR*usp(ahere,2,ac,kc)*multsb1r(ahere,ac,kd)&
	 	   +2.0_KR*usp(ahere,1,ac,kc)*multsb1i(ahere,ac,kd)
	      END IF
	    end if

!     Point-split J_1 (1-direction)
!     Diagonal part

	    sb2r(leftx,kc,kd)=sb2r(leftx,kc,kd)&
	   +uss(leftx,1,1,kc,ac)*multsb1r(ahere,ac,kd)&
	   -uss(leftx,1,2,kc,ac)*multsb1i(ahere,ac,kd)

	    sb2r(rightx,kc,kd)=sb2r(rightx,kc,kd)&
	   +uss(ahere,1,1,ac,kc)*multsb1r(ahere,ac,kd)&
	   +uss(ahere,1,2,ac,kc)*multsb1i(ahere,ac,kd)

	    sb2i(leftx,kc,kd)=sb2i(leftx,kc,kd)&
	   +uss(leftx,1,2,kc,ac)*multsb1r(ahere,ac,kd)&
	   +uss(leftx,1,1,kc,ac)*multsb1i(ahere,ac,kd)

	    sb2i(rightx,kc,kd)=sb2i(rightx,kc,kd)&
	   -uss(ahere,1,2,ac,kc)*multsb1r(ahere,ac,kd)&
	   +uss(ahere,1,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Off-diagonal J_1 part
! Changed the following off diagonal part to match gaugelinks in CurrentCalc.

	     sb2r(leftx,kc,5-kd)=sb2r(leftx,kc,5-kd)&
	    -uss(leftx,1,1,kc,ac)*multsb1r(ahere,ac,kd)&
	    +uss(leftx,1,2,kc,ac)*multsb1i(ahere,ac,kd)

	     sb2r(rightx,kc,5-kd)=sb2r(rightx,kc,5-kd)&
	    +uss(ahere,1,1,ac,kc)*multsb1r(ahere,ac,kd)&
	    +uss(ahere,1,2,ac,kc)*multsb1i(ahere,ac,kd)

	     sb2i(leftx,kc,5-kd)=sb2i(leftx,kc,5-kd)&
	    -uss(leftx,1,2,kc,ac)*multsb1r(ahere,ac,kd)&
	    -uss(leftx,1,1,kc,ac)*multsb1i(ahere,ac,kd)

	     sb2i(rightx,kc,5-kd)=sb2i(rightx,kc,5-kd)&
	    -uss(ahere,1,2,ac,kc)*multsb1r(ahere,ac,kd)&
	    +uss(ahere,1,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Point-split J_2 (2-direction)
!     Diagonal part

	     sb2r(lefty,kc,kd)=sb2r(lefty,kc,kd)&
	    +uss(lefty,2,1,kc,ac)*multsb1r(ahere,ac,kd)&
	    -uss(lefty,2,2,kc,ac)*multsb1i(ahere,ac,kd)

	     sb2r(righty,kc,kd)=sb2r(righty,kc,kd)&
	    +uss(ahere,2,1,ac,kc)*multsb1r(ahere,ac,kd)&
	    +uss(ahere,2,2,ac,kc)*multsb1i(ahere,ac,kd)

	     sb2i(lefty,kc,kd)=sb2i(lefty,kc,kd)&
	    +uss(lefty,2,2,kc,ac)*multsb1r(ahere,ac,kd)&
	    +uss(lefty,2,1,kc,ac)*multsb1i(ahere,ac,kd)

	     sb2i(righty,kc,kd)=sb2i(righty,kc,kd)&
	    -uss(ahere,2,2,ac,kc)*multsb1r(ahere,ac,kd)&
	    +uss(ahere,2,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Off-diagonal J_2 part
! Changed the following off diagonal part to match gaugelinks in CurrentCalc.

	     IF (mod(kd,2).eq.0) THEN
	         sb2r(lefty,kc,5-kd)=sb2r(lefty,kc,5-kd)&
	        -uss(lefty,2,2,kc,ac)*multsb1r(ahere,ac,kd)&
	        -uss(lefty,2,1,kc,ac)*multsb1i(ahere,ac,kd)

	         sb2r(righty,kc,5-kd)=sb2r(righty,kc,5-kd)&
	        -uss(ahere,2,2,ac,kc)*multsb1r(ahere,ac,kd)&
	        +uss(ahere,2,1,ac,kc)*multsb1i(ahere,ac,kd)

	         sb2i(lefty,kc,5-kd)=sb2i(lefty,kc,5-kd)&
	        +uss(lefty,2,1,kc,ac)*multsb1r(ahere,ac,kd)&
	        -uss(lefty,2,2,kc,ac)*multsb1i(ahere,ac,kd)

	         sb2i(righty,kc,5-kd)=sb2i(righty,kc,5-kd)&
	        -uss(ahere,2,1,ac,kc)*multsb1r(ahere,ac,kd)&
	        -uss(ahere,2,2,ac,kc)*multsb1i(ahere,ac,kd)

	     ELSE IF(mod(kd,2).eq.1) THEN
	         sb2r(lefty,kc,5-kd)=sb2r(lefty,kc,5-kd)&
	        +uss(lefty,2,2,kc,ac)*multsb1r(ahere,ac,kd)&
	        +uss(lefty,2,1,kc,ac)*multsb1i(ahere,ac,kd)

	         sb2r(righty,kc,5-kd)=sb2r(righty,kc,5-kd)&
	        +uss(ahere,2,2,ac,kc)*multsb1r(ahere,ac,kd)&
	        -uss(ahere,2,1,ac,kc)*multsb1i(ahere,ac,kd)

	         sb2i(lefty,kc,5-kd)=sb2i(lefty,kc,5-kd)&
	        -uss(lefty,2,1,kc,ac)*multsb1r(ahere,ac,kd)&
	        +uss(lefty,2,2,kc,ac)*multsb1i(ahere,ac,kd)

	         sb2i(righty,kc,5-kd)=sb2i(righty,kc,5-kd)&
	        +uss(ahere,2,1,ac,kc)*multsb1r(ahere,ac,kd)&
	        +uss(ahere,2,2,ac,kc)*multsb1i(ahere,ac,kd)

	     END IF

!     Point-split J_3 (3-direction)
!     Diagonal part

	     sb2r(leftz,kc,kd)=sb2r(leftz,kc,kd)&
	    +uss(leftz,3,1,kc,ac)*multsb1r(ahere,ac,kd)&
	    -uss(leftz,3,2,kc,ac)*multsb1i(ahere,ac,kd)

	     sb2r(rightz,kc,kd)=sb2r(rightz,kc,kd)&
	    +uss(ahere,3,1,ac,kc)*multsb1r(ahere,ac,kd)&
	    +uss(ahere,3,2,ac,kc)*multsb1i(ahere,ac,kd)

	     sb2i(leftz,kc,kd)=sb2i(leftz,kc,kd)&
	    +uss(leftz,3,2,kc,ac)*multsb1r(ahere,ac,kd)&
	    +uss(leftz,3,1,kc,ac)*multsb1i(ahere,ac,kd)

	     sb2i(rightz,kc,kd)=sb2i(rightz,kc,kd)&
	    -uss(ahere,3,2,ac,kc)*multsb1r(ahere,ac,kd)&
	    +uss(ahere,3,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Off-diagonal J_3 part
! Changed the following off diagonal part to match gaugelinks in CurrentCalc.

	     IF (mod(kd,2).eq.1) THEN
		 sb2r(leftz,kc,3/kd)=sb2r(leftz,kc,3/kd)&
		-uss(leftz,3,1,kc,ac)*multsb1r(ahere,ac,kd)&
		+uss(leftz,3,2,kc,ac)*multsb1i(ahere,ac,kd)

		 sb2r(rightz,kc,3/kd)=sb2r(rightz,kc,3/kd)&
		+uss(ahere,3,1,ac,kc)*multsb1r(ahere,ac,kd)&
		+uss(ahere,3,2,ac,kc)*multsb1i(ahere,ac,kd)

		 sb2i(leftz,kc,3/kd)=sb2i(leftz,kc,3/kd)&
		-uss(leftz,3,2,kc,ac)*multsb1r(ahere,ac,kd)&
		-uss(leftz,3,1,kc,ac)*multsb1i(ahere,ac,kd)

		 sb2i(rightz,kc,3/kd)=sb2i(rightz,kc,3/kd)&
		-uss(ahere,3,2,ac,kc)*multsb1r(ahere,ac,kd)&
		+uss(ahere,3,1,ac,kc)*multsb1i(ahere,ac,kd)

	     ELSE IF(mod(kd,2).eq.0) THEN
		 sb2r(leftz,kc,8/kd)=sb2r(leftz,kc,8/kd)&
		+uss(leftz,3,1,kc,ac)*multsb1r(ahere,ac,kd)&
		-uss(leftz,3,2,kc,ac)*multsb1i(ahere,ac,kd)

		 sb2r(rightz,kc,8/kd)=sb2r(rightz,kc,8/kd)&
		-uss(ahere,3,1,ac,kc)*multsb1r(ahere,ac,kd)&
		-uss(ahere,3,2,ac,kc)*multsb1i(ahere,ac,kd)

		 sb2i(leftz,kc,8/kd)=sb2i(leftz,kc,8/kd)&
		+uss(leftz,3,2,kc,ac)*multsb1r(ahere,ac,kd)&
		+uss(leftz,3,1,kc,ac)*multsb1i(ahere,ac,kd)

		 sb2i(rightz,kc,8/kd)=sb2i(rightz,kc,8/kd)&
		+uss(ahere,3,2,ac,kc)*multsb1r(ahere,ac,kd)&
		-uss(ahere,3,1,ac,kc)*multsb1i(ahere,ac,kd)

	     END IF

        enddo ! kc loop
     enddo ! kd loop

  elseif ((ad==2).or.(ad==4)) then

     do kd=2,4,2
        do kc=1,nc

!     Point-split J_4 (4-direction)

	   if (fixbc.eqv.(.false.)) then
	       IF (kd.eq.3 .or. kd.eq.4) THEN
		   sb2r(leftt,kc,kd)=sb2r(leftt,kc,kd)&
		  +2.0_KR*usp(leftt,1,kc,ac)*multsb1r(ahere,ac,kd)&
		  -2.0_KR*usp(leftt,2,kc,ac)*multsb1i(ahere,ac,kd)

		   sb2i(leftt,kc,kd)=sb2i(leftt,kc,kd)&
		  +2.0_KR*usp(leftt,2,kc,ac)*multsb1r(ahere,ac,kd)&
		  +2.0_KR*usp(leftt,1,kc,ac)*multsb1i(ahere,ac,kd)

	       ELSE IF(kd.eq.1 .or. kd.eq.2) THEN
		   sb2r(rightt,kc,kd)=sb2r(rightt,kc,kd)&
		  +2.0_KR*usp(ahere,1,ac,kc)*multsb1r(ahere,ac,kd)&
		  +2.0_KR*usp(ahere,2,ac,kc)*multsb1i(ahere,ac,kd)

		   sb2i(rightt,kc,kd)=sb2i(rightt,kc,kd)&
		  -2.0_KR*usp(ahere,2,ac,kc)*multsb1r(ahere,ac,kd)&
		  +2.0_KR*usp(ahere,1,ac,kc)*multsb1i(ahere,ac,kd)

	       END IF
	   else 
	       IF ((kd.eq.3 .or. kd.eq.4).and.(at.ne.1)) THEN
		   sb2r(leftt,kc,kd)=sb2r(leftt,kc,kd)&	
		  +2.0_KR*usp(leftt,1,kc,ac)*multsb1r(ahere,ac,kd)&
		  -2.0_KR*usp(leftt,2,kc,ac)*multsb1i(ahere,ac,kd)

		   sb2i(leftt,kc,kd)=sb2i(leftt,kc,kd)&
		  +2.0_KR*usp(leftt,2,kc,ac)*multsb1r(ahere,ac,kd)&
		  +2.0_KR*usp(leftt,1,kc,ac)*multsb1i(ahere,ac,kd)

	       ELSE IF((kd.eq.1 .or. kd.eq.2).and.(at.ne.nt)) THEN

	  	   sb2r(rightt,kc,kd)=sb2r(rightt,kc,kd)&
		  +2.0_KR*usp(ahere,1,ac,kc)*multsb1r(ahere,ac,kd)&
		  +2.0_KR*usp(ahere,2,ac,kc)*multsb1i(ahere,ac,kd)

		   sb2i(rightt,kc,kd)=sb2i(rightt,kc,kd)&
		  -2.0_KR*usp(ahere,2,ac,kc)*multsb1r(ahere,ac,kd)&
		  +2.0_KR*usp(ahere,1,ac,kc)*multsb1i(ahere,ac,kd)

	       END IF
	   end if

!     Point-split J_1 (1-direction)
!     Diagonal part

	   sb2r(leftx,kc,kd)=sb2r(leftx,kc,kd)&
	  +uss(leftx,1,1,kc,ac)*multsb1r(ahere,ac,kd)&
	  -uss(leftx,1,2,kc,ac)*multsb1i(ahere,ac,kd)

	   sb2r(rightx,kc,kd)=sb2r(rightx,kc,kd)&
	  +uss(ahere,1,1,ac,kc)*multsb1r(ahere,ac,kd)&
	  +uss(ahere,1,2,ac,kc)*multsb1i(ahere,ac,kd)

	   sb2i(leftx,kc,kd)=sb2i(leftx,kc,kd)&
	  +uss(leftx,1,2,kc,ac)*multsb1r(ahere,ac,kd)&
	  +uss(leftx,1,1,kc,ac)*multsb1i(ahere,ac,kd)

	   sb2i(rightx,kc,kd)=sb2i(rightx,kc,kd)&
	  -uss(ahere,1,2,ac,kc)*multsb1r(ahere,ac,kd)&
	  +uss(ahere,1,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Off-diagonal J_1 part
! Changed the following off diagonal part to match gaugelinks in CurrentCalc.


	   sb2r(leftx,kc,5-kd)=sb2r(leftx,kc,5-kd)&
	  -uss(leftx,1,1,kc,ac)*multsb1r(ahere,ac,kd)&
	  +uss(leftx,1,2,kc,ac)*multsb1i(ahere,ac,kd)

	   sb2r(rightx,kc,5-kd)=sb2r(rightx,kc,5-kd)&
	  +uss(ahere,1,1,ac,kc)*multsb1r(ahere,ac,kd)&
	  +uss(ahere,1,2,ac,kc)*multsb1i(ahere,ac,kd)

	   sb2i(leftx,kc,5-kd)=sb2i(leftx,kc,5-kd)&
	  -uss(leftx,1,2,kc,ac)*multsb1r(ahere,ac,kd)&
	  -uss(leftx,1,1,kc,ac)*multsb1i(ahere,ac,kd)

	   sb2i(rightx,kc,5-kd)=sb2i(rightx,kc,5-kd)&
	  -uss(ahere,1,2,ac,kc)*multsb1r(ahere,ac,kd)&
	  +uss(ahere,1,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Point-split J_2 (2-direction)
!     Diagonal part

	   sb2r(lefty,kc,kd)=sb2r(lefty,kc,kd)&
	  +uss(lefty,2,1,kc,ac)*multsb1r(ahere,ac,kd)&
	  -uss(lefty,2,2,kc,ac)*multsb1i(ahere,ac,kd)

	   sb2r(righty,kc,kd)=sb2r(righty,kc,kd)&
	  +uss(ahere,2,1,ac,kc)*multsb1r(ahere,ac,kd)&
	  +uss(ahere,2,2,ac,kc)*multsb1i(ahere,ac,kd)

	   sb2i(lefty,kc,kd)=sb2i(lefty,kc,kd)&
	  +uss(lefty,2,2,kc,ac)*multsb1r(ahere,ac,kd)&
	  +uss(lefty,2,1,kc,ac)*multsb1i(ahere,ac,kd)

	   sb2i(righty,kc,kd)=sb2i(righty,kc,kd)&
	  -uss(ahere,2,2,ac,kc)*multsb1r(ahere,ac,kd)&
	  +uss(ahere,2,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Off-diagonal J_2 part
! Changed the following off diagonal part to match gaugelinks in CurrentCalc.

	   IF (mod(kd,2).eq.0) THEN
	       sb2r(lefty,kc,5-kd)=sb2r(lefty,kc,5-kd)&
	      -uss(lefty,2,2,kc,ac)*multsb1r(ahere,ac,kd)&
	      -uss(lefty,2,1,kc,ac)*multsb1i(ahere,ac,kd)

	       sb2r(righty,kc,5-kd)=sb2r(righty,kc,5-kd)&
	      -uss(ahere,2,2,ac,kc)*multsb1r(ahere,ac,kd)&
	      +uss(ahere,2,1,ac,kc)*multsb1i(ahere,ac,kd)

	       sb2i(lefty,kc,5-kd)=sb2i(lefty,kc,5-kd)&
	      +uss(lefty,2,1,kc,ac)*multsb1r(ahere,ac,kd)&
	      -uss(lefty,2,2,kc,ac)*multsb1i(ahere,ac,kd)

	       sb2i(righty,kc,5-kd)=sb2i(righty,kc,5-kd)&
	      -uss(ahere,2,1,ac,kc)*multsb1r(ahere,ac,kd)&
	      -uss(ahere,2,2,ac,kc)*multsb1i(ahere,ac,kd)

	   ELSE IF(mod(kd,2).eq.1) THEN

	       sb2r(lefty,kc,5-kd)=sb2r(lefty,kc,5-kd)&
	      +uss(lefty,2,2,kc,ac)*multsb1r(ahere,ac,kd)&
	      +uss(lefty,2,1,kc,ac)*multsb1i(ahere,ac,kd)

	       sb2r(righty,kc,5-kd)=sb2r(righty,kc,5-kd)&
	      +uss(ahere,2,2,ac,kc)*multsb1r(ahere,ac,kd)&
	      -uss(ahere,2,1,ac,kc)*multsb1i(ahere,ac,kd)

	       sb2i(lefty,kc,5-kd)=sb2i(lefty,kc,5-kd)&
	      -uss(lefty,2,1,kc,ac)*multsb1r(ahere,ac,kd)&
	      +uss(lefty,2,2,kc,ac)*multsb1i(ahere,ac,kd)

	       sb2i(righty,kc,5-kd)=sb2i(righty,kc,5-kd)&
	      +uss(ahere,2,1,ac,kc)*multsb1r(ahere,ac,kd)&
	      +uss(ahere,2,2,ac,kc)*multsb1i(ahere,ac,kd)

	   END IF

!     Point-split J_3 (3-direction)
!     Diagonal part

               sb2r(leftz,kc,kd)=sb2r(leftz,kc,kd)&
	      +uss(leftz,3,1,kc,ac)*multsb1r(ahere,ac,kd)&
	      -uss(leftz,3,2,kc,ac)*multsb1i(ahere,ac,kd)

	       sb2r(rightz,kc,kd)=sb2r(rightz,kc,kd)&
	      +uss(ahere,3,1,ac,kc)*multsb1r(ahere,ac,kd)&
	      +uss(ahere,3,2,ac,kc)*multsb1i(ahere,ac,kd)

	       sb2i(leftz,kc,kd)=sb2i(leftz,kc,kd)&
	      +uss(leftz,3,2,kc,ac)*multsb1r(ahere,ac,kd)&
	      +uss(leftz,3,1,kc,ac)*multsb1i(ahere,ac,kd)

	       sb2i(rightz,kc,kd)=sb2i(rightz,kc,kd)&
	      -uss(ahere,3,2,ac,kc)*multsb1r(ahere,ac,kd)&
	      +uss(ahere,3,1,ac,kc)*multsb1i(ahere,ac,kd)

!     Off-diagonal J_3 part
! Changed the following off diagonal part to match gaugelinks in CurrentCalc.

   	       IF (mod(kd,2).eq.1) THEN
		   sb2r(leftz,kc,3/kd)=sb2r(leftz,kc,3/kd)&
		  -uss(leftz,3,1,kc,ac)*multsb1r(ahere,ac,kd)&
		  +uss(leftz,3,2,kc,ac)*multsb1i(ahere,ac,kd)

		   sb2r(rightz,kc,3/kd)=sb2r(rightz,kc,3/kd)&
		  +uss(ahere,3,1,ac,kc)*multsb1r(ahere,ac,kd)&
		  +uss(ahere,3,2,ac,kc)*multsb1i(ahere,ac,kd)

		   sb2i(leftz,kc,3/kd)=sb2i(leftz,kc,3/kd)&
		  -uss(leftz,3,2,kc,ac)*multsb1r(ahere,ac,kd)&
		  -uss(leftz,3,1,kc,ac)*multsb1i(ahere,ac,kd)

		   sb2i(rightz,kc,3/kd)=sb2i(rightz,kc,3/kd)&
		  -uss(ahere,3,2,ac,kc)*multsb1r(ahere,ac,kd)&
		  +uss(ahere,3,1,ac,kc)*multsb1i(ahere,ac,kd)

	       ELSE IF(mod(kd,2).eq.0) THEN

	   	   sb2r(leftz,kc,8/kd)=sb2r(leftz,kc,8/kd)&
		  +uss(leftz,3,1,kc,ac)*multsb1r(ahere,ac,kd)&
		  -uss(leftz,3,2,kc,ac)*multsb1i(ahere,ac,kd)

		   sb2r(rightz,kc,8/kd)=sb2r(rightz,kc,8/kd)&
		  -uss(ahere,3,1,ac,kc)*multsb1r(ahere,ac,kd)&
		  -uss(ahere,3,2,ac,kc)*multsb1i(ahere,ac,kd)

		   sb2i(leftz,kc,8/kd)=sb2i(leftz,kc,8/kd)&
		  +uss(leftz,3,2,kc,ac)*multsb1r(ahere,ac,kd)&
		  +uss(leftz,3,1,kc,ac)*multsb1i(ahere,ac,kd)

		   sb2i(rightz,kc,8/kd)=sb2i(rightz,kc,8/kd)&
		  +uss(ahere,3,2,ac,kc)*multsb1r(ahere,ac,kd)&
		  -uss(ahere,3,1,ac,kc)*multsb1i(ahere,ac,kd)

	       END IF
       enddo ! kc loop
    enddo ! kd loop
  endif ! (ad==1).or.(ad==3)

  multsb1r(ahere,ac,ad)=0.0_KR
  multsb1i(ahere,ac,ad)=0.0_KR
	      
  Return
  End subroutine Multiply

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx

  Subroutine GammaMultiply2(sb2r,sb2i,multsb1r,multsb1i,&
                           ax,ay,az,at,usp,uss,fixbc,myid)

! INPUT: 
! sbxr, sbxi  :: are the input vectors that contain the previous order
!                of the perturbatively expanded matrix.
! ax,ay,az,at :: the space-time coordinates that define the correct position
!                of the propagators and where they are "farmed" out to.
! usp         :: the time gauge link
! uss         :: the space gauge line
! fixbc       :: specifies if the boundry conditions are fixed or periodic 
!                in the time direction. All space corrdinates are periddic. 
!                fixbc==.true. (fixed) ; fixbc==.false. (periodic)
! myid        :: identifies the process in a parrallel program.

! OUTPUT:
! sb2r,sb2i   :: the multiplied output vector that contains the matrix 
!                multiplication for the perturbative expansion. 

  use input2      ! makes cosd,sind "global constants"
! use multstorage ! allocates memmory for multsbir and multsb1i

  real(kind=KR),    intent(in),    dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),    dimension(:,:,:,:,:)             :: uss
! real(kind=KR),    intent(in),    dimension(nxyzt,nc,nd)           :: sbxr,sbxi
  integer(kind=KI), intent(in)                                      :: myid
  real(kind=KR),    intent(inout), dimension(nxyzt,nc,nd)           :: sb2r,sb2i
  logical,          intent(in)                                      :: fixbc
  real(kind=KR),                   dimension(2)                     :: sbr,sbi
  integer(kind=KI), intent(in)                                      :: ax,ay,az,at
  integer(kind=KI)                                                  :: bx,by,bz,bt
  integer(kind=KI)                                                  :: ahere,leftx,rightx,&
                                                                       lefty,righty,leftz,rightz,&
                                                                       leftt,rightt
  integer(kind=KI)                                                  :: im,imm,ad,ac,kc,kd,ierr
  integer(kind=KI),                dimension(9)                     :: imv
  logical                                                           :: false,true
  integer(kind=KI) :: counter, ii
  real(kind=KR),   intent(in),     dimension(nxyzt,nc,nd)           :: multsb1r,multsb1i

  !call allocatemults


! NOTE: This subroutine, GammaMultiply uses a different
!       representation for the off-diagonal elements of the
!       operators. The other representation is found in
!       subroutine Multiply.


! Impose periodic boundary conditions

  bx = mod(ax-1+nx,nx)+1
  by = mod(ay-1+ny,ny)+1
  bz = mod(az-1+nz,nz)+1
  bt = mod(at-1+nt,nt)+1

  leftx  = mod((bx-1)-1+nx,nx)+1
  rightx = mod((bx+1)-1+nx,nx)+1
  lefty  = mod((by-1)-1+ny,ny)+1
  righty = mod((by+1)-1+ny,ny)+1
  leftz  = mod((bz-1)-1+nz,nz)+1
  rightz = mod((bz+1)-1+nz,nz)+1
  leftt  = mod((bt-1)-1+nt,nt)+1
  rightt = mod((bt+1)-1+nt,nt)+1

! Translate coordinates to single array index

  ahere = bx + (by-1)*nx + (bz-1)*nx*ny + (bt-1)*nx*ny*nz

  
! multsb1r(ahere,:,:) = 0.0_KR
! multsb1r(ahere,:,:) = 0.0_KR

! multsb1r(ahere,:,:) = sbxr(ahere,:,:)
! multsb1i(ahere,:,:) = sbxi(ahere,:,:)

! do kc=1,nc
 
!    sbr(1) = multsb1r(ahere,kc,1)
!    sbi(1) = multsb1i(ahere,kc,1)
!    sbr(2) = multsb1r(ahere,kc,2)
!    sbi(2) = multsb1i(ahere,kc,2)
 
!    multsb1r(ahere,kc,1) = cosd*multsb1r(ahere,kc,1) - sind*multsb1r(ahere,kc,3)
!    multsb1i(ahere,kc,1) = cosd*multsb1i(ahere,kc,1) - sind*multsb1i(ahere,kc,3)
!    multsb1r(ahere,kc,2) = cosd*multsb1r(ahere,kc,2) - sind*multsb1r(ahere,kc,4)
!    multsb1i(ahere,kc,2) = cosd*multsb1i(ahere,kc,2) - sind*multsb1i(ahere,kc,4)
 
!    multsb1r(ahere,kc,3) = cosd*multsb1r(ahere,kc,3) + sind*sbr(1)
!    multsb1i(ahere,kc,3) = cosd*multsb1i(ahere,kc,3) + sind*sbi(1)
!    multsb1r(ahere,kc,4) = cosd*multsb1r(ahere,kc,4) + sind*sbr(2)
!    multsb1i(ahere,kc,4) = cosd*multsb1i(ahere,kc,4) + sind*sbi(2)
! enddo ! kc

  leftx  = leftx+(by-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  rightx = rightx+(by-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  lefty  = bx+(lefty-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  righty = bx+(righty-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  leftz  = bx+(by-1)*nx+(leftz-1)*nx*ny+(bt-1)*nx*ny*nz
  rightz = bx+(by-1)*nx+(rightz-1)*nx*ny+(bt-1)*nx*ny*nz
  leftt  = bx+(by-1)*nx+(bz-1)*nx*ny+(leftt-1)*nx*ny*nz
  rightt = bx+(by-1)*nx+(bz-1)*nx*ny+(rightt-1)*nx*ny*nz

   imv(1) = leftx
   imv(2) = rightx
   imv(3) = lefty
   imv(4) = righty
   imv(5) = leftz
   imv(6) = rightz
   imv(7) = leftt
   imv(8) = rightt

   do kd=1,4
      do ac=1,nc
         do kc=1,nc
         if (multsb1r(ahere,kc,kd)/=0.0_KR .or. multsb1i(ahere,kc,kd)/=0.0_KR) then

!   Point-split J_4 (4-direction)
            if (.not. fixbc) then
! U_mu(x) contribution
                IF (kd.eq.3 .or. kd.eq.4) THEN
                    sb2r(leftt,ac,kd)=sb2r(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(leftt,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftt,ac,kd)=sb2i(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution
                ELSE IF(kd.eq.1 .or. kd.eq.2) THEN
                    sb2r(rightt,ac,kd)=sb2r(rightt,ac,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightt,ac,kd)=sb2i(rightt,ac,kd)&
                   -2.0_KR*usp(ahere,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF
            else ! fixbc
! U_mu(x) contribution
                IF ((kd.eq.3 .or. kd.eq.4).and.(bt.ne.1)) THEN
                    sb2r(leftt,ac,kd)=sb2r(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(leftt,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftt,ac,kd)=sb2i(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution
                ELSE IF((kd.eq.1 .or. kd.eq.2).and.(bt.ne.nt)) THEN
                    sb2r(rightt,ac,kd)=sb2r(rightt,ac,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightt,ac,kd)=sb2i(rightt,ac,kd)&
                   -2.0_KR*usp(ahere,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF
            end if ! fixbc

!     Point-split J_1 (1-direction)
!     Diagonal part

! U_mu(x) contribution
 

            sb2r(leftx,ac,kd)=sb2r(leftx,ac,kd)&
           +uss(leftx,1,1,ac,kc)*multsb1r(ahere,kc,kd)&
           -uss(leftx,1,2,ac,kc)*multsb1i(ahere,kc,kd)
 
            sb2i(leftx,ac,kd)=sb2i(leftx,ac,kd)&
           +uss(leftx,1,1,ac,kc)*multsb1i(ahere,kc,kd)&
           +uss(leftx,1,2,ac,kc)*multsb1r(ahere,kc,kd)
 
! U_mudagger(x) contribution

            sb2r(rightx,ac,kd)=sb2r(rightx,ac,kd)&
           +uss(ahere,1,1,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,1,2,kc,ac)*multsb1i(ahere,kc,kd)
 
            sb2i(rightx,ac,kd)=sb2i(rightx,ac,kd)&
           +uss(ahere,1,1,kc,ac)*multsb1i(ahere,kc,kd)&
           -uss(ahere,1,2,kc,ac)*multsb1r(ahere,kc,kd)
 
!     Off-diagonal dirac J_1 part

! U_mu(x) contribution 
 
            sb2r(leftx,ac,5-kd)=sb2r(leftx,ac,5-kd)&
           -uss(leftx,1,1,ac,kc)*multsb1r(ahere,kc,kd)&
           +uss(leftx,1,2,ac,kc)*multsb1i(ahere,kc,kd)
 
            sb2i(leftx,ac,5-kd)=sb2i(leftx,ac,5-kd)&
           -uss(leftx,1,1,ac,kc)*multsb1i(ahere,kc,kd)&
           -uss(leftx,1,2,ac,kc)*multsb1r(ahere,kc,kd)
 
! U_mudagger(x) contribution

            sb2r(rightx,ac,5-kd)=sb2r(rightx,ac,5-kd)&
           +uss(ahere,1,1,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,1,2,kc,ac)*multsb1i(ahere,kc,kd)
 
            sb2i(rightx,ac,5-kd)=sb2i(rightx,ac,5-kd)&
           +uss(ahere,1,1,kc,ac)*multsb1i(ahere,kc,kd)&
           -uss(ahere,1,2,kc,ac)*multsb1r(ahere,kc,kd)

!     Point-split J_2 (2-direction)
!     Diagonal part

! U_mu(x) contribution

            sb2r(lefty,ac,kd)=sb2r(lefty,ac,kd)&
           +uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
           -uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

            sb2i(lefty,ac,kd)=sb2i(lefty,ac,kd)&
           +uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
           +uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

            sb2r(righty,ac,kd)=sb2r(righty,ac,kd)&
           +uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            sb2i(righty,ac,kd)=sb2i(righty,ac,kd)&
           -uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)

!     Off-diagonal dirac J_2 part
            IF (mod(kd,2).eq.0) THEN

! U_mu(x) contribution

                sb2r(lefty,ac,5-kd)=sb2r(lefty,ac,5-kd)&
               -uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(lefty,ac,5-kd)=sb2i(lefty,ac,5-kd)&
               +uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(righty,ac,5-kd)=sb2r(righty,ac,5-kd)&
               -uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)


                sb2i(righty,ac,5-kd)=sb2i(righty,ac,5-kd)&
               -uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            ELSE IF(mod(kd,2).eq.1) THEN

! U_mu(x) contribution

                sb2r(lefty,ac,5-kd)=sb2r(lefty,ac,5-kd)&
               +uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(lefty,ac,5-kd)=sb2i(lefty,ac,5-kd)&
               -uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(righty,ac,5-kd)=sb2r(righty,ac,5-kd)&
               +uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)

                sb2i(righty,ac,5-kd)=sb2i(righty,ac,5-kd)&
               +uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            END IF

!     Point-split J_3 (3-direction)
!     Diagonal part

! U_mu(x) contribution

                sb2r(leftz,ac,kd)=sb2r(leftz,ac,kd)&
               +uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(leftz,ac,kd)=sb2i(leftz,ac,kd)&
               +uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(rightz,ac,kd)=sb2r(rightz,ac,kd)&
               +uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                sb2i(rightz,ac,kd)=sb2i(rightz,ac,kd)&
               -uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

!     Off-diagonal dirac J_3 part
                IF (mod(kd,2).eq.1) THEN

! U_mu(x) contribution

                    sb2r(leftz,ac,3/kd)=sb2r(leftz,ac,3/kd)&
                   -uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   +uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftz,ac,3/kd)=sb2i(leftz,ac,3/kd)&
                   -uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   -uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                    sb2r(rightz,ac,3/kd)=sb2r(rightz,ac,3/kd)&
                   +uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   +uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightz,ac,3/kd)=sb2i(rightz,ac,3/kd)&
                   -uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   +uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

                ELSE IF(mod(kd,2).eq.0) THEN

! U_mu(x) contribution

                   sb2r(leftz,ac,8/kd)=sb2r(leftz,ac,8/kd)&
                  +uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
                  -uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                   sb2i(leftz,ac,8/kd)=sb2i(leftz,ac,8/kd)&
                  +uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
                  +uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                   sb2r(rightz,ac,8/kd)=sb2r(rightz,ac,8/kd)&
                  -uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
                  -uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                   sb2i(rightz,ac,8/kd)=sb2i(rightz,ac,8/kd)&
                  +uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
                  -uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF

            endif ! check
            enddo ! kc loop
         enddo ! ac
      enddo ! kd loop

  do ii=1,8
  do kc=1,nc

     sbr(1) = sb2r(imv(ii),kc,1)
     sbi(1) = sb2i(imv(ii),kc,1)
     sbr(2) = sb2r(imv(ii),kc,2)
     sbi(2) = sb2i(imv(ii),kc,2)

     sb2r(imv(ii),kc,1) = cosd*sb2r(imv(ii),kc,1) - sind*sb2r(imv(ii),kc,3)
     sb2i(imv(ii),kc,1) = cosd*sb2i(imv(ii),kc,1) - sind*sb2i(imv(ii),kc,3)
     sb2r(imv(ii),kc,2) = cosd*sb2r(imv(ii),kc,2) - sind*sb2r(imv(ii),kc,4)
     sb2i(imv(ii),kc,2) = cosd*sb2i(imv(ii),kc,2) - sind*sb2i(imv(ii),kc,4)

     sb2r(imv(ii),kc,3) = cosd*sb2r(imv(ii),kc,3) + sind*sbr(1)
     sb2i(imv(ii),kc,3) = cosd*sb2i(imv(ii),kc,3) + sind*sbi(1)
     sb2r(imv(ii),kc,4) = cosd*sb2r(imv(ii),kc,4) + sind*sbr(2)
     sb2i(imv(ii),kc,4) = cosd*sb2i(imv(ii),kc,4) + sind*sbi(2)
  enddo ! kc
  enddo ! ii


  Return
  End subroutine GammaMultiply2

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx

  Subroutine GammaMultiplyP(sb2r,sb2i,sbxr,sbxi,&
                           ax,ay,az,at,usp,uss,fixbc,myid)

! This routine was called GammaMultiply. Changed name ONLY to
! GammaMultiplyP on 1-15-08. Represents Wilson action multiply
! with r=+1.

! INPUT:
! sbxr, sbxi  :: are the input vectors that contain the previous order
!                of the perturbatively expanded matrix.
! ax,ay,az,at :: the space-time coordinates that define the correct position
!                of the propagators and where they are "farmed" out to.
! usp         :: the time gauge link
! uss         :: the space gauge line
! fixbc       :: specifies if the boundry conditions are fixed or periodic
!                in the time direction. All space corrdinates are periddic.
!                fixbc==.true. (fixed) ; fixbc==.false. (periodic)
! myid        :: identifies the process in a parrallel program.

! OUTPUT:
! sb2r,sb2i   :: the multiplied output vector that contains the matrix
!                multiplication for the perturbative expansion.

  use input2      ! makes cosd,sind "global constants"
! use multstorage ! allocates memmory for multsbir and multsb1i

  real(kind=KR),    intent(in),    dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),    dimension(:,:,:,:,:)             :: uss
  real(kind=KR),    intent(in),    dimension(nxyzt,nc,nd)           :: sbxr,sbxi
  integer(kind=KI), intent(in)                                      :: myid
  real(kind=KR),    intent(inout), dimension(nxyzt,nc,nd)           :: sb2r,sb2i
  logical,          intent(in)                                      :: fixbc
  real(kind=KR),                   dimension(2)                     :: sbr,sbi
  integer(kind=KI), intent(in)                                      :: ax,ay,az,at
  integer(kind=KI)                                                  :: bx,by,bz,bt
  integer(kind=KI)                                                  :: ahere,leftx,rightx,&
                                                                       lefty,righty,leftz,rightz,&
                                                                       leftt,rightt
  integer(kind=KI)                                                  :: im,imm,ad,ac,kc,kd,ierr
  integer(kind=KI),                dimension(9)                     :: imv
  logical                                                           :: false,true
  integer(kind=KI) :: counter, ii
  real(kind=KR),                   dimension(nxyzt,nc,nd)           :: multsb1r,multsb1i

  !call allocatemults


! NOTE: This subroutine, GammaMultiply uses a different
!       representation for the off-diagonal elements of the
!       operators. The other representation is found in
!       subroutine Multiply.


! Impose periodic boundary conditions

  bx = mod(ax-1+nx,nx)+1
  by = mod(ay-1+ny,ny)+1
  bz = mod(az-1+nz,nz)+1
  bt = mod(at-1+nt,nt)+1

  leftx  = mod((bx-1)-1+nx,nx)+1
  rightx = mod((bx+1)-1+nx,nx)+1
  lefty  = mod((by-1)-1+ny,ny)+1
  righty = mod((by+1)-1+ny,ny)+1
  leftz  = mod((bz-1)-1+nz,nz)+1
  rightz = mod((bz+1)-1+nz,nz)+1
  leftt  = mod((bt-1)-1+nt,nt)+1
  rightt = mod((bt+1)-1+nt,nt)+1

! Translate coordinates to single array index

  ahere = bx + (by-1)*nx + (bz-1)*nx*ny + (bt-1)*nx*ny*nz


  multsb1r(ahere,:,:) = 0.0_KR
  multsb1r(ahere,:,:) = 0.0_KR

  multsb1r(ahere,:,:) = sbxr(ahere,:,:)
  multsb1i(ahere,:,:) = sbxi(ahere,:,:)


  do kc=1,nc

     sbr(1) = multsb1r(ahere,kc,1)
     sbi(1) = multsb1i(ahere,kc,1)
     sbr(2) = multsb1r(ahere,kc,2)
     sbi(2) = multsb1i(ahere,kc,2)

     multsb1r(ahere,kc,1) = cosd*multsb1r(ahere,kc,1) - sind*multsb1r(ahere,kc,3)
     multsb1i(ahere,kc,1) = cosd*multsb1i(ahere,kc,1) - sind*multsb1i(ahere,kc,3)
     multsb1r(ahere,kc,2) = cosd*multsb1r(ahere,kc,2) - sind*multsb1r(ahere,kc,4)
     multsb1i(ahere,kc,2) = cosd*multsb1i(ahere,kc,2) - sind*multsb1i(ahere,kc,4)

     multsb1r(ahere,kc,3) = cosd*multsb1r(ahere,kc,3) + sind*sbr(1)
     multsb1i(ahere,kc,3) = cosd*multsb1i(ahere,kc,3) + sind*sbi(1)
     multsb1r(ahere,kc,4) = cosd*multsb1r(ahere,kc,4) + sind*sbr(2)
     multsb1i(ahere,kc,4) = cosd*multsb1i(ahere,kc,4) + sind*sbi(2)
  enddo ! kc

  leftx  = leftx+(by-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  rightx = rightx+(by-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  lefty  = bx+(lefty-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  righty = bx+(righty-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  leftz  = bx+(by-1)*nx+(leftz-1)*nx*ny+(bt-1)*nx*ny*nz
  rightz = bx+(by-1)*nx+(rightz-1)*nx*ny+(bt-1)*nx*ny*nz
  leftt  = bx+(by-1)*nx+(bz-1)*nx*ny+(leftt-1)*nx*ny*nz
  rightt = bx+(by-1)*nx+(bz-1)*nx*ny+(rightt-1)*nx*ny*nz

   do kd=1,4
      do ac=1,nc
         do kc=1,nc
         if (multsb1r(ahere,kc,kd)/=0.0_KR .or. multsb1i(ahere,kc,kd)/=0.0_KR) then

!   Point-split J_4 (4-direction)
            if (.not. fixbc) then
! U_mu(x) contribution
                IF (kd.eq.3 .or. kd.eq.4) THEN
                    sb2r(leftt,ac,kd)=sb2r(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(leftt,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftt,ac,kd)=sb2i(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution
                ELSE IF(kd.eq.1 .or. kd.eq.2) THEN
                    sb2r(rightt,ac,kd)=sb2r(rightt,ac,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightt,ac,kd)=sb2i(rightt,ac,kd)&
                   -2.0_KR*usp(ahere,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF
            else ! fixbc
! U_mu(x) contribution
                IF ((kd.eq.3 .or. kd.eq.4).and.(bt.ne.1)) THEN
                    sb2r(leftt,ac,kd)=sb2r(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(leftt,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftt,ac,kd)=sb2i(leftt,ac,kd)&
                   +2.0_KR*usp(leftt,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(leftt,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution
                ELSE IF((kd.eq.1 .or. kd.eq.2).and.(bt.ne.nt)) THEN
                    sb2r(rightt,ac,kd)=sb2r(rightt,ac,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightt,ac,kd)=sb2i(rightt,ac,kd)&
                   -2.0_KR*usp(ahere,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(ahere,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF
            end if ! fixbc

!     Point-split J_1 (1-direction)
!     Diagonal part

! U_mu(x) contribution


            sb2r(leftx,ac,kd)=sb2r(leftx,ac,kd)&
           +uss(leftx,1,1,ac,kc)*multsb1r(ahere,kc,kd)&
           -uss(leftx,1,2,ac,kc)*multsb1i(ahere,kc,kd)

            sb2i(leftx,ac,kd)=sb2i(leftx,ac,kd)&
           +uss(leftx,1,1,ac,kc)*multsb1i(ahere,kc,kd)&
           +uss(leftx,1,2,ac,kc)*multsb1r(ahere,kc,kd)

! U_mudagger(x) contribution

            sb2r(rightx,ac,kd)=sb2r(rightx,ac,kd)&
           +uss(ahere,1,1,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,1,2,kc,ac)*multsb1i(ahere,kc,kd)

            sb2i(rightx,ac,kd)=sb2i(rightx,ac,kd)&
           +uss(ahere,1,1,kc,ac)*multsb1i(ahere,kc,kd)&
           -uss(ahere,1,2,kc,ac)*multsb1r(ahere,kc,kd)

!     Off-diagonal dirac J_1 part

! U_mu(x) contribution

            sb2r(leftx,ac,5-kd)=sb2r(leftx,ac,5-kd)&
           -uss(leftx,1,1,ac,kc)*multsb1r(ahere,kc,kd)&
           +uss(leftx,1,2,ac,kc)*multsb1i(ahere,kc,kd)

            sb2i(leftx,ac,5-kd)=sb2i(leftx,ac,5-kd)&
           -uss(leftx,1,1,ac,kc)*multsb1i(ahere,kc,kd)&
           -uss(leftx,1,2,ac,kc)*multsb1r(ahere,kc,kd)

! U_mudagger(x) contribution

            sb2r(rightx,ac,5-kd)=sb2r(rightx,ac,5-kd)&
           +uss(ahere,1,1,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,1,2,kc,ac)*multsb1i(ahere,kc,kd)

            sb2i(rightx,ac,5-kd)=sb2i(rightx,ac,5-kd)&
           +uss(ahere,1,1,kc,ac)*multsb1i(ahere,kc,kd)&
           -uss(ahere,1,2,kc,ac)*multsb1r(ahere,kc,kd)

!     Point-split J_2 (2-direction)
!     Diagonal part

! U_mu(x) contribution

            sb2r(lefty,ac,kd)=sb2r(lefty,ac,kd)&
           +uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
           -uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

            sb2i(lefty,ac,kd)=sb2i(lefty,ac,kd)&
           +uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
           +uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

            sb2r(righty,ac,kd)=sb2r(righty,ac,kd)&
           +uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            sb2i(righty,ac,kd)=sb2i(righty,ac,kd)&
           -uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)

!     Off-diagonal dirac J_2 part
            IF (mod(kd,2).eq.0) THEN

! U_mu(x) contribution

                sb2r(lefty,ac,5-kd)=sb2r(lefty,ac,5-kd)&
               -uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(lefty,ac,5-kd)=sb2i(lefty,ac,5-kd)&
               +uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(righty,ac,5-kd)=sb2r(righty,ac,5-kd)&
               -uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)


                sb2i(righty,ac,5-kd)=sb2i(righty,ac,5-kd)&
               -uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            ELSE IF(mod(kd,2).eq.1) THEN

! U_mu(x) contribution

                sb2r(lefty,ac,5-kd)=sb2r(lefty,ac,5-kd)&
               +uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(lefty,ac,5-kd)=sb2i(lefty,ac,5-kd)&
               -uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(righty,ac,5-kd)=sb2r(righty,ac,5-kd)&
               +uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)

                sb2i(righty,ac,5-kd)=sb2i(righty,ac,5-kd)&
               +uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            END IF

!     Point-split J_3 (3-direction)
!     Diagonal part

! U_mu(x) contribution

                sb2r(leftz,ac,kd)=sb2r(leftz,ac,kd)&
               +uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(leftz,ac,kd)=sb2i(leftz,ac,kd)&
               +uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(rightz,ac,kd)=sb2r(rightz,ac,kd)&
               +uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                sb2i(rightz,ac,kd)=sb2i(rightz,ac,kd)&
               -uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

!     Off-diagonal dirac J_3 part
                IF (mod(kd,2).eq.1) THEN

! U_mu(x) contribution

                    sb2r(leftz,ac,3/kd)=sb2r(leftz,ac,3/kd)&
                   -uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   +uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftz,ac,3/kd)=sb2i(leftz,ac,3/kd)&
                   -uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   -uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                    sb2r(rightz,ac,3/kd)=sb2r(rightz,ac,3/kd)&
                   +uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   +uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightz,ac,3/kd)=sb2i(rightz,ac,3/kd)&
                   -uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   +uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

                ELSE IF(mod(kd,2).eq.0) THEN

! U_mu(x) contribution

                   sb2r(leftz,ac,8/kd)=sb2r(leftz,ac,8/kd)&
                  +uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
                  -uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                   sb2i(leftz,ac,8/kd)=sb2i(leftz,ac,8/kd)&
                  +uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
                  +uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                   sb2r(rightz,ac,8/kd)=sb2r(rightz,ac,8/kd)&
                  -uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
                  -uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                   sb2i(rightz,ac,8/kd)=sb2i(rightz,ac,8/kd)&
                  +uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
                  -uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF

            endif ! check
            enddo ! kc loop
         enddo ! ac
      enddo ! kd loop

  Return
  End subroutine GammaMultiplyP

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx

  Subroutine GammaMultiplyM(sb2r,sb2i,sbxr,sbxi,&
                           ax,ay,az,at,usp,uss,fixbc,myid)

! This routine is used when the r factor in Wilson's action takes
! on the value of -1. GammaMultiplyP is used for r = +1.

! INPUT:
! sbxr, sbxi  :: are the input vectors that contain the previous order
!                of the perturbatively expanded matrix.
! ax,ay,az,at :: the space-time coordinates that define the correct position
!                of the propagators and where they are "farmed" out to.
! usp         :: the time gauge link
! uss         :: the space gauge line
! fixbc       :: specifies if the boundry conditions are fixed or periodic
!                in the time direction. All space corrdinates are periddic.
!                fixbc==.true. (fixed) ; fixbc==.false. (periodic)
! myid        :: identifies the process in a parrallel program.

! OUTPUT:
! sb2r,sb2i   :: the multiplied output vector that contains the matrix
!                multiplication for the perturbative expansion.

  use input2      ! makes cosd,sind "global constants"
! use multstorage ! allocates memmory for multsbir and multsb1i

  real(kind=KR),    intent(in),    dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),    dimension(:,:,:,:,:)             :: uss
  real(kind=KR),    intent(in),    dimension(nxyzt,nc,nd)           :: sbxr,sbxi
  integer(kind=KI), intent(in)                                      :: myid
  real(kind=KR),    intent(inout), dimension(nxyzt,nc,nd)           :: sb2r,sb2i
  logical,          intent(in)                                      :: fixbc
  real(kind=KR),                   dimension(2)                     :: sbr,sbi
  integer(kind=KI), intent(in)                                      :: ax,ay,az,at
  integer(kind=KI)                                                  :: bx,by,bz,bt
  integer(kind=KI)                                                  :: ahere,leftx,rightx,&
                                                                       lefty,righty,leftz,rightz,&
                                                                       leftt,rightt
  integer(kind=KI)                                                  :: im,imm,ad,ac,kc,kd,ierr
  integer(kind=KI),                dimension(9)                     :: imv
  logical                                                           :: false,true
  integer(kind=KI) :: counter, ii
  real(kind=KR),                   dimension(nxyzt,nc,nd)           :: multsb1r,multsb1i

  !call allocatemults


! NOTE: This subroutine, GammaMultiply uses a different
!       representation for the off-diagonal elements of the
!       operators. The other representation is found in
!       subroutine Multiply.


! Impose periodic boundary conditions

  bx = mod(ax-1+nx,nx)+1
  by = mod(ay-1+ny,ny)+1
  bz = mod(az-1+nz,nz)+1
  bt = mod(at-1+nt,nt)+1

  leftx  = mod((bx-1)-1+nx,nx)+1
  rightx = mod((bx+1)-1+nx,nx)+1
  lefty  = mod((by-1)-1+ny,ny)+1
  righty = mod((by+1)-1+ny,ny)+1
  leftz  = mod((bz-1)-1+nz,nz)+1
  rightz = mod((bz+1)-1+nz,nz)+1
  leftt  = mod((bt-1)-1+nt,nt)+1
  rightt = mod((bt+1)-1+nt,nt)+1

! Translate coordinates to single array index

  ahere = bx + (by-1)*nx + (bz-1)*nx*ny + (bt-1)*nx*ny*nz


  multsb1r(ahere,:,:) = 0.0_KR
  multsb1r(ahere,:,:) = 0.0_KR

  multsb1r(ahere,:,:) = sbxr(ahere,:,:)
  multsb1i(ahere,:,:) = sbxi(ahere,:,:)


  do kc=1,nc

     sbr(1) = multsb1r(ahere,kc,1)
     sbi(1) = multsb1i(ahere,kc,1)
     sbr(2) = multsb1r(ahere,kc,2)
     sbi(2) = multsb1i(ahere,kc,2)

     multsb1r(ahere,kc,1) = cosd*multsb1r(ahere,kc,1) - sind*multsb1r(ahere,kc,3)
     multsb1i(ahere,kc,1) = cosd*multsb1i(ahere,kc,1) - sind*multsb1i(ahere,kc,3)
     multsb1r(ahere,kc,2) = cosd*multsb1r(ahere,kc,2) - sind*multsb1r(ahere,kc,4)
     multsb1i(ahere,kc,2) = cosd*multsb1i(ahere,kc,2) - sind*multsb1i(ahere,kc,4)

     multsb1r(ahere,kc,3) = cosd*multsb1r(ahere,kc,3) + sind*sbr(1)
     multsb1i(ahere,kc,3) = cosd*multsb1i(ahere,kc,3) + sind*sbi(1)
     multsb1r(ahere,kc,4) = cosd*multsb1r(ahere,kc,4) + sind*sbr(2)
     multsb1i(ahere,kc,4) = cosd*multsb1i(ahere,kc,4) + sind*sbi(2)
  enddo ! kc

  leftx  = leftx+(by-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  rightx = rightx+(by-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  lefty  = bx+(lefty-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  righty = bx+(righty-1)*nx+(bz-1)*nx*ny+(bt-1)*nx*ny*nz
  leftz  = bx+(by-1)*nx+(leftz-1)*nx*ny+(bt-1)*nx*ny*nz
  rightz = bx+(by-1)*nx+(rightz-1)*nx*ny+(bt-1)*nx*ny*nz
  leftt  = bx+(by-1)*nx+(bz-1)*nx*ny+(leftt-1)*nx*ny*nz
  rightt = bx+(by-1)*nx+(bz-1)*nx*ny+(rightt-1)*nx*ny*nz

   do kd=1,4
      do ac=1,nc
         do kc=1,nc
         if (multsb1r(ahere,kc,kd)/=0.0_KR .or. multsb1i(ahere,kc,kd)/=0.0_KR) then

!   Point-split J_4 (4-direction)
            if (.not. fixbc) then
! U_mu(x) contribution
                IF (kd.eq.1 .or. kd.eq.2) THEN
                    sb2r(leftt,ac,kd)=sb2r(leftt,ac,kd)&
                   -2.0_KR*usp(leftt,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(leftt,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftt,ac,kd)=sb2i(leftt,ac,kd)&
                   -2.0_KR*usp(leftt,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(leftt,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution
                ELSE IF(kd.eq.3 .or. kd.eq.4) THEN
                    sb2r(rightt,ac,kd)=sb2r(rightt,ac,kd)&
                   -2.0_KR*usp(ahere,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(ahere,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightt,ac,kd)=sb2i(rightt,ac,kd)&
                   +2.0_KR*usp(ahere,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(ahere,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF
            else ! fixbc
! U_mu(x) contribution
                IF ((kd.eq.1 .or. kd.eq.2).and.(bt.ne.1)) THEN
                    sb2r(leftt,ac,kd)=sb2r(leftt,ac,kd)&
                   -2.0_KR*usp(leftt,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   +2.0_KR*usp(leftt,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftt,ac,kd)=sb2i(leftt,ac,kd)&
                   -2.0_KR*usp(leftt,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(leftt,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution
                ELSE IF((kd.eq.3 .or. kd.eq.4).and.(bt.ne.nt)) THEN
                    sb2r(rightt,ac,kd)=sb2r(rightt,ac,kd)&
                   -2.0_KR*usp(ahere,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(ahere,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightt,ac,kd)=sb2i(rightt,ac,kd)&
                   +2.0_KR*usp(ahere,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   -2.0_KR*usp(ahere,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF
            end if ! fixbc

!     Point-split J_1 (1-direction)
!     Diagonal part

! U_mu(x) contribution


            sb2r(leftx,ac,kd)=sb2r(leftx,ac,kd)&
           -uss(leftx,1,1,ac,kc)*multsb1r(ahere,kc,kd)&
           +uss(leftx,1,2,ac,kc)*multsb1i(ahere,kc,kd)

            sb2i(leftx,ac,kd)=sb2i(leftx,ac,kd)&
           -uss(leftx,1,1,ac,kc)*multsb1i(ahere,kc,kd)&
           -uss(leftx,1,2,ac,kc)*multsb1r(ahere,kc,kd)

! U_mudagger(x) contribution

            sb2r(rightx,ac,kd)=sb2r(rightx,ac,kd)&
           -uss(ahere,1,1,kc,ac)*multsb1r(ahere,kc,kd)&
           -uss(ahere,1,2,kc,ac)*multsb1i(ahere,kc,kd)

            sb2i(rightx,ac,kd)=sb2i(rightx,ac,kd)&
           -uss(ahere,1,1,kc,ac)*multsb1i(ahere,kc,kd)&
           +uss(ahere,1,2,kc,ac)*multsb1r(ahere,kc,kd)

!     Off-diagonal dirac J_1 part

! U_mu(x) contribution

            sb2r(leftx,ac,5-kd)=sb2r(leftx,ac,5-kd)&
           -uss(leftx,1,1,ac,kc)*multsb1r(ahere,kc,kd)&
           +uss(leftx,1,2,ac,kc)*multsb1i(ahere,kc,kd)

            sb2i(leftx,ac,5-kd)=sb2i(leftx,ac,5-kd)&
           -uss(leftx,1,1,ac,kc)*multsb1i(ahere,kc,kd)&
           -uss(leftx,1,2,ac,kc)*multsb1r(ahere,kc,kd)

! U_mudagger(x) contribution

            sb2r(rightx,ac,5-kd)=sb2r(rightx,ac,5-kd)&
           +uss(ahere,1,1,kc,ac)*multsb1r(ahere,kc,kd)&
           +uss(ahere,1,2,kc,ac)*multsb1i(ahere,kc,kd)

            sb2i(rightx,ac,5-kd)=sb2i(rightx,ac,5-kd)&
           +uss(ahere,1,1,kc,ac)*multsb1i(ahere,kc,kd)&
           -uss(ahere,1,2,kc,ac)*multsb1r(ahere,kc,kd)

!     Point-split J_2 (2-direction)
!     Diagonal part

! U_mu(x) contribution

            sb2r(lefty,ac,kd)=sb2r(lefty,ac,kd)&
           -uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
           +uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

            sb2i(lefty,ac,kd)=sb2i(lefty,ac,kd)&
           -uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
           -uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

            sb2r(righty,ac,kd)=sb2r(righty,ac,kd)&
           -uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
           -uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            sb2i(righty,ac,kd)=sb2i(righty,ac,kd)&
           +uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
           -uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)

!     Off-diagonal dirac J_2 part
            IF (mod(kd,2).eq.0) THEN

! U_mu(x) contribution

                sb2r(lefty,ac,5-kd)=sb2r(lefty,ac,5-kd)&
               -uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(lefty,ac,5-kd)=sb2i(lefty,ac,5-kd)&
               +uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(righty,ac,5-kd)=sb2r(righty,ac,5-kd)&
               -uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)


                sb2i(righty,ac,5-kd)=sb2i(righty,ac,5-kd)&
               -uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            ELSE IF(mod(kd,2).eq.1) THEN

! U_mu(x) contribution

                sb2r(lefty,ac,5-kd)=sb2r(lefty,ac,5-kd)&
               +uss(lefty,2,2,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(lefty,2,1,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(lefty,ac,5-kd)=sb2i(lefty,ac,5-kd)&
               -uss(lefty,2,1,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(lefty,2,2,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(righty,ac,5-kd)=sb2r(righty,ac,5-kd)&
               +uss(ahere,2,2,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,2,1,kc,ac)*multsb1i(ahere,kc,kd)

                sb2i(righty,ac,5-kd)=sb2i(righty,ac,5-kd)&
               +uss(ahere,2,1,kc,ac)*multsb1r(ahere,kc,kd)&
               +uss(ahere,2,2,kc,ac)*multsb1i(ahere,kc,kd)

            END IF

!     Point-split J_3 (3-direction)
!     Diagonal part

! U_mu(x) contribution

                sb2r(leftz,ac,kd)=sb2r(leftz,ac,kd)&
               -uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
               +uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                sb2i(leftz,ac,kd)=sb2i(leftz,ac,kd)&
               -uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
               -uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                sb2r(rightz,ac,kd)=sb2r(rightz,ac,kd)&
               -uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                sb2i(rightz,ac,kd)=sb2i(rightz,ac,kd)&
               +uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
               -uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

!     Off-diagonal dirac J_3 part
                IF (mod(kd,2).eq.1) THEN

! U_mu(x) contribution

                    sb2r(leftz,ac,3/kd)=sb2r(leftz,ac,3/kd)&
                   -uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
                   +uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                    sb2i(leftz,ac,3/kd)=sb2i(leftz,ac,3/kd)&
                   -uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
                   -uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                    sb2r(rightz,ac,3/kd)=sb2r(rightz,ac,3/kd)&
                   +uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
                   +uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                    sb2i(rightz,ac,3/kd)=sb2i(rightz,ac,3/kd)&
                   -uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
                   +uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

                ELSE IF(mod(kd,2).eq.0) THEN

! U_mu(x) contribution

                   sb2r(leftz,ac,8/kd)=sb2r(leftz,ac,8/kd)&
                  +uss(leftz,3,1,ac,kc)*multsb1r(ahere,kc,kd)&
                  -uss(leftz,3,2,ac,kc)*multsb1i(ahere,kc,kd)

                   sb2i(leftz,ac,8/kd)=sb2i(leftz,ac,8/kd)&
                  +uss(leftz,3,2,ac,kc)*multsb1r(ahere,kc,kd)&
                  +uss(leftz,3,1,ac,kc)*multsb1i(ahere,kc,kd)

! U_mudagger(x) contribution

                   sb2r(rightz,ac,8/kd)=sb2r(rightz,ac,8/kd)&
                  -uss(ahere,3,1,kc,ac)*multsb1r(ahere,kc,kd)&
                  -uss(ahere,3,2,kc,ac)*multsb1i(ahere,kc,kd)

                   sb2i(rightz,ac,8/kd)=sb2i(rightz,ac,8/kd)&
                  +uss(ahere,3,2,kc,ac)*multsb1r(ahere,kc,kd)&
                  -uss(ahere,3,1,kc,ac)*multsb1i(ahere,kc,kd)

                END IF

            endif ! check
            enddo ! kc loop
         enddo ! ac
      enddo ! kd loop

  Return
  End subroutine GammaMultiplyM

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx

  Subroutine GammaMultiply(sb2r,sb2i,sbxr,sbxi,&
                           ax,ay,az,at,usp,uss,fixbc,ir,myid)

! INPUT:
! sbxr, sbxi  :: are the input vectors that contain the previous order
!                of the perturbatively expanded matrix.
! ax,ay,az,at :: the space-time coordinates that define the correct position
!                of the propagators and where they are "farmed" out to.
! usp         :: the time gauge link
! uss         :: the space gauge line
! fixbc       :: specifies if the boundry conditions are fixed or periodic
!                in the time direction. All space corrdinates are periddic.
!                fixbc==.true. (fixed) ; fixbc==.false. (periodic)
! ir          :: Wilson r value.
! myid        :: identifies the process in a parrallel program.

! OUTPUT:
! sb2r,sb2i   :: the multiplied output vector that contains the matrix
!                multiplication for the perturbative expansion.

  use input2      ! makes cosd,sind "global constants"
! use multstorage ! allocates memmory for multsbir and multsb1i

  real(kind=KR),    intent(in),    dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),    dimension(:,:,:,:,:)             :: uss
  real(kind=KR),    intent(in),    dimension(nxyzt,nc,nd)           :: sbxr,sbxi
  integer(kind=KI), intent(in)                                      :: myid
  real(kind=KR),    intent(inout), dimension(nxyzt,nc,nd)           :: sb2r,sb2i
  logical,          intent(in)                                      :: fixbc
  integer(kind=KI), intent(in)                                      :: ax,ay,az,at,ir

 if(ir.eq.1) then 
   call GammaMultiplyP(sb2r,sb2i,sbxr,sbxi,ax,ay,az,at,usp,uss,fixbc,myid)
 endif

 if(ir.eq.-1) then 
  call GammaMultiplyM(sb2r,sb2i,sbxr,sbxi,ax,ay,az,at,usp,uss,fixbc,myid)
 endif

 end subroutine GammaMultiply


!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx

  Subroutine Calc1(s,jd,jc,jri)

  use operator
!  use gaugelinks

  integer jd,jc,jri
  integer(kind=KI)                                     :: ix,iy,iz,itt,&
    			  		                  ishift
  integer(kind=KI)                                     :: isp,ist
  integer(kind=KI)                                     :: ind1,ind2
  integer(kind=KI)                                     :: jcsrx
  real(kind=KR), dimension(nxyzt)                      :: s

  real(kind=KR), allocatable, dimension(:,:,:,:,:)     :: uss
  real(kind=KR), allocatable, dimension(:,:,:,:)       :: usp

  rhor(:)=0.0_KR
  rhoi(:)=0.0_KR
  j1pr(:)=0.0_KR
  j1pi(:)=0.0_KR
  j2pr(:)=0.0_KR
  j2pi(:)=0.0_KR
  j3pr(:)=0.0_KR
  j3pi(:)=0.0_KR

  ishift=nx*ny*nz

  jcsrx = jc
!     Added above line and removed loops over jcsrx to eliminate
!     multiplications by zero.  --A. Bryant (6/27/02)

!     IF((jd.eq.jdsrc).and.(jd.eq.1.or.jd.eq.2)) THEN
   IF(jd.eq.1.or.jd.eq.2) THEN
	      if(jri.eq.1) then
	       do itt=1,nt
		 do isp=1,nx*ny*nz
		   ind1=isp+(itt-1)*nx*ny*nz
		   ind2=ind1+ishift
		   if(itt.eq.nt) ind2=isp
		     rhor(ind1)=rhor(ind1)&
			       +2.*s(ind2)*usp(ind1,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		     rhoi(ind1)=rhoi(ind1)&
			       +2.*s(ind2)*usp(ind1,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		 enddo ! isp
	       enddo ! itt
	      else
	       do itt=1,nt
		 do isp=1,nx*ny*nz
		   ind1=isp+(itt-1)*nx*ny*nz
		   ind2=ind1+ishift
		   if(itt.eq.nt) ind2=isp
		     rhor(ind1)=rhor(ind1)&
			       -2.*s(ind2)*usp(ind1,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		     rhoi(ind1)=rhoi(ind1)&
			       +2.*s(ind2)*usp(ind1,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		 enddo ! isp
	       enddo ! itt
	      endif
!     ELSE IF((jd.eq.jdsrc).and.(jd.eq.3.or.jd.eq.4)) THEN
  ELSE IF(jd.eq.3.or.jd.eq.4) THEN
	      if(jri.eq.1) then
	       do itt=1,nt
		 do isp=1,nxyz
		   ind1=isp+(itt-1)*nx*ny*nz
		   ind2=ind1+ishift
		   if(itt.eq.nt) ind2=isp
		     rhor(ind1)=rhor(ind1)&
			       -2.*s(ind1)*usp(ind1,1,jc,jcsrx)*z2(ind2,jcsrx,jd)
		     rhoi(ind1)=rhoi(ind1)&
			       +2.*s(ind1)*usp(ind1,2,jc,jcsrx)*z2(ind2,jcsrx,jd)
		 enddo ! isp
	       enddo ! itt
	      else
	       do itt=1,nt
		 do isp=1,nxyz
		   ind1=isp+(itt-1)*nx*ny*nz
		   ind2=ind1+ishift
		   if(itt.eq.nt) ind2=isp
		     rhor(ind1)=rhor(ind1)&
			       -2.*s(ind1)*usp(ind1,2,jc,jcsrx)*z2(ind2,jcsrx,jd)
		     rhoi(ind1)=rhoi(ind1)&
			       -2.*s(ind1)*usp(ind1,1,jc,jcsrx)*z2(ind2,jcsrx,jd)
		 enddo ! isp
	       enddo ! itt
	      endif
  ENDIF
!
! Calculate point-split J_1 (1-direction)
! Diagonal part
  if(jri.eq.1) then
		do ist=1,nt*nz*ny
		  do ix=1,nx
		    ind1=ix+(ist-1)*nx
		    ind2=ind1+1
		    if(ix.eq.nx) ind2=ind2-nx
		      j1pr(ind1)=j1pr(ind1)&
				-s(ind1)*uss(ind1,1,1,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				+s(ind2)*uss(ind1,1,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		      j1pi(ind1)=j1pi(ind1)&
				+s(ind1)*uss(ind1,1,2,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				+s(ind2)*uss(ind1,1,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		  enddo ! ix
		enddo ! ist
	       else if(jri.eq.2) then
		do ist=1,nt*nz*ny
		  do ix=1,nx
		    ind1=ix+(ist-1)*nx
		    ind2=ind1+1
		    if(ix.eq.nx) ind2=ind2-nx
		      j1pr(ind1)=j1pr(ind1)&
				-s(ind1)*uss(ind1,1,2,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				-s(ind2)*uss(ind1,1,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		      j1pi(ind1)=j1pi(ind1)&
				-s(ind1)*uss(ind1,1,1,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				+s(ind2)*uss(ind1,1,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		  enddo ! ix
		enddo ! ist
	       endif
! Off-diagonal part
  if(jri.eq.1) then
		do ist=1,nt*nz*ny
		  do ix=1,nx
		    ind1=ix+(ist-1)*nx
		    ind2=ind1+1
		    if(ix.eq.nx) ind2=ind2-nx
		      j1pr(ind1)=j1pr(ind1)&
				+s(ind1)*uss(ind1,1,1,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				+s(ind2)*uss(ind1,1,1,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		      j1pi(ind1)=j1pi(ind1)&
				-s(ind1)*uss(ind1,1,2,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				+s(ind2)*uss(ind1,1,2,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		  enddo ! ix
		enddo ! ist
	       else if(jri.eq.2) then
		do ist=1,nt*nz*ny
		  do ix=1,nx
		    ind1=ix+(ist-1)*nx
		    ind2=ind1+1
		    if(ix.eq.nx) ind2=ind2-nx
		      j1pr(ind1)=j1pr(ind1)&
				+s(ind1)*uss(ind1,1,2,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				-s(ind2)*uss(ind1,1,2,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		      j1pi(ind1)=j1pi(ind1)&
				+s(ind1)*uss(ind1,1,1,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				+s(ind2)*uss(ind1,1,1,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		  enddo ! ix
		enddo ! ist
  endif
!
! Calculate point-split J_2 (2-direction)
! Diagonal part
  if(jri.eq.1) then
		do ist=1,nt*nz
		  do iy=1,nx*ny
		    ind1=iy+(ist-1)*nx*ny
		    ind2=ind1+nx
		    if(iy+nx.gt.nx*ny) ind2=ind2-nx*ny
		      j2pr(ind1)=j2pr(ind1)&
				-s(ind1)*uss(ind1,2,1,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				+s(ind2)*uss(ind1,2,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		      j2pi(ind1)=j2pi(ind1)&
				+s(ind1)*uss(ind1,2,2,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				+s(ind2)*uss(ind1,2,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		  enddo ! iy
		enddo ! ist
	       else if(jri.eq.2) then
		do ist=1,nt*nz
		  do iy=1,nx*ny
		    ind1=iy+(ist-1)*nx*ny
		    ind2=ind1+nx
		    if(iy+nx.gt.nx*ny) ind2=ind2-nx*ny
		      j2pr(ind1)=j2pr(ind1)&
				-s(ind1)*uss(ind1,2,2,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				-s(ind2)*uss(ind1,2,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		      j2pi(ind1)=j2pi(ind1)&
				-s(ind1)*uss(ind1,2,1,jc,jcsrx)*z2(ind2,jcsrx,jd)&
				+s(ind2)*uss(ind1,2,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		  enddo ! iy
		enddo ! ist
	       endif
! Off-diagonal part
  if(mod(jd,2).eq.1) then
		if(jri.eq.1) then
		do ist=1,nt*nz
		  do iy=1,nx*ny
		     ind1=iy+(ist-1)*nx*ny
		     ind2=ind1+nx
		     if(iy+nx.gt.nx*ny) ind2=ind2-nx*ny
		       j2pr(ind1)=j2pr(ind1)&
				 +s(ind1)*uss(ind1,2,2,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 -s(ind2)*uss(ind1,2,2,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		       j2pi(ind1)=j2pi(ind1)&
				 +s(ind1)*uss(ind1,2,1,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 +s(ind2)*uss(ind1,2,1,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		  enddo ! iy
		enddo ! ist
		else if(jri.eq.2) then
		do ist=1,nt*nz
		  do iy=1,nx*ny
		     ind1=iy+(ist-1)*nx*ny
		     ind2=ind1+nx
		     if(iy+nx.gt.nx*ny) ind2=ind2-nx*ny
		       j2pr(ind1)=j2pr(ind1)&
				 -s(ind1)*uss(ind1,2,1,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 -s(ind2)*uss(ind1,2,1,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		       j2pi(ind1)=j2pi(ind1)&
				 +s(ind1)*uss(ind1,2,2,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 -s(ind2)*uss(ind1,2,2,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		  enddo ! iy
		enddo ! ist
		endif
	       endif
	       if(mod(jd,2).eq.0) then
		if(jri.eq.1) then
		do ist=1,nt*nz
		  do iy=1,nx*ny
		     ind1=iy+(ist-1)*nx*ny
		     ind2=ind1+nx
		     if(iy+nx.gt.nx*ny) ind2=ind2-nx*ny
		       j2pr(ind1)=j2pr(ind1)&
				 -s(ind1)*uss(ind1,2,2,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 +s(ind2)*uss(ind1,2,2,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		       j2pi(ind1)=j2pi(ind1)&
				 -s(ind1)*uss(ind1,2,1,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 -s(ind2)*uss(ind1,2,1,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		  enddo ! iy
		enddo ! ist
		else if(jri.eq.2) then
		do ist=1,nt*nz
		  do iy=1,nx*ny
		     ind1=iy+(ist-1)*nx*ny
		     ind2=ind1+nx
		     if(iy+nx.gt.nx*ny) ind2=ind2-nx*ny
		       j2pr(ind1)=j2pr(ind1)&
				 +s(ind1)*uss(ind1,2,1,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 +s(ind2)*uss(ind1,2,1,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		       j2pi(ind1)=j2pi(ind1)&
				 -s(ind1)*uss(ind1,2,2,jc,jcsrx)*z2(ind2,jcsrx,5-jd)&
				 +s(ind2)*uss(ind1,2,2,jcsrx,jc)*z2(ind1,jcsrx,5-jd)
		  enddo ! iy
		enddo ! ist
		endif
  endif
!
! Calculate point-split J_3 (3-direction)
! Diagonal part
  IF(jri.eq.1) THEN
	       do ist=1,nt
		 do iz=1,nx*ny*nz
		   ind1=iz+(ist-1)*nx*ny*nz
		   ind2=ind1+nx*ny
		   if(iz+nx*ny.gt.nx*ny*nz) ind2=ind2-nx*ny*nz
		     j3pr(ind1)=j3pr(ind1)&
			       -s(ind1)*uss(ind1,3,1,jc,jcsrx)*z2(ind2,jcsrx,jd)&
			       +s(ind2)*uss(ind1,3,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		     j3pi(ind1)=j3pi(ind1)&
			       +s(ind1)*uss(ind1,3,2,jc,jcsrx)*z2(ind2,jcsrx,jd)&
			       +s(ind2)*uss(ind1,3,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		 enddo ! iz
	       enddo ! ist 
	      ELSE IF(jri.eq.2) THEN
	       do ist=1,nt
		 do iz=1,nx*ny*nz
		   ind1=iz+(ist-1)*nx*ny*nz
		   ind2=ind1+nx*ny
		   if(iz+nx*ny.gt.nx*ny*nz) ind2=ind2-nx*ny*nz
		     j3pr(ind1)=j3pr(ind1)&
			       -s(ind1)*uss(ind1,3,2,jc,jcsrx)*z2(ind2,jcsrx,jd)&
			       -s(ind2)*uss(ind1,3,2,jcsrx,jc)*z2(ind1,jcsrx,jd)
		     j3pi(ind1)=j3pi(ind1)&
			       -s(ind1)*uss(ind1,3,1,jc,jcsrx)*z2(ind2,jcsrx,jd)&
			       +s(ind2)*uss(ind1,3,1,jcsrx,jc)*z2(ind1,jcsrx,jd)
		 enddo ! iz
	       enddo ! ist 
	      ENDIF
! Off-diagonal part
  IF((mod(jd,2).eq.1).and.(jri.eq.1)) THEN
	       do ist=1,nt
		 do iz=1,nx*ny*nz
		   ind1=iz+(ist-1)*nx*ny*nz
		   ind2=ind1+nx*ny
		   if(iz+nx*ny.gt.nx*ny*nz) ind2=ind2-nx*ny*nz
		     j3pr(ind1)=j3pr(ind1)&
			       +s(ind1)*uss(ind1,3,1,jc,jcsrx)*z2(ind2,jcsrx,3/jd)&
			       +s(ind2)*uss(ind1,3,1,jcsrx,jc)*z2(ind1,jcsrx,3/jd)
		     j3pi(ind1)=j3pi(ind1)&
			       -s(ind1)*uss(ind1,3,2,jc,jcsrx)*z2(ind2,jcsrx,3/jd)&
			       +s(ind2)*uss(ind1,3,2,jcsrx,jc)*z2(ind1,jcsrx,3/jd)
		 enddo ! iz
	       enddo ! ist 
  ELSE IF((mod(jd,2).eq.1).and.(jri.eq.2)) THEN
	       do ist=1,nt
		 do iz=1,nx*ny*nz
		   ind1=iz+(ist-1)*nx*ny*nz
		   ind2=ind1+nx*ny
		   if(iz+nx*ny.gt.nx*ny*nz) ind2=ind2-nx*ny*nz
		     j3pr(ind1)=j3pr(ind1)&
			       +s(ind1)*uss(ind1,3,2,jc,jcsrx)*z2(ind2,jcsrx,3/jd)&
			       -s(ind2)*uss(ind1,3,2,jcsrx,jc)*z2(ind1,jcsrx,3/jd)
		     j3pi(ind1)=j3pi(ind1)&
			       +s(ind1)*uss(ind1,3,1,jc,jcsrx)*z2(ind2,jcsrx,3/jd)&
			       +s(ind2)*uss(ind1,3,1,jcsrx,jc)*z2(ind1,jcsrx,3/jd)
		 enddo ! iz
	       enddo ! ist 
  ENDIF
  IF((mod(jd,2).eq.0).and.(jri.eq.1)) THEN
	       do ist=1,nt
		 do iz=1,nx*ny*nz
		   ind1=iz+(ist-1)*nx*ny*nz
		   ind2=ind1+nx*ny
		   if(iz+nx*ny.gt.nx*ny*nz) ind2=ind2-nx*ny*nz
		     j3pr(ind1)=j3pr(ind1)&
			       -s(ind1)*uss(ind1,3,1,jc,jcsrx)*z2(ind2,jcsrx,8/jd)&
			       -s(ind2)*uss(ind1,3,1,jcsrx,jc)*z2(ind1,jcsrx,8/jd)
		     j3pi(ind1)=j3pi(ind1)&
			       +s(ind1)*uss(ind1,3,2,jc,jcsrx)*z2(ind2,jcsrx,8/jd)&
			       -s(ind2)*uss(ind1,3,2,jcsrx,jc)*z2(ind1,jcsrx,8/jd)
		 enddo ! iz
	       enddo ! ist 
  ELSE IF((mod(jd,2).eq.0).and.(jri.eq.2)) THEN
	       do ist=1,nt
		 do iz=1,nx*ny*nz
		   ind1=iz+(ist-1)*nx*ny*nz
		   ind2=ind1+nx*ny
		   if(iz+nx*ny.gt.nx*ny*nz) ind2=ind2-nx*ny*nz
		     j3pr(ind1)=j3pr(ind1)&
			       -s(ind1)*uss(ind1,3,2,jc,jcsrx)*z2(ind2,jcsrx,8/jd)&
			       +s(ind2)*uss(ind1,3,2,jcsrx,jc)*z2(ind1,jcsrx,8/jd)
		     j3pi(ind1)=j3pi(ind1)&
			       -s(ind1)*uss(ind1,3,1,jc,jcsrx)*z2(ind2,jcsrx,8/jd)&
			       -s(ind2)*uss(ind1,3,1,jcsrx,jc)*z2(ind1,jcsrx,8/jd)
		 enddo ! iz
	       enddo ! ist 
  ENDIF
	!
  RETURN
  END Subroutine Calc1

!***********************************************************************

 Subroutine scalarCalc(scalar,idirac,icolor,jri,ahere,signal,myid)
 
 use operator

 integer(kind=KI), intent(in)                             :: idirac,icolor,jri,ahere, &
                                                             signal, myid
 real(kind=KR),    intent(in), dimension(nxyzt)           :: scalar

! If signal==1 then calculate the scalar else if signal==2
! then calculate the pseudoscalar.

! if (z2(ahere,icolor,idirac)/=0.0_KR) then

! Calculate psibar-psi: scalar
      if (signal==1) then
          psir(ahere) = 0.0_KR
          psii(ahere) = 0.0_KR
          if (jri.eq.1) then
           !  if (myid==0) print "(a17,i5,2i3,2es17.10)","printing stuff::", ahere, icolor,idirac, scalar(ahere), z2(ahere,icolor,idirac)
              psir(ahere)=psir(ahere) + scalar(ahere)*z2(ahere,icolor,idirac)
          else
              psii(ahere)=psii(ahere) + scalar(ahere)*z2(ahere,icolor,idirac)
          end if ! jri

! Calculate psibar*gamma5*psi: pseudo-scalar
      else if(signal==2) then
          psur(ahere) = 0.0_KR
          psui(ahere) = 0.0_KR
          if (jri.eq.1) then
              psur(ahere)=psur(ahere) + scalar(ahere)*z2(ahere,icolor,idirac)
          else
              psui(ahere)=psui(ahere) + scalar(ahere)*z2(ahere,icolor,idirac)
          end if ! jri
       
      endif ! signal 
! endif ! z2

 return
 end Subroutine scalarCalc

!***********************************************************************


  Subroutine gammaCurrentCalcX(s,jd,icolor,jc,jri,ahere,&
   	                      leftx,rightx,lefty,righty,&
                              leftz,rightz,leftt,rightt,ittt, &
                              usp,uss,fixbc,myid)


  use operator
! use gaugelinks

  real(kind=KR),    intent(in),  dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)             :: uss
  integer(kind=KI), intent(in)                                    :: jd,jc,jri,icolor
  integer(kind=KI), intent(in)                                    :: ahere,leftx,rightx,&
								     lefty,righty,leftz,rightz,&
								     leftt,rightt,ittt
  logical,          intent(in)                                    :: fixbc
  integer(kind=KI), intent(in)                                    :: myid
  real(kind=KR), intent(inout), dimension(nxyzt)                  :: s
  integer(kind=KI)  :: ierr

! Impose periodic boundary conditions

  rhor(ahere)=0.0_KR
  rhor(leftt)=0.0_KR
  rhoi(ahere)=0.0_KR
  rhoi(leftt)=0.0_KR
  j1pr(ahere)=0.0_KR
  j1pr(leftx)=0.0_KR
  j1pi(ahere)=0.0_KR
  j1pi(leftx)=0.0_KR
  j2pr(ahere)=0.0_KR
  j2pr(lefty)=0.0_KR
  j2pi(ahere)=0.0_KR
  j2pi(lefty)=0.0_KR
  j3pr(ahere)=0.0_KR
  j3pr(leftz)=0.0_KR
  j3pi(ahere)=0.0_KR
  j3pi(leftz)=0.0_KR


!     Calculate point-split J_4 (4-direction)

! Dr Wilcox/Dean: Reminder that the color order for the index
!                 ahere was (icolor,jc) and the Hermitian
!                 order for U-dagger is (jc,icolor)!

! NOTE: This subroutine, gammaCurrentCalc uses a different 
!       representation for the off-diagonal elements of the 
!       operators. The other representation is found in
!       subroutine CurrentCalc. 

! This rouinte calculates the operators using the propagator
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! Note that there was an overall sign difference between the charge
! density as calculated here and currentCalc2. Changing the sign
! here. -WW
 
! Now appears that this sign change is not consistent with the
! rest of the operators in here. The rest have an overall minus
! wrt the charge density part. -WW

! It now looks very much like Dean mixed up the U-mu and U-mudagger
! terms below.

  if (.not.fixbc) then
      IF (jd.eq.1 .or. jd.eq.2) THEN
          if (jri.eq.1) then
              rhor(leftt)=rhor(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,icolor,jc)*z2(ahere,icolor,jd)
	      rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,2,icolor,jc)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(leftt)=rhor(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,2,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,icolor,jc)*z2(ahere,icolor,jd)
          end if
      ELSE IF(jd.eq.3 .or. jd.eq.4) THEN
          if (jri.eq.1) then
              rhor(ahere)=rhor(ahere)&
	     -2.0_KR*s(rightt)*usp(ahere,1,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,2,jc,icolor)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(ahere)=rhor(ahere)&
	     -2.0_KR*s(rightt)*usp(ahere,2,jc,icolor)*z2(ahere,icolor,jd)
	      rhoi(ahere)=rhoi(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,1,jc,icolor)*z2(ahere,icolor,jd)
          end if
      END IF
  else ! fixbc

        IF ((jd.eq.1 .or. jd.eq.2).and.ittt/=1) THEN
          if (jri.eq.1) then
              rhor(leftt)=rhor(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,2,icolor,jc)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(leftt)=rhor(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,2,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,icolor,jc)*z2(ahere,icolor,jd)
          end if
       ELSE IF((jd.eq.3 .or. jd.eq.4).and.ittt/=nt) THEN
          if (jri.eq.1) then
              rhor(ahere)=rhor(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,1,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,2,jc,icolor)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(ahere)=rhor(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,2,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,1,jc,icolor)*z2(ahere,icolor,jd)
          end if
      END IF
 endif ! fixbc

!     Calculate point-split J_1 (1-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j1pr(ahere)=j1pr(ahere)&
     +s(rightx)*uss(ahere,1,1,jc,icolor)*z2(ahere,icolor,jd)

      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,1,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
     -s(rightx)*uss(ahere,1,2,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,2,icolor,jc)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j1pr(ahere)=j1pr(ahere)&
! Look!!
     +s(rightx)*uss(ahere,1,2,jc,icolor)*z2(ahere,icolor,jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,2,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
! Look!!
     +s(rightx)*uss(ahere,1,1,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,1,icolor,jc)*z2(ahere,icolor,jd)
  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j1pr(ahere)=j1pr(ahere)&
     -s(rightx)*uss(ahere,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

  else if(jri.eq.2) then
      j1pr(ahere)=j1pr(ahere)&
     -s(rightx)*uss(ahere,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     -s(rightx)*uss(ahere,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

  end if ! (jri.eq.1)

!     Calculate point-split J_2 (2-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j2pr(ahere)=j2pr(ahere)&
     +s(righty)*uss(ahere,2,1,jc,icolor)*z2(ahere,icolor,jd)

      j2pr(lefty)=j2pr(lefty)&
     -s(lefty)*uss(lefty,2,1,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     -s(righty)*uss(ahere,2,2,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     -s(lefty)*uss(lefty,2,2,icolor,jc)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j2pr(ahere)=j2pr(ahere)&
     +s(righty)*uss(ahere,2,2,jc,icolor)*z2(ahere,icolor,jd)

      j2pr(lefty)=j2pr(lefty)&
     +s(lefty)*uss(lefty,2,2,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     +s(righty)*uss(ahere,2,1,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     -s(lefty)*uss(lefty,2,1,icolor,jc)*z2(ahere,icolor,jd)

  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  IF (mod(jd,2).eq.1) THEN 
      if (jri.eq.1) then
          j2pr(ahere)=j2pr(ahere)&
         -s(righty)*uss(ahere,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(lefty)=j2pr(lefty)&
	 +s(lefty)*uss(lefty,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         -s(righty)*uss(ahere,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 -s(lefty)*uss(lefty,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
          j2pr(ahere)=j2pr(ahere)&
	 +s(righty)*uss(ahere,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(lefty)=j2pr(lefty)&
	 +s(lefty)*uss(lefty,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

	  j2pi(ahere)=j2pi(ahere)&
	 -s(righty)*uss(ahere,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 +s(lefty)*uss(lefty,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
      if (jri.eq.1) then
          j2pr(ahere)=j2pr(ahere)&
	 +s(righty)*uss(ahere,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(lefty)=j2pr(lefty)&
	 -s(lefty)*uss(lefty,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

	  j2pi(ahere)=j2pi(ahere)&
	 +s(righty)*uss(ahere,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 +s(lefty)*uss(lefty,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
	  j2pr(ahere)=j2pr(ahere)&
	 -s(righty)*uss(ahere,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(lefty)=j2pr(lefty)&
	 -s(lefty)*uss(lefty,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

	  j2pi(ahere)=j2pi(ahere)&
	 +s(righty)*uss(ahere,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 -s(lefty)*uss(lefty,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)

  END IF

!     Calculate point-split J_3 (3-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j3pr(ahere)=j3pr(ahere)&
     +s(rightz)*uss(ahere,3,1,jc,icolor)*z2(ahere,icolor,jd)

      j3pr(leftz)=j3pr(leftz)&
     -s(leftz)*uss(leftz,3,1,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere)&
     -s(rightz)*uss(ahere,3,2,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz)&
     -s(leftz)*uss(leftz,3,2,icolor,jc)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j3pr(ahere)=j3pr(ahere)&
     +s(rightz)*uss(ahere,3,2,jc,icolor)*z2(ahere,icolor,jd)
	 
      j3pr(leftz)=j3pr(leftz)&
     +s(leftz)*uss(leftz,3,2,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere)&
     +s(rightz)*uss(ahere,3,1,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz) &
     -s(leftz)*uss(leftz,3,1,icolor,jc)*z2(ahere,icolor,jd)
	 
  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  IF (mod(jd,2).eq.1) THEN
      if (jri.eq.1) then
          j3pr(ahere)=j3pr(ahere)&
	 -s(rightz)*uss(ahere,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

	  j3pr(leftz)=j3pr(leftz)&
	 -s(leftz)*uss(leftz,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

	  j3pi(ahere)=j3pi(ahere)&
	 +s(rightz)*uss(ahere,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

	  j3pi(leftz)=j3pi(leftz)&
	 -s(leftz)*uss(leftz,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

      else if(jri.eq.2) then
          j3pr(ahere)=j3pr(ahere)&
	 -s(rightz)*uss(ahere,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

	  j3pr(leftz)=j3pr(leftz)&
	 +s(leftz)*uss(leftz,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

	  j3pi(ahere)=j3pi(ahere)&
         -s(rightz)*uss(ahere,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

	  j3pi(leftz)=j3pi(leftz)&
	 -s(leftz)*uss(leftz,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
      if (jri.eq.1) then
          j3pr(ahere)=j3pr(ahere)&
	 +s(rightz)*uss(ahere,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

	  j3pr(leftz)=j3pr(leftz)&
	 +s(leftz)*uss(leftz,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

	  j3pi(ahere)=j3pi(ahere)&
	 -s(rightz)*uss(ahere,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

	  j3pi(leftz)=j3pi(leftz)&
	 +s(leftz)*uss(leftz,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

      else if(jri.eq.2) then
          j3pr(ahere)=j3pr(ahere)&
	 +s(rightz)*uss(ahere,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

	  j3pr(leftz)=j3pr(leftz)&
	 -s(leftz)*uss(leftz,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

	  j3pi(ahere)=j3pi(ahere)&
	 +s(rightz)*uss(ahere,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

	  j3pi(leftz)=j3pi(leftz)&
	 +s(leftz)*uss(leftz,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

      end if ! (jri.eq.1)

  END IF

  Return
  End subroutine gammaCurrentCalcX

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************


  Subroutine gammaCurrentCalc(s,jd,icolor,jc,jri,ahere,&
                              leftx,rightx,lefty,righty,&
                              leftz,rightz,leftt,rightt,ittt, &
                              usp,uss,fixbc,ir,myid)


  use operator
! use gaugelinks

  real(kind=KR),    intent(in),  dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)             :: uss
  integer(kind=KI), intent(in)                                    :: jd,jc,jri,icolor
  integer(kind=KI), intent(in)                                    :: ahere,leftx,rightx,&
                                                                     lefty,righty,leftz,rightz,&
                                                                     leftt,rightt,ittt,ir
  logical,          intent(in)                                    :: fixbc
  integer(kind=KI), intent(in)                                    :: myid
  real(kind=KR), intent(inout), dimension(nxyzt)                  :: s

  if(ir.eq.1) then 

      call gammaCurrentCalcP(s,jd,icolor,jc,jri,ahere,&
                              leftx,rightx,lefty,righty,&
                              leftz,rightz,leftt,rightt,ittt, &
                              usp,uss,fixbc,myid)
  endif

  if(ir.eq.-1) then 

     call gammaCurrentCalcM(s,jd,icolor,jc,jri,ahere,&
                              leftx,rightx,lefty,righty,&
                              leftz,rightz,leftt,rightt,ittt, &
                              usp,uss,fixbc,myid)
  endif
  
  End subroutine gammaCurrentCalc

!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************


  Subroutine gammaCurrentCalcP(s,jd,icolor,jc,jri,ahere,&
                              leftx,rightx,lefty,righty,&
                              leftz,rightz,leftt,rightt,ittt, &
                              usp,uss,fixbc,myid)


  use operator
! use gaugelinks

  real(kind=KR),    intent(in),  dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)             :: uss
  integer(kind=KI), intent(in)                                    :: jd,jc,jri,icolor
  integer(kind=KI), intent(in)                                    :: ahere,leftx,rightx,&
                                                                     lefty,righty,leftz,rightz,&
                                                                     leftt,rightt,ittt
  logical,          intent(in)                                    :: fixbc
  integer(kind=KI), intent(in)                                    :: myid
  real(kind=KR), intent(inout), dimension(nxyzt)                  :: s
  integer(kind=KI)  :: ierr

! Impose periodic boundary conditions

  rhor(ahere)=0.0_KR
  rhor(leftt)=0.0_KR
  rhoi(ahere)=0.0_KR
  rhoi(leftt)=0.0_KR
  j1pr(ahere)=0.0_KR
  j1pr(leftx)=0.0_KR
  j1pi(ahere)=0.0_KR
  j1pi(leftx)=0.0_KR
  j2pr(ahere)=0.0_KR
  j2pr(lefty)=0.0_KR
  j2pi(ahere)=0.0_KR
  j2pi(lefty)=0.0_KR
  j3pr(ahere)=0.0_KR
  j3pr(leftz)=0.0_KR
  j3pi(ahere)=0.0_KR
  j3pi(leftz)=0.0_KR


!     Calculate point-split J_4 (4-direction)

! This rouinte calculates the operators using the propagator
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! I'm starting over from the old gammaCurrentCalc, which is renamed
! to gammaCurrentCalcX. -WW

! I made 3 changes to the old version to get the new:
! 1. On all sections, usp,uss(icolor,jc) --> usp,uss(jc,icolor)
! 2. On rho section, usp(2) --> -usp(2) (imag. part)
! 3. On all others, uss(1) --> -uss(1) (real part)


  if (.not.fixbc) then
      IF (jd.eq.1 .or. jd.eq.2) THEN
          if (jri.eq.1) then
              rhor(leftt)=rhor(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(leftt)=rhor(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
          end if
      ELSE IF(jd.eq.3 .or. jd.eq.4) THEN
          if (jri.eq.1) then
              rhor(ahere)=rhor(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(ahere)=rhor(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
          end if
      END IF
  else ! fixbc

        IF ((jd.eq.1 .or. jd.eq.2).and.ittt/=1) THEN
          if (jri.eq.1) then
              rhor(leftt)=rhor(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(leftt)=rhor(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
          end if
       ELSE IF((jd.eq.3 .or. jd.eq.4).and.ittt/=nt) THEN
          if (jri.eq.1) then
              rhor(ahere)=rhor(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(ahere)=rhor(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
          end if
      END IF
 endif ! fixbc

!     Calculate point-split J_1 (1-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j1pr(ahere)=j1pr(ahere)&
     -s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
     -s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j1pr(ahere)=j1pr(ahere)&
! Look!!
     +s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
! Look!!
     -s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     +s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,jd)
  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j1pr(ahere)=j1pr(ahere)&
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

  else if(jri.eq.2) then
      j1pr(ahere)=j1pr(ahere)&
     -s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     +s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

  end if ! (jri.eq.1)

!     Calculate point-split J_2 (2-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j2pr(ahere)=j2pr(ahere)&
     -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,jd)

      j2pr(lefty)=j2pr(lefty)&
     +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j2pr(ahere)=j2pr(ahere)&
     +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,jd)

      j2pr(lefty)=j2pr(lefty)&
     +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,jd)

  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  IF (mod(jd,2).eq.1) THEN
      if (jri.eq.1) then
          j2pr(ahere)=j2pr(ahere)&
         -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
          j2pr(ahere)=j2pr(ahere)&
         -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
      if (jri.eq.1) then
          j2pr(ahere)=j2pr(ahere)&
         +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
          j2pr(ahere)=j2pr(ahere)&
         +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)

  END IF

!     Calculate point-split J_3 (3-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j3pr(ahere)=j3pr(ahere)&
     -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,jd)

      j3pr(leftz)=j3pr(leftz)&
     +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere)&
     -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz)&
     -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j3pr(ahere)=j3pr(ahere)&
     +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,jd)

      j3pr(leftz)=j3pr(leftz)&
     +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere)&
     -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz) &
     +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,jd)

  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  IF (mod(jd,2).eq.1) THEN
      if (jri.eq.1) then
          j3pr(ahere)=j3pr(ahere)&
         +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pr(leftz)=j3pr(leftz)&
         +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pi(ahere)=j3pi(ahere)&
         +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pi(leftz)=j3pi(leftz)&
         -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

      else if(jri.eq.2) then
          j3pr(ahere)=j3pr(ahere)&
         -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pr(leftz)=j3pr(leftz)&
         +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pi(ahere)=j3pi(ahere)&
         +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pi(leftz)=j3pi(leftz)&
         +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
      if (jri.eq.1) then
          j3pr(ahere)=j3pr(ahere)&
         -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pr(leftz)=j3pr(leftz)&
         -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pi(ahere)=j3pi(ahere)&
         -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pi(leftz)=j3pi(leftz)&
         +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

      else if(jri.eq.2) then
          j3pr(ahere)=j3pr(ahere)&
         +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pr(leftz)=j3pr(leftz)&
         -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pi(ahere)=j3pi(ahere)&
         -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pi(leftz)=j3pi(leftz)&
         -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

      end if ! (jri.eq.1)

  END IF

  Return
  End subroutine gammaCurrentCalcP


!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************
!***********************************************************************


  Subroutine gammaCurrentCalcM(s,jd,icolor,jc,jri,ahere,&
                              leftx,rightx,lefty,righty,&
                              leftz,rightz,leftt,rightt,ittt, &
                              usp,uss,fixbc,myid)


  use operator
! use gaugelinks

  real(kind=KR),    intent(in),  dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)             :: uss
  integer(kind=KI), intent(in)                                    :: jd,jc,jri,icolor
  integer(kind=KI), intent(in)                                    :: ahere,leftx,rightx,&
                                                                     lefty,righty,leftz,rightz,&
                                                                     leftt,rightt,ittt
  logical,          intent(in)                                    :: fixbc
  integer(kind=KI), intent(in)                                    :: myid
  real(kind=KR), intent(inout), dimension(nxyzt)                  :: s
  integer(kind=KI)  :: ierr

! Impose periodic boundary conditions

  rhor(ahere)=0.0_KR
  rhor(leftt)=0.0_KR
  rhoi(ahere)=0.0_KR
  rhoi(leftt)=0.0_KR
  j1pr(ahere)=0.0_KR
  j1pr(leftx)=0.0_KR
  j1pi(ahere)=0.0_KR
  j1pi(leftx)=0.0_KR
  j2pr(ahere)=0.0_KR
  j2pr(lefty)=0.0_KR
  j2pi(ahere)=0.0_KR
  j2pi(lefty)=0.0_KR
  j3pr(ahere)=0.0_KR
  j3pr(leftz)=0.0_KR
  j3pi(ahere)=0.0_KR
  j3pi(leftz)=0.0_KR


!     Calculate point-split J_4 (4-direction)

! This rouinte calculates the operators using the propagator
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! I'm starting over from the old gammaCurrentCalc, which is renamed
! to gammaCurrentCalcX. -WW

! I made 3 changes to the old version to get the new:
! 1. On all sections, usp,uss(icolor,jc) --> usp,uss(jc,icolor)
! 2. On rho section, usp(2) --> -usp(2) (imag. part)
! 3. On all others, uss(1) --> -uss(1) (real part)


  if (.not.fixbc) then
      IF (jd.eq.3 .or. jd.eq.4) THEN
          if (jri.eq.1) then
              rhor(leftt)=rhor(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(leftt)=rhor(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
          end if
      ELSE IF(jd.eq.1 .or. jd.eq.2) THEN
          if (jri.eq.1) then
              rhor(ahere)=rhor(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(ahere)=rhor(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
          end if
      END IF
  else ! fixbc

        IF ((jd.eq.3 .or. jd.eq.4).and.ittt/=1) THEN
          if (jri.eq.1) then
              rhor(leftt)=rhor(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             +2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(leftt)=rhor(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
              rhoi(leftt)=rhoi(leftt)&
             -2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
          end if
       ELSE IF((jd.eq.1 .or. jd.eq.2).and.ittt/=nt) THEN
          if (jri.eq.1) then
              rhor(ahere)=rhor(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
          else if(jri.eq.2) then
              rhor(ahere)=rhor(ahere)&
             -2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
              rhoi(ahere)=rhoi(ahere)&
             +2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
          end if
      END IF
 endif ! fixbc

!     Calculate point-split J_1 (1-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j1pr(ahere)=j1pr(ahere)&
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,jd)

      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     +s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j1pr(ahere)=j1pr(ahere)&
! Look!!
     -s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,jd)

      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
! Look!!
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,jd)
  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j1pr(ahere)=j1pr(ahere)&
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

  else if(jri.eq.2) then
      j1pr(ahere)=j1pr(ahere)&
     -s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pr(leftx)=j1pr(leftx)&
     +s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     +s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

  end if ! (jri.eq.1)

!     Calculate point-split J_2 (2-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j2pr(ahere)=j2pr(ahere)&
     +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,jd)

      j2pr(lefty)=j2pr(lefty)&
     -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j2pr(ahere)=j2pr(ahere)&
     -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,jd)

      j2pr(lefty)=j2pr(lefty)&
     -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,jd)

  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  IF (mod(jd,2).eq.1) THEN
      if (jri.eq.1) then
          j2pr(ahere)=j2pr(ahere)&
         -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
          j2pr(ahere)=j2pr(ahere)&
         -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
      if (jri.eq.1) then
          j2pr(ahere)=j2pr(ahere)&
         +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
          j2pr(ahere)=j2pr(ahere)&
         +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pr(lefty)=j2pr(lefty)&
         +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

          j2pi(ahere)=j2pi(ahere)&
         +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

          j2pi(lefty)=j2pi(lefty)&
         -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)

  END IF

!     Calculate point-split J_3 (3-direction)
!     Diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  if (jri.eq.1) then
      j3pr(ahere)=j3pr(ahere)&
     +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,jd)

      j3pr(leftz)=j3pr(leftz)&
     -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere)&
     +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz)&
     +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j3pr(ahere)=j3pr(ahere)&
     -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,jd)

      j3pr(leftz)=j3pr(leftz)&
     -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere)&
     +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz) &
     -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,jd)

  end if ! (jri.eq.1)

!     Off-diagonal part
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

  IF (mod(jd,2).eq.1) THEN
      if (jri.eq.1) then
          j3pr(ahere)=j3pr(ahere)&
         +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pr(leftz)=j3pr(leftz)&
         +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pi(ahere)=j3pi(ahere)&
         +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pi(leftz)=j3pi(leftz)&
         -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

      else if(jri.eq.2) then
          j3pr(ahere)=j3pr(ahere)&
         -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pr(leftz)=j3pr(leftz)&
         +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pi(ahere)=j3pi(ahere)&
         +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pi(leftz)=j3pi(leftz)&
         +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
      if (jri.eq.1) then
          j3pr(ahere)=j3pr(ahere)&
         -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pr(leftz)=j3pr(leftz)&
         -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pi(ahere)=j3pi(ahere)&
         -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pi(leftz)=j3pi(leftz)&
         +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

      else if(jri.eq.2) then
          j3pr(ahere)=j3pr(ahere)&
         +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pr(leftz)=j3pr(leftz)&
         -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pi(ahere)=j3pi(ahere)&
         -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pi(leftz)=j3pi(leftz)&
         -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

      end if ! (jri.eq.1)

  END IF

  Return
  End subroutine gammaCurrentCalcM


!___-.___1____-____2____-____3____-____4____-____5____-____6____-____7xx
!***********************************************************************

  Subroutine currentCalc(s,jd,icolor,jc,jri,ahere,&
        	         leftx,rightx,lefty,righty,leftz,&
                         rightz,leftt,rightt,usp,uss,myid)


  use operator
! use gaugelinks

  real(kind=KR),    intent(in),  dimension(:,:,:,:)               :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)             :: uss
  integer(kind=KI), intent(in)                                    :: jd,jc,jri,icolor
  integer(kind=KI), intent(in)                                    :: ahere,leftx,rightx,&
							             lefty,righty,leftz,rightz,&
							             leftt,rightt
  integer(kind=KI), intent(in)                                    :: myid
  real(kind=KR), intent(inout), dimension(nxyzt)                  :: s
  integer(kind=KI)  :: ierr
!     Impose periodic boundary conditions

  rhor(ahere)=0.0_KR
  rhor(leftt)=0.0_KR
  rhoi(ahere)=0.0_KR
  rhoi(leftt)=0.0_KR
  j1pr(ahere)=0.0_KR
  j1pr(leftx)=0.0_KR
  j1pi(ahere)=0.0_KR
  j1pi(leftx)=0.0_KR
  j2pr(ahere)=0.0_KR
  j2pr(lefty)=0.0_KR
  j2pi(ahere)=0.0_KR
  j2pi(lefty)=0.0_KR
  j3pr(ahere)=0.0_KR
  j3pr(leftz)=0.0_KR
  j3pi(ahere)=0.0_KR
  j3pi(leftz)=0.0_KR


! Dr Wilcox/Dean: Reminder that the color order for the index
!                 ahere was (icolor,jc) and the Hermitian
!                 order for U-dagger is (jc,icolor)!

! NOTE: This subroutine, CurrentCalc uses a different 
!       representation for the off-diagonal elements of the 
!       operators. The other representation is found in
!       subroutine gammaCurrentCalc. 

! This rouinte calculates the operators using the propagator
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}


!     Calculate point-split J_4 (4-direction)

! Changes the jd values here...they cause disagreement with the original program....
  IF (jd.eq.1 .or. jd.eq.2) THEN
      if (jri.eq.1) then
	  rhor(ahere)=rhor(ahere)&
	 +2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
	  rhoi(ahere)=rhoi(ahere)&
	 +2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
      else if(jri.eq.2) then
          rhor(ahere)=rhor(ahere)&
	 -2.0_KR*s(rightt)*usp(ahere,2,icolor,jc)*z2(ahere,icolor,jd)
	  rhoi(ahere)=rhoi(ahere)&
	 +2.0_KR*s(rightt)*usp(ahere,1,icolor,jc)*z2(ahere,icolor,jd)
      end if ! (jri.eq.1)
  ELSE IF(jd.eq.3 .or. jd.eq.4) THEN
      if (jri.eq.1) then
	  rhor(leftt)=rhor(leftt)&
	 -2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
	  rhoi(leftt)=rhoi(leftt)&
	 +2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
      else if(jri.eq.2) then
          rhor(leftt)=rhor(leftt)&
	 -2.0_KR*s(leftt)*usp(leftt,2,jc,icolor)*z2(ahere,icolor,jd)
	  rhoi(leftt)=rhoi(leftt)&
	 -2.0_KR*s(leftt)*usp(leftt,1,jc,icolor)*z2(ahere,icolor,jd)
      end if ! (jri.eq.1)
  END IF

!     Calculate point-split J_1 (1-direction)
!     Diagonal part

  if (jri.eq.1) then
      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,jd)

      j1pr(ahere)=j1pr(ahere)&
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     +s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,jd)

      j1pr(ahere)=j1pr(ahere)&
     -s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,jd)

      j1pi(ahere)=j1pi(ahere)&
     +s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,jd)

  end if ! (jri.eq.1)

!     Off-diagonal part

  if (jri.eq.1) then
      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pr(ahere)=j1pr(ahere)&
     -s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     +s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     -s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

  else if(jri.eq.2) then
      j1pr(leftx)=j1pr(leftx)&
     -s(leftx)*uss(leftx,1,2,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pr(ahere)=j1pr(ahere)&
     +s(rightx)*uss(ahere,1,2,icolor,jc)*z2(ahere,icolor,5-jd)

      j1pi(leftx)=j1pi(leftx)&
     -s(leftx)*uss(leftx,1,1,jc,icolor)*z2(ahere,icolor,5-jd)

      j1pi(ahere)=j1pi(ahere)&
     -s(rightx)*uss(ahere,1,1,icolor,jc)*z2(ahere,icolor,5-jd)

  end if ! (jri.eq.1)

!     Calculate point-split J_2 (2-direction)
!     Diagonal part

  if (jri.eq.1) then
      j2pr(lefty)=j2pr(lefty)&
     -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,jd)

      j2pr(ahere)=j2pr(ahere)&
     +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j2pr(lefty)=j2pr(lefty)&
     -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,jd)

      j2pr(ahere)=j2pr(ahere)&
     -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,jd)

      j2pi(lefty)=j2pi(lefty)&
     -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,jd)

      j2pi(ahere)=j2pi(ahere)&
     +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,jd)

  end if ! (jri.eq.1)

!     Off-diagonal part

  IF (mod(jd,2).eq.1) THEN 
      if (jri.eq.1) then
          j2pr(lefty)=j2pr(lefty)&
	 -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(ahere)=j2pr(ahere)&
	 +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(ahere)=j2pi(ahere)&
	 -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
          j2pr(lefty)=j2pr(lefty)&
	 +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(ahere)=j2pr(ahere)&
	 +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 -s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(ahere)=j2pi(ahere)&
	 +s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
      if (jri.eq.1) then
          j2pr(lefty)=j2pr(lefty)&
	 +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(ahere)=j2pr(ahere)&
	 -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 +s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(ahere)=j2pi(ahere)&
	 +s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

      else if(jri.eq.2) then
          j2pr(lefty)=j2pr(lefty)&
	 -s(lefty)*uss(lefty,2,1,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pr(ahere)=j2pr(ahere)&
	 -s(righty)*uss(ahere,2,1,icolor,jc)*z2(ahere,icolor,5-jd)

	  j2pi(lefty)=j2pi(lefty)&
	 +s(lefty)*uss(lefty,2,2,jc,icolor)*z2(ahere,icolor,5-jd)

	  j2pi(ahere)=j2pi(ahere)&
	 -s(righty)*uss(ahere,2,2,icolor,jc)*z2(ahere,icolor,5-jd)

      end if ! (jri.eq.1)
  END IF

!     Calculate point-split J_3 (3-direction)
!     Diagonal part

  if (jri.eq.1) then
      j3pr(leftz)=j3pr(leftz)&
     -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,jd)

      j3pr(ahere)=j3pr(ahere)&
     +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz)&
     +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere)&
     +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,jd)

  else if(jri.eq.2) then
      j3pr(leftz)=j3pr(leftz)&
     -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,jd)
	 
      j3pr(ahere)=j3pr(ahere)&
     -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,jd)

      j3pi(leftz)=j3pi(leftz)&
     -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,jd)

      j3pi(ahere)=j3pi(ahere) &
     +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,jd)
 
  end if ! (jri.eq.1)

!     Off-diagonal part

  IF (mod(jd,2).eq.1) THEN
      if (jri.eq.1) then
          j3pr(leftz)=j3pr(leftz)&
         -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pr(ahere)=j3pr(ahere)&
         -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pi(leftz)=j3pi(leftz)&
         +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pi(ahere)=j3pi(ahere)&
         -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

      else if(jri.eq.2) then
          j3pr(leftz)=j3pr(leftz)&
         -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pr(ahere)=j3pr(ahere)&
         +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,3/jd)

          j3pi(leftz)=j3pi(leftz)&
         -s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,3/jd)

          j3pi(ahere)=j3pi(ahere)&
         -s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,3/jd)

      end if ! (jri.eq.1)

  ELSE IF(mod(jd,2).eq.0) THEN
      if (jri.eq.1) then
          j3pr(leftz)=j3pr(leftz)&
         +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pr(ahere)=j3pr(ahere)&
         +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pi(leftz)=j3pi(leftz)&
         -s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pi(ahere)=j3pi(ahere)&
         +s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

      else if(jri.eq.2) then
          j3pr(leftz)=j3pr(leftz)&
         +s(leftz)*uss(leftz,3,2,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pr(ahere)=j3pr(ahere)&
         -s(rightz)*uss(ahere,3,2,icolor,jc)*z2(ahere,icolor,8/jd)

          j3pi(leftz)=j3pi(leftz)&
         +s(leftz)*uss(leftz,3,1,jc,icolor)*z2(ahere,icolor,8/jd)

          j3pi(ahere)=j3pi(ahere)&
         +s(rightz)*uss(ahere,3,1,icolor,jc)*z2(ahere,icolor,8/jd)

      end if ! (jri.eq.1)

  END IF

  Return
  End subroutine currentCalc

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  Subroutine currentCalc2(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,ir,myid)

  use operator
! use gaugelinks
          
  real(kind=KR),    intent(in),  dimension(nxyzt,nc,nd)               :: z2input 
  real(kind=KR),    intent(in),  dimension(:,:,:,:)                   :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)                 :: uss
  integer(kind=KI), intent(in)                                        :: jd,jri,icolor,ittt  
  integer(kind=KI), intent(in)                                        :: ahere,leftx,rightx,&
                                                                         lefty,righty,leftz,rightz,&
                                                                         leftt,rightt,ir
  integer(kind=KI), intent(in)                                        :: myid
  character(len=*), intent(in),  dimension(:)                         :: rwdir
  real(kind=KR),    intent(in),  dimension(nxyzt)                     :: s
  

  if(ir.eq.1) call currentCalc2P(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)

  if(ir.eq.-1) call currentCalc2M(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)

  end subroutine currentCalc2

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  Subroutine currentCalc2P(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)

  use operator
! use gaugelinks
          
  real(kind=KR),    intent(in),  dimension(nxyzt,nc,nd)               :: z2input 
  real(kind=KR),    intent(in),  dimension(:,:,:,:)                   :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)                 :: uss
  integer(kind=KI), intent(in)                                        :: jd,jri,icolor,ittt  
  integer(kind=KI), intent(in)                                        :: ahere,leftx,rightx,&
                                                                         lefty,righty,leftz,rightz,&
                                                                         leftt,rightt
  integer(kind=KI), intent(in)                                        :: myid
  character(len=*), intent(in),  dimension(:)                         :: rwdir
  real(kind=KR),    intent(in),  dimension(nxyzt)                     :: s
  integer(kind=KI)                                                    :: jc,ierr

  rhor(ahere)=0.0_KR
  rhor(leftt)=0.0_KR
  rhoi(ahere)=0.0_KR
  rhoi(leftt)=0.0_KR
  j1pr(ahere)=0.0_KR
  j1pr(leftx)=0.0_KR
  j1pi(ahere)=0.0_KR
  j1pi(leftx)=0.0_KR
  j2pr(ahere)=0.0_KR
  j2pr(lefty)=0.0_KR
  j2pi(ahere)=0.0_KR
  j2pi(lefty)=0.0_KR
  j3pr(ahere)=0.0_KR
  j3pr(leftz)=0.0_KR
  j3pi(ahere)=0.0_KR
  j3pi(leftz)=0.0_KR

  
! CONVENTION FOR DIRAC GAMMA MATRICES:
!
!      / 0 0 0 1 \       / 0  0 0 -i \       / 0  0 1  0 \       / 1 0  0  0 \
! gam1=| 0 0 1 0 |, gam2=| 0  0 i  0 |, gam3=| 0  0 0 -1 |, gam4=| 0 1  0  0 |.
!      | 0 1 0 0 |       | 0 -i 0  0 |       | 1  0 0  0 |       | 0 0 -1  0 |
!      \ 1 0 0 0 /       \ i  0 0  0 /       \ 0 -1 0  0 /       \ 0 0  0 -1 /
!
!                                        / 0 0 -i  0 \
! Note that gam5 = gam1*gam2*gam3*gam4 = | 0 0  0 -i |.
!                                        | i 0  0  0 |
!                                        \ 0 i  0  0 /
!

! This rouinte calculates the operators using the propagator
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! I'm starting over again here, just like in gammaCurrentCalc. The
! original currentCalc2 now renamed to currentCalc2X. -WW

  do jc = 1,nc

!     Calculate point-split J_4 (4-direction)
   if (.not. fixbc) then
     IF (jd.eq.1 .or. jd.eq.2) THEN
         if (jri.eq.1) then
                 rhor(ahere)=rhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 rhor(ahere)=rhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF(jd.eq.3 .or. jd.eq.4) THEN
         if (jri.eq.1) then
                 rhor(leftt)=rhor(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 rhoi(leftt)=rhoi(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     rhor(leftt)=rhor(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     rhoi(leftt)=rhoi(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   else ! fixbc

! NOTE: Since the propagator is fixed at "ahere" then the restrictions on the
!       boundry are different than that in gammacurrentcalc.
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     IF ((jd.eq.1 .or. jd.eq.2).and.ittt/=nt) THEN
         if (jri.eq.1) then
                 rhor(ahere)=rhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 rhor(ahere)=rhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF((jd.eq.3 .or. jd.eq.4).and.ittt/=1) THEN
         if (jri.eq.1) then
                 rhor(leftt)=rhor(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 rhoi(leftt)=rhoi(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     rhor(leftt)=rhor(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     rhoi(leftt)=rhoi(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   endif ! fixbc


!     Calculate point-split J_1 (1-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     if (jri.eq.1) then
! U_mu(x) contribution
         j1pr(leftx)=j1pr(leftx)&
        -s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)& !diagonal part
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)!off-diagonal part
 
         j1pi(leftx)=j1pi(leftx)&
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)& !diagonal part
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)!off-diagonal part
 
! U_mudagger(x) contribution
         j1pr(ahere)=j1pr(ahere)&
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)& !diagonal part
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd)!off-diagonal part
 
         j1pi(ahere)=j1pi(ahere)&
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)& !diagonal part
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd)!off-diagonal part
 
     else if(jri.eq.2) then
 
! U_mu(x) contribution
         j1pr(leftx)=j1pr(leftx)&
! Look!!
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal part
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal part
 
         j1pi(leftx)=j1pi(leftx)&
! Look!!
        -s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal part
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal part
  
! U_mudagger(x) contribution
         j1pr(ahere)=j1pr(ahere)&
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal part
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal part
 
         j1pi(ahere)=j1pi(ahere)&
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal part
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal part
 
     end if ! (jri.eq.1)


!     Calculate point-split J_2 (2-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(y) contribution
         j2pr(lefty)=j2pr(lefty)&
        -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

         j2pi(lefty)=j2pi(lefty)&
        -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         j2pr(ahere)=j2pr(ahere)&
        +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

         j2pi(ahere)=j2pi(ahere)&
        -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

     else if(jri.eq.2) then
! U_mu(y) contribution
         j2pr(lefty)=j2pr(lefty)&
        +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

         j2pi(lefty)=j2pi(lefty)&
        -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         j2pr(ahere)=j2pr(ahere)&
        +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

         j2pi(ahere)=j2pi(ahere)&
        +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     END IF

!     Calculate point-split J_3 (3-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(z) contribution
         j3pr(leftz)=j3pr(leftz)&
        -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

         j3pi(leftz)=j3pi(leftz)&
        -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         j3pr(ahere)=j3pr(ahere)&
        +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

         j3pi(ahere)=j3pi(ahere)&
        -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

     else if(jri.eq.2) then
! U_mu(z) contribution
         j3pr(leftz)=j3pr(leftz)&
        +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

         j3pi(leftz)=j3pi(leftz)&
        -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         j3pr(ahere)=j3pr(ahere)&
        +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

         j3pi(ahere)=j3pi(ahere) &
        +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

             j3pi(leftz)=j3pi(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

             j3pi(ahere)=j3pi(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

             j3pi(leftz)=j3pi(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

             j3pi(ahere)=j3pi(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

             j3pi(leftz)=j3pi(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)

             j3pi(ahere)=j3pi(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

             j3pi(leftz)=j3pi(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

             j3pi(ahere)=j3pi(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)
         end if ! (jri.eq.1)

     END IF

  enddo ! jc
  Return
  End subroutine currentCalc2P
!*****************************************************************************
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  Subroutine currentCalc2M(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)

  use operator
! use gaugelinks
          
  real(kind=KR),    intent(in),  dimension(nxyzt,nc,nd)               :: z2input 
  real(kind=KR),    intent(in),  dimension(:,:,:,:)                   :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)                 :: uss
  integer(kind=KI), intent(in)                                        :: jd,jri,icolor,ittt  
  integer(kind=KI), intent(in)                                        :: ahere,leftx,rightx,&
                                                                         lefty,righty,leftz,rightz,&
                                                                         leftt,rightt
  integer(kind=KI), intent(in)                                        :: myid
  character(len=*), intent(in),  dimension(:)                         :: rwdir
  real(kind=KR),    intent(in),  dimension(nxyzt)                     :: s
  integer(kind=KI)                                                    :: jc,ierr

  rhor(ahere)=0.0_KR
  rhor(leftt)=0.0_KR
  rhoi(ahere)=0.0_KR
  rhoi(leftt)=0.0_KR
  j1pr(ahere)=0.0_KR
  j1pr(leftx)=0.0_KR
  j1pi(ahere)=0.0_KR
  j1pi(leftx)=0.0_KR
  j2pr(ahere)=0.0_KR
  j2pr(lefty)=0.0_KR
  j2pi(ahere)=0.0_KR
  j2pi(lefty)=0.0_KR
  j3pr(ahere)=0.0_KR
  j3pr(leftz)=0.0_KR
  j3pi(ahere)=0.0_KR
  j3pi(leftz)=0.0_KR

  
! CONVENTION FOR DIRAC GAMMA MATRICES:
!
!      / 0 0 0 1 \       / 0  0 0 -i \       / 0  0 1  0 \       / 1 0  0  0 \
! gam1=| 0 0 1 0 |, gam2=| 0  0 i  0 |, gam3=| 0  0 0 -1 |, gam4=| 0 1  0  0 |.
!      | 0 1 0 0 |       | 0 -i 0  0 |       | 1  0 0  0 |       | 0 0 -1  0 |
!      \ 1 0 0 0 /       \ i  0 0  0 /       \ 0 -1 0  0 /       \ 0 0  0 -1 /
!
!                                        / 0 0 -i  0 \
! Note that gam5 = gam1*gam2*gam3*gam4 = | 0 0  0 -i |.
!                                        | i 0  0  0 |
!                                        \ 0 i  0  0 /
!

! This rouinte calculates the operators using the propagator
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! I'm starting over again here, just like in gammaCurrentCalc. The
! original currentCalc2 now renamed to currentCalc2X. -WW

  do jc = 1,nc

!     Calculate point-split J_4 (4-direction)
   if (.not. fixbc) then
     IF (jd.eq.3 .or. jd.eq.4) THEN
         if (jri.eq.1) then
                 rhor(ahere)=rhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 rhor(ahere)=rhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF(jd.eq.1 .or. jd.eq.2) THEN
         if (jri.eq.1) then
                 rhor(leftt)=rhor(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 rhoi(leftt)=rhoi(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     rhor(leftt)=rhor(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     rhoi(leftt)=rhoi(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   else ! fixbc

! NOTE: Since the propagator is fixed at "ahere" then the restrictions on the
!       boundry are different than that in gammacurrentcalc.
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     IF ((jd.eq.3 .or. jd.eq.4).and.ittt/=nt) THEN
         if (jri.eq.1) then
                 rhor(ahere)=rhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 rhor(ahere)=rhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF((jd.eq.1 .or. jd.eq.2).and.ittt/=1) THEN
         if (jri.eq.1) then
                 rhor(leftt)=rhor(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 rhoi(leftt)=rhoi(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     rhor(leftt)=rhor(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     rhoi(leftt)=rhoi(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   endif ! fixbc


!     Calculate point-split J_1 (1-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     if (jri.eq.1) then
! U_mu(x) contribution
         j1pr(leftx)=j1pr(leftx)&
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)& !diagonal part
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)!off-diagonal part
 
         j1pi(leftx)=j1pi(leftx)&
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)& !diagonal part
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)!off-diagonal part
 
! U_mudagger(x) contribution
         j1pr(ahere)=j1pr(ahere)&
        -s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)& !diagonal part
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd)!off-diagonal part
 
         j1pi(ahere)=j1pi(ahere)&
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)& !diagonal part
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd)!off-diagonal part
 
     else if(jri.eq.2) then
 
! U_mu(x) contribution
         j1pr(leftx)=j1pr(leftx)&
! Look!!
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal part
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal part
 
         j1pi(leftx)=j1pi(leftx)&
! Look!!
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal part
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal part
  
! U_mudagger(x) contribution
         j1pr(ahere)=j1pr(ahere)&
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal part
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal part
 
         j1pi(ahere)=j1pi(ahere)&
        -s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal part
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal part
 
     end if ! (jri.eq.1)


!     Calculate point-split J_2 (2-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(y) contribution
         j2pr(lefty)=j2pr(lefty)&
        +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

         j2pi(lefty)=j2pi(lefty)&
        +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         j2pr(ahere)=j2pr(ahere)&
        -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

         j2pi(ahere)=j2pi(ahere)&
        +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

     else if(jri.eq.2) then
! U_mu(y) contribution
         j2pr(lefty)=j2pr(lefty)&
        -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

         j2pi(lefty)=j2pi(lefty)&
        +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         j2pr(ahere)=j2pr(ahere)&
        -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

         j2pi(ahere)=j2pi(ahere)&
        -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     END IF

!     Calculate point-split J_3 (3-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(z) contribution
         j3pr(leftz)=j3pr(leftz)&
        +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

         j3pi(leftz)=j3pi(leftz)&
        +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         j3pr(ahere)=j3pr(ahere)&
        -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

         j3pi(ahere)=j3pi(ahere)&
        +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

     else if(jri.eq.2) then
! U_mu(z) contribution
         j3pr(leftz)=j3pr(leftz)&
        -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

         j3pi(leftz)=j3pi(leftz)&
        +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         j3pr(ahere)=j3pr(ahere)&
        -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

         j3pi(ahere)=j3pi(ahere) &
        -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

             j3pi(leftz)=j3pi(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

             j3pi(ahere)=j3pi(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

             j3pi(leftz)=j3pi(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

             j3pi(ahere)=j3pi(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

             j3pi(leftz)=j3pi(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)

             j3pi(ahere)=j3pi(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

             j3pi(leftz)=j3pi(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

             j3pi(ahere)=j3pi(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)
         end if ! (jri.eq.1)

     END IF

  enddo ! jc
  Return
  End subroutine currentCalc2M
!*****************************************************************************

  Subroutine currentCalc2_axial(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,ir,myid)

  use operator
! use gaugelinks
          
  real(kind=KR),    intent(in),  dimension(nxyzt,nc,nd)               :: z2input 
  real(kind=KR),    intent(in),  dimension(:,:,:,:)                   :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)                 :: uss
  integer(kind=KI), intent(in)                                        :: jd,jri,icolor,ittt  
  integer(kind=KI), intent(in)                                        :: ahere,leftx,rightx,&
                                                                         lefty,righty,leftz,rightz,&
                                                                         leftt,rightt,ir
  integer(kind=KI), intent(in)                                        :: myid
  character(len=*), intent(in),  dimension(:)                         :: rwdir
  real(kind=KR),    intent(in),  dimension(nxyzt)                     :: s


  if(ir.eq.1) call currentCalc2_axialP(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)
  
  if(ir.eq.-1) call currentCalc2_axialM(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)


  End subroutine currentCalc2_axial



! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  Subroutine currentCalc2_axialP(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)

  use operator
! use gaugelinks
          
  real(kind=KR),    intent(in),  dimension(nxyzt,nc,nd)               :: z2input 
  real(kind=KR),    intent(in),  dimension(:,:,:,:)                   :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)                 :: uss
  integer(kind=KI), intent(in)                                        :: jd,jri,icolor,ittt  
  integer(kind=KI), intent(in)                                        :: ahere,leftx,rightx,&
                                                                         lefty,righty,leftz,rightz,&
                                                                         leftt,rightt
  integer(kind=KI), intent(in)                                        :: myid
  character(len=*), intent(in),  dimension(:)                         :: rwdir
  real(kind=KR),    intent(in),  dimension(nxyzt)                     :: s
  integer(kind=KI)                                                    :: jc,ierr

  arhor(ahere)=0.0_KR
  arhor(leftt)=0.0_KR
  arhoi(ahere)=0.0_KR
  arhoi(leftt)=0.0_KR
  aj1pr(ahere)=0.0_KR
  aj1pr(leftx)=0.0_KR
  aj1pi(ahere)=0.0_KR
  aj1pi(leftx)=0.0_KR
  aj2pr(ahere)=0.0_KR
  aj2pr(lefty)=0.0_KR
  aj2pi(ahere)=0.0_KR
  aj2pi(lefty)=0.0_KR
  aj3pr(ahere)=0.0_KR
  aj3pr(leftz)=0.0_KR
  aj3pi(ahere)=0.0_KR
  aj3pi(leftz)=0.0_KR

  
! CONVENTION FOR DIRAC GAMMA MATRICES:
!
!      / 0 0 0 1 \       / 0  0 0 -i \       / 0  0 1  0 \       / 1 0  0  0 \
! gam1=| 0 0 1 0 |, gam2=| 0  0 i  0 |, gam3=| 0  0 0 -1 |, gam4=| 0 1  0  0 |.
!      | 0 1 0 0 |       | 0 -i 0  0 |       | 1  0 0  0 |       | 0 0 -1  0 |
!      \ 1 0 0 0 /       \ i  0 0  0 /       \ 0 -1 0  0 /       \ 0 0  0 -1 /
!
!                                        / 0 0 -i  0 \
! Note that gam5 = gam1*gam2*gam3*gam4 = | 0 0  0 -i |.
!                                        | i 0  0  0 |
!                                        \ 0 i  0  0 /
!

! This rouinte calculates the operators using the propagator
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! I'm starting over again here, just like in gammaCurrentCalc. The
! original currentCalc2 now renamed to currentCalc2X. -WW

  do jc = 1,nc

!     Calculate point-split J_4 (4-direction)
   if (.not. fixbc) then
     IF (jd.eq.1 .or. jd.eq.2) THEN
         if (jri.eq.1) then
                 arhor(ahere)=arhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 arhor(ahere)=arhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF(jd.eq.3 .or. jd.eq.4) THEN
         if (jri.eq.1) then
                 arhor(leftt)=arhor(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 arhoi(leftt)=arhoi(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     arhor(leftt)=arhor(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     arhoi(leftt)=arhoi(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   else ! fixbc

! NOTE: Since the propagator is fixed at "ahere" then the restrictions on the
!       boundry are different than that in gammacurrentcalc.
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     IF ((jd.eq.1 .or. jd.eq.2).and.ittt/=nt) THEN
         if (jri.eq.1) then
                 arhor(ahere)=arhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 arhor(ahere)=arhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF((jd.eq.3 .or. jd.eq.4).and.ittt/=1) THEN
         if (jri.eq.1) then
                 arhor(leftt)=arhor(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 arhoi(leftt)=arhoi(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     arhor(leftt)=arhor(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     arhoi(leftt)=arhoi(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   endif ! fixbc


!     Calculate point-split J_1 (1-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     if (jri.eq.1) then
! U_mu(x) contribution
         aj1pr(leftx)=aj1pr(leftx)&
        -s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)&
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)
 
         aj1pi(leftx)=aj1pi(leftx)&
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)&
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)
 
! U_mudagger(x) contribution
         aj1pr(ahere)=aj1pr(ahere)&
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)&
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd)
 
         aj1pi(ahere)=aj1pi(ahere)&
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)&
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd)
 
     else if(jri.eq.2) then
 
! U_mu(x) contribution
         aj1pr(leftx)=aj1pr(leftx)&
! Look!!
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)&
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)
 
         aj1pi(leftx)=aj1pi(leftx)&
! Look!!
        -s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)&
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)
  
! U_mudagger(x) contribution
         aj1pr(ahere)=aj1pr(ahere)&
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)&
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd)
 
         aj1pi(ahere)=aj1pi(ahere)&
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)&
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd)
 
     end if ! (jri.eq.1)


!     Calculate point-split J_2 (2-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(y) contribution
         aj2pr(lefty)=aj2pr(lefty)&
        -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

         aj2pi(lefty)=aj2pi(lefty)&
        -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         aj2pr(ahere)=aj2pr(ahere)&
        +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

         aj2pi(ahere)=aj2pi(ahere)&
        -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

     else if(jri.eq.2) then
! U_mu(y) contribution
         aj2pr(lefty)=aj2pr(lefty)&
        +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

         aj2pi(lefty)=aj2pi(lefty)&
        -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         aj2pr(ahere)=aj2pr(ahere)&
        +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

         aj2pi(ahere)=aj2pi(ahere)&
        +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     END IF

!     Calculate point-split J_3 (3-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(z) contribution
         aj3pr(leftz)=aj3pr(leftz)&
        -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

         aj3pi(leftz)=aj3pi(leftz)&
        -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         aj3pr(ahere)=aj3pr(ahere)&
        +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

         aj3pi(ahere)=aj3pi(ahere)&
        -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

     else if(jri.eq.2) then
! U_mu(z) contribution
         aj3pr(leftz)=aj3pr(leftz)&
        +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

         aj3pi(leftz)=aj3pi(leftz)&
        -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         aj3pr(ahere)=aj3pr(ahere)&
        +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

         aj3pi(ahere)=aj3pi(ahere) &
        +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)
         end if ! (jri.eq.1)

     END IF

  enddo ! jc
  Return
  
  end subroutine currentCalc2_axialP

!*******************************************************************************

  Subroutine currentCalc2_axialM(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)

  use operator
! use gaugelinks
          
  real(kind=KR),    intent(in),  dimension(nxyzt,nc,nd)               :: z2input 
  real(kind=KR),    intent(in),  dimension(:,:,:,:)                   :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)                 :: uss
  integer(kind=KI), intent(in)                                        :: jd,jri,icolor,ittt  
  integer(kind=KI), intent(in)                                        :: ahere,leftx,rightx,&
                                                                         lefty,righty,leftz,rightz,&
                                                                         leftt,rightt
  integer(kind=KI), intent(in)                                        :: myid
  character(len=*), intent(in),  dimension(:)                         :: rwdir
  real(kind=KR),    intent(in),  dimension(nxyzt)                     :: s
  integer(kind=KI)                                                    :: jc,ierr

  arhor(ahere)=0.0_KR
  arhor(leftt)=0.0_KR
  arhoi(ahere)=0.0_KR
  arhoi(leftt)=0.0_KR
  aj1pr(ahere)=0.0_KR
  aj1pr(leftx)=0.0_KR
  aj1pi(ahere)=0.0_KR
  aj1pi(leftx)=0.0_KR
  aj2pr(ahere)=0.0_KR
  aj2pr(lefty)=0.0_KR
  aj2pi(ahere)=0.0_KR
  aj2pi(lefty)=0.0_KR
  aj3pr(ahere)=0.0_KR
  aj3pr(leftz)=0.0_KR
  aj3pi(ahere)=0.0_KR
  aj3pi(leftz)=0.0_KR

  
! CONVENTION FOR DIRAC GAMMA MATRICES:
!
!      / 0 0 0 1 \       / 0  0 0 -i \       / 0  0 1  0 \       / 1 0  0  0 \
! gam1=| 0 0 1 0 |, gam2=| 0  0 i  0 |, gam3=| 0  0 0 -1 |, gam4=| 0 1  0  0 |.
!      | 0 1 0 0 |       | 0 -i 0  0 |       | 1  0 0  0 |       | 0 0 -1  0 |
!      \ 1 0 0 0 /       \ i  0 0  0 /       \ 0 -1 0  0 /       \ 0 0  0 -1 /
!
!                                        / 0 0 -i  0 \
! Note that gam5 = gam1*gam2*gam3*gam4 = | 0 0  0 -i |.
!                                        | i 0  0  0 |
!                                        \ 0 i  0  0 /
!

! This rouinte calculates the operators using the propagator
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! I'm starting over again here, just like in gammaCurrentCalc. The
! original currentCalc2 now renamed to currentCalc2X. -WW

  do jc = 1,nc

!     Calculate point-split J_4 (4-direction)
   if (.not. fixbc) then
     IF (jd.eq.3 .or. jd.eq.4) THEN
         if (jri.eq.1) then
                 arhor(ahere)=arhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 arhor(ahere)=arhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF(jd.eq.1 .or. jd.eq.2) THEN
         if (jri.eq.1) then
                 arhor(leftt)=arhor(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 arhoi(leftt)=arhoi(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     arhor(leftt)=arhor(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     arhoi(leftt)=arhoi(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   else ! fixbc

! NOTE: Since the propagator is fixed at "ahere" then the restrictions on the
!       boundry are different than that in gammacurrentcalc.
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     IF ((jd.eq.3 .or. jd.eq.4).and.ittt/=nt) THEN
         if (jri.eq.1) then
                 arhor(ahere)=arhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 arhor(ahere)=arhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,icolor,jc)*z2input(rightt,jc,jd)
                 arhoi(ahere)=arhoi(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,1,icolor,jc)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF((jd.eq.1 .or. jd.eq.2).and.ittt/=1) THEN
         if (jri.eq.1) then
                 arhor(leftt)=arhor(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
                 arhoi(leftt)=arhoi(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     arhor(leftt)=arhor(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,2,jc,icolor)*z2input(leftt,jc,jd)
                     arhoi(leftt)=arhoi(leftt)&
                    +2.0_KR*s(ahere)*usp(leftt,1,jc,icolor)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   endif ! fixbc


!     Calculate point-split J_1 (1-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     if (jri.eq.1) then
! U_mu(x) contribution
         aj1pr(leftx)=aj1pr(leftx)&
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal
 
         aj1pi(leftx)=aj1pi(leftx)&
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal
        +s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal
 
! U_mudagger(x) contribution
         aj1pr(ahere)=aj1pr(ahere)&
        -s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal
 
         aj1pi(ahere)=aj1pi(ahere)&
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal
 
     else if(jri.eq.2) then
 
! U_mu(x) contribution
         aj1pr(leftx)=aj1pr(leftx)&
! Look!!
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal
        -s(ahere)*uss(leftx,1,2,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal
 
         aj1pi(leftx)=aj1pi(leftx)&
! Look!!
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,jd)&   !diagonal
        +s(ahere)*uss(leftx,1,1,jc,icolor)*z2input(leftx,jc,5-jd)  !off-diagonal
  
! U_mudagger(x) contribution
         aj1pr(ahere)=aj1pr(ahere)&
        -s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal
        +s(ahere)*uss(ahere,1,2,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal
 
         aj1pi(ahere)=aj1pi(ahere)&
        -s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,jd)&  !diagonal
        +s(ahere)*uss(ahere,1,1,icolor,jc)*z2input(rightx,jc,5-jd) !off-diagonal
 
     end if ! (jri.eq.1)


!     Calculate point-split J_2 (2-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(y) contribution
         aj2pr(lefty)=aj2pr(lefty)&
        +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

         aj2pi(lefty)=aj2pi(lefty)&
        +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         aj2pr(ahere)=aj2pr(ahere)&
        -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

         aj2pi(ahere)=aj2pi(ahere)&
        +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

     else if(jri.eq.2) then
! U_mu(y) contribution
         aj2pr(lefty)=aj2pr(lefty)&
        -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,jd)

         aj2pi(lefty)=aj2pi(lefty)&
        +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         aj2pr(ahere)=aj2pr(ahere)&
        -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,jd)

         aj2pi(ahere)=aj2pi(ahere)&
        -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            -s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            +s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            -s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            -s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             aj2pr(lefty)=aj2pr(lefty)&
            +s(ahere)*uss(lefty,2,1,jc,icolor)*z2input(lefty,jc,5-jd)

             aj2pi(lefty)=aj2pi(lefty)&
            +s(ahere)*uss(lefty,2,2,jc,icolor)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             aj2pr(ahere)=aj2pr(ahere)&
            +s(ahere)*uss(ahere,2,1,icolor,jc)*z2input(righty,jc,5-jd)

             aj2pi(ahere)=aj2pi(ahere)&
            -s(ahere)*uss(ahere,2,2,icolor,jc)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     END IF

!     Calculate point-split J_3 (3-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(z) contribution
         aj3pr(leftz)=aj3pr(leftz)&
        +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

         aj3pi(leftz)=aj3pi(leftz)&
        +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         aj3pr(ahere)=aj3pr(ahere)&
        -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

         aj3pi(ahere)=aj3pi(ahere)&
        +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

     else if(jri.eq.2) then
! U_mu(z) contribution
         aj3pr(leftz)=aj3pr(leftz)&
        -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,jd)

         aj3pi(leftz)=aj3pi(leftz)&
        +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         aj3pr(ahere)=aj3pr(ahere)&
        -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,jd)

         aj3pi(ahere)=aj3pi(ahere) &
        -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,3/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            +s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,3/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            +s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,3/jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            -s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            +s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             aj3pr(leftz)=aj3pr(leftz)&
            +s(ahere)*uss(leftz,3,2,jc,icolor)*z2input(leftz,jc,8/jd)

             aj3pi(leftz)=aj3pi(leftz)&
            -s(ahere)*uss(leftz,3,1,jc,icolor)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             aj3pr(ahere)=aj3pr(ahere)&
            -s(ahere)*uss(ahere,3,2,icolor,jc)*z2input(rightz,jc,8/jd)

             aj3pi(ahere)=aj3pi(ahere)&
            -s(ahere)*uss(ahere,3,1,icolor,jc)*z2input(rightz,jc,8/jd)
         end if ! (jri.eq.1)

     END IF

  enddo ! jc
  Return
  
  end subroutine currentCalc2_axialM

!*******************************************************************************




!***********************************************************************
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  Subroutine currentCalc2X(s,jd,icolor,jri,ahere,&
                          leftx,rightx,lefty,righty,leftz,rightz,leftt,rightt,ittt,&
                          usp,uss,z2input,rwdir,myid)

  use operator
! use gaugelinks

  real(kind=KR),    intent(in),  dimension(nxyzt,nc,nd)               :: z2input
  real(kind=KR),    intent(in),  dimension(:,:,:,:)                   :: usp
  real(kind=KR),    intent(in),  dimension(:,:,:,:,:)                 :: uss
  integer(kind=KI), intent(in)                                        :: jd,jri,icolor,ittt
  integer(kind=KI), intent(in)                                        :: ahere,leftx,rightx,&
                                                                         lefty,righty,leftz,rightz,&
                                                                         leftt,rightt
  integer(kind=KI), intent(in)                                        :: myid
  character(len=*), intent(in),  dimension(:)                         :: rwdir
  real(kind=KR),    intent(in),  dimension(nxyzt)                     :: s
  integer(kind=KI)                                                    :: jc,ierr

  rhor(ahere)=0.0_KR
  rhor(leftt)=0.0_KR
  rhoi(ahere)=0.0_KR
  rhoi(leftt)=0.0_KR
  j1pr(ahere)=0.0_KR
  j1pr(leftx)=0.0_KR
  j1pi(ahere)=0.0_KR
  j1pi(leftx)=0.0_KR
  j2pr(ahere)=0.0_KR
  j2pr(lefty)=0.0_KR
  j2pi(ahere)=0.0_KR
  j2pi(lefty)=0.0_KR
  j3pr(ahere)=0.0_KR
  j3pr(leftz)=0.0_KR
  j3pi(ahere)=0.0_KR
  j3pi(leftz)=0.0_KR


! CONVENTION FOR DIRAC GAMMA MATRICES:
!
!      / 0 0 0 1 \       / 0  0 0 -i \       / 0  0 1  0 \       / 1 0  0  0 \
! gam1=| 0 0 1 0 |, gam2=| 0  0 i  0 |, gam3=| 0  0 0 -1 |, gam4=| 0 1  0  0 |.
!      | 0 1 0 0 |       | 0 -i 0  0 |       | 1  0 0  0 |       | 0 0 -1  0 |
!      \ 1 0 0 0 /       \ i  0 0  0 /       \ 0 -1 0  0 /       \ 0 0  0 -1 /
!
!                                        / 0 0 -i  0 \
! Note that gam5 = gam1*gam2*gam3*gam4 = | 0 0  0 -i |.
!                                        | i 0  0  0 |
!                                        \ 0 i  0  0 /
!

! Dr Wilcox/Dean: Reminder that the color order for the index
!                 ahere was (icolor,jc) and the Hermitian
!                 order for U-dagger is (jc,icolor)!

! NOTE: This subroutine, CurrentCalc2 uses a different
!       representation for the off-diagonal elements of the
!       operators. The other representation is found in
!       subroutine gammaCurrentCalc.


! This rouinte calculates the operators using the propagator
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

! It now looks very much like Dean mixed up the U-mu and U-mudagger
! terms below. -WW

  do jc = 1,nc

!     Calculate point-split J_4 (4-direction)
   if (.not. fixbc) then
     IF (jd.eq.1 .or. jd.eq.2) THEN
         if (jri.eq.1) then
                 rhor(ahere)=rhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,jc,icolor)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,jc,icolor)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 rhor(ahere)=rhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,jc,icolor)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,jc,icolor)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF(jd.eq.3 .or. jd.eq.4) THEN
         if (jri.eq.1) then
                 rhor(leftt)=rhor(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,1,icolor,jc)*z2input(leftt,jc,jd)
                 rhoi(leftt)=rhoi(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,2,icolor,jc)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     rhor(leftt)=rhor(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,2,icolor,jc)*z2input(leftt,jc,jd)
                     rhoi(leftt)=rhoi(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,1,icolor,jc)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   else ! fixbc

! NOTE: Since the propagator is fixed at "ahere" then the restrictions on the
!       boundry are different than that in gammacurrentcalc.
!      operator = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                     -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     IF ((jd.eq.1 .or. jd.eq.2).and.ittt/=nt) THEN
         if (jri.eq.1) then
                 rhor(ahere)=rhor(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,jc,icolor)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,2,jc,icolor)*z2input(rightt,jc,jd)
         else if(jri.eq.2) then
                 rhor(ahere)=rhor(ahere)&
                -2.0_KR*s(ahere)*usp(ahere,2,jc,icolor)*z2input(rightt,jc,jd)
                 rhoi(ahere)=rhoi(ahere)&
                +2.0_KR*s(ahere)*usp(ahere,1,jc,icolor)*z2input(rightt,jc,jd)
         end if ! (jri.eq.1)
     ELSE IF((jd.eq.3 .or. jd.eq.4).and.ittt/=1) THEN
         if (jri.eq.1) then
                 rhor(leftt)=rhor(leftt)&
                -2.0_KR*s(ahere)*usp(leftt,1,icolor,jc)*z2input(leftt,jc,jd)
                 rhoi(leftt)=rhoi(leftt)&
                +2.0_KR*s(ahere)*usp(leftt,2,icolor,jc)*z2input(leftt,jc,jd)
         else if(jri.eq.2) then
                     rhor(leftt)=rhor(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,2,icolor,jc)*z2input(leftt,jc,jd)
                     rhoi(leftt)=rhoi(leftt)&
                    -2.0_KR*s(ahere)*usp(leftt,1,icolor,jc)*z2input(leftt,jc,jd)
         end if ! (jri.eq.1)
     END IF
   endif ! fixbc


!     Calculate point-split J_1 (1-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}

     if (jri.eq.1) then
! U_mu(x) contribution
         j1pr(leftx)=j1pr(leftx)&
        +s(ahere)*uss(leftx,1,1,icolor,jc)*z2input(leftx,jc,jd)&
        -s(ahere)*uss(leftx,1,1,icolor,jc)*z2input(leftx,jc,5-jd)

         j1pi(leftx)=j1pi(leftx)&
        -s(ahere)*uss(leftx,1,2,icolor,jc)*z2input(leftx,jc,jd)&
        +s(ahere)*uss(leftx,1,2,icolor,jc)*z2input(leftx,jc,5-jd)

! U_mudagger(x) contribution
         j1pr(ahere)=j1pr(ahere)&
        -s(ahere)*uss(ahere,1,1,jc,icolor)*z2input(rightx,jc,jd)&
        -s(ahere)*uss(ahere,1,1,jc,icolor)*z2input(rightx,jc,5-jd)

         j1pi(ahere)=j1pi(ahere)&
        -s(ahere)*uss(ahere,1,2,jc,icolor)*z2input(rightx,jc,jd)&
        -s(ahere)*uss(ahere,1,2,jc,icolor)*z2input(rightx,jc,5-jd)

     else if(jri.eq.2) then

! U_mu(x) contribution
         j1pr(leftx)=j1pr(leftx)&
! Look!! Suspect - directly below should be +
        -s(ahere)*uss(leftx,1,2,icolor,jc)*z2input(leftx,jc,jd)&
        -s(ahere)*uss(leftx,1,2,icolor,jc)*z2input(leftx,jc,5-jd)

         j1pi(leftx)=j1pi(leftx)&
! Look!! Suspect - directly below should be +
        -s(ahere)*uss(leftx,1,1,icolor,jc)*z2input(leftx,jc,jd)&
        -s(ahere)*uss(leftx,1,1,icolor,jc)*z2input(leftx,jc,5-jd)

! U_mudagger(x) contribution
         j1pr(ahere)=j1pr(ahere)&
        +s(ahere)*uss(ahere,1,2,jc,icolor)*z2input(rightx,jc,jd)&
        +s(ahere)*uss(ahere,1,2,jc,icolor)*z2input(rightx,jc,5-jd)

         j1pi(ahere)=j1pi(ahere)&
        -s(ahere)*uss(ahere,1,1,jc,icolor)*z2input(rightx,jc,jd)&
        -s(ahere)*uss(ahere,1,1,jc,icolor)*z2input(rightx,jc,5-jd)

     end if ! (jri.eq.1)


!     Calculate point-split J_2 (2-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(y) contribution
         j2pr(lefty)=j2pr(lefty)&
        +s(ahere)*uss(lefty,2,1,icolor,jc)*z2input(lefty,jc,jd)

         j2pi(lefty)=j2pi(lefty)&
        -s(ahere)*uss(lefty,2,2,icolor,jc)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         j2pr(ahere)=j2pr(ahere)&
        -s(ahere)*uss(ahere,2,1,jc,icolor)*z2input(righty,jc,jd)

         j2pi(ahere)=j2pi(ahere)&
        -s(ahere)*uss(ahere,2,2,jc,icolor)*z2input(righty,jc,jd)

     else if(jri.eq.2) then
! U_mu(y) contribution
         j2pr(lefty)=j2pr(lefty)&
        +s(ahere)*uss(lefty,2,2,icolor,jc)*z2input(lefty,jc,jd)

         j2pi(lefty)=j2pi(lefty)&
        +s(ahere)*uss(lefty,2,1,icolor,jc)*z2input(lefty,jc,jd)

! U_mudagger(y) contribution
         j2pr(ahere)=j2pr(ahere)&
        +s(ahere)*uss(ahere,2,2,jc,icolor)*z2input(righty,jc,jd)

         j2pi(ahere)=j2pi(ahere)&
        -s(ahere)*uss(ahere,2,1,jc,icolor)*z2input(righty,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            -s(ahere)*uss(lefty,2,2,icolor,jc)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            -s(ahere)*uss(lefty,2,1,icolor,jc)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            +s(ahere)*uss(ahere,2,2,jc,icolor)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            -s(ahere)*uss(ahere,2,1,jc,icolor)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            +s(ahere)*uss(lefty,2,1,icolor,jc)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            -s(ahere)*uss(lefty,2,2,icolor,jc)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            +s(ahere)*uss(ahere,2,1,jc,icolor)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            +s(ahere)*uss(ahere,2,2,jc,icolor)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            +s(ahere)*uss(lefty,2,2,icolor,jc)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            +s(ahere)*uss(lefty,2,1,icolor,jc)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            -s(ahere)*uss(ahere,2,2,jc,icolor)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            +s(ahere)*uss(ahere,2,1,jc,icolor)*z2input(righty,jc,5-jd)

         else if(jri.eq.2) then
! U_mudagger(y) contribution
             j2pr(lefty)=j2pr(lefty)&
            -s(ahere)*uss(lefty,2,1,icolor,jc)*z2input(lefty,jc,5-jd)

             j2pi(lefty)=j2pi(lefty)&
            +s(ahere)*uss(lefty,2,2,icolor,jc)*z2input(lefty,jc,5-jd)

! U_mu(y) contribution
             j2pr(ahere)=j2pr(ahere)&
            -s(ahere)*uss(ahere,2,1,jc,icolor)*z2input(righty,jc,5-jd)

             j2pi(ahere)=j2pi(ahere)&
            -s(ahere)*uss(ahere,2,2,jc,icolor)*z2input(righty,jc,5-jd)

         end if ! (jri.eq.1)

     END IF

!     Calculate point-split J_3 (3-direction)
!      operator(x) = - Tr{(1+gamma(mu)) U-mudagger(x) s(x,x+a mu)
!                        -(1-gamma(mu)) U-mu(x) s(x+a mu,x)}
!     Diagonal part

     if (jri.eq.1) then
! U_mu(z) contribution
         j3pr(leftz)=j3pr(leftz)&
        +s(ahere)*uss(leftz,3,1,icolor,jc)*z2input(leftz,jc,jd)

         j3pi(leftz)=j3pi(leftz)&
        -s(ahere)*uss(leftz,3,2,icolor,jc)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         j3pr(ahere)=j3pr(ahere)&
        -s(ahere)*uss(ahere,3,1,jc,icolor)*z2input(rightz,jc,jd)

         j3pi(ahere)=j3pi(ahere)&
        -s(ahere)*uss(ahere,3,2,jc,icolor)*z2input(rightz,jc,jd)

     else if(jri.eq.2) then
! U_mu(z) contribution
         j3pr(leftz)=j3pr(leftz)&
        +s(ahere)*uss(leftz,3,2,icolor,jc)*z2input(leftz,jc,jd)

         j3pi(leftz)=j3pi(leftz)&
        +s(ahere)*uss(leftz,3,1,icolor,jc)*z2input(leftz,jc,jd)

! U_mudagger(z) contribution
         j3pr(ahere)=j3pr(ahere)&
        +s(ahere)*uss(ahere,3,2,jc,icolor)*z2input(rightz,jc,jd)

         j3pi(ahere)=j3pi(ahere) &
        -s(ahere)*uss(ahere,3,1,jc,icolor)*z2input(rightz,jc,jd)

     end if ! (jri.eq.1)

!     Off-diagonal part

     IF (mod(jd,2).eq.1) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            -s(ahere)*uss(leftz,3,1,icolor,jc)*z2input(leftz,jc,3/jd)

             j3pi(leftz)=j3pi(leftz)&
            +s(ahere)*uss(leftz,3,2,icolor,jc)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            -s(ahere)*uss(ahere,3,1,jc,icolor)*z2input(rightz,jc,3/jd)

             j3pi(ahere)=j3pi(ahere)&
            -s(ahere)*uss(ahere,3,2,jc,icolor)*z2input(rightz,jc,3/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            -s(ahere)*uss(leftz,3,2,icolor,jc)*z2input(leftz,jc,3/jd)

             j3pi(leftz)=j3pi(leftz)&
            -s(ahere)*uss(leftz,3,1,icolor,jc)*z2input(leftz,jc,3/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            +s(ahere)*uss(ahere,3,2,jc,icolor)*z2input(rightz,jc,3/jd)

             j3pi(ahere)=j3pi(ahere)&
            -s(ahere)*uss(ahere,3,1,jc,icolor)*z2input(rightz,jc,3/jd)

         end if ! (jri.eq.1)

     ELSE IF(mod(jd,2).eq.0) THEN
         if (jri.eq.1) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            +s(ahere)*uss(leftz,3,1,icolor,jc)*z2input(leftz,jc,8/jd)

             j3pi(leftz)=j3pi(leftz)&
            -s(ahere)*uss(leftz,3,2,icolor,jc)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            +s(ahere)*uss(ahere,3,1,jc,icolor)*z2input(rightz,jc,8/jd)

             j3pi(ahere)=j3pi(ahere)&
            +s(ahere)*uss(ahere,3,2,jc,icolor)*z2input(rightz,jc,8/jd)

         else if(jri.eq.2) then
! U_mudagger(z) contribution
             j3pr(leftz)=j3pr(leftz)&
            +s(ahere)*uss(leftz,3,2,icolor,jc)*z2input(leftz,jc,8/jd)

             j3pi(leftz)=j3pi(leftz)&
            +s(ahere)*uss(leftz,3,1,icolor,jc)*z2input(leftz,jc,8/jd)

! U_mu(z) contribution
             j3pr(ahere)=j3pr(ahere)&
            -s(ahere)*uss(ahere,3,2,jc,icolor)*z2input(rightz,jc,8/jd)

             j3pi(ahere)=j3pi(ahere)&
            +s(ahere)*uss(ahere,3,1,jc,icolor)*z2input(rightz,jc,8/jd)
         end if ! (jri.eq.1)

     END IF

  enddo ! jc
  Return
  End subroutine currentCalc2X

!***********************************************************************

  subroutine utouss(upart,uss,usp,numprocs,MRT,myid)

  real(kind=KR),    intent(out),  dimension(:,:,:,:)                    :: usp
  real(kind=KR),    intent(out),  dimension(:,:,:,:,:)                  :: uss
  real(kind=KR),    intent(in),     dimension(18,ntotal,4,2,16)         :: upart
  integer(kind=KI), intent(in)                                          :: myid,numprocs,MRT                 
  real(kind=KR),                       dimension(18,ntotal,4,2,16)      :: utemp
  real(kind=KR),                       dimension(9,ntotal,3,2,16)       :: rtempuss,itempuss
  real(kind=KR),                       dimension(9,ntotal,1,2,16)       :: rtempusp,itempusp

  integer(kind=KI)                                                      :: iblock,ieo,j,i,&
                                                                           kc1,kc2,isite,ixyz,site,inps
  integer(kind=KI)                                                      :: kc,proc,count,ierr
  integer(kind=KI),                    dimension(2)                     :: ix
  integer(kind=KI)                                                      :: iy,iz,it
  integer(kind=KI) :: ieo1,ieo2,itbit,izbit,iybit,ixbit,itbit2,&
                      izbit2,iybit2,ixbit2,ixbit3,iblbit
  integer(kind=KI), dimension(4)                                        :: ip,np

  count = (18*ntotal*4*2*16)
  if (myid==0) then
      do proc=0,numprocs-1
         if (proc==0) then
             utemp = upart
         else
             call MPI_RECV(utemp, count, MRT, proc, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
         endif ! proc

         do iblock = 1,16
            do ieo = 1,2
!    Adapt the gauge links to fit program
!    Map real part of the coulour matrix to our gaugelinks uss,usp
               do i=1,9
                  do ixyz = 1,3
                     rtempuss(i,:,ixyz,ieo,iblock) = utemp(i+(i-1),:,ixyz,ieo,iblock)
                  enddo ! ixyz
                  rtempusp(i,:,1,ieo,iblock)    = utemp(i+(i-1),:,4,ieo,iblock)
               enddo ! i
!    Map the imaginary part of color matrix to gaugelinks uss,usp
               do j=1,9
                  do ixyz = 1,3
                     itempuss(j,:,ixyz,ieo,iblock) = utemp(2*j,:,ixyz,ieo,iblock)
                  enddo ! ixyz
                  itempusp(j,:,1,ieo,iblock)    = utemp(2*j,:,4,ieo,iblock)
               enddo ! j
            enddo ! ieo
         enddo ! iblock
       
  np(1) = npx
  np(2) = npy
  np(3) = npz
  np(4) = npt
  call atoc(proc,np,ip)

! Begin main loop, constructing ix,iy,iz,it from isite,ieo,ibl.
  site = 0
  isite = 0
  ieo1 = 2
  ieo2 = 1
  do itbit = 2,nt/npt,2
     itbit2 = itbit + ip(4)*nt/npt
     ieo1 = 3 - ieo1
     ieo2 = 3 - ieo2
     do izbit = 2,nz/npz,2
        izbit2 = izbit + ip(3)*nz/npz
        ieo1 = 3 - ieo1
        ieo2 = 3 - ieo2
        do iybit = 2,ny/npy,2
           iybit2 = iybit + ip(2)*ny/npy
           ieo1 = 3 - ieo1
           ieo2 = 3 - ieo2
           do ixbit = 4,nx/npx,4
              ixbit2 = ixbit + ip(1)*nx/npx
              isite = isite + 1
              do ieo = 1,2
                 do iblock = 1,16
                    if (iblock>8) then
                        it = itbit2
                    else
                        it = itbit2 - 1
                    endif ! (iblock>8)
                    iblbit = 1 + modulo(iblock-1,8)
                    if (iblbit>4) then
                        iz = izbit2
                    else
                        iz = izbit2 - 1
                    endif ! (iblbit>4)
                    iblbit = 1 + modulo(iblbit-1,4)
                    if (iblbit>2) then
                        iy = iybit2
                    else
                        iy = iybit2 - 1
                    endif ! (iblbit>2)
                    if (modulo(iblock,2)==1) then
                        ixbit3 = ixbit2 - 1
                    else
                        ixbit3 = ixbit2
                    endif ! (modulo==1)
                    ix(ieo1) = ixbit3 - 2
                    ix(ieo2) = ixbit3
                    site = ix(ieo) + (iy-1)*nx + (iz-1)*nx*ny + (it-1)*nx*ny*nz
                    do ixyz = 1,3
                       do kc1 = 1,nc
                          i = 2*(kc1-1) -1
                          do kc2 = 1,nc
                             kc = (kc1+kc2) + i
                             uss(site,ixyz,1,kc1,kc2) = rtempuss(kc,isite,ixyz,ieo,iblock)
                             uss(site,ixyz,2,kc1,kc2) = itempuss(kc,isite,ixyz,ieo,iblock)
                          enddo ! kc2
                        enddo ! kc1
                     enddo ! ixyz
                     do kc1 = 1,nc
                        i = 2*(kc1-1) -1
                        do kc2 = 1,nc
                           kc = (kc1+kc2) + i
                           usp(site,1,kc1,kc2)      = rtempusp(kc,isite,1,ieo,iblock)
                           usp(site,2,kc1,kc2)      = itempusp(kc,isite,1,ieo,iblock)
                        enddo ! kc2
                     enddo ! kc1
                 enddo ! iblock
              enddo ! ieo
           enddo ! ixbit
        enddo ! iybit
     enddo ! izbit
  enddo ! itbit

      end do ! proc
  else
      call MPI_SEND(upart, count, MRT, 0, 0, MPI_COMM_WORLD, ierr)
  endif ! (myid=0)

  end subroutine utouss

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  subroutine changevector(realz2noise,imagz2noise,bepart,bopart,numprocs,MRT,myid)

  real(kind=KR),    intent(out),    dimension(nxyzt,nc,nd)           :: realz2noise,imagz2noise
  real(kind=KR),    intent(in),     dimension(6,ntotal,4,2,8)        :: bepart
  real(kind=KR),    intent(in),     dimension(6,nvhalf,4,2,8)        :: bopart
  integer(kind=KI), intent(in)                                       :: myid,numprocs,MRT                 

  real(kind=KR),                    dimension(nxyzt,nri,nc,nd)       :: evenz2,oddz2
  integer(kind=KI),                 dimension(nxyzt)                 :: hasdata

  real(kind=KR),                    dimension(6,ntotal,nd,2,8)       :: betemp
  real(kind=KR),                    dimension(6,nvhalf,nd,2,8)       :: botemp
  real(kind=KR),                    dimension(6,ntotal,nd,2,16)      :: rtempb,itempb

  integer(kind=KI)                                                   :: iblock,ieo,i,&
                                                                        isite,icolor,idirac,site,&
                                                                        thesite, ic
  integer(kind=KI)                                                   :: kc,proc,count,ierr
  integer(kind=KI)                                                   :: counte, counto
  integer(kind=KI),                 dimension(2)                     :: ix 
  integer(kind=KI)                                                   :: iy,iz,it
  integer(kind=KI) :: j,k,l,m,n
  integer(kind=KI) :: ieo1,ieo2,itbit,izbit,iybit,ixbit,itbit2,&
                      izbit2,iybit2,ixbit2,ixbit3,iblbit
  integer(kind=KI), dimension(4)  :: ip,np 

  evenz2 = 0.0_KR
  oddz2 = 0.0_KR
  hasdata = 0
  realz2noise = 0.0_KR
  imagz2noise = 0.0_KR
 
  counte = (6*ntotal*4*2*8)
  counto = (6*nvhalf*4*2*8)

!!!! WARNING!!!!
! ABDOU ~ not sure in here, but it is VERY IMPORTANT that the shift index is handled with 
!         care. You must make sure that the looping order is correct such that we don't
!         "jumble" the data in array space.

  if (myid==0) then
      do proc=0,numprocs-1
         if (proc==0) then
             betemp = bepart
             botemp = bopart
         else
             call MPI_RECV(betemp, counte, MRT, proc, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
             call MPI_RECV(botemp, counto, MRT, proc, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
         endif
! Working code
         do isite=1,nvhalf
            do ieo = 1,2
               do ic=1,nc
                  do idirac = 1,nd
                     rtempb(ic,isite,idirac,ieo,2)   = botemp(ic+(ic-1),isite,idirac,ieo,1)
                     rtempb(ic,isite,idirac,ieo,3)   = botemp(ic+(ic-1),isite,idirac,ieo,2)
                     rtempb(ic,isite,idirac,ieo,5)   = botemp(ic+(ic-1),isite,idirac,ieo,3)
                     rtempb(ic,isite,idirac,ieo,8)   = botemp(ic+(ic-1),isite,idirac,ieo,4)
                     rtempb(ic,isite,idirac,ieo,9)   = botemp(ic+(ic-1),isite,idirac,ieo,5)
                     rtempb(ic,isite,idirac,ieo,12)   = botemp(ic+(ic-1),isite,idirac,ieo,6)
                     rtempb(ic,isite,idirac,ieo,14)   = botemp(ic+(ic-1),isite,idirac,ieo,7)
                     rtempb(ic,isite,idirac,ieo,15)   = botemp(ic+(ic-1),isite,idirac,ieo,8)

                     itempb(ic,isite,idirac,ieo,2)   = botemp(2*ic,isite,idirac,ieo,1)
                     itempb(ic,isite,idirac,ieo,3)   = botemp(2*ic,isite,idirac,ieo,2)
                     itempb(ic,isite,idirac,ieo,5)   = botemp(2*ic,isite,idirac,ieo,3)
                     itempb(ic,isite,idirac,ieo,8)   = botemp(2*ic,isite,idirac,ieo,4)
                     itempb(ic,isite,idirac,ieo,9)   = botemp(2*ic,isite,idirac,ieo,5)
                     itempb(ic,isite,idirac,ieo,12)   = botemp(2*ic,isite,idirac,ieo,6)
                     itempb(ic,isite,idirac,ieo,14)   = botemp(2*ic,isite,idirac,ieo,7)
                     itempb(ic,isite,idirac,ieo,15)   = botemp(2*ic,isite,idirac,ieo,8)
 
                     rtempb(ic,isite,idirac,ieo,1)   = betemp(ic+(ic-1),isite,idirac,ieo,1)
                     rtempb(ic,isite,idirac,ieo,4)   = betemp(ic+(ic-1),isite,idirac,ieo,2)
                     rtempb(ic,isite,idirac,ieo,6)   = betemp(ic+(ic-1),isite,idirac,ieo,3)
                     rtempb(ic,isite,idirac,ieo,7)   = betemp(ic+(ic-1),isite,idirac,ieo,4)
                     rtempb(ic,isite,idirac,ieo,10)   = betemp(ic+(ic-1),isite,idirac,ieo,5)
                     rtempb(ic,isite,idirac,ieo,11)   = betemp(ic+(ic-1),isite,idirac,ieo,6)
                     rtempb(ic,isite,idirac,ieo,13)   = betemp(ic+(ic-1),isite,idirac,ieo,7)
                     rtempb(ic,isite,idirac,ieo,16)   = betemp(ic+(ic-1),isite,idirac,ieo,8)
 
                     itempb(ic,isite,idirac,ieo,1)   = betemp(2*ic,isite,idirac,ieo,1)
                     itempb(ic,isite,idirac,ieo,4)   = betemp(2*ic,isite,idirac,ieo,2)
                     itempb(ic,isite,idirac,ieo,6)   = betemp(2*ic,isite,idirac,ieo,3)
                     itempb(ic,isite,idirac,ieo,7)   = betemp(2*ic,isite,idirac,ieo,4)
                     itempb(ic,isite,idirac,ieo,10)   = betemp(2*ic,isite,idirac,ieo,5)
                     itempb(ic,isite,idirac,ieo,11)   = betemp(2*ic,isite,idirac,ieo,6)
                     itempb(ic,isite,idirac,ieo,13)   = betemp(2*ic,isite,idirac,ieo,7)
                     itempb(ic,isite,idirac,ieo,16)   = betemp(2*ic,isite,idirac,ieo,8)

              
                  enddo ! idirac
               enddo ! ic
            enddo ! ieo
         enddo ! isite

! The mapping of sites is detemined by the picture for the blocking in qqcd/cfqsprops/cfgsprops.f90.
! Notice that the "block" index is not linear, meaning that the site (first index) jumps from one to 
! two when the "block" changes to the right of the intial entry in the diagram. Our job is to
! map this non-linear fashion into the site which fills nxyzt.

  np(1) = npx
  np(2) = npy
  np(3) = npz
  np(4) = npt
  call atoc(proc,np,ip)

! Begin main loop, constructing ix,iy,iz,it from isite,ieo,ibl.
  isite = 0
  ieo1 = 2
  ieo2 = 1
  do itbit = 2,nt/npt,2
     itbit2 = itbit + ip(4)*nt/npt
     ieo1 = 3 - ieo1
     ieo2 = 3 - ieo2
     do izbit = 2,nz/npz,2
        izbit2 = izbit + ip(3)*nz/npz
        ieo1 = 3 - ieo1
        ieo2 = 3 - ieo2
        do iybit = 2,ny/npy,2
           iybit2 = iybit + ip(2)*ny/npy
           ieo1 = 3 - ieo1
           ieo2 = 3 - ieo2
           do ixbit = 4,nx/npx,4
              ixbit2 = ixbit + ip(1)*nx/npx
              isite = isite + 1
              do ieo = 1,2
                 do iblock = 1,16
                    if (iblock>8) then
                        it = itbit2
                    else
                        it = itbit2 - 1
                    endif ! (iblock>8)
                    iblbit = 1 + modulo(iblock-1,8)
                    if (iblbit>4) then
                        iz = izbit2
                    else
                        iz = izbit2 - 1
                    endif ! (iblbit>4)
                    iblbit = 1 + modulo(iblbit-1,4)
                    if (iblbit>2) then
                        iy = iybit2
                    else
                        iy = iybit2 - 1
                    endif ! (iblbit>2)
                    if (modulo(iblock,2)==1) then
                        ixbit3 = ixbit2 - 1
                    else
                        ixbit3 = ixbit2
                    endif ! (modulo==1)
                    ix(ieo1) = ixbit3 - 2
                    ix(ieo2) = ixbit3

                    thesite = ix(ieo) + (iy-1)*nx + (iz-1)*nx*ny + (it-1)*nx*ny*nz
                    do icolor = 1,nc 
                       do idirac = 1,nd
                          realz2noise(thesite,icolor,idirac) = rtempb(icolor,isite,idirac,ieo,iblock)
                          imagz2noise(thesite,icolor,idirac) = itempb(icolor,isite,idirac,ieo,iblock)
                       enddo ! idirac
                    enddo ! icolor
                 enddo ! iblock
              enddo ! ieo
           enddo ! ixbit
        enddo ! iybit
     enddo ! izbit
  enddo ! itbit

      end do ! proc
  else
      call MPI_SEND(bepart, counte, MRT, 0, 0, MPI_COMM_WORLD, ierr)
      call MPI_SEND(bopart, counto, MRT, 0, 0, MPI_COMM_WORLD, ierr)
  endif

  end subroutine changevector

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  subroutine changenoise(realz2noise,imagz2noise,bepart,bopart,numprocs,MRT,myid)

  real(kind=KR),    intent(out),    dimension(nxyzt,nc,nd)              :: realz2noise,imagz2noise
  real(kind=KR),    intent(in),     dimension(6,ntotal,4,2,8)           :: bepart,bopart
  integer(kind=KI), intent(in)                                          :: myid,numprocs,MRT

  real(kind=KR),                    dimension(nxyzt,nri,nc,nd)          :: evenz2,oddz2
  integer(kind=KI),                 dimension(nxyzt)                    :: hasdata

  real(kind=KR),                    dimension(6,ntotal,nd,2,8)          :: betemp,botemp
  real(kind=KR),                    dimension(6,ntotal,nd,2,16)         :: rtempb,itempb

  integer(kind=KI)                                                      :: iblock,ieo,i,&
                                                                           isite,icolor,idirac,site,&
                                                                           thesite, ic
  integer(kind=KI)                                                      :: kc,proc,count,ierr
  integer(kind=KI)                                                      :: counte, counto
  integer(kind=KI),                 dimension(2)                        :: ix
  integer(kind=KI)                                                      :: iy,iz,it
  integer(kind=KI) :: j,k,l,m,n
  integer(kind=KI) :: ieo1,ieo2,itbit,izbit,iybit,ixbit,itbit2,&
                      izbit2,iybit2,ixbit2,ixbit3,iblbit
  integer(kind=KI), dimension(4) :: ip,np
  integer(kind=KI) :: iblah,ii
 

  realz2noise= 0.0_KR
  imagz2noise= 0.0_KR
  oddz2 = 0.0_KR
  hasdata = 0

  count = (6*ntotal*4*2*8)

  if (myid==0) then
      do proc=0,numprocs-1


         if (proc==0) then
             betemp = bepart
             botemp = bopart
         else
             call MPI_RECV(betemp, count, MRT, proc, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
             call MPI_RECV(botemp, count, MRT, proc, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
          endif ! proc

! Working code?

!print *, "nvhalf,ntotal=",nvhalf,ntotal

        !  do isite=1,ntotal
         do isite=1,nvhalf
             do ieo = 1,2
                do ic=1,nc
                   do idirac = 1,nd

                      rtempb(ic,isite,idirac,ieo,2)   = botemp(ic+(ic-1),isite,idirac,ieo,1)
                      rtempb(ic,isite,idirac,ieo,3)   = botemp(ic+(ic-1),isite,idirac,ieo,2)
                      rtempb(ic,isite,idirac,ieo,5)   = botemp(ic+(ic-1),isite,idirac,ieo,3)
                      rtempb(ic,isite,idirac,ieo,8)   = botemp(ic+(ic-1),isite,idirac,ieo,4)
                      rtempb(ic,isite,idirac,ieo,9)   = botemp(ic+(ic-1),isite,idirac,ieo,5)
                      rtempb(ic,isite,idirac,ieo,12)  = botemp(ic+(ic-1),isite,idirac,ieo,6)
                      rtempb(ic,isite,idirac,ieo,14)  = botemp(ic+(ic-1),isite,idirac,ieo,7)
                      rtempb(ic,isite,idirac,ieo,15)  = botemp(ic+(ic-1),isite,idirac,ieo,8)

                      itempb(ic,isite,idirac,ieo,2)   = botemp(2*ic,isite,idirac,ieo,1)
                      itempb(ic,isite,idirac,ieo,3)   = botemp(2*ic,isite,idirac,ieo,2)
                      itempb(ic,isite,idirac,ieo,5)   = botemp(2*ic,isite,idirac,ieo,3)
                      itempb(ic,isite,idirac,ieo,8)   = botemp(2*ic,isite,idirac,ieo,4)
                      itempb(ic,isite,idirac,ieo,9)   = botemp(2*ic,isite,idirac,ieo,5)
                      itempb(ic,isite,idirac,ieo,12)  = botemp(2*ic,isite,idirac,ieo,6)
                      itempb(ic,isite,idirac,ieo,14)  = botemp(2*ic,isite,idirac,ieo,7)
                      itempb(ic,isite,idirac,ieo,15)  = botemp(2*ic,isite,idirac,ieo,8)

                      rtempb(ic,isite,idirac,ieo,1)   = betemp(ic+(ic-1),isite,idirac,ieo,1)
                      rtempb(ic,isite,idirac,ieo,4)   = betemp(ic+(ic-1),isite,idirac,ieo,2)
                      rtempb(ic,isite,idirac,ieo,6)   = betemp(ic+(ic-1),isite,idirac,ieo,3)
                      rtempb(ic,isite,idirac,ieo,7)   = betemp(ic+(ic-1),isite,idirac,ieo,4)
                      rtempb(ic,isite,idirac,ieo,10)  = betemp(ic+(ic-1),isite,idirac,ieo,5)
                      rtempb(ic,isite,idirac,ieo,11)  = betemp(ic+(ic-1),isite,idirac,ieo,6)
                      rtempb(ic,isite,idirac,ieo,13)  = betemp(ic+(ic-1),isite,idirac,ieo,7)
                      rtempb(ic,isite,idirac,ieo,16)  = betemp(ic+(ic-1),isite,idirac,ieo,8)

                      itempb(ic,isite,idirac,ieo,1)   = betemp(2*ic,isite,idirac,ieo,1)
                      itempb(ic,isite,idirac,ieo,4)   = betemp(2*ic,isite,idirac,ieo,2)
                      itempb(ic,isite,idirac,ieo,6)   = betemp(2*ic,isite,idirac,ieo,3)
                      itempb(ic,isite,idirac,ieo,7)   = betemp(2*ic,isite,idirac,ieo,4)
                      itempb(ic,isite,idirac,ieo,10)  = betemp(2*ic,isite,idirac,ieo,5)
                      itempb(ic,isite,idirac,ieo,11)  = betemp(2*ic,isite,idirac,ieo,6)
                      itempb(ic,isite,idirac,ieo,13)  = betemp(2*ic,isite,idirac,ieo,7)
                      itempb(ic,isite,idirac,ieo,16)  = betemp(2*ic,isite,idirac,ieo,8)

                   enddo ! idirac
                enddo ! ic
             enddo ! ieo
          enddo ! isite

! The mapping of sites is detemined by the picture for the blocking in qqcd/cfqsprops/cfgsprops.f90.
! Notice that the "block" index is not linear, meaning that the site (first index) jumps from one to
! two when the "block" changes to the right of the intial entry in the diagram. Our job is to
! map this non-linear fashion into the site which fills nxyzt.

  np(1) = npx
  np(2) = npy
  np(3) = npz
  np(4) = npt
  call atoc(proc,np,ip)


! Begin main loop, constructing ix,iy,iz,it from isite,ieo,ibl.
  isite = 0
  ieo1 = 2
  ieo2 = 1
  do itbit = 2,nt/npt,2
     itbit2 = itbit + ip(4)*nt/npt
     ieo1 = 3 - ieo1
     ieo2 = 3 - ieo2
     do izbit = 2,nz/npz,2
        izbit2 = izbit + ip(3)*nz/npz
        ieo1 = 3 - ieo1
        ieo2 = 3 - ieo2
        do iybit = 2,ny/npy,2
           iybit2 = iybit + ip(2)*ny/npy
           ieo1 = 3 - ieo1
           ieo2 = 3 - ieo2
           do ixbit = 4,nx/npx,4
              ixbit2 = ixbit + ip(1)*nx/npx
              isite = isite + 1
              do ieo = 1,2
                 do iblock = 1,16
                    if (iblock>8) then
                        it = itbit2
                    else
                        it = itbit2 - 1
                    endif ! (iblock>8)
                    iblbit = 1 + modulo(iblock-1,8)
                    if (iblbit>4) then
                        iz = izbit2
                    else
                        iz = izbit2 - 1
                    endif ! (iblbit>4)
                    iblbit = 1 + modulo(iblbit-1,4)
                    if (iblbit>2) then
                        iy = iybit2
                    else
                        iy = iybit2 - 1
                    endif ! (iblbit>2)
                    if (modulo(iblock,2)==1) then
                        ixbit3 = ixbit2 - 1
                    else
                        ixbit3 = ixbit2
                    endif ! (modulo==1)
                    ix(ieo1) = ixbit3 - 2
                    ix(ieo2) = ixbit3

                    thesite = ix(ieo) + (iy-1)*nx + (iz-1)*nx*ny + (it-1)*nx*ny*nz


                    do icolor = 1,nc
                       do idirac = 1,nd
                          realz2noise(thesite,icolor,idirac) = rtempb(icolor,isite,idirac,ieo,iblock)
                          imagz2noise(thesite,icolor,idirac) = itempb(icolor,isite,idirac,ieo,iblock)
                       enddo ! idirac
                    enddo ! icolor
                 enddo ! iblock
              enddo ! ieo
           enddo ! ixbit
        enddo ! iybit
     enddo ! izbit
  enddo ! itbit
 
      end do ! proc
  else
      call MPI_SEND(bepart, count, MRT, 0, 0, MPI_COMM_WORLD, ierr)
      call MPI_SEND(bopart, count, MRT, 0, 0, MPI_COMM_WORLD, ierr)
  endif

  end subroutine changenoise

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 subroutine writeops(op,oper,xkappa,rwdir,myid)


   real(kind=KR), intent(in),        dimension(nsav,0:3)              :: op
   real(kind=KR), intent(in),        dimension(nsav,nt,5,0:1)         :: oper
   real(kind=KR), intent(in)                                          :: xkappa
   character(len=*), intent(in),     dimension(:)                     :: rwdir
   integer(kind=KI), intent(in)                                       :: myid

   real(kind=KR),                    dimension(nsav,0:3)              :: oa,oe   
   real(kind=KR),                    dimension(nsav,nt,5,0:1)         :: oab,oeb
   real(kind=KR)                                                      :: xnl
   character(len=1)                                                   :: noise


   integer(kind=KI)                                                   :: iop,isb,ix,itr,&
                                                                         i

! Write out results at the end.
!
 1205  format(///)
 1206  format(i6,d24.10,' +-',d24.10)
!

       open(unit=8,file=trim(rwdir(myid+1))//"LOG.VEV",action="write",&
            form="formatted",status="new")
        write(unit=8,fmt="(a16)")           "vacuum operators"


       oa(:,:)=0.0_KR
       oe(:,:)=0.0_KR
! 
       oa(:,0)=oa(:,0)+op(:,0)
       oa(:,1)=oa(:,1)+op(:,0)+op(:,1)
!
       write(unit=8,fmt="(a16)")          "isb=0 quantities"
       write(6,*) 'isb=0 quantities'
       write(6,1205)

       do iop=1,nsav
         write(6,1206) iop,oa(iop,0),oe(iop,0)
         write(unit=8,fmt="(i6,d24.10,' +-',d24.10)")    iop,oa(iop,0),oe(iop,0)
       enddo ! iop
!
       write(6,1205)
       write(unit=8,fmt="(a16)")          "isb=1 quantities"
       write(6,*) 'isb=1 quantities'
       write(6,1205)

       do iop=1,nsav
!        write(6,1206) iop,oa(iop,1),oe(iop,1)
         write(6,1206) iop,oa(iop,1),oe(iop,1)
         write(unit=8,fmt="(i6,d24.10,' +-',d24.10)")    iop,oa(iop,1),oe(iop,1)
       enddo ! iop
!
!     New stuff from zzing.f

       do isb=0,1
         do ix=1,5
           do itr=1,nt
             do iop=1,nsav
               oab(iop,itr,ix,isb)=0.0_KR
               oeb(iop,itr,ix,isb)=0.0_KR
             enddo ! iop
           enddo ! itr
         enddo ! ix
       enddo ! isb
!
       do ix=1,5
         do itr=1,nt
           do iop=1,nsav
             oab(iop,itr,ix,0)=oab(iop,itr,ix,0)+&
                               oper(iop,itr,ix,0)
             oab(iop,itr,ix,1)=oab(iop,itr,ix,1)+&
                               oper(iop,itr,ix,0)+oper(iop,itr,ix,1)
           enddo ! iop
         enddo ! itr
       enddo ! ix


!

 1209  format(3i6,d24.10,' +-',d24.10)


       xnl=dble(nxyz)
       write(unit=8,fmt="(a18)")          "isb=3,4 quantities"
       write(6,*) 'isb=3,4 quantities'
       write(6,1205)

       do ix=1,5
         do itr=1,nt
           do i=1,2
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,0)/xnl,&
                           oeb(i,itr,ix,0)/xnl
             write(unit=8,fmt="(3i6,d24.10,' +-',d24.10)") i,itr,ix,xkappa*oab(i,itr,ix,0)/xnl,&
                           oeb(i,itr,ix,0)/xnl
           end do ! i
           do i=3,4  
             write(6,1209) i,itr,ix,oab(i,itr,ix,0)/xnl, &
                           oeb(i,itr,ix,0)/xnl
             write(unit=8,fmt="(3i6,d24.10,' +-',d24.10)") i,itr,ix,oab(i,itr,ix,0)/xnl, &
                           oeb(i,itr,ix,0)/xnl
           end do ! i
           do i=5,10
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,0)/xnl,&
                           oeb(i,itr,ix,0)/xnl
             write(unit=8,fmt="(3i6,d24.10,' +-',d24.10)") i,itr,ix,xkappa*oab(i,itr,ix,0)/xnl,&
                           oeb(i,itr,ix,0)/xnl
           end do ! i
         enddo ! itr
       enddo ! ix

       write(unit=8,fmt="(a18)")          "isb=5,6 quantities"
       write(6,*) 'isb=5,6 quantities'
       write(6,1205)

       do ix=1,5
         do itr=1,nt
           do i=1,2
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
             write(unit=8,fmt="(3i6,d24.10,' +-',d24.10)") i,itr,ix,xkappa*oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
           end do ! i
           do i=3,4 
             write(6,1209) i,itr,ix,oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
             write(unit=8,fmt="(3i6,d24.10,' +-',d24.10)") i,itr,ix,oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
           end do ! i
           do i=5,10
             write(6,1209) i,itr,ix,xkappa*oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
             write(unit=8,fmt="(3i6,d24.10,' +-',d24.10)") i,itr,ix,xkappa*oab(i,itr,ix,1)/xnl,&
                           oeb(i,itr,ix,1)/xnl
           end do ! i
         enddo ! itr
       enddo ! ix

      close(unit=8,status="keep")

  end subroutine writeops

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 subroutine opwrite(oper,sigma,kappa,delta,shiftnum,ntmqcd,rwdir,&
                    nmom,nop,nsub,myid)


   integer(kind=KI), intent(in)                                       :: nsub, nmom,&
                                                                         nop
   real(kind=KR),    intent(in),     dimension(2,nt,6,nmom,nop)    :: oper
   real(kind=KR),    intent(in),     dimension(2,nt,6,nmom,nop)    :: sigma
   real(kind=KR),    intent(in)                                       :: delta
   integer(kind=KI), intent(in)                                       :: shiftnum
   integer(kind=KI), intent(in)                                       :: ntmqcd
   real(kind=KR),    intent(in)                                       :: kappa
   character(len=*), intent(in),     dimension(:)                     :: rwdir
   integer(kind=KI), intent(in)                                       :: myid

   character(len=2)                                                   :: trailer
   integer(kind=KI)                                                   :: iop,it,imom
   real(kind=KR)                                                      :: xnl, xkappa,cosd




! DEAN ~ Do you need to divid sigma by the volume nxyzt??

       trailer = ".x"
       write(unit=trailer(2:2),fmt="(i1.1)") shiftnum
      
       if(ntmqcd > 0) then
         open(unit=8,file=trim(rwdir(myid+1))//"OPERATORS.LOG.VEV"//trailer//"tmU",action="write",&
              form="formatted",status="new")
         write(unit=8,fmt="(a16)")           "vacuum operators"
       else
         open(unit=8,file=trim(rwdir(myid+1))//"OPERATORS.LOG.VEV"//trailer//"tmD",action="write",&
              form="formatted",status="new")
         write(unit=8,fmt="(a16)")           "vacuum operators"
       endif ! ntmqcd


      xnl = dble(nxyz)
      cosd = cos(delta)
      xkappa = cosd*kappa

       if (nsub.eq.0) then
! 
       write(unit=8,fmt="(a22)")          "zero subtraction level"
!

       do it=1,nt
         do imom=1,nmom
           do iop=1,nop
             if(iop==2) then
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,1,&
                                 oper(1,it,1,imom,iop)/xnl, &
                                 sigma(1,it,1,imom,iop)/xnl
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,2,&
                                 oper(2,it,1,imom,iop)/xnl, &
                                 sigma(2,it,1,imom,iop)/xnl
              else
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,1,&
                                 xkappa*oper(1,it,1,imom,iop)/xnl, &
                                 xkappa*sigma(1,it,1,imom,iop)/xnl
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,2,&
                                 xkappa*oper(2,it,1,imom,iop)/xnl, &
                                 xkappa*sigma(2,it,1,imom,iop)/xnl
              endif ! imom
           enddo ! iop
         enddo ! imom
       enddo ! it
!
       else if (nsub.eq.4) then
       write(unit=8,fmt="(a23)")          "first subtraction level"

       do it=1,nt
         do imom=1,nmom
           do iop=1,nop
             if (iop==2) then
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,1,&
                                 oper(1,it,4,imom,iop)/xnl, &
                                 sigma(1,it,4,imom,iop)/xnl
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,2,&
                                 oper(2,it,4,imom,iop)/xnl, &
                                 sigma(2,it,4,imom,iop)/xnl
             else
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,1,&
                                 xkappa*oper(1,it,4,imom,iop)/xnl, &
                                 xkappa*sigma(1,it,4,imom,iop)/xnl
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,2,&
                                 xkappa*oper(2,it,4,imom,iop)/xnl, &
                                 xkappa*sigma(2,it,4,imom,iop)/xnl
             endif ! imom
           enddo ! iop
         enddo ! imom
       enddo ! it

       elseif (nsub==6) then

       write(unit=8,fmt="(a25)")          "highest subtraction level"

       do it=1,nt
         do imom=1,nmom
           do iop=1,nop
             if (iop==2) then
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,1,&
                                 oper(1,it,6,imom,iop)/xnl, &
                                 sigma(1,it,6,imom,iop)/xnl
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,2,&
                                 oper(2,it,6,imom,iop)/xnl, &
                                 sigma(2,it,6,imom,iop)/xnl
             else
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,1,&
                                 xkappa*oper(1,it,6,imom,iop)/xnl, &
                                 xkappa*sigma(1,it,6,imom,iop)/xnl
               write(unit=8,fmt="(4i8,d24.10, ' '' +-',d24.10)")    it,imom,iop,2,&
                                 xkappa*oper(2,it,6,imom,iop)/xnl, &
                                 xkappa*sigma(2,it,6,imom,iop)/xnl
             endif ! imom
           enddo ! iop
         enddo ! imom
       enddo ! it

      endif ! nsub==6

      close(unit=8,status="keep")

      call printlog("Done with OPERATOR LOG",myid,rwdir)

  end subroutine opwrite

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  subroutine printarray1(s,myid,rwdir,imax,a)

  character(len=*), intent(in) :: s
  character(len=*), intent(in),     dimension(:)  :: rwdir
  integer(kind=KI), intent(in) :: imax,myid
  real(kind=KR), intent(in), dimension(:) :: a

  integer(kind=KI)  :: i
     
      do i=1,imax
!           print "(a32,1i5,d24.10)", s,i,a(i)
            open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",     &
                 action="write",form="formatted",status="old",position="append")
            write(unit=8,fmt="(a32,1i5,d24.10)")  s,i,a(i)
            close(unit=8,status="keep")
       enddo ! imax

  end subroutine printarray1

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  subroutine printarray2(s,myid,rwdir,imax,jmax,a)

  character(len=*), intent(in) :: s
  character(len=*), intent(in),     dimension(:)  :: rwdir
  integer(kind=KI), intent(in) :: imax,jmax,myid
  real(kind=KR), intent(in), dimension(:,:) :: a

  integer(kind=KI)  :: i,j
      do i=1,imax
        do j=1,jmax
            print "(a32,2i5,d24.10)", s,i,j,a(i,j)
            open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",     &
                 action="write",form="formatted",status="old",position="append")
            write(unit=8,fmt="(a32,2i5,d24.10)")  s,i,j,a(i,j)
            close(unit=8,status="keep")
          enddo ! jmax
        enddo ! imax

  end subroutine printarray2

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  subroutine printarray3(s,myid,rwdir,imax,jmax,kmax,a)

  character(len=*), intent(in) :: s
  character(len=*), intent(in),     dimension(:)  :: rwdir
  integer(kind=KI), intent(in) :: imax,jmax,kmax,myid
  real(kind=KR), intent(in), dimension(:,:,:) :: a

  integer(kind=KI)  :: i,j,k
      do i=1,imax
        do j=1,jmax
          do k=1,kmax
            print "(a32,3i5,d24.10)", s,i,j,k,a(i,j,k)
            open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",     &
                 action="write",form="formatted",status="old",position="append")
            write(unit=8,fmt="(a32,3i5,d24.10)")  s,i,j,k,a(i,j,k)
            close(unit=8,status="keep")
          enddo ! kmax
        enddo ! jmax
      enddo ! imax

  end subroutine printarray3

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


  subroutine printarray4(s,imax,jmax,kmax,lmax,a)

  character(len=*), intent(in) :: s
  integer(kind=KI), intent(in) :: imax,jmax,kmax,lmax
  real(kind=KR), intent(in), dimension(:,:,:,:) :: a

  integer(kind=KI)  :: i,j,k,l
      do i=1,imax
        do j=1,jmax
          do k=1,kmax
            do l=1,lmax
                   print "(a32,4i5,d24.10)", s,i,j,k,l,a(i,j,k,l)
             enddo !lmax
           enddo ! kmax
          enddo ! jmax
        enddo ! imax

  end subroutine printarray4

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  subroutine printarray5(s,imax,jmax,kmax,lmax,mmax,a)

  character(len=*), intent(in) :: s
  integer(kind=KI), intent(in) :: imax,jmax,kmax,lmax,mmax
  real(kind=KR), intent(in), dimension(:,:,:,:,:) :: a

  integer(kind=KI)  :: i,j,k,l,m
      do i=1,imax
        do j=1,jmax
          do k=1,kmax
            do l=1,lmax
              do m=1,mmax
                   print "(a32,5i5,d24.10)", s,i,j,k,l,m,a(i,j,k,l,m)
               enddo ! mmax
             enddo !lmax
           enddo ! kmax
          enddo ! jmax
        enddo ! imax

  end subroutine printarray5

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 subroutine printlog(s,myid,rwdir)

 character(len=*), intent(in)                  :: s
 character(len=*), intent(in), dimension(:)    :: rwdir
 integer(kind=KI), intent(in)                  :: myid
      if (myid==0) then
        open(unit=8,file=trim(rwdir(myid+1))//"CFGSPROPS.LOG",     &
             action="write",form="formatted",status="old",position="append")
        write(unit=8,fmt=*)  s
        close(unit=8,status="keep")
       endif

  end subroutine printlog

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 integer function lcut5(in)
  integer(kind=KI), intent(in) :: in

   if(abs(in).le.nx/2-1) then
    lcut5 = in
   else
    lcut5 = in + 1
   endif ! 
    
 end function lcut5 
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 integer function lcut6(in)
  integer(kind=KI), intent(in) :: in

   if(abs(in).le.nx/2-1) then
    lcut6 = in 
   elseif(abs(in).eq.4) then
    lcut6 = in + 1
   elseif(abs(in).eq.5) then
    lcut6 = in + 2
   endif ! abs
    
 end function lcut6 

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 subroutine check4entry(x,rwdir,myid,idin)

! This subroutine prints values of the real parts of sources and propagators.

    real(kind=KR), intent(in), dimension(6,ntotal,4,2,8)     :: x
    character(len=*), intent(in), dimension(:)            :: rwdir
    integer(kind=KI), intent(in) :: myid,idin
    integer(kind=KI) :: i,j,k,l,m, ierr

    if (myid==idin) then
      print *, "Checking for entry"
      do i =1,5,2
         do j =1,nvhalf
            do k=1,4
               do l=1,2
                  do m=1,8
                     if(abs(x(i,j,k,l,m)) /= 0.0_KR) then
                       print "(a64,6i3,1es17.10)", "myid, i,j,k,l,m, x(i,j,k,l,m)=", myid,i,j,k,l,m,x(i,j,k,l,m)
                     endif
                  end do ! m
               end do ! l
           enddo ! k
        enddo ! j
      enddo ! i
      call printlog("Finished checking entries",myid,rwdir)
    endif ! myid

    call MPI_BARRIER(MPI_COMM_WORLD,ierr)
    stop

   end subroutine check4entry

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 subroutine vv(v1,v2,w)
! Vector*vector multiplier: calculate
! w(i) = w(i) + v1^dagger(i) delta_{ic,colour} delta_{id,Dirac} v2(i)
! Note that there is no factor of gamma_4 between v1^dagger and v2, because
! v1^dagger and v2 are understood to be two ends of a fermion propagator
! and, as usual, should really be thought of as psibar (implicit gamma_4)
! and psi.

! INPUT:
!   v1() and v2() are vectors of the form     / v(1)+I*v(2) \
!                                         v = | v(3)+I*v(4) |
!                                             \ v(5)+I*v(6) /
!   in colour space.
!   There is one such vector for each of the 4 Dirac components.
!   expected size: v1(6,nvhalf,4), v2(6,nvhalf,4)
!   nvhalf is the number of v1 vectors = the number of v2 vectors.
! OUTPUT:
!   w(1,i) = w(1,i) + Re[ v1^dagger(i) v2(i)]
!   w(2,i) = w(2,i) + Im[ v1^dagger(i) v2(i)]
!   expected size: w(2,nvhalf) or w(2,ntotal)

    real(kind=KR),    intent(in),    dimension(:,:,:) :: v1, v2
    real(kind=KR),    intent(inout), dimension(:,:)   :: w

    integer(kind=KI) :: id, i
  
    do id = 1,4
     do i = 1,nvhalf
      w(1,i) = w(1,i) + v1(1,i,id)*v2(1,i,id) + v1(2,i,id)*v2(2,i,id) &
                      + v1(3,i,id)*v2(3,i,id) + v1(4,i,id)*v2(4,i,id) &
                      + v1(5,i,id)*v2(5,i,id) + v1(6,i,id)*v2(6,i,id)
      w(2,i) = w(2,i) + v1(1,i,id)*v2(2,i,id) - v1(2,i,id)*v2(1,i,id) &
                      + v1(3,i,id)*v2(4,i,id) - v1(4,i,id)*v2(3,i,id) &
                      + v1(5,i,id)*v2(6,i,id) - v1(6,i,id)*v2(5,i,id)
     enddo ! i
    enddo ! id

 end subroutine vv

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 subroutine atoc(ia,nc,ic)
! Convert single-integer address "ia" of a lattice site to spacetime
! coordinates "ic" in a spacetime of size "nc"
! OR
! Convert single-integer address "ia" of a process to 4-D coordinates
! "ic" on a grid of processes of size "nc"
! NOTE: coordinates and addresses are numbered 0, 1, 2, ...
!       expected sizes: ic(4), nc(4)

    integer(kind=KI), intent(in)                :: ia
    integer(kind=KI), intent(in),  dimension(:) :: nc
    integer(kind=KI), intent(out), dimension(:) :: ic

    ic(1) = modulo(ia,nc(1))
    ic(2) = modulo(ia/nc(1),nc(2))
    ic(3) = modulo(ia/(nc(1)*nc(2)),nc(3))
    ic(4) = modulo(ia/(nc(1)*nc(2)*nc(3)),nc(4))

 end subroutine atoc


! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 subroutine gather(sub,myid,numprocs,MRT)
 
 real(kind=KR),    intent(inout),    dimension(nxyzt,nc,nd)   :: sub
 integer(kind=KI), intent(in)                              :: myid, numprocs, &
                                                              MRT

 integer(kind=KI)                                          :: ierr
 integer(kind=KI)                                          :: ixyzt, jc, jd
 integer(kind=KI)                                          :: ownerproc 
 integer(kind=KI),                dimension(9)             :: imv
 integer(kind=KI)                                          :: ix, iy, iz, it
 integer(kind=KI)                                          :: ihere,leftx,rightx,lefty,righty,&
                                                              leftz,rightz,leftt,rightt
 real(kind=KR), dimension(nc,nd)      :: chunk

 if (.false.) then
 do jc = 1,nc
    do jd = 1,nd
       do ixyzt = 1,nxyzt
          if (sub(ixyzt,jc,jd)/=0.0_KR) then
             print "(a20,4i5,1es17.10)","myid,ihere,sub=", myid,ixyzt,jc,jd,sub(ixyzt,jc,jd)
          endif ! check
       enddo ! ixyzt
    enddo ! jd
 enddo ! jc
 call MPI_BARRIER(MPI_COMM_WORLD,ierr)
 stop
! ALL the data is here....not being BCAST right. 

 do ixyzt = 1,nxyzt
    ownerproc = mod(ixyzt-1, numprocs)

    if (ownerproc == myid) then
       do jc = 1,nc
          do jd = 1,nd
             chunk(jc,jd) = sub(ixyzt,jc,jd)
          enddo
       enddo
    endif

    call MPI_BCAST(chunk,nc*nd,MRT,ownerproc,MPI_COMM_WORLD,ierr)

    if (ownerproc .ne. myid) then
       do jc = 1,nc
          do jd = 1,nd
             sub(ixyzt,jc,jd) = chunk(jc,jd)
          enddo
       enddo
    endif

 enddo

 do jc = 1,nc
    do jd = 1,nd
       do ixyzt = 1,nxyzt
          ownerproc = mod(ixyzt-1, numprocs)
          call MPI_BCAST(sub(ixyzt,jc,jd),1,MRT,ownerproc,MPI_COMM_WORLD,ierr)
       enddo ! ixyzt
    enddo ! jd
 enddo ! jc
 
 endif ! .false
 end subroutine gather
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
  subroutine gamma5vector(a,ihere,icolor,ntmqcd,myid)

! Multiplies vector a by -i*gamma5.

! This subroutine is employed to move the "twisted operators" into
! the physical basis. For example we it can be shown in the
! twisted formalism that the neutral pion and the charged pion need
! to be rotated by the exp[+/-igamma_5w/2] to have the same meaning
! that it had in the physical basis. The plus and minus sign
! are a result of the tau_3 doublet.

! The form of the rotation is:

!        a -> (1+/-igamma_5)a

! where the +/- represnts the tmU and tmD.

! We are assuming MAIXIMAL TWIST with this (1 +/- i gamma_5) term
! such that the twist angle is exactly pi/4

! INPUT: vecsrc is the input e/o preconditioned RHS.
!        angle is the maximal twist angle
!        ntmqcd is the parameter that signals tmU or tmD
! OUTPUT: vecsrc -> exp[+/-igamma_5w/2]*vecsrc



    real(kind=KR),    intent(inout),   dimension(nxyzt,nc,nd)      :: a
    integer(kind=KI), intent(in)                                   :: ntmqcd, myid
    integer(kind=KI), intent(in)                                   :: ihere, icolor

    real(kind=KR),                     dimension(2)                :: temp
    real(kind=KR)                                                  :: fac
    integer(kind=KI)                                               :: isite


    temp = 0.0_KR
    fac = 1.0_KR/(sqrt(2.0_KR))


    if(ntmqcd>0) then
! This will do the tmU case and multiple a by (1+igamma_5)

       temp(1) = a(ihere,icolor,1)
       temp(2) = a(ihere,icolor,2)
 
       a(ihere,icolor,1) = a(ihere,icolor,1) + a(ihere,icolor,3)
       a(ihere,icolor,2) = a(ihere,icolor,2) + a(ihere,icolor,4)
       a(ihere,icolor,3) = a(ihere,icolor,3) - temp(1)
       a(ihere,icolor,4) = a(ihere,icolor,4) - temp(2)

       a(ihere,icolor,:) = fac*a(ihere,icolor,:)

    else if(ntmqcd<0) then
! This will do the tmD case and multiple a by (1-igamma_5)

       temp(1) = a(ihere,icolor,1)
       temp(2) = a(ihere,icolor,2)

       a(ihere,icolor,1) = a(ihere,icolor,1) - a(ihere,icolor,3)
       a(ihere,icolor,2) = a(ihere,icolor,2) - a(ihere,icolor,4)
       a(ihere,icolor,3) = a(ihere,icolor,3) + temp(1)
       a(ihere,icolor,4) = a(ihere,icolor,4) + temp(2)

       a(ihere,icolor,:) = fac*a(ihere,icolor,:)

    endif ! ntmqcd


 end subroutine gamma5vector

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 end module vevbleft


