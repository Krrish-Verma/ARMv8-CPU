/*
 * Lab03c.S
 *
 * C equivalent:
 *
 * long long int j = 4;
 *
 * for (i = 0; i < 10; i++) {
 *     my_array[i] = j + j;
 *     j++;
 * }
 */

.section .data
.balign 8

.global my_array
my_array:
    .space 80                  // Reserve 80 bytes.
                               // 10 quad words × 8 bytes = 80 bytes.

.section .text
.balign 4

.global lab03c
.type lab03c, %function

lab03c:
    /*
     * Register assignments:
     *
     * X0 = address of current my_array element
     * X1 = j
     * X2 = i
     * X3 = temporary value for i - 10
     * X4 = j + j
     * X30 = return address
     */

    ADR  X0, my_array          // X0 = address of my_array[0].

    MOVZ X1, #4                // j = 4, the first digit of my UIN.

    MOVZ X2, #0                // i = 0.

lab03c_loop:

    SUB  X3, X2, #10            // X3 = i - 10.

    CBZ  X3, lab03c_done        // If i - 10 == 0, exit the loop.
                                // Therefore, stop when i == 10.

    ADD  X4, X1, X1             // X4 = j + j.

    STUR X4, [X0, #0]           // my_array[i] = j + j.

    ADD  X1, X1, #1             // j++.

    ADD  X0, X0, #8             // Move to the next array element.
                                // Each quad word is 8 bytes.

    ADD  X2, X2, #1             // i++.

    B    lab03c_loop            // Repeat the loop.

lab03c_done:

    BR   X30                    // Return to the C caller.

.size lab03c, .-lab03c

.section .note.GNU-stack,"",@progbits