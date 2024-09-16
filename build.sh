#!/bin/bash

ESP32_MODULE_NAME=esp32
ESP32_BOARD_NAME=esp32-devkitc

MY_APP_NAME=hello
BUILD_PREFIX_DIR=src

MY_APP_DIR=${BUILD_PREFIX_DIR}/${MY_APP_NAME}

NUTTX_DIR=${BUILD_PREFIX_DIR}/nuttx
NUTTX_GIT_URL=https://github.com/apache/incubator-nuttx
NUTTX_GIT_TAG=nuttx-12.0.0

NUTTX_APPS_DIR=${BUILD_PREFIX_DIR}/apps
NUTTX_APPS_GIT_URL=https://github.com/apache/incubator-nuttx-apps
NUTTX_APPS_GIT_TAG=nuttx-12.0.0
NUTTX_APPS_EXTERNAL_DIR=${NUTTX_APPS_DIR}/external

function configure() {
    # clone incubator-nuttx
    if [ ! -d ${NUTTX_DIR} ]; then
        mkdir -p $(dirname ${NUTTX_DIR})
        git clone ${NUTTX_GIT_URL} -b ${NUTTX_GIT_TAG} ${NUTTX_DIR}
    fi

    # clone incubator-nuttx-apps
    if [ ! -d ${NUTTX_APPS_DIR} ]; then
        mkdir -p $(dirname ${NUTTX_APPS_DIR})
        git clone ${NUTTX_APPS_GIT_URL} -b ${NUTTX_APPS_GIT_TAG} ${NUTTX_APPS_DIR}
    fi

    # apps/external setting
    if [ ! -d ${NUTTX_APPS_EXTERNAL_DIR} ]; then
        mkdir -p ${NUTTX_APPS_EXTERNAL_DIR}
        cat << 'EOS' > ${NUTTX_APPS_EXTERNAL_DIR}/Makefile
MENUDESC = "External"

include $(APPDIR)/Directory.mk
EOS
        cat << 'EOS' > ${NUTTX_APPS_EXTERNAL_DIR}/Make.defs
include $(wildcard $(APPDIR)/external/*/Make.defs)
EOS
    fi

    if [ ! -d ${NUTTX_APPS_EXTERNAL_DIR}/${MY_APP_NAME} ]; then
        ln -s $(pwd)/${MY_APP_DIR} ${NUTTX_APPS_EXTERNAL_DIR}/${MY_APP_NAME}
    fi

    # configure
    cd ${NUTTX_DIR}

    ./tools/configure.sh -l ${ESP32_BOARD_NAME}:nsh

    kconfig-tweak --file .config --enable CONFIG_BOARDCTL_ROMDISK
    kconfig-tweak --file .config --set-str CONFIG_NSH_SCRIPT_REDIRECT_PATH ""
    kconfig-tweak --file .config --set-val CONFIG_FS_ROMFS_CACHE_FILE_NSECTORS 1

    kconfig-tweak --file .config --disable CONFIG_NSH_CONSOLE_LOGIN

    kconfig-tweak --file .config --enable CONFIG_FS_ROMFS
    kconfig-tweak --file .config --enable CONFIG_NSH_ROMFSETC
    kconfig-tweak --file .config --enable CONFIG_NSH_ARCHROMFS

    kconfig-tweak --file .config --enable CONFIG_FS_FAT

    kconfig-tweak --file .config --enable CONFIG_APP_HELLO
    kconfig-tweak --file .config --set-val CONFIG_APP_HELLO_PRIORITY 100
    kconfig-tweak --file .config --set-val CONFIG_APP_HELLO_STACKSIZE 2048

    # auto executing setting
    cd boards/xtensa/${ESP32_MODULE_NAME}/${ESP32_BOARD_NAME}/include

    if [ -e rc.sysinit.template ]; then
        rm rc.sysinit.template
    fi
    if [ -e rcS.template ]; then
        rm rcS.template
    fi
    
    touch rc.sysinit.template
    touch rcS.template
    echo "#! /bin/nsh" > rcS.template
    echo "hello" >> rcS.template
    ../../../../../tools/mkromfsimg.sh ../../../../../
    cd ../../../../..
}

function clean() {
    cd ${NUTTX_DIR}
    make clean_context all
    make clean
    cd ../..
}

function build() {
    cd ${NUTTX_DIR}
    make -j$(nproc)
    cd ../..
}

function allclean() {
    echo "Cleaning up generated files..."
    if [ -d ${NUTTX_DIR} ]; then
        cd ${NUTTX_DIR}
        make clean
        cd ../..
        rm -rf ${NUTTX_DIR}
    fi
    if [ -d ${NUTTX_APPS_DIR} ]; then
        rm -rf ${NUTTX_APPS_DIR}
    fi
}

case "$1" in
    allclean)
        allclean
        ;;
    clean)
        clean
        ;;
    configure)
        configure
        ;;
    build)
        build
        ;;
    *)
        configure
        build
        ;;
esac
