!
! Copyright 2020-2022 Fluid Numerics LLC
! Author : Joseph Schoonover (joe@fluidnumerics.com)
! Support : support@fluidnumerics.com
!
! //////////////////////////////////////////////////////////////////////////////////////////////// !
MODULE SELF_Model

  USE SELF_SupportRoutines
  USE SELF_Metadata
  USE SELF_Mesh
  USE SELF_MappedData
  USE SELF_HDF5
  USE HDF5
  USE FEQParse

! //////////////////////////////////////////////// !
!   Time integration parameters

!     Runge-Kutta 3rd Order, low storage constants
  REAL(prec),PARAMETER :: rk3_a(1:3) = (/0.0_prec,-5.0_prec/9.0_prec,-153.0_prec/128.0_prec/)
  REAL(prec),PARAMETER :: rk3_b(1:3) = (/0.0_prec,1.0_prec/3.0_prec,3.0_prec/4.0_prec/)
  REAL(prec),PARAMETER :: rk3_g(1:3) = (/1.0_prec/3.0_prec,15.0_prec/16.0_prec,8.0_prec/15.0_prec/)

! 
  INTEGER, PARAMETER :: SELF_EULER = 100
  INTEGER, PARAMETER :: SELF_RK3 = 300
  INTEGER, PARAMETER :: SELF_RK4 = 400

  INTEGER, PARAMETER :: SELF_INTEGRATOR_LENGTH = 10 ! max length of integrator methods when specified as char
  INTEGER, PARAMETER :: SELF_EQUATION_LENGTH = 500

! //////////////////////////////////////////////// !
!   Boundary Condition parameters
!

  ! Conditions on the solution
  INTEGER, PARAMETER :: SELF_BC_PRESCRIBED = 100
  INTEGER, PARAMETER :: SELF_BC_RADIATION = 101
  INTEGER, PARAMETER :: SELF_BC_NONORMALFLOW = 102

  ! Conditions on the solution gradients
  INTEGER, PARAMETER :: SELF_BC_PRESCRIBED_STRESS = 200
  INTEGER, PARAMETER :: SELF_BC_NOSTRESS = 201

! //////////////////////////////////////////////// !
!   Model Formulations
!
  INTEGER, PARAMETER :: SELF_FORMULATION_LENGTH = 30 ! max length of integrator methods when specified as char
  INTEGER, PARAMETER :: SELF_CONSERVATIVE_FLUX = 0
  INTEGER, PARAMETER :: SELF_SPLITFORM_FLUX = 1


  TYPE,ABSTRACT :: Model
    LOGICAL :: gpuAccel
    INTEGER :: fluxDivMethod

    ! Time integration attributes
    INTEGER :: timeIntegrator
    REAL(prec) :: dt
    REAL(prec) :: t

    CONTAINS

    PROCEDURE :: ForwardStep => ForwardStep_Model
    PROCEDURE :: ForwardStepEuler => ForwardStepEuler_Model 

    PROCEDURE :: PreTendency => PreTendency_Model
    PROCEDURE :: SourceMethod => Source_Model
    PROCEDURE :: FluxMethod => Flux_Model
    PROCEDURE :: RiemannSolver => RiemannSolver_Model
    PROCEDURE :: SetBoundaryCondition => SetBoundaryCondition_Model

    PROCEDURE(UpdateSolution),DEFERRED :: UpdateSolution
    PROCEDURE(CalculateTendency),DEFERRED :: CalculateTendency

    GENERIC :: SetTimeIntegrator => SetTimeIntegrator_withInt, &
                                    SetTimeIntegrator_withChar
    PROCEDURE,PRIVATE :: SetTimeIntegrator_withInt
    PROCEDURE,PRIVATE :: SetTimeIntegrator_withChar

    PROCEDURE :: SetSimulationTime
    PROCEDURE :: GetSimulationTime
!    PROCEDURE :: SetTimeStep
!    PROCEDURE :: GetTimeStep

    GENERIC :: SetFluxMethod => SetFluxMethod_withInt, &
                                    SetFluxMethod_withChar
    PROCEDURE,PRIVATE :: SetFluxMethod_withInt
    PROCEDURE,PRIVATE :: SetFluxMethod_withChar

    PROCEDURE :: EnableGPUAccel => EnableGPUAccel_Model
    PROCEDURE :: DisableGPUAccel => DisableGPUAccel_Model

  END TYPE Model

  TYPE,EXTENDS(Model),ABSTRACT :: Model1D
    TYPE(MappedScalar1D) :: solution
    TYPE(MappedScalar1D) :: solutionGradient
    TYPE(MappedScalar1D) :: velocity
    TYPE(MappedScalar1D) :: flux
    TYPE(MappedScalar1D) :: source
    TYPE(MappedScalar1D) :: fluxDivergence
    TYPE(MappedScalar1D) :: dSdt
    TYPE(MPILayer),POINTER :: decomp
    TYPE(Mesh1D),POINTER :: mesh
    TYPE(Geometry1D),POINTER :: geometry

    CONTAINS

    PROCEDURE :: Init => Init_Model1D
    PROCEDURE :: Free => Free_Model1D

    PROCEDURE :: UpdateHost => UpdateHost_Model1D
    PROCEDURE :: UpdateDevice => UpdateDevice_Model1D

    PROCEDURE :: UpdateSolution => UpdateSolution_Model1D
    PROCEDURE :: CalculateTendency => CalculateTendency_Model1D
    PROCEDURE :: CalculateFluxDivergence => CalculateFluxDivergence_Model1D

    GENERIC :: SetSolution => SetSolutionFromChar_Model1D,&
                              SetSolutionFromEqn_Model1D
    PROCEDURE,PRIVATE :: SetSolutionFromChar_Model1D
    PROCEDURE,PRIVATE :: SetSolutionFromEqn_Model1D

    GENERIC :: SetVelocityField => SetVelocityFieldFromChar_Model1D,&
                              SetVelocityFieldFromEqn_Model1D
    PROCEDURE,PRIVATE :: SetVelocityFieldFromChar_Model1D
    PROCEDURE,PRIVATE :: SetVelocityFieldFromEqn_Model1D

