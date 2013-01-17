#!/bin/bash

# Usage: ./mkpkg.sh [debuild options]

# Use MODE=host for local compilation, then MODE=pbuilder for final
# verifications on amd64/i386, and to generate source files for upload.
#
# Generated files are put in tmpbuild/.


###############################################
# Environment variables supported by the script
###############################################
# debuild mode: host=source/hostarch; pbuilder=source
MODE="${MODE:=host}"
([ "${MODE}" = pbuilder ] || [ "${MODE}" = host ]) || {
    echo "Invalid MODE chosen"
    exit 1
}

SIGN="${SIGN:=n}"
([ "${SIGN}" = y ] || [ "${SIGN}" = n ]) || {
    echo "Invalid SIGN chosen"
    exit 1
}
###############################################

[ -f `basename "$0"` ] || {
    echo "ERROR: this should be run from the 'project'-debian directory directly"
    exit 1
}

# Remove -debian from the directory name
CPU_ARCH=`uname -m`

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

if [ "${MODE}" = pbuilder ]; then
    (uscan --no-download --verbose | grep -q "Newest version on remote site is ${PROJ_VERSION}") || {
        echo "ERROR: upstream version is not up-to-date"
        exit 1
    }
fi

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

if [ "${SIGN}" = n ]; then
    SIGNOPT=" -us -uc "
else
    SIGNOPT=""
fi

# When doing a pbuilder run, don't need to build binary packages with debuild
if [ "${MODE}" = pbuilder ]; then
    BUILDTYPEOPT=" -S "
else
    BUILDTYPEOPT=""
fi

cd ${PROJ_NAME}-${PROJ_VERSION}/

#lintian complains because of some confusion between ubuntu/debian
debuild ${BUILDTYPEOPT} ${SIGNOPT} "$@" --lintian-opts --pedantic -i -I --show-overrides || {
    echo "ERROR: debuild failed to create source package"
    exit 1
}

if [ "${MODE}" = pbuilder ]; then
    if [ "${CPU_ARCH}" = "x86_64" ]; then
        pbuilder-dist sid amd64 clean || {
            echo "ERROR: pbuilder-dist clean"
            exit 1
        }
        pbuilder-dist sid amd64 update || {
            echo "ERROR: pbuilder-dist update"
            exit 1
        }
        pbuilder-dist sid amd64 build ../${PROJ_NAME}_${PROJ_VERSION}-*.dsc || {
            echo "ERROR: pbuilder-dist build"
            exit 1
        }
    fi

    pbuilder-dist sid i386 clean || {
        echo "ERROR: pbuilder-dist clean"
        exit 1
    }
    pbuilder-dist sid i386 update || {
        echo "ERROR: pbuilder-dist update"
        exit 1
    }
    pbuilder-dist sid i386 build ../${PROJ_NAME}_${PROJ_VERSION}-*.dsc || {
        echo "ERROR: pbuilder-dist build"
        exit 1
    }
fi

