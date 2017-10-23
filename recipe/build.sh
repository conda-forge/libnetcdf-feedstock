#!/bin/bash
if [ `uname` == "Linux" ]; then
    LD_SUFFIX="so"
elif [ `uname` == "Darwin" ]; then
    LD_SUFFIX="dylib"
else
    LD_SUFFIX="DLL"
fi


# Build static.
cmake -D CMAKE_INSTALL_PREFIX=$PREFIX \
      -D CURL_INCLUDE_DIR=$PREFIX/include \
      -D CURL_LIBRARY=$PREFIX/lib/libcurl.$LD_SUFFIX \
      -D CMAKE_INSTALL_LIBDIR:PATH=$PREFIX/lib \
      -D ENABLE_DAP=ON \
      -D ENABLE_HDF4=ON \
      -D ENABLE_NETCDF_4=ON \
      -D BUILD_SHARED_LIBS=OFF \
      -D ENABLE_TESTS=OFF \
      -D BUILD_UTILITIES=ON \
      -D ENABLE_DOXYGEN=OFF \
      -D ENABLE_LOGGING=ON \
      $SRC_DIR
make
# ctest  # Run only for the shared lib build to save time.
make install
make clean

# Build shared.
cmake -D CMAKE_INSTALL_PREFIX=$PREFIX \
      -D CMAKE_INSTALL_LIBDIR:PATH=$PREFIX/lib \
      -D ENABLE_DAP=ON \
      -D ENABLE_HDF4=ON \
      -D ENABLE_NETCDF_4=ON \
      -D BUILD_SHARED_LIBS=ON \
      -D ENABLE_TESTS=OFF \
      -D BUILD_UTILITIES=ON \
      -D ENABLE_DOXYGEN=OFF \
      -D ENABLE_LOGGING=ON \
      $SRC_DIR
make
ctest
make install
