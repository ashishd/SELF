!
! Copyright 2020-2022 Fluid Numerics LLC
! Author : Joseph Schoonover (joe@fluidnumerics.com)
! Support : support@fluidnumerics.com
!
! //////////////////////////////////////////////////////////////////////////////////////////////// !
MODULE SELF_DG

  USE SELF_Metadata
  USE SELF_MPI
  USE SELF_Mesh
  USE SELF_MappedData
  USE SELF_HDF5
  USE HDF5

  TYPE,PUBLIC :: DG2D
    TYPE(MappedScalar2D),PUBLIC :: solution
    TYPE(Scalar2D),PUBLIC :: plotSolution
    TYPE(MappedVector2D),PUBLIC :: solutionGradient
    TYPE(MappedVector2D),PUBLIC :: flux
    TYPE(MappedScalar2D),PUBLIC :: source
    TYPE(MappedScalar2D),PUBLIC :: fluxDivergence
    TYPE(MappedScalar2D),PUBLIC :: dSdt
    TYPE(MPILayer),PUBLIC :: decomp
    TYPE(Mesh2D),PUBLIC :: mesh
    TYPE(SEMQuad),PUBLIC :: geometry
    TYPE(Metadata),ALLOCATABLE,PUBLIC :: solutionMetaData(:)

    ! Work arrays
    ! Can't be private to be accessible by type extensions
    ! TO DO : Really need to figure out the reuse business for the initializer...
    TYPE(MappedScalar2D) :: workScalar
    TYPE(MappedVector2D) :: workVector
    TYPE(MappedVector2D) :: compFlux
    TYPE(MappedTensor2D) :: workTensor

  CONTAINS

    PROCEDURE,PUBLIC :: Init => Init_DG2D
    PROCEDURE,PUBLIC :: Free => Free_DG2D

    PROCEDURE,PUBLIC :: UpdateHost => UpdateHost_DG2D
    PROCEDURE,PUBLIC :: UpdateDevice => UpdateDevice_DG2D

!    PROCEDURE,PUBLIC :: FluxMethod => FluxMethod_DG2D
    PROCEDURE,PUBLIC :: CalculateSolutionGradient => CalculateSolutionGradient_DG2D
    PROCEDURE,PUBLIC :: CalculateFluxDivergence => CalculateFluxDivergence_DG2D
    PROCEDURE,PUBLIC :: CalculateDSDt => CalculateDSDt_DG2D

    PROCEDURE,PUBLIC :: Read => Read_DG2D
    PROCEDURE,PUBLIC :: Write => Write_DG2D

  END TYPE DG2D

  TYPE,PUBLIC :: DG3D
    TYPE(MappedScalar3D),PUBLIC :: solution
    TYPE(Scalar3D),PUBLIC :: plotSolution
    TYPE(MappedVector3D),PUBLIC :: solutionGradient
    TYPE(MappedVector3D),PUBLIC :: flux
    TYPE(MappedScalar3D),PUBLIC :: source
    TYPE(MappedScalar3D),PUBLIC :: fluxDivergence
    TYPE(MappedScalar3D),PUBLIC :: dSdt
    TYPE(MPILayer),PUBLIC :: decomp
    TYPE(Mesh3D),PUBLIC :: mesh
    TYPE(SEMHex),PUBLIC :: geometry
    TYPE(Metadata),ALLOCATABLE,PUBLIC :: solutionMetaData(:)

    ! Work arrays
    TYPE(MappedScalar3D) :: workScalar
    TYPE(MappedVector3D) :: workVector
    TYPE(MappedVector3D) :: compFlux
    TYPE(MappedTensor3D) :: workTensor

  CONTAINS

    PROCEDURE,PUBLIC :: Init => Init_DG3D
    PROCEDURE,PUBLIC :: Free => Free_DG3D

    PROCEDURE,PUBLIC :: UpdateHost => UpdateHost_DG3D
    PROCEDURE,PUBLIC :: UpdateDevice => UpdateDevice_DG3D

    PROCEDURE,PUBLIC :: CalculateSolutionGradient => CalculateSolutionGradient_DG3D
    PROCEDURE,PUBLIC :: CalculateFluxDivergence => CalculateFluxDivergence_DG3D
    PROCEDURE,PUBLIC :: CalculateDSDt => CalculateDSDt_DG3D

    PROCEDURE,PUBLIC :: Read => Read_DG3D
    PROCEDURE,PUBLIC :: Write => Write_DG3D

  END TYPE DG3D

  INTEGER,PARAMETER :: SELF_DG_BASSIREBAY = 100

  INTERFACE
    SUBROUTINE CalculateDSDt_DG2D_gpu_wrapper(fluxDivergence, source, dSdt, N, nVar, nEl) &
      bind(c,name="CalculateDSDt_DG2D_gpu_wrapper")
      USE iso_c_binding
      IMPLICIT NONE
      TYPE(c_ptr) :: fluxDivergence, source, dSdt
      INTEGER(C_INT),VALUE :: N,nVar,nEl
    END SUBROUTINE CalculateDSDt_DG2D_gpu_wrapper
  END INTERFACE

  INTERFACE
    SUBROUTINE CalculateDSDt_DG3D_gpu_wrapper(fluxDivergence, source, dSdt, N, nVar, nEl) &
      bind(c,name="CalculateDSDt_DG3D_gpu_wrapper")
      USE iso_c_binding
      IMPLICIT NONE
      TYPE(c_ptr) :: fluxDivergence, source, dSdt
      INTEGER(C_INT),VALUE :: N,nVar,nEl
    END SUBROUTINE CalculateDSDt_DG3D_gpu_wrapper
  END INTERFACE

