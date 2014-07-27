/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    main.c
**  Author:  Uncle Wong 
**  Date:    07-25-2014 18:20:18 
**
**  Purpose:
**************************************************************************/


/* Include files. */
#include "type.h"
#include "string.h"
#include "protect.h"
#include "start.h"
#include "process.h"




void testa()
{
    int i = 0; 
    while (1) {
        disp_str("A");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }
}


void testb()
{
    int i = 0x1000; 
    while (1) {
        disp_str("B");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }
}

void testc()
{
    int i = 0x2000; 
    while (1) {
        disp_str("C");
        disp_int(i++);
        disp_str(".");
        delay(1);
    }
}


static void start_0_process()
{
    register_irq_handler(CLOCK_IRQ, clock_handler);
    enable_irq(CLOCK_IRQ);

    /* 启动0号进程, 第一次启动从ring0-ring1，k_reenter已经隐含+1(-1 + 1 = 0) */
    k_reenter = 0; 

    next_process_ptr = task_tbl;
    restore_scene();

    while (1) {}
}



void kernel_main ()
{   
    memset(task_tbl, 0, sizeof(process_t) * MAX_TASK_NR);

    start_process("proc_a", testa, TASK_TYPE_KERNEL, 0);
    //start_process("proc_b", testb, TASK_TYPE_USER, 0);
    //start_process("proc_c", testc, TASK_TYPE_USER, 0);
    
    start_0_process();
}





