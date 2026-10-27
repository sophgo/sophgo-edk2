#!/bin/bash
# Standalone SG2042 (mango) firmware build environment for sophgo-edk2.
# zsbl/fw_dynamic/fip/dtb/dtbo come pre-built from edk2-non-osi, so no
# opensbi/zsbl source checkout is needed. Function names and layout
# follow bootloader-riscv/scripts/envsetup.sh (mango branches).

RV_EDKII_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RV_OUTPUT_DIR="$RV_EDKII_SRC_DIR/Build/${PLAT:-SRA1-20}"
RV_FIRMWARE_INSTALL_DIR="$RV_OUTPUT_DIR/firmware"
RV_FIRMWARE="$RV_EDKII_SRC_DIR/edk2-non-osi/Silicon/Sophgo/SG2042/Boot"

CHIP=${CHIP:-mango}
PLAT=${PLAT:-SRA1-20}
MANGO_PLAT_LIST='SG2042-EVB MilkV-Pioneer SRA1-20'

RISCV64_ELF_CROSS_COMPILE=${RISCV64_ELF_CROSS_COMPILE:-"riscv64-unknown-elf-"}

source "$RV_EDKII_SRC_DIR/tools/sign.sh"

function show_rv_env()
{
	echo "CHIP: $CHIP"
	echo "PLAT: $PLAT"
	echo "RISCV64_ELF_CROSS_COMPILE: $RISCV64_ELF_CROSS_COMPILE"
	echo "RV_EDKII_SRC_DIR: $RV_EDKII_SRC_DIR"
	echo "RV_OUTPUT_DIR: $RV_OUTPUT_DIR"
	echo "RV_FIRMWARE_INSTALL_DIR: $RV_FIRMWARE_INSTALL_DIR"
	echo "RV_FIRMWARE: $RV_FIRMWARE"
}

function show_rv_functions()
{
	echo "build_rv_edk2			-build EDKII bin"
	echo "clean_rv_edk2			-clean EDKII build"
	echo "build_pack			-build the pack utility"
	echo "build_rv_firmware		-prepare firmware components"
	echo "build_rv_firmware_bin		-build firmware bin"
	echo "build_rv_firmware_image		-build firmware image"
	echo "build_rv_all			-build firmware bin and image"
	echo "show_rv_env			-show environment variables"
	echo "show_rv_functions		-show this message"
}

function build_pack()
{
	pushd "$RV_EDKII_SRC_DIR/tools/pack"
	make clean
	make
	popd
}

function build_rv_edk2()
{
	pushd $RV_EDKII_SRC_DIR

	export WORKSPACE=$RV_EDKII_SRC_DIR
	export PACKAGES_PATH=$WORKSPACE/edk2:$WORKSPACE/edk2-platforms:$WORKSPACE/edk2-non-osi:$WORKSPACE/external-modules
	export EDK_TOOLS_PATH=$WORKSPACE/edk2/BaseTools

	# Auto-detect edk2 toolchain tag: GCC5 was removed in tools_def v3.06
	if grep -q "Remove.*GCC5" "$EDK_TOOLS_PATH/Conf/tools_def.template" 2>/dev/null; then
		local EDK2_TOOLCHAIN=GCC
	else
		local EDK2_TOOLCHAIN=GCC5
	fi
	export ${EDK2_TOOLCHAIN}_RISCV64_PREFIX=$RISCV64_ELF_CROSS_COMPILE

	source edk2/edksetup.sh

	make -C edk2/BaseTools -j$(nproc)

	TARGET=RELEASE

	build -a RISCV64 -t $EDK2_TOOLCHAIN -b $TARGET -D ACPI_ENABLE -p Platform/Sophgo/SG2042Pkg/${PLAT}/${PLAT}.dsc

	popd
}

function clean_rv_edk2()
{
	rm -rf $RV_EDKII_SRC_DIR/Build/${PLAT}

	pushd $RV_EDKII_SRC_DIR/edk2/BaseTools
	make clean
	popd
}

function build_rv_firmware()
{
	mkdir -p $RV_FIRMWARE_INSTALL_DIR
	if [ ! -f $RV_FIRMWARE_INSTALL_DIR/fip.bin ]; then
		cp -v $RV_FIRMWARE/fip.bin $RV_FIRMWARE_INSTALL_DIR/fip.bin
	fi

	cp -v $RV_FIRMWARE/zsbl.bin $RV_FIRMWARE_INSTALL_DIR
	cp -v $RV_FIRMWARE/fw_dynamic.bin $RV_FIRMWARE_INSTALL_DIR
	cp -v $RV_FIRMWARE/mango-*.dtb $RV_FIRMWARE_INSTALL_DIR
	cp -v $RV_FIRMWARE/mango-*.dtbo $RV_FIRMWARE_INSTALL_DIR

	build_pack
	cp -v "$RV_EDKII_SRC_DIR/tools/pack/pack" $RV_FIRMWARE_INSTALL_DIR
}

function clean_rv_firmware()
{
	rm -rf $RV_FIRMWARE_INSTALL_DIR
	make -C "$RV_EDKII_SRC_DIR/tools/pack" clean
}

