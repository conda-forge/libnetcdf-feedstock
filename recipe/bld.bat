mkdir %SRC_DIR%\build
cd %SRC_DIR%\build

set BUILD_TYPE=Release
:: set BUILD_TYPE=RelWithDebInfo
:: set BUILD_TYPE=Debug

rem manually specify hdf5 paths to work-around https://github.com/Unidata/netcdf-c/issues/1444
cmake -LAH -G "NMake Makefiles" ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DBUILD_SHARED_LIBS=ON ^
      -DENABLE_TESTS=ON ^
      -DENABLE_HDF4=ON ^
      -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
      -DENABLE_CDF5=ON ^
      -DENABLE_BYTERANGE=ON ^
      -DHDF5_C_LIBRARY="%LIBRARY_LIB:\=/%/hdf5.lib" ^
      -DHDF5_HL_LIBRARY="%LIBRARY_LIB:\=/%/hdf5_hl.lib" ^
      -DHDF5_INCLUDE_DIR="%LIBRARY_INC:\=/%" ^
      -DCMAKE_C_FLAGS="-DH5_BUILT_AS_DYNAMIC_LIB" ^
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

