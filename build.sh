#!/bin/bash

# PrimiHub Platform Build Script
# Based on Jenkins configuration for building primihub-sdk and primihub-service

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check Maven
    if command_exists mvn; then
        print_success "Maven found: $(mvn --version 2>/dev/null | head -n 1)"
    else
        print_error "Maven not found. Please install Maven first."
        exit 1
    fi
    
    # Check Docker (optional, only needed for image building)
    if command_exists docker; then
        print_success "Docker found: $(docker --version)"
    else
        print_warning "Docker not found. Docker image building will be skipped."
    fi
    
    # Check Java - prefer Java 21 for compatibility with Spring Boot 2.3.x and modern tooling
    if [ -d "/opt/homebrew/Cellar/openjdk@21" ]; then
        # Use Java 21 from Homebrew if available
        JAVA_21_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
        export JAVA_HOME="$JAVA_21_HOME"
        export PATH="$JAVA_21_HOME/bin:$PATH"
        JAVA_VERSION=$("$JAVA_21_HOME/bin/java" -version 2>&1 | head -n 1)
        print_success "Using Java 21 for compatibility: $JAVA_VERSION"
        print_success "Set JAVA_HOME to: $JAVA_HOME"
    elif command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1)
        print_success "Java found: $JAVA_VERSION"

        # Always detect JAVA_HOME from the active java command to ensure consistency
        print_info "Detecting JAVA_HOME from active Java installation..."
        JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java) || which java)))
        export JAVA_HOME
        print_success "Set JAVA_HOME to: $JAVA_HOME"
    else
        print_error "Java not found. Please install Java first."
        exit 1
    fi
}

# Function to build primihub-sdk
build_sdk() {
    print_info "Building primihub-sdk..."
    
    if [ ! -d "primihub-sdk" ]; then
        print_error "primihub-sdk directory not found"
        exit 1
    fi
    
    cd primihub-sdk
    
    # Detect OS and set appropriate classifier
    OS_TYPE=$(uname -s)
    ARCH_TYPE=$(uname -m)
    
    if [ "$OS_TYPE" = "Darwin" ]; then
        if [ "$ARCH_TYPE" = "arm64" ]; then
            OS_CLASSIFIER="osx-aarch_64"
        else
            OS_CLASSIFIER="osx-x86_64"
        fi
    elif [ "$OS_TYPE" = "Linux" ]; then
        if [ "$ARCH_TYPE" = "aarch64" ]; then
            OS_CLASSIFIER="linux-aarch_64"
        else
            OS_CLASSIFIER="linux-x86_64"
        fi
    else
        OS_CLASSIFIER="linux-x86_64"  # Default to Linux
        print_warning "Unknown OS type $OS_TYPE, defaulting to $OS_CLASSIFIER"
    fi
    
    print_info "Detected OS: $OS_TYPE, Architecture: $ARCH_TYPE, using classifier: $OS_CLASSIFIER"
    
    # Try building with the detected classifier first
    print_info "Attempting build with classifier: $OS_CLASSIFIER"
    mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true -Dos.detected.classifier=$OS_CLASSIFIER
    
    if [ $? -eq 0 ]; then
        print_success "primihub-sdk built successfully with classifier: $OS_CLASSIFIER"
    else
        print_warning "Build failed with classifier $OS_CLASSIFIER, trying alternative approach..."
        
        # Try building by skipping protobuf compilation goals
        print_info "Attempting build without protobuf compilation..."
        mvn clean compile -Dmaven.test.skip=true -Dasciidoctor.skip=true
        
        if [ $? -eq 0 ]; then
            print_success "primihub-sdk compiled successfully (protobuf compilation may be incomplete)"
            print_info "Note: Full build may require protoc installation for your platform"
        else
            print_error "Failed to build primihub-sdk with all approaches"
            print_info "This may be due to missing protoc binary for your platform."
            print_info "You may need to install protoc manually or use a different build environment."
            exit 1
        fi
    fi
    
    cd ..
}

# Function to build primihub-service
build_service() {
    print_info "Building primihub-service..."
    
    if [ ! -d "primihub-service" ]; then
        print_error "primihub-service directory not found"
        exit 1
    fi
    
    cd primihub-service
    
    # Build with Maven (skip tests and asciidoctor)
    mvn clean install -Dmaven.test.skip=true -Dasciidoctor.skip=true
    
    if [ $? -eq 0 ]; then
        print_success "primihub-service built successfully"
    else
        print_error "Failed to build primihub-service"
        exit 1
    fi
    
    cd ..
}

# Function to build Docker image
build_docker_image() {
    if ! command_exists docker; then
        print_warning "Docker not available, skipping image build"
        return 0
    fi
    
    print_info "Building Docker image..."
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker daemon is not running. Please start Docker first."
        return 1
    fi
    
    # Generate build number (using timestamp if BUILD_NUMBER is not set)
    BUILD_NUMBER=${BUILD_NUMBER:-$(date +%Y%m%d%H%M%S)}
    
    # Set image tag
    IMAGE_TAG="192.168.99.10/primihub/privacy:${BUILD_NUMBER}"
    
    print_info "Building image: $IMAGE_TAG"
    
    # Build Docker image
    docker build -t "$IMAGE_TAG" -f ./primihub-service/Dockerfile.local ./primihub-service
    
    if [ $? -eq 0 ]; then
        print_success "Docker image built successfully: $IMAGE_TAG"
        
        # Optionally push the image (commented out by default)
        # print_info "Pushing image to registry..."
        # docker push "$IMAGE_TAG"
    else
        print_error "Failed to build Docker image"
        return 1
    fi
}

# Function to display usage
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -s, --skip-docker    Skip Docker image building"
    echo "  -b, --build-number   Set custom build number (default: timestamp)"
    echo "  --sdk-only           Build only primihub-sdk"
    echo "  --service-only       Build only primihub-service"
    echo ""
    echo "Environment variables:"
    echo "  BUILD_NUMBER         Set build number for Docker image tagging"
}

# Parse command line arguments
SKIP_DOCKER=false
BUILD_SDK=true
BUILD_SERVICE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -s|--skip-docker)
            SKIP_DOCKER=true
            shift
            ;;
        -b|--build-number)
            BUILD_NUMBER="$2"
            shift 2
            ;;
        --sdk-only)
            BUILD_SERVICE=false
            shift
            ;;
        --service-only)
            BUILD_SDK=false
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Main execution
main() {
    print_info "Starting PrimiHub Platform build process..."
    
    # Check prerequisites
    check_prerequisites
    
    # Build SDK if requested
    if [ "$BUILD_SDK" = true ]; then
        build_sdk
    fi
    
    # Build Service if requested
    if [ "$BUILD_SERVICE" = true ]; then
        build_service
    fi
    
    # Build Docker image if requested and not skipped
    if [ "$SKIP_DOCKER" = false ] && [ "$BUILD_SERVICE" = true ]; then
        build_docker_image
    fi
    
    print_success "Build process completed successfully!"
}

# Run main function
main "$@"
