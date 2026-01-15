# tests/test_robust_memory.s
# Test harness for Robust Memory System

.include "corelib/platform/x86_64/asm/macros.inc"

.section .text
.global _start

_start:
    # --------------------------------------------------------------------------
    # 1. Test Basic Allocator (mem_alloc)
    # --------------------------------------------------------------------------
    movq $32, %rdi
    call mem_alloc

    testq %rax, %rax
    jz .fail_alloc

    # Verify Magic Header "VZOELFOX" at [ptr - 16] (Header Start + 32)
    # Wait, layout in alloc.s:
    # Header start at [ptr - 56] ?
    # Let's check alloc.s:
    #   leaq 48(%rax), %rax -> Base + 48.
    #   addq $8, %rax       -> Base + 56.
    #   Magic at Base + 32.
    #   So Magic is at (UserPtr - 56) + 32 = UserPtr - 24.

    # But wait, alloc.s logic:
    #   leaq 48(%rax), %rax # Base + 48
    #   movq %r12, (%rax)   # User Size Header at Base + 48
    #   addq $8, %rax       # User Ptr at Base + 56

    # Magic is at Base + 32.
    # Base = UserPtr - 56.
    # Magic Addr = (UserPtr - 56) + 32 = UserPtr - 24.

    movabsq $0x584F464C454F5A56, %rcx
    cmpq %rcx, -24(%rax)
    jne .fail_magic

    # --------------------------------------------------------------------------
    # 2. Test Arena (arena_create, arena_alloc)
    # --------------------------------------------------------------------------
    movq $1024, %rdi    # Size 1024
    call arena_create

    testq %rax, %rax
    jz .fail_arena_create

    movq %rax, %r12     # Save Arena Ptr

    movq %r12, %rdi
    movq $64, %rsi
    call arena_alloc

    testq %rax, %rax
    jz .fail_arena_alloc

    # --------------------------------------------------------------------------
    # 3. Test Pool (pool_create, pool_alloc)
    # --------------------------------------------------------------------------
    movq $32, %rdi      # Obj Size
    movq $10, %rsi      # Capacity
    call pool_create

    testq %rax, %rax
    jz .fail_pool_create

    movq %rax, %r13     # Save Pool Ptr

    # Validate Magic "MORFPOOL"
    # Pool struct has Magic at offset 40
    movabsq $0x4C4F4F50464F524D, %rcx
    cmpq %rcx, 40(%r13)
    jne .fail_pool_magic

    # Alloc from Pool
    movq %r13, %rdi
    call pool_alloc

    testq %rax, %rax
    jz .fail_pool_alloc

    # --------------------------------------------------------------------------
    # 4. Test Daemon Start (daemon_start)
    # --------------------------------------------------------------------------
    # Note: daemon_start forks. Parent returns PID, Child loops forever.
    # To test safely without hanging the test runner, we can't easily kill the child
    # unless we save the PID.

    call daemon_start

    # If we are here, we are parent (daemon_start calls exit in child)
    testq %rax, %rax
    jle .fail_daemon

    # Kill the daemon child to clean up
    movq %rax, %rdi     # PID
    movq $9, %rsi       # SIGKILL
    movq $62, %rax      # SYS_KILL
    syscall

    # --------------------------------------------------------------------------
    # Success
    # --------------------------------------------------------------------------
    movq $60, %rax      # SYS_EXIT
    movq $0, %rdi       # Status 0
    syscall

.fail_alloc:
    movq $60, %rax
    movq $1, %rdi
    syscall

.fail_magic:
    movq $60, %rax
    movq $2, %rdi
    syscall

.fail_arena_create:
    movq $60, %rax
    movq $3, %rdi
    syscall

.fail_arena_alloc:
    movq $60, %rax
    movq $4, %rdi
    syscall

.fail_pool_create:
    movq $60, %rax
    movq $5, %rdi
    syscall

.fail_pool_magic:
    movq $60, %rax
    movq $6, %rdi
    syscall

.fail_pool_alloc:
    movq $60, %rax
    movq $7, %rdi
    syscall

.fail_daemon:
    movq $60, %rax
    movq $8, %rdi
    syscall
