section .data
    msg db "Halo", 10
    msg_len equ $ - msg
    alloc_msg db "Allocated at: "
    alloc_msg_len equ $ - alloc_msg

section .text
    global main
    extern mem_alloc
    extern io_print_bytes
    extern io_print_newline
    extern io_print_hex

%include "core/syscalls.inc"

main:
    ; 1. Print static message "Halo\n"
    mov rdi, msg
    mov rsi, msg_len
    call io_print_bytes

    ; 2. Allocate memory
    mov rdi, 32
    call mem_alloc
    test rax, rax
    jz .fail
    mov r8, rax         ; Save pointer

    ; 3. Print "Allocated at: "
    mov rdi, alloc_msg
    mov rsi, alloc_msg_len
    call io_print_bytes

    ; 4. Print the address in Hex
    mov rdi, r8
    call io_print_hex
    call io_print_newline

    ; 5. Use the memory (write something and print it)
    mov byte [r8], 'T'
    mov byte [r8+1], 'e'
    mov byte [r8+2], 's'
    mov byte [r8+3], 't'
    mov byte [r8+4], 10

    mov rdi, r8
    mov rsi, 5
    call io_print_bytes

    ; Return 0
    xor rax, rax
    ret

.fail:
    mov rax, 1
    ret
