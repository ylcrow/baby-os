/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    process.h
**  Author:  Uncle Wong 
**  Date:    07-25-2014 17:38:40 
**
**  Purpose:
**************************************************************************/
#ifndef __PROCESS_H__ 
#define __PROCESS_H__

#include "type.h"
#include "protect.h"



#define  ONCE_TASK_STACK   0x8000
#define MAX_TASK_NR   3	

#define TASK_TYPE_INVALID  0
#define TASK_TYPE_KERNEL   1 
#define TASK_TYPE_USER     2

#define   SET_LDT_SELECTOR(index)     (index << 3) & SA_RPL_MASK & SA_TI_MASK | SA_TIL | SA_RPL1
#define   SET_GDT_SELECTOR(index)     (index << 3) & SA_RPL_MASK & SA_TI_MASK | SA_TIG | SA_RPL0



typedef	void	(*task_f)	();


typedef struct stackframe_s {	/* proc_ptr points here				↑ Low			*/
	u32	gs;		/* ┓						│			*/
	u32	fs;		/* ┃						│			*/
	u32	es;		/* ┃						│			*/
	u32	ds;		/* ┃						│			*/
	u32	edi;		/* ┃						│			*/
	u32	esi;		/* ┣ pushed by save()				│			*/
	u32	ebp;		/* ┃						│			*/
	u32	kernel_esp;	/* <- 'popad' will ignore it			│			*/
	u32	ebx;		/* ┃						↑栈从高地址往低地址增长*/		
	u32	edx;		/* ┃						│			*/
	u32	ecx;		/* ┃						│			*/
	u32	eax;		/* ┛						│			*/
	u32	retaddr;	/* return address for assembly code save()	│			*/
	u32	eip;		/*  ┓						│			*/
	u32	cs;		/*  ┃						│			*/
	u32	eflags;		/*  ┣ these are pushed by CPU during interrupt	│			*/
	u32	esp;		/*  ┃						│			*/
	u32	ss;		/*  ┛						┷High			*/
} stackframe_t;


typedef struct process_s {
	stackframe_t regs;          /* process registers saved in stack frame */
    u16 ldt_selector;
    u16 pad;
    u32 task_type;               /* KERNEL_TASK, USER_TASK */
	task_f	enter;
	u32 pid;                   /* process id passed in from MM */
    u32 priority;
	char p_name[16];           /* name of the process */
} process_t;



extern process_t  task_tbl[MAX_TASK_NR];
extern process_t  *next_process_ptr;
extern char    task_stack[ONCE_TASK_STACK * MAX_TASK_NR];
extern int     k_reenter;


extern void clock_handler(int irq);
extern int start_process(char *name, task_f func, u32 task_type, u32 priority);


#endif /* __PROCESS_H__ */



