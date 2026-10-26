#!/bin/bash
# Standalone SG2044 firmware build environment for sophgo-edk2.
# zsbl/fw_dynamic/fsbl/dtbo come pre-built from edk2-non-osi, so no
# opensbi/eboot source checkout is needed. Function names and layout
# follow bootloader-riscv/scripts/envsetup.sh.

RV_EDKII_SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RV_OUTPUT_DIR="$RV_EDKII_SRC_DIR/Build/${PLAT:-SD3-10}"
RV_FIRMWARE_INSTALL_DIR="$RV_OUTPUT_DIR/firmware"
RV_FIRMWARE="$RV_EDKII_SRC_DIR/edk2-non-osi/Silicon/Sophgo/SG2044/Boot"

CHIP=${CHIP:-sg2044}
PLAT=${PLAT:-SD3-10}
SG2044_PLAT_LIST='SD3-10 SD3-10-LB SD3-12 SRA3-40 SRA3-40-LB SRA3-40-8 SRM31'

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

	build -a RISCV64 -t $EDK2_TOOLCHAIN -b $TARGET -p Platform/Sophgo/${CHIP^^}Pkg/${PLAT}/${PLAT^^}.dsc

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
	if [ ! -f $RV_FIRMWARE_INSTALL_DIR/fsbl.bin ]; then
		cp -v $RV_FIRMWARE/fsbl.bin $RV_FIRMWARE_INSTALL_DIR/fsbl.bin
	fi

	cp -v $RV_FIRMWARE/zsbl.bin $RV_FIRMWARE_INSTALL_DIR
	cp -v $RV_FIRMWARE/fw_dynamic.bin $RV_FIRMWARE_INSTALL_DIR
	cp -v $RV_FIRMWARE/sg2044-*.dtbo $RV_FIRMWARE_INSTALL_DIR

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
	local PRIVKEY_PATH="$RV_EDKII_SRC_DIR/keys/sophgo-root-private-key.pem"
	local PUBKEY_PATH="$RV_EDKII_SRC_DIR/keys/sophgo-root-public-key.pem"
	local PUBKEY_DER_PATH="public_key.der"
	local EFI_FV="$RV_EDKII_SRC_DIR/Build/${PLAT}/RELEASE_GCC/FV/${PLAT^^}.fd"

	if [ ! -f "$EFI_FV" ]; then
		echo "Error: EDK2 firmware not found at $EFI_FV"
		echo "Run build_rv_edk2 first"
		return 1
	fi

	build_rv_firmware

	cp -v "$EFI_FV" $RV_FIRMWARE_INSTALL_DIR

	pushd $RV_FIRMWARE_INSTALL_DIR
	rm -f firmware*.bin

	./pack -a -p SG2044.fd -t 0x80000 -f ${PLAT^^}.fd -l 0x80200000 -o 0x600000 firmware.bin
	./pack -a -p fsbl.bin -t 0x80000 -f fsbl.bin -l 0x7010080000 firmware.bin
	./pack -a -p zsbl.bin -t 0x80000 -f zsbl.bin -l 0x40000000 firmware.bin
	./pack -a -p fw_dynamic.bin -t 0x80000 -f fw_dynamic.bin -l 0x80000000 firmware.bin
	./pack -a -p sg2044-evb.dtbo -t 0x80000 -f sg2044-evb.dtbo -l 0x88000000 firmware.bin
	./pack -a -p sg2044-sd3-12.dtbo -t 0x80000 -f sg2044-sd3-12.dtbo -l 0x88000000 firmware.bin
	./pack -a -p sg2044-sra3.dtbo -t 0x80000 -f sg2044-sra3.dtbo -l 0x88000000 firmware.bin
	export_key $PRIVKEY_PATH $PUBKEY_PATH
	sign $PRIVKEY_PATH ${PLAT^^}.fd
	sign $PRIVKEY_PATH fsbl.bin
	sign $PRIVKEY_PATH zsbl.bin
	sign $PRIVKEY_PATH fw_dynamic.bin
	sign $PRIVKEY_PATH sg2044-evb.dtbo
	sign $PRIVKEY_PATH sg2044-sd3-12.dtbo
	sign $PRIVKEY_PATH sg2044-sra3.dtbo
	./pack -a -p SG2044.fd.sig -t 0x80000 -f ${PLAT^^}.fd.sig firmware.bin
	./pack -a -p fsbl.bin.sig -t 0x80000 -f fsbl.bin.sig firmware.bin
	./pack -a -p zsbl.bin.sig -t 0x80000 -f zsbl.bin.sig firmware.bin
	./pack -a -p fw_dynamic.bin.sig -t 0x80000 -f fw_dynamic.bin.sig firmware.bin
	./pack -a -p sg2044-evb.dtbo.sig -t 0x80000 -f sg2044-evb.dtbo.sig firmware.bin
	./pack -a -p sg2044-sd3-12.dtbo.sig -t 0x80000 -f sg2044-sd3-12.dtbo.sig firmware.bin
	./pack -a -p sg2044-sra3.dtbo.sig -t 0x80000 -f sg2044-sra3.dtbo.sig firmware.bin
	./pack -a -p public_key.der -t 0x80000 -f $PUBKEY_DER_PATH firmware.bin

	if [ ! -e "$RELEASED_NOTE_PATH/sg2044_firmware_release_note.md" ] || [ ! -s "$RELEASED_NOTE_PATH/sg2044_firmware_release_note.md" ];then
		local version="1.0.0"
	else
		local FIRST_MATCH=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+_[0-9]{4}-[0-9]{2}-[0-9]{2}' "$RELEASED_NOTE_PATH/sg2044_firmware_release_note.md" | head -n 1)
		local version="$(echo "$FIRST_MATCH" | cut -d'_' -f1)"
	fi
	echo -n ${version} | ./pack -a -o 0x0 firmware.bin

	rm -f pack *.sig $PUBKEY_DER_PATH

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
	sudo cp $RV_FIRMWARE_INSTALL_DIR/fsbl.bin efi/riscv64
	sudo cp $RV_FIRMWARE_INSTALL_DIR/zsbl.bin efi/riscv64
	sudo cp $RV_FIRMWARE_INSTALL_DIR/${PLAT^^}.fd efi/riscv64/SG2044.fd
	sudo cp $RV_FIRMWARE_INSTALL_DIR/fw_dynamic.bin efi/riscv64
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
