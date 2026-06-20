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

## ft_atoi_base

**Prototipo:** `int ft_atoi_base(const char *str, const char *base)`

Convierte la cadena `str` a un entero usando la base indicada por `base`. Por ejemplo, con `base = "0123456789"` se comporta como `atoi`; con `base = "01"` interpreta la cadena como binario. Devuelve `0` si la base es inválida.

```asm
ft_atoi_base:

    .comprobar_longitud_base:
        push rdi                    ; Salva str: RDI se va a sobrescribir
        mov rdi, rsi                ; RDI = base (argumento de ft_strlen)
        call ft_strlen              ; RAX = longitud de base
        cmp rax, 1
        jbe .retornar_cero          ; Base de longitud <= 1 es inválida
        mov r10, rax                ; R10 = longitud de base (el "divisor" de posición)
        jmp .buscar_invalid_chars

    .buscar_invalid_chars:
        mov rdi, rsi                ; RDI = base (para iterar con índice)
        mov rax, 0                  ; RAX = índice dentro de base

        .next_char:
            cmp byte [rdi + rax], 0
            je .check_espacios      ; Fin de base sin errores: pasar a parsear str

            mov cl, byte [rdi + rax]
            cmp cl, ' '
                je .retornar_cero   ; Espacio inválido en base
            cmp cl, 43
                je .retornar_cero   ; '+' inválido en base
            cmp cl, 45
                je .retornar_cero   ; '-' inválido en base
            cmp cl, 9
                jb .comprobar_duplicado
            cmp cl, 13
                jbe .retornar_cero  ; Whitespace de control (tab, LF, VT, FF, CR)

            jmp .comprobar_duplicado

            .siguiente_char:
                inc rax
                jmp .next_char

    .comprobar_duplicado:
        push rax                    ; Salva posición actual
        .incrementar_busqueda_duplicado:
            inc rax
            cmp byte [rdi + rax], 0
                je .fin_comprobar_duplicado
            cmp cl, byte [rdi + rax]
                jne .incrementar_busqueda_duplicado
            pop rax
            jmp .retornar_cero      ; Char repetido en base: inválida

            .fin_comprobar_duplicado:
                pop rax
                jmp .siguiente_char

    .check_espacios:
        pop rdi                     ; Restaura str (el que se salvó al inicio)
        mov rax, -1

        .move_for_spaces:
            inc rax
            mov cl, byte[rdi + rax]
            cmp cl, ' '
                je .move_for_spaces
            cmp cl, 9
                je .move_for_spaces
            cmp cl, 10
                je .move_for_spaces
            cmp cl, 11
                je .move_for_spaces
            cmp cl, 12
                je .move_for_spaces
            cmp cl, 13
                je .move_for_spaces
            cmp cl, 0
                je .termina_sin_numero

    .check_signos:
        dec rax
        mov r9b, 1                  ; R9B = signo: 1 positivo, -1 negativo

        .move_for_signos:
            inc rax
            mov cl, byte[rdi + rax]
            cmp cl, 0
                je .termina_sin_numero
            cmp cl, '+'
                je .move_for_signos
            cmp cl, '-'
                jne .empezar_conversion_matematica
            neg r9b                 ; Alterna el signo (1 -> -1 -> 1 -> ...)
            jmp .move_for_signos

    .empezar_conversion_matematica:
        mov r8, 0                   ; R8 = acumulador del resultado
        mov r15, 0                  ; R15 = índice dentro de base

        .aumentar_puntero_base:
            cmp byte[rsi + r15], 0
            je .termina_sin_numero  ; Char de str no encontrado en base: parar
            cmp cl, byte[rsi + r15]
            je .add_numero
            .continuar_bucle:
                inc r15
                jmp .aumentar_puntero_base

            .siguiente_numero:
                inc rax
                mov cl, byte[rdi + rax]
                cmp cl, 0
                je .terminar_recorrido
                jmp .aumentar_puntero_base

    .add_numero:
        imul r8, r10                ; resultado = resultado * longitud_base
        add r8, r15                 ; resultado += valor_del_digito (posición en base)
        mov r15, 0
        jmp .siguiente_numero

    .terminar_recorrido:
        cmp r9b, -1
        jne .salir
        neg r8                      ; Aplica el signo negativo
        .salir:
            mov rax, r8
            ret

    .termina_sin_numero:
        xor rax, rax
        ret

    .retornar_cero:
        xor rax, rax
        pop rdi
        ret
```

