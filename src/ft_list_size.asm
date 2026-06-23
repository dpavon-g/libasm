section .text
    global ft_list_size

ft_list_size:

    mov rax, 0
    
    .bucle:
        cmp rdi, 0
        je .finish
        inc rax
        mov rdi, [rdi + 8]
        jmp .bucle
        
    .finish:
        ret