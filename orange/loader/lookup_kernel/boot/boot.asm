    org  07c00h
    
    jmp short boot_start
    nop
    
    %include "fat12_hdr.inc" 
    %include "def_addr.inc"


IMG_BASE        equ	LOADERIMG_VIRT_BASE_ADDR      	; image 被加载到的段地址
IMG_OFFSET      equ	LOADERIMG_OFFSET                ; image 被加载到的偏移地址
image_name      db	"LOADER  BIN"	    ; 需要加载的img名
IMG_NAME_LEN    equ  $ - image_name     ; fat12: max 13 bytes(8文件名 + 3后缀名 + 2space)

TOP_STACK       equ	07c00h


boot_start:	
	mov	    ax, cs
	mov	    ds, ax
	mov	    es, ax
	mov	    ss, ax
	mov	    sp, TOP_STACK

    call    search_image                ; loopup loader && read loader

	jmp	    IMG_BASE:IMG_OFFSET         ; into loader


%include "search_image.inc"

times 	510-($-$$)	db	0
dw 	0xaa55				


