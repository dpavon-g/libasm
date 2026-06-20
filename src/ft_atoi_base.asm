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
        mov r10, rax
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
                jne .empezar_conversion_matematica
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
    
    .empezar_conversion_matematica:
        mov r8, 0
        mov r11, 0 ; Registro para recorrer la base
        ; r10 tiene la longitud de la base.

        .aumentar_puntero_base:
            cmp byte[rsi + r11], 0
            je .termina_sin_numero
            cmp cl, byte[rsi + r11]
            je .add_numero
            .continuar_bucle:
                inc r11
                jmp .aumentar_puntero_base

            .siguiente_numero:
                inc rax
                mov cl, byte[rdi + rax]
                cmp cl, 0
                je .terminar_recorrido
                jmp .aumentar_puntero_base

    .add_numero:
        imul r8, r10
        add r8, r11
        mov r11, 0
        jmp .siguiente_numero

    .terminar_recorrido:
        cmp r9b, -1
        jne .salir
        neg r8
        .salir:
            mov rax, r8
            ret

    .termina_sin_numero:
        xor rax, rax
        ret

    .fin:
        pop rdi
        ret

    
    
