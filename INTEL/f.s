;section .data
;perimeter       TIMES 5 DD 0
;figureAddress   TIMES 5 DQ 0
;height          TIMES 5 DD 0
;width           TIMES 5 DD 0
;counter         DB 0

section .text

;[rbp - 4]  x during iteration
;[rbp - 8]  y during iteration
;[rbp - 12] bottom
;[rbp - 16] right
;[rbp - 20] up
;[rbp - 24] left
;[rbp - 32] address of the pixel, that was found first
;[rbp - 36] perimeter counter
;ebx - flag
;r11 - array of data
;0 - perimeter, 4 - 1st pixel address, 12 - height, 16 - width
;[rbp - 60], [rbp - 80], [rbp - 100], [rbp - 120], [rbp - 140] - 5 different figures possible
;r12 - input pixel map pointer
;r13 - output pixel map pointer
;r14d - x
;r15d - y

global f
f:
	push rbp
	mov rbp, rsp

	sub rsp, 140
	lea r11, [rbp - 40]
	mov r12, rdi
	mov r13, rsi
	add r13, 4
	mov r14d, edx
	mov r15d, ecx

	mov DWORD [rbp - 4], 0
    mov DWORD [rbp - 8], 0

findNextPixel:
    mov eax, DWORD [r12]
    cmp eax, 0xff000000
    je  setup
    cmp eax, 0xff000001
    je  skipPixels

    add r12, 4
    inc DWORD [rbp - 4]
    cmp r14d, DWORD [rbp - 4]
    jne findNextPixel
    mov DWORD [rbp - 4], 0
    inc DWORD [rbp - 8]
    cmp r15d, DWORD [rbp - 8]
    jne findNextPixel
    jmp createOutputImage

setup:
    mov ebx, 0
    mov r8d, DWORD [rbp - 8]
    mov DWORD [rbp - 12], r8d
    mov DWORD [rbp - 16], 0
    mov DWORD [rbp - 20], 0
    mov DWORD [rbp - 24], r14d
    mov QWORD [rbp - 32], r12
    mov DWORD [rbp - 36], 0
    inc DWORD [r12]

goRight:
    mov ebx, 0
    add r12, 4
    inc DWORD [rbp - 4]
    cmp QWORD [rbp - 32], r12
    je  saveFigure
    mov eax, DWORD [r12]
    cmp eax, 0xffffffff
    jne cRight
    sub r12, 4
    dec DWORD [rbp - 4]
    jmp goUp
cRight:
    call checkPixels

    cmp ebx, 1
    je goDown
cRightFin:
    inc DWORD [r12]

    inc DWORD [rbp - 36]

    mov eax, DWORD [rbp - 4]
    cmp DWORD [rbp - 16], eax
    jg  goRight
    mov DWORD [rbp - 16], eax
    jmp goRight

goUp:
    mov ebx, 0
    mov r8, r14
    sal r8, 2
    add r12, r8
    inc DWORD [rbp - 8]
    cmp QWORD [rbp - 32], r12
    je  saveFigure
    mov eax, DWORD [r12]
    cmp eax, 0xffffffff
    jne cUp
    sub r12, r8
    dec DWORD [rbp - 8]
    jmp goLeft
cUp:
    call checkPixels
    cmp ebx, 1
    je goRight
cUpFin:
    inc DWORD [r12]

    inc DWORD [rbp - 36]

    mov eax, DWORD [rbp - 8]
    cmp DWORD [rbp - 20], eax
    jg  goUp
    mov DWORD [rbp - 20], eax
    jmp goUp

goLeft:
    mov ebx, 0
    sub r12, 4
    dec DWORD [rbp - 4]
    cmp QWORD [rbp - 32], r12
    je  saveFigure
    mov eax, DWORD [r12]
    cmp eax, 0xffffffff
    jne cLeft
    add r12, 4
    inc DWORD [rbp - 4]
    jmp goDown
cLeft:
    call checkPixels
    cmp ebx, 1
    je goUp
cLeftFin:
    inc DWORD [r12]

    inc DWORD [rbp - 36]

    mov eax, DWORD [rbp - 4]
    cmp DWORD [rbp - 24], eax
    jl  goLeft
    mov DWORD [rbp - 24], eax
    jmp goLeft

