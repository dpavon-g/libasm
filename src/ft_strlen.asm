section .text
global ft_strlen

ft_strlen:
    mov rax, 0

.next_char:
    cmp byte [rdi + rax], 0
    je .done

    inc rax
    jmp .next_char

.done:
    ret