CONTAINS

  SUBROUTINE Init_DG2D(this,interp,nvar,enableMPI,spec)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(out) :: this
    INTEGER,INTENT(in) :: cqType
    INTEGER,INTENT(in) :: tqType
    INTEGER,INTENT(in) :: cqDegree
    INTEGER,INTENT(in) :: tqDegree
    INTEGER,INTENT(in) :: nvar
    LOGICAL,INTENT(in) :: enableMPI
    TYPE(MeshSpec),INTENT(in) :: spec

    CALL this % decomp % Init(enableMPI)

    ! Load Mesh
    CALL this % mesh % Load(spec,this % decomp)

    CALL this % decomp % SetMaxMsg(this % mesh % nUniqueSides)

    CALL this % decomp % setElemToRank(this % mesh % nElem)

    ! Create geometry from mesh
    CALL this % geometry % GenerateFromMesh(this % mesh,cqType,tqType,cqDegree,tqDegree)

    CALL this % solution % Init(interp,nVar,this % mesh % nElem)
    CALL this % plotSolution % Init(tqDegree,tqType,tqDegree,tqType,nVar,this % mesh % nElem)
    CALL this % dSdt % Init(interp,nVar,this % mesh % nElem)
    CALL this % solutionGradient % Init(interp,nVar,this % mesh % nElem)
    CALL this % flux % Init(interp,nVar,this % mesh % nElem)
    CALL this % source % Init(interp,nVar,this % mesh % nElem)
    CALL this % fluxDivergence % Init(interp,nVar,this % mesh % nElem)

    CALL this % workScalar % Init(interp,nVar,this % mesh % nElem)
    CALL this % workVector % Init(interp,nVar,this % mesh % nElem)
    CALL this % workTensor % Init(interp,nVar,this % mesh % nElem)
    CALL this % compFlux % Init(interp,nVar,this % mesh % nElem)

    ALLOCATE (this % solutionMetaData(1:nvar))

  END SUBROUTINE Init_DG2D

  SUBROUTINE Free_DG2D(this)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(inout) :: this

    CALL this % mesh % Free()
    CALL this % geometry % Free()
    CALL this % solution % Free()
    CALL this % plotSolution % Free()
    CALL this % dSdt % Free()
    CALL this % solutionGradient % Free()
    CALL this % flux % Free()
    CALL this % source % Free()
    CALL this % fluxDivergence % Free()
    CALL this % workScalar % Free()
    CALL this % workVector % Free()
    CALL this % workTensor % Free()
    CALL this % compFlux % Free()
    DEALLOCATE (this % solutionMetaData)

  END SUBROUTINE Free_DG2D

  SUBROUTINE UpdateHost_DG2D(this)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(inout) :: this

    CALL this % mesh % UpdateHost()
    CALL this % geometry % UpdateHost()
    CALL this % solution % UpdateHost()
    CALL this % plotSolution % UpdateHost()
    CALL this % dSdt % UpdateHost()
    CALL this % solutionGradient % UpdateHost()
    CALL this % flux % UpdateHost()
    CALL this % source % UpdateHost()
    CALL this % fluxDivergence % UpdateHost()
    CALL this % workScalar % UpdateHost()
    CALL this % workVector % UpdateHost()
    CALL this % workTensor % UpdateHost()
    CALL this % compFlux % UpdateHost()

  END SUBROUTINE UpdateHost_DG2D

  SUBROUTINE UpdateDevice_DG2D(this)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(inout) :: this

    CALL this % mesh % UpdateDevice()
    CALL this % geometry % UpdateDevice()
    CALL this % plotSolution % UpdateDevice()
    CALL this % dSdt % UpdateDevice()
    CALL this % solutionGradient % UpdateDevice()
    CALL this % flux % UpdateDevice()
    CALL this % source % UpdateDevice()
    CALL this % fluxDivergence % UpdateDevice()
    CALL this % workScalar % UpdateDevice()
    CALL this % workVector % UpdateDevice()
    CALL this % workTensor % UpdateDevice()
    CALL this % compFlux % UpdateDevice()

  END SUBROUTINE UpdateDevice_DG2D

  SUBROUTINE CalculateSolutionGradient_DG2D(this,gpuAccel)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(inout) :: this
    LOGICAL,INTENT(in) :: gpuAccel

    CALL this % solution % BassiRebaySides(gpuAccel)

    CALL this % solution % Gradient(this % workTensor, &
                                    this % geometry, &
                                    this % solutionGradient, &
                                    selfWeakDGForm,gpuAccel)

  END SUBROUTINE CalculateSolutionGradient_DG2D

  SUBROUTINE CalculateFluxDivergence_DG2D(this,gpuAccel)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(inout) :: this
    LOGICAL,INTENT(in) :: gpuAccel

    CALL this % flux % Divergence(this % geometry, &
                                  this % fluxDivergence, &
                                  selfWeakDGForm,gpuAccel)

  END SUBROUTINE CalculateFluxDivergence_DG2D

  SUBROUTINE CalculateDSDt_DG2D(this,gpuAccel)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(inout) :: this
    LOGICAL,INTENT(in) :: gpuAccel
    ! Local
    INTEGER :: i, j, k, iVar, iEl

    IF( gpuAccel )THEN

      CALL CalculateDSDt_DG2D_gpu_wrapper( this % fluxDivergence % interior % deviceData, &
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

  END SUBROUTINE CalculateDSDt_DG2D

  SUBROUTINE Write_DG2D(this,fileName)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(in) :: this
    CHARACTER(*),INTENT(in) :: fileName
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

    IF (this % decomp % mpiEnabled) THEN

      CALL Open_HDF5(fileName,H5F_ACC_TRUNC_F,fileId,this % decomp % mpiComm)

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

      CALL Open_HDF5(fileName,H5F_ACC_TRUNC_F,fileId)

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

  END SUBROUTINE Write_DG2D

  SUBROUTINE Read_DG2D(this,fileName)
    IMPLICIT NONE
    CLASS(DG2D),INTENT(inout) :: this
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

  END SUBROUTINE Read_DG2D

  SUBROUTINE Init_DG3D(this,cqType,tqType,cqDegree,tqDegree,nvar,enableMPI,spec)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(out) :: this
    INTEGER,INTENT(in) :: cqType
    INTEGER,INTENT(in) :: tqType
    INTEGER,INTENT(in) :: cqDegree
    INTEGER,INTENT(in) :: tqDegree
    INTEGER,INTENT(in) :: nvar
    LOGICAL,INTENT(in) :: enableMPI
    TYPE(MeshSpec),INTENT(in) :: spec

    CALL this % decomp % Init(enableMPI)

    ! Load Mesh
    CALL this % mesh % Load(spec,this % decomp)

    CALL this % decomp % SetMaxMsg(this % mesh % nUniqueSides)

    ! Create geometry from mesh
    CALL this % geometry % GenerateFromMesh(this % mesh,cqType,tqType,cqDegree,tqDegree)

    CALL this % solution % Init(interp,nVar,this % mesh % nElem)
    CALL this % dSdt % Init(interp,nVar,this % mesh % nElem)
    CALL this % solutionGradient % Init(interp,nVar,this % mesh % nElem)
    CALL this % flux % Init(interp,nVar,this % mesh % nElem)
    CALL this % source % Init(interp,nVar,this % mesh % nElem)
    CALL this % fluxDivergence % Init(interp,nVar,this % mesh % nElem)

    CALL this % workScalar % Init(interp,nVar,this % mesh % nElem)
    CALL this % workVector % Init(interp,nVar,this % mesh % nElem)
    CALL this % workTensor % Init(interp,nVar,this % mesh % nElem)
    CALL this % compFlux % Init(interp,nVar,this % mesh % nElem)

    ALLOCATE (this % solutionMetaData(1:nvar))

  END SUBROUTINE Init_DG3D

  SUBROUTINE Free_DG3D(this)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(inout) :: this

    CALL this % mesh % Free()
    CALL this % geometry % Free()
    CALL this % solution % Free()
    CALL this % dSdt % Free()
    CALL this % solutionGradient % Free()
    CALL this % flux % Free()
    CALL this % source % Free()
    CALL this % fluxDivergence % Free()
    CALL this % workScalar % Free()
    CALL this % workVector % Free()
    CALL this % workTensor % Free()
    CALL this % compFlux % Free()
    DEALLOCATE (this % solutionMetaData)

  END SUBROUTINE Free_DG3D

  SUBROUTINE UpdateHost_DG3D(this)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(inout) :: this

    CALL this % mesh % UpdateHost()
    CALL this % geometry % UpdateHost()
    CALL this % solution % UpdateHost()
    CALL this % dSdt % UpdateHost()
    CALL this % solutionGradient % UpdateHost()
    CALL this % flux % UpdateHost()
    CALL this % source % UpdateHost()
    CALL this % fluxDivergence % UpdateHost()
    CALL this % workScalar % UpdateHost()
    CALL this % workVector % UpdateHost()
    CALL this % workTensor % UpdateHost()
    CALL this % compFlux % UpdateHost()

  END SUBROUTINE UpdateHost_DG3D

  SUBROUTINE UpdateDevice_DG3D(this)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(inout) :: this

    CALL this % mesh % UpdateDevice()
    CALL this % geometry % UpdateDevice()
    CALL this % solution % UpdateDevice()
    CALL this % dSdt % UpdateDevice()
    CALL this % solutionGradient % UpdateDevice()
    CALL this % flux % UpdateDevice()
    CALL this % source % UpdateDevice()
    CALL this % fluxDivergence % UpdateDevice()
    CALL this % workScalar % UpdateDevice()
    CALL this % workVector % UpdateDevice()
    CALL this % workTensor % UpdateDevice()
    CALL this % compFlux % UpdateDevice()

  END SUBROUTINE UpdateDevice_DG3D

  SUBROUTINE CalculateSolutionGradient_DG3D(this,gpuAccel)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(inout) :: this
    LOGICAL,INTENT(in) :: gpuAccel

    CALL this % solution % BassiRebaySides(gpuAccel)

    CALL this % solution % Gradient(this % workTensor, &
                                    this % geometry, &
                                    this % solutionGradient, &
                                    selfWeakDGForm,gpuAccel)

  END SUBROUTINE CalculateSolutionGradient_DG3D

  SUBROUTINE CalculateFluxDivergence_DG3D(this,gpuAccel)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(inout) :: this
    LOGICAL,INTENT(in) :: gpuAccel

    CALL this % flux % Divergence(this % geometry, &
                                  this % fluxDivergence, &
                                  selfWeakDGForm,gpuAccel)

  END SUBROUTINE CalculateFluxDivergence_DG3D

  SUBROUTINE CalculateDSDt_DG3D(this,gpuAccel)
    !! Adds the flux convergence and source terms together and assigns to dSdt
    IMPLICIT NONE
    CLASS(DG3D),INTENT(inout) :: this
    LOGICAL,INTENT(in) :: gpuAccel
    ! Local
    INTEGER :: i, j, k, iVar, iEl

    IF( gpuAccel )THEN

      CALL CalculateDSDt_DG3D_gpu_wrapper( this % fluxDivergence % interior % deviceData, &
                                      this % source % interior % deviceData, &
                                      this % dSdt % interior % deviceData, &
                                      this % solution % interp % N, &
                                      this % solution % nVar, &
                                      this % solution % nElem ) 
                                      
    ELSE

      DO iEl = 1, this % solution % nElem
        DO iVar = 1, this % solution % nVar
          DO k = 0, this % solution % interp % N
            DO j = 0, this % solution % interp % N
              DO i = 0, this % solution % interp % N

                this % dSdt % interior % hostData(i,j,k,iVar,iEl) = &
                        this % source % interior % hostData(i,j,k,iVar,iEl) -&
                        this % fluxDivergence % interior % hostData(i,j,k,iVar,iEl)

              ENDDO
            ENDDO
          ENDDO
        ENDDO
      ENDDO

    ENDIF

  END SUBROUTINE CalculateDSDt_DG3D

  SUBROUTINE Write_DG3D(this,fileName)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(in) :: this
    CHARACTER(*),INTENT(in) :: fileName
    ! Local
    INTEGER(HID_T) :: fileId
    INTEGER(HID_T) :: solOffset(1:5)
    INTEGER(HID_T) :: xOffset(1:6)
    INTEGER(HID_T) :: bOffset(1:5)
    INTEGER(HID_T) :: bxOffset(1:6)
    INTEGER(HID_T) :: solGlobalDims(1:5)
    INTEGER(HID_T) :: xGlobalDims(1:6)
    INTEGER(HID_T) :: bGlobalDims(1:5)
    INTEGER(HID_T) :: bxGlobalDims(1:6)
    INTEGER :: firstElem

    IF (this % decomp % mpiEnabled) THEN

      CALL Open_HDF5(fileName,H5F_ACC_TRUNC_F,fileId, &
                     this % decomp % mpiComm)

      firstElem = this % decomp % offsetElem % hostData(this % decomp % rankId)
      solOffset(1:5) = (/0,0,0,1,firstElem/)
      solGlobalDims(1:5) = (/this % solution % interp % N, &
                             this % solution % interp % N, &
                             this % solution % interp % N, &
                             this % solution % nVar, &
                             this % decomp % nElem/)
      xOffset(1:6) = (/1,0,0,0,1,firstElem/)
      xGlobalDims(1:6) = (/3, &
                           this % solution % interp % N, &
                           this % solution % interp % N, &
                           this % solution % interp % N, &
                           this % solution % nVar, &
                           this % decomp % nElem/)

      ! Offsets and dimensions for element boundary data
      bOffset(1:5) = (/0,0,1,1,firstElem/)
      bGlobalDims(1:5) = (/this % solution % interp % N, &
                           this % solution % interp % N, &
                           this % solution % nVar, &
                           6,&
                           this % decomp % nElem/)

      bxOffset(1:6) = (/1,0,0,1,1,firstElem/)
      bxGlobalDims(1:6) = (/3,&
                           this % solution % interp % N, &
                           this % solution % interp % N, &
                           this % solution % nVar, &
                           6,&
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

      CALL Open_HDF5(fileName,H5F_ACC_TRUNC_F,fileId)

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

  END SUBROUTINE Write_DG3D

  SUBROUTINE Read_DG3D(this,fileName)
    IMPLICIT NONE
    CLASS(DG3D),INTENT(inout) :: this
    CHARACTER(*),INTENT(in) :: fileName
    ! Local
    INTEGER(HID_T) :: fileId
    INTEGER(HID_T) :: solOffset(1:5)
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
      solOffset(1:5) = (/0,0,0,1,firstElem/)
      CALL ReadArray_HDF5(fileId,'/state/interior/solution',this % solution % interior,solOffset)
    ELSE
      CALL ReadArray_HDF5(fileId,'/state/interior/solution',this % solution % interior)
    END IF

    CALL Close_HDF5(fileId)

  END SUBROUTINE Read_DG3D

END MODULE SELF_DG
