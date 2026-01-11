section .text
    global ft_strncmp

ft_strncmp:
    ; Entrada: RDI = s1, RSI = s2, RDX = n
    xor rax, rax
    test rdx, rdx
    jz .done_equals

.next_char:

    mov al, [rdi]
    mov cl, [rsi]

    cmp al, cl
    jne .done


    test al, al
    jz .done_equals

    inc rdi
    inc rsi
    dec rdx

    test rdx, rdx
    jz .done_equals

    jmp .next_char

.done:
    movzx eax, al
    movzx ecx, cl

    sub eax, ecx

    ret

.done_equals:
    xor rax, rax
    ret

    

