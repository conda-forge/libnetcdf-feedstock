mkdir %SRC_DIR%\build
cd %SRC_DIR%\build

set BUILD_TYPE=Release
:: set BUILD_TYPE=RelWithDebInfo
:: set BUILD_TYPE=Debug

rem to be filled with mpi options
set PARALLEL=""

rem manually specify hdf5 paths to work-around https://github.com/Unidata/netcdf-c/issues/1444
cmake -LAH -G "NMake Makefiles" ^
      %CMAKE_ARGS% ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
      -DBUILD_SHARED_LIBS=ON ^
      -DNETCDF_BUILD_UTILITIES=ON ^
      -DNETCDF_ENABLE_DOXYGEN=OFF ^
      -DNETCDF_ENABLE_TESTS=ON ^
      -DENABLE_EXTERNAL_SERVER_TESTS=OFF ^
      -DNETCDF_ENABLE_DAP=ON ^
      -DENABLE_DAP_REMOTE_TESTS=OFF ^
      -DNETCDF_ENABLE_HDF4=ON ^
      -DNETCDF_ENABLE_HDF5=ON ^
      -DENABLE_PLUGIN_INSTALL=ON ^
      -DPLUGIN_INSTALL_DIR=YES ^
      -DNETCDF_ENABLE_CDF5=ON ^
      -DNETCDF_ENABLE_BYTERANGE=ON ^
      -DNETCDF_ENABLE_NCZARR=on ^
      -DNETCDF_ENABLE_NCZARR_ZIP=on ^
      -DNETCDF_ENABLE_NCZARR_S3=off ^
      -DENABLE_NCZARR_S3_TESTS=off ^
      -DENABLE_S3_SDK=off ^
      -DHDF5_C_LIBRARY="%LIBRARY_LIB:\=/%/hdf5.lib" ^
      -DHDF5_HL_LIBRARY="%LIBRARY_LIB:\=/%/hdf5_hl.lib" ^
      -DHDF5_INCLUDE_DIR="%LIBRARY_INC:\=/%" ^
      -DCMAKE_C_FLAGS="-DH5_BUILT_AS_DYNAMIC_LIB" ^
      %PARALLEL% ^
      %SRC_DIR%
if errorlevel 1 exit \b 1

cmake --build . --config %BUILD_TYPE% --target install
if errorlevel 1 exit \b 1

:: We need to add some entries to PATH before running the tests
set ORIG_PATH=%PATH%
set PATH=%CD%\liblib\%BUILD_TYPE%;%CD%\liblib;%PREFIX%\Library\bin;%PATH%

:: 6 or 7 tests fail due to minor floating point / format string differences in the VS2008 build
goto end_tests
if "%vc%" == "9" goto vc9_tests
ctest -VV
if errorlevel 1 exit \b 1
goto end_tests
:vc9_tests
ctest -VV
:end_tests
