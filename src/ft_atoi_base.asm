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

    mov r15, rax

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
    xor cl, cl
    ; Aqui voy a comprobar que solo haya espacios al principio
    jmp .src_valid_string
    jmp .end

.cmp_space_char_str:
    cmp cl, 0
    jz .next_str_char
    jmp .error_handler_without_stack

.src_valid_string:
    ; Esta funcion va a comprobar los espacios que tiene el string, si encuentra un espacio checkea rax para ver si ha encontrado otro char diferente antes, si no lo ha encontrado sigue, sino da error. En caso de que encuentre un signo + o - empezara a tratar de convertir la string en num.
    mov al, [rdi]
    cmp al, 32
    je .cmp_space_char_str
    sub al, 9
    cmp al, 4
    jbe .cmp_space_char_str
    add al, 9
    .init_sign:
        mov r8, 1
    .check_sign:
        cmp al, '-'
        jne .check_plus
        mov r8, -1
        inc rdi
        jmp .convert_string
    
    .check_plus:
        cmp al, '+'
        je .start_convert
        .start_convert:
        inc rdi
        jmp .convert_string

    jmp .convert_string
    inc cl
    .next_str_char:
        inc rdi
        jmp .src_valid_string

.convert_string:
    xor rax, rax ; lo uso para recorrer la cadena
    xor rcx, rcx ; lo uso para calcular el valor del char
    xor r14, r14 ; lo uso para saber en que posicion de la cadena estoy
    xor r13, r13 ; lo uso para almacenar el valor final
    .inc_final_string:
        ; resultado = (posicion del char * logintud base) + valor posicion base
        ; r14 contiene la posicion del char
        ; r15 contiene la longitud de la base
        mov rcx, r14
        imul r14, r15
        add r13, r14
        mov al, [rdi]
        test al, al
        jz .end_final
        inc rdi
        inc r14
        jmp .inc_final_string

.end_final:
    imul r13, r8
    mov rax, r13
    ret

.end:
    mov rax, 1
    ret

.error_handler_without_stack:
    xor rax, rax
    ret

.error_handler:
    add rsp, 8
    xor rax, rax
    ret