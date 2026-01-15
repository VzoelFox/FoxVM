section .text
    global main
    extern io_print_string
    extern io_print_newline
    extern debug_dump_registers

main:
    ; Print welcome message
    mov rdi, s_welcome
    call io_print_string
    call io_print_newline

    ; Test debugging registers
    mov rdi, s_debug
    call io_print_string
    call io_print_newline

    ; Load some dummy values to verify dump
    mov rax, 0xDEADBEEF
    mov rbx, 0xCAFEBABE
    mov rcx, 12345
    call debug_dump_registers

    ; Return 0
    xor rax, rax
    ret

section .data
    s_welcome db "Welcome to Morph VM (Native Debug Test)", 0
    s_debug   db "Testing Register Dump:", 0
