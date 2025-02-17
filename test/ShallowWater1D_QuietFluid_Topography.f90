PROGRAM ShallowWater_QuietFluid

USE SELF_Constants
USE SELF_Lagrange
USE SELF_Mesh
USE SELF_Geometry
USE SELF_ShallowWater1D
USE SELF_CLI

  IMPLICIT NONE

  INTEGER, PARAMETER :: nvar = 2 ! The number prognostic variables
  INTEGER, PARAMETER :: nX = 10
  REAL(prec), PARAMETER :: tolerance=1000.0_prec*epsilon(1.0_prec) ! Error tolerance

  REAL(prec) :: dt
  REAL(prec) :: ioInterval
  REAL(prec) :: tn
  INTEGER :: N ! Control Degree
  INTEGER :: M ! Target degree
  INTEGER :: quadrature
  CHARACTER(LEN=self_QuadratureTypeCharLength) :: qChar
  LOGICAL :: mpiRequested
  LOGICAL :: gpuRequested
  integer :: i

  REAL(prec) :: referenceEntropy
  REAL(prec) :: solutionMax(1:2)
  TYPE(Lagrange),TARGET :: interp
  TYPE(Mesh1D),TARGET :: mesh
  TYPE(Geometry1D),TARGET :: geometry
  TYPE(ShallowWater1D),TARGET :: semModel
  TYPE(MPILayer),TARGET :: decomp
  TYPE(CLI) :: args
  CHARACTER(LEN=SELF_EQUATION_LENGTH) :: initialCondition(1:nvar)
  CHARACTER(LEN=SELF_EQUATION_LENGTH) :: topography
  CHARACTER(LEN=255) :: SELF_PREFIX

    CALL get_environment_variable("SELF_PREFIX", SELF_PREFIX)
    CALL args % Init( TRIM(SELF_PREFIX)//"/etc/cli/default.json")
    CALL args % LoadFromCLI()

    CALL args % Get_CLI('--output-interval',ioInterval)
    CALL args % Get_CLI('--end-time',tn)
    CALL args % Get_CLI('--time-step',dt)
    CALL args % Get_CLI('--mpi',mpiRequested)
    CALL args % Get_CLI('--gpu',gpuRequested)
    CALL args % Get_CLI('--control-degree',N)
    CALL args % Get_CLI('--control-quadrature',qChar)
    quadrature = GetIntForChar(qChar)
    CALL args % Get_CLI('--target-degree',M)

    ! Initialize a domain decomposition
    ! Here MPI is disabled, since scaling is currently
    ! atrocious with the uniform block mesh
    CALL decomp % Init(enableMPI=.FALSE.)

    ! Create an interpolant
    CALL interp % Init(N,quadrature,M,UNIFORM)

    ! Create a uniform block mesh
    CALL mesh % UniformBlockMesh(1,nX,(/0.0_prec,1.0_prec/))

    ! Generate a decomposition
    CALL decomp % GenerateDecomposition(mesh % nElem, 1)

    ! Generate geometry (metric terms) from the mesh elements
    CALL geometry % Init(interp,mesh % nElem)
    CALL geometry % GenerateFromMesh(mesh)

    ! Initialize the semModel
    CALL semModel % Init(nvar,mesh,geometry,decomp)

    ! Enable GPU Acceleration (if a GPU is found) !
    !CALL semModel % EnableGPUAccel()
 
    topography = "h = 1.0-0.1*exp( -(x-0.5)^2 / 0.01 )"
    CALL semModel % SetTopography(topography)
    CALL semModel % SetLakeAtRest()

    CALL semModel % CalculateEntropy()
    CALL semModel % ReportEntropy()
    referenceEntropy = semModel % entropy

    ! Write the initial condition to file
    CALL semModel % WriteModel()
    CALL semModel % WriteTecplot()

    ! Set the time integrator (euler, rk3)
    CALL semModel % SetTimeIntegrator("rk3")

    ! Set your time step
    semModel % dt = dt

    !! Forward step the semModel and do the file io
    CALL semModel % ForwardStep( tn = tn, ioInterval = ioInterval )

    !! Manually write the last semModel state
    CALL semModel % WriteModel('solution.pickup.h5')

    ! Error checking !
    IF( semModel % entropy /= semModel % entropy )THEN
      PRINT*, "Model entropy is not a number"
      STOP 2
    ENDIF

    IF( semModel % entropy >= HUGE(1.0_prec) )THEN
      PRINT*, "Model entropy is infinite."
      STOP 1
    ENDIF

    IF( semModel % entropy > referenceEntropy )THEN
      PRINT*, "Warning : final entropy greater than initial entropy"
      ! Currently do nothing in this situation, since
      ! conservative solvers in mapped geometries may
      ! not be entropy conservative.
      ! However, throwing this warning will bring some
      ! visibility
    ENDIF

    ! Check the solution !
    solutionMax = semModel % solution % AbsMaxInterior() 
    IF( solutionMax(1) > tolerance)THEN
      PRINT*, "Non-zero velocity field detected for quiescent fluid."
      PRINT*, solutionMax
!      STOP 1
    ENDIF

    ! Clean up
    CALL semModel % Free()
    CALL decomp % Free()
    CALL geometry % Free()
    CALL mesh % Free()
    CALL interp % Free()
    CALL args % Free()
    CALL decomp % Finalize()

END PROGRAM ShallowWater_QuietFluid
