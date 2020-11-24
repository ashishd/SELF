FROM gcr.io/self-fluids/self-dep:latest AS devel

COPY . /tmp

# FEQParse
RUN mkdir -p /tmp/extern/feq-parse/build && \
    cd /tmp/extern/feq-parse/build && \
    cmake -DCMAKE_INSTALL_PREFIX="/apps/self" /tmp/extern/feq-parse && \
    make && make install

# JSON-Fortran
RUN mkdir -p /tmp/extern/json-fortran/build && \
    cd /tmp/extern/json-fortran/build && \
    cmake -DSKIP_DOC_GEN=True -DCMAKE_INSTALL_PREFIX="/apps/self" /tmp/extern/json-fortran && \
    make && make install

# FLAP
RUN mkdir -p /tmp/extern/FLAP/build && \
    cd /tmp/extern/FLAP/build && \
    cmake -DCMAKE_INSTALL_PREFIX="/apps/self" /tmp/extern/FLAP && \
    make && make install

ENV HIP_PLATFORM=nvcc \
    HIP_COMPILER=/usr/local/cuda/bin/nvcc

#RUN cd /tmp && \
#    make install -f /tmp/self.make

RUN mkdir -p /tmp/build && \
    cd /tmp/build && \
    FC="/opt/hipfort/bin/hipfc" \
    CXX="/opt/rocm/bin/hipcc" \
    CXXFLAGS="" \
    FFLAGS="-DGPU -ffree-line-length-none -I/apps/self/include/FLAP -I/apps/self/include/PENF -I/apps/self/include/FACE" \
    cmake -DCMAKE_INSTALL_PREFIX="/apps/self" /tmp &&\
    make VERBOSE=1 && make install


FROM gcr.io/self-fluids/self-dep:latest

COPY --from=devel /apps /apps
ENV LD_LIBRARY_PATH=/apps/self/lib:$LD_LIBRARY_PATH \
    PATH=/apps/self/bin:$PATH
