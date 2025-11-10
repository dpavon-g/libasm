section .text
global ft_strlen

ft_strlen:
    xor rax, rax           ; Set RAX (length) to 0
.next_char:
    cmp byte [rdi + rax], 0 ; Compare current byte with 0
    je .done               ; If 0, jump to done
    inc rax                ; Increment RAX
    jmp .next_char         ; Repeat
.done:
    ret                    ; Return length in RAX