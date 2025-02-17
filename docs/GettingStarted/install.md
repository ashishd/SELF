# Install SELF
The Spectral Element Library in Fortran can be built provided the following dependencies are met

* Fortran 2008 compliant compiler
* MPI, e.g. [OpenMPI](https://www.open-mpi.org/)
* [GNU Make](https://www.gnu.org/software/make/)
* [ROCm](https://rocmdocs.amd.com/en/latest/Installation_Guide/Installation-Guide.html) ( >= 4.2 )
* [HIPFort](https://github.com/ROCmSoftwarePlatform/hipfort) ( >= 4.2 ; Must be built with the Fortran compiler you will build SELF with. )
* [HDF5](https://www.hdfgroup.org/solutions/hdf5/)
* [FEQParse](https://github.com/FluidNumerics/feq-parse)
* [FLAP](https://github.com/szaghi/FLAP)
* [JSON-Fortran](https://github.com/jacobwilliams/json-fortran)


## Bare Metal Install

### Install SELF Dependencies
Before getting started, make sure that you the following installed on your system : 

* C++ Compiler (`g++` recommended)
* Fortran Compiler (`gfortran` recommended)
* GNU Make
* [ROCm](https://rocmdocs.amd.com/en/latest/Installation_Guide/Installation-Guide.html)

Keep in mind that ROCm is officially supported only on CentOS, RHEL, Ubuntu, and SLES 15.

On Ubuntu, you can install these dependencies using the following

```
sudo apt-get update
sudo apt-get install gcc g++ gfortran build-essential libnuma-dev
sudo apt install wget gnupg2
wget -q -O - https://repo.radeon.com/rocm/rocm.gpg.key | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/5.2/ ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
sudo apt install rocm-dev
sudo reboot
```


To help install the remainder of SELF's dependencies, we recommend that you use [Spack](https://spack.io). SELF comes with a Spack environment file that can be used to create a spack environment on your system.

First, install Spack

```
git clone https://github.com/spack/spack ~/spack
source ~/spack/share/spack/setup-env.sh
```

Download the SELF source code and activate the spack environment

```
git clone https://github.com/fluidnumerics/SELF ~/SELF
spack env activate -d ~/SELF/env
```

Once the environment is activated, show which packages will be installed and verify the output appears like what is shown below

```
$ spack find
==> In environment /home/joe/SELF/env
==> Root specs
feq-parse@1.1.0  flap@master  hdf5@1.12.0 +cxx+fortran+mpi  hipfort@4.5.2  json-fortran@7.1.0

==> 0 installed packages
```

Next, you can install the dependencies

```
spack install
```

Keep in mind, this installation process can take up to two hours.

### Install SELF
SELF comes with a [simple bash script](https://github.com/FluidNumerics/SELF/blob/main/install.sh) that can be used to install SELF. Provided you followed the steps above to install SELF dependencies, you can simply run this script.

```
cd ~/SELF
./install.sh
```

This will install SELF under `${HOME}/view/self`. By default, this script is configured to build with serial, MPI, and GPU support with the target GPU set to AMD MI100 (`gfx900`). To change the behavior of the installation script, you can set the following environment variables before calling the script

* `VIEW` - The path to the spack environment view.
* `SELF_PREFIX` - The path to install SELF. Defaults to `$VIEW`
* `GPU_TARGET` - GPU microarchitecture code to build for. Defaults to `gfx900` (AMD MI100)
* `PREC` - Floating point precision to build with. Defaults to `double`. Change to `single` to build using 32-bit floating point arithmetic.
* `SELF_FFLAGS` - compiler flags to build SELF.


## Build a Docker Container
SELF comes with a Dockerfile to create builds that target specific GPU platforms. To build Docker containers, you will need to install [Docker](https://www.docker.com/). 

### Build with Cloud-Build-Local (Recommended)
To build a Docker container with SELF pre-installed, the SELF repository comes with a Cloud Build pipeline for use on your local system. This pipeline will execute `docker run` with the appropriate Dockerfile, depending on the target GPU architecture specified in the build substitutions. To use cloud-build-local, you will need to install [Docker](https://www.docker.com/), the [gcloud CLI, and google-cloud-sdk-cloud-build-local](https://cloud.google.com/sdk/docs/install).

Once installed, you can simply build SELF using the following command from the root of the SELF repository.

```
cloud-build-local --config=ci/cloudbuild.local.yaml --dryrun=false .
```

By default, this will build SELF with double precision floating point arithmetic, no optimizations (debug build), and with GPU kernels offloaded to Nvidia V100 GPUs. You can customize the behavior of the build process by using build substitutions. The following build substitution variables are currently available

* `_PREC` : The floating point precision to use in SELF; either `single` or `double`
* `_GPU_TARGET`: GPU microarchitecture code to build for. Defaults to `sm_72` (Nvidia V100)
* `_HIP_PLATFORM`: The value to set for the `HIP_PLATFORM` environment variable. Either `nvidia` or `amd`
* `_FFLAGS` : The compiler flags to send to the fortran compiler.

As an example, you can specify these substitution variables using something like the following

```
cloud-build-local --config=ci/cloudbuild.local.yaml --dryrun=false . --substitutions=_PREC=single,_GPU_TARGET=gfx906,_HIP_PLATFORM=amd
```