**Cómo funciona:**

La función tiene cuatro fases bien diferenciadas:

**Fase 1 — Validación de la base (`.comprobar_longitud_base` y `.buscar_invalid_chars`)**

Antes de hacer nada con `str`, se valida que `base` sea legal. Primero se comprueba que tenga al menos 2 caracteres (una base de longitud 0 o 1 no tiene sentido matemático). La longitud se guarda en `R10` porque se necesitará después como multiplicador en la conversión.

Luego se recorre `base` carácter a carácter buscando caracteres prohibidos: espacio (32), `+` (43), `-` (45) y los caracteres de control de whitespace del rango 9–13 (tab, LF, VT, FF, CR). Cualquiera de ellos hace que la base sea inválida. Para cada carácter que pasa ese filtro, `.comprobar_duplicado` comprueba que no aparezca más adelante en la misma cadena, porque una base con dígitos repetidos es ambigua.

El `push rdi` al inicio es imprescindible: como se llama a `ft_strlen` pasando `RSI` (la base) como argumento, hay que sobreescribir `RDI`, pero `RDI` contiene `str` y se necesita después. Se restaura en `pop rdi` cuando empieza la fase de parseo.

**Fase 2 — Saltar espacios iniciales (`.check_espacios`)**

Una vez validada la base, se avanza el índice sobre `str` saltando todos los caracteres de espacio en blanco al inicio (32, 9–13). El truco de empezar `RAX` en `-1` y hacer `inc rax` al inicio del bucle en lugar de al final evita tener que duplicar la lógica para leer el primer carácter.

**Fase 3 — Procesar signos (`.check_signos`)**

`R9B` (el byte bajo de `R9`) actúa como bandera de signo, inicializada a `1`. Cada vez que se encuentra un `+` se ignora; cada vez que se encuentra un `-` se hace `neg r9b`, que alterna entre `1` y `-1` en complemento a dos. Así se gestiona correctamente la secuencia `"--123"` (resultado positivo) o `"+-123"` (resultado negativo).

**Fase 4 — Conversión (`.empezar_conversion_matematica` y `.add_numero`)**

El algoritmo es el clásico de Horner: para cada dígito se hace `resultado = resultado * base + valor_del_dígito`. El valor de un dígito es su posición dentro de la cadena `base` (almacenada en `R15`), porque `base[0]` representa el `0`, `base[1]` el `1`, etc. La longitud de la base (en `R10`) es el multiplicador.

Cuando el carácter actual de `str` no se encuentra en ninguna posición de `base`, se detiene la conversión (un carácter que no es un dígito válido termina el número, como hace `atoi` con los no-numéricos).

Al terminar, si `R9B` vale `-1` se niega el acumulador `R8` y se copia a `RAX` para retornar.

**Por qué esos registros:**

| Registro | Rol en esta función | Motivo de la elección |
|----------|---------------------|-----------------------|
| `RDI` | Puntero a `str` | Es el primer argumento por ABI; se salva en pila antes de llamar a `ft_strlen` |
| `RSI` | Puntero a `base` | Segundo argumento por ABI; nunca se modifica (referencia constante durante toda la función) |
| `RAX` | Índice de iteración / retorno | Se usa como índice mientras no hay valor de retorno; al final recibe el resultado de `R8` |
| `CL` | Byte del carácter actual | Registro de 8 bits de `RCX`; carga un solo byte sin necesidad de extensión para comparaciones |
| `R8` | Acumulador del resultado | Registro volátil de propósito general; libre al no ser argumento ni retorno, aguanta el valor de 64 bits del resultado |
| `R9B` | Bandera de signo (1 / -1) | El byte bajo de `R9` basta para guardar el signo; `neg r9b` lo alterna en complemento a dos |
| `R10` | Longitud de la base | Se calcula una sola vez y se reutiliza como multiplicador en cada iteración de Horner |
| `R15` | Índice dentro de `base` | Necesario en paralelo con `RAX` (que itera `str`); al ser un registro callee-saved en System V no interfiere con las llamadas internas |

---

## Compilación

```bash
make
```

Los archivos `.asm` se ensamblan con NASM en formato ELF64:

```bash
nasm -f elf64 src/ft_strlen.asm -o obj/ft_strlen.o
```
