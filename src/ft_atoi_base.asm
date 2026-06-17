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
        jmp .fin

    .buscar_invalid_chars:
        mov rdi, rsi
        mov rax, 0

        .next_char:
            cmp byte [rdi + rax], 0
            je .check_espacios_y_signos_num

            mov cl, byte [rdi + rax]
            cmp cl, 43
                je .retornar_cero
            cmp cl, 45
                je .retornar_cero
            cmp cl, 9
                jl .comprobar_duplicado
            cmp cl, 13
                jle .retornar_cero
            
            jmp .comprobar_duplicado

            .siguiente_char:
                inc rax
                jmp .next_char

    .check_espacios_y_signos_num:
        jmp .retornar_uno

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

    .fin:
        pop rdi
        ret
    
    
