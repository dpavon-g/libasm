section .text
    global ft_list_remove_if
    extern malloc

ft_list_remove_if:
    ; RDI contiene begin_list
    ; RSI contiene data_ref
    ; RDX contiene puntero a la función del compare
    ; RCX contiene puntero a la función del free

    push rbp
    mov rbp, rsp
    push r12
    push r13

    .recorrer_list:
        cmp rdi, 0
        je .fin
        push rdi
        mov rdi, [rdi]
        call rdx
        cmp rax, 0
        je .eliminar_nodo
        pop rdi
        mov rdi, [rdi + 8]
        jmp .recorrer_list

    .eliminar_nodo
        mov r11, [rdi + 8]

        .eliminar_primer_nodo:

    .fin:
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp