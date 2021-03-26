#include <hip/hip_runtime.h>
#include "SELF_HIP_Macros.h"

/*
// Template
__global__ void Template_{1D|2D|3D}_gpu( , int N, int nVar){

  size_t iVar = hipBlockIdx_x;
  size_t iEl = hipBlockIdx_y;
  size_t i = hipThreadIdx_x;
  size_t j = hipThreadIdx_y;
  size_t k = hipThreadIdx_z;


  // How to access scalars 
  f[SC_1D_INDEX(i,iVar,iEl,N,nVar)];
  f[SC_2D_INDEX(i,j,iVar,iEl,N,nVar)];
  f[SC_3D_INDEX(i,j,k,iVar,iEl,N,nVar)];

  // How to access vectors (2d)
  f[VE_2D_INDEX(1,i,j,iVar,iEl,N,nVar)];
  f[VE_2D_INDEX(2,i,j,iVar,iEl,N,nVar)];


  // How to access vectors (3d)
  f[VE_3D_INDEX(1,i,j,k,iVar,iEl,N,nVar)];
  f[VE_3D_INDEX(2,i,j,k,iVar,iEl,N,nVar)];
  f[VE_3D_INDEX(3,i,j,k,iVar,iEl,N,nVar)];

  // How to access tensors (2d)
  f[TE_2D_INDEX(1,1,i,j,iVar,iEl,N,nVar)];
  f[TE_2D_INDEX(2,1,i,j,iVar,iEl,N,nVar)];
  f[TE_2D_INDEX(1,2,i,j,iVar,iEl,N,nVar)];
  f[TE_2D_INDEX(2,2,i,j,iVar,iEl,N,nVar)];


  // How to access tensors (3d)
  f[TE_3D_INDEX(1,1,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(2,1,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(3,1,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(1,2,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(2,2,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(3,2,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(1,3,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(2,3,i,j,k,iVar,iEl,N,nVar)];
  f[TE_3D_INDEX(3,3,i,j,k,iVar,iEl,N,nVar)];

}

extern "C"
{
  void Template_{1D|2D|3D}_gpu_wrapper(int N, int nVar)
  {
	  hipLaunchKernelGGL((Template_{1D|2D|3D}_gpu), dim3(nVar,nEl,1), dim3(N+1,N+1,N+1), 0, 0,  N, M, nVar);
  } 
}

*/
/*
__global__ void CalculateContravariantBasis_SEMQuad_gpu(real *scalar, real *dxds, int N, int nVar){

  size_t iVar = hipBlockIdx_x;
  size_t iEl = hipBlockIdx_y;
  size_t i = hipThreadIdx_x;
  size_t j = hipThreadIdx_y;

    scalar[SC_1D_INDEX(i,iVar,iEl,N,nVar)] = scalar[SC_1D_INDEX(i,iVar,iEl,N,nVar)]/
                                             dxds[SC_1D_INDEX(i,0,iEl,N,1)];
}
extern "C"
{
  void CalculateContravariantBasis_SEMQuad_gpu_wrapper(int N, int nVar)
  {
	  hipLaunchKernelGGL((CalculateContravariantBasis_SEMQuad_gpu), dim3(nVar,nEl,1), dim3(N+1,N+1,1), 0, 0,  N);
  } 
}
*/
__global__ void CalculateContravariantBasis_SEMHex_gpu(real *dxds, real *dsdx, int N){

  size_t iEl = hipBlockIdx_x;
  size_t i = hipThreadIdx_x;
  size_t j = hipThreadIdx_y;
  size_t k = hipThreadIdx_z;

    // Ja1
    dsdx[TE_3D_INDEX(1,1,i,j,k,0,iEl,N,1)] = 
	      dxds[TE_3D_INDEX(2,2,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(3,3,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(3,2,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(2,3,i,j,k,0,iEl,N,1)];

    dsdx[TE_3D_INDEX(2,1,i,j,k,0,iEl,N,1)] =
              dxds[TE_3D_INDEX(1,3,i,j,k,0,iEl,N,1)]*
              dxds[TE_3D_INDEX(3,2,i,j,k,0,iEl,N,1)]-
              dxds[TE_3D_INDEX(3,3,i,j,k,0,iEl,N,1)]*
              dxds[TE_3D_INDEX(1,2,i,j,k,0,iEl,N,1)];

    dsdx[TE_3D_INDEX(3,1,i,j,k,0,iEl,N,1)] = 
              dxds[TE_3D_INDEX(1,2,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(2,3,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(2,2,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(1,3,i,j,k,0,iEl,N,1)];

    // Ja2
    dsdx[TE_3D_INDEX(1,2,i,j,k,0,iEl,N,1)] = 
              dxds[TE_3D_INDEX(2,3,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(3,1,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(3,3,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(2,1,i,j,k,0,iEl,N,1)];

    dsdx[TE_3D_INDEX(2,2,i,j,k,0,iEl,N,1)] = 
              dxds[TE_3D_INDEX(1,1,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(3,3,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(3,1,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(1,3,i,j,k,0,iEl,N,1)];

    dsdx[TE_3D_INDEX(3,2,i,j,k,0,iEl,N,1)] = 
              dxds[TE_3D_INDEX(1,3,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(2,1,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(2,3,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(1,1,i,j,k,0,iEl,N,1)];

    // Ja3
    dsdx[TE_3D_INDEX(1,3,i,j,k,0,iEl,N,1)] = 
              dxds[TE_3D_INDEX(2,1,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(3,2,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(3,1,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(2,2,i,j,k,0,iEl,N,1)];

    dsdx[TE_3D_INDEX(2,3,i,j,k,0,iEl,N,1)] = 
              dxds[TE_3D_INDEX(1,2,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(3,1,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(3,2,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(1,1,i,j,k,0,iEl,N,1)];

    dsdx[TE_3D_INDEX(3,3,i,j,k,0,iEl,N,1)] = 
              dxds[TE_3D_INDEX(1,1,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(2,2,i,j,k,0,iEl,N,1)]- 
              dxds[TE_3D_INDEX(2,1,i,j,k,0,iEl,N,1)]* 
              dxds[TE_3D_INDEX(1,2,i,j,k,0,iEl,N,1)];
}
extern "C"
{
  void CalculateContravariantBasis_SEMHex_gpu_wrapper(real **dxds, real **dsdx, int N, int nEl)
  { 
	  hipLaunchKernelGGL((CalculateContravariantBasis_SEMHex_gpu), dim3(nEl,1,1), dim3(N+1,N+1,N+1), 0, 0, *dxds, *dsdx, N);
  } 
}
