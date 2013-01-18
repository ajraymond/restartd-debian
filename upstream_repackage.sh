#!/bin/bash

# Script v1.0

[ -f `basename "$0"` ] || {
    echo "ERROR: This script should be run from the source directory"
    exit 1
}

# Get project name from PWD
PROJ_NAME=`basename "$PWD" | awk -F'/' '{print $NF}' | cut -d'-' -f 1`

[ -f upstream_deliverables ] || {
    echo "ERROR: deliverables file not present"
    exit 1
}
PROJ_FILES=`cat upstream_deliverables`

[ -d ../${PROJ_NAME} ] || {
    echo "ERROR: Project directory not found"
    exit 1
}

[ -f ../${PROJ_NAME}/version ] || {
    echo "ERROR: version file not present"
    exit 1
}
PROJ_VERSION=`cat ../${PROJ_NAME}/version`

# Prepend a project-version/ to the sources in the tarball
eval tar -C ../${PROJ_NAME} --transform "s,^,${PROJ_NAME}-${PROJ_VERSION}/,S" -cvzf ${PROJ_NAME}-${PROJ_VERSION}.tar.gz ${PROJ_FILES}
[ $? -eq 0 ] || {
    echo "ERROR: tar command failed"
    exit 1
}

