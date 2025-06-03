# Whisper.cpp Backend

C++ backend for whisper.cpp with real-time transcription.

## Features

⚡ Real-time Transcription: Low-latency, streaming speech-to-text.

🖥️ Runs Locally: Fully offline — no internet or cloud services required.

🎯 C++ Backend: High-performance backend built with C++ for stability and speed.

🧠 Powered by whisper.cpp: Efficient inference using OpenAI's Whisper model in C++.

🧩 Easy Integration: Exposed as a service for seamless integration with other apps or pipelines.

🧱 Optimized for Consumer GPUs: Leverages local GPU for fast and efficient transcription, no specialized hardware needed.

## Requirements
- FFmpeg
- C++ compiler (for Whisper.cpp)
- CMake

## Installation

### Prerequisites Installation

#### For Windows:
1. **FFmpeg**:
    - Download from [FFmpeg.org](https://ffmpeg.org/download.html) or install via [Chocolatey](https://chocolatey.org/): `choco install ffmpeg`
    - Add FFmpeg to your PATH environment variable
    - Verify installation: `ffmpeg -version`

2. **C++ Compiler**:
    - Install Visual Studio Build Tools from [Microsoft](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
    - Select "Desktop development with C++" workload during installation

3. **CMake**:
    - Download and install from [CMake.org](https://cmake.org/download/)
    - Ensure you select "Add CMake to the system PATH" during installation
    - Verify installation: `cmake --version`

#### For macOS:
1. **FFmpeg**:
    - Install via Homebrew: `brew install ffmpeg`
    - Verify installation: `ffmpeg -version`

2. **C++ Compiler**:
    - Install Xcode Command Line Tools: `xcode-select --install`
    - Verify installation: `clang --version`

3. **CMake**:
    - Install via Homebrew: `brew install cmake`
    - Verify installation: `cmake --version`

### 3. Build Whisper Server

#### For Windows:
Run the build script which will:
- Build Whisper.cpp with custom server modifications
- Set up the server package with required files

```cmd
./build_whisper.cmd
```

Or run with PowerShell:
```powershell
.\run_build_whisper.ps1
```

#### For macOS:
```bash
./build_whisper.sh
```

If you encounter permission issues, make the script executable:
```bash
chmod +x build_whisper.sh
./build_whisper.sh
```

### 4. Running the Server

#### Download model
Download the Whisper model for [huggingface](https://huggingface.co/ggerganov/whisper.cpp/)
Move the model to the "whisper-server-package/models" directory.

#### For Windows:
The PowerShell script provides an interactive way to start the backend services:

```cmd
./run_clean_start_backend.ps1
```

Or directly with PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File run_clean_start_backend.ps1
```

The script will:
1. Check and clean up any existing processes
2. Display available models and prompt for selection
3. Start the Whisper server in a new window

To stop all services, close the command windows or press Ctrl+C in each window.

#### For macOS:
```bash
./clean_start_backend.sh
```

If you encounter permission issues:
```bash
chmod +x clean_start_backend.sh
./clean_start_backend.sh
```

### 5. Use

```bash
curl -X POST "http://127.0.0.1:8178/inference" \
     -F "file=@/path/to/your/file" \
     -F "language=zh" \
     -F "diarize=0" \
     -F "response_format=json" \
     -F "temperature=0.2"
```

## Included Projects

This repo includes the full source of [whisper.cpp](https://github.com/ggerganov/whisper.cpp) under the `whisper.cpp/` directory, for ease of build and deployment.  
License and attribution remain under their original terms.
