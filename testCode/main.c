#include "../includes/libasm.h"

int main(int argc, char **argv) {
    char texto[] = "00000000";
    const char *texto2 = "11111111";
    const char *texto3 = "22222222";

    printf("Cadena original: %s\n", texto);
    printf("Cadena texto2: %s\n", texto2);
    printf("Cadena texto3: %s\n", texto3);

    int longitud = ft_strlen(texto);
    printf("ft_strlen | La longitud de la cadena es: %d\n", longitud);
    
    char *dest = ft_strcpy(texto, texto2);
    printf("Después de ft_strcpy, el primer string es: %s\n", dest);

    char *dest2 = ft_strncpy(texto, texto3, longitud + 1);
    printf("Después de ft_strncpy, el primer string es: %s\n", dest2);

    int cmp_result = ft_strcmp(texto2, texto3);
    printf("Resultado de ft_strcmp entre texto2 y texto3: %d\n", cmp_result);

    int cmp_result2 = ft_strcmp(texto3, texto2);
    printf("Resultado de ft_strcmp entre texto3 y texto2: %d\n", cmp_result2);

    int cmp_result3 = ft_strcmp(texto2, texto2);
    printf("Resultado de ft_strcmp entre texto2 y texto2: %d\n", cmp_result3);

    return 0;
}