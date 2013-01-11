#!/bin/bash

[ -f `basename "$0"` ] || {
    echo "ERROR: this should be run from the 'project'-debian directory directly"
    exit 1
}

# Remove -debian from the directory name
PROJ_NAME=`basename "$PWD" | awk -F'/' '{print $NF}' | cut -d'-' -f 1`

[ -d ../${PROJ_NAME} ] || {
    echo "ERROR: project directory not present"
    exit 1
}

[ -f ../${PROJ_NAME}/version ] || {
    echo "ERROR: project version file not present"
    exit 1
}
PROJ_VERSION=`cat ../${PROJ_NAME}/version`

# Check that the changelog contains information for this version
grep -q "${PROJ_NAME} (${PROJ_VERSION}-[0-9]\+)" debian/changelog || {
    echo "ERROR: no changelog entry found for version ${PROJ_VERSION}"
    exit 1
}

rm -rf tmpbuild/

cd ../${PROJ_NAME}
./mktarball.sh || {
    echo "ERROR: tarball creation failed"
    exit 1
}
cd - > /dev/null

mkdir tmpbuild || {
    echo "ERROR: could not create tmpbuild directory"
    exit 1
}

mv ../${PROJ_NAME}/${PROJ_NAME}-${PROJ_VERSION}.tar.gz tmpbuild/${PROJ_NAME}_${PROJ_VERSION}.orig.tar.gz || {
    echo "ERROR: could not move tarball archive to build directory"
    exit 1
}

cd tmpbuild/
tar -xvzf ${PROJ_NAME}_${PROJ_VERSION}.orig.tar.gz || {
    echo "ERROR: could not extract archive for build"
    exit 1
}

cp -r ../debian ${PROJ_NAME}-${PROJ_VERSION}/ || {
    echo "ERROR: could not copy debian directory for build"
    exit 1
}

[ -d ${PROJ_NAME}-${PROJ_VERSION}/ ] || {
    echo "ERROR: project directory not found"
    exit 1
}

cd ${PROJ_NAME}-${PROJ_VERSION}/
dpkg-buildpackage || {
    echo "ERROR: package build failed"
    exit 1
}

