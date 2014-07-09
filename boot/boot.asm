%include "def_addr.inc"
org  BOOTIMG_OFFSET  
    
    jmp short boot_start
    nop

    %include "fat12_hdr.asm" 

    image_name      db	"LOADER  BIN"	        ; 需要加载的img名,fat12保存文件名时以两个space代替"."
    IMG_NAME_LEN    equ  $ - image_name         ; fat12: max 13 bytes(8文件名 + 3后缀名 + 2space)

    IMG_BASE        equ	LOADERIMG_VIRT_BASE_ADDR      	; image 被加载到的段地址
    IMG_OFFSET      equ	LOADERIMG_OFFSET                ; image 被加载到的偏移地址

    
boot_start:	
	mov ax, cs
	mov ds, ax
	mov es, ax
	mov ss, ax
	mov sp, BOOT_STACK_TOP

    call    search_image            ; search loader && load loader

	jmp IMG_BASE:IMG_OFFSET         ; jmp  loader

    %include "search_in_fat12.asm"

    times   510 - ($ - $$)  db  0
    dw  0xaa55				

