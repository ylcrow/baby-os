/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    protect.h
**  Author:  Uncle Wong 
**  Date:    07-13-2014 19:23:40 
**
**  Purpose:
**************************************************************************/
#ifndef __PROTECT_H__ 
#define __PROTECT_H__

#include "type.h"


typedef	void	(*int_handler)	();


typedef struct {
	u32	backlink;
	u32	esp0;		/* stack pointer to use during interrupt */
	u32	ss0;		/*   "   segment  "  "    "        "     */
	u32	esp1;
	u32	ss1;
	u32	esp2;
	u32	ss2;
	u32	cr3;
	u32	eip;
	u32	flags;
	u32	eax;
	u32	ecx;
	u32	edx;
	u32	ebx;
	u32	esp;
	u32	ebp;
	u32	esi;
	u32	edi;
	u32	es;
	u32	cs;
	u32	ss;
	u32	ds;
	u32	fs;
	u32	gs;
	u32	ldt;
	u16	trap;
	u16	iobase;	/* I/O位图基址大于或等于TSS段界限，就表示没有I/O许可位图 */
	/*u8	iomap[2];*/
} tss_t;








/* 存储段描述符/系统段描述符 */
typedef struct descriptor_s		/* 共 8 个字节 */
{
	u16	limit_low;		/* Limit */
	u16	base_low;		/* Base */
	u8	base_mid;		/* Base */
	u8	attr1;			/* P(1) DPL(2) DT(1) TYPE(4) */
	u8	limit_high_attr2;	/* G(1) D(1) 0(1) AVL(1) LimitHigh(4) */
	u8	base_high;		/* Base */
} descriptor_t; 


/* 门描述符 */
typedef struct gate_s
{
	u16	offset_low;	/* Offset Low */
	u16	selector;	/* Selector */
	u8	dcount;		/* 该字段只在调用门描述符中有效。如果在利用
				     * 调用门调用子程序时引起特权级的转换和堆栈
				     * 的改变，需要将外层堆栈中的参数复制到内层
				     * 堆栈。该双字计数字段就是用于说明这种情况
				     * 发生时，要复制的双字参数的数量。
                     */
	u8	attr;		/* P(1) DPL(2) DT(1) TYPE(4) */
	u16	offset_high;	/* Offset High */
} gate_t;






/* GDT/IDT/LDT最多支持数量 */
#define GDT_SIZE    128
#define IDT_SIZE    256
#define LDT_SIZE	2


/* 描述符权限 */
#define	PRIVILEGE_KRNL	0
#define	PRIVILEGE_TASK	1
#define	PRIVILEGE_USER	3

/* 选择子权限 */
#define SA_RPL_MASK  0xFFFC
#define SA_RPL0      0
#define SA_RPL1      1
#define SA_RPL2      2
#define SA_RPL3      3

/* 选择子指向哪一个描述符 */
#define SA_TI_MASK  0xFFFB
#define SA_TIG      0
#define SA_TIL      4 



/* 描述符索引,与Loader的匹配 */
#define	INDEX_DUMMY		    0	
#define	INDEX_FLAT_C		1	
#define	INDEX_FLAT_RW		2	
#define	INDEX_VIDEO		    3	
#define	INDEX_TSS		    4	
#define	INDEX_LDT		    5	


/* 选择子,与Loader的匹配 */
#define	SELECTOR_DUMMY		    (INDEX_DUMMY << 3)		 /* 0x00 */
#define	SELECTOR_FLAT_C		    (INDEX_FLAT_C << 3)      /* 0x08 */		
#define	SELECTOR_FLAT_RW	    (INDEX_FLAT_RW << 3)     /* 0x10 */		
#define	SELECTOR_VIDEO		    ((INDEX_VIDEO << 3) + 3) /* 0x18 + RPL(3) */
#define	SELECTOR_TSS		    (INDEX_TSS << 3)         /* 0x20 */	
#define	SELECTOR_LDT	        (INDEX_LDT << 3)         /* 0x28 */	


