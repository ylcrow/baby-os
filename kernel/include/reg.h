/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    reg.h
**  Author:  Uncle Wong 
**  Date:    07-13-2014 20:57:26 
**
**  Purpose:
**************************************************************************/
#ifndef __REG_H__ 
#define __REG_H__
#include "type.h"

extern u8 in_byte(u16 port);
extern void out_byte(u16 port, u8 value);
#endif /* __REG_H__ */



