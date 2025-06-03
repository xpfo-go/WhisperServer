#!/bin/bash

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Helper functions for logging
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    return 1
}

log_section() {
    echo -e "\n${BLUE}=== $1 ===${NC}\n"
}

# Error handling
handle_error() {
    log_error "$1"
    exit 1
}

# Main script
log_section "Starting Whisper.cpp Build Process"

log_info "Checking for whisper.cpp directory..."
if [ ! -d "whisper.cpp" ]; then
    handle_error "Directory 'whisper.cpp' not found. Please make sure you're in the correct directory and the submodule is initialized"
fi

log_info "Changing to whisper.cpp directory..."
cd whisper.cpp || handle_error "Failed to change to whisper.cpp directory"

log_info "Checking for custom server directory..."
if [ ! -d "../whisper-custom/server" ]; then
    handle_error "Directory '../whisper-custom/server' not found. Please make sure the custom server files exist"
fi

log_info "Copying custom server files..."
cp -r ../whisper-custom/server/* "examples/server/" || handle_error "Failed to copy custom server files"
log_success "Custom server files copied successfully"

log_info "Verifying server files..."
ls "examples/server/" || handle_error "Failed to list server files"

log_section "Building Whisper Server"
log_info "Installing required dependencies..."
brew install libomp llvm cmake || handle_error "Failed to install dependencies"

log_info "Setting up compiler environment..."
export CC=/opt/homebrew/opt/llvm/bin/clang
export CXX=/opt/homebrew/opt/llvm/bin/clang++
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

log_info "Building whisper.cpp..."
rm -rf build
mkdir build && cd build || handle_error "Failed to create build directory"
cmake -DCMAKE_C_COMPILER=/opt/homebrew/opt/llvm/bin/clang -DCMAKE_CXX_COMPILER=/opt/homebrew/opt/llvm/bin/clang++ .. || handle_error "CMake configuration failed"
make -j4 || handle_error "Make failed"
cd ..
log_success "Build completed successfully"

# Configuration
PACKAGE_NAME="whisper-server-package"
MODEL_NAME="ggml-small.bin"
MODEL_DIR="$PACKAGE_NAME/models"

log_section "Package Configuration"
log_info "Package name: $PACKAGE_NAME"
log_info "Model name: $MODEL_NAME"
log_info "Model directory: $MODEL_DIR"

# Create necessary directories
log_info "Creating package directories..."
mkdir -p "$PACKAGE_NAME" || handle_error "Failed to create package directory"
mkdir -p "$MODEL_DIR" || handle_error "Failed to create models directory"
log_success "Package directories created successfully"

# Copy server binary
log_info "Copying server binary..."
cp build/bin/whisper-server "$PACKAGE_NAME/" || handle_error "Failed to copy server binary"
log_success "Server binary copied successfully"

# Copy model file

# Check for existing models
log_section "Model Management"
log_info "Checking for existing Whisper models..."

EXISTING_MODELS=$(find "$MODEL_DIR" -name "ggml-*.bin" -type f)

if [ -n "$EXISTING_MODELS" ]; then
    log_info "Found existing models:"
    echo -e "${BLUE}$EXISTING_MODELS${NC}"
else
    log_warning "No existing models found"
fi

# Create run script
log_info "Creating run script..."
cat > "$PACKAGE_NAME/run-server.sh" << 'EOL'
#!/bin/bash

# Default configuration
HOST="127.0.0.1"
PORT="8178"
MODEL="models/ggml-large-v3.bin"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run the server
./whisper-server \
    --model "$MODEL" \
    --host "$HOST" \
    --port "$PORT" \
    --diarize \
    --print-progress


EOL
log_success "Run script created successfully"

log_info "Making script executable: $PACKAGE_NAME/run-server.sh"
# Make run script executable
chmod +x "$PACKAGE_NAME/run-server.sh" || handle_error "Failed to make script executable"

log_info "Listing files..."
ls || handle_error "Failed to list files"

# Check if package directory already exists
if [ -d "../$PACKAGE_NAME" ]; then
    log_info "Listing parent directory..."
    log_warning "Package directory already exists: ../$PACKAGE_NAME"
    log_info "Listing package directory..."
else
    log_info "Creating package directory: ../$PACKAGE_NAME"
    mkdir "../$PACKAGE_NAME" || handle_error "Failed to create package directory"
    log_success "Package directory created successfully"
fi

# Move whisper-server package out of whisper.cpp to ../PACKAGE_NAME

# If package directory already exists outside whisper.cpp, copy just whisper-server and model to it. Replace
# the contents of the directory with the new files
if [ -d "../$PACKAGE_NAME" ]; then
    log_info "Copying package contents to existing directory..."
    cp -r "$PACKAGE_NAME/"* "../$PACKAGE_NAME" || handle_error "Failed to copy package contents"
    
else
   
   log_info "Copying whisper-server and model to ../$PACKAGE_NAME"
    cp "$MODEL_DIR/$MODEL_NAME" "../$PACKAGE_NAME/models/" || handle_error "Failed to copy model"
    cp "$PACKAGE_NAME/run-server.sh" "../$PACKAGE_NAME" || handle_error "Failed to copy run script"
    cp -r "$PACKAGE_NAME/public" "../$PACKAGE_NAME" || handle_error "Failed to copy public directory"
    cp "$PACKAGE_NAME/whisper-server" "../$PACKAGE_NAME" || handle_error "Failed to copy whisper-server"
    # rm -r "$PACKAGE_NAME"
fi

log_section "Build Process Complete"
log_success "Whisper.cpp server build and setup completed successfully!"

echo -e "${GREEN}You can now proceed with running the server by running './clean_start_backend.sh'${NC} "
