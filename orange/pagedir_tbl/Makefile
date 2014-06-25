##################################################
# Makefile 
##################################################

SRC := pm_page.asm
BIN_DOS := $(SRC:%.asm=%.com)
BIN_BIOS := $(SRC:%.asm=%.bin)

.PHONY : dos direct ready $(BIN_DOS) $(BIN_BIOS)

dos: ready $(BIN_DOS)  
	@echo -e "copy freedos.img"
	@ln -sf ../shared/freedos.img  freedos.img
	@echo -e "copy bochsrc"
	@cp -f ../shared/bochsrc_dos  bochsrc
	@echo -e "mkfs.fat  pm.img"
	@mkfs.fat pm.img &> /dev/null
	@echo -e "copy $(BIN_DOS) to pm.img"
	@mkdir -p  /mnt/floppy
	@mount -o loop pm.img /mnt/floppy/
	@cp $(BIN_DOS) /mnt/floppy/
	@umount /mnt/floppy/

direct: ready $(BIN_BIOS)
	@echo -e "copy bochsrc"
	@cp -f ../shared/bochsrc_bios  bochsrc
	@echo -e "copy $(BIN_BIOS) to pm.img"
	@dd if=$(BIN_BIOS) of=pm.img bs=512 count=1 conv=notrunc

$(BIN_DOS): $(SRC)
	@sed '/org/c org 0100h' $(SRC) > $(SRC)_tmp
	@mv $(SRC)_tmp  $(SRC)
	@echo -e "nasm $(SRC)  to $(BIN_DOS)"
	@nasm $< -o $@

$(BIN_BIOS): $(SRC)
	@sed '/org/c org 07c00h' $(SRC) > $(SRC)_tmp
	@mv $(SRC)_tmp  $(SRC)
	@echo -e "nasm $(SRC)  to $(BIN_BIOS)"
	@nasm $< -o $@

ready:
	@ln -sf ../shared/pm.inc pm.inc 
	@echo -e "copy pm.img"
	@cp -f ../shared/pm.img  pm.img

clean:
	@rm -f $(BIN_BIOS)  $(BIN_DOS) bochsrc  freedos.img  pm.img pm.inc
