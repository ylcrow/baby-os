##################################################
# Makefile
##################################################

BOOT:=boot.asm
LDR:=loader.asm
BOOT_BIN:=$(subst .asm,.bin,$(BOOT))
LDR_BIN:=$(subst .asm,.bin,$(LDR))

ASMKFLAGS += -I include/ -I lib/real_mode/ -I lib/protect_mode/

.PHONY : everything

everything : $(BOOT_BIN) $(LDR_BIN)

clean :
	rm -f $(BOOT_BIN) $(LDR_BIN)

$(BOOT_BIN) : $(BOOT)
	nasm $(ASMKFLAGS) $< -o $@ 

$(LDR_BIN) : $(LDR)
	nasm $(ASMKFLAGS)  $< -o $@

