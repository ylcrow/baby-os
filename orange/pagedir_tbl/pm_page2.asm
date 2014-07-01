%include  "pm.inc"

org 0100h
	jmp _begin

PageDirBase		equ	200000h	; 页目录开始地址: 2M  共4k
PageTblBase		equ	201000h	; 页表开始地址: 2M+4K 共4M
PageDirBase2		equ	210000h	; 页目录开始地址:	2M + 64K
PageTblBase2		equ	211000h	; 页表开始地址:		2M + 64K + 4K

FUNC_ADDR       equ	00401000h
FUNC_FOO		equ	00401000h
FUNC_BAR        equ	00501000h

[SECTION .gdt]
;gdt            base addr --------  addr limit -------- desc attr
desc_null:          Descriptor 0,               0,                      0            ;null指针，用于填充ldtr  
desc_normal:        Descriptor 0,               0ffffh,                 DA_DRW ;64k         
desc_16code:        Descriptor 0,               0ffffh,                 DA_C            
desc_32code:        Descriptor 0,               SEG_CODE32_LEN - 1,     DA_C + DA_32    
desc_display:       Descriptor 0B8000h,         0ffffh,                 DA_DRW + DA_DPL3         
desc_data:          Descriptor 0,               DATA_LEN - 1,           DA_DRW
desc_stack:         Descriptor 0,               STACK_LEN - 1,          DA_DRWA + DA_32
desc_flat_c:        Descriptor 0,               0fffffh,                DA_CR|DA_32|DA_LIMIT_4K; 0~4G
desc_flat_rw:       Descriptor 0,               0fffffh,                DA_DRW|DA_LIMIT_4K     ; 0~4G



;gdt ptr, gdt len
GDT_LEN     equ     $ - desc_null
gdt_ptr     dw      GDT_LEN - 1             ;16bits  gdt_limit (gdt_len - 1)
            dd      0                       ;desc_null why?  32bits  gdt_baseaddr 

;selector
SELECTOR_NORMAL     equ desc_normal - desc_null
SELECTOR_16CODE     equ desc_16code - desc_null
SELECTOR_32CODE     equ desc_32code - desc_null
SELECTOR_DISPLAY    equ desc_display - desc_null
SELECTOR_DATA       equ desc_data - desc_null
SELECTOR_STACK      equ desc_stack - desc_null
SELECTOR_FLAT_C     equ desc_flat_c - desc_null
SELECTOR_FLAT_RW     equ desc_flat_rw - desc_null
;END of section .gdt


[SECTION .stack]
ALIGN 32
[BITS 32]
_stack_start:
    times  512 db 0
STACK_LEN   equ   $ - _stack_start
STACK_TOP   equ   STACK_LEN - 1



[SECTION .data]
ALIGN	32
[BITS	32]
_data_start:
; 实模式下使用这些符号
real_mode_sp_value  dw  0
_szPMMessage:		db	"In Protect Mode now. ^-^", 0Ah, 0Ah, 0	; 进入保护模式后显示此字符串
_szMemChkTitle:		db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0	; 进入保护模式后显示此字符串
_szRAMSize			db	"RAM size:", 0
_dwMCRNumber:		dd	0	; Memory Check Result
_dwDispPos:			dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
_dwMemSize:			dd	0
_MemChkBuf:	times	256	db	0
_szReturn			db	0Ah, 0
_sPGE   			db	0AH, "PageDirEntry/PageTable Count: ", 0
_pagetbl_cnt   		dd	0

_ARDStruct:			; Address Range Descriptor Structure
	_dwBaseAddrLow:		dd	0
	_dwBaseAddrHigh:	dd	0
	_dwLengthLow:		dd	0
	_dwLengthHigh:		dd	0
	_dwType:		dd	0

; 保护模式下使用这些符号
PAGETBL_CNT     equ _pagetbl_cnt - $$
sPGE            equ _sPGE - $$
szPMMessage		equ	_szPMMessage	- $$
szMemChkTitle		equ	_szMemChkTitle	- $$
szRAMSize		equ	_szRAMSize	- $$
dwDispPos		equ	_dwDispPos	- $$
dwMemSize		equ	_dwMemSize	- $$
dwMCRNumber		equ	_dwMCRNumber	- $$
ARDStruct		equ	_ARDStruct	- $$
	dwBaseAddrLow	equ	_dwBaseAddrLow	- $$
	dwBaseAddrHigh	equ	_dwBaseAddrHigh	- $$
	dwLengthLow	equ	_dwLengthLow	- $$
	dwLengthHigh	equ	_dwLengthHigh	- $$
	dwType		equ	_dwType		- $$
