#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2020 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=potter
VENDOR=motorola

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in

        # Fix xml version
        product/etc/permissions/vendor.qti.hardware.data.connection-V1.0-java.xml | product/etc/permissions/vendor.qti.hardware.data.connection-V1.1-java.xml)
            sed -i 's/xml version="2.0"/xml version="1.0"/' "${2}"
            ;;

        # Fix fingerprint UHID
        vendor/etc/init/android.hardware.biometrics.fingerprint@2.1-service.rc)
            sed -i 's/group system input 9015/group system uhid input 9015/' "${2}"
            ;;

        # memset shim
        vendor/bin/charge_only_mode)
            "${PATCHELF}" --add-needed libmemset_shim.so "${2}"
            ;;

        # qsap shim
        vendor/lib64/libmdmcutback.so)
            "${PATCHELF}" --add-needed libqsap_shim.so "${2}"
            ;;

        vendor/lib/libmot_gpu_mapper.so)
            sed -i "s/libgui/libwui/" "${2}"
            ;;

        # Fix missing symbols
        vendor/lib64/libril-qc-hal-qmi.so)
            "${PATCHELF}" --add-needed "libcutils_shim.so" "${2}"
            ;;


        # Fix missing symbols
        vendor/lib/libmot_gpu_mapper.so)
            for  CAMERA_SHIM in $(grep -L "libshims_camera.so" "${2}"); do
                "${PATCHELF}" --add-needed "libshims_camera.so" "$CAMERA_SHIM"
            done
            ;;

        product/lib/lib-imscamera.so)
            for  CAMERA_SHIM in $(grep -L "libshims_camera.so" "${2}"); do
                "${PATCHELF}" --add-needed "libshims_camera.so" "$CAMERA_SHIM"
            done
            ;;

        product/lib/lib-imsvideocodec.so)
            for  CAMERA_SHIM in $(grep -L "libshims_camera.so" "${2}"); do
                "${PATCHELF}" --add-needed "libshims_camera.so" "$CAMERA_SHIM"
            done
            ;;

        product/lib64/lib-imscamera.so)
            for  CAMERA_SHIM in $(grep -L "libshims_camera.so" "${2}"); do
                "${PATCHELF}" --add-needed "libshims_camera.so" "$CAMERA_SHIM"
            done
            ;;

        product/lib64/lib-imsvideocodec.so)
            for  CAMERA_SHIM in $(grep -L "libshims_camera.so" "${2}"); do
                "${PATCHELF}" --add-needed "libshims_camera.so" "$CAMERA_SHIM"
            done
            ;;

    esac
}

    # Initialize the helper
    setup_vendor "${DEVICE}" "${VENDOR}" "${ANDROID_ROOT}" true "${CLEAN_VENDOR}"

    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" "${KANG}" --section "${SECTION}"

"${MY_DIR}/setup-makefiles.sh"