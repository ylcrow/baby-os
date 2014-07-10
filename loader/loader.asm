%include "pm.inc"    
%include "def_addr.inc"

org	 LOADERIMG_OFFSET

    jmp loader_start

    ;search_image函数会用到一些变量,可以在精简下
    %include "fat12_hdr.asm" 

    desc_gdt:           Descriptor 0,               0,                      0                               ; NULL指针
    desc_flat_c:        Descriptor 0,               0fffffh,                DA_CR  | DA_32 | DA_LIMIT_4K    ; 0~4G
    desc_flat_rw:       Descriptor 0,               0fffffh,                DA_DRW | DA_32 | DA_LIMIT_4K    ; 0~4G
    desc_display:       Descriptor 0B8000h,         0ffffh,                 DA_DRW | DA_DPL3                ;  

    gdt_ptr     dw      $ - desc_gdt - 1                                ;16bits  gdt_limit (gdt_len - 1)
                dd      LOADERIMG_PHYS_BASE_ADDR + desc_gdt             ;32bits  gdt_baseaddr 

    ;selector
    SELECTOR_FLAT_C     equ desc_flat_c - desc_gdt
    SELECTOR_FLAT_RW    equ desc_flat_rw - desc_gdt
    SELECTOR_DISPLAY    equ desc_display - desc_gdt + SA_RPL3 


loader_start:
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, LOADER_RM_STACK_TOP

    ; 获取内存信息
    call    get_mem_info  ;输出参数：mem_info_buf, mem_ards_cnt

    ; loader kernel.bin
    call    search_image
    
    ; 加载 GDTR
    lgdt	[gdt_ptr]
    
    ; 关中断
    cli
    
    ; 打开地址线A20
    in	al, 92h
    or	al, 00000010b
    out	92h, al
    
    ; 准备切换到保护模式
    mov	eax, cr0
    or	eax, 1
    mov	cr0, eax
    
    ; 真正进入保护模式
    jmp	dword SELECTOR_FLAT_C:(LOADERIMG_PHYS_BASE_ADDR + pro_mode_start)


    %include "get_mem.asm"
    %include "search_in_fat12.asm"





[SECTION .code]
ALIGN	32
[BITS	32]
pro_mode_start:
	mov	ax, SELECTOR_DISPLAY
	mov	gs, ax
	mov	ax, SELECTOR_FLAT_RW
	mov	ds, ax
	mov	es, ax
	mov	fs, ax
	mov	ss, ax
	mov	esp, LOADER_PM_STACK_TOP

    
    call cal_mem_size   ;输入参数：mem_info_buf, mem_ards_cnt
                        ;输出参数：_dwMemSize
    
    call enable_mmu     ;输入参数：_dwMemSize

    call init_kernel    ;加载ELF格式kernel

	jmp SELECTOR_FLAT_C:KERNEL_ENNTRY_PHY_ADDR       

    %include "lib.asm"
    %include "enable_mmu.asm"
    %include "cal_mem_size.asm"
    %include "init_kernel.asm"


    


