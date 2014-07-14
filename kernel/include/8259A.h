/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    8259A.h
**  Author:  Uncle Wong 
**  Date:    07-14-2014 21:08:08 
**
**  Purpose:
**************************************************************************/
#ifndef __8259A_H__ 
#define __8259A_H__


/* 配置硬中断与向量的对应关系的寄存器 8259A interrupt controller ports. */
#define INT_M_CTL     0x20 /* I/O port for interrupt controller       <Master> */
#define INT_M_CTLMASK 0x21 /* setting bits in this port disables ints <Master> */
#define INT_S_CTL     0xA0 /* I/O port for second interrupt controller<Slave>  */
#define INT_S_CTLMASK 0xA1 /* setting bits in this port disables ints <Slave>  */



#endif /* __8259A_H__ */




