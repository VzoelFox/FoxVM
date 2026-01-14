section .text
    global main
    extern mem_alloc

%include "src/runtime/syscalls.inc"

main:
    ; Allocate 16 bytes
    mov rdi, 16
    call mem_alloc

    test rax, rax
    jz .fail

    ; Save the pointer
    mov r8, rax

    ; Write "Halo\n" to allocated memory
    mov byte [r8], 'H'
    mov byte [r8+1], 'a'
    mov byte [r8+2], 'l'
    mov byte [r8+3], 'o'
    mov byte [r8+4], 10  ; newline

    ; Print it
    mov rsi, r8         ; Buffer to print (the allocated memory)
    mov rdx, 5          ; Length
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    ; Return 0
    xor rax, rax
    ret

.fail:
    ; Return 1
    mov rax, 1
    ret
