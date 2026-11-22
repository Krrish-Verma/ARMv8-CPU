.section .text
.balign 4
.globl lab02_3d
.type lab02_3d, %function

lab02_3d:
    ADD  X1, X0, 0xfe       // X0 is the argument; X1 = argument + 254.
    ADR  X0, myvalue        // X0 now holds the address to return.
    STUR X1, [X0, 0]       // Store the complete 64-bit result.
    BR   X30               // Return to main with the address in X0.
.size lab02_3d, .-lab02_3d

.section .data
.balign 8
.type myvalue, %object
myvalue: .quad 0
.size myvalue, 8

.section .note.GNU-stack,"",%progbits
