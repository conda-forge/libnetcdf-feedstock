#!/bin/bash
# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

set -x

if [[ ! -z "$mpi" && "$mpi" != "nompi" ]]; then
  export PARALLEL="-DENABLE_PARALLEL4=ON -DENABLE_PARALLEL_TESTS=ON"
  export CC=mpicc
  export CXX=mpicxx
  export TESTPROC=4
  export OMPI_MCA_rmaps_base_oversubscribe=yes
  export OMPI_MCA_btl=self,tcp
  export OMPI_MCA_plm=isolated
  export OMPI_MCA_rmaps_base_oversubscribe=yes
  export OMPI_MCA_btl_vader_single_copy_mechanism=none
  mpiexec="mpiexec --allow-run-as-root"
  # for cross compiling using openmpi
  export OPAL_PREFIX=$PREFIX
else
  export CC=$(basename ${CC})
  export CXX=$(basename ${CXX})
  PARALLEL=""
fi

if [[ ${HOST} =~ .*darwin.* ]]; then
    # We have a problem with over-stripping of dylibs in the test programs:
    # nm ${PREFIX}/lib/libdf.dylib | grep error_top
    #   000000000006197c S _error_top
    # Then, despite this being linked to explicitly when creating the test programs:
    # ./hdf4_test_tst_chunk_hdf4
    # dyld: Symbol not found: _error_top
    #   Referenced from: ${PREFIX}/lib/libmfhdf.0.dylib
    #   Expected in: flat namespace
    #  in ${PREFIX}/lib/libmfhdf.0.dylib
    # Abort trap: 56
    # Now clearly libmfhdf should autoload libdf but it does not and that is not going to change:
    # https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=556439
    # .. so we must remove our unused stripping instead :-(
    # (it may be possible to arrange this symbol to be in the 'D'ata section instead of 'S'
    #  (symbol in a section other than those above according to man nm), instead though
    #  or to fix ld64 so that it checks for symbols being used in this section).
    export LDFLAGS=$(echo "${LDFLAGS}" | sed "s/-Wl,-dead_strip_dylibs//g")
    export CFLAGS="$CFLAGS -fno-strict-aliasing"
fi

if [[ ${DEBUG_C} == yes ]]; then
  CMAKE_BUILD_TYPE=Debug
else
  CMAKE_BUILD_TYPE=Release
fi

if [[ ${target_platform} == "linux-ppc64le" ]]; then
    export CFLAGS=${CFLAGS//-O3/-O0}
    # This is the easiest way to get CMake to stop appending -O3
    CMAKE_BUILD_TYPE=None
fi

# 2022/04/25
# DAP Remote tests are causing spurious failures at the momment
# https://github.com/Unidata/netcdf-c/issues/2188#issuecomment-1015927961
# -DENABLE_DAP_REMOTE_TESTS=OFF

mkdir build-shared
cd build-shared
# Build shared.
cmake ${CMAKE_ARGS} \
      -DCMAKE_PREFIX_PATH=${PREFIX} \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DENABLE_DAP=ON \
      -DENABLE_DAP_REMOTE_TESTS=OFF \
      -DENABLE_HDF4=ON \
      -DENABLE_NETCDF_4=ON \
      -DBUILD_SHARED_LIBS=ON \
      -DENABLE_TESTS=ON \
      -DBUILD_UTILITIES=ON \
      -DENABLE_DOXYGEN=OFF \
      -DENABLE_CDF5=ON \
      -DENABLE_EXTERNAL_SERVER_TESTS=OFF \
      ${PARALLEL} \
      -DENABLE_NCZARR=on \
      -DENABLE_NCZARR_S3=off \
      -DENABLE_NCZARR_S3_TESTS=off \
      ${SRC_DIR}
make install -j${CPU_COUNT} ${VERBOSE_CM}

SKIP=""

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
ctest -VV --output-on-failure -j${CPU_COUNT} ${SKIP}
fi

#
# Clean up build directories
#
cd ..
rm -rf build-shared

# Fix build paths in nc-config
sed -i.bak "s#${BUILD_PREFIX}/bin/${CC}#${CC}#g" ${PREFIX}/bin/nc-config
rm ${PREFIX}/bin/nc-config.bak

# Clean out build-location stuff from cmake files 
# Should only be libm, but the patterns are more general just in case
for fname in `ls ${PREFIX}/lib/cmake/netCDF/*`; do
     # fix linux
     sed -i.bak "s#${CONDA_BUILD_SYSROOT}/usr/lib/lib\([a-z]*\).so#\1#g" ${fname}
     # fix OSX
     sed -i.bak "s#/Applications/Xcode_[0-9]*.[0-9]*.[0-9]*.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX[0-9]*.[0-9]*.sdk/usr/lib/lib\([a-zA-Z0-9]*\).dylib#\1#g" ${fname}
     rm ${fname}.bak
     cat ${fname}
 done