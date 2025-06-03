@echo off
setlocal enabledelayedexpansion

REM Configuration
set "PACKAGE_NAME=whisper-server-package"
set "MODEL_DIR=%PACKAGE_NAME%\models"
set "PORT=8178"

echo === Environment Check ===
echo.

if not exist "%PACKAGE_NAME%" (
    echo Whisper server directory not found. Please run build_whisper.cmd first
    goto :eof
)


echo === Initial Cleanup ===
echo.

echo Checking for existing whisper servers...
taskkill /F /FI "IMAGENAME eq whisper-server.exe" 2>nul
if %ERRORLEVEL% equ 0 (
    echo Existing whisper servers terminated
) else (
    echo No existing whisper servers found
)
timeout /t 1 >nul

echo === Model Selection ===
echo.

if not exist "%MODEL_DIR%" (
    echo Models directory not found: %MODEL_DIR%
    goto :eof
)

set "AVAILABLE_MODELS="
for %%f in ("%MODEL_DIR%\ggml-*.bin") do (
    set "AVAILABLE_MODELS=!AVAILABLE_MODELS!%%~nxf;"
)

if not defined AVAILABLE_MODELS (
    echo No model files found in %MODEL_DIR%
    echo Please download from: https://huggingface.co/ggerganov/whisper.cpp/
    goto :eof
)

REM Remove last semicolon
set "AVAILABLE_MODELS=%AVAILABLE_MODELS:~0,-1%"

REM Ask user which model to use if not provided
set "MODEL_NAME="
if "%~1"=="" (
    echo Available models:
    for %%m in (%AVAILABLE_MODELS%) do (
        echo     %%m
    )
    echo.
    set /p MODEL_NAME="Enter a model file name (e.g. ggml-small.bin): "
) else (
    set "MODEL_NAME=%~1"
)

REM Check if model file exists
if not exist "%MODEL_DIR%\%MODEL_NAME%" (
    echo Invalid model: %MODEL_NAME%
    echo File not found: %MODEL_DIR%\%MODEL_NAME%
    goto :eof
)

echo Selected model: %MODEL_NAME%

echo === Starting Whisper Server ===
echo.

cd "%PACKAGE_NAME%" || (
    echo Failed to change to whisper-server directory
    goto :eof
)

start "Whisper Server" cmd /k "whisper-server.exe --model models\%MODEL_NAME% --host 127.0.0.1 --port %PORT% --diarize --print-progress"

echo Waiting for whisper server to start...
timeout /t 5 >nul

for /f "tokens=2" %%a in ('tasklist /fi "imagename eq whisper-server.exe" /fo list ^| findstr "PID:"') do (
    set "WHISPER_PID=%%a"
)

if not defined WHISPER_PID (
    echo Whisper server failed to start. Check logs for details.
    cd ..
    goto :eof
)

netstat -ano | findstr ":%PORT%.*LISTENING" >nul
if %ERRORLEVEL% neq 0 (
    echo Whisper server is not listening on port %PORT%. Waiting longer...
    timeout /t 10 >nul
    netstat -ano | findstr ":%PORT%.*LISTENING" >nul
    if %ERRORLEVEL% neq 0 (
        echo Whisper server still not listening. Terminating...
        taskkill /F /PID %WHISPER_PID% 2>nul
        cd ..
        goto :eof
    )
)

echo ===================================
echo Whisper Server started successfully!
echo PID: %WHISPER_PID%
echo Port: %PORT%
echo ===================================
echo Press Ctrl+C to stop the server
echo.
pause >nul

echo === Stopping Whisper Server ===
taskkill /F /PID %WHISPER_PID% 2>nul
echo Done.

goto :eof