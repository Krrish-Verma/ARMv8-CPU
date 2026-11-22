#include <stdio.h>

extern long long int test(long long int a, long long int b);
extern void lab03b(void);
extern void lab03c(void);

extern long long int UIN;
extern long long int my_array[10];

int main(void)
{
    long long int a = test(3, 5);
    printf("Result of test(3, 5) = %lld\n", a);

    printf("UIN before loop = %lld\n", UIN);
    lab03b();
    printf("UIN after loop = %lld\n", UIN);

    lab03c();
    for (int i = 0; i < 10; i++) {
        printf("my_array[%d] = %lld\n", i, my_array[i]);
    }

    return 0;
}
