// main.c
#include <stdio.h>

extern int suma(int a, int b);

int main() {
    int resultado = suma(3, 4);
    printf("3 + 4 = %d\n", resultado);
    return 0;
}