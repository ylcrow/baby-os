/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    process.c
**  Author:  Uncle Wong 
**  Date:    07-25-2014 18:16:15 
**
**  Purpose:
**************************************************************************/


/* Include files. */
#include "string.h"
#include "process.h"
#include "klib.h"


process_t  task_tbl[MAX_TASK_NR];
process_t  *next_process_ptr;
char    task_stack[ONCE_TASK_STACK * MAX_TASK_NR];
int     k_reenter;





void clock_handler(int irq)
{
    disp_str("#");
    if (k_reenter != 0) {
        disp_str("!");
        return;
    }

    next_process_ptr++;
    if (next_process_ptr >= task_tbl + MAX_TASK_NR) {
        next_process_ptr = task_tbl;
    }
}




int start_process(char *name, task_f func, u32 task_type, u32 priority)
{
    process_t *pro;
    int i;


    if (task_type != TASK_TYPE_KERNEL 
            && task_type != TASK_TYPE_USER) {
        return KRNL_RET_ERROR;
    }

    for (i = 0; i < MAX_TASK_NR; i++) {
        pro = &task_tbl[i];
        if (pro->task_type == TASK_TYPE_INVALID) {
            break;
        }
    }
    if (i == MAX_TASK_NR) {
        return KRNL_RET_ERROR;
    }


    strcpy(pro->p_name, name);
    pro->pid = i;
    pro->enter = func;
    pro->priority = priority;
    pro->regs.gs = SELECTOR_VIDEO;
    pro->regs.eip = (u32)func;
    pro->regs.esp = (u32)task_stack + sizeof(task_stack) - ONCE_TASK_STACK * i;
    pro->regs.eflags = 0x1202; /* IF = 1; IOPL = 1 */


    if (task_type == TASK_TYPE_KERNEL) {
        pro->task_type = TASK_TYPE_KERNEL;
        pro->ldt_selector = SELECTOR_DUMMY;
        pro->regs.cs = SET_GDT_SELECTOR(INDEX_FLAT_C);
        pro->regs.ds = SET_GDT_SELECTOR(INDEX_FLAT_RW);
        pro->regs.es = SET_GDT_SELECTOR(INDEX_FLAT_RW);
        pro->regs.fs = SET_GDT_SELECTOR(INDEX_FLAT_RW);
        pro->regs.ss = SET_GDT_SELECTOR(INDEX_FLAT_RW);
        /* krnl task 的现场保存在它自己的任务栈, 而非进程结构体 */
        pro->regs.esp = pro->regs.esp - (sizeof(stackframe_t) - 8); /* skip ss esp */
        memcpy((void *)pro->regs.esp, &pro->regs, sizeof(stackframe_t) - 8);
    } 
    else if (task_type == TASK_TYPE_USER) {
        pro->task_type = TASK_TYPE_USER;
        pro->ldt_selector = SELECTOR_LDT;
        pro->regs.cs = SET_LDT_SELECTOR(0);
        pro->regs.ds = SET_LDT_SELECTOR(1);
        pro->regs.es = SET_LDT_SELECTOR(1);
        pro->regs.fs = SET_LDT_SELECTOR(1);
        pro->regs.ss = SET_LDT_SELECTOR(1);
    } 

    return KRNL_RET_OK; 
}



