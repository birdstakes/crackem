#include "vm.asm"

; insertion sort from wikipedia, modified a bit to make life easier
; hopefully it's still correct...

; i = 0
; while i < len(A) - 1:
;    j = i
;    while j != -1 and A[j] >= A[j+1]:
;        A[j], A[j+1] = A[j+1], A[j]
;        j -= 1
;    i += 1

; inputs:
; r0 = A
; r1 = len(A)

dec r1, clobber r3

; r2 = i, already 0

; while i < len(A) - 1
outer_loop:
    ; if !(i - (len(A) - 1) < 0) we're done
    sub r3, r2, r1, clobber r4
    ltz r3, clobber r4
    if r3 then .fallthrough else hlt, clobber r4
    .fallthrough:

    ; j = i
    mov r3, r2

    ; while j != -1 and A[j] >= A[j+1]
    inner_loop:
        ; break if j == -1
        mov r5, r3
        inc r5, clobber r6
        if r5 then .fallthrough else .break, clobber r4
        .fallthrough:

        ; r5 = A[j]
        mov r4, r0
        add r4, r3
        ld r5, r4

        ; r6 = A[j+1]
        inc r4, clobber r6
        ld r6, r4

        ; r5 = A[j] - A[j+1]
        sub nosave r5, r6, clobber r4

        ; break if r5 < 0 ==> A[j] < A[j+1] ==> !(A[j] >= A[j+1])
        ltz r5, clobber r4
        if r5 then .break else .fallthrough2, clobber r4
        .fallthrough2:

        ; swap A[j] and A[j+1]

        ; r5 = A[j]
        mov r4, r0
        add r4, r3
        ld r5, r4

        ; r6 = A[j+1]
        inc r4, clobber r6
        ld r6, r4

        ; A[j+1] = r5
        str r4, r5

        ; A[j] = r6
        dec r4, clobber r5
        str r4, r6

        ; j -= 1
        dec r3, clobber r4
        jmp inner_loop

    .break:

    ; i += 1
    inc r2, clobber r3
    jmp outer_loop

hlt:
    jmp hlt
