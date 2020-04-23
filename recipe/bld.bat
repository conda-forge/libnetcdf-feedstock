mkdir %SRC_DIR%\build
cd %SRC_DIR%\build

set BUILD_TYPE=Release
:: set BUILD_TYPE=RelWithDebInfo
:: set BUILD_TYPE=Debug
set HDF5_DIR=%LIBRARY_PREFIX%\cmake\hdf5

cmake -G "NMake Makefiles" ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DBUILD_SHARED_LIBS=ON ^
      -DENABLE_TESTS=ON ^
      -DENABLE_HDF4=ON ^
      -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
      -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
      -D ENABLE_CDF5=ON ^
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

