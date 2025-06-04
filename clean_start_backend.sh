#!/bin/bash

# Exit on error
set -e

# Color codes and emojis
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
PACKAGE_NAME="whisper-server-package"
MODEL_DIR="$PACKAGE_NAME/models"

# Helper functions for logging
log_info() {
    echo -e "${BLUE}ℹ️  [INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}✅ [SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  [WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}❌ [ERROR]${NC} $1"
    return 1
}

log_section() {
    echo -e "\n${PURPLE}🔄 === $1 ===${NC}\n"
}

# Error handling function
handle_error() {
    local error_msg="$1"
    log_error "$error_msg"
    cleanup
    exit 1
}

# Cleanup function
cleanup() {
    log_section "Cleanup"
    if [ -n "$WHISPER_PID" ]; then
        log_info "Stopping Whisper server..."
        if kill -0 $WHISPER_PID 2>/dev/null; then
            kill -9 $WHISPER_PID 2>/dev/null || log_warning "Failed to kill Whisper server process"
            pkill -9 -f "whisper-server" 2>/dev/null || log_warning "Failed to kill remaining whisper-server processes"
        fi
        log_success "Whisper server stopped"
    fi
}

# Set up trap for cleanup on script exit, interrupt, or termination
trap cleanup EXIT INT TERM

# Check if required directories and files exist
log_section "Environment Check"

if [ ! -d "$PACKAGE_NAME" ]; then
    handle_error "Whisper server directory not found. Please run build_whisper.sh first"
fi

# Kill any existing whisper-server processes
log_section "Initial Cleanup"

log_info "Checking for existing whisper servers..."
if pkill -f "whisper-server" 2>/dev/null; then
    log_success "Existing whisper servers terminated"
else
    log_warning "No existing whisper servers found"
fi
sleep 1  # Give processes time to terminate

# Check and kill if backend app in port 5167 is running
log_section "Backend App Check"


# Check for existing model
log_section "Model Check"

if [ ! -d "$MODEL_DIR" ]; then
    handle_error "Models directory not found. Please run build_whisper.sh first"
fi

log_info "Checking for Whisper models..."
EXISTING_MODELS=$(find "$MODEL_DIR" -name "ggml-*.bin" -type f)

if [ -n "$EXISTING_MODELS" ]; then
    log_success "Found existing models:"
    echo -e "${BLUE}$EXISTING_MODELS${NC}"
else
    log_warning "No existing models found"
fi

# Whisper models
models=$(find "$MODEL_DIR" -name "ggml-*.bin" -type f -exec basename {} \;)

# Ask user which model to use if the argument is not provided
if [ -z "$1" ]; then
    log_section "Model Selection"
    log_info "Available models:"
    echo -e "${BLUE}$models${NC}"
    read -p "$(echo -e "${YELLOW}🎯 Enter a model name (e.g. small):${NC} ")" MODEL_SHORT_NAME
else
    MODEL_SHORT_NAME=$1
fi

# Check if the model is valid
if ! echo "$models" | grep -qw "$MODEL_SHORT_NAME"; then
    handle_error "Invalid model: $MODEL_SHORT_NAME"
fi

MODEL_NAME=$MODEL_SHORT_NAME
log_success "Selected model: $MODEL_NAME"

# Check if the modelname exists in directory
if [ -f "$MODEL_DIR/$MODEL_NAME" ]; then
    log_success "Model file exists: $MODEL_DIR/$MODEL_NAME"
else
    handle_error "Model file does not exist: $MODEL_DIR/$MODEL_NAME, please see https://huggingface.co/ggerganov/whisper.cpp/. download the model and then mv model file to dir of whisper-server-package/models/"
fi

log_section "Starting Services"

# Start the whisper server in background
log_info "Starting Whisper server... 🎙️"
cd "$PACKAGE_NAME" || handle_error "Failed to change to whisper-server directory"
./run-server.sh --model "models/$MODEL_NAME" &
WHISPER_PID=$!
cd .. || handle_error "Failed to return to root directory"

# Wait for server to start and check if it's running
sleep 2
if ! kill -0 $WHISPER_PID 2>/dev/null; then
    handle_error "Whisper server failed to start"
fi


log_success "🎉 All services started successfully!"
echo -e "${GREEN}🔍 Whisper Server (PID: $WHISPER_PID)${NC}"
echo -e "${BLUE}Press Ctrl+C to stop all services${NC}"

# Show whisper server port and python backend port
echo -e "${BLUE}Whisper Server Port: 8178${NC}"

# Keep the script running and wait for both processes
wait $WHISPER_PID || handle_error "One of the services crashed"
