#!/bin/bash

# --- Configuration ---
IMAGE_NAME="newluminous/pyspark"
ENV_FILE=".env"

load_env() {
    if [ -f "$1" ]; then
        echo "Loading environment variables from $1"
        export $(grep -v '^#' "$1" | xargs)
    else
        echo "Warning: $1 file not found. Using default values."
    fi
}
load_env "$ENV_FILE"

# Use values from .env (e.g., SPARK_VERSION) or defaults for the build args
BUILD_SPARK_VERSION=${SPARK_VERSION:-"3.3.3"}
BUILD_PYTHON_VERSION=${PYTHON_VERSION:-"3.9"}
BUILD_HADOOP_USER_NAME=${HADOOP_USER_NAME:-"spark"}


# --- Output effective build arguments ---
echo "-------------------------------------"
echo "Building Docker image: $IMAGE_NAME"
echo "Using build arguments:"
echo "  SPARK_VERSION_ARG:          $BUILD_SPARK_VERSION"
echo "  PYTHON_VERSION_ARG:         $BUILD_PYTHON_VERSION"
echo "-------------------------------------"

# --- Docker Build Command ---
docker build \
    --build-arg SPARK_VERSION_ARG="$BUILD_SPARK_VERSION" \
    --build-arg PYTHON_VERSION_ARG="$BUILD_PYTHON_VERSION" \
    -t "$IMAGE_NAME" .

echo "-------------------------------------"
echo "Docker build complete. Image: $IMAGE_NAME"
echo "-------------------------------------"