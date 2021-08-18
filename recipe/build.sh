#!/bin/bash

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

declare -a CMAKE_PLATFORM_FLAGS
if [[ ${HOST} =~ .*darwin.* ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
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
else
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")
fi

if [[ ${DEBUG_C} == yes ]]; then
  CMAKE_BUILD_TYPE=Debug
else
  CMAKE_BUILD_TYPE=Release
fi

# Build static.
cmake ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR="lib" \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DENABLE_DAP=ON \
      -DENABLE_HDF4=ON \
      -DENABLE_NETCDF_4=ON \
      -DBUILD_SHARED_LIBS=OFF \
      -DENABLE_TESTS=ON \
      -DBUILD_UTILITIES=ON \
      -DENABLE_DOXYGEN=OFF \
      -DENABLE_LOGGING=ON \
      -DCMAKE_C_FLAGS_RELEASE=${CFLAGS} \
      -DCMAKE_C_FLAGS_DEBUG=${CFLAGS} \
      -DCURL_INCLUDE_DIR=${PREFIX}/include \
      -DCURL_LIBRARY=${PREFIX}/lib/libcurl${SHLIB_EXT} \
      -DENABLE_CDF5=ON \
      -DENABLE_BYTERANGE=ON \
      ${CMAKE_PLATFORM_FLAGS[@]} \
      -DENABLE_NCZARR=on -DENABLE_NCZARR_S3=off -DENABLE_NCZARR_S3_TESTS=off \
      ${SRC_DIR}
make -j${CPU_COUNT} ${VERBOSE_CM}
# ctest  # Run only for the shared lib build to save time.
make install -j${CPU_COUNT}
make clean

# Build shared.
cmake ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR="lib" \
      -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
      -DENABLE_DAP=ON \
      -DENABLE_HDF4=ON \
      -DENABLE_NETCDF_4=ON \
      -DBUILD_SHARED_LIBS=ON \
      -DENABLE_TESTS=ON \
      -DBUILD_UTILITIES=ON \
      -DENABLE_DOXYGEN=OFF \
      -DENABLE_LOGGING=ON \
      -DCMAKE_C_FLAGS_RELEASE=${CFLAGS} \
      -DCMAKE_C_FLAGS_DEBUG=${CFLAGS} \
      -DCURL_INCLUDE_DIR=${PREFIX}/include \
      -DCURL_LIBRARY=${PREFIX}/lib/libcurl${SHLIB_EXT} \
      -DENABLE_CDF5=ON \
      ${CMAKE_PLATFORM_FLAGS[@]} \
      -DENABLE_NCZARR=on -DENABLE_NCZARR_S3=off -DENABLE_NCZARR_S3_TESTS=off \
      ${SRC_DIR}
make -j${CPU_COUNT} ${VERBOSE_CM}
make install -j${CPU_COUNT}
ctest -VV --output-on-failure || true

# Fix build paths in cmake artifacts
for fname in `ls ${PREFIX}/lib/cmake/netCDF/*`; do
    sed -i.bak "s#${CONDA_BUILD_SYSROOT}/usr/lib/lib\([a-z]*\).so#\1#g" ${fname}
    sed -i.bak "s#/Applications/Xcode_.*app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.*sdk/usr/lib/lib\([a-z]*\).dylib#\1#g" ${fname}
    rm ${fname}.bak
    cat ${fname}
done

# Fix build paths in nc-config
sed -i.bak "s#${BUILD_PREFIX}/bin/${CC}#${CC}#g" ${PREFIX}/bin/nc-config
rm ${PREFIX}/bin/nc-config.bak
