section .text
global ft_strlen

ft_strlen:
    mov rax, 0;
    .next_char:
        cmp byte [rdi + rax], 0

