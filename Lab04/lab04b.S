        .globl power

power:
        // X0 = base
        // X1 = exponent

        CBZ X1, power_base_case    // If exp == 0, return 1

        SUB SP, SP, 16             // Create this call's stack frame
        STUR X0, [SP, 0]           // Save this call's base
        STUR X30, [SP, 8]          // Save return address before using BL

        SUB X1, X1, 1              // Set exponent argument to exp - 1
        BL power                    // Recursively call power(base, exp - 1)

        ADD X1, X0, XZR            // X1 = result from recursive call
        LDUR X0, [SP, 0]           // X0 = saved base
        BL my_mul                   // Calculate base * recursive result

        LDUR X30, [SP, 8]          // Restore this call's return address
        ADD SP, SP, 16             // Remove this call's stack frame
        BR X30                     // Return the result in X0

power_base_case:
        ADD X0, XZR, XZR           // Set X0 to 0
        ADD X0, X0, 1              // Set X0 to 1
        BR X30                     // Return 1