!    PROCEDURE :: ReprojectFlux => ReprojectFlux_Model1D

    PROCEDURE :: Read => Read_Model1D
    PROCEDURE :: Write => Write_Model1D
    PROCEDURE :: WriteTecplot => WriteTecplot_Model1D

  END TYPE Model1D

  TYPE,EXTENDS(Model) :: Model2D
    TYPE(MappedScalar2D) :: solution
    TYPE(MappedVector2D) :: solutionGradient
    TYPE(MappedVector2D) :: velocity
    TYPE(MappedVector2D) :: compVelocity
    TYPE(MappedVector2D) :: flux
    TYPE(MappedScalar2D) :: source
    TYPE(MappedScalar2D) :: fluxDivergence
    TYPE(MappedScalar2D) :: dSdt
    TYPE(MPILayer),POINTER :: decomp
    TYPE(Mesh2D),POINTER :: mesh
    TYPE(SEMQuad),POINTER :: geometry

    CONTAINS

    PROCEDURE :: Init => Init_Model2D
    PROCEDURE :: Free => Free_Model2D

    PROCEDURE :: UpdateHost => UpdateHost_Model2D
    PROCEDURE :: UpdateDevice => UpdateDevice_Model2D

    PROCEDURE :: UpdateSolution => UpdateSolution_Model2D
    PROCEDURE :: CalculateTendency => CalculateTendency_Model2D
    PROCEDURE :: CalculateFluxDivergence => CalculateFluxDivergence_Model2D

    GENERIC :: SetSolution => SetSolutionFromChar_Model2D,&
                              SetSolutionFromEqn_Model2D
    PROCEDURE,PRIVATE :: SetSolutionFromChar_Model2D
    PROCEDURE,PRIVATE :: SetSolutionFromEqn_Model2D

    GENERIC :: SetVelocityField => SetVelocityFieldFromChar_Model2D,&
                              SetVelocityFieldFromEqn_Model2D
    PROCEDURE,PRIVATE :: SetVelocityFieldFromChar_Model2D
    PROCEDURE,PRIVATE :: SetVelocityFieldFromEqn_Model2D

    PROCEDURE :: ReprojectFlux => ReprojectFlux_Model2D

    PROCEDURE :: Read => Read_Model2D
    PROCEDURE :: Write => Write_Model2D
    PROCEDURE :: WriteTecplot => WriteTecplot_Model2D

  END TYPE Model2D

  INTERFACE 
    SUBROUTINE UpdateSolution( this, dt )
      USE SELF_Constants, ONLY : prec
      IMPORT Model
      IMPLICIT NONE
      CLASS(Model),INTENT(inout) :: this
      REAL(prec),OPTIONAL,INTENT(in) :: dt
    END SUBROUTINE UpdateSolution
  END INTERFACE

  INTERFACE 
    SUBROUTINE CalculateTendency( this )
      IMPORT Model
      IMPLICIT NONE
      CLASS(Model),INTENT(inout) :: this
    END SUBROUTINE CalculateTendency
  END INTERFACE


  INTERFACE
    SUBROUTINE UpdateSolution_Model1D_gpu_wrapper(solution, dSdt, dt, N, nVar, nEl) &
      bind(c,name="UpdateSolution_Model1D_gpu_wrapper")
      USE iso_c_binding
      USE SELF_Constants
      IMPLICIT NONE
      TYPE(c_ptr) :: solution, dSdt
      INTEGER(C_INT),VALUE :: N,nVar,nEl
      REAL(c_prec),VALUE :: dt
    END SUBROUTINE UpdateSolution_Model1D_gpu_wrapper
  END INTERFACE

  INTERFACE
    SUBROUTINE UpdateSolution_Model2D_gpu_wrapper(solution, dSdt, dt, N, nVar, nEl) &
      bind(c,name="UpdateSolution_Model2D_gpu_wrapper")
      USE iso_c_binding
      USE SELF_Constants
      IMPLICIT NONE
      TYPE(c_ptr) :: solution, dSdt
      INTEGER(C_INT),VALUE :: N,nVar,nEl
      REAL(c_prec),VALUE :: dt
    END SUBROUTINE UpdateSolution_Model2D_gpu_wrapper
  END INTERFACE

  INTERFACE
    SUBROUTINE CalculateDSDt_Model1D_gpu_wrapper(fluxDivergence, source, dSdt, N, nVar, nEl) &
      bind(c,name="CalculateDSDt_Model1D_gpu_wrapper")
      USE iso_c_binding
      IMPLICIT NONE
      TYPE(c_ptr) :: fluxDivergence, source, dSdt
      INTEGER(C_INT),VALUE :: N,nVar,nEl
    END SUBROUTINE CalculateDSDt_Model1D_gpu_wrapper
  END INTERFACE

  INTERFACE
    SUBROUTINE CalculateDSDt_Model2D_gpu_wrapper(fluxDivergence, source, dSdt, N, nVar, nEl) &
      bind(c,name="CalculateDSDt_Model2D_gpu_wrapper")
      USE iso_c_binding
      IMPLICIT NONE
      TYPE(c_ptr) :: fluxDivergence, source, dSdt
      INTEGER(C_INT),VALUE :: N,nVar,nEl
    END SUBROUTINE CalculateDSDt_Model2D_gpu_wrapper
  END INTERFACE

  INTERFACE
    SUBROUTINE CalculateDSDt_Model3D_gpu_wrapper(fluxDivergence, source, dSdt, N, nVar, nEl) &
      bind(c,name="CalculateDSDt_Model3D_gpu_wrapper")
      USE iso_c_binding
      IMPLICIT NONE
      TYPE(c_ptr) :: fluxDivergence, source, dSdt
      INTEGER(C_INT),VALUE :: N,nVar,nEl
    END SUBROUTINE CalculateDSDt_Model3D_gpu_wrapper
  END INTERFACE

