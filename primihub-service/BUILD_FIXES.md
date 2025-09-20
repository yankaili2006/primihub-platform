# Primihub Service Build Fixes

This document outlines the steps taken to fix the build issues for the primihub-service project.

## Problem Description
The build was failing due to:
1. Network connectivity issues when downloading dependencies
2. Missing protoc compiler
3. Version mismatch between protoc compiler and protobuf/gRPC dependencies
4. Missing annotations in generated protobuf code

## Fix Steps

### 1. Make build.sh executable
```bash
chmod +x primihub-service/build.sh
```

### 2. Install protoc compiler manually
```bash
# Install protoc via Homebrew
brew install protobuf

# Verify installation
protoc --version  # Should show libprotoc 32.1
```

### 3. Configure Maven to use system protoc
Updated `primihub-service/biz/pom.xml` to specify the system protoc executable:
```xml
<configuration>
    <protocExecutable>/opt/homebrew/bin/protoc</protocExecutable>
    <pluginArtifact>io.grpc:protoc-gen-grpc-java:1.60.2:exe:${os.detected.classifier}</pluginArtifact>
    <pluginId>grpc</pluginId>
    <protoSourceRoot>src/main/resources/proto</protoSourceRoot>
</configuration>
```

### 4. Update gRPC dependencies
Updated the grpc-all dependency from version 1.10.1 to 1.60.2 to match the protoc-gen-grpc-java version:
```xml
<dependency>
    <groupId>io.grpc</groupId>
    <artifactId>grpc-all</artifactId>
    <version>1.60.2</version>
</dependency>
```

### 5. Add explicit protobuf-java dependency
Added protobuf-java dependency to match the protoc compiler version:
```xml
<dependency>
    <groupId>com.google.protobuf</groupId>
    <artifactId>protobuf-java</artifactId>
    <version>3.21.12</version>
</dependency>
```

## Current Status
The build process should now work correctly with:
- protoc version: 32.1
- grpc-all version: 1.60.2  
- protobuf-java version: 3.21.12
- protoc-gen-grpc-java version: 1.60.2

## Running the Build
```bash
cd primihub-service
./build.sh
```

## Notes
- The protoc version (32.1) and protobuf-java version (3.21.12) should be kept in sync
- The grpc-all version (1.60.2) should match the protoc-gen-grpc-java version
- The system protoc path may need to be adjusted if installed in a different location
