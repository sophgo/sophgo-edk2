SOPHGO EDK2
###########

Build
=====

Install dependencies.
----------------------
    .. code:: sh

        sudo apt-get install autoconf automake autotools-dev curl python3 libmpc-dev libmpfr-dev libgmp-dev gawk build-essential bison flex texinfo gperf libtool patchutils bc zlib1g-dev libexpat-dev ninja-build uuid-dev gcc-riscv64-unknown-elf

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

Setup environments.
------------------
    .. code:: sh

        export WORKSPACE=`pwd`
        export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi
        export GCC5_RISCV64_PREFIX=riscv64-unknown-elf-
        source edk2/edksetup.sh

Build base tools.
-------------------
    .. code:: sh

        make -C edk2/BaseTools

Build binaries.
---------------------

Final output is ``$WORKSPACE/Build/SG2044/DEBUG_GCC5/FV/SG2044.fd``.

    .. code:: sh
    
        build -a RISCV64 -t GCC5 -b DEBUG -p Platform/Sophgo/SG2044Pkg/SG2044.dsc


More building options:
------------------------   
   
1. Build Debug version or Release version: use ``-b DEBUG`` or  ``-b RELEASE``.
   
   Final output is in ``$WORKSPACE/Build/SG2044/DEBUG_GCC5/FV/SG2044.fd``
   
    .. code:: sh
      
        # build debug version
        build -a RISCV64 -t GCC5 -b DEBUG -p Platform/Sophgo/SG2044Pkg/SG2044.dsc
        # build release version
        build -a RISCV64 -t GCC5 -b RELEASE -p Platform/Sophgo/SG2044Pkg/SG2044.dsc

2. Enable ``MultiArchUefiPkg`` for graphics cards supporting UEFI: use ``-D X64EMU_ENABLE``.

    .. code:: sh

        build -a RISCV64 -t GCC5 -b RELEASE -D X64EMU_ENABLE -p Platform/Sophgo/SG2044Pkg/SG2044.dsc

   
   ``-D X64EMU_ENABLE`` is an option to enable MultiArchUefiPkg, an emulator for x64 OpRoms, or not.
   Please see the link https://github.com/intel/MultiArchUefiPkg for more details.
   If you use ``-b DEBUG`` to replace ``-b RELEASE`` to build, MultiArchUefiPkg maybe not work.

3. Enable ACPI: use ``-D ACPI_ENABLE``.

    .. code:: sh

        build -a RISCV64 -t GCC5 -b DEBUG -D ACPI_ENABLE -p Platform/Sophgo/SG2044Pkg/SG2044.dsc

   ``-D ACPI_ENABLE`` is an option to enable ACPI. ACPI support is currently provided for SG2044 EVB. To enable the ACPI feature in the linux kernel on the SG2044 platform, see the link https://github.com/sophgo/linux-riscv/tree/sg2044-dev-6.12.

Deploy
======

1. Mount your SD card (assume your SD card is ``/dev/sdc`` on your PC).

    .. code:: sh

        sudo mount /dev/sdc1 /mnt

2. Copy ``SG2044.fd``  to your SD card in the ``0:riscv64/`` directory.
   
    .. code:: sh
        
        sudo cp SG2044.fd /mnt/riscv64/ 