CONTAINS

  SUBROUTINE PreTendency_Model(this)
    !! PreTendency is a template routine that is used to house any additional calculations
    !! that you want to execute at the beginning of the tendency calculation routine.
    !! This default PreTendency simply returns back to the caller without executing any instructions
    !!
    !! The intention is to provide a method that can be overridden through type-extension, to handle
    !! any steps that need to be executed before proceeding with the usual tendency calculation methods.
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this

      RETURN

  END SUBROUTINE PreTendency_Model

  SUBROUTINE Source_Model(this)
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this

      RETURN

  END SUBROUTINE Source_Model

  SUBROUTINE RiemannSolver_Model(this)
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this

      RETURN

  END SUBROUTINE RiemannSolver_Model

  SUBROUTINE Flux_Model(this)
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this

      RETURN

  END SUBROUTINE Flux_Model

  SUBROUTINE SetBoundaryCondition_Model(this)
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this

      RETURN

  END SUBROUTINE SetBoundaryCondition_Model 
  
  SUBROUTINE SetTimeIntegrator_withInt(this,integrator)
    !! Sets the time integrator method, using an integer flag
    !!
    !! Valid options for `integrator` are
    !!
    !!    SELF_EULER
    !!    SELF_RK3
    !!    SELF_RK4
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this
    INTEGER, INTENT(in) :: integrator

      this % timeIntegrator = integrator

  END SUBROUTINE SetTimeIntegrator_withInt

  SUBROUTINE SetTimeIntegrator_withChar(this,integrator)
    !! Sets the time integrator method, using a character input
    !!
    !! Valid options for integrator are
    !!
    !!   "euler"
    !!   "rk3"
    !!   "rk4"
    !!
    !! Note that the character provided is not case-sensitive
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this
    CHARACTER(*), INTENT(in) :: integrator
    ! Local
    CHARACTER(SELF_INTEGRATOR_LENGTH) :: upperCaseInt

      upperCaseInt = UpperCase(TRIM(integrator))

      SELECT CASE (TRIM(upperCaseInt))

        CASE ("EULER")
          this % timeIntegrator = SELF_EULER

        CASE ("RK3")
          this % timeIntegrator = SELF_RK3

        CASE ("RK4")
          this % timeIntegrator = SELF_RK4

        CASE DEFAULT
          this % timeIntegrator = SELF_EULER

      END SELECT

  END SUBROUTINE SetTimeIntegrator_withChar

  SUBROUTINE SetFluxMethod_withInt(this,fluxDivMethod)
    !! Sets the method for calculating the flux divergence, using an integer flag
    !!
    !! Valid options for `fluxDivMethod` are
    !!
    !!    SELF_CONSERVATIVE_FLUX
    !!    SELF_SPLITFORM_FLUX
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this
    INTEGER, INTENT(in) :: fluxDivMethod

      this % fluxDivMethod = fluxDivMethod

  END SUBROUTINE SetFluxMethod_withInt

  SUBROUTINE SetFluxMethod_withChar(this,fluxDivMethod)
    !! Sets the method for calculating the flux divergence, using a character input
    !!
    !! Valid options for flux method are
    !!
    !!   "conservative"
    !!   "split" or "splitform" or "split form" or "split-form"
    !!
    !! Note that the character provided is not case-sensitive
    !!
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this
    CHARACTER(*), INTENT(in) :: fluxDivMethod
    ! Local
    CHARACTER(SELF_FORMULATION_LENGTH) :: upperCaseInt

      upperCaseInt = UpperCase(TRIM(fluxDivMethod))

      SELECT CASE (TRIM(upperCaseInt))

        CASE ("CONSERVATIVE")
          this % fluxDivMethod = SELF_CONSERVATIVE_FLUX

        CASE ("SPLIT")
          this % fluxDivMethod = SELF_SPLITFORM_FLUX

        CASE ("SPLITFORM")
          this % fluxDivMethod = SELF_SPLITFORM_FLUX

        CASE ("SPLIT FORM")
          this % fluxDivMethod = SELF_SPLITFORM_FLUX

        CASE ("SPLIT-FORM")
          this % fluxDivMethod = SELF_SPLITFORM_FLUX

        CASE DEFAULT
          this % fluxDivMethod = SELF_CONSERVATIVE_FLUX

      END SELECT

  END SUBROUTINE SetFluxMethod_withChar

  SUBROUTINE GetSimulationTime(this,t)
    !! Returns the current simulation time stored in the model % t attribute
    IMPLICIT NONE
    CLASS(Model),INTENT(in) :: this
    REAL(prec),INTENT(out) :: t

      t = this % t

  END SUBROUTINE GetSimulationTime

  SUBROUTINE SetSimulationTime(this,t)
    !! Sets the model % t attribute with the provided simulation time
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this
    REAL(prec),INTENT(in) :: t

      this % t = t

  END SUBROUTINE SetSimulationTime

  SUBROUTINE EnableGPUAccel_Model(this)
    IMPLICIT NONE
    CLASS(Model), INTENT(inout) :: this

    IF (GPUAvailable()) THEN
      this % gpuAccel = .TRUE.
    ELSE
      this % gpuAccel = .FALSE.
      ! TO DO : Warning to user that no GPU is available
    ENDIF

  END SUBROUTINE EnableGPUAccel_Model

  SUBROUTINE DisableGPUAccel_Model(this)
    IMPLICIT NONE
    CLASS(Model), INTENT(inout) :: this

    this % gpuAccel = .FALSE.

  END SUBROUTINE DisableGPUAccel_Model

  ! ////////////////////////////////////// !
  !       Time Integrators                 !

  SUBROUTINE ForwardStep_Model(this,tn,dt)
  !!  Forward steps the model using the associated tendency procedure and time integrator
  !!
  !!  If the final time `tn` is provided, the model is forward stepped to that final time,
  !!  otherwise, the model is forward stepped only a single time step
  !!  
  !!  If a time step is provided through the interface, the model time step size is updated
  !!  and that time step is used to update the model
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this
    REAL(prec),OPTIONAL,INTENT(in) :: tn
    REAL(prec),OPTIONAL,INTENT(in) :: dt
    ! Local
    INTEGER :: nSteps
    

    IF (PRESENT(dt)) THEN
      this % dt = dt
    ENDIF

    IF (PRESENT(tn)) THEN
      nSteps = INT( (tn - this % t)/(this % dt) )
    ELSE
      nSteps = 1
    ENDIF

    SELECT CASE (this % timeIntegrator)

      CASE (SELF_EULER)

        CALL this % ForwardStepEuler(nSteps)
        this % t = tn