MemChkBuf		equ	_MemChkBuf	- $$
szReturn		equ	_szReturn	- $$
DATA_LEN  equ  $ - _data_start


[SECTION .begincode]
[BITS 16]
_begin:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0100h   ;向下增长

    mov [WAIT_FILL + 3], ax
    mov [real_mode_sp_value], sp


    ;get memory info
    mov ebx, 0
    mov di, _MemChkBuf
.loop:
    mov eax, 0E820h
    mov ecx, 20
    mov edx, 0534D4150h
    int 15h
    jc GET_ARDS_FAIL    ; if (cf != 0) {goto err;}
    add di, 20
    inc dword [_dwMCRNumber]
    cmp ebx, 0          ; if (ebx != 0) {goto loop;}
    jne .loop
    jmp GET_ARDS_OK
GET_ARDS_FAIL:
    mov dword [_dwMCRNumber], 0
GET_ARDS_OK:




    ;fill desc_32code baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _code32_start
    mov word [desc_32code + 2], ax
    shr eax, 16
    mov byte [desc_32code + 4], al
    mov byte [desc_32code + 7], ah

    ;fill desc_16code baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _code16_start
    mov word [desc_16code + 2], ax
    shr eax, 16
    mov byte [desc_16code + 4], al
    mov byte [desc_16code + 7], ah

    ;fill desc_stack  baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _stack_start
    mov word [desc_stack + 2], ax
    shr eax, 16
    mov byte [desc_stack + 4], al
    mov byte [desc_stack + 7], ah


    ;fill desc_data baseaddr 
    xor eax, eax   
    mov ax, cs
    shl eax, 4
    add eax, _data_start
    mov word [desc_data + 2], ax
    shr eax, 16
    mov byte [desc_data + 4], al
    mov byte [desc_data + 7], ah


    ;load gdt
    xor eax, eax
    mov ax, cs
    shl eax, 4
    add eax, desc_null 
    mov dword [gdt_ptr + 2], eax;
    lgdt [gdt_ptr]



    ;关闭中断
    cli

    ;open a20  
    ;8086芯片在访问超过1M的的地址时会回滚
    ;8086'OS为了向上兼容80286的芯片
    ;在不修改系统代码的情况下，关掉20地址线就可以实现地址回滚
	in	al, 92h
	or	al, 00000010b
	out	92h, al

    ;set protect mode
	mov	eax, cr0
	or	eax, 1
	mov	cr0, eax

    ;jmp protect mode
	jmp	dword SELECTOR_32CODE:0     ;dword 表明将偏移0编译后占用32bit 0x12345678 -> 0x5678

    ;go back real mode
REAL_MODE_ENTRY:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, [real_mode_sp_value]

    ;open a20
    in al, 92h
    and al, 11111110b
    out 92h, al

    ;open interrupt
    sti

    ;return dos
    mov ax, 4c00h
    int 21h     


; 下面的代码全运行在保护模式
; 实模式下段寄存器的高速缓冲区(属性缓存)必须正确，同时实模式无法修改缓冲区
; 所以在返回实模式前，使用jmp selector_16code来恢复cs的缓冲区属性(code, 16, exe)，
; 使用mov selector_normal来恢复其他缓冲区属性(data,rw)
[SECTION .16code]
ALIGN 32
[BITS 16]
_code16_start:
    mov ax, SELECTOR_NORMAL
    mov ds, ax          ;使用mov恢复ds的高速缓冲区,下面类似
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax

    mov eax, cr0
    and eax, 7ffffffeh; PG=0;PE=0
    mov cr0, eax

WAIT_FILL:
    jmp 0:REAL_MODE_ENTRY ;cs是动态的，需要运行在实模式时填充
SEG_CODE16_LEN  equ  $ - _code16_start


