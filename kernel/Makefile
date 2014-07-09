
KERNEL:=kernel.asm
KERNEL_BIN:=$(subst .asm,.bin,$(KERNEL))

$(KERNEL_BIN) : $(KERNEL)
	nasm -f elf -o $(subst .asm,.o,$(KERNEL)) $<
	ld -s -Ttext 0x30400 -o $@ $(subst .asm,.o,$(KERNEL))


clean :
	rm -f $(KERNEL_BIN) $(subst .asm,.o,$(KERNEL))
