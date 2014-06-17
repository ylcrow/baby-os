%include  "pm.inc"
org 07c00h
	jmp _code16_start



[SECTION .gdt]
;gdt
desc_null:      Descriptor 0, 0, 0 
desc_32code:    Descriptor 0, SEG_CODE32_LEN - 1, DA_C + DA_32
desc_display:   Descriptor 0B8000h, 0ffffh,  DA_DRW


;gdt ptr
gdt_ptr     dw      $ - desc_null - 1       ;word 16bits
            dd      0                       ;double word 32bits


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

    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _code32_start

    mov word [desc_32code + 2], ax
    shr eax, 16
    mov byte [desc_32code + 4], al
    mov byte [desc_32code + 7], ah


    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, desc_null 
    mov dword [gdt_ptr + 2], eax;
    lgdt [gdt_ptr]


    cli


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

