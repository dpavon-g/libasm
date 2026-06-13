# libasm

Reimplementación de funciones de la libft en ensamblador x86-64 (NASM).
## Convención de registros

| Registro | Uso |
|----------|-----|
| `RDI`    | Primer argumento |
| `RSI`    | Segundo argumento |
| `RDX`    | Tercer argumento |
| `RAX`    | Valor de retorno |
| `RCX`, `R8`-`R11` | Volátiles (pueden modificarse) |

---

## ft_strlen

**Prototipo:** `size_t ft_strlen(const char *s)`

Calcula la longitud de una cadena contando bytes hasta encontrar el carácter nulo `\0`.

```asm
ft_strlen:
    mov rax, 0          ; RAX = contador, empieza en 0

.next_char:
    cmp byte [rdi + rax], 0   ; Compara s[RAX] con '\0'
    je .done                   ; Si es nulo, terminamos

    inc rax                    ; Si no, avanzamos el contador
    jmp .next_char

.done:
    ret                        ; RAX contiene la longitud
```

**Cómo funciona:** En lugar de mover el puntero `RDI`, se usa `RAX` como índice. Se accede a cada byte con la dirección base más el índice (`[rdi + rax]`). Cuando el byte es `0`, `RAX` ya vale la longitud y se devuelve directamente.

---

## ft_strcmp

**Prototipo:** `int ft_strcmp(const char *s1, const char *s2)`

Compara dos cadenas carácter a carácter. Devuelve la diferencia del primer par de bytes distintos, o `0` si son iguales.

```asm
ft_strcmp:
    xor rax, rax        ; Limpia RAX (también limpia AH, AL)

.next_char:
    mov al, [rdi]       ; AL = byte actual de s1
    mov cl, [rsi]       ; CL = byte actual de s2

    cmp al, cl
    jne .done           ; Si son distintos, saltar a calcular diferencia

    test al, al
    jz .done            ; Si ambos son '\0' (iguales), terminamos

    inc rdi
    inc rsi
    jmp .next_char

.done:
    movzx eax, al       ; Extiende AL a EAX sin signo
    movzx ecx, cl       ; Extiende CL a ECX sin signo
    sub eax, ecx        ; Diferencia s1[i] - s2[i]
    ret
```

**Cómo funciona:** Se leen los bytes de ambas cadenas en `AL` y `CL`. Si difieren, se sale del bucle. El `movzx` antes del `sub` es clave: convierte los bytes a enteros sin signo de 32 bits para que la resta sea correcta y no haya desbordamiento de signo. Si los bytes son iguales y ninguno es `\0`, se avanza ambos punteros.

---

## ft_strcpy

**Prototipo:** `char *ft_strcpy(char *dest, const char *src)`

Copia la cadena `src` en `dest`, incluyendo el `\0` final. Devuelve `dest`.

```asm
ft_strcpy:
    mov rax, rdi        ; Guarda dest en RAX para devolverlo al final

.next_char:
    mov cl, [rsi]       ; CL = byte actual de src
    mov [rdi], cl       ; Lo escribe en dest

    test cl, cl
    jz .done            ; Si acabamos de escribir '\0', terminamos

    inc rsi
    inc rdi
    jmp .next_char

.done:
    ret                 ; RAX = puntero original a dest
```

**Cómo funciona:** Lo primero es salvar `RDI` en `RAX` porque la función debe devolver el puntero al destino, pero `RDI` se va a modificar durante la copia. Luego se copia byte a byte usando `CL` como registro intermedio. El `\0` también se copia (la comprobación `test cl, cl` ocurre *después* de escribirlo).

---

## ft_strncpy

**Prototipo:** `char *ft_strncpy(char *dest, const char *src, size_t n)`

Copia hasta `n` bytes de `src` en `dest`. Se detiene antes si encuentra `\0`.

```asm
ft_strncpy:
    mov rax, rdi        ; Guarda dest en RAX

.next_char:
    test rdx, rdx
    jz .done            ; Si n == 0, terminamos

    mov cl, [rsi]       ; CL = byte actual de src
    mov [rdi], cl       ; Escribe en dest

    test cl, cl
    jz .done            ; Si es '\0', terminamos

    inc rsi
    inc rdi
    dec rdx             ; n--
    jmp .next_char

.done:
    ret
```

**Cómo funciona:** Igual que `ft_strcpy` pero con un tercer argumento en `RDX` que actúa como contador descendente. Hay dos condiciones de salida: que `RDX` llegue a `0` (se copió el máximo) o que el byte copiado sea `\0` (fin de cadena). A diferencia de la versión de la libc, esta implementación **no rellena** el resto con ceros cuando `src` es más corta que `n`.

---

## ft_strncmp

**Prototipo:** `int ft_strncmp(const char *s1, const char *s2, size_t n)`

Compara hasta `n` caracteres de dos cadenas.

