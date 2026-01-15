section .data
    heap_current dq 0

section .text
    global mem_alloc
    global mem_snapshot
    global mem_init
    global mem_get_current

    ; Constants
    SYS_BRK equ 12
    ; "VZOELFOX" -> 0x584F464C454F5A56
    MAGIC_HEADER equ 0x584F464C454F5A56
    ; "MORPHSNP" -> M=4D O=4F R=52 P=50 H=48 S=53 N=4E P=50
    ; Little Endian: P N S H P R O M -> 50 4E 53 48 50 52 4F 4D
    MAGIC_SNAPSHOT equ 0x504E534850524F4D

; mem_init
; Initializes the heap pointer if not already done
; Output: RAX = current heap break
mem_init:
    mov rax, SYS_BRK
    xor rdi, rdi
    syscall
    mov [heap_current], rax
    ret

; mem_alloc_internal
; Input: RDI = size, RDX = header magic
; Output: RAX = pointer to payload
mem_alloc_internal:
    push rbx
    push r12            ; Save R12 (callee-saved) to hold header

    mov rbx, rdi        ; rbx = requested size
    mov r12, rdx        ; r12 = header magic

    ; Ensure heap is initialized
    mov rax, [heap_current]
    test rax, rax
    jnz .ready
    call mem_init
    mov rax, [heap_current]
.ready:

    add rbx, 8          ; Add header size

    ; Calculate new break
    mov rdi, rax        ; rdi = old break (start of new block)
    add rdi, rbx        ; rdi = target break

    ; Request memory
    mov rax, SYS_BRK
    syscall

    cmp rax, rdi        ; Check if brk returned the requested address
    jne .fail

    ; Success. Write header at the old break.
    mov rcx, [heap_current] ; rcx = start of block

    ; Write Magic Header
    mov [rcx], r12

    ; Update heap_current to the new break
    mov [heap_current], rdi

    ; Return pointer to payload (start + 8)
    lea rax, [rcx + 8]

    pop r12
    pop rbx
    ret

.fail:
    xor rax, rax
    pop r12
    pop rbx
    ret

; mem_alloc(size)
mem_alloc:
    mov rdx, MAGIC_HEADER
    jmp mem_alloc_internal

; mem_snapshot(size)
mem_snapshot:
    mov rdx, MAGIC_SNAPSHOT
    jmp mem_alloc_internal

; mem_get_current
mem_get_current:
    mov rax, [heap_current]
    ret
