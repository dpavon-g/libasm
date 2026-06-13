ft_atoi_base:

    .comprobar_longitud_base:
        push rdi
        mov rdi, rsi
        call ft_strlen
        cmp rax, 1
        jbe .retornar_cero

    .retornar_cero:
        xor rax, rax
    .fin:
        pop rdi
        mov rsp, rbp
        pop rbp
        ret
    
    