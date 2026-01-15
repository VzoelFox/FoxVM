section .text
    global _start
    extern main

%include "syscalls.inc"

_start:
    ; Call the main application logic
    call main

    ; Exit the program
    ; Assuming main returns exit code in rax
    mov rdi, rax        ; status
    mov rax, SYS_EXIT   ; syscall number
    syscall
