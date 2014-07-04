##################################################
# Makefile
##################################################

BOOT:=boot.asm
LDR:=loader.asm
BOOT_BIN:=$(subst .asm,.bin,$(BOOT))
LDR_BIN:=$(subst .asm,.bin,$(LDR))

IMG:=a.img
FLOPPY:=/mnt/floppy/

.PHONY : everything

everything : $(BOOT_BIN) $(LDR_BIN)
	cp -f ../../shared/pm.img  $(IMG)
	cp -f ../../shared/bochsrc_bios_v2  bochsrc
	dd if=$(BOOT_BIN) of=$(IMG) bs=512 count=1 conv=notrunc
	mkdir -p $(FLOPPY) 
	mount -o loop $(IMG) $(FLOPPY)
	cp $(LDR_BIN) $(FLOPPY) -v
	umount $(FLOPPY)

clean :
	rm -f $(BOOT_BIN) $(LDR_BIN) $(IMG) bochsrc

$(BOOT_BIN) : $(BOOT)
	nasm $< -o $@

$(LDR_BIN) : $(LDR)
	nasm $< -o $@