[SECTION .32code]
[BITS 32]
_code32_start:
    mov ax, SELECTOR_DISPLAY
    mov gs, ax

    mov ax, SELECTOR_DATA
    mov ds, ax
    mov es, ax
    
	mov	ax, SELECTOR_STACK ;没用ss sp时, 后面用了call, 没出问题好奇怪
	mov	ss, ax				
    mov	esp,STACK_TOP 

	push	szPMMessage
    call    DispStr
    add esp, 4

	push	szMemChkTitle
	call	DispStr
	add	esp, 4

    call    _cpy_func

	call	_disp_mem_size    

    call    _setup_paging

    call    _change_process1
    call    SELECTOR_FLAT_C:FUNC_ADDR

    call    _change_process2
    call    SELECTOR_FLAT_C:FUNC_ADDR

    ;jmp $
	jmp	SELECTOR_16CODE:0   ;使用jmp来恢复cs的高速缓冲区





foo:
OffsetFoo		equ	foo - $$
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'F'
	mov	[gs:((80 * 17 + 0) * 2)], ax	; 屏幕第 17 行, 第 0 列。
	mov	al, 'o'
	mov	[gs:((80 * 17 + 1) * 2)], ax	; 屏幕第 17 行, 第 1 列。
	mov	[gs:((80 * 17 + 2) * 2)], ax	; 屏幕第 17 行, 第 2 列。
	ret
LenFoo			equ	$ - foo


bar:
OffsetBar		equ	bar - $$
	mov	ah, 0Ch			; 0000: 黑底    1100: 红字
	mov	al, 'B'
	mov	[gs:((80 * 18 + 0) * 2)], ax	; 屏幕第 18 行, 第 0 列。
	mov	al, 'a'
	mov	[gs:((80 * 18 + 1) * 2)], ax	; 屏幕第 18 行, 第 1 列。
	mov	al, 'r'
	mov	[gs:((80 * 18 + 2) * 2)], ax	; 屏幕第 18 行, 第 2 列。
	ret
LenBar			equ	$ - bar







_cpy_func:
   	mov	ax, cs
	mov	ds, ax
	mov	ax, SELECTOR_FLAT_RW 
	mov	es, ax

	push	LenFoo
	push	OffsetFoo
	push	FUNC_FOO
	call	MemCpy
	add	esp, 12

	push	LenBar
	push	OffsetBar
	push	FUNC_BAR
	call	MemCpy
	add	esp, 12

	;push	LenPagingDemoAll
	;push	OffsetPagingDemoProc
	;push	ProcPagingDemo
	;call	MemCpy
	;add	esp, 12

	mov	ax, SELECTOR_DATA
	mov	ds, ax			; 数据段选择子
	mov	es, ax

    ret
;_cpy_func end
 



_disp_mem_size:
	push	esi
	push	edi
	push	ecx

	mov	esi, MemChkBuf
	mov	ecx, [dwMCRNumber];for(int i=0;i<[MCRNumber];i++)//每次得到一个ARDS
.loop:				    ;{
	mov	edx, 5		  ;  for(int j=0;j<5;j++) //每次得到一个ARDS中的成员
	mov	edi, ARDStruct	  ;  {//依次显示BaseAddrLow,BaseAddrHigh,LengthLow,
.1:				  ;             LengthHigh,Type
	push	dword [esi]	  ;
	call	DispInt		  ;    DispInt(MemChkBuf[j*4]); //显示一个成员
	pop	eax		  ;
	stosd			  ;    ARDStruct[j*4] = MemChkBuf[j*4];
	add	esi, 4		  ;
	dec	edx		  ;
	cmp	edx, 0		  ;
	jnz	.1		  ;  }
	call	DispReturn	  ;  printf("\n");
	cmp	dword [dwType], 1 ;  if(Type == AddressRangeMemory)
	jne	.2		  ;  {
	mov	eax, [dwBaseAddrLow];
	add	eax, [dwLengthLow];
	cmp	eax, [dwMemSize]  ;    if(BaseAddrLow + LengthLow > MemSize)
	jb	.2		  ;
	mov	[dwMemSize], eax  ;    MemSize = BaseAddrLow + LengthLow;
.2:				  ;  }
	loop	.loop		  ;}
				  ;
	call	DispReturn	  ;printf("\n");
	push	szRAMSize	  ;
	call	DispStr		  ;printf("RAM size:");
	add	esp, 4		  ;
				  ;
	push	dword [dwMemSize] ;
	call	DispInt		  ;DispInt(MemSize);
	add	esp, 4		  ;

	call	DispReturn	  ;printf("\n");

	pop	ecx
	pop	edi
	pop	esi
	ret




