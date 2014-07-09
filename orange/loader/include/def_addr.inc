;boot
BOOTIMG_OFFSET  equ     07c00h          ;boot加载的偏移地址
BOOT_STACK_TOP  equ     BOOTIMG_OFFSET  ;boot的stack顶


;loader
LOADERIMG_VIRT_BASE_ADDR        equ  09000h
LOADERIMG_PHYS_BASE_ADDR        equ  LOADERIMG_VIRT_BASE_ADDR  * 010h
LOADERIMG_OFFSET                equ  0100h
LOADER_RM_STACK_TOP             equ  LOADERIMG_OFFSET  ;因为ss = cs 所以这样用就刚好在offset下面 

;kernel
KERNELIMG_VIRT_BASE_ADDR        equ  08000h
KERNELIMG_PHYS_BASE_ADDR        equ  KERNELIMG_VIRT_BASE_ADDR  * 010h
KERNELIMG_OFFSET                equ  0h
KERNELIMG_PHYS_ADDR             equ  KERNELIMG_PHYS_BASE_ADDR  + KERNELIMG_OFFSET 
KERNEL_ENNTRY_PHY_ADDR          equ  030400h

PageDirBase     equ 200000h  ;2M
PageTblBase     equ 201000h  ;2M + 4k


