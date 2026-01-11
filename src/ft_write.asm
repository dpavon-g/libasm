section .text
    global ft_write
    extern __errno_location

ft_write:
    mov rax, 1
    syscall

    cmp rax, 0
    jl .error_handler

    ret

.error_handler:
    neg rax

    push rax

    call __errno_location wrt ..plt

    pop rdi
    
    mov [rax], edi
    
    mov rax, -1
    ret