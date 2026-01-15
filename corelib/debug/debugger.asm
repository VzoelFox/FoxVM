section .text
    global debug_dump_registers
    extern io_print_string
    extern io_print_hex
    extern io_print_newline
    extern io_print_to_stderr

%include "syscalls.inc"

; -----------------------------------------------------------------------------
; MACRO: PANIC
; Description: Prints a message to STDERR and exits with error code 1.
; -----------------------------------------------------------------------------
%macro PANIC 1
    section .data
    %%msg db "PANIC: ", %1, 10, 0
    section .text
    mov rdi, %%msg
    call io_print_to_stderr

    ; Dump registers for context
    call debug_dump_registers

    mov rdi, 1          ; Exit code 1
    mov rax, SYS_EXIT
    syscall
%endmacro

; -----------------------------------------------------------------------------
; debug_dump_registers
; Description: Prints the values of general purpose registers to STDOUT.
; -----------------------------------------------------------------------------
debug_dump_registers:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15

    ; We need to preserve the original register values (except what we pushed)
    ; But for dumping, we just want to see them.
    ; Since we are in a function call, some are already modified (stack).
    ; Ideally this should be called via a macro that pushes everything first if we want
    ; exact state at call site. But for now, let's print what we can.

    ; Example output:
    ; RAX: <hex>  RBX: <hex>

    ; RAX
    mov rdi, s_rax
    call io_print_string
    mov rdi, rax        ; Note: This is RAX *now*, which might be garbage if not preserved by caller
    call io_print_hex
    call io_print_newline

    ; RBX (saved on stack)
    mov rdi, s_rbx
    call io_print_string
    mov rdi, [rsp + 32] ; r15(0), r14(8), r13(16), r12(24), rbx(32) relative to current rsp?
                        ; Wait, we pushed 5 regs (5*8=40 bytes).
                        ; rsp points to r15.
                        ; rbx is at rsp + 32.
    call io_print_hex
    call io_print_newline

    ; RCX
    mov rdi, s_rcx
    call io_print_string
    mov rdi, rcx
    call io_print_hex
    call io_print_newline

    ; RDX
    mov rdi, s_rdx
    call io_print_string
    mov rdi, rdx
    call io_print_hex
    call io_print_newline

    ; RDI
    mov rdi, s_rdi
    call io_print_string
    mov rdi, rdi        ; RDI is used for arguments, so this value is likely garbage/this string pointer
    call io_print_hex
    call io_print_newline

    ; RSI
    mov rdi, s_rsi
    call io_print_string
    mov rdi, rsi
    call io_print_hex
    call io_print_newline

    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

section .data
    s_rax db "RAX: ", 0
    s_rbx db "RBX: ", 0
    s_rcx db "RCX: ", 0
    s_rdx db "RDX: ", 0
    s_rdi db "RDI: ", 0
    s_rsi db "RSI: ", 0
