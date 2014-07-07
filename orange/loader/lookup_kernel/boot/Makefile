##################################################
# Makefile
##################################################

BOOT:=boot.asm
LDR:=loader.asm
BOOT_BIN:=$(subst .asm,.bin,$(BOOT))
LDR_BIN:=$(subst .asm,.bin,$(LDR))

IMG:=a.img
FLOPPY:=/mnt/floppy/
ASMKFLAGS := -I include/

.PHONY : everything

everything : $(BOOT_BIN) $(LDR_BIN)

clean :
	rm -f $(BOOT_BIN) $(LDR_BIN) $(IMG) bochsrc

$(BOOT_BIN) : $(BOOT)
	nasm $(ASMKFLAGS) $< -o $@ 

$(LDR_BIN) : $(LDR)
	nasm $(ASMKFLAGS)  $< -o $@

