SOPHGO EDK2
###########

Build
=====

1. Install dependencies.

.. highlights::

    .. code:: sh

        sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build uuid-dev gcc-riscv64-unknown-elf

2. Clone repository (maybe you have done this).

.. highlights::

    .. code:: sh

        git clone https://github.com/sophgo/sophgo-edk2.git

3. Enter repository.

.. highlights::

    .. code:: sh

        cd sophgo-edk2

4. Init submodules.

.. highlights::

    .. code:: sh

        git submodule sync
        git submodule update --init --recursive

5. Setup environments.

.. highlights::

    .. code:: sh

        export WORKSPACE=`pwd`
        export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi
        export GCC5_RISCV64_PREFIX=riscv64-unknown-elf-
        source edk2/edksetup.sh

6. Build base tools.

.. highlights::

    .. code:: sh

        make -C edk2/BaseTools

7. Build binaries for SG2042.

.. highlights::

    .. code:: sh

        build -a RISCV64 -t GCC5 -p Platform/Sophgo/SG2042_EVB_Board/SG2042.dsc


.. note::

 - ``-D X64EMU_ENABLE`` is an option to enable MultiArchUefiPkg, an emulator for x64 OpRoms, or not.


8. Final output is ``$WORKSPACE/Build/SG2042_EVB/DEBUG_GCC5/FV/SG2042.fd``.

Deploy
======

1. Mount your SD card (assume your SD card is ``/dev/sdc`` on your PC).

.. highlights::

    .. code:: sh

        sudo mount /dev/sdc1 /mnt

2. Copy ``$WORKSPACE/Build/SG2042_EVB/DEBUG_GCC5/FV/SG2042.fd`` to your SD card.

- Option 1: Replace ``riscv64_Image`` directly.


.. highlights::

    .. code:: sh

        sudo cp $WORKSPACE/Build/SG2042_EVB/DEBUG_GCC5/FV/SG2042.fd /mnt/riscv64/riscv64_Image


- Option 2: Write ``conf.ini`` in the ``0:riscv64/`` directory.

  The example is as follows:

.. highlights::

    .. code:: ini

        [sophgo-config]

        [devicetree]
        name = mango-sophgo-x8evb.dtb

        [kernel]
        name = SG2042.fd

        [eof]

Run
===

1. Connect your serial port to RISC-V debug port (UART0).

2. Power on your board, wait untill entering the UEFI shell.

3. Boot Linux kernel using GRUB2, type commands in the UEFI Shell as follows or put a ``startup.nsh`` file in your SD card.

.. highlights::

    .. code:: sh

        fs0:
        grubriscv64.efi
