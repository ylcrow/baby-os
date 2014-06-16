##################################################
# Makefile of pmtestx.asm (x=[1,2,3...])
##################################################

SRC:=pmtest.asm
BIN_COM:=$(subst .asm,.com,$(SRC))
BIN_BIN:=$(subst .asm,.bin,$(SRC))

.PHONY : dos direct $(BIN_COM) $(BIN_BIN)

dos: $(BIN_COM)
	rm -f bochsrc
	cp bochsrc_dos  bochsrc
	mkfs.fat pm.img
	mount -o loop pm.img /mnt/floppy/
	cp $(BIN_COM) /mnt/floppy/ -v
	umount /mnt/floppy/

direct: $(BIN_BIN)
	rm -f bochsrc
	cp bochsrc_bin  bochsrc
	dd if=$(BIN_BIN) of=pm.img bs=512 count=1 conv=notrunc

$(BIN_COM) : $(SRC)
	sed '/org/c org 0100h' $(SRC) > $(SRC)_tmp
	mv $(SRC)_tmp  $(SRC)
	nasm $< -o $@


$(BIN_BIN) : $(SRC)
	sed '/org/c org 07c00h' $(SRC) > $(SRC)_tmp
	mv $(SRC)_tmp  $(SRC)
	nasm $< -o $@

clean:
	rm -f $(BIN_BIN)  $(BIN_COM) bochsrc