/* 描述符类型值说明 */
#define	DA_32			0x4000	/* 32 位段				*/
#define	DA_LIMIT_4K		0x8000	/* 段界限粒度为 4K 字节			*/
#define	DA_DPL0			0x00	/* DPL = 0				*/
#define	DA_DPL1			0x20	/* DPL = 1				*/
#define	DA_DPL2			0x40	/* DPL = 2				*/
#define	DA_DPL3			0x60	/* DPL = 3				*/
/* 存储段描述符类型值说明 */
#define	DA_DR			0x90	/* 存在的只读数据段类型值		*/
#define	DA_DRW			0x92	/* 存在的可读写数据段属性值		*/
#define	DA_DRWA			0x93	/* 存在的已访问可读写数据段类型值	*/
#define	DA_C			0x98	/* 存在的只执行代码段属性值		*/
#define	DA_CR			0x9A	/* 存在的可执行可读代码段属性值		*/
#define	DA_CCO			0x9C	/* 存在的只执行一致代码段属性值		*/
#define	DA_CCOR			0x9E	/* 存在的可执行可读一致代码段属性值	*/
/* 系统段描述符类型值说明 */
#define	DA_LDT			0x82	/* 局部描述符表段类型值			*/
#define	DA_TaskGate		0x85	/* 任务门类型值				*/
#define	DA_386TSS		0x89	/* 可用 386 任务状态段类型值		*/
#define	DA_386CGate		0x8C	/* 386 调用门类型值			*/
#define	DA_386IGate		0x8E	/* 386 中断门类型值			*/
#define	DA_386TGate		0x8F	/* 386 陷阱门类型值			*/

/* 中断向量(Fault/Abort/Trap) */
#define	INT_VECTOR_DIVIDE		0x0
#define	INT_VECTOR_DEBUG		0x1
#define	INT_VECTOR_NMI			0x2
#define	INT_VECTOR_BREAKPOINT		0x3
#define	INT_VECTOR_OVERFLOW		0x4
#define	INT_VECTOR_BOUNDS		0x5
#define	INT_VECTOR_INVAL_OP		0x6
#define	INT_VECTOR_COPROC_NOT		0x7
#define	INT_VECTOR_DOUBLE_FAULT		0x8
#define	INT_VECTOR_COPROC_SEG		0x9
#define	INT_VECTOR_INVAL_TSS		0xA
#define	INT_VECTOR_SEG_NOT		    0xB
#define	INT_VECTOR_STACK_FAULT		0xC
#define	INT_VECTOR_PROTECTION		0xD
#define	INT_VECTOR_PAGE_FAULT		0xE
#define	INT_VECTOR_RESERVE		    0xF
#define	INT_VECTOR_COPROC_ERR		0x10

/* 中断向量(硬中断) */
#define	INT_VECTOR_IRQ0			0x20
#define	INT_VECTOR_IRQ8			0x28

#define vir2phys(seg_base, vir)	(u32)(((u32)seg_base) + (u32)(vir))




/* 8259A 相关  */
typedef	void	(*irq_handler)	(int irq);

/* 配置硬中断与向量的对应关系的寄存器 8259A interrupt controller ports. */
#define INT_M_CTL     0x20 /* I/O port for interrupt controller       <Master> */
#define INT_M_CTLMASK 0x21 /* setting bits in this port disables ints <Master> */
#define INT_S_CTL     0xA0 /* I/O port for second interrupt controller<Slave>  */
#define INT_S_CTLMASK 0xA1 /* setting bits in this port disables ints <Slave>  */


/* Hardware interrupts */
#define	NR_IRQ		16	/* Number of IRQs */
#define	CLOCK_IRQ	0
#define	KEYBOARD_IRQ	1
#define	CASCADE_IRQ	2	/* cascade enable for 2nd AT controller */
#define	ETHER_IRQ	3	/* default ethernet interrupt vector */
#define	SECONDARY_IRQ	3	/* RS232 interrupt vector for port 2 */
#define	RS232_IRQ	4	/* RS232 interrupt vector for port 1 */
#define	XT_WINI_IRQ	5	/* xt winchester */
#define	FLOPPY_IRQ	6	/* floppy disk */
#define	PRINTER_IRQ	7
#define	AT_WINI_IRQ	14	/* at winchester */








void exception_handler(int vec_no,int err_code,int eip,int cs,int eflags);
void spurious_irq(int irq);
void prepare_gdt(void);
void prepare_idt(void);
void register_irq_handler(int irq, irq_handler  hlr);
void disable_irq(int irq);
void enable_irq(int irq);


extern u8              gdt_ptr[6];
extern descriptor_t    gdt[GDT_SIZE];

extern u8              idt_ptr[6];
extern gate_t          idt[IDT_SIZE];


/* 用户级进程切换时共用同一个ldt,tss */
extern descriptor_t    ldt[LDT_SIZE];
extern tss_t           tss;

/* 硬中断处理函数表  */
extern irq_handler  irq_table[NR_IRQ];



#endif /* __PROTECT_H__ */



