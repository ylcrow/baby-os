%include  "pm.inc"

org 0100h
	jmp _begin


[SECTION .gdt]
;gdt            base addr --------  addr limit -------- desc attr
desc_null:          Descriptor 0,               0,                      0            ;null指针，用于填充ldtr  
desc_normal:        Descriptor 0,               0ffffh,                 DA_DRW          
desc_16code:        Descriptor 0,               0ffffh,                 DA_C            
desc_32code:        Descriptor 0,               SEG_CODE32_LEN - 1,     DA_C + DA_32    
desc_display:       Descriptor 0B8000h,         0ffffh,                 DA_DRW + DA_DPL3         
desc_stack:         Descriptor 0,               STACK_LEN - 1,          DA_DRWA + DA_32
desc_stack3:        Descriptor 0,               STACK3_LEN - 1,         DA_DRWA + DA_32 + DA_DPL3
desc_ldt:           Descriptor 0,               LDT_LEN - 1,            DA_LDT 
desc_codeb:         Descriptor 0,               CODEB_LEN - 1,          DA_C + DA_32
desc_codec:         Descriptor 0,               CODEC_LEN - 1,          DA_C + DA_32 + DA_DPL3
desc_tss:           Descriptor 0,               TSS_LEN - 1,            DA_386TSS
desc_gate:          Gate       SELECTOR_CODEB,  0,             0,       DA_386CGate + DA_DPL3



;gdt ptr, gdt len
GDT_LEN     equ     $ - desc_null
gdt_ptr     dw      GDT_LEN - 1             ;16bits  gdt_limit (gdt_len - 1)
            dd      0                       ;desc_null why?  32bits  gdt_baseaddr 

;selector
SELECTOR_NORMAL     equ desc_normal - desc_null
SELECTOR_16CODE     equ desc_16code - desc_null
SELECTOR_32CODE     equ desc_32code - desc_null
SELECTOR_DISPLAY    equ desc_display - desc_null
SELECTOR_STACK      equ desc_stack - desc_null
SELECTOR_STACK3     equ desc_stack3 - desc_null + SA_RPL3
;SELECTOR_STACK3     equ desc_stack3 - desc_null 
SELECTOR_LDT        equ desc_ldt - desc_null
SELECTOR_CODEB      equ desc_codeb - desc_null
SELECTOR_CODEC      equ desc_codec - desc_null + SA_RPL3; retf时检查cs的rpl判断是否需要切换特权级
SELECTOR_TSS        equ  desc_tss - desc_null
SELECTOR_CALLGATE   equ  desc_gate - desc_null + SA_RPL3
;END of section .gdt

[SECTION .tss]
ALIGN 32
[BITS 32]
_tss_start:
		DD	0			    ; Back
		DD	STACK_TOP		; esp0 		
        DD	SELECTOR_STACK  ; ss0 
		DD	0			    ; esp1 
		DD	0			    ; ss1 
		DD	0			    ; esp2 
		DD	0			    ; ss2 
		DD	0			    ; CR3
		DD	0			    ; EIP
		DD	0			    ; EFLAGS
		DD	0			    ; EAX
		DD	0			    ; ECX
		DD	0			    ; EDX
		DD	0			    ; EBX
		DD	0			    ; ESP
		DD	0			    ; EBP
		DD	0			    ; ESI
		DD	0			    ; EDI
		DD	0			    ; ES
		DD	0			    ; CS
		DD	0			    ; SS
		DD	0			    ; DS
		DD	0			    ; FS
		DD	0			    ; GS
		DD	0			    ; LDT
		DW	0			    ; 调试陷阱标志
		DW	$ - _tss_start + 2	; I/O位图基址
		DB	0ffh			; I/O位图结束标志
TSS_LEN equ $ - _tss_start






[SECTION .ldt]
;ldt
ldt_desc_codea:   Descriptor 0,  CODEA_LEN -1,  DA_C + DA_32;

;ldt len
LDT_LEN             equ   $ - ldt_desc_codea

;ldt selector
LDT_SELECTOR_CODEA  equ   ldt_desc_codea - ldt_desc_codea + SA_TIL
;END of section .ldt

[SECTION .stack]
ALIGN 32
[BITS 32]
_stack_start:
    times  512 db 0
STACK_LEN   equ   $ - _stack_start
STACK_TOP   equ   STACK_LEN - 1


[SECTION .stack3]
ALIGN 32
[BITS 32]
_stack3_start:
    times  512 db 0
