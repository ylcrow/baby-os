
enable_mmu:
	xor	edx, edx
	mov	eax, [dwMemSize]
	mov	ebx, 400000h	; 400000h = 4M = 4096 * 1024, 一个页表对应的内存大小
    add eax, ebx
    add eax, -1     ;(a + b - 1)/b
	div	ebx
	mov	ecx, eax	; 此时 ecx 为页表的个数，也即 PDE 应该的个数
    push sPGE 
    call DispStr
    add esp, 4
	push ecx		; 暂存页表个数, call后不要pop了
	call DispInt

    ;init PGE
    mov ax, SELECTOR_FLAT_RW
    mov es, ax
    xor eax, eax
    mov edi, PageDirBase
    mov eax, PageTblBase | PG_P | PG_USU | PG_RWW
.1: stosd
    add eax, 4096
    loop .1


    ;init PTE
    ;mov ecx, 1024 * 1024 ; 1024个页表，每个页表1024项，简化连续处理; 共1M个页表项
	pop	eax			    ; 页表个数,将暂存的ecx pop出来
	mov	ebx, 1024		; 每个页表 1024 个 PTE
	mul	ebx
	mov	ecx, eax		; PTE个数 = 页表个数 * 1024
    xor eax, eax
    mov edi, PageTblBase
    mov eax, 0 | PG_P | PG_USU | PG_RWW ; 平坦映射
.2: stosd
    add eax, 4096; 每PTE指向一个4k空间（页）的首地址
    loop .2


    ;enable  mmu
    mov eax, PageDirBase
    mov cr3, eax
    mov eax, cr0
    or eax, 80000000h
    mov cr0, eax
    jmp short .3
.3:
    nop
    ret



