section .text
    global io_print_bytes
    global io_print_newline
    global io_print_hex
    global io_print_string
    global io_print_string_len
    global io_print_int
    global io_print_to_stderr

%include "syscalls.inc"

; -----------------------------------------------------------------------------
; io_print_bytes
; Arguments:
;   RDI: Pointer to buffer
;   RSI: Length of buffer
; -----------------------------------------------------------------------------
io_print_bytes:
    mov rdx, rsi        ; Length
    mov rsi, rdi        ; Buffer
    mov rdi, STDOUT     ; File descriptor
    mov rax, SYS_WRITE  ; Syscall number
    syscall
    ret

; -----------------------------------------------------------------------------
; io_print_newline
; Arguments: None
; -----------------------------------------------------------------------------
io_print_newline:
    push 0x0A
    mov rsi, rsp        ; Address of the char on stack
    mov rdx, 1          ; Length 1
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall
    add rsp, 8          ; Restore stack
    ret

; -----------------------------------------------------------------------------
; io_print_hex
; Arguments:
;   RDI: 64-bit integer to print
; Description: Prints 16-char hex representation.
; -----------------------------------------------------------------------------
io_print_hex:
    push rbp
    mov rbp, rsp
    sub rsp, 16

    mov rax, rdi
    mov rcx, 16

.loop:
    dec rcx
    mov rdx, rax
    and rdx, 0xF
    cmp rdx, 9
    jg .hex_letter
    add rdx, '0'
    jmp .store_char
.hex_letter:
    add rdx, 'A' - 10
.store_char:
    mov [rsp + rcx], dl
    shr rax, 4
    test rcx, rcx
    jnz .loop

    mov rsi, rsp
    mov rdx, 16
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    add rsp, 16
    pop rbp
    ret

; -----------------------------------------------------------------------------
; io_print_string
; Arguments:
;   RDI: Pointer to null-terminated string (ASCIZ)
; -----------------------------------------------------------------------------
io_print_string:
    push rbx
    mov rbx, rdi        ; Save pointer

    ; Calculate length
    xor rcx, rcx
.len_loop:
    cmp byte [rbx + rcx], 0
    je .print
    inc rcx
    jmp .len_loop

.print:
    mov rdx, rcx        ; Length
    mov rsi, rbx        ; Buffer
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    pop rbx
    ret

; -----------------------------------------------------------------------------
; io_print_string_len
; Arguments:
;   RDI: Pointer to string
;   RSI: Length
; -----------------------------------------------------------------------------
io_print_string_len:
    mov rdx, rsi
    mov rsi, rdi
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall
    ret

; -----------------------------------------------------------------------------
; io_print_to_stderr
; Arguments:
;   RDI: Pointer to null-terminated string
; -----------------------------------------------------------------------------
io_print_to_stderr:
    push rbx
    mov rbx, rdi

    xor rcx, rcx
.len_loop:
    cmp byte [rbx + rcx], 0
    je .print
    inc rcx
    jmp .len_loop

.print:
    mov rdx, rcx
    mov rsi, rbx
    mov rdi, 2          ; STDERR file descriptor (usually 2)
    mov rax, SYS_WRITE
    syscall

    pop rbx
    ret

; -----------------------------------------------------------------------------
; io_print_int
; Arguments:
;   RDI: 64-bit signed integer to print
; -----------------------------------------------------------------------------
io_print_int:
    push rbp
    mov rbp, rsp
    sub rsp, 24         ; Buffer for 20 digits + sign + null

    mov rax, rdi
    mov rbx, 10         ; Divisor
    mov rcx, 0          ; Digit count

    ; Handle negative
    test rax, rax
    jns .positive
    neg rax
    ; We'll add the minus sign later or print it first,
    ; but simpler to just remember we need it.
    ; For simplicity here, let's print the number backwards into buffer.

.positive:
    ; Check for 0 explicitly? No, do-while loop handles it if structured right,
    ; but let's do a simple loop.
    test rax, rax
    jnz .convert_loop

    ; If zero
    mov byte [rsp+23], '0'
    lea rsi, [rsp+23]
    mov rdx, 1
    jmp .do_print

.convert_loop:
    xor rdx, rdx
    div rbx             ; RAX / 10, RDX = remainder
    add dl, '0'

    ; Store at end of buffer working backwards
    mov r8, 24
    sub r8, 1
    sub r8, rcx         ; Index = 23 - rcx
    mov [rsp + r8], dl

    inc rcx
    test rax, rax
    jnz .convert_loop

    ; Add sign if needed
    cmp rdi, 0
    jge .print_num

    mov r8, 23
    sub r8, rcx
    mov byte [rsp + r8], '-'
    inc rcx

.print_num:
    ; Calculate start address: rsp + 24 - rcx
    mov rsi, rsp
    add rsi, 24
    sub rsi, rcx

    mov rdx, rcx

.do_print:
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    add rsp, 24
    pop rbp
    ret
