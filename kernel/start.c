/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    start.c
**  Author:  Uncle Wong 
**  Date:    07-13-2014 19:09:54 
**
**  Purpose:
**      准备idt和gdt为Kernel
**************************************************************************/


/* Include files. */
#include "type.h"
#include "string.h"
#include "protect.h"
#include "8259A.h"
#include "start.h"



u8              gdt_ptr[6];
descriptor_t    gdt[GDT_SIZE];
u8              idt_ptr[6];
gate_t          idt[IDT_SIZE];


static void init_idt_desc(u8 vector, u8 desc_type, int_handler handler, u8 privilege)
{
	gate_t*	p_gate	= &idt[vector];
	u32	base	= (u32)handler;
	p_gate->offset_low	= base & 0xFFFF;
	p_gate->selector	= SELECTOR_FLAT_C;
	p_gate->dcount		= 0;
	p_gate->attr		= desc_type | (privilege << 5);
	p_gate->offset_high	= (base >> 16) & 0xFFFF;
}



static void init_8259A(void)
{
	/* Master 8259, ICW1. */
	out_byte(INT_M_CTL,	0x11);

	/* Slave  8259, ICW1. */
	out_byte(INT_S_CTL,	0x11);

	/* Master 8259, ICW2. 设置 '主8259' 的中断入口地址为 0x20. */
	out_byte(INT_M_CTLMASK,	INT_VECTOR_IRQ0);

	/* Slave  8259, ICW2. 设置 '从8259' 的中断入口地址为 0x28 */
	out_byte(INT_S_CTLMASK,	INT_VECTOR_IRQ8);

	/* Master 8259, ICW3. IR2 对应 '从8259'. */
	out_byte(INT_M_CTLMASK,	0x4);

	/* Slave  8259, ICW3. 对应 '主8259' 的 IR2. */
	out_byte(INT_S_CTLMASK,	0x2);

	/* Master 8259, ICW4. */
	out_byte(INT_M_CTLMASK,	0x1);

	/* Slave  8259, ICW4. */
	out_byte(INT_S_CTLMASK,	0x1);

    //打开键盘中断
	/* Master 8259, OCW1.  */
	out_byte(INT_M_CTLMASK,	0xFD);

	/* Slave  8259, OCW1.  */
	out_byte(INT_S_CTLMASK,	0xFF);

}



static void init_vector(void)
{
    // 中断向量表(Abort/Trap/Fault)
	init_idt_desc(INT_VECTOR_DIVIDE,	DA_386IGate,
		      divide_error,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_DEBUG,		DA_386IGate,
		      single_step_exception,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_NMI,		DA_386IGate,
		      nmi,			PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_BREAKPOINT,	DA_386IGate,
		      breakpoint_exception,	PRIVILEGE_USER);

	init_idt_desc(INT_VECTOR_OVERFLOW,	DA_386IGate,
		      overflow,			PRIVILEGE_USER);

	init_idt_desc(INT_VECTOR_BOUNDS,	DA_386IGate,
		      bounds_check,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_INVAL_OP,	DA_386IGate,
		      inval_opcode,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_COPROC_NOT,	DA_386IGate,
		      copr_not_available,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_DOUBLE_FAULT,	DA_386IGate,
		      double_fault,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_COPROC_SEG,	DA_386IGate,
		      copr_seg_overrun,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_INVAL_TSS,	DA_386IGate,
		      inval_tss,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_SEG_NOT,	DA_386IGate,
		      segment_not_present,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_STACK_FAULT,	DA_386IGate,
		      stack_exception,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_PROTECTION,	DA_386IGate,
		      general_protection,	PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_PAGE_FAULT,	DA_386IGate,
		      page_fault,		PRIVILEGE_KRNL);

	init_idt_desc(INT_VECTOR_COPROC_ERR,	DA_386IGate,
		      copr_error,		PRIVILEGE_KRNL);


    // 注册硬中断
    init_8259A();


    // 中断向量表(硬中断)
    init_idt_desc(INT_VECTOR_IRQ0 + 0,      DA_386IGate,
                      hwint00,                  PRIVILEGE_KRNL);

    init_idt_desc(INT_VECTOR_IRQ0 + 1,      DA_386IGate,
                  hwint01,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ0 + 2,      DA_386IGate,
                  hwint02,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ0 + 3,      DA_386IGate,
                  hwint03,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ0 + 4,      DA_386IGate,
                  hwint04,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ0 + 5,      DA_386IGate,
                  hwint05,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ0 + 6,      DA_386IGate,
                  hwint06,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ0 + 7,      DA_386IGate,
                  hwint07,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 0,      DA_386IGate,
                  hwint08,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 1,      DA_386IGate,
                  hwint09,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 2,      DA_386IGate,
                  hwint10,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 3,      DA_386IGate,
                  hwint11,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 4,      DA_386IGate,
                  hwint12,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 5,      DA_386IGate,
                  hwint13,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 6,      DA_386IGate,
                  hwint14,                  PRIVILEGE_KRNL);
    
    init_idt_desc(INT_VECTOR_IRQ8 + 7,      DA_386IGate,
              hwint15,                  PRIVILEGE_KRNL);

}



void exception_handler(int vec_no,int err_code,int eip,int cs,int eflags)
{
	int i;
	int text_color = 0x74; /* 灰底红字 */

	char * err_msg[] = {"#DE Divide Error",
			    "#DB RESERVED",
			    "—  NMI Interrupt",
			    "#BP Breakpoint",
			    "#OF Overflow",
			    "#BR BOUND Range Exceeded",
			    "#UD Invalid Opcode (Undefined Opcode)",
			    "#NM Device Not Available (No Math Coprocessor)",
			    "#DF Double Fault",
			    "    Coprocessor Segment Overrun (reserved)",
			    "#TS Invalid TSS",
			    "#NP Segment Not Present",
			    "#SS Stack-Segment Fault",
			    "#GP General Protection",
			    "#PF Page Fault",
			    "—  (Intel reserved. Do not use.)",
			    "#MF x87 FPU Floating-Point Error (Math Fault)",
			    "#AC Alignment Check",
			    "#MC Machine Check",
			    "#XF SIMD Floating-Point Exception"
	};

	/* 通过打印空格的方式清空屏幕的前五行，并把 disp_pos 清零 */
	disp_pos = 0;
	for(i=0;i<80*5;i++){
		disp_str(" ");
	}
	disp_pos = 0;

	disp_color_str("Exception! --> ", text_color);
	disp_color_str(err_msg[vec_no], text_color);
	disp_color_str("\n\n", text_color);
	disp_color_str("EFLAGS:", text_color);
	disp_int(eflags);
	disp_color_str("CS:", text_color);
	disp_int(cs);
	disp_color_str("EIP:", text_color);
	disp_int(eip);

	if(err_code != 0xFFFFFFFF){
		disp_color_str("Error code:", text_color);
		disp_int(err_code);
	}
}

void spurious_irq(int irq)
{
        disp_str("spurious_irq: ");
        disp_int(irq);
        disp_str("\n");
}




void prepare_gdt(void)
{
	u16* p_gdt_limit = (u16*)(&gdt_ptr[0]);
	u32* p_gdt_base  = (u32*)(&gdt_ptr[2]);


    /* GDT需要与Loader的GDT一样, copy */
	memcpy(&gdt, (void*)*p_gdt_base, *p_gdt_limit + 1);


	*p_gdt_limit = GDT_SIZE * sizeof(descriptor_t) - 1;
	*p_gdt_base  = (u32)&gdt;
}


void prepare_idt(void)
{
	u16* p_idt_limit = (u16*)(&idt_ptr[0]);
	u32* p_idt_base  = (u32*)(&idt_ptr[2]);


	init_vector();


	*p_idt_limit = IDT_SIZE * sizeof(gate_t) - 1;
	*p_idt_base  = (u32)&idt;
}


