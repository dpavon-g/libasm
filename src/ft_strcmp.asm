section .text
    global ft_strcmp

ft_strcmp:
    ; Entrada: RDI = s1, RSI = s2
    xor rax, rax

.next_char:
    mov al, [rdi]
    mov cl, [rsi]

    cmp al, cl
    jne .done

    test al, al
    jz .done

    inc rdi
    inc rsi

    jmp .next_char

.done:
    movzx eax, al
    movzx ecx, cl

    sub eax, ecx

    ret


    

