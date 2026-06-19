section .text
    global ft_atoi_base
    extern ft_strlen

ft_atoi_base:

    .comprobar_longitud_base:
        push rdi
        mov rdi, rsi
        call ft_strlen
        cmp rax, 1
        jbe .retornar_cero
        jmp .buscar_invalid_chars

    .retornar_cero:
        xor rax, rax
        jmp .fin

    .retornar_uno:
        mov rax, 1
        ret

    .buscar_invalid_chars:
        mov rdi, rsi
        mov rax, 0

        .next_char:
            cmp byte [rdi + rax], 0
            je .check_espacios

            mov cl, byte [rdi + rax]
            cmp cl, ' '
                je .retornar_cero
            cmp cl, 43
                je .retornar_cero
            cmp cl, 45
                je .retornar_cero
            cmp cl, 9
                jb .comprobar_duplicado
            cmp cl, 13
                jbe .retornar_cero
            
            jmp .comprobar_duplicado

            .siguiente_char:
                inc rax
                jmp .next_char

    .check_espacios:
        pop rdi
        mov rax, -1
        
        .move_for_spaces:
            inc rax
            mov cl, byte[rdi + rax]
            cmp cl, ' '
                je .move_for_spaces
            cmp cl, 9
                je .move_for_spaces
            cmp cl, 10
                je .move_for_spaces
            cmp cl, 11
                je .move_for_spaces
            cmp cl, 12
                je .move_for_spaces
            cmp cl, 13
                je .move_for_spaces
            cmp cl, 0
                je .termina_sin_numero
            
    .check_signos:
        dec rax
        mov r9b, 1

        .move_for_signos:
            inc rax
            mov cl, byte[rdi + rax]
            cmp cl, 0
                je .termina_sin_numero
            cmp cl, '+'
                je .move_for_signos
            cmp cl, '-'
                jne .retornar_uno ;Hago esto para que no se rompa, tengo que seguir la ejecucion aqui.
            neg r9b
            jmp .move_for_signos

    .comprobar_duplicado:
        push rax
        .incrementar_busqueda_duplicado:
            inc rax
            cmp byte [rdi + rax], 0
                je .fin_comprobar_duplicado

            cmp cl, byte [rdi + rax]
                jne .incrementar_busqueda_duplicado

            pop rax
            jmp .retornar_cero

            .fin_comprobar_duplicado:
                pop rax
                jmp .siguiente_char
    
    .termina_sin_numero:
        xor rax, rax
        ret

    .fin:
        pop rdi
        ret

    
    
