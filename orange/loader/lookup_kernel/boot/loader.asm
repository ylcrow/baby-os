%include "pm.inc"    
%include "def_addr.inc"

    org	 LOADERIMG_OFFSET
    jmp  loader_start


;gdt
desc_gdt:           Descriptor 0,               0,                      0                       ; NULL指针
desc_flat_c:        Descriptor 0,               0fffffh,                DA_CR|DA_32|DA_LIMIT_4K ; 0~4G
desc_flat_rw:       Descriptor 0,               0fffffh,                DA_DRW|DA_LIMIT_4K      ; 0~4G
desc_display:       Descriptor 0B8000h,         0ffffh,                 DA_DRW + DA_DPL3        ;  


;gdt ptr
GDT_LEN     equ     $ - desc_gdt
gdt_ptr     dw      GDT_LEN - 1                                     ;16bits  gdt_limit (gdt_len - 1)
            dd      LOADERIMG_PHYS_BASE_ADDR + desc_gdt             ;32bits  gdt_baseaddr 


;selector
SELECTOR_FLAT_C     equ desc_flat_c - desc_gdt
SELECTOR_FLAT_RW     equ desc_flat_rw - desc_gdt


loader_start:






KillMotor:
	push	dx
	mov	dx, 03F2h
	mov	al, 0
	out	dx, al
	pop	dx
	ret

