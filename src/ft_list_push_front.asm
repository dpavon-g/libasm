section .text
    global ft_list_push_front
    extern malloc


ft_list_push_front:
    cmp rdi, 0
    je .end_function

    push rbp
    mov rbp, rsp
    
    push rdi
    push rsi

    mov rdi, 16
    call malloc WRT ..plt

    pop rsi
    pop rdi

    mov rsp, rbp
    pop rbp

    cmp rax, 0
    je .end_function

    mov [rax], rsi

    mov rdx, [rdi]
    mov [rax + 8], rdx
    mov [rdi], rax

.end_function:
    ret