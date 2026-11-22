/* main.c program to test the recursive ARMv8 power function */

#include <stdio.h>

extern long long int power(long long int base, long long int exp);

int main(void)
{
    long long int base = 3;
    long long int exp = 5;
    long long int result = power(base, exp);

    printf("base = %lld, exp = %lld, result = %lld\n",
           base, exp, result);
    return 0;
}
