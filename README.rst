SOPHGO EDK2
###########

This repository builds UEFI firmware for SOPHGO RISC-V platforms:

- **SG2044**: SG2044 EVB, SRA3 server boards, SD3 boards (firmware.bin/img
  packaging flow via ``tools/pack``)
- **SG2042**: SG2042 EVB, Milk-V Pioneer, SRA1 server boards (firmware.bin/img
  packaging flow via ``tools/pack``)

All platforms build from the shared ``devel-sophgo`` branch.

Build
=====

Install dependencies.
----------------------
    .. code:: sh

        sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build uuid-dev gcc-riscv64-unknown-elf acpica-tools parted kpartx dosfstools mtools openssl

Clone repository (maybe you have done this).
---------------------------------------------
    .. code:: sh

        git clone https://github.com/sophgo/sophgo-edk2.git

Enter repository.
------------------
    .. code:: sh

        cd sophgo-edk2

Init submodules.
-----------------
    .. code:: sh

        git submodule sync
        git submodule update --init --recursive

Build firmware.
----------------

The unified build entry is ``tools/envsetup.sh``. Select the chip and
platform, source the script, then run ``build_rv_all``:

    .. code:: sh

        # SG2044 example
        CHIP=sg2044 PLAT=SD3-10 source tools/envsetup.sh
        build_rv_all

        # SG2042 example (CHIP=mango; adds -D ACPI_ENABLE automatically)
        CHIP=mango PLAT=SG2042-EVB source tools/envsetup.sh
        build_rv_all

The final outputs are ``Build/$PLAT/RELEASE_GCC/FV/${PLAT^^}.fd``,
``firmware.bin`` and ``firmware.img`` under ``Build/$PLAT/firmware/``.

Available platforms
--------------------

    - SG2044 (CHIP=sg2044): ``SD3-10``, ``SD3-10-LB``, ``SD3-12``,
      ``SRA3-40``, ``SRA3-40-LB``, ``SRA3-40-8``, ``SRM31``
      (default ``PLAT=SD3-10``)
    - SG2042 (CHIP=mango): ``SG2042-EVB``, ``MilkV-Pioneer``, ``SRA1-20``

More building options:
------------------------

1. Build Debug version or Release version: use ``-b DEBUG`` or ``-b RELEASE``.

   ``build_rv_all`` always builds RELEASE. To build a DEBUG FD manually:

    .. code:: sh

        export WORKSPACE=`pwd`
        export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi
        source edk2/edksetup.sh
        make -C edk2/BaseTools
        # SG2044 example (toolchain tag GCC, GCC5 was removed in tools_def v3.06)
        build -a RISCV64 -t GCC -b DEBUG -p Platform/Sophgo/SG2044Pkg/SD3-10/SD3-10.dsc
        # SG2042 example (ACPI is required on SG2042)
        build -a RISCV64 -t GCC -b DEBUG -D ACPI_ENABLE -p Platform/Sophgo/SG2042Pkg/SG2042-EVB/SG2042-EVB.dsc

2. Enable ``MultiArchUefiPkg`` for graphics cards supporting UEFI: use ``-D X64EMU_ENABLE``.

    .. code:: sh

        build -a RISCV64 -t GCC -b RELEASE -D X64EMU_ENABLE -p Platform/Sophgo/SG2044Pkg/SD3-10/SD3-10.dsc


   ``-D X64EMU_ENABLE`` is an option to enable MultiArchUefiPkg, an emulator for x64 OpRoms, or not.
   Please see the link https://github.com/intel/MultiArchUefiPkg for more details.
   If you use ``-b DEBUG`` to replace ``-b RELEASE`` to build, MultiArchUefiPkg maybe not work.

3. Enable ACPI: use ``-D ACPI_ENABLE``.

   SG2042 always builds with ACPI enabled (the unified build does this
   automatically). For SG2044 it is optional.

   Make sure the iASL (Intel ACPI Source Language Optimizing Compiler and Disassembler) is the latest version ``20241212``.

   The iASL compiler/disassembler is a fully-featured translator for the ACPI Source Language (ASL) and ACPI binary data tables.
   Please see the link https://www.intel.com/content/www/us/en/content-details/772895/iasl-acpi-source-language-optimizing-compiler-disassembler-user-guide-doc.html for more details.

   The install steps as follows.

   .. code:: sh

        # Download source code
        git clone https://github.com/acpica/acpica.git

        cd acpica

        # Compile
        make

        # Install
        sudo make install

        # Check version
        iasl -v
        # # Show the info
        Intel ACPI Component Architecture
        ASL+ Optimizing Compiler/Disassembler version 20241212
        Copyright (c) 2000 - 2023 Intel Corporation

   ``-D ACPI_ENABLE`` is an option to enable ACPI. ACPI support is currently provided for SG2044 EVB. To use the ACPI feature in the Linux Kernel on the SG2044 platform, see the link https://github.com/sophgo/linux-riscv/tree/sg2044-dev-6.12.

    .. code:: sh

        build -a RISCV64 -t GCC -b DEBUG -D ACPI_ENABLE -p Platform/Sophgo/SG2044Pkg/SD3-10/SD3-10.dsc


Deploy
======

1. Mount your SD card (assume your SD card is ``/dev/sdc`` on your PC).

    .. code:: sh

        sudo mount /dev/sdc1 /mnt

2. Copy the firmware FD to your SD card in the ``0:riscv64/`` directory.

    .. code:: sh

        # SG2044
        sudo cp SG2044.fd /mnt/riscv64/
        # SG2042
        sudo cp SG2042-EVB.fd /mnt/riscv64/
