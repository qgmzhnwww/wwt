.PHONY: help build boot kernel qemu debug clean dir

.POSIX:
.DELETE_ON_ERROR:
MAKEFLAGS += --warn-undefined-variables
MAKEFLAGS += --no-builtin-rules

KERNEL_DIR := kernel
KERNEL_BUILD_DIR		:= build/kernel
KERNEL_BINARY	:= ${KERNEL_BUILD_DIR}/kernel.elf
FONT_FILE		:= ./zap-light16.psf

BOOT_DIR := boot
BOOT_BUILD_DIR    := build/boot
BOOT_BINARY := ${BOOT_BUILD_DIR}/bootx64.efi

BUILD_DIR         := build
DISK_IMG          := ${BUILD_DIR}/kernel.img
DISK_IMG_SIZE     := 2880

QEMU_FLAGS := \
	-bios OVMF.fd \
	-drive if=none,id=uas-disk1,file=${DISK_IMG},format=raw \
	-m 256M \
	-cpu qemu64 \
	-device usb-storage,drive=uas-disk1 \
	-serial stdio \
	-usb \
	-net none \
	-vga std

help:
	@echo "build system"
	@echo " help:            display a list of make targets [DEFAULT]"
	@echo " build:           build the binaries, keys, etc."
	@echo " qemu:            build the binaries, keys, etc and start QEMU"
	@echo " clean:           remove all build artifacts"

build: ${DISK_IMG}

boot: ${BOOT_BINARY}

kernel: ${KERNEL_BINARY}

qemu: ${DISK_IMG}
	qemu-system-x86_64 \
		${QEMU_FLAGS}

debug: ${DISK_IMG}
	qemu-system-x86_64 \
		${QEMU_FLAGS} \
		-m 512M \
		-S \
		-gdb tcp::1234

clean:
	@rm -rf build

${DISK_IMG}: dir ${BOOT_BINARY} ${KERNEL_BINARY}
	# Create UEFI boot disk image in DOS format.
	dd if=/dev/zero of=$@ bs=1k count=${DISK_IMG_SIZE}
	mformat -i $@ -f ${DISK_IMG_SIZE} ::
	mmd -i $@ ::/EFI
	mmd -i $@ ::/EFI/BOOT
	# Copy the boot to the boot partition.
	mcopy -i $@ ${BOOT_BINARY} ::/efi/boot/bootx64.efi
	mcopy -i $@ ${KERNEL_BINARY} ::/kernel.elf
	mcopy -i $@ ${FONT_FILE} ::/zap-light16.psf

${BOOT_BINARY}:
	make -C ${BOOT_DIR}

dir:
	mkdir -p ${BUILD_DIR}
	mkdir -p ${KERNEL_BUILD_DIR}
	mkdir -p ${BOOT_BUILD_DIR}

${KERNEL_BINARY}:
	make -C ${KERNEL_DIR}