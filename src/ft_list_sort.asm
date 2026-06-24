section .text
    global ft_list_sort

ft_list_sort:
    cmp rdi, 0
    je .final

    push rbp
    mov rbp, rsp

    push rbx
    push r12
    push r13

    mov r13, rsi
    mov rbx, [rdi]
    cmp rbx, 0
    je .restore_exit

    .recorrer_bucle:
        cmp rbx, 0
        je .restore_exit
        mov r12, [rbx + 8]

        .comparar_nodos:
            cmp r12, 0
            je .avanzar_nodo1

            mov rdi, [rbx]
            mov rsi, [r12]
            call r13

            cmp eax, 0
            jge .hacer_swap

            mov r12, [r12 + 8]
            jmp .comparar_nodos

        .hacer_swap:
            mov r8, [rbx]
            mov r9, [r12]
            mov [rbx], r9
            mov [r12], r8

        .avanzar_nodo1:
            mov rbx, [rbx + 8]
            jmp .recorrer_bucle

    .restore_exit:
        pop r13
        pop r12
        pop rbx

        mov rsp, rbp
        pop rbp

    .final:
        ret