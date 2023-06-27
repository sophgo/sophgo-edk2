SOPHGO EDK2
###########

Build
=====

1. Install dependencies

:code:`$sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build uuide-dev gcc-riscv64-unknown-elf`

2. Clone this repository(maybe you have done this)

:code:`git clone https://github.com/sophgo/sophgo-edk2.git`

3. Enter the root of this repository

:code:`cd sophgo-edk2`

4. Init submodules

:code:`git submodule sync`

:code:`git submodule update --init --recursive`

5. Setup environments

:code:`export WORKSPACE=`pwd``

:code:`export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi`

:code:`export GCC5_RISCV64_PREFIX=riscv64-unknown-elf-`

:code:`source edk2/edksetup.sh`

6. Build base tools

:code:`make -C edk2/BaseTools`

7. Build edk2 binaries of SG2042

:code:`build -a RISCV64 -t GCC5 -p      Platform/Sophgo/SG2042Pkg/SG2042_EVB_v1_0_Board/SG2042.dsc`

8. Final output is $WORKSPACE/Build/SG2042_EVB_v1_0/DEBUG_GCC5/FV/SG2042.fd

Deploy
======

1. Mount your SD card(assume your SD card is /dev/sdc in your PC)

:code:`sudo mount /dev/sdc1 /mnt`

1. Copy $WORKSPACE/Build/SG2042_EVB_v1_0/DEBUG_GCC5/FV/SG2042.fd to your SD card and replace fw_jump.bin

:code:`sudo cp $WORKSPACE/Build/SG2042_EVB_v1_0/DEBUG_GCC5/FV/SG2042.fd /mnt/riscv64/fw_jump.bin`

Run
===

1. Connect your serial port to RISC-V debug port(UART0)

2. Power on your board, wait untill entering the UEFI shell

3. Boot grub

:code:`>>fs0:`

:code:`>>grubriscv64.efi`
