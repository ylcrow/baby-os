%include "pm.inc"    
%include "def_addr.inc"

org	 LOADERIMG_OFFSET

    jmp loader_start

    desc_gdt:           Descriptor 0,               0,                      0                       ; NULL指针
    desc_flat_c:        Descriptor 0,               0fffffh,                DA_CR|DA_32|DA_LIMIT_4K ; 0~4G
    desc_flat_rw:       Descriptor 0,               0fffffh,                DA_DRW|DA_LIMIT_4K      ; 0~4G
    desc_display:       Descriptor 0B8000h,         0ffffh,                 DA_DRW + DA_DPL3        ;  

    gdt_ptr     dw      $ - desc_gdt - 1                                ;16bits  gdt_limit (gdt_len - 1)
                dd      LOADERIMG_PHYS_BASE_ADDR + desc_gdt             ;32bits  gdt_baseaddr 


;selector
SELECTOR_FLAT_C     equ desc_flat_c - desc_gdt
SELECTOR_FLAT_RW    equ desc_flat_rw - desc_gdt
SELECTOR_DISPLAY    equ desc_display - desc_gdt + SA_RPL3 


loader_start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, LOADER_STACK_TOP

    ;get meminfo
    ;search kernel.bin
    
    ; 加载 GDTR
    ;	lgdt	[GdtPtr]
    
    ; 关中断
    	cli
    
    ; 打开地址线A20
    	in	al, 92h
    	or	al, 00000010b
    	out	92h, al
    
    ; 准备切换到保护模式
    	mov	eax, cr0
    	or	eax, 1
    	mov	cr0, eax
    
    ; 真正进入保护模式
    	;jmp	dword SelectorFlatC:(BaseOfLoaderPhyAddr+LABEL_PM_START)


[SECTION .code]
ALIGN	32
[BITS	32]
LABEL_PM_START:
    ;init ds ss es gs fs esp
    ;display mem info
    ;open mmu
    ;init kernel
    ;jmp kernel
    
[SECTION .data]

