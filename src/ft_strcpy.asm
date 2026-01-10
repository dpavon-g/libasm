section .text
    global ft_strcpy

ft_strcpy:
    ; Entrada: RDI = dest, RSI = src
    mov rax, rdi
    
.next_char:
    mov cl, [rsi]
    mov [rdi], cl

    test cl, cl
    jz .done

    inc rsi
    inc rdi

    jmp .next_char

.done:
    ret