section .data
    daemon_pid dd 0
    timespec:
        dq 0          ; seconds
        dq 100000000  ; nanoseconds (100ms)

section .text
    global spawn_daemon
    global get_daemon_pid

    ; Constants
    SYS_FORK equ 57
    SYS_NANOSLEEP equ 35
    SYS_EXIT equ 60
    SYS_WRITE equ 1

spawn_daemon:
    ; Ret: RAX = PID of child (in parent), or 0 (in child)
    mov rax, SYS_FORK
    syscall

    cmp rax, 0
    je .daemon_entry    ; We are the child
    jl .error           ; Error

    ; Parent logic
    mov [daemon_pid], eax
    ret

.error:
    ret

.daemon_entry:
    ; Daemon loop
    ; This runs in the background process
.loop:
    ; Sleep for 100ms to avoid burning CPU
    mov rax, SYS_NANOSLEEP
    lea rdi, [timespec]
    xor rsi, rsi
    syscall

    ; Here we would perform GC / Cleanup
    ; For now, it just lives.

    jmp .loop

get_daemon_pid:
    mov eax, [daemon_pid]
    ret
