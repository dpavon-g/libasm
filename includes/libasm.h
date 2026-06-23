#ifndef LIBASM_H
# define LIBASM_H

#include <stdio.h>
#include <sys/types.h>

typedef struct s_list
{
    void            *data;
    struct s_list   *next;
}                   t_list;

int ft_strlen(const char *str);
char *ft_strcpy(char *dest, const char *src);
char *ft_strncpy(char *dest, const char *src, size_t n);
int ft_strcmp(const char *s1, const char *s2);
int ft_strncmp(const char *s1, const char *s2, size_t n);
ssize_t ft_write(int fd, const void *buf, size_t count);
ssize_t ft_read(int fd, void *buf, size_t count);
char *ft_strdup(const char *s);
int ft_atoi_base(char *str, char *base);
void ft_list_push_front(t_list **begin_list, void *data);
int ft_list_size(t_list *begin_list);

#endif