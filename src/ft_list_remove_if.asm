section .text
    global ft_list_remove_if
    extern free

ft_list_remove_if:
    ; RDI contiene begin_list
    ; RSI contiene data_ref
    ; RDX contiene puntero a la función del compare
    ; RCX contiene puntero a la función del free

    ; Alineo la pila
    push rbp
    mov rbp, rsp

    ; Guardo los registros inmutables
    push r12
    push r13
    push r14
    push r15

    ; Altero los registros inmutables
    mov r12, rdi
    mov r13, RSI
    mov r14, rdx
    mov r15, rcx


    .recorrer_list:
        mov r8, [r12]
        cmp r8, 0
        je .fin

        mov rdi, [r8]
        mov rsi, r13
        call r14

        cmp eax, 0
        je .eliminar_nodo

        mov r8, [r12]
        mov r12, [r8 + 8] 
        jmp .recorrer_list

    .eliminar_nodo:
        mov r8, [r12]
        mov r11, [r8 + 8]
        mov [r12], r11

        cmp r15, 0
        je .free_nodo
        
        mov rdi, [r8]
        call r15

        jmp .recorrer_list

        .free_nodo:

        mov rdi, [r8]
        call free WRT ..plt
        jmp .recorrer_list


    .fin:
        pop r15
        pop r14
        pop r13
        pop r12
        mov rsp, rbp
        pop rbp