#include "../includes/libasm.h"

int main(int argc, char **argv) {
    char texto[] = "00000000";
    const char *texto2 = "111111111";
    const char *texto3 = "122222222";

    printf("Cadena original: %s\n", texto);
    printf("Cadena texto2: %s\n", texto2);
    printf("Cadena texto3: %s\n", texto3);

    int longitud = ft_strlen(texto);
    printf("ft_strlen | La longitud de la cadena es: %d\n", longitud);
    
    char *dest = ft_strcpy(texto, texto2);
    printf("Después de ft_strcpy, el primer string es: %s\n", dest);

    char *dest2 = ft_strncpy(texto, texto3, longitud + 1);
    printf("Después de ft_strncpy, el primer string es: %s\n", dest2);

    printf("Cadena texto2: %s\n", texto2);
    printf("Cadena texto3: %s\n", texto3);

    int cmp_result = ft_strcmp(texto2, texto3);
    printf("Resultado de ft_strcmp entre texto2 y texto3: %d\n", cmp_result);

    cmp_result = ft_strcmp(texto3, texto2);
    printf("Resultado de ft_strcmp entre texto3 y texto2: %d\n", cmp_result);

    cmp_result = ft_strcmp(texto2, texto2);
    printf("Resultado de ft_strcmp entre texto2 y texto2: %d\n", cmp_result);

    int ncmp_result = ft_strncmp(texto2, texto3, 1);
    printf("Resultado de ft_strncmp unchar entre texto2 y texto3: %d\n", ncmp_result);

    ncmp_result = ft_strncmp(texto3, texto2, 1);
    printf("Resultado de ft_strncmp un char entre texto3 y texto2: %d\n", ncmp_result);

    ncmp_result = ft_strncmp(texto2, texto2, 1);
    printf("Resultado de ft_strncmp un char entre texto2 y texto2: %d\n", ncmp_result);

    ssize_t write_result = ft_write(1, "Hello, world!\n", 14);
    printf("Resultado de ft_write: %zd\n", write_result);

    ssize_t read_result;
    char buffer[20];
    ft_write(1, "Please enter some text: ", 24);
    read_result = ft_read(0, buffer, 19);
    if (read_result >= 0) {
        buffer[read_result] = '\0';
        printf("You entered: %s", buffer);
    } else {
        printf("Error reading input.\n");
    }

    char *strdup_result = ft_strdup(buffer);
    printf("Resultado de ft_strdup: %s\n", strdup_result);


    int atoi_base_result = ft_atoi_base("Hz", "123");
    printf("Resultado de atoi_base: %d\n", atoi_base_result);

    return 0;
}