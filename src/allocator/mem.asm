section .data
    current_break dq 0

section .text
    global mem_alloc

%include "src/runtime/syscalls.inc"

; mem_alloc(size_in_bytes)
; Input: RDI = size
; Output: RAX = pointer to memory, or 0 on failure
mem_alloc:
    push rbx                ; Save RBX (callee-saved)
    mov rbx, rdi            ; Save requested size in RBX

    ; Check if we have initialized current_break
    mov rax, [current_break]
    test rax, rax
    jnz .calculate_new_break

    ; Initialize: Get current break
    mov rax, SYS_BRK
    mov rdi, 0
    syscall

    mov [current_break], rax

.calculate_new_break:
    ; current_break is in [current_break]
    mov rdi, [current_break] ; RDI = old break (start of new block)
    add rdi, rbx             ; RDI = target break (old + size)

    mov rax, SYS_BRK
    syscall                  ; Call brk(target_break)

    ; sys_brk returns the new break address on success
    ; If it failed, it usually returns the current break (which is < target)

    cmp rax, rdi             ; Check if returned address == requested address
    jne .error

    ; Success
    mov rax, [current_break] ; Return old break (pointer to start of block)
    mov [current_break], rdi ; Update global current_break

    pop rbx
    ret

.error:
    xor rax, rax            ; Return 0 (NULL)
    pop rbx
    ret