function build_rv_firmware_bin()
{
	local RELEASED_NOTE_PATH="$RV_EDKII_SRC_DIR/release-note"
	local EFI_FV=$(ls $RV_EDKII_SRC_DIR/Build/${PLAT}/RELEASE_GCC*/FV/${PLAT^^}.fd 2>/dev/null | head -n 1)

	if [ -z "$EFI_FV" ]; then
		echo "Error: EDK2 firmware not found in Build/${PLAT}/RELEASE_GCC*/FV/"
		echo "Run build_rv_edk2 first"
		return 1
	fi

	build_rv_firmware

	cp -v "$EFI_FV" $RV_FIRMWARE_INSTALL_DIR

	pushd $RV_FIRMWARE_INSTALL_DIR
	rm -f firmware*.bin

	./pack -a -p fip.bin -t 0x600000 -f fip.bin -o 0x30000 firmware.bin
	./pack -a -p ${PLAT}.fd -t 0x600000 -f ${PLAT^^}.fd -l 0x2000000 -o 0x2040000 firmware.bin
	./pack -a -p zsbl.bin -t 0x600000 -f zsbl.bin -l 0x40000000 firmware.bin
	./pack -a -p fw_dynamic.bin -t 0x600000 -f fw_dynamic.bin -l 0x0 firmware.bin
	./pack -a -p mango-milkv-pioneer.dtb -t 0x600000 -f mango-milkv-pioneer.dtb -l 0x20000000 firmware.bin
	./pack -a -p mango-milkv-pioneer.dtbo -t 0x600000 -f mango-milkv-pioneer.dtbo -l 0x20000000 firmware.bin
	./pack -a -p mango-sophgo-pisces.dtb -t 0x600000 -f mango-sophgo-pisces.dtb -l 0x20000000 firmware.bin
	./pack -a -p mango-sophgo-pisces.dtbo -t 0x600000 -f mango-sophgo-pisces.dtbo -l 0x20000000 firmware.bin
	./pack -a -p mango-sophgo-x4evb.dtb -t 0x600000 -f mango-sophgo-x4evb.dtb -l 0x20000000 firmware.bin
	./pack -a -p mango-sophgo-x4evb.dtbo -t 0x600000 -f mango-sophgo-x4evb.dtbo -l 0x20000000 firmware.bin
	./pack -a -p mango-sophgo-x8evb.dtb -t 0x600000 -f mango-sophgo-x8evb.dtb -l 0x20000000 firmware.bin
	./pack -a -p mango-sophgo-x8evb.dtbo -t 0x600000 -f mango-sophgo-x8evb.dtbo -l 0x20000000 firmware.bin
	./pack -a -p mango-sophgo-capricorn.dtb -t 0x600000 -f mango-sophgo-capricorn.dtb -l 0x20000000 firmware.bin
	./pack -a -p mango-yixin-s2110.dtb -t 0x600000 -f mango-yixin-s2110.dtb -l 0x20000000 firmware.bin

	if [ ! -e "$RELEASED_NOTE_PATH/sg2042_firmware_release_note.md" ] || [ ! -s "$RELEASED_NOTE_PATH/sg2042_firmware_release_note.md" ];then
		local version="1.0.0"
	else
		local FIRST_MATCH=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+_[0-9]{4}-[0-9]{2}-[0-9]{2}' "$RELEASED_NOTE_PATH/sg2042_firmware_release_note.md" | head -n 1)
		local version="$(echo "$FIRST_MATCH" | cut -d'_' -f1)"
	fi
	echo -n ${version} | ./pack -a -o 0x0 firmware.bin

	rm -f pack

	popd
}

function clean_rv_firmware_bin()
{
	rm -rf $RV_FIRMWARE_INSTALL_DIR
	make -C "$RV_EDKII_SRC_DIR/tools/pack" clean
}

function build_rv_firmware_image()
{
	if [ ! -f $RV_FIRMWARE_INSTALL_DIR/firmware.bin ]; then
		echo "Error: $RV_FIRMWARE_INSTALL_DIR/firmware.bin not found, run build_rv_firmware_bin first"
		return 1
	fi

	pushd $RV_FIRMWARE_INSTALL_DIR
	rm -f firmware.img

	echo create an image file...
	dd if=/dev/zero of=firmware.img bs=256MiB count=1

	echo create partitions...
	sudo parted firmware.img mktable msdos
	sudo parted firmware.img mkpart p fat32 0% 100%
	loops=$(sudo kpartx -av firmware.img | cut -d ' ' -f 3)
	fat32part=$(echo $loops | cut -d ' ' -f 1)
	sudo mkfs.vfat /dev/mapper/$fat32part -n EFI

	echo mount EFI partition...
	sudo mkdir -p efi/
	sudo mount /dev/mapper/$fat32part efi
	sudo mkdir -p efi/riscv64

	echo copy bootloader...
	sudo cp $RV_FIRMWARE_INSTALL_DIR/fip.bin efi/
	sudo cp $RV_FIRMWARE_INSTALL_DIR/zsbl.bin efi/
	sudo cp $RV_FIRMWARE_INSTALL_DIR/${PLAT^^}.fd efi/riscv64/${PLAT}.fd
	sudo cp $RV_FIRMWARE_INSTALL_DIR/fw_dynamic.bin efi/riscv64
	sudo cp $RV_FIRMWARE_INSTALL_DIR/*.dtb efi/riscv64
	sudo cp $RV_FIRMWARE_INSTALL_DIR/*.dtbo efi/riscv64

	echo cleanup...
	sudo umount /dev/mapper/$fat32part
	sudo kpartx -d $RV_FIRMWARE_INSTALL_DIR/firmware.img
	sudo rm -rf efi

	popd
}

function clean_rv_firmware_image()
{
	rm -f $RV_FIRMWARE_INSTALL_DIR/firmware.img
}

function build_rv_all()
{
	build_rv_edk2
	build_rv_firmware_bin
	build_rv_firmware_image
}

function clean_rv_all()
{
	clean_rv_firmware_bin
	clean_rv_firmware_image
	clean_rv_edk2
}

echo "Build environment for chip $CHIP and platform $PLAT setups done"