!      CASE RK3
!
!        CALL this % ForwardStepRK3(nSteps)

      CASE DEFAULT
        ! TODO : Warn user that time integrator not valid, default to Euler
        CALL this % ForwardStepEuler(nSteps)

    END SELECT

  END SUBROUTINE ForwardStep_Model

  SUBROUTINE ForwardStepEuler_Model(this,nSteps)
    IMPLICIT NONE
    CLASS(Model),INTENT(inout) :: this
    INTEGER,INTENT(in) :: nSteps
    ! Local
    INTEGER :: i

    DO i = 1, nSteps

      CALL this % CalculateTendency()
      CALL this % UpdateSolution()

    ENDDO 

  END SUBROUTINE ForwardStepEuler_Model

  SUBROUTINE Init_Model1D(this,nvar,mesh,geometry,decomp)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(out) :: this
    INTEGER,INTENT(in) :: nvar
    TYPE(Mesh1D),INTENT(in),TARGET :: mesh
    TYPE(Geometry1D),INTENT(in),TARGET :: geometry
    TYPE(MPILayer),INTENT(in),TARGET :: decomp

    this % decomp => decomp
    this % mesh => mesh
    this % geometry => geometry
    this % gpuAccel = .FALSE.

    CALL this % solution % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % velocity % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % dSdt % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % solutionGradient % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % flux % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % source % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % fluxDivergence % Init(geometry % x % interp,nVar,this % mesh % nElem)

  END SUBROUTINE Init_Model1D

  SUBROUTINE Free_Model1D(this)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this

    CALL this % solution % Free()
    CALL this % velocity % Free()
    CALL this % dSdt % Free()
    CALL this % solutionGradient % Free()
    CALL this % flux % Free()
    CALL this % source % Free()
    CALL this % fluxDivergence % Free()

  END SUBROUTINE Free_Model1D

  SUBROUTINE UpdateHost_Model1D(this)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this

    CALL this % mesh % UpdateHost()
    CALL this % geometry % UpdateHost()
    CALL this % velocity % UpdateHost()
    CALL this % solution % UpdateHost()
    CALL this % dSdt % UpdateHost()
    CALL this % solutionGradient % UpdateHost()
    CALL this % flux % UpdateHost()
    CALL this % source % UpdateHost()
    CALL this % fluxDivergence % UpdateHost()

  END SUBROUTINE UpdateHost_Model1D

  SUBROUTINE UpdateDevice_Model1D(this)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this

    CALL this % mesh % UpdateDevice()
    CALL this % geometry % UpdateDevice()
    CALL this % dSdt % UpdateDevice()
    CALL this % solution % UpdateDevice()
    CALL this % velocity % UpdateDevice()
    CALL this % solutionGradient % UpdateDevice()
    CALL this % flux % UpdateDevice()
    CALL this % source % UpdateDevice()
    CALL this % fluxDivergence % UpdateDevice()

  END SUBROUTINE UpdateDevice_Model1D

  SUBROUTINE SetSolutionFromEqn_Model1D(this, eqn) 
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this
    TYPE(EquationParser),INTENT(in) :: eqn(1:this % solution % nVar)
    ! Local
    INTEGER :: iVar

      ! Copy the equation parser
      DO iVar = 1, this % solution % nVar
        CALL this % solution % SetEquation(ivar, eqn(iVar) % equation)
      ENDDO

      CALL this % solution % SetInteriorFromEquation( this % geometry, this % t )
      CALL this % solution % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % solution % UpdateDevice()
      ENDIF

  END SUBROUTINE SetSolutionFromEqn_Model1D 

  SUBROUTINE SetSolutionFromChar_Model1D(this, eqnChar) 
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this
    CHARACTER(LEN=SELF_EQUATION_LENGTH),INTENT(in) :: eqnChar(1:this % solution % nVar)
    ! Local
    INTEGER :: iVar

      DO iVar = 1, this % solution % nVar
        CALL this % solution % SetEquation(ivar, eqnChar(iVar))
      ENDDO

      CALL this % solution % SetInteriorFromEquation( this % geometry, this % t )
      CALL this % solution % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % solution % UpdateDevice()
      ENDIF

  END SUBROUTINE SetSolutionFromChar_Model1D

  SUBROUTINE SetVelocityFieldFromEqn_Model1D(this, eqn) 
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this
    TYPE(EquationParser),INTENT(in) :: eqn

      ! Copy the equation parser
      ! Set the x-component of the velocity
      CALL this % velocity % SetEquation(1,eqn % equation)

      ! Set the velocity values using the equation parser
      CALL this % velocity % SetInteriorFromEquation( this % geometry, this % t )

      CALL this % velocity % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % velocity % UpdateDevice()
      ENDIF

  END SUBROUTINE SetVelocityFieldFromEqn_Model1D 

  SUBROUTINE SetVelocityFieldFromChar_Model1D(this, eqnChar) 
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this
    CHARACTER(LEN=SELF_EQUATION_LENGTH),INTENT(in) :: eqnChar

      ! Set the x-component of the velocity
      CALL this % velocity % SetEquation(1,eqnChar)

      ! Set the velocity values using the equation parser
      CALL this % velocity % SetInteriorFromEquation( this % geometry, this % t )

      CALL this % velocity % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % velocity % UpdateDevice()
      ENDIF

  END SUBROUTINE SetVelocityFieldFromChar_Model1D

  SUBROUTINE UpdateSolution_Model1D(this,dt)
    !! Computes a solution update as `s=s+dt*dsdt`, where dt is either provided through the interface
    !! or taken as the Model's stored time step size (model % dt)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this
    REAL(prec),OPTIONAL,INTENT(in) :: dt
    ! Local
    REAL(prec) :: dtLoc
    INTEGER :: i, iVar, iEl

    IF (PRESENT(dt)) THEN
      dtLoc = dt
    ELSE 
      dtLoc = this % dt
    ENDIF

    IF (this % gpuAccel) THEN

      CALL UpdateSolution_Model1D_gpu_wrapper( this % solution % interior % deviceData, &
                                      this % dSdt % interior % deviceData, &
                                      dtLoc, &
                                      this % solution % interp % N, &
                                      this % solution % nVar, &
                                      this % solution % nElem ) 
                                      

    ELSE

      DO iEl = 1, this % solution % nElem
        DO iVar = 1, this % solution % nVar
          DO i = 0, this % solution % interp % N

            this % solution % interior % hostData(i,iVar,iEl) = &
                this % solution % interior % hostData(i,iVar,iEl) +&
                dtLoc*this % dSdt % interior % hostData(i,iVar,iEl)

          ENDDO
        ENDDO
      ENDDO

    ENDIF

  END SUBROUTINE UpdateSolution_Model1D

  SUBROUTINE CalculateFluxDivergence_Model1D(this)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this

    CALL this % flux % Derivative(this % geometry, &
                                  this % fluxDivergence, &
                                  selfWeakDGForm,&
                                  this % gpuAccel)

  END SUBROUTINE CalculateFluxDivergence_Model1D

  SUBROUTINE CalculateTendency_Model1D(this)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this
    ! Local
    INTEGER :: i, iVar, iEl

