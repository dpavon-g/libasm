section .text
    global ft_strncpy

ft_strncpy:
    ; Entrada: RDI = dest, RSI = src, RDX = n
    mov rax, rdi
    
.next_char:
    test rdx, rdx
    jz .done

    mov cl, [rsi]
    mov [rdi], cl

    test cl, cl
    jz .done

    inc rsi
    inc rdi
    dec rdx

    jmp .next_char

.done:
    ret