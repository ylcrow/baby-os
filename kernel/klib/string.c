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
#include "stirng.h"

int disp_pos = 0;

char * itoa(char * str, int num)
{
	char *	p = str;
	char	ch;
	int	i;
	int	flag = 0;

	*p++ = '0';
	*p++ = 'x';

	if(num == 0){
		*p++ = '0';
	}
	else{	
		for(i=28;i>=0;i-=4){
			ch = (num >> i) & 0xF;
			if(flag || (ch > 0)){
				flag = 1;
				ch += '0';
				if(ch > '9'){
					ch += 7;
				}
				*p++ = ch;
			}
		}
	}

	*p = 0;

	return str;
}

void disp_int(int input)
{
	char output[16];
	itoa(output, input);
	disp_str(output);
}
