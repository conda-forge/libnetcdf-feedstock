mkdir %SRC_DIR%\build
cd %SRC_DIR%\build

:: set BUILD_TYPE=Release
:: set BUILD_TYPE=RelWithDebInfo
set BUILD_TYPE=Debug
set HDF5_DIR=%LIBRARY_PREFIX%\cmake\hdf5

cmake -G "%CMAKE_GENERATOR%" ^
      -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
      -DBUILD_SHARED_LIBS=ON ^
      -DENABLE_TESTS=ON ^
      -DENABLE_HDF4=ON ^
      -DENABLE_LOGGING=ON ^
      -DNC_USE_RELEASE_CRT=ON ^
      -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
      -DZLIB_LIBRARY="%LIBRARY_LIB%\zlib.lib" ^
      -DZLIB_INCLUDE_DIR="%LIBRARY_INC%" ^
      -DCMAKE_BUILD_TYPE=%BUILD_TYPE% ^
      %SRC_DIR%
if errorlevel 1 exit \b 1

cmake --build . --config %BUILD_TYPE%
if errorlevel 1 exit \b 1

:: Please do not remove this.
:: If you need to debug the VC9 build this shows how (set BUILD_TYPE=RelWithDebInfo too)
echo If you need to debug this in Visual Studio:
echo set PATH=%CD%\liblib\%BUILD_TYPE%;%CD%\liblib;%PREFIX%\Library\bin;%PATH%
echo "C:\Program Files (x86)\Microsoft Visual Studio 9.0\Common7\IDE\devenv.exe" /debugexe %CD%\ncdump\%BUILD_TYPE%\ncdump.exe -h http://geoport-dev.whoi.edu/thredds/dodsC/estofs/atlantic

ctest
if errorlevel 1 exit \b 1

cmake --build . --config %BUILD_TYPE% --target install
if errorlevel 1 exit \b 1

:: Also leave this test where it is. ATM, conda-build deletes host prefixes by the time it runs the
:: package tests which makes investigating problems very tricky. Pinging @msarahan about that.
ncdump\%BUILD_TYPE%\ncdump.exe -h http://geoport-dev.whoi.edu/thredds/dodsC/estofs/atlantic

if errorlevel 1 exit \b 1