```asm
ft_strncmp:
    xor rax, rax
    test rdx, rdx
    jz .done_equals     ; Si n == 0, son iguales por definición

.next_char:
    mov al, [rdi]
    mov cl, [rsi]

    cmp al, cl
    jne .done           ; Bytes distintos: calcular diferencia

    test al, al
    jz .done_equals     ; Ambos son '\0': iguales

    inc rdi
    inc rsi
    dec rdx
    test rdx, rdx
    jz .done_equals     ; Se compararon n bytes sin diferencia

    jmp .next_char

.done:
    movzx eax, al
    movzx ecx, cl
    sub eax, ecx
    ret

.done_equals:
    xor rax, rax
    ret
```

**Cómo funciona:** Combina la lógica de `ft_strcmp` con el contador `n` de `ft_strncpy`. Tiene dos etiquetas de salida separadas: `.done` para cuando los bytes difieren (devuelve la diferencia) y `.done_equals` para cuando se llega a `n` o a `\0` en ambas cadenas (devuelve `0`). El caso `n == 0` se trata al inicio como igualdad inmediata.

---

## ft_strdup

**Prototipo:** `char *ft_strdup(const char *s)`

Duplica una cadena reservando memoria dinámica. Devuelve el puntero a la copia, o `NULL` si falla `malloc`.

```asm
ft_strdup:
    push rdi            ; Salva el puntero a s (RDI se perderá en las llamadas)

    call ft_strlen      ; RAX = longitud de s (sin '\0')

    mov rdi, rax
    inc rdi             ; RDI = longitud + 1 (espacio para el '\0')

    call malloc WRT ..plt   ; RAX = puntero al bloque reservado

    test rax, rax
    jz .error_handler   ; malloc devolvió NULL

    mov rdi, rax        ; RDI = destino (bloque nuevo)
    pop rsi             ; RSI = s original (recuperada de la pila)
    push rax            ; Salva el puntero destino para devolverlo

.copy_string:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .end
    inc rdi
    inc rsi
    jmp .copy_string

.end:
    pop rax             ; Recupera el puntero al inicio del bloque
    ret

.error_handler:
    add rsp, 8          ; Limpia el RDI que quedó en la pila (pop sin registro)
    xor rax, rax        ; Devuelve NULL
    ret
```

**Cómo funciona:** Es la función más compleja porque llama a otras funciones (`ft_strlen` y `malloc`), lo que destruye `RDI`. Por eso se guarda `RDI` en la pila con `push` antes de cada llamada. El flujo es:
1. Salvar `s` en la pila.
2. Llamar a `ft_strlen` → `RAX` = longitud.
3. `malloc(longitud + 1)` → `RAX` = bloque nuevo.
4. Recuperar `s` de la pila a `RSI`, guardar el bloque en la pila para poder devolverlo después.
5. Copiar byte a byte hasta `\0`.
6. `pop rax` devuelve el puntero al inicio del bloque.

En el manejador de error, `add rsp, 8` limpia el slot de la pila donde estaba guardado `RDI`, ya que no se puede hacer `pop` con ningún registro sin destruirlo.

---

## ft_write

**Prototipo:** `ssize_t ft_write(int fd, const void *buf, size_t count)`

Envuelve la syscall `write`. Si falla, pone el código de error en `errno` y devuelve `-1`.

```asm
ft_write:
    mov rax, 1      ; Número de syscall write en Linux x86-64
    syscall

    cmp rax, 0
    jl .error_handler   ; El kernel devuelve negativo en error

    ret

.error_handler:
    neg rax             ; Convierte el error negativo a positivo (código errno)

    push rax            ; Salva el código de error

    call __errno_location wrt ..plt   ; RAX = puntero a errno del hilo actual

    pop rdi
    mov [rax], edi      ; *errno = código de error

    mov rax, -1
    ret
```

**Cómo funciona:** Los argumentos ya llegan en los registros correctos (`RDI=fd`, `RSI=buf`, `RDX=count`) según la ABI, que coincide con la convención de syscalls de Linux. Se pone `1` en `RAX` (número de la syscall `write`) y se llama a `syscall`. Si el kernel devuelve un valor negativo, es un error: el valor negativo es `-errno`. Se niega para obtener el código positivo, se llama a `__errno_location` (que devuelve la dirección de la variable `errno` del hilo) y se escribe el código ahí. Finalmente se devuelve `-1`.

---

## ft_read

**Prototipo:** `ssize_t ft_read(int fd, void *buf, size_t count)`

Envuelve la syscall `read`. Manejo de errores idéntico al de `ft_write`.

```asm
ft_read:
    mov rax, 0      ; Número de syscall read en Linux x86-64
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
```

**Cómo funciona:** Idéntico a `ft_write` en estructura. La única diferencia es el número de syscall: `0` para `read` en lugar de `1`. Los argumentos (`fd`, `buf`, `count`) ya están en `RDI`, `RSI` y `RDX` por la ABI, que coincide con los argumentos de la syscall, por lo que no hay que mover nada antes del `syscall`. El manejo de `errno` es exactamente el mismo mecanismo.

---

## Compilación

```bash
make
```

Los archivos `.asm` se ensamblan con NASM en formato ELF64:

```bash
nasm -f elf64 src/ft_strlen.asm -o obj/ft_strlen.o
```