STACK3_LEN   equ   $ - _stack3_start
STACK3_TOP   equ   STACK3_LEN - 1




;
real_mode_sp_value  dw 0

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


    ;fill desc_tss baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _tss_start
    mov word [desc_tss + 2], ax
    shr eax, 16
    mov byte [desc_tss + 4], al
    mov byte [desc_tss + 7], ah

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


    ;fill desc_stack3  baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _stack3_start
    mov word [desc_stack3 + 2], ax
    shr eax, 16
    mov byte [desc_stack3 + 4], al
    mov byte [desc_stack3 + 7], ah




    ;fill desc_codeb baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _codeb_start
    mov word [desc_codeb+ 2], ax
    shr eax, 16
    mov byte [desc_codeb + 4], al
    mov byte [desc_codeb + 7], ah




    ;fill desc_codec baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _codec_start
    mov word [desc_codec+ 2], ax
    shr eax, 16
    mov byte [desc_codec + 4], al
    mov byte [desc_codec + 7], ah






    ;fill ldt_desc_codea baseaddr 
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, _codea_start
    mov word [ldt_desc_codea + 2], ax
    shr eax, 16
    mov byte [ldt_desc_codea + 4], al
    mov byte [ldt_desc_codea + 7], ah


    ;fill desc_ldt baseaddr 
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, ldt_desc_codea
    mov word [desc_ldt + 2], ax
    shr eax, 16
    mov byte [desc_ldt + 4], al
    mov byte [desc_ldt + 7], ah



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
    mov al, 11111110b
    mov cr0, eax

WAIT_FILL:
    jmp 0:REAL_MODE_ENTRY ;cs是动态的，需要运行在实模式时填充
SEG_CODE16_LEN  equ  $ - _code16_start


[SECTION .32code]
[BITS 32]
_code32_start:
    mov ax, SELECTOR_DISPLAY
    mov gs, ax

    ;没用ss sp时, 后面用了call, 没出问题好奇怪
	mov	ax, SELECTOR_STACK
	mov	ss, ax				
    mov	esp,STACK_TOP 

	mov	edi, (80 * 11 + 79) * 2	; 屏幕第 11 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'P'
	mov	[gs:edi], ax

    mov ax, SELECTOR_TSS
    ltr ax

    push SELECTOR_STACK3
    push STACK3_TOP
    push SELECTOR_CODEC ;作为cs保持到栈，cs代表的是调用者的dpl, 请求调用门时的rpl添加到哪里？？
    push 0
    retf

    ;call SELECTOR_CALLGATE:0    ;跳入调用门 ;请求调用门时的rpl添加this吗?

	; Load LDT
	mov	ax, SELECTOR_LDT 
	lldt	ax
    jmp  LDT_SELECTOR_CODEA:0    ;跳入局部任务

	;jmp	SELECTOR_16CODE:0   ;使用jmp来恢复cs的高速缓冲区
SEG_CODE32_LEN  equ  $ - _code32_start



;CODE A为LDT做测试
[SECTION .codea]
ALIGN	32
[BITS	32]
_codea_start:
    mov ax, SELECTOR_DISPLAY
    mov gs, ax

	mov	edi, (80 * 12 + 79) * 2	; 屏幕第 12 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'a'
	mov	[gs:edi], ax
	jmp	SELECTOR_16CODE:0   ;使用jmp来恢复cs的高速缓冲区

CODEA_LEN  equ	$ - _codea_start


;CODE B为调用门做测试
[SECTION .codeb]
ALIGN	32
[BITS 32]
_codeb_start:
    mov ax, SELECTOR_DISPLAY
    mov gs, ax

	mov	edi, (80 * 13 + 79) * 2	; 屏幕第 13 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'b'
	mov	[gs:edi], ax

	jmp	SELECTOR_16CODE:0   ;直接跳回实模式

    ;retf
CODEB_LEN   equ $ - _codeb_start
   


;CODE C为ring变换做测试
[SECTION .codec]
ALIGN	32
[BITS 32]
_codec_start:
    mov ax, SELECTOR_DISPLAY
    mov gs, ax

	mov	edi, (80 * 14 + 79) * 2	; 屏幕第 14 行, 第 79 列。
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'c'
    mov	[gs:edi], ax

    call SELECTOR_CALLGATE:0

    jmp $
CODEC_LEN   equ $ - _codec_start
   
