section .text
    global _start
    extern mem_alloc
    extern mem_snapshot
    extern spawn_daemon

    ; Constants
    MAGIC_HEADER equ 0x584F464C454F5A56 ; "VZOELFOX"
    MAGIC_SNAPSHOT equ 0x504E534850524F4D ; "MORPHSNP"

_start:
    ; 1. Test Allocation (VZOELFOX)
    mov rdi, 16
    call mem_alloc

    test rax, rax
    jz .fail_alloc

    ; Verify Header
    mov rbx, [rax - 8]
    mov rdx, MAGIC_HEADER
    cmp rbx, rdx
    jne .fail_header

    ; 2. Test Snapshot (MORPHSNP)
    mov rdi, 16
    call mem_snapshot

    test rax, rax
    jz .fail_snapshot

    ; Verify Header
    mov rbx, [rax - 8]
    mov rdx, MAGIC_SNAPSHOT
    cmp rbx, rdx
    jne .fail_snapshot_header

    ; 3. Test Daemon Spawn
    call spawn_daemon

    cmp rax, 0
    jle .fail_daemon ; PID should be positive in parent

    ; Success
    mov rax, 60 ; sys_exit
    mov rdi, 0  ; status 0
    syscall

.fail_alloc:
    mov rax, 60
    mov rdi, 1
    syscall

.fail_header:
    mov rax, 60
    mov rdi, 2
    syscall

.fail_snapshot:
    mov rax, 60
    mov rdi, 4
    syscall

.fail_snapshot_header:
    mov rax, 60
    mov rdi, 5
    syscall

.fail_daemon:
    mov rax, 60
    mov rdi, 3
    syscall
