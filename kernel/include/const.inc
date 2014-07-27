
INT_M_CTL       equ   0x20 
INT_M_CTLMASK   equ   0x21 
INT_S_CTL       equ   0xA0 
INT_S_CTLMASK   equ   0xA1 
EOI             equ   0x20



SELECTOR_DUMMY		equ    0x00 
SELECTOR_FLAT_C		equ    0x08 		
SELECTOR_FLAT_RW	equ    0x10 		
SELECTOR_VIDEO		equ    (0x18 + 3)
SELECTOR_TSS		equ    0x20	
SELECTOR_LDT	    equ    0x28	


; 任务现场结构体偏移
STACKFRAME_SIZE             equ   (18 * 4)
STACKFRAME_RETADR_OFFSET    equ   (12 * 4)
STACKFRAME_ESP_OFFSET       equ   (16 * 4)


; 任务结构体偏移 
PROCESS_LDT_OFFSET          equ     STACKFRAME_SIZE
PROCESS_TASK_TYPE_OFFSET    equ     STACKFRAME_SIZE + 4

; 任务类型
TASK_TYPE_USER              equ   2


; TSS偏移
TSS_ESP0_OFFSET             equ   4


