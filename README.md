# Hello world on NuttX ESP32

Hello world on NuttX ESP32

## Environment

```
PROJECT_NAME=hello-world-on-nuttx-esp32
```

## Clone


```
git clone https://github.com/wurly200a/${PROJECT_NAME}.git
cd ${PROJECT_NAME}
```

## Build

Use a docker image created with https://github.com/wurly200a/builder_nuttx_esp32/blob/main/Dockerfile

```
docker run --rm -it -v ${PWD}:/home/builder/${PROJECT_NAME} -w /home/builder/${PROJECT_NAME} wurly/builder_nuttx_esp32
get_idf
./build.sh
exit
```

## Write FlashROM


```
wget https://github.com/espressif/esp-nuttx-bootloader/releases/download/latest/bootloader-esp32.bin -P src/nuttx/
wget https://github.com/espressif/esp-nuttx-bootloader/releases/download/latest/partition-table-esp32.bin -P src/nuttx/
```

```
python3 -m venv ./venv
. venv/bin/activate
pip3 install esptool==v4.7.0
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 --before default_reset erase_flash
esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 921600 write_flash 0x1000 src/nuttx/bootloader-esp32.bin 0x8000 src/nuttx/partition-table-esp32.bin 0x10000 src/nuttx/nuttx.bin
deactivate
```
