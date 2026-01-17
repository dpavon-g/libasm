section .text
    global ft_atoi_base
    extern ft_strlen

ft_atoi_base:
    ; Entrada: RDI = str, RSI = base
    jmp .check_base_length

.check_base_length:
    push rdi
    mov rdi, rsi
    call ft_strlen

    cmp rax, 2
    jl .error_handler

    pop rdi

    push rsi

    jmp .check_base_errors

.check_base_errors:
    mov al, [rsi]

    cmp al, '+'
    je .error_handler
    cmp al, '-'
    je .error_handler
    ; Los chars invalidos son del 9 al 13(tabulaciones y espacios varios) y el 32(espacio normal), 
    ; por lo que si le restamos 9 y el num es menor o igual a 4 significa que es invalido
    cmp al, 32
    je .error_handler

    sub al, 9
    cmp al, 4
    jbe .error_handler

    add al, 9

    ; Por ultimo comprobamos que encuentre el nulo en la cadena
    test al, al
    jz .check_base_repeats

    inc rsi
    jmp .check_base_errors

.check_base_repeats:
    ; Aqui compruebo si no se repite ningun char en la base 
    pop rsi
    push rsi
    mov rdx, rsi
    dec rdx

    .principal_iter_base:
    inc rdx
    mov bl, [rdx]
    test bl, bl
    jz .check_str_errors
    mov rsi, rdx
    .second_iter_base:
        inc rsi
        mov al, [rsi]
        cmp al, bl
        je .error_handler

        test al, al
        jz .principal_iter_base

        jmp .second_iter_base

.check_str_errors:
    ; Comprobamos longitud de str
    pop rsi
    push rdi
    call ft_strlen

    cmp rax, 2
    jl .error_handler

    pop rdi

    jmp .end

.end:
    mov rax, 1
    ret

.error_handler:
    add rsp, 8
    mov rax, 0
    ret