!      CALL this % solution % AverageSides()
!      CALL this % solution % DiffSides()
!      CALL this % SetBoundaryCondition()
      CALL this % PreTendency()
      CALL this % solution % BoundaryInterp(this % gpuAccel)
      CALL this % SetBoundaryCondition()
      CALL this % SourceMethod()
      CALL this % RiemannSolver()
      CALL this % FluxMethod()
      CALL this % CalculateFluxDivergence()

    IF( this % gpuAccel )THEN

      CALL CalculateDSDt_Model1D_gpu_wrapper( this % fluxDivergence % interior % deviceData, &
                                      this % source % interior % deviceData, &
                                      this % dSdt % interior % deviceData, &
                                      this % solution % interp % N, &
                                      this % solution % nVar, &
                                      this % solution % nElem ) 
                                      
    ELSE

      DO iEl = 1, this % solution % nElem
        DO iVar = 1, this % solution % nVar
          DO i = 0, this % solution % interp % N

            this % dSdt % interior % hostData(i,iVar,iEl) = &
                    this % source % interior % hostData(i,iVar,iEl) -&
                    this % fluxDivergence % interior % hostData(i,iVar,iEl)

          ENDDO
        ENDDO
      ENDDO

    ENDIF

  END SUBROUTINE CalculateTendency_Model1D

  SUBROUTINE Write_Model1D(this,fileName)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(in) :: this
    CHARACTER(*),OPTIONAL,INTENT(in) :: fileName
    ! Local
    INTEGER(HID_T) :: fileId
    INTEGER(HID_T) :: solOffset(1:3)
    INTEGER(HID_T) :: xOffset(1:3)
    INTEGER(HID_T) :: bOffset(1:3)
    INTEGER(HID_T) :: bxOffset(1:3)
    INTEGER(HID_T) :: solGlobalDims(1:3)
    INTEGER(HID_T) :: xGlobalDims(1:3)
    INTEGER(HID_T) :: bGlobalDims(1:3)
    INTEGER(HID_T) :: bxGlobalDims(1:3)
    INTEGER :: firstElem
    ! Local
    CHARACTER(LEN=self_FileNameLength) :: pickupFile
    CHARACTER(13) :: timeStampString

    IF( PRESENT(filename) )THEN
      pickupFile = filename
    ELSE
      timeStampString = TimeStamp(this % t, 's')
      pickupFile = 'solution.'//timeStampString//'.h5'
    ENDIF

    IF (this % decomp % mpiEnabled) THEN

      CALL Open_HDF5(pickupFile,H5F_ACC_TRUNC_F,fileId,this % decomp % mpiComm)

      firstElem = this % decomp % offsetElem % hostData(this % decomp % rankId)
      solOffset(1:3) = (/0,1,firstElem/)
      solGlobalDims(1:3) = (/this % solution % interp % N, &
                             this % solution % nVar, &
                             this % decomp % nElem/)


      xOffset(1:3) = (/0,1,firstElem/)
      xGlobalDims(1:3) = (/this % solution % interp % N, &
                           this % solution % nVar, &
                           this % decomp % nElem/)

      ! Offsets and dimensions for element boundary data
      bOffset(1:3) = (/1,1,firstElem/)
      bGlobalDims(1:3) = (/this % solution % nVar, &
                           2,&
                           this % decomp % nElem/)

      bxOffset(1:3) = (/1,1,firstElem/)
      bxGlobalDims(1:3) = (/this % solution % nVar, &
                           2,&
                           this % decomp % nElem/)

      
      CALL CreateGroup_HDF5(fileId,'/quadrature')

      IF( this % decomp % rankId == 0 )THEN
        CALL WriteArray_HDF5(fileId,'/quadrature/xi', &
                             this % solution % interp % controlPoints)

        CALL WriteArray_HDF5(fileId,'/quadrature/weights', &
                             this % solution % interp % qWeights)

        CALL WriteArray_HDF5(fileId,'/quadrature/dgmatrix', &
                             this % solution % interp % dgMatrix)

        CALL WriteArray_HDF5(fileId,'/quadrature/dmatrix', &
                             this % solution % interp % dMatrix)
      ENDIF

      CALL CreateGroup_HDF5(fileId,'/state')

      CALL CreateGroup_HDF5(fileId,'/state/interior')

      CALL CreateGroup_HDF5(fileId,'/state/boundary')

      CALL CreateGroup_HDF5(fileId,'/mesh')

      CALL CreateGroup_HDF5(fileId,'/mesh/interior')

      CALL CreateGroup_HDF5(fileId,'/mesh/boundary')

      CALL WriteArray_HDF5(fileId,'/state/interior/solution', &
                           this % solution % interior,solOffset,solGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solution', &
                           this % solution % boundary,bOffset,bGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/interior/fluxDivergence', &
                           this % fluxDivergence % interior,solOffset,solGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/interior/flux', &
                           this % flux % interior,xOffset,xGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/boundary/flux', &
                           this % flux % boundary,bxOffset,bxGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/interior/solutionGradient', &
                           this % solutionGradient % interior,xOffset,xGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solutionGradient', &
                           this % solutionGradient % boundary,bxOffset,bxGlobalDims)

      CALL WriteArray_HDF5(fileId,'/mesh/interior/x', &
                           this % geometry % x % interior,xOffset,xGlobalDims)

      CALL WriteArray_HDF5(fileId,'/mesh/boundary/x', &
                           this % geometry % x % boundary,bxOffset,bxGlobalDims)

      CALL Close_HDF5(fileId)

    ELSE

      CALL Open_HDF5(pickupFile,H5F_ACC_TRUNC_F,fileId)

      CALL CreateGroup_HDF5(fileId,'/quadrature')

      CALL WriteArray_HDF5(fileId,'/quadrature/xi', &
                           this % solution % interp % controlPoints)

      CALL WriteArray_HDF5(fileId,'/quadrature/weights', &
                           this % solution % interp % qWeights)

      CALL WriteArray_HDF5(fileId,'/quadrature/dgmatrix', &
                           this % solution % interp % dgMatrix)

      CALL WriteArray_HDF5(fileId,'/quadrature/dmatrix', &
                           this % solution % interp % dMatrix)

      CALL CreateGroup_HDF5(fileId,'/state')

      CALL CreateGroup_HDF5(fileId,'/state/interior')

      CALL CreateGroup_HDF5(fileId,'/state/boundary')

      CALL CreateGroup_HDF5(fileId,'/mesh')

      CALL CreateGroup_HDF5(fileId,'/mesh/interior')

      CALL CreateGroup_HDF5(fileId,'/mesh/boundary')

      CALL WriteArray_HDF5(fileId,'/state/interior/solution',this % solution % interior)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solution',this % solution % boundary)

      CALL WriteArray_HDF5(fileId,'/state/interior/fluxDivergence',this % fluxDivergence % interior)

      CALL WriteArray_HDF5(fileId,'/state/interior/flux',this % flux % interior)

      CALL WriteArray_HDF5(fileId,'/state/boundary/flux',this % flux % boundary)

      CALL WriteArray_HDF5(fileId,'/state/interior/solutionGradient',this % solutionGradient % interior)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solutionGradient',this % solutionGradient % boundary)

      CALL WriteArray_HDF5(fileId,'/mesh/interior/x',this % geometry % x % interior)

      CALL WriteArray_HDF5(fileId,'/mesh/boundary/x',this % geometry % x % boundary)

      CALL Close_HDF5(fileId)

    END IF

  END SUBROUTINE Write_Model1D

  SUBROUTINE Read_Model1D(this,fileName)
    IMPLICIT NONE
    CLASS(Model1D),INTENT(inout) :: this
    CHARACTER(*),INTENT(in) :: fileName
    ! Local
    INTEGER(HID_T) :: fileId
    INTEGER(HID_T) :: solOffset(1:3)
    INTEGER :: firstElem
    INTEGER :: N

    IF (this % decomp % mpiEnabled) THEN
      CALL Open_HDF5(fileName,H5F_ACC_RDWR_F,fileId, &
                     this % decomp % mpiComm)
    ELSE
      CALL Open_HDF5(fileName,H5F_ACC_RDWR_F,fileId)
    END IF

    CALL ReadAttribute_HDF5(fileId,'N',N)

    IF (this % solution % interp % N /= N) THEN
      STOP 'Error : Solution polynomial degree does not match input file'
    END IF

    IF (this % decomp % mpiEnabled) THEN
      firstElem = this % decomp % offsetElem % hostData(this % decomp % rankId) + 1
      solOffset(1:3) = (/0,1,firstElem/)
      CALL ReadArray_HDF5(fileId,'/state/interior/solution', &
                          this % solution % interior,solOffset)
    ELSE
      CALL ReadArray_HDF5(fileId,'/state/interior/solution',this % solution % interior)
    END IF

    CALL Close_HDF5(fileId)

  END SUBROUTINE Read_Model1D

  SUBROUTINE WriteTecplot_Model1D(this, filename)
    IMPLICIT NONE
    CLASS(Model1D), INTENT(inout) :: this
    CHARACTER(*), INTENT(in), OPTIONAL :: filename
    ! Local
    CHARACTER(8) :: zoneID
    INTEGER :: fUnit
    INTEGER :: iEl, i 
    CHARACTER(LEN=self_FileNameLength) :: tecFile
    CHARACTER(13) :: timeStampString
    CHARACTER(5) :: rankString
    TYPE(Scalar1D) :: solution
    TYPE(Scalar1D) :: x
    TYPE(Lagrange),TARGET :: interp

    IF( PRESENT(filename) )THEN
      tecFile = filename
    ELSE
      timeStampString = TimeStamp(this % t, 's')

      IF( this % decomp % mpiEnabled )THEN
        WRITE(rankString,'(I5.5)') this % decomp % rankId 
        tecFile = 'solution.'//rankString//'.'//timeStampString//'.tec'
      ELSE
        tecFile = 'solution.'//timeStampString//'.tec'
      ENDIF

    ENDIF
                      
    IF( this % gpuAccel )THEN
      ! Copy data to the CPU
      CALL this % solution % interior % UpdateHost()
    ENDIF

    ! Create an interpolant for the uniform grid
    CALL interp % Init(this % solution % interp % M,&
            this % solution % interp % targetNodeType,&
            this % solution % interp % N, &
            this % solution % interp % controlNodeType)

    CALL solution % Init( interp, &
            this % solution % nVar, this % solution % nElem )

    CALL x % Init( interp, 1, this % solution % nElem )

    ! Map the mesh positions to the target grid
    CALL this % geometry % x % GridInterp(x, gpuAccel=.FALSE.)

    ! Map the solution to the target grid
    CALL this % solution % GridInterp(solution,gpuAccel=.FALSE.)
   
    ! Let's write some tecplot!! 
     OPEN( UNIT=NEWUNIT(fUnit), &
      FILE= TRIM(tecFile), &
      FORM='formatted', &
      STATUS='replace')

    ! TO DO :: Create header from solution metadata 
    WRITE(fUnit,*) 'VARIABLES = "X","solution"'

    DO iEl = 1, this % solution % nElem

      ! TO DO :: Get the global element ID 
      WRITE(zoneID,'(I8.8)') iEl
      WRITE(fUnit,*) 'ZONE T="el'//trim(zoneID)//'", I=',this % solution % interp % M+1

      DO i = 0, this % solution % interp % M

        WRITE(fUnit,'(2(E15.7,1x))') x % interior % hostData(i,1,iEl), &
                                     solution % interior % hostData(i,1,iEl)

      ENDDO

    ENDDO

    CLOSE(UNIT=fUnit)

    CALL x % Free()
    CALL solution % Free() 
    CALL interp % Free()

  END SUBROUTINE WriteTecplot_Model1D

  SUBROUTINE Init_Model2D(this,nvar,mesh,geometry,decomp)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(out) :: this
    INTEGER,INTENT(in) :: nvar
    TYPE(Mesh2D),INTENT(in),TARGET :: mesh
    TYPE(SEMQuad),INTENT(in),TARGET :: geometry
    TYPE(MPILayer),INTENT(in),TARGET :: decomp

    this % decomp => decomp
    this % mesh => mesh
    this % geometry => geometry
    this % gpuAccel = .FALSE.

    CALL this % solution % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % velocity % Init(geometry % x % interp,1,this % mesh % nElem)
    CALL this % compVelocity % Init(geometry % x % interp,1,this % mesh % nElem)
    CALL this % dSdt % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % solutionGradient % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % flux % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % source % Init(geometry % x % interp,nVar,this % mesh % nElem)
    CALL this % fluxDivergence % Init(geometry % x % interp,nVar,this % mesh % nElem)

  END SUBROUTINE Init_Model2D

  SUBROUTINE Free_Model2D(this)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this

    CALL this % solution % Free()
    CALL this % velocity % Free()
    CALL this % compVelocity % Free()
    CALL this % dSdt % Free()
    CALL this % solutionGradient % Free()
    CALL this % flux % Free()
    CALL this % source % Free()
    CALL this % fluxDivergence % Free()

  END SUBROUTINE Free_Model2D

  SUBROUTINE UpdateHost_Model2D(this)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this

    CALL this % mesh % UpdateHost()
    CALL this % geometry % UpdateHost()
    CALL this % solution % UpdateHost()
    CALL this % dSdt % UpdateHost()
    CALL this % solution % UpdateHost()
    CALL this % velocity % UpdateHost()
    CALL this % solutionGradient % UpdateHost()
    CALL this % flux % UpdateHost()
    CALL this % source % UpdateHost()
    CALL this % fluxDivergence % UpdateHost()

  END SUBROUTINE UpdateHost_Model2D

  SUBROUTINE UpdateDevice_Model2D(this)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this

    CALL this % mesh % UpdateDevice()
    CALL this % geometry % UpdateDevice()
    CALL this % dSdt % UpdateDevice()
    CALL this % solution % UpdateDevice()
    CALL this % velocity % UpdateDevice()
    CALL this % solutionGradient % UpdateDevice()
    CALL this % flux % UpdateDevice()
    CALL this % source % UpdateDevice()
    CALL this % fluxDivergence % UpdateDevice()

  END SUBROUTINE UpdateDevice_Model2D

  SUBROUTINE SetSolutionFromEqn_Model2D(this, eqn) 
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this
    TYPE(EquationParser),INTENT(in) :: eqn(1:this % solution % nVar)
    ! Local
    INTEGER :: iVar

      ! Copy the equation parser
      DO iVar = 1, this % solution % nVar
        CALL this % solution % SetEquation(ivar, eqn(iVar) % equation)
      ENDDO

      CALL this % solution % SetInteriorFromEquation( this % geometry, this % t )

      CALL this % solution % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % solution % UpdateDevice()
      ENDIF

  END SUBROUTINE SetSolutionFromEqn_Model2D 

  SUBROUTINE SetVelocityFieldFromEqn_Model2D(this, eqn) 
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this
    TYPE(EquationParser),INTENT(in) :: eqn(1:2)

      ! Copy the equation parser
      ! Set the x-component of the velocity
      CALL this % velocity % SetEquation(1,1,eqn(1) % equation)

      ! Set the y-component of the velocity
      CALL this % velocity % SetEquation(2,1,eqn(2) % equation)

      ! Set the velocity values using the equation parser
      CALL this % velocity % SetInteriorFromEquation( this % geometry, this % t )

      CALL this % velocity % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % velocity % UpdateDevice()
      ENDIF

  END SUBROUTINE SetVelocityFieldFromEqn_Model2D 

  SUBROUTINE SetVelocityFieldFromChar_Model2D(this, eqnChar) 
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this
    CHARACTER(LEN=SELF_EQUATION_LENGTH),INTENT(in) :: eqnChar(1:2)

      ! Set the x-component of the velocity
      CALL this % velocity % SetEquation(1,1,eqnChar(1))

      ! Set the y-component of the velocity
      CALL this % velocity % SetEquation(2,1,eqnChar(2))

      ! Set the velocity values using the equation parser
      CALL this % velocity % SetInteriorFromEquation( this % geometry, this % t )

      CALL this % velocity % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % velocity % UpdateDevice()
      ENDIF

  END SUBROUTINE SetVelocityFieldFromChar_Model2D

  SUBROUTINE SetSolutionFromChar_Model2D(this, eqnChar) 
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this
    CHARACTER(LEN=SELF_EQUATION_LENGTH),INTENT(in) :: eqnChar(1:this % solution % nVar)
    ! Local
    INTEGER :: iVar

      DO iVar = 1, this % solution % nVar
        CALL this % solution % SetEquation(ivar, eqnChar(iVar))
      ENDDO

      CALL this % solution % SetInteriorFromEquation( this % geometry, this % t )

      CALL this % solution % BoundaryInterp( gpuAccel = .FALSE. )

      IF( this % gpuAccel )THEN
        CALL this % solution % UpdateDevice()
      ENDIF

  END SUBROUTINE SetSolutionFromChar_Model2D

  SUBROUTINE UpdateSolution_Model2D(this,dt)
    !! Computes a solution update as `s=s+dt*dsdt`, where dt is either provided through the interface
    !! or taken as the Model's stored time step size (model % dt)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this
    REAL(prec),OPTIONAL,INTENT(in) :: dt
    ! Local
    REAL(prec) :: dtLoc
    INTEGER :: i, j, iVar, iEl

    IF (PRESENT(dt)) THEN
      dtLoc = dt
    ELSE 
      dtLoc = this % dt
    ENDIF

    IF (this % gpuAccel) THEN

      CALL UpdateSolution_Model2D_gpu_wrapper( this % solution % interior % deviceData, &
                                      this % dSdt % interior % deviceData, &
                                      dtLoc, &
                                      this % solution % interp % N, &
                                      this % solution % nVar, &
                                      this % solution % nElem ) 
                                      

    ELSE

      DO iEl = 1, this % solution % nElem
        DO iVar = 1, this % solution % nVar
          DO j = 0, this % solution % interp % N
            DO i = 0, this % solution % interp % N

              this % solution % interior % hostData(i,j,iVar,iEl) = &
                  this % solution % interior % hostData(i,j,iVar,iEl) +&
                  dtLoc*this % dSdt % interior % hostData(i,j,iVar,iEl)

            ENDDO
          ENDDO
        ENDDO
      ENDDO

    ENDIF

  END SUBROUTINE UpdateSolution_Model2D

  SUBROUTINE ReprojectFlux_Model2D(this) 
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this

      CALL this % flux % ContravariantProjection(this % geometry, this % flux, this % gpuAccel)

  END SUBROUTINE ReprojectFlux_Model2D

  SUBROUTINE CalculateFluxDivergence_Model2D(this)
    !! Calculates the divergence of the flux vector using either the split-form or conservative formulation.
    !! If the split-form is used, you need to set the velocity field
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this

      IF (this % fluxDivMethod == SELF_SPLITFORM_FLUX) THEN
        CALL this % velocity % ContravariantProjection(this % geometry, this % compVelocity, this % gpuAccel)

        IF (this % gpuAccel) THEN
          CALL this % flux % interp % VectorDGDivergence_2D(this % flux % interior % deviceData, &
                                                           this % solution % interior % deviceData, &
                                                           this % compVelocity % interior % deviceData, &
                                                           this % flux % boundaryNormal % deviceData, &
                                                           this % fluxDivergence % interior % deviceData, &
                                                           this % flux % nvar, &
                                                           this % flux % nelem)
        ELSE
          CALL this % flux % interp % VectorDGDivergence_2D(this % flux % interior % hostData, &
                                                           this % solution % interior % hostData, &
                                                           this % compVelocity % interior % hostData, &
                                                           this % flux % boundaryNormal % hostData, &
                                                           this % fluxDivergence % interior % hostData, &
                                                           this % flux % nvar, &
                                                           this % flux % nelem)
        END IF

      ELSE ! Conservative Form

        CALL this % flux % Divergence(this % geometry, &
                                      this % fluxDivergence, &
                                      selfWeakDGForm,&
                                      this % gpuAccel)
      ENDIF

  END SUBROUTINE CalculateFluxDivergence_Model2D

  SUBROUTINE CalculateTendency_Model2D(this)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this
    ! Local
    INTEGER :: i, j, iVar, iEl