[SECTION .data]
ALIGN	32
    ; get_mem_info  && cal_mem_size 
    ; --------------------------------------------------------
    mem_info_buf:       times	256	db	0
    mem_ards_cnt:       dd	0
    MEM_INFO_BUF    equ LOADERIMG_PHYS_BASE_ADDR + mem_info_buf
    MEM_ARDS_CNT    equ LOADERIMG_PHYS_BASE_ADDR + mem_ards_cnt
    ;取物理地址是因为选择子从0开始了,我们用了平坦映射



    ; cal_mem_size  && enable_mmu 
    ; --------------------------------------------------------
    _dwMemSize:			    dd	0
    _szMemChkTitle:		    db	"BaseAddrL BaseAddrH LengthLow LengthHigh   Type", 0Ah, 0
    _str_ram_size:		    db	"RAM size:", 0
    _sPGE   			    db	0AH, "PageDirEntry/PageTable Count: ", 0
    _ARDStruct:
	_dwBaseAddrLow:		    dd	0
	_dwBaseAddrHigh:	    dd	0
	_dwLengthLow:		    dd	0
	_dwLengthHigh:		    dd	0
	_dwType:		        dd	0

    dwMemSize		    equ	LOADERIMG_PHYS_BASE_ADDR + _dwMemSize
    szMemChkTitle		equ LOADERIMG_PHYS_BASE_ADDR +	_szMemChkTitle
    STR_RAM_SIZE        equ	LOADERIMG_PHYS_BASE_ADDR +_str_ram_size
    sPGE                equ LOADERIMG_PHYS_BASE_ADDR +_sPGE 
    ARDStruct		    equ	LOADERIMG_PHYS_BASE_ADDR +_ARDStruct
    dwBaseAddrLow	    equ	LOADERIMG_PHYS_BASE_ADDR +_dwBaseAddrLow
    dwBaseAddrHigh	    equ	LOADERIMG_PHYS_BASE_ADDR +_dwBaseAddrHigh
    dwLengthLow	        equ	LOADERIMG_PHYS_BASE_ADDR +_dwLengthLow
    dwLengthHigh	    equ	LOADERIMG_PHYS_BASE_ADDR +_dwLengthHigh
    dwType		        equ	LOADERIMG_PHYS_BASE_ADDR +_dwType



    ; search_image
    ; --------------------------------------------------------
    image_name          db	"KERNEL  BIN"	        ; 需要加载的img名,fat12保存文件名时以两个space代替"."
    IMG_NAME_LEN    equ  $ - image_name         ; fat12: max 13 bytes(8文件名 + 3后缀名 + 2space)
    IMG_BASE        equ	KERNELIMG_VIRT_BASE_ADDR      	; image 被加载到的段地址
    IMG_OFFSET      equ	KERNELIMG_OFFSET                ; image 被加载到的偏移地址


    ; printf
    ; --------------------------------------------------------
    _dwDispPos:			dd	(80 * 6 + 0) * 2	; 屏幕第 6 行, 第 0 列。
    _szReturn:			db	0Ah, 0
    dwDispPos		equ	LOADERIMG_PHYS_BASE_ADDR + _dwDispPos
    szReturn		equ	LOADERIMG_PHYS_BASE_ADDR + _szReturn


    ; --------------------------------------------------------
    times	1000h	db	0
    LOADER_PM_STACK_TOP equ	LOADERIMG_PHYS_BASE_ADDR + $	; 栈顶


















	;***************************************************************
	; 内存看上去是这样的：
	;              ┃                                    ┃
	;              ┃                 .                  ┃
	;              ┃                 .                  ┃
	;              ┃                 .                  ┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■■■■■■■■■■■┃
	;              ┃■■■■■■Page  Tables■■■■■■┃
	;              ┃■■■■■(大小由LOADER决定)■■■■┃
	;    00101000h ┃■■■■■■■■■■■■■■■■■■┃ PageTblBase
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■■■■■■■■■■■┃
	;    00100000h ┃■■■■Page Directory Table■■■■┃ PageDirBase  <- 1M
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□□□□□□□□□□□□□□□┃
	;       F0000h ┃□□□□□□□System ROM□□□□□□┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□□□□□□□□□□□□□□□┃
	;       E0000h ┃□□□□Expansion of system ROM □□┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□□□□□□□□□□□□□□□┃
	;       C0000h ┃□□□Reserved for ROM expansion□□┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□□□□□□□□□□□□□□□┃ B8000h ← gs
	;       A0000h ┃□□□Display adapter reserved□□□┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□□□□□□□□□□□□□□□┃
	;       9FC00h ┃□□extended BIOS data area (EBDA)□┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■■■■■■■■■■■┃
	;       90000h ┃■■■■■■■LOADER.BIN■■■■■■┃ somewhere in LOADER ← esp
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■■■■■■■■■■■┃
	;       80000h ┃■■■■■■■KERNEL.BIN■■■■■■┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■■■■■■■■■■■┃
	;       30000h ┃■■■■■■■■KERNEL■■■■■■■┃ 30400h ← KERNEL 入口 (KernelEntryPointPhyAddr)
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃                                    ┃
	;        7E00h ┃              F  R  E  E            ┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃■■■■■■■■■■■■■■■■■■┃
	;        7C00h ┃■■■■■■BOOT  SECTOR■■■■■■┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃                                    ┃
	;         500h ┃              F  R  E  E            ┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃□□□□□□□□□□□□□□□□□□┃
	;         400h ┃□□□□ROM BIOS parameter area □□┃
	;              ┣━━━━━━━━━━━━━━━━━━┫
	;              ┃◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇◇┃
	;           0h ┃◇◇◇◇◇◇Int  Vectors◇◇◇◇◇◇┃
	;              ┗━━━━━━━━━━━━━━━━━━┛ ← cs, ds, es, fs, ss
	;
	;
	;		┏━━━┓		┏━━━┓
	;		┃■■■┃ 我们使用 	┃□□□┃ 不能使用的内存
	;		┗━━━┛		┗━━━┛
	;		┏━━━┓		┏━━━┓
	;		┃      ┃ 未使用空间	┃◇◇◇┃ 可以覆盖的内存
	;		┗━━━┛		┗━━━┛
	;
	; 注：KERNEL 的位置实际上是很灵活的，可以通过同时改变 LOAD.INC 中的 KernelEntryPointPhyAddr 和 MAKEFILE 中参数 -Ttext 的值来改变。
	;     比如，如果把 KernelEntryPointPhyAddr 和 -Ttext 的值都改为 0x400400，则 KERNEL 就会被加载到内存 0x400000(4M) 处，入口在 0x400400。
	;


