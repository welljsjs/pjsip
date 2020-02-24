#!/bin/sh

# This script has to be run from the root of the (custom)
# pjproject (pjsip) repo (pjsip for Apple platforms)

# Environment Variables
OPENSSL_VERSION="1.1.1c"
PJSIP_VERSION="2.10"
OPUS_VERSION="1.3.1"
MACOS_MIN_SDK_VERSION="10.13"
IOS_MIN_SDK_VERSION="9.0"

# This script is non-interactive - the only way to specify custom parameters
# is via environment variables.
# There might be a future version of this script that supports an "-i" (interactive)
# option to provide a CLI.
# Not yet implemented.

# The compiled libraries will have the following directory structure:
# - /lib/
#       - [dependency]/
#           - [version]/
#               - iOS/
#                   - [lib-name].a
#               - macOS/
#                   - [lib-name].a
# This way, we can upgrade to a newer version of a dependency but still keep
# the old ones in place in case the upgrade has some unwanted side-effects.

# see http://stackoverflow.com/a/3915420/318790
function realpath() { echo $(
    cd $(dirname "$1")
    pwd
)/$(basename "$1"); }

# Important globals
__FILE__=$(realpath "$0")
__DIR__=$(dirname "${__FILE__}")
LIB_DIR="${__DIR__}/lib" # This is where we copy the libraries to once they are compiled.
BUILD_DIR="${__DIR__}/build"
OPENSSL_BUILD_DIR="${BUILD_DIR}/openssl"
OPUS_BUILD_DIR="${BUILD_DIR}/opus"
PJSIP_BUILD_DIR="${BUILD_DIR}/pjproject"
OPENSSL_LIB_DIR="${LIB_DIR}/openssl/${OPENSSL_VERSION}"
OPUS_LIB_DIR="${LIB_DIR}/opus/${OPUS_VERSION}"
PJSIP_LIB_DIR="${LIB_DIR}/pjsip/${PJSIP_VERSION}"
OPENSSL_BUILD_SCRIPT="${__DIR__}/openssl/openssl.sh"
OPUS_BUILD_SCRIPT="${__DIR__}/opus.sh"
PJSIP_BUILD_SCRIPT="${__DIR__}/pjsip.sh"

function openssl() {
    # If there are no libs or the specific version is not present, create the directory for that version.
    if [ ! -d "${OPENSSL_LIB_DIR}" ]; then
        mkdir -p "${OPENSSL_LIB_DIR}"

        echo "OpenSSL libs for specified version does not exist - building OpenSSL ${OPENSSL_VERSION} ..."

        "${OPENSSL_BUILD_SCRIPT}" "--version=${OPENSSL_VERSION}" "--reporoot=${OPENSSL_BUILD_DIR}"

        cp -r "${OPENSSL_BUILD_DIR}/lib" "${OPENSSL_LIB_DIR}/"
        cp -r "${OPENSSL_BUILD_DIR}/include" "${OPENSSL_LIB_DIR}/"

        echo "Finished building OpenSSL"
    else
        echo "OpenSSL libs for the specified version exist - NOT rebuilding OpenSSL (delete specific version [${OPENSSL_LIB_DIR}] to force a rebuild)"
    fi
}

function opus() {
    # If there are no libs or the specific version is not present, create the directory for that version.
    if [ ! -d "${OPUS_LIB_DIR}" ]; then
        mkdir -p "${OPUS_LIB_DIR}"

        echo "Opus libs for specified version does not exist - building Opus ${OPUS_VERSION} ..."

        "${OPUS_BUILD_SCRIPT}" "${OPUS_BUILD_DIR}"

        cp -r "${OPUS_BUILD_DIR}/dependencies/"* "${OPUS_LIB_DIR}/"

        echo "Finished building Opus"
    else
        echo "Opus libs for the specified version exist - NOT rebuilding Opus (delete specific version [${OPUS_LIB_DIR}] to force a rebuild)"
    fi
}

function pjsip() {
    # If there are no libs or the specific version is not present, create the directory for that version.
    if [ ! -d "${PJSIP_LIB_DIR}" ]; then
        mkdir -p "${PJSIP_LIB_DIR}"

        echo "PJSIP libs for specified version does not exist - building PJSIP ${PJSIP_VERSION} ..."

        "${PJSIP_BUILD_SCRIPT}" "${PJSIP_BUILD_DIR}" --with-openssl "${OPENSSL_LIB_DIR}" --with-opus "${OPUS_LIB_DIR}"

        # Create subdirectories for pjsip modules
        mkdir -p "${PJSIP_LIB_DIR}/pjlib"
        mkdir -p "${PJSIP_LIB_DIR}/pjlib-util"
        mkdir -p "${PJSIP_LIB_DIR}/pjmedia"
        mkdir -p "${PJSIP_LIB_DIR}/pjnath"
        mkdir -p "${PJSIP_LIB_DIR}/pjsip"
        mkdir -p "${PJSIP_LIB_DIR}/third_party"

        # Copy modules (libraries and headers)
        cp -r "${PJSIP_BUILD_DIR}/src/pjlib/lib" "${PJSIP_LIB_DIR}/pjlib/"
        cp -r "${PJSIP_BUILD_DIR}/src/pjlib/include" "${PJSIP_LIB_DIR}/pjlib/"

        cp -r "${PJSIP_BUILD_DIR}/src/pjlib-util/lib" "${PJSIP_LIB_DIR}/pjlib-util/"
        cp -r "${PJSIP_BUILD_DIR}/src/pjlib-util/include" "${PJSIP_LIB_DIR}/pjlib-util/"

        cp -r "${PJSIP_BUILD_DIR}/src/pjmedia/lib" "${PJSIP_LIB_DIR}/pjmedia/"
        cp -r "${PJSIP_BUILD_DIR}/src/pjmedia/include" "${PJSIP_LIB_DIR}/pjmedia/"

        cp -r "${PJSIP_BUILD_DIR}/src/pjnath/lib" "${PJSIP_LIB_DIR}/pjnath/"
        cp -r "${PJSIP_BUILD_DIR}/src/pjnath/include" "${PJSIP_LIB_DIR}/pjnath/"

        cp -r "${PJSIP_BUILD_DIR}/src/pjsip/lib" "${PJSIP_LIB_DIR}/pjsip/"
        cp -r "${PJSIP_BUILD_DIR}/src/pjsip/include" "${PJSIP_LIB_DIR}/pjsip/"

        cp -r "${PJSIP_BUILD_DIR}/src/third_party/lib" "${PJSIP_LIB_DIR}/third_party/"
        cp -r "${PJSIP_BUILD_DIR}/src/third_party/include" "${PJSIP_LIB_DIR}/third_party/"

        echo "Finished building PJSIP"
    else
        echo "PJSIP libs for the specified version exist - NOT rebuilding PJSIP (delete specific version [${PJSIP_LIB_DIR}] to force a rebuild)"
    fi
}

openssl
opus
pjsip
