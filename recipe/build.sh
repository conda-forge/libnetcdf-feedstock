#!/bin/bash

declare -a CMAKE_PLATFORM_FLAGS
if [[ ${HOST} =~ .*darwin.* ]]; then
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_OSX_SYSROOT="${CONDA_BUILD_SYSROOT}")
else
  CMAKE_PLATFORM_FLAGS+=(-DCMAKE_TOOLCHAIN_FILE="${RECIPE_DIR}/cross-linux.cmake")
fi

if [[ ${DEBUG_C} == yes ]]; then
  CMAKE_BUILD_TYPE=Debug
else
  CMAKE_BUILD_TYPE=Release
fi

# Build static.
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR:PATH=${PREFIX}/lib \
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
      ${CMAKE_PLATFORM_FLAGS[@]} \
      ${SRC_DIR}
make -j${CPU_COUNT} ${VERBOSE_CM}
# ctest  # Run only for the shared lib build to save time.
make install -j${CPU_COUNT}
make clean

# Build shared.
cmake -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR:PATH=${PREFIX}/lib \
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
      ${CMAKE_PLATFORM_FLAGS[@]} \
      ${SRC_DIR}
make -j${CPU_COUNT} ${VERBOSE_CM}
make install -j${CPU_COUNT}
ctest
