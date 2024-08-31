#!/bin/bash

MY_APP_NAME=hello
OS_BUILD_PREFIX=src

NUTTX_DIR=${OS_BUILD_PREFIX}/nuttx
NUTTX_GIT_URL=https://github.com/apache/incubator-nuttx
NUTTX_GIT_TAG=nuttx-12.5.1

NUTTX_APPS_DIR=${OS_BUILD_PREFIX}/apps
NUTTX_APPS_GIT_URL=https://github.com/apache/incubator-nuttx-apps
NUTTX_APPS_GIT_TAG=nuttx-12.5.1

if [ ! -d ${NUTTX_DIR} ]; then
    mkdir -p $(dirname ${NUTTX_DIR})
    git clone ${NUTTX_GIT_URL} -b ${NUTTX_GIT_TAG} ${NUTTX_DIR}
fi

if [ ! -d ${NUTTX_APPS_DIR} ]; then
    mkdir -p $(dirname ${NUTTX_APPS_DIR})
    git clone ${NUTTX_APPS_GIT_URL} -b ${NUTTX_APPS_GIT_TAG} ${NUTTX_APPS_DIR}
fi

NUTTX_APPS_EXTERNAL_DIR=${NUTTX_APPS_DIR}/external

if [ ! -d ${NUTTX_APPS_EXTERNAL_DIR} ]; then
    mkdir -p ${NUTTX_APPS_EXTERNAL_DIR}
    cat << 'EOS' > ${NUTTX_APPS_EXTERNAL_DIR}/Makefile
MENUDESC = "Extenal"

include $(APPDIR)/Directory.mk
EOS
    cat << 'EOS' > ${NUTTX_APPS_EXTERNAL_DIR}/Make.defs
include $(wildcard $(APPDIR)/external/*/Make.defs)
EOS
fi

if [ ! -d ${NUTTX_APPS_EXTERNAL_DIR}/${MY_APP_NAME} ]; then
    ln -s $(pwd)/${MY_APP_NAME} ${NUTTX_APPS_EXTERNAL_DIR}/${MY_APP_NAME}
fi

cd ${OS_BUILD_PREFIX}/nuttx

#make clean_context all
#make clean

./tools/configure.sh -l esp32-devkitc:nsh

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

cd boards/xtensa/esp32/esp32-devkitc/include
rm rc.sysinit.template
touch rc.sysinit.template
rm rcS.template
touch rcS.template
echo "#! /bin/nsh" > rcS.template
echo "hello" >> rcS.template
../../../../../tools/mkromfsimg.sh ../../../../../
cd ../../../../..

make -j$(nproc)

cd ../..
