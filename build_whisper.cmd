@echo off
setlocal enabledelayedexpansion

echo === Starting Whisper.cpp Build Process ===
echo.

echo Checking for whisper.cpp directory...
if not exist "whisper.cpp" (
    echo Directory 'whisper.cpp' not found. Please make sure you're in the correct directory and the submodule is initialized
    goto :eof
)

echo Changing to whisper.cpp directory...
cd whisper.cpp


echo "List all files in the whisper.cpp examples directory"
dir /b examples\server

echo "Copying the all the server files from ../whisper-custom/server to examples/server"
xcopy /E /Y /I ..\whisper-custom\server examples\server

echo Checking for server directory...
if not exist "examples\server" (
    echo Server directory not found. Please make sure the whisper.cpp repository is properly cloned
    cd ..
    goto :eof
)

echo Checking for server source files...
if not exist "examples\server\server.cpp" (
    echo Server source files not found. Please make sure the whisper.cpp repository is properly cloned
    cd ..
    goto :eof
)

echo Building whisper.cpp server...
mkdir build 2>nul
cd build

echo Running CMake...
@REM cpu version:
@REM cmake .. -DBUILD_SHARED_LIBS=OFF -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_SERVER=ON

@REM gpu version:
cmake .. -DBUILD_SHARED_LIBS=OFF -DWHISPER_BUILD_TESTS=OFF -DWHISPER_BUILD_SERVER=ON -DGGML_CUDA=ON -DCMAKE_CUDA_COMPILER="%CUDA_PATH%\bin\nvcc.exe" -DCMAKE_CUDA_ARCHITECTURES="86"
if %ERRORLEVEL% neq 0 (
    echo Failed to run CMake
    cd ..\..
    goto :eof
)

echo Building with CMake...
cmake --build . --config Release --parallel
if %ERRORLEVEL% neq 0 (
    echo Failed to build with CMake
    cd ..\..
    goto :eof
)

echo Checking for server executable...
if not exist "bin\Release\whisper-server.exe" (
    if not exist "bin\whisper-server.exe" (
        echo Server executable not found. Build may have failed
        cd ..\..
        goto :eof
    )
)

echo Creating package directory...
cd ..\..

set "PACKAGE_NAME=whisper-server-package"
set "MODEL_DIR=%MODEL_DIR%\models"

echo Creating run script...
if not exist "%PACKAGE_NAME%" (
    mkdir "%PACKAGE_NAME%"
    if %ERRORLEVEL% neq 0 (
        echo Failed to create package directory
        goto :eof
    )
)

if not exist "%PACKAGE_NAME%\models" (
    mkdir "%PACKAGE_NAME%\models"
)

(
    echo @echo off
    echo REM Default configuration
    echo set "HOST=127.0.0.1"
    echo set "PORT=8178"
    echo set "MODEL=models\%MODEL_NAME%"
    echo.
    echo REM Parse command line arguments
    echo :parse_args
    echo if "%%~1"=="" goto run
    echo if "%%~1"=="--host" (
    echo     set "HOST=%%~2"
    echo     shift /2
    echo     goto parse_args
    echo )
    echo if "%%~1"=="--port" (
    echo     set "PORT=%%~2"
    echo     shift /2
    echo     goto parse_args
    echo )
    echo if "%%~1"=="--model" (
    echo     set "MODEL=%%~2"
    echo     shift /2
    echo     goto parse_args
    echo )
    echo echo Unknown option: %%~1
    echo exit /b 1
    echo.
    echo :run
    echo REM Run the server
    echo whisper-server.exe ^
    echo     --model "%%MODEL%%" ^
    echo     --host "%%HOST%%" ^
    echo     --port "%%PORT%%" ^
    echo     --diarize ^
    echo     --print-progress
) > "%PACKAGE_NAME%\run-server.cmd"

echo Run script created successfully

REM Copy files to package directory
echo Copying files to package directory...

if not exist "%PACKAGE_NAME%" (
    mkdir "%PACKAGE_NAME%"
)

if not exist "%PACKAGE_NAME%\models" (
    mkdir "%PACKAGE_NAME%\models"
)

if exist "whisper.cpp\build\bin\Release\whisper-server.exe" (
    copy "whisper.cpp\build\bin\Release\whisper-server.exe" "%PACKAGE_NAME%\"
) else if exist "whisper.cpp\build\bin\whisper-server.exe" (
    copy "whisper.cpp\build\bin\whisper-server.exe" "%PACKAGE_NAME%\"
)

if %ERRORLEVEL% neq 0 (
    echo Failed to copy whisper-server.exe
    goto :eof
)


if exist "whisper.cpp\examples\server\public" (
    xcopy /E /Y /I "whisper.cpp\examples\server\public" "%PACKAGE_NAME%\public\"
)

echo === Build Process Complete ===
echo You can now proceed with running the server by running 'start_with_output.ps1'

goto :eof
