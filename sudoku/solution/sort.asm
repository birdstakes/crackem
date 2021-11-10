#include "vm.asm"

; inputs:
; r0 = A
; r1 = len(A)

minus r3
add r1, r3

; i = r2, which is already 0
; while i < len(A)
outer_loop:
    ; r4 = -r1
    plus r3
    not r4, r1
    add r4, r3

    ; r3 = r2 - r1 = i - len(A)
    mov r3, r2
    add r3, r4

    ; r3 = r3 < 0
    ld r4, pc
    #d9 255
    not r4, r4
    and r3, r4

    ; if false we're done
    ld r4, pc
    #d9 3 ; this will be interpreted as `and r0, r0`, a nop
    add r4, pc
    nz r3, r3
    add r4, r3
    ld pc, r4
    #d9 hlt, l1
l1:
    ; j (r3) = i
    mov r3, r2

; while j > 0 and A[j] > A[j+1]
inner_loop:
    ; break if j == -1
    mov r5, r3
    plus r6
    add r5, r6

    ld r4, pc
    #d9 3
    add r4, pc
    nz r5, r5
    add r4, r5
    ld pc, r4
    #d9 break_inner_loop, l2
l2:
    ; r5 = A[j]
    mov r4, r0
    add r4, r3
    ld r5, r4

    ; r6 = A[j+1]
    plus r6
    add r4, r6
    ld r6, r4

    ; r5 -= r6
    plus r4
    not r6, r6
    add r6, r4
    add r5, r6

    ; r5 = r5 < 0 = A[j] - A[j+1] < 0 = A[j] < A[j+1]
    ld r4, pc
    #d9 255
    not r4, r4
    and r5, r4

    ; break if A[j] < A[j+1]
    ld r4, pc
    #d9 3
    add r4, pc
    nz r5, r5
    add r4, r5
    ld pc, r4
    #d9 l3, break_inner_loop

l3:
    ; swap A[j] and A[j+1]

    ; r5 = A[j]
    mov r4, r0
    add r4, r3
    ld r5, r4

    ; r6 = A[j+1]
    plus r6
    add r4, r6
    ld r6, r4

    ; A[j+1] = r5
    str r4, r5

    ; A[j] = r6
    minus r5
    add r4, r5
    str r4, r6

    ; j = j - 1
    minus r4
    add r3, r4

    jmp inner_loop
break_inner_loop:

    plus r3
    add r2, r3
    jmp outer_loop

hlt:
    jmp hlt
