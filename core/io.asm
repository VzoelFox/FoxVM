section .text
    global io_print_bytes
    global io_print_newline
    global io_print_hex

%include "core/syscalls.inc"

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
    ; Push a newline character (0x0A) onto the stack
    ; We push 8 bytes (rax size) but only use the lowest byte
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
; Description:
;   Prints the 16-character hexadecimal representation of the integer.
;   Does NOT print a newline or "0x" prefix.
; -----------------------------------------------------------------------------
io_print_hex:
    push rbp
    mov rbp, rsp
    sub rsp, 16         ; Allocate 16 bytes buffer on stack

    mov rax, rdi        ; The value to process
    mov rcx, 16         ; Loop counter (16 nibbles)

.loop:
    dec rcx             ; Decrement index (15 down to 0)

    ; Extract 4 bits (LSB)
    mov rdx, rax
    and rdx, 0xF

    ; Convert to ASCII
    cmp rdx, 9
    jg .hex_letter
    add rdx, '0'
    jmp .store_char

.hex_letter:
    add rdx, 'A' - 10

.store_char:
    ; Store in buffer at [rsp + rcx]
    ; Because we process LSB first, we store at the end of the buffer (index 15)
    ; and move backwards.
    mov [rsp + rcx], dl

    shr rax, 4          ; Move to next nibble
    test rcx, rcx
    jnz .loop

    ; Print the buffer
    mov rsi, rsp        ; Buffer address
    mov rdx, 16         ; Length
    mov rdi, STDOUT
    mov rax, SYS_WRITE
    syscall

    add rsp, 16         ; Deallocate buffer
    pop rbp
    ret
