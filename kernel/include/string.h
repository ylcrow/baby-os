/**************************************************************************
**  Copyright (c) 2014 Uncle Wong.
**
**  Project: Baby Os
**  File:    sting.h
**  Author:  Uncle Wong 
**  Date:    07-13-2014 20:17:09 
**
**  Purpose:
**************************************************************************/
#ifndef __STING_H__ 
#define __STING_H__

extern  int disp_pos;
extern  void* memcpy(void* dst, void* src, int size);
extern  void memset(void* p_dst, char ch, int size);
extern  char* strcpy(char* p_dst, char* p_src);
extern  void disp_int(int input);
extern  void disp_color_str(char * info, int color);
extern  void disp_str(char * pszInfo);

#endif /* __STING_H__ */



