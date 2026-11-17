.section .data
.balign 8

.global UIN
UIN:
    .quad 30               // Initial value: sum of my UIN digits.

.section .text
.balign 4
.global lab03b
.type lab03b, %function

lab03b:
    // X0: address of UIN
    // X1: current UIN value
    // X2: loop index i
    // X3: temporary loop-condition value

    ADR  X0, UIN            // Get the address of UIN.
    LDUR X1, [X0, #0]       // Load its 64-bit value.
    MOVZ X2, #0             // i = 0.

lab03b_loop:
    SUB  X3, X2, #6         // Compare i with 6 by subtraction.
    CBZ  X3, lab03b_done    // Stop at i == 6; execute for i = 0..5.

    ADD  X1, X1, #1         // UIN = UIN + 1.
    STUR X1, [X0, #0]       // Save UIN back to memory.

    ADD  X2, X2, #1         // i++.
    B    lab03b_loop        // Repeat the condition check.

lab03b_done:
    BR   X30                // Return to main.

.size lab03b, .-lab03b
.section .note.GNU-stack,"",@progbits
