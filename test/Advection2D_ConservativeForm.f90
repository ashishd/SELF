PROGRAM Advection_ConservativeForm_2D

USE SELF_Constants
USE SELF_Lagrange
USE SELF_Mesh
USE SELF_Geometry
USE SELF_Advection2D
USE SELF_CLI

  INTEGER, PARAMETER :: nvar = 1 ! The number of tracer fields

  REAL(prec) :: dt
  REAL(prec) :: ioInterval
  REAL(prec) :: tn
  INTEGER :: N ! Control Degree
  INTEGER :: M ! Target degree
  INTEGER :: quadrature
  CHARACTER(LEN=self_QuadratureTypeCharLength) :: qChar
  LOGICAL :: mpiRequested
  LOGICAL :: gpuRequested

  REAL(prec) :: referenceEntropy
  TYPE(Lagrange),TARGET :: interp
  TYPE(Mesh2D),TARGET :: mesh
  TYPE(SEMQuad),TARGET :: geometry
  TYPE(Advection2D),TARGET :: semModel
  TYPE(MPILayer),TARGET :: decomp
  TYPE(CLI) :: args
  CHARACTER(LEN=SELF_EQUATION_LENGTH) :: initialCondition(1:nvar)
  CHARACTER(LEN=SELF_EQUATION_LENGTH) :: velocityField(1:2)
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
    CALL decomp % Init(enableMPI=mpiRequested)

    ! Create an interpolant
    CALL interp % Init(N,quadrature,M,UNIFORM)

    ! Create a uniform block mesh
    CALL get_environment_variable("SELF_PREFIX", SELF_PREFIX)
    CALL mesh % Read_HOPr(TRIM(SELF_PREFIX)//"/etc/mesh/Block2D/Block2D_mesh.h5",decomp)

    ! Generate geometry (metric terms) from the mesh elements
    CALL geometry % Init(interp,mesh % nElem)
    CALL geometry % GenerateFromMesh(mesh)

    ! Initialize the semModel
    CALL semModel % Init(nvar,mesh,geometry,decomp)

    ! Set the solution name
    CALL semModel % solution % SetName(1,'Tracer')

    IF( gpuRequested )THEN
      ! Enable GPU Acceleration (if a GPU is found) !
      CALL semModel % EnableGPUAccel()
    ENDIF

    ! Set the velocity field
    velocityField = (/"vx=1.0","vy=1.0"/)
    CALL semModel % SetVelocityField( velocityField )

    ! Set the initial condition
    initialCondition = (/"s = exp( -( (x-0.5-t)^2 + (y-0.5-t)^2 )/0.01 )"/)
    CALL semModel % SetSolution( initialCondition )
    CALL semModel % CalculateEntropy()
    CALL semModel % ReportEntropy()
    referenceEntropy = semModel % entropy

    ! Write the initial condition to file
    CALL semModel % WriteModel()
    CALL semModel % WriteTecplot()

    ! Set the time integrator (euler, rk3, rk4)
    CALL semModel % SetTimeIntegrator("Euler")

   ! ! Set your time step
    semModel % dt = dt

   ! ! Forward step the semModel and do the file io
    CALL semModel % ForwardStep( tn = tn, ioInterval = ioInterval )

   ! ! Manually write the last semModel state
    CALL semModel % WriteModel()
    CALL semModel % WriteTecplot()

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

    ! Clean up
    CALL semModel % Free()
    CALL decomp % Free()
    CALL geometry % Free()
    CALL mesh % Free()
    CALL interp % Free()
    CALL args % Free()
    CALL decomp % Finalize()

END PROGRAM Advection_ConservativeForm_2D