_setup_paging:
	xor	edx, edx
	mov	eax, [dwMemSize]
	mov	ebx, 400000h	; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
    add eax, ebx
    add eax, -1     ;(a + b - 1)/b
	div	ebx
    mov [PAGETBL_CNT], eax ;此时 eax 为页表的个数，也即PDE的个数


    ;打印页表数量提示字符串,打印页表个数
    push sPGE
    call DispStr
    add esp, 4
	push eax
	call DispInt 
    add esp, 4



    ;init PGE1
    mov ecx, [PAGETBL_CNT]
    mov ax, SELECTOR_FLAT_RW
    mov es, ax
    xor eax, eax
    xor edi, PageDirBase
    mov eax, PageTblBase | PG_P | PG_USU | PG_RWW
.1: stosd
    add eax, 4096
    loop .1


    ;init PTE1
    mov ax, SELECTOR_FLAT_RW
    mov es, ax
    mov eax, [PAGETBL_CNT]
	mov	ebx, 1024		; 每个页表 1024 个 PTE
	mul	ebx
	mov	ecx, eax		; PTE个数 = 页表个数 * 1024
    xor eax, eax
    xor edi, PageTblBase
    mov eax, 0 | PG_P | PG_USU | PG_RWW ; 平坦映射
.2: stosd
    add eax, 4096; 每PTE指向一个4k空间（页）的首地址
    loop .2

    ;func = func_bar
    mov	eax, FUNC_ADDR 
	shr	eax, 22
	mov	ebx, 4096; << 12
	mul	ebx
	mov	ecx, eax
	mov	eax, FUNC_ADDR
	shr	eax, 12
	and	eax, 03FFh	; 1111111111b (10 bits)
	mov	ebx, 4 ;<< 2
	mul	ebx
	add	eax, ecx
	add	eax, PageTblBase; 一个地址占4个空间所以地址都是上移2位的
	mov	dword [es:eax], FUNC_BAR | PG_P | PG_USU | PG_RWW


    ;init PGE2
    mov ecx, [PAGETBL_CNT]
    mov ax, SELECTOR_FLAT_RW
    mov es, ax
    xor eax, eax
    xor edi, PageDirBase2
    mov eax, PageTblBase2 | PG_P | PG_USU | PG_RWW
.3: stosd
    add eax, 4096
    loop .3


    ;init PTE2
    mov ax, SELECTOR_FLAT_RW
    mov es, ax
    mov eax, [PAGETBL_CNT]
	mov	ebx, 1024		; 每个页表 1024 个 PTE
	mul	ebx
	mov	ecx, eax		; PTE个数 = 页表个数 * 1024
    xor eax, eax
    xor edi, PageTblBase2
    mov eax, 0 | PG_P | PG_USU | PG_RWW ; 平坦映射
.4: stosd
    add eax, 4096; 每PTE指向一个4k空间（页）的首地址
    loop .4


    ;func = func_foo
    mov	eax, FUNC_ADDR
	shr	eax, 22
	mov	ebx, 4096; << 12
	mul	ebx
	mov	ecx, eax
	mov	eax, FUNC_ADDR
	shr	eax, 12
	and	eax, 03FFh	; 1111111111b (10 bits)
	mov	ebx, 4 ;<< 2
	mul	ebx
	add	eax, ecx
	add	eax, PageTblBase2; 一个地址占4个空间所以地址都是上移2位的
	mov	dword [es:eax], FUNC_FOO | PG_P | PG_USU | PG_RWW
    ret
;--------- _setup_paging end --------


_change_process1:
    mov eax, PageDirBase
    mov cr3, eax
    mov eax, cr0
    or eax, 80000000h
    mov cr0, eax
    jmp short .test
.test:
    nop
    ret


_change_process2:
    mov eax, PageDirBase2
    mov cr3, eax
    mov eax, cr0
    or eax, 80000000h
    mov cr0, eax
    jmp short .test
.test:
    nop
    ret



%include "lib.inc"

SEG_CODE32_LEN  equ  $ - _code32_start

  
