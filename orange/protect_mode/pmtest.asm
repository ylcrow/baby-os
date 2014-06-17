%include  "pm.inc"

org 07c00h
	jmp _code16_start


[SECTION .gdt]
;gdt            base addr --------  addr limit -------- desc attr
desc_null:      Descriptor 0,       0,                  0               
desc_32code:    Descriptor 0,       SEG_CODE32_LEN - 1, DA_C + DA_32    
desc_display:   Descriptor 0B8000h, 0ffffh,             DA_DRW          


;gdt ptr
gdt_ptr     dw      $ - desc_null - 1       ;16bits  gdt_limit (gdt_len - 1)
            dd      0                       ;desc_null why?  32bits  gdt_baseaddr 


;selector
SELECTOR_32CODE     equ desc_32code - desc_null
SELECTOR_DISPLAY    equ desc_display - desc_null




[SECTION .16]
[BITS 16]
_code16_start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h

    ;fill desc_32code baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _code32_start
    mov word [desc_32code + 2], ax
    shr eax, 16
    mov byte [desc_32code + 4], al
    mov byte [desc_32code + 7], ah


    ;load gdt
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, desc_null 
    mov dword [gdt_ptr + 2], eax;
    lgdt [gdt_ptr]


    ;关闭中断
    cli

    ;open a20  
    ;8086芯片在访问超过1M的的地址时会回滚
    ;8086'OS为了向上兼容80286的芯片
    ;在不修改系统代码的情况下，关掉20地址线就可以实现地址回滚
	in	al, 92h
	or	al, 00000010b
	out	92h, al


	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

	jmp	dword SELECTOR_32CODE:0



[SECTION .32]
[BITS 32]
_code32_start:
    mov ax, SELECTOR_DISPLAY
    mov gs, ax


	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax
	jmp	$

SEG_CODE32_LEN  equ  $ - _code32_start

