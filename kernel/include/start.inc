; extern func
extern prepare_gdt
extern prepare_idt
extern	exception_handler
extern	spurious_irq
extern  kernel_main

; extern var
extern	gdt_ptr
extern	idt_ptr
extern  irq_table
extern  k_reenter
extern  tss
extern  next_process_ptr


; global var/func
global _start
global restore_scene
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


