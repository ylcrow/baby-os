
get_mem_info:
    mov ebx, 0
    mov di, mem_info_buf
.loop:
    mov eax, 0E820h
    mov ecx, 20
    mov edx, 0534D4150h
    int 15h
    jc GET_ARDS_FAIL    ; if (cf != 0) {goto err;}
    add di, 20
    inc dword [mem_ards_cnt]
    cmp ebx, 0          ; if (ebx != 0) {goto loop;}
    jne .loop
    jmp GET_ARDS_OK
GET_ARDS_FAIL:
    mov dword [mem_ards_cnt], 0
GET_ARDS_OK:
    ret