!      CALL this % solution % AverageSides()
!      CALL this % solution % DiffSides()
      CALL this % PreTendency()
      CALL this % solution % BoundaryInterp(this % gpuAccel)
      CALL this % SetBoundaryCondition()
      CALL this % SourceMethod()
      CALL this % RiemannSolver()
      CALL this % FluxMethod()
      CALL this % ReprojectFlux()
      CALL this % CalculateFluxDivergence()

    IF( this % gpuAccel )THEN

      CALL CalculateDSDt_Model2D_gpu_wrapper( this % fluxDivergence % interior % deviceData, &
                                      this % source % interior % deviceData, &
                                      this % dSdt % interior % deviceData, &
                                      this % solution % interp % N, &
                                      this % solution % nVar, &
                                      this % solution % nElem ) 
                                      
    ELSE

      DO iEl = 1, this % solution % nElem
        DO iVar = 1, this % solution % nVar
          DO j = 0, this % solution % interp % N
            DO i = 0, this % solution % interp % N

              this % dSdt % interior % hostData(i,j,iVar,iEl) = &
                      this % source % interior % hostData(i,j,iVar,iEl) -&
                      this % fluxDivergence % interior % hostData(i,j,iVar,iEl)

            ENDDO
          ENDDO
        ENDDO
      ENDDO

    ENDIF

  END SUBROUTINE CalculateTendency_Model2D

  SUBROUTINE Write_Model2D(this,fileName)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(in) :: this
    CHARACTER(*),OPTIONAL,INTENT(in) :: fileName
    ! Local
    INTEGER(HID_T) :: fileId
    INTEGER(HID_T) :: solOffset(1:4)
    INTEGER(HID_T) :: xOffset(1:5)
    INTEGER(HID_T) :: bOffset(1:4)
    INTEGER(HID_T) :: bxOffset(1:5)
    INTEGER(HID_T) :: solGlobalDims(1:4)
    INTEGER(HID_T) :: xGlobalDims(1:5)
    INTEGER(HID_T) :: bGlobalDims(1:4)
    INTEGER(HID_T) :: bxGlobalDims(1:5)
    INTEGER :: firstElem
    ! Local
    CHARACTER(LEN=self_FileNameLength) :: pickupFile
    CHARACTER(13) :: timeStampString

    IF( PRESENT(filename) )THEN
      pickupFile = filename
    ELSE
      timeStampString = TimeStamp(this % t, 's')
      pickupFile = 'solution.'//timeStampString//'.h5'
    ENDIF

    IF (this % decomp % mpiEnabled) THEN

      CALL Open_HDF5(pickupFile,H5F_ACC_TRUNC_F,fileId,this % decomp % mpiComm)

      firstElem = this % decomp % offsetElem % hostData(this % decomp % rankId)
      solOffset(1:4) = (/0,0,1,firstElem/)
      solGlobalDims(1:4) = (/this % solution % interp % N, &
                             this % solution % interp % N, &
                             this % solution % nVar, &
                             this % decomp % nElem/)


      xOffset(1:5) = (/1,0,0,1,firstElem/)
      xGlobalDims(1:5) = (/2, &
                           this % solution % interp % N, &
                           this % solution % interp % N, &
                           this % solution % nVar, &
                           this % decomp % nElem/)

      ! Offsets and dimensions for element boundary data
      bOffset(1:4) = (/0,1,1,firstElem/)
      bGlobalDims(1:4) = (/this % solution % interp % N, &
                           this % solution % nVar, &
                           4,&
                           this % decomp % nElem/)

      bxOffset(1:5) = (/1,0,1,1,firstElem/)
      bxGlobalDims(1:5) = (/2,&
                           this % solution % interp % N, &
                           this % solution % nVar, &
                           4,&
                           this % decomp % nElem/)

      
      CALL CreateGroup_HDF5(fileId,'/quadrature')

      IF( this % decomp % rankId == 0 )THEN
        CALL WriteArray_HDF5(fileId,'/quadrature/xi', &
                             this % solution % interp % controlPoints)

        CALL WriteArray_HDF5(fileId,'/quadrature/weights', &
                             this % solution % interp % qWeights)

        CALL WriteArray_HDF5(fileId,'/quadrature/dgmatrix', &
                             this % solution % interp % dgMatrix)

        CALL WriteArray_HDF5(fileId,'/quadrature/dmatrix', &
                             this % solution % interp % dMatrix)
      ENDIF

      CALL CreateGroup_HDF5(fileId,'/state')

      CALL CreateGroup_HDF5(fileId,'/state/interior')

      CALL CreateGroup_HDF5(fileId,'/state/boundary')

      CALL CreateGroup_HDF5(fileId,'/mesh')

      CALL CreateGroup_HDF5(fileId,'/mesh/interior')

      CALL CreateGroup_HDF5(fileId,'/mesh/boundary')

      CALL WriteArray_HDF5(fileId,'/state/interior/solution', &
                           this % solution % interior,solOffset,solGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solution', &
                           this % solution % boundary,bOffset,bGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/interior/fluxDivergence', &
                           this % fluxDivergence % interior,solOffset,solGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/interior/flux', &
                           this % flux % interior,xOffset,xGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/boundary/flux', &
                           this % flux % boundary,bxOffset,bxGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/interior/solutionGradient', &
                           this % solutionGradient % interior,xOffset,xGlobalDims)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solutionGradient', &
                           this % solutionGradient % boundary,bxOffset,bxGlobalDims)

      CALL WriteArray_HDF5(fileId,'/mesh/interior/x', &
                           this % geometry % x % interior,xOffset,xGlobalDims)

      CALL WriteArray_HDF5(fileId,'/mesh/boundary/x', &
                           this % geometry % x % boundary,bxOffset,bxGlobalDims)

      CALL Close_HDF5(fileId)

    ELSE

      CALL Open_HDF5(pickupFile,H5F_ACC_TRUNC_F,fileId)

      CALL CreateGroup_HDF5(fileId,'/quadrature')

      CALL WriteArray_HDF5(fileId,'/quadrature/xi', &
                           this % solution % interp % controlPoints)

      CALL WriteArray_HDF5(fileId,'/quadrature/weights', &
                           this % solution % interp % qWeights)

      CALL WriteArray_HDF5(fileId,'/quadrature/dgmatrix', &
                           this % solution % interp % dgMatrix)

      CALL WriteArray_HDF5(fileId,'/quadrature/dmatrix', &
                           this % solution % interp % dMatrix)

      CALL CreateGroup_HDF5(fileId,'/state')

      CALL CreateGroup_HDF5(fileId,'/state/interior')

      CALL CreateGroup_HDF5(fileId,'/state/boundary')

      CALL CreateGroup_HDF5(fileId,'/mesh')

      CALL CreateGroup_HDF5(fileId,'/mesh/interior')

      CALL CreateGroup_HDF5(fileId,'/mesh/boundary')

      CALL WriteArray_HDF5(fileId,'/state/interior/solution',this % solution % interior)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solution',this % solution % boundary)

      CALL WriteArray_HDF5(fileId,'/state/interior/fluxDivergence',this % fluxDivergence % interior)

      CALL WriteArray_HDF5(fileId,'/state/interior/flux',this % flux % interior)

      CALL WriteArray_HDF5(fileId,'/state/boundary/flux',this % flux % boundary)

      CALL WriteArray_HDF5(fileId,'/state/interior/solutionGradient',this % solutionGradient % interior)

      CALL WriteArray_HDF5(fileId,'/state/boundary/solutionGradient',this % solutionGradient % boundary)

      CALL WriteArray_HDF5(fileId,'/mesh/interior/x',this % geometry % x % interior)

      CALL WriteArray_HDF5(fileId,'/mesh/boundary/x',this % geometry % x % boundary)

      CALL Close_HDF5(fileId)

    END IF

  END SUBROUTINE Write_Model2D

  SUBROUTINE Read_Model2D(this,fileName)
    IMPLICIT NONE
    CLASS(Model2D),INTENT(inout) :: this
    CHARACTER(*),INTENT(in) :: fileName
    ! Local
    INTEGER(HID_T) :: fileId
    INTEGER(HID_T) :: solOffset(1:4)
    INTEGER :: firstElem
    INTEGER :: N

    IF (this % decomp % mpiEnabled) THEN
      CALL Open_HDF5(fileName,H5F_ACC_RDWR_F,fileId, &
                     this % decomp % mpiComm)
    ELSE
      CALL Open_HDF5(fileName,H5F_ACC_RDWR_F,fileId)
    END IF

    CALL ReadAttribute_HDF5(fileId,'N',N)

    IF (this % solution % interp % N /= N) THEN
      STOP 'Error : Solution polynomial degree does not match input file'
    END IF

    IF (this % decomp % mpiEnabled) THEN
      firstElem = this % decomp % offsetElem % hostData(this % decomp % rankId) + 1
      solOffset(1:4) = (/0,0,1,firstElem/)
      CALL ReadArray_HDF5(fileId,'/state/interior/solution', &
                          this % solution % interior,solOffset)
    ELSE
      CALL ReadArray_HDF5(fileId,'/state/interior/solution',this % solution % interior)
    END IF

    CALL Close_HDF5(fileId)

  END SUBROUTINE Read_Model2D

  SUBROUTINE WriteTecplot_Model2D(this, filename)
    IMPLICIT NONE
    CLASS(Model2D), INTENT(inout) :: this
    CHARACTER(*), INTENT(in), OPTIONAL :: filename
    ! Local
    CHARACTER(8) :: zoneID
    INTEGER :: fUnit
    INTEGER :: iEl, i, j 
    CHARACTER(LEN=self_FileNameLength) :: tecFile
    CHARACTER(13) :: timeStampString
    CHARACTER(5) :: rankString
    TYPE(Scalar2D) :: solution
    TYPE(Vector2D) :: x
    TYPE(Lagrange),TARGET :: interp

    IF( PRESENT(filename) )THEN
      tecFile = filename
    ELSE
      timeStampString = TimeStamp(this % t, 's')

      IF( this % decomp % mpiEnabled )THEN
        WRITE(rankString,'(I5.5)') this % decomp % rankId 
        tecFile = 'solution.'//rankString//'.'//timeStampString//'.tec'
      ELSE
        tecFile = 'solution.'//timeStampString//'.tec'
      ENDIF

    ENDIF
                      
    IF( this % gpuAccel )THEN
      ! Copy data to the CPU
      CALL this % solution % interior % UpdateHost()
    ENDIF

    ! Create an interpolant for the uniform grid
    CALL interp % Init(this % solution % interp % M,&
            this % solution % interp % targetNodeType,&
            this % solution % interp % N, &
            this % solution % interp % controlNodeType)

    CALL solution % Init( interp, &
            this % solution % nVar, this % solution % nElem )

    CALL x % Init( interp, 1, this % solution % nElem )

    ! Map the mesh positions to the target grid
    CALL this % geometry % x % GridInterp(x, gpuAccel=.FALSE.)

    ! Map the solution to the target grid
    CALL this % solution % GridInterp(solution,gpuAccel=.FALSE.)
   
    ! Let's write some tecplot!! 
     OPEN( UNIT=NEWUNIT(fUnit), &
      FILE= TRIM(tecFile), &
      FORM='formatted', &
      STATUS='replace')

    ! TO DO :: Create header from solution metadata 
    WRITE(fUnit,*) 'VARIABLES = "X", "Y","solution"'

    DO iEl = 1, this % solution % nElem

      ! TO DO :: Get the global element ID 
      WRITE(zoneID,'(I8.8)') iEl
      WRITE(fUnit,*) 'ZONE T="el'//trim(zoneID)//'", I=',this % solution % interp % M+1,&
                                                 ', J=',this % solution % interp % M+1

      DO j = 0, this % solution % interp % M
        DO i = 0, this % solution % interp % M

          WRITE(fUnit,'(3(E15.7,1x))') x % interior % hostData(1,i,j,1,iEl), &
                                       x % interior % hostData(2,i,j,1,iEl), &
                                       solution % interior % hostData(i,j,1,iEl)

        ENDDO
      ENDDO

    ENDDO

    CLOSE(UNIT=fUnit)

    CALL x % Free()
    CALL solution % Free() 
    CALL interp % Free()

  END SUBROUTINE WriteTecplot_Model2D

END MODULE SELF_Model
