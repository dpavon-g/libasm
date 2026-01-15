section .text
    global ft_strdup
    extern ft_strlen
    extern malloc

ft_strdup:
    ; Entrada: RDI = s
    
    push rdi

    call ft_strlen

    mov rdi, rax

    inc rdi

    call malloc WRT ..plt

    test rax, rax
    jz .error_handler

    mov rdi, rax
    pop rsi
    push rax
    
.copy_string:
    mov al, [rsi]
    mov [rdi], al
    test al, al  
    jz .end
    inc rdi
    inc rsi
    jmp .copy_string

.end:
    pop rax
    ret

.error_handler:
    add rsp, 8
    xor rax, rax
    ret