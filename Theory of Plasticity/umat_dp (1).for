
C=======================================================================
C     UMAT FOR DRUCKER-PRAGER PLASTICITY
C     PLAIN STRESS CONDITION (SIGMA_33 = 0)
C
C     Compatible with ABAQUS Standard
C
C     MODEL:
C       - Linear Elasticity
C       - Drucker-Prager Yield Criterion
C       - Perfect Plasticity
C       - Plane Stress Formulation
C
C     MATERIAL PROPERTIES (PROPS ARRAY)
C       PROPS(1) = E              Young's Modulus
C       PROPS(2) = NU             Poisson's Ratio
C       PROPS(3) = ALPHA          Drucker-Prager parameter
C       PROPS(4) = K              Cohesion parameter
C
C     STRESS COMPONENT ORDER:
C       STRESS(1) = SIGMA_11
C       STRESS(2) = SIGMA_22
C       STRESS(3) = SIGMA_12
C
C=======================================================================

      SUBROUTINE UMAT(STRESS,STATEV,DDSDDE,SSE,SPD,SCD,
     1 RPL,DDSDDT,DRPLDE,DRPLDT,
     2 STRAN,DSTRAN,TIME,DTIME,TEMP,DTEMP,
     3 PREDEF,DPRED,CMNAME,NDI,NSHR,NTENS,
     4 NSTATV,PROPS,NPROPS,COORDS,DROT,PNEWDT,
     5 CELENT,DFGRD0,DFGRD1,NOEL,NPT,LAYER,
     6 KSPT,JSTEP,KINC)

      INCLUDE 'ABA_PARAM.INC'

      CHARACTER*80 CMNAME

      DIMENSION STRESS(NTENS),STATEV(NSTATV),
     1 DDSDDE(NTENS,NTENS),
     2 DDSDDT(NTENS),DRPLDE(NTENS),
     3 STRAN(NTENS),DSTRAN(NTENS),
     4 TIME(2),PREDEF(1),DPRED(1),
     5 PROPS(NPROPS),COORDS(3),
     6 DROT(3,3),DFGRD0(3,3),DFGRD1(3,3)

      DOUBLE PRECISION E,NU
      DOUBLE PRECISION ALPHA,KDP
      DOUBLE PRECISION G,LAMBDA
      DOUBLE PRECISION C11,C12,C33

      DOUBLE PRECISION SIGTR(3)
      DOUBLE PRECISION DEPS(3)

      DOUBLE PRECISION SIGMA11,SIGMA22,TAU12
      DOUBLE PRECISION I1,J2,FYIELD

      DOUBLE PRECISION S11,S22,S33,S12
      DOUBLE PRECISION MEANSTRESS

      DOUBLE PRECISION FACTOR
      INTEGER I,J

C-----------------------------------------------------------------------
C     MATERIAL PROPERTIES
C-----------------------------------------------------------------------

      E      = PROPS(1)
      NU     = PROPS(2)
      ALPHA  = PROPS(3)
      KDP    = PROPS(4)

C-----------------------------------------------------------------------
C     ELASTIC CONSTANTS
C-----------------------------------------------------------------------

      G      = E/(2.0D0*(1.0D0+NU))
      LAMBDA = E*NU/((1.0D0+NU)*(1.0D0-2.0D0*NU))

C-----------------------------------------------------------------------
C     PLANE STRESS ELASTIC MATRIX
C-----------------------------------------------------------------------

      C11 = E/(1.0D0-NU*NU)
      C12 = E*NU/(1.0D0-NU*NU)
      C33 = G

C-----------------------------------------------------------------------
C     INITIALIZE STIFFNESS MATRIX
C-----------------------------------------------------------------------

      DO I=1,NTENS
         DO J=1,NTENS
            DDSDDE(I,J)=0.0D0
         END DO
      END DO

      DDSDDE(1,1)=C11
      DDSDDE(1,2)=C12
      DDSDDE(2,1)=C12
      DDSDDE(2,2)=C11
      DDSDDE(3,3)=C33

C-----------------------------------------------------------------------
C     STRAIN INCREMENT
C-----------------------------------------------------------------------

      DEPS(1)=DSTRAN(1)
      DEPS(2)=DSTRAN(2)
      DEPS(3)=DSTRAN(3)

C-----------------------------------------------------------------------
C     ELASTIC PREDICTOR
C-----------------------------------------------------------------------

      SIGTR(1)=STRESS(1)
     1        +C11*DEPS(1)
     2        +C12*DEPS(2)

      SIGTR(2)=STRESS(2)
     1        +C12*DEPS(1)
     2        +C11*DEPS(2)

      SIGTR(3)=STRESS(3)
     1        +C33*DEPS(3)

C-----------------------------------------------------------------------
C     STRESS COMPONENTS
C-----------------------------------------------------------------------

      SIGMA11 = SIGTR(1)
      SIGMA22 = SIGTR(2)
      TAU12   = SIGTR(3)

      S33 = 0.0D0

C-----------------------------------------------------------------------
C     FIRST STRESS INVARIANT I1
C-----------------------------------------------------------------------

      I1 = SIGMA11 + SIGMA22 + S33

      MEANSTRESS = I1/3.0D0

C-----------------------------------------------------------------------
C     DEVIATORIC STRESSES
C-----------------------------------------------------------------------

      S11 = SIGMA11 - MEANSTRESS
      S22 = SIGMA22 - MEANSTRESS
      S12 = TAU12

C-----------------------------------------------------------------------
C     SECOND DEVIATORIC INVARIANT J2
C-----------------------------------------------------------------------

      J2 = 0.5D0*(S11*S11 + S22*S22 + S33*S33)
     1     + S12*S12

C-----------------------------------------------------------------------
C     DRUCKER-PRAGER YIELD FUNCTION
C-----------------------------------------------------------------------

      FYIELD = DSQRT(J2) + ALPHA*I1 - KDP

C-----------------------------------------------------------------------
C     CHECK YIELD CONDITION
C-----------------------------------------------------------------------

      IF (FYIELD .LE. 0.0D0) THEN

         STRESS(1)=SIGTR(1)
         STRESS(2)=SIGTR(2)
         STRESS(3)=SIGTR(3)

      ELSE

C-----------------------------------------------------------------------
C        SIMPLE RADIAL RETURN METHOD
C-----------------------------------------------------------------------

         FACTOR = KDP/(DSQRT(J2) + ALPHA*I1)

         STRESS(1)=SIGTR(1)*FACTOR
         STRESS(2)=SIGTR(2)*FACTOR
         STRESS(3)=SIGTR(3)*FACTOR

C-----------------------------------------------------------------------
C        REDUCED TANGENT STIFFNESS
C-----------------------------------------------------------------------

         DDSDDE(1,1)=0.1D0*C11
         DDSDDE(1,2)=0.1D0*C12
         DDSDDE(2,1)=0.1D0*C12
         DDSDDE(2,2)=0.1D0*C11
         DDSDDE(3,3)=0.1D0*C33

      END IF

      STATEV(1)=FYIELD

      RETURN
      END
