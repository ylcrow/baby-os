/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    start.h
**  Author:  Uncle Wong 
**  Date:    07-13-2014 19:44:24 
**
**  Purpose:
**************************************************************************/
#ifndef __START_H__ 
#define __START_H__
#include "protect.h"


extern void	    divide_error(void);
extern void	    single_step_exception(void);
extern void	    nmi(void);
extern void	    breakpoint_exception(void);
extern void	    overflow(void);
extern void	    bounds_check(void);
extern void	    inval_opcode(void);
extern void	    copr_not_available(void);
extern void	    double_fault(void);
extern void	    copr_seg_overrun(void);
extern void	    inval_tss(void);
extern void	    segment_not_present(void);
extern void	    stack_exception(void);
extern void	    general_protection(void);
extern void	    page_fault(void);
extern void	    copr_error(void);
extern void     hwint00(void);
extern void     hwint01(void);
extern void     hwint02(void);
extern void     hwint03(void);
extern void     hwint04(void);
extern void     hwint05(void);
extern void     hwint06(void);
extern void     hwint07(void);
extern void     hwint08(void);
extern void     hwint09(void);
extern void     hwint10(void);
extern void     hwint11(void);
extern void     hwint12(void);
extern void     hwint13(void);
extern void     hwint14(void);
extern void     hwint15(void);



extern u8              gdt_ptr[6];
extern descriptor_t    gdt[GDT_SIZE];
extern u8              idt_ptr[6];
extern date_t          idt[IDT_SIZE];


extern void prepare_gdt(void);
extern void prepare_idt(void);
extern void spurious_irq(int irq);
extern void exception_handler(int vec_no,int err_code,int eip,int cs,int eflags);

#endif /* __START_H__ */