goDown:
    mov ebx, 0
    mov r8, r14
    sal r8, 2
    sub r12, r8
    dec DWORD [rbp - 8]
    cmp QWORD [rbp - 32], r12
    je  saveFigure
    mov eax, DWORD [r12]
    cmp eax, 0xffffffff
    jne cDown
    add r12, r8
    inc DWORD [rbp - 8]
    jmp goRight
cDown:
    call checkPixels

    cmp ebx, 1
    je goLeft
cDownFin:
    inc DWORD [r12]

    inc DWORD [rbp - 36]

    jmp goDown

checkPixels:
    push rbp
    mov rbp, rsp

    mov r8, r14
    sal r8, 2
    add r12, r8
    mov eax, DWORD [r12]
    sub r12, r8
    cmp eax, 0xffffffff
    je  checkFin
    add r12, 4
    mov eax, DWORD [r12]
    sub r12, 4
    cmp eax, 0xffffffff
    je  checkFin
    sub r12, r8
    mov eax, DWORD [r12]
    add r12, r8
    cmp eax, 0xffffffff
    je  checkFin
    sub r12, 4
    mov eax, DWORD [r12]
    add r12, 4
    cmp eax, 0xffffffff
    je  checkFin
    inc ebx
checkFin:
    nop
    leave
	ret

saveFigure:
    inc DWORD [rbp - 36]

    mov r8d, DWORD [rbp - 36]
    mov DWORD [r11 - 4], r8d

    mov eax, r14d
    sal eax, 2
    mul DWORD [rbp - 12]
    mov r8, rax
    mov eax, [rbp - 24]
    sal eax, 2
    add r8, rax
    add r8, rdi
    mov QWORD [r11 - 12], r8

    mov r8, 0
    mov r8d, DWORD [rbp - 20]
    sub r8d, DWORD [rbp - 12]
    inc r8d
    mov DWORD [r11 - 16], r8d
    mov r8d, DWORD [rbp - 16]
    sub r8d, DWORD [rbp - 24]
    inc r8d
    mov DWORD [r11 - 20], r8d

    mov DWORD [rbp - 12], 0     ;zeroing, just in case
    mov DWORD [rbp - 16], 0
    mov DWORD [rbp - 20], 0
    mov DWORD [rbp - 24], 0
    mov DWORD [rbp - 32], 0
    mov DWORD [rbp - 36], 0
    mov rbx, 0

    sub r11, 20
    lea r8, [rbp - 140]
    cmp r11, r8
breakpoint_a:
    je  createOutputImage
    jmp findNextPixel

createOutputImage:
chooseFigure:
    mov r8d, 0x7fffffff
    lea rax, [rbp - 40]
loop:
    cmp DWORD [rax - 4], -1
    je  continue
    cmp DWORD [rax - 4], r8d
    jg  continue
    mov r8d, DWORD [rax - 4]
    mov r9, rax
continue:
    sub rax, 20
    cmp rax, r11
    jg  loop

    cmp r8d, 0x7fffffff
    je  end
    mov DWORD [r9 - 4], -1

    mov r12, QWORD [r9 - 12]
    mov DWORD [rbp - 4], 0
    mov DWORD [rbp - 8], 0
    mov eax, DWORD [r9 - 16]
    mov DWORD [rbp - 12], eax
    mov eax, DWORD [r9 - 20]
    mov DWORD [rbp - 16], eax

writeColumn:
    mov eax, DWORD [r12]
    cmp eax, 0xff000001
    jne writePixel
    dec eax
writePixel:
    mov DWORD [r13], eax
    inc DWORD [rbp - 8]
    mov r8, r14
    sal r8, 2
    add r12, r8
    add r13, r8
    mov eax, DWORD [rbp - 8]
    cmp eax, DWORD [rbp - 12]
    jl writeColumn

switchColumn:
    mov r8, r14
    sal r8, 2
    mov eax, DWORD [rbp - 12]
    mul r8
    sub r12, rax
    sub r13, rax
    add r12, 4
    add r13, 4
    inc DWORD [rbp - 4]
    mov DWORD [rbp - 8], 0
    mov eax, DWORD [rbp - 4]
    cmp eax, DWORD [rbp - 16]
    jl writeColumn

    add r13, 12
    jmp chooseFigure

skipPixels:
    add r12, 4
    inc DWORD [rbp - 4]
    mov eax, DWORD [r12]
    cmp eax, 0xffffffff
    je  findNextPixel
    jmp skipPixels

end:
	mov rsp, rbp
	pop rbp
	ret

