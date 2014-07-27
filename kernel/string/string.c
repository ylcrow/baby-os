/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    string.c
**  Author:  Uncle Wong 
**  Date:    07-13-2014 20:50:29 
**
**  Purpose:
**************************************************************************/
#include "string.h"

/* 初始化为0的全局变量的初始化应该是由库统一清0的，
 * 我们没有库，于是这里的赋0操作完全没用, 
 * 我们需要在第一次使用它前初始化为0。 */
int disp_pos = 0;

void disp_int(int input)
{
	char output[16];
	itoa(output, input);
	disp_str(output);
}
