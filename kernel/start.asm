%include "start.inc"
%include "const.inc"


[section .text]
_start:
    mov esp, STACK_TOP

    call prepare_idt
    lidt [idt_ptr]

    sgdt [gdt_ptr]
    call prepare_gdt   
    lgdt [gdt_ptr]

    jmp SELECTOR_FLAT_C:_restart

_restart:
    xor eax, eax
    mov ax, SELECTOR_TSS
    ltr ax

    jmp kernel_main

save_scene:
    pushad          ; `.
    push    ds      ;  |
    push    es      ;  | 保存原寄存器值
    push    fs      ;  |
    push    gs      ; /
    mov     dx, ss
    mov     ds, dx
    mov     es, dx
    
    mov     eax, esp                   

    inc     dword [k_reenter]    
    cmp     dword [k_reenter], 0 
    jne     .r_enter                   
;-------------------------------
    mov     ebx, [next_process_ptr]
    cmp     dword [ebx + PROCESS_TASK_TYPE_OFFSET], TASK_TYPE_USER
    je      .u_task1
    mov     [ebx + STACKFRAME_ESP_OFFSET], eax
.u_task1:
;-------------------------------
    mov     esp, STACK_TOP
    push    restore_scene              
    jmp     [eax + STACKFRAME_RETADR_OFFSET]
.r_enter:                              
    push    restore_reenter_scene      
    jmp     [eax + STACKFRAME_RETADR_OFFSET]


restore_scene:              
	mov	esp, [next_process_ptr]
	lldt	[esp + PROCESS_LDT_OFFSET] 
;--------------------------------
    cmp     dword [esp + PROCESS_TASK_TYPE_OFFSET], TASK_TYPE_USER
    je      .u_task2
    mov     esp, [esp + STACKFRAME_ESP_OFFSET]
    jmp     restore_reenter_scene
.u_task2:
;--------------------------------
	lea	eax, [esp + STACKFRAME_SIZE]
	mov	dword [tss + TSS_ESP0_OFFSET], eax
restore_reenter_scene:
	dec	dword [k_reenter]
	pop	gs
	pop	fs
	pop	es
	pop	ds
	popad
	add	esp, 4
	iretd


; ---------------------------------
%macro  hwint_master    1
        ; 保存现场
        call save_scene

        ; 屏蔽当前中断
	    in	al, INT_M_CTLMASK
	    or	al, (1 << %1)		
	    out	INT_M_CTLMASK, al	

        ; 发送EOI
	    mov	al, EOI			
	    out	INT_M_CTL, al	

        ; 打开中断
	    sti	

        ; 调用中断处理方法
        push    %1
	    call	[irq_table + 4 * %1]
        pop     ecx         ;add     esp, 4

        ; 关闭中断
        cli

        ; 恢复接受当前中断
    	in	al, INT_M_CTLMASK	
    	and	al, ~(1 << %1)		
    	out	INT_M_CTLMASK, al	

        ret
%endmacro
; ---------------------------------



; ---------------------------------
%macro  hwint_slave     1
        push    %1
        call    spurious_irq
        add     esp, 4
        hlt
%endmacro
; ---------------------------------



; 中断和异常 -- 硬件中断
ALIGN   16
hwint00:                ; Interrupt routine for irq 0 (the clock).
        hwint_master    0

ALIGN   16
hwint01:                ; Interrupt routine for irq 1 (keyboard)
        hwint_master    1

ALIGN   16
hwint02:                ; Interrupt routine for irq 2 (cascade!)
        hwint_master    2

ALIGN   16
hwint03:                ; Interrupt routine for irq 3 (second serial)
        hwint_master    3

ALIGN   16
hwint04:                ; Interrupt routine for irq 4 (first serial)
        hwint_master    4

ALIGN   16
hwint05:                ; Interrupt routine for irq 5 (XT winchester)
        hwint_master    5

ALIGN   16
hwint06:                ; Interrupt routine for irq 6 (floppy)
        hwint_master    6

ALIGN   16
hwint07:                ; Interrupt routine for irq 7 (printer)
        hwint_master    7

ALIGN   16
hwint08:                ; Interrupt routine for irq 8 (realtime clock).
        hwint_slave     8


ALIGN   16
hwint09:                ; Interrupt routine for irq 9 (irq 2 redirected)
        hwint_slave     9

ALIGN   16
hwint10:                ; Interrupt routine for irq 10
        hwint_slave     10

ALIGN   16
hwint11:                ; Interrupt routine for irq 11
        hwint_slave     11

ALIGN   16
hwint12:                ; Interrupt routine for irq 12
        hwint_slave     12

ALIGN   16
hwint13:                ; Interrupt routine for irq 13 (FPU exception)
        hwint_slave     13

ALIGN   16
hwint14:                ; Interrupt routine for irq 14 (AT winchester)
        hwint_slave     14

ALIGN   16
hwint15:                ; Interrupt routine for irq 15
        hwint_slave     15



; 中断和异常 -- 异常
divide_error:
	push	0xFFFFFFFF	; no err code
	push	0		; vector_no	= 0
	jmp	exception
single_step_exception:
	push	0xFFFFFFFF	; no err code
	push	1		; vector_no	= 1
	jmp	exception
nmi:
	push	0xFFFFFFFF	; no err code
	push	2		; vector_no	= 2
	jmp	exception
breakpoint_exception:
	push	0xFFFFFFFF	; no err code
	push	3		; vector_no	= 3
	jmp	exception
overflow:
	push	0xFFFFFFFF	; no err code
	push	4		; vector_no	= 4
	jmp	exception
bounds_check:
	push	0xFFFFFFFF	; no err code
	push	5		; vector_no	= 5
	jmp	exception
inval_opcode:
	push	0xFFFFFFFF	; no err code
	push	6		; vector_no	= 6
	jmp	exception
copr_not_available:
	push	0xFFFFFFFF	; no err code
	push	7		; vector_no	= 7
	jmp	exception
double_fault:
	push	8		; vector_no	= 8
	jmp	exception
copr_seg_overrun:
	push	0xFFFFFFFF	; no err code
	push	9		; vector_no	= 9
	jmp	exception
inval_tss:
	push	10		; vector_no	= A
	jmp	exception
segment_not_present:
	push	11		; vector_no	= B
	jmp	exception
stack_exception:
	push	12		; vector_no	= C
	jmp	exception
general_protection:
	push	13		; vector_no	= D
	jmp	exception
page_fault:
	push	14		; vector_no	= E
	jmp	exception
copr_error:
	push	0xFFFFFFFF	; no err code
	push	16		; vector_no	= 10h
	jmp	exception

exception:
	call	exception_handler
	add	esp, 4*2	; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
	hlt


    

[section .bss]
STACK   resb 2 * 1024
STACK_TOP:





