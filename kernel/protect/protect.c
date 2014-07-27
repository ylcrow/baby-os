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
#include "start.h"


u8              gdt_ptr[6];
descriptor_t    gdt[GDT_SIZE];

u8              idt_ptr[6];
gate_t          idt[IDT_SIZE];


/* 用户级进程切换时共用同一个ldt,tss */
descriptor_t    ldt[LDT_SIZE];
tss_t           tss;

/* 硬中断处理函数表  */
irq_handler  irq_table[NR_IRQ];



static u32 seg2phys(u16 seg)
{
	descriptor_t  * p_dest = &gdt[seg >> 3];

	return (p_dest->base_high << 24) | (p_dest->base_mid << 16) | (p_dest->base_low);
}



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

static void init_descriptor(descriptor_t * p_desc, u32 base, u32 limit, u16 attribute)
{
	p_desc->limit_low		= limit & 0x0FFFF;		// 段界限 1		(2 字节)
	p_desc->base_low		= base & 0x0FFFF;		// 段基址 1		(2 字节)
	p_desc->base_mid		= (base >> 16) & 0x0FF;		// 段基址 2		(1 字节)
	p_desc->attr1			= attribute & 0xFF;		// 属性 1
	p_desc->limit_high_attr2	= ((limit >> 16) & 0x0F) |
						(attribute >> 8) & 0xF0;// 段界限 2 + 属性 2
	p_desc->base_high		= (base >> 24) & 0x0FF;		// 段基址 3		(1 字节)
}





static void init_8259A(void)
{
    int i = 0;
    
    for (i = 0; i < NR_IRQ; i++) {
        irq_table[i] = spurious_irq;
    }

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

    //关闭中断
	/* Master 8259, OCW1.  */
	out_byte(INT_M_CTLMASK,	0xFF);
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
	    disp_pos = 0;
        disp_str("spurious_irq: ");
        disp_int(irq);
        disp_str("\n");
}




void prepare_gdt(void)
{
	u16* p_gdt_limit = (u16*)(&gdt_ptr[0]);
	u32* p_gdt_base  = (u32*)(&gdt_ptr[2]);
    u32  seg_phys = seg2phys(SELECTOR_FLAT_RW);

    /* 初始化GDT, 前面几个desc与Loader的一样, copy */
	memcpy(&gdt, (void*)*p_gdt_base, *p_gdt_limit + 1);
    init_descriptor(&gdt[INDEX_TSS], vir2phys(seg_phys, &tss),  sizeof(tss) - 1,  DA_386TSS) ;
    init_descriptor(&gdt[INDEX_LDT], vir2phys(seg_phys, ldt),   LDT_SIZE * sizeof(descriptor_t) - 1,  DA_LDT) ;

    /* 初始化新的gdt指针 */
	*p_gdt_limit = GDT_SIZE * sizeof(descriptor_t) - 1;
	*p_gdt_base  = (u32)&gdt;

    /* 初始化LDT， 任务切换时使用同一个LDT */
    memcpy(&ldt[0], &gdt[INDEX_FLAT_C], sizeof(descriptor_t));
    ldt[0].attr1 = DA_C | (PRIVILEGE_TASK << 5);
    memcpy(&ldt[1], &gdt[INDEX_FLAT_RW], sizeof(descriptor_t));
    ldt[0].attr1 = DA_DRW | (PRIVILEGE_TASK << 5);

    /* 初始化TSS，任务切换时更新tss.esp0 */
    memset(&tss, 0, sizeof(tss));
    tss.ss0 = SELECTOR_FLAT_RW;
    tss.iobase = sizeof(tss);

    /* 提取赋值0，避免打印时出现gs访问溢出 */
	disp_pos = 0;
}


void prepare_idt(void)
{
	u16* p_idt_limit = (u16*)(&idt_ptr[0]);
	u32* p_idt_base  = (u32*)(&idt_ptr[2]);


	*p_idt_limit = IDT_SIZE * sizeof(gate_t) - 1;
	*p_idt_base  = (u32)&idt;

	init_vector();
}





void register_irq_handler(int irq, irq_handler  hlr)
{
    disable_irq(irq);
    irq_table[irq] = hlr;
}




