

; 选择子,与Loader的匹配 
SELECTOR_DUMMY		equ    0		
SELECTOR_FLAT_C		equ    0x08		
SELECTOR_FLAT_RW	equ    0x10		
SELECTOR_VIDEO		equ    (0x18+3)	    ; RPL = 3


; extern func
extern prepare_gdt
extern prepare_idt
extern	exception_handler
extern	spurious_irq

; extern var
extern	gdt_ptr
extern	idt_ptr

; global var
global _start
global	divide_error
global	single_step_exception
global	nmi
global	breakpoint_exception
global	overflow
global	bounds_check
global	inval_opcode
global	copr_not_available
global	double_fault
global	copr_seg_overrun
global	inval_tss
global	segment_not_present
global	stack_exception
global	general_protection
global	page_fault
global	copr_error
global  hwint00
global  hwint01
global  hwint02
global  hwint03
global  hwint04
global  hwint05
global  hwint06
global  hwint07
global  hwint08
global  hwint09
global  hwint10
global  hwint11
global  hwint12
global  hwint13
global  hwint14
global  hwint15



; ---------------------------------
%macro  hwint_master    1
        push    %1
        call    spurious_irq
        add     esp, 4
        hlt
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



; ---------------------------------
%macro  exceptoin_init     1
        push    %1
    	call	exception_handler
    	add	esp, 4*2	; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
    	hlt
%endmacro
; ---------------------------------
