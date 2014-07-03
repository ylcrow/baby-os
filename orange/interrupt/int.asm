%include  "pm.inc"

org 0100h
	jmp _begin

[SECTION .gdt]
;gdt            base addr --------  addr limit -------- desc attr
desc_null:          Descriptor 0,               0,                      0            ;null指针，用于填充ldtr  
desc_normal:        Descriptor 0,               0ffffh,                 DA_DRW ;64k         
desc_16code:        Descriptor 0,               0ffffh,                 DA_C            
desc_32code:        Descriptor 0,               SEG_CODE32_LEN - 1,     DA_CR + DA_32   ; 一定要可读，等下会cpy代码到flat rw区 
desc_display:       Descriptor 0B8000h,         0ffffh,                 DA_DRW + DA_DPL3         
desc_data:          Descriptor 0,               DATA_LEN - 1,           DA_DRW
desc_stack:         Descriptor 0,               STACK_LEN - 1,          DA_DRWA + DA_32



;gdt ptr, gdt len
GDT_LEN     equ     $ - desc_null
gdt_ptr     dw      GDT_LEN - 1             ;16bits  gdt_limit (gdt_len - 1)
            dd      0                       ;desc_null why?  32bits  gdt_baseaddr 

;selector
SELECTOR_NORMAL     equ desc_normal - desc_null
SELECTOR_16CODE     equ desc_16code - desc_null
SELECTOR_32CODE     equ desc_32code - desc_null
SELECTOR_DISPLAY    equ desc_display - desc_null
SELECTOR_DATA       equ desc_data - desc_null
SELECTOR_STACK      equ desc_stack - desc_null
;END of section .gdt


[SECTION .idt]
ALIGN 32
[BITS 32]
_start_idt:
%rep 32
		    Gate	SELECTOR_32CODE, SpuriousHandler,      0, DA_386IGate
%endrep
.020h:		Gate	SELECTOR_32CODE,  ClockInterrupt,      0, DA_386IGate
%rep 95
		    Gate	SELECTOR_32CODE, SpuriousHandler,      0, DA_386IGate
%endrep
.080h:		Gate	SELECTOR_32CODE,     SystemCall,      0, DA_386IGate

LDT_LEN     equ	    $ - _start_idt
idt_ptr	    dw	    LDT_LEN  - 1	; idt界限
		    dd	    0		        ; idt基地址





[SECTION .stack]
ALIGN 32
[BITS 32]
_stack_start:
    times  512 db 0
STACK_LEN   equ   $ - _stack_start
STACK_TOP   equ   STACK_LEN - 1



[SECTION .data]
ALIGN	32
[BITS	32]
_data_start:
; 实模式下使用这些符号
real_mode_sp_value  dw  0
_szPMMessage:		db	"In Protect Mode now. ^-^", 0Ah, 0Ah, 0
_s_out_pm_msg:	    db "Out Protect Mode now. ^-^", 0Ah, 0Ah, 0
_dwDispPos:			dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
_szReturn			db	0Ah, 0
_SavedIDTR:			dd	0	; 用于保存 IDTR
				    dd	0
_SavedIMREG:		db	0	; 中断屏蔽寄存器值


; 保护模式下使用这些符号
SavedIDTR		equ	_SavedIDTR	- $$
SavedIMREG		equ	_SavedIMREG	- $$
szPMMessage		equ	_szPMMessage	- $$
S_OUT_PM_MSG    equ	_s_out_pm_msg	- $$
dwDispPos		equ	_dwDispPos	- $$
szReturn		equ	_szReturn	- $$

DATA_LEN  equ  $ - _data_start


[SECTION .begincode]
[BITS 16]
_begin:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h   ;向下增长

    mov [WAIT_FILL + 3], ax
    mov [real_mode_sp_value], sp



    ;fill desc_32code baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _code32_start
    mov word [desc_32code + 2], ax
    shr eax, 16
    mov byte [desc_32code + 4], al
    mov byte [desc_32code + 7], ah

    ;fill desc_16code baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _code16_start
    mov word [desc_16code + 2], ax
    shr eax, 16
    mov byte [desc_16code + 4], al
    mov byte [desc_16code + 7], ah

    ;fill desc_stack  baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _stack_start
    mov word [desc_stack + 2], ax
    shr eax, 16
    mov byte [desc_stack + 4], al
    mov byte [desc_stack + 7], ah


    ;fill desc_data baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _data_start
    mov word [desc_data + 2], ax
    shr eax, 16
    mov byte [desc_data + 4], al
    mov byte [desc_data + 7], ah


    ;prepare gdt baseaddr
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, desc_null 
    mov dword [gdt_ptr + 2], eax;


	;prepare idt baseaddr
    xor	eax, eax
	mov	ax, ds
	shl	eax, 4
	add	eax, _start_idt;	
    mov	dword [idt_ptr + 2], eax


	; 保存 IDTR
	sidt	[_SavedIDTR]


	; 保存中断屏蔽寄存器(IMREG)值
	in	al, 21h
	mov	[_SavedIMREG], al


    ;load gdt
    lgdt [gdt_ptr]


    ;关闭中断
    cli

    ;load idt
    lidt [idt_ptr]


    ;open a20  
    ;8086芯片在访问超过1M的的地址时会回滚
    ;8086'OS为了向上兼容80286的芯片
    ;在不修改系统代码的情况下，关掉20地址线就可以实现地址回滚
	in	al, 92h
	or	al, 00000010b
	out	92h, al

    ;set protect mode
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

    ;jmp protect mode
	jmp	dword SELECTOR_32CODE:0     ;dword 表明将偏移0编译后占用32bit 0x12345678 -> 0x5678

    ;go back real mode
REAL_MODE_ENTRY:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, [real_mode_sp_value]


    ; 恢复 IDTR 的原值
	lidt	[_SavedIDTR]	


    ;open a20
    in al, 92h
    and al, 11111110b
    out 92h, al

    ;open interrupt
    sti

    ;return dos
    mov ax, 4c00h
    int 21h     


; 下面的代码全运行在保护模式
; 实模式下段寄存器的高速缓冲区(属性缓存)必须正确，同时实模式无法修改缓冲区
; 所以在返回实模式前，使用jmp selector_16code来恢复cs的缓冲区属性(code, 16, exe)，
; 使用mov selector_normal来恢复其他缓冲区属性(data,rw)
[SECTION .16code]
ALIGN 32
[BITS 16]
_code16_start:
    mov ax, SELECTOR_NORMAL
    mov ds, ax          ;使用mov恢复ds的高速缓冲区,下面类似
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov eax, cr0
    and eax, 7ffffffeh; PG=0;PE=0
    mov cr0, eax

WAIT_FILL:
    jmp 0:REAL_MODE_ENTRY ;cs是动态的，需要运行在实模式时填充
SEG_CODE16_LEN  equ  $ - _code16_start


[SECTION .32code]
[BITS 32]
_code32_start:
    mov ax, SELECTOR_DISPLAY
    mov gs, ax

    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    
	mov	ax, SELECTOR_STACK 
	mov	ss, ax				
    mov	esp,STACK_TOP 


    ;printf into pm mode
	push	szPMMessage
    call    DispStr
    add esp, 4


	call	Init8259A

    ;test int n
	int	080h

    ;test clock_intrrupt
	;sti
    ;jmp $

    ;会有警告，但是强制执行也没问题样？
	call	SetRealmode8259A

    ;printf out pm mode
	push	S_OUT_PM_MSG
    call    DispStr
    add esp, 4

	jmp	SELECTOR_16CODE:0   ;使用jmp来恢复cs的高速缓冲区





Init8259A:
	mov	al, 011h
	out	020h, al	; 主8259, ICW1.
	call	io_delay

	out	0A0h, al	; 从8259, ICW1.
	call	io_delay

	mov	al, 020h	; IRQ0 对应中断向量 0x20
	out	021h, al	; 主8259, ICW2.
	call	io_delay

	mov	al, 028h	; IRQ8 对应中断向量 0x28
	out	0A1h, al	; 从8259, ICW2.
	call	io_delay

	mov	al, 004h	; IR2 对应从8259
	out	021h, al	; 主8259, ICW3.
	call	io_delay

	mov	al, 002h	; 对应主8259的 IR2
	out	0A1h, al	; 从8259, ICW3.
	call	io_delay

	mov	al, 001h
	out	021h, al	; 主8259, ICW4.
	call	io_delay

	out	0A1h, al	; 从8259, ICW4.
	call	io_delay

	;mov	al, 11111111b	; 屏蔽主8259所有中断
	mov	al, 11111110b	; 仅仅开启定时器中断
	out	021h, al	; 主8259, OCW1.
	call	io_delay

	mov	al, 11111111b	; 屏蔽从8259所有中断
	out	0A1h, al	; 从8259, OCW1.
	call	io_delay

	ret



SetRealmode8259A:
	mov	ax, SELECTOR_DATA 
	mov	fs, ax

	mov	al, 017h
	out	020h, al	; 主8259, ICW1.
	call	io_delay

	mov	al, 008h	; IRQ0 对应中断向量 0x8
	out	021h, al	; 主8259, ICW2.
	call	io_delay

	mov	al, 001h
	out	021h, al	; 主8259, ICW4.
	call	io_delay

	mov	al, [fs:SavedIMREG]	; ┓恢复中断屏蔽寄存器(IMREG)的原值
	out	021h, al		; ┛
	call	io_delay

	ret



_clock_interrupt:
ClockInterrupt equ	_clock_interrupt - $$
	inc	byte [gs:((80 * 0 + 70) * 2)]	; 屏幕第 0 行, 第 70 列。
	mov	al, 20h
	out	20h, al				; 发送 EOI
	iretd



_system_call:
SystemCall equ	_system_call - $$
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, 'I'
	mov	[gs:((80 * 0 + 70) * 2)], ax	; 屏幕第 0 行, 第 70 列。
	iretd



_SpuriousHandler:
SpuriousHandler	equ	_SpuriousHandler - $$
	mov	ah, 0Ch				; 0000: 黑底    1100: 红字
	mov	al, '!'
	mov	[gs:((80 * 0 + 75) * 2)], ax	; 屏幕第 0 行, 第 75 列。
	jmp	$
	iretd



%include "lib.inc"

SEG_CODE32_LEN  equ  $ - _code32_start

  
