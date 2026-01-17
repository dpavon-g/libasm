ASFLAGS = -f elf64 -g -F dwarf -w+all -w+error
# -f elf64	Lo uso para el formato estandar de ejecutables en linux (obligatorio para enlazar con GCC)
# -g 		Genera información de depuración (para GDB por ejemplo).
# -F dwarf	Es el formato mas común para depuración de GDB (debe usarse junto con -g).
# -w+all	Es el equivalente a -Wall en GCC, habilita todas las advertencias (Warnings)
# -w+error	Convierte todas las advertencias en errores. Si encuentra una advertencia, la compilación falla. 

EXECFLAGS = -z noexecstack

MAIN = testCode/main.c

AS = nasm

NAME = libasm.a
TESTNAME = testProgram

SRC = src/ft_strlen.asm \
	  src/ft_strcpy.asm \
	  src/ft_strncpy.asm \
	  src/ft_strcmp.asm \
	  src/ft_strncmp.asm \
	  src/ft_write.asm \
	  src/ft_read.asm \
	  src/ft_strdup.asm \
	  src/ft_atoi_base.asm \

OBJ = $(SRC:.asm=.o)

all: $(NAME)

$(NAME): $(OBJ)
	@ar rc $(NAME) $(OBJ)
	@echo "$(NAME) created"

%.o: %.asm
	$(AS) $(ASFLAGS) -o $@ $<

clean:
	@rm -f $(OBJ) $(TESTNAME)
	@echo "Objects and test program deleted"

fclean: clean
	@rm -f $(NAME)
	@echo "$(NAME) deleted"

test: $(TESTNAME)
	./$(TESTNAME)

$(TESTNAME): $(OBJ) $(MAIN)
	gcc $(EXECFLAGS) $(MAIN) $(OBJ) -o $(TESTNAME)

re: fclean all

.PHONY: all clean fclean re test
