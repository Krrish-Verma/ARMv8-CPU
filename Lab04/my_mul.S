        .globl my_mul                 // Make my_mul available to main.c

my_mul:
        // X0 = first number
        // X1 = second number

        SUB SP, SP, 16                // Reserve 16 bytes on the stack
        STUR X19, [SP, 0]             // Save the original X19
        ADD X19, X1, XZR              // Copy X1 into X19 as the loop counter
        ADD X9, XZR, XZR              // Set the result X9 to 0

mult_loop:
        CBZ X19, mult_eol             // Exit the loop when X19 reaches 0
        ADD X9, X9, X0                // Add X0 to the result
        SUB X19, X19, 1               // Decrease the loop counter
        B mult_loop                   // Repeat the loop

mult_eol:
        LDUR X19, [SP, 0]             // Restore the original X19

        ADD SP, SP, 16                // FIX: Restore SP by releasing 16 bytes

        ADD X0, X9, XZR               // Copy the result into return register X0
        BR X30                        // Return to main