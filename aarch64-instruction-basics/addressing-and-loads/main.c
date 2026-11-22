#include <stdint.h>
#include <stdio.h>

extern long long int test(void);
extern char *Lab02_3b(void);
extern long long int lab02_3d(long long int input);

int main(void)
{
	test();

    /* Question 11: the assembly changes only the fourth character. */
    char *message = Lab02_3b();
    printf("Question 11: %s\n", message);

    /* Question 12: turn the returned integer address into a pointer. */
    long long int input = 100;
    long long int address = lab02_3d(input);
    long long int *value_pointer = (long long int *)(uintptr_t)address;
    printf("Question 12: input = %lld, stored value = %lld\n",
           input, *value_pointer);
    return 0;
}
