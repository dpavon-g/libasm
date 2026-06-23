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

    ; Aquí empezaria a hacer los bucles

    .restore_exit:
        pop r13
        pop r12
        pop rbx

        mov rsp, rbp
        pop rbp

    .final:
        ret