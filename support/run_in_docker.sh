#!/usr/bin/env bash

SHOME=`dirname $0`
cd $SHOME

SRCROOT=`cd ..; pwd`
cd $SRCROOT

# Build the Docker image using the current uid/gid so
# repeat iterations of the Jenkins environment can 
# properly cleanup the workspace.
DOCKER_BUILD=`docker build -q \
    --build-arg build_user=${USER} \
    --build-arg build_uid=$(id -u) \
    --build-arg build_gid=$(id -g) \
    -f support/Dockerfile.jenkins \
    support`
DOCKER_IMAGE=`echo $DOCKER_BUILD | awk -F: '{print $2}'`

# Include VCD_CONNECTION as a mounted file and environment variable
VCD_ARGS=""
if [ "$GOVCD_CONFIG" != "" ]; then
    VCD_ARGS="-eGOVCD_CONFIG=$GOVCD_CONFIG -v$GOVCD_CONFIG:$GOVCD_CONFIG"
fi

# Run the Docker container with source code mounted along
# with additional files and environment variables
docker run --rm \
    $VCD_ARGS \
    -v$SRCROOT:$SRCROOT \
    -w$SRCROOT \
    $DOCKER_IMAGE \
    /bin/bash -c "$*"

EC=$?
if [ $EC -ne 0 ]; then
    exit $EC
fi