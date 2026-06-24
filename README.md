# libasm

> Reimplementación de funciones de la libc y listas enlazadas en ensamblador **x86-64** (NASM).

---

## Índice

- [Compilación](#compilación)
- [Convención de registros](#convención-de-registros)
- [Estructura t\_list](#estructura-t_list)
- [Funciones de cadena](#funciones-de-cadena)
  - [ft\_strlen](#ft_strlen)
  - [ft\_strcmp](#ft_strcmp)
  - [ft\_strncmp](#ft_strncmp)
  - [ft\_strcpy](#ft_strcpy)
  - [ft\_strncpy](#ft_strncpy-1)
  - [ft\_strdup](#ft_strdup)
- [Funciones de conversión](#funciones-de-conversión)
  - [ft\_atoi\_base](#ft_atoi_base)
- [Syscalls](#syscalls)
  - [ft\_write](#ft_write)
  - [ft\_read](#ft_read)
- [Listas enlazadas](#listas-enlazadas)
  - [ft\_list\_push\_front](#ft_list_push_front)
  - [ft\_list\_size](#ft_list_size)
  - [ft\_list\_sort](#ft_list_sort)

---

## Compilación

```bash
make
```

Los archivos `.asm` se ensamblan con NASM en formato ELF64:

```bash
nasm -f elf64 src/ft_strlen.asm -o obj/ft_strlen.o
```

---

## Convención de registros

La ABI System V AMD64 define cómo se pasan argumentos y valores de retorno entre funciones:

| Registro | Rol |
|----------|-----|
| `RDI` | 1.er argumento |
| `RSI` | 2.º argumento |
| `RDX` | 3.er argumento |
| `RCX`, `R8`, `R9` | 4.º–6.º argumento |
| `RAX` | Valor de retorno |
| `RCX`, `R8`–`R11` | Volátiles — una llamada los puede destruir |
| `RBX`, `R12`–`R15`, `RBP` | No volátiles — hay que preservarlos si se usan |

> **Regla de oro:** si una función llama a otra (`call`), cualquier valor en registros volátiles se pierde. Hay que guardarlos en la pila (`push`) antes y restaurarlos (`pop`) después.

---

## Estructura t\_list

Las funciones de lista trabajan sobre esta estructura definida en `includes/libasm.h`:

```c
typedef struct s_list
{
    void            *data;   /* puntero al dato (offset +0) */
    struct s_list   *next;   /* puntero al siguiente nodo  (offset +8) */
}   t_list;
```

Cada nodo ocupa exactamente **16 bytes** (dos punteros de 8 bytes). En ensamblador, `[nodo]` accede a `data` y `[nodo + 8]` accede a `next`.

---

## Funciones de cadena

---

### ft\_strlen

**Prototipo:** `size_t ft_strlen(const char *s)`

Calcula la longitud de una cadena contando bytes hasta encontrar el carácter nulo `\0`.

```asm
ft_strlen:
    mov rax, 0                     ; RAX = contador, empieza en 0

.next_char:
    cmp byte [rdi + rax], 0        ; ¿s[RAX] == '\0'?
    je .done

    inc rax
    jmp .next_char

.done:
    ret                            ; RAX = longitud
```

En lugar de mover el puntero `RDI`, se usa `RAX` como índice. Cuando el byte comparado es `0`, `RAX` ya contiene la longitud y se devuelve directamente, sin ninguna operación extra.

---

### ft\_strcmp

**Prototipo:** `int ft_strcmp(const char *s1, const char *s2)`

Compara dos cadenas carácter a carácter. Devuelve la diferencia del primer par de bytes distintos, o `0` si son iguales.

```asm
ft_strcmp:
    xor rax, rax                   ; Limpia RAX (y AL)

.next_char:
    mov al, [rdi]                  ; AL = byte actual de s1
    mov cl, [rsi]                  ; CL = byte actual de s2

    cmp al, cl
    jne .done                      ; Bytes distintos → calcular diferencia

    test al, al
    jz .done                       ; Ambos '\0' → iguales

    inc rdi
    inc rsi
    jmp .next_char

.done:
    movzx eax, al                  ; Extiende AL a EAX sin signo
    movzx ecx, cl
    sub eax, ecx                   ; Devuelve s1[i] - s2[i]
    ret
```

El `movzx` antes del `sub` es imprescindible: convierte los bytes a enteros de 32 bits **sin signo** para que la resta sea correcta. Sin él, un carácter como `'\xFF'` se trataría como `-1` y la diferencia sería errónea.

---

### ft\_strncmp

**Prototipo:** `int ft_strncmp(const char *s1, const char *s2, size_t n)`

Compara hasta `n` caracteres de dos cadenas.

```asm
ft_strncmp:
    xor rax, rax
    test rdx, rdx
    jz .done_equals                ; n == 0 → iguales por definición

.next_char:
    mov al, [rdi]
    mov cl, [rsi]

    cmp al, cl
    jne .done                      ; Bytes distintos

    test al, al
    jz .done_equals                ; Ambos '\0'

    inc rdi
    inc rsi
    dec rdx
    test rdx, rdx
    jz .done_equals                ; Se compararon n bytes sin diferencia

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

Combina la lógica de `ft_strcmp` con el contador `n`. Tiene dos etiquetas de salida separadas: `.done` cuando los bytes difieren (devuelve la diferencia) y `.done_equals` cuando se llega a `n` o a `\0` simultáneo (devuelve `0`).

---

### ft\_strcpy

**Prototipo:** `char *ft_strcpy(char *dest, const char *src)`

Copia la cadena `src` en `dest`, incluyendo el `\0` final. Devuelve `dest`.

```asm
ft_strcpy:
    mov rax, rdi                   ; Guarda dest en RAX para devolverlo

.next_char:
    mov cl, [rsi]                  ; CL = byte actual de src
    mov [rdi], cl                  ; Lo escribe en dest

    test cl, cl
    jz .done                       ; Si era '\0', terminamos

    inc rsi
    inc rdi
    jmp .next_char

.done:
    ret                            ; RAX = puntero original a dest
```

`RDI` se salva en `RAX` al principio porque `RDI` se va a incrementar durante la copia, pero la función debe devolver el puntero **original** al destino. El `\0` también se copia: la comprobación ocurre *después* de escribirlo.

---

### ft\_strncpy

**Prototipo:** `char *ft_strncpy(char *dest, const char *src, size_t n)`

Copia hasta `n` bytes de `src` en `dest`. Se detiene antes si encuentra `\0`.

```asm
ft_strncpy:
    mov rax, rdi                   ; Guarda dest en RAX

.next_char:
    test rdx, rdx
    jz .done                       ; n == 0 → terminamos

    mov cl, [rsi]
    mov [rdi], cl

    test cl, cl
    jz .done                       ; Byte '\0' copiado → terminamos

    inc rsi
    inc rdi
    dec rdx
    jmp .next_char

.done:
    ret
```

Igual que `ft_strcpy` pero con el tercer argumento `RDX` como contador descendente. Hay dos condiciones de salida: `RDX` llega a `0` (máximo alcanzado) o se copia un `\0` (fin de cadena). A diferencia de la versión de la libc, esta implementación **no rellena** el resto con ceros cuando `src` es más corta que `n`.

---

### ft\_strdup

**Prototipo:** `char *ft_strdup(const char *s)`

Duplica una cadena reservando memoria dinámica. Devuelve el puntero a la copia, o `NULL` si falla `malloc`.

```asm
ft_strdup:
    push rdi                       ; Salva s (RDI se perderá en las llamadas)

    call ft_strlen                 ; RAX = longitud de s

    mov rdi, rax
    inc rdi                        ; RDI = longitud + 1 (espacio para '\0')
    call malloc WRT ..plt          ; RAX = bloque reservado

    test rax, rax
    jz .error_handler

    mov rdi, rax                   ; RDI = destino
    pop rsi                        ; RSI = s original (de la pila)
    push rax                       ; Salva el puntero destino para devolverlo

.copy_string:
    mov al, [rsi]
    mov [rdi], al
    test al, al
    jz .end
    inc rdi
    inc rsi
    jmp .copy_string

.end:
    pop rax                        ; Recupera el puntero al inicio del bloque
    ret

.error_handler:
    add rsp, 8                     ; Descarta el RDI que quedó en pila
    xor rax, rax                   ; Devuelve NULL
    ret
```

Es la función más compleja porque llama a `ft_strlen` y `malloc`, ambas destruyen `RDI`. El flujo es:

1. `push rdi` — salva `s`.
2. `ft_strlen` → `RAX` = longitud.
3. `malloc(longitud + 1)` → `RAX` = bloque nuevo.
4. `pop rsi` — recupera `s` al segundo argumento; `push rax` — salva el bloque.
5. Copia byte a byte hasta `\0`.
6. `pop rax` — devuelve el puntero al inicio del bloque.

En el manejador de error, `add rsp, 8` limpia el slot de la pila donde estaba `RDI` sin necesidad de hacer un `pop` que sobreescribiría un registro.

---

## Funciones de conversión

---

### ft\_atoi\_base

**Prototipo:** `int ft_atoi_base(const char *str, const char *base)`

Convierte `str` a entero usando la base indicada por `base`. Con `base = "0123456789"` se comporta como `atoi`; con `base = "01"` interpreta la cadena como binario. Devuelve `0` si la base es inválida.

```asm
ft_atoi_base:

    .comprobar_longitud_base:
        push rdi                    ; Salva str antes de sobrescribir RDI
        mov rdi, rsi
        call ft_strlen              ; RAX = longitud de base
        cmp rax, 1
        jbe .retornar_cero          ; Base de longitud <= 1 → inválida
        mov r10, rax                ; R10 = longitud de base (multiplicador de Horner)
        jmp .buscar_invalid_chars

    .buscar_invalid_chars:
        mov rdi, rsi
        mov rax, 0

        .next_char:
            cmp byte [rdi + rax], 0
            je .check_espacios      ; Base válida → parsear str

            mov cl, byte [rdi + rax]
            cmp cl, ' '
                je .retornar_cero
            cmp cl, 43
                je .retornar_cero   ; '+'
            cmp cl, 45
                je .retornar_cero   ; '-'
            cmp cl, 9
                jb .comprobar_duplicado
            cmp cl, 13
                jbe .retornar_cero  ; tab, LF, VT, FF, CR

            jmp .comprobar_duplicado

            .siguiente_char:
                inc rax
                jmp .next_char

    .comprobar_duplicado:
        push rax
        .incrementar_busqueda_duplicado:
            inc rax
            cmp byte [rdi + rax], 0
                je .fin_comprobar_duplicado
            cmp cl, byte [rdi + rax]
                jne .incrementar_busqueda_duplicado
            pop rax
            jmp .retornar_cero      ; Dígito repetido → base inválida

            .fin_comprobar_duplicado:
                pop rax
                jmp .siguiente_char

    .check_espacios:
        pop rdi                     ; Restaura str
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
        mov r9b, 1                  ; Signo: 1 = positivo

        .move_for_signos:
            inc rax
            mov cl, byte[rdi + rax]
            cmp cl, 0
                je .termina_sin_numero
            cmp cl, '+'
                je .move_for_signos
            cmp cl, '-'
                jne .empezar_conversion_matematica
            neg r9b                 ; Alterna 1 ↔ -1
            jmp .move_for_signos

    .empezar_conversion_matematica:
        mov r8, 0                   ; R8 = acumulador
        mov r15, 0                  ; R15 = índice dentro de base

        .aumentar_puntero_base:
            cmp byte[rsi + r15], 0
            je .termina_sin_numero  ; Carácter no encontrado en base
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
        add r8, r15                 ; resultado += valor_del_dígito
        mov r15, 0
        jmp .siguiente_numero

    .terminar_recorrido:
        cmp r9b, -1
        jne .salir
        neg r8
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

La función tiene cuatro fases bien diferenciadas:

**Fase 1 — Validación de la base**

Se verifica que `base` tenga al menos 2 caracteres y que ninguno de ellos sea un carácter prohibido: espacio (32), `+` (43), `-` (45) y los caracteres de control del rango 9–13 (tab, LF, VT, FF, CR). También se detectan dígitos repetidos, que harían la base ambigua. La longitud de la base se guarda en `R10` porque se reutilizará como multiplicador.

**Fase 2 — Saltar espacios iniciales**

Se avanza el índice sobre `str` ignorando todos los blancos iniciales. El truco de iniciar `RAX` en `-1` y hacer `inc rax` al principio del bucle evita duplicar la lectura del primer carácter.

**Fase 3 — Procesar signos**

`R9B` (byte bajo de `R9`) actúa como bandera de signo, inicializada a `1`. Cada `-` encontrado ejecuta `neg r9b`, alternando entre `1` y `-1`. Así `"--123"` resulta positivo y `"+-123"` negativo.

**Fase 4 — Conversión (algoritmo de Horner)**

Para cada dígito: `resultado = resultado * longitud_base + posición_del_dígito_en_base`. El valor de un dígito es su índice dentro de `base` (guardado en `R15`). Un carácter de `str` que no aparece en `base` termina la conversión, igual que `atoi` con los no-numéricos.

| Registro | Rol |
|----------|-----|
| `RDI` | Puntero a `str` |
| `RSI` | Puntero a `base` (constante durante toda la función) |
| `RAX` | Índice de iteración / valor de retorno |
| `CL` | Byte del carácter actual |
| `R8` | Acumulador del resultado |
| `R9B` | Bandera de signo (1 / -1) |
| `R10` | Longitud de base (multiplicador de Horner) |
| `R15` | Índice dentro de `base` |

---

## Syscalls

---

### ft\_write

**Prototipo:** `ssize_t ft_write(int fd, const void *buf, size_t count)`

Envuelve la syscall `write`. Si falla, escribe el código de error en `errno` y devuelve `-1`.

```asm
ft_write:
    mov rax, 1              ; Número de syscall write en Linux x86-64
    syscall

    cmp rax, 0
    jl .error_handler

    ret

.error_handler:
    neg rax                 ; El kernel devuelve -errno; negamos para obtener el código

    push rax
    call __errno_location wrt ..plt    ; RAX = dirección de errno del hilo actual
    pop rdi
    mov [rax], edi          ; *errno = código de error

    mov rax, -1
    ret
```

Los argumentos (`fd`, `buf`, `count`) ya llegan en `RDI`, `RSI` y `RDX` por la ABI, que coincide exactamente con los registros de la syscall de Linux. Solo hay que poner el número de syscall (`1`) en `RAX` y ejecutar `syscall`. Si el resultado es negativo, el kernel está devolviendo `-errno`: se niega para obtener el código positivo, se llama a `__errno_location` (que devuelve la dirección de la variable `errno` del hilo actual) y se escribe el código ahí.

---

### ft\_read

**Prototipo:** `ssize_t ft_read(int fd, void *buf, size_t count)`

Envuelve la syscall `read`. Manejo de errores idéntico al de `ft_write`.

```asm
ft_read:
    mov rax, 0              ; Número de syscall read en Linux x86-64
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

Idéntico a `ft_write` en estructura. La única diferencia es el número de syscall: `0` para `read` en lugar de `1`. El mecanismo de `errno` es exactamente el mismo.

---

## Listas enlazadas

Las tres funciones siguientes trabajan con la estructura `t_list`. En memoria, cada nodo tiene el campo `data` en el offset `+0` y el campo `next` en el offset `+8`.

---

### ft\_list\_push\_front

**Prototipo:** `void ft_list_push_front(t_list **begin_list, void *data)`

Crea un nuevo nodo con `data` y lo inserta al principio de la lista actualizando `*begin_list`.

```asm
ft_list_push_front:
    cmp rdi, 0
    je .end_function               ; begin_list == NULL → no hacer nada

    push rbp
    mov rbp, rsp

    push rdi                       ; Salva begin_list (RDI se perderá en malloc)
    push rsi                       ; Salva data

    mov rdi, 16
    call malloc WRT ..plt          ; Reserva 16 bytes (data + next)

    pop rsi                        ; Restaura data
    pop rdi                        ; Restaura begin_list

    mov rsp, rbp
    pop rbp

    cmp rax, 0
    je .end_function               ; malloc falló → no hacer nada

    mov [rax], rsi                 ; nodo->data = data
    mov rdx, [rdi]                 ; RDX = *begin_list (antiguo primer nodo)
    mov [rax + 8], rdx             ; nodo->next = antiguo primer nodo
    mov [rdi], rax                 ; *begin_list = nuevo nodo

.end_function:
    ret
```

El nodo nuevo se crea con `malloc(16)`. Después de la llamada, `RAX` apunta al bloque. Se escribe `data` en el offset `+0` y el antiguo primer nodo (`*begin_list`) en el offset `+8`. Finalmente se actualiza `*begin_list` para que apunte al nodo nuevo. El `push`/`pop` de `RDI` y `RSI` es necesario porque `malloc` es una llamada externa que puede destruir los registros volátiles.

```
Antes:          begin_list ──► [nodo_A | nodo_B]

Después:        begin_list ──► [nuevo | nodo_A | nodo_B]
                                 ↑
                              data = data pasado
```

---

### ft\_list\_size

**Prototipo:** `int ft_list_size(t_list *begin_list)`

Devuelve el número de nodos de la lista.

```asm
ft_list_size:
    mov rax, 0                     ; Contador = 0

.bucle:
    cmp rdi, 0
    je .finish                     ; Nodo NULL → fin de lista

    inc rax                        ; Cuenta el nodo actual
    mov rdi, [rdi + 8]             ; RDI = nodo->next
    jmp .bucle

.finish:
    ret                            ; RAX = número de nodos
```

Recorre la lista siguiendo los punteros `next` (offset `+8`) e incrementa el contador en cada nodo. Cuando `RDI` es `NULL` (fin de lista), `RAX` contiene el total y se devuelve. Es la función más sencilla del proyecto.

---

### ft\_list\_sort

**Prototipo:** `void ft_list_sort(t_list **begin_list, int (*cmp)())`

Ordena la lista usando la función de comparación `cmp`. La función `cmp` debe devolver un valor negativo si el primer argumento va antes que el segundo, o un valor `>= 0` si hay que intercambiarlos.

```asm
ft_list_sort:
    cmp rdi, 0
    je .final                      ; begin_list == NULL → no hacer nada

    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13                       ; Preserva registros no volátiles

    mov r13, rsi                   ; R13 = función de comparación
    mov rbx, [rdi]                 ; RBX = primer nodo (*begin_list)
    cmp rbx, 0
    je .restore_exit

.recorrer_bucle:
    cmp rbx, 0
    je .restore_exit

    mov r12, [rbx + 8]             ; R12 = nodo siguiente a RBX

    .comparar_nodos:
        cmp r12, 0
        je .avanzar_nodo1          ; Fin de la sub-lista → avanzar nodo exterior

        mov rdi, [rbx]             ; RDI = rbx->data
        mov rsi, [r12]             ; RSI = r12->data
        call r13                   ; cmp(rbx->data, r12->data)

        cmp eax, 0
        jge .hacer_swap            ; cmp >= 0 → intercambiar datos

        mov r12, [r12 + 8]         ; Avanza R12 solo si no hubo swap
        jmp .comparar_nodos

    .hacer_swap:
        mov r8, [rbx]              ; Guarda rbx->data
        mov r9, [r12]              ; Guarda r12->data
        mov [rbx], r9              ; rbx->data = r12->data
        mov [r12], r8              ; r12->data = rbx->data
                                   ; (cae en avanzar_nodo1)

    .avanzar_nodo1:
        mov rbx, [rbx + 8]        ; Avanza RBX al siguiente nodo
        jmp .recorrer_bucle

.restore_exit:
    pop r13
    pop r12
    pop rbx
    mov rsp, rbp
    pop rbp

.final:
    ret
```

El algoritmo usa dos punteros: `RBX` como nodo exterior y `R12` como nodo interior que avanza desde `RBX->next`. Para cada par, llama a `cmp(rbx->data, r12->data)` y, si el resultado es `>= 0`, **intercambia los campos `data`** de los dos nodos (no los propios nodos, que permanecen en su posición en memoria). Después de un intercambio, el nodo exterior avanza directamente sin continuar la exploración interior.

Los registros `RBX`, `R12` y `R13` son **no volátiles** según la ABI, por lo que se preservan con `push`/`pop` alrededor de toda la lógica. `R13` guarda el puntero a la función de comparación para que `call r13` no interfiera con los registros de argumento.

| Registro | Rol |
|----------|-----|
| `RBX` | Nodo exterior (bucle principal) |
| `R12` | Nodo interior (sub-bucle de comparación) |
| `R13` | Puntero a la función `cmp` |
| `R8`, `R9` | Valores temporales durante el intercambio |
