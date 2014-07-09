
export ASM		= nasm
export AS      = as
export LD      = ld
export CC      = gcc
export CPP     = $(CC) -E
export AR      = ar
export NM      = nm
export STRIP   = strip
export OBJCOPY = objcopy
export OBJDUMP = objdump
export RANLIB  = ranlib
export MKDIR	= mkdir -p
export MAKE		= make


ROOTDIR  := $(shell pwd)
KERNEL_DIR := $(ROOTDIR)/kernel
LOADER_DIR := $(ROOTDIR)/loader
FLOPPY	:= /mnt/floppy/
IMAGE 	:= $(ROOTDIR)/image/a.img
BOOT 	:= $(LOADER_DIR)/boot.bin
LOADER := $(LOADER_DIR)/loader.bin
KERNEL := $(KERNEL_DIR)/kernel.bin

.PHONY: all clean loader kernel buildimage loader_clean kernel_clean

all: loader kernel buildimage

clean: loader_clean kernel_clean


loader:
	$(MAKE) -C $(LOADER_DIR)

loader_clean:
	-$(MAKE) -C $(LOADER_DIR) clean


kernel:	
	$(MAKE) -C $(KERNEL_DIR)

kernel_clean:
	-$(MAKE) -C $(KERNEL_DIR) clean

buildimage:
	dd if=$(BOOT) of=$(IMAGE) bs=512 count=1 conv=notrunc
	$(MKDIR) $(FLOPPY)
	-umount $(FLOPPY)
	mount -o loop $(IMAGE) $(FLOPPY)
	cp $(LOADER) $(FLOPPY) -v
	cp $(KERNEL) $(FLOPPY) -v
	umount $(FLOPPY)







