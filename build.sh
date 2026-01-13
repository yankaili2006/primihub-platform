#!/bin/bash

# Simple build script for primihub platform
echo "Building primihub platform..."

# Create target directories if they don't exist
mkdir -p primihub-service/application/target
mkdir -p primihub-service/gateway/target

# Build using Docker Maven with shared .m2 repository
echo "Building SDK and Service together..."
docker run --rm \
  -v $(pwd):/opt \
  -v maven-repo:/root/.m2 \
  -w /opt \
  maven:3.8.6-openjdk-8 \
  bash -c "mvn -f primihub-sdk/pom.xml clean install -Dmaven.test.skip=true -DskipTests=true -q && \
           mvn -f primihub-service/pom.xml clean install -Dmaven.test.skip=true -DskipTests=true -q"

echo "Build completed!"
