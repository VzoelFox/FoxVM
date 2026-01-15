# corelib/memory/pool.s
# Implementasi Memory Pool (Linux x86_64)

.include "corelib/platform/x86_64/asm/macros.inc"

.section .data
    # Magic signature: "MORFPOOL" in little-endian
    .global pool_magic_sig
    pool_magic_sig: .quad 0x4C4F4F50464F524D

.section .text
.global pool_create
.global pool_alloc
.global pool_free
.global pool_validate

# ------------------------------------------------------------------------------
# func pool_create(obj_size: i64, capacity: i64) -> ptr
# Input:  %rdi = obj_size
#         %rsi = capacity
# Output: %rax = pointer to Pool struct (or 0 if failed)
# ------------------------------------------------------------------------------
pool_create:
    pushq %rbp
    movq %rsp, %rbp

    # Allocate stack for locals
    subq $16, %rsp
    # -8(%rbp): obj_size
    # -16(%rbp): total_size

    # 1. Validasi obj_size >= 8
    cmpq $8, %rdi
    jl .create_fail

    # Simpan obj_size
    movq %rdi, -8(%rbp)

    # 2. Hitung Total Size = (obj_size * capacity) + 48
    movq %rdi, %rax
    mulq %rsi           # rax = obj_size * capacity

    addq $48, %rax
    movq %rax, -16(%rbp) # Simpan total_size

    # 3. Alokasi memori
    movq %rax, %rdi     # rdi = total_size
    call mem_alloc

    testq %rax, %rax
    jz .create_fail

    # %rax = Base Address
    # Init Header (48 bytes)

    # [0x00] Start Ptr = Base + 48
    leaq 48(%rax), %rcx
    movq %rcx, 0(%rax)

    # [0x08] Current Ptr = Start Ptr
    movq %rcx, 8(%rax)

    # [0x10] End Ptr = Base + Total Size
    movq -16(%rbp), %rdx # Restore total_size
    addq %rax, %rdx      # Base + Total Size
    movq %rdx, 16(%rax)

    # [0x18] Object Size
    movq -8(%rbp), %rcx  # Restore obj_size
    movq %rcx, 24(%rax)

    # [0x20] Free List Head = 0 (NULL)
    movq $0, 32(%rax)

    # [0x28] Magic = MORFPOOL (untuk validasi dan prevent cross-domain corruption)
    movq pool_magic_sig(%rip), %rcx
    movq %rcx, 40(%rax)

    # Return Base Address
    leave
    ret

.create_fail:
    xorq %rax, %rax
    leave
    ret

# ------------------------------------------------------------------------------
# func pool_alloc(pool: ptr) -> ptr
# Input:  %rdi = pool
# Output: %rax = obj_ptr (or 0 if OOM or invalid pool)
# ------------------------------------------------------------------------------
pool_alloc:
    pushq %rbp
    movq %rsp, %rbp

    # 0. Validate pool pointer
    testq %rdi, %rdi
    jz .alloc_oom

    # 1. Validate Magic (MORFPOOL) - prevent cross-domain corruption
    movq 40(%rdi), %rax
    cmpq pool_magic_sig(%rip), %rax
    jne .alloc_oom           # Invalid pool, return 0

    # 2. Cek Free List Head [0x20]
    movq 32(%rdi), %rax
    testq %rax, %rax
    jnz .alloc_from_free_list

    # 2. Alloc dari Bump Pointer
    movq 8(%rdi), %rax  # Current
    movq 24(%rdi), %rcx # Obj Size
    movq 16(%rdi), %rdx # End

    # Calc New Current
    movq %rax, %r8      # Old Current (Result)
    addq %rcx, %rax     # New Current

    # Check Bounds
    cmpq %rdx, %rax
    ja .alloc_oom

    # Update Current
    movq %rax, 8(%rdi)

    # Return Old Current
    movq %r8, %rax
    leave
    ret

.alloc_from_free_list:
    # %rax contains current Free List Head (Obj Ptr)
    # Next free block ptr is stored at start of Obj Ptr
    movq (%rax), %rcx   # Next Free Node
    movq %rcx, 32(%rdi) # Update Free List Head

    # Return Obj Ptr (%rax)
    leave
    ret

.alloc_oom:
    xorq %rax, %rax
    leave
    ret

# ------------------------------------------------------------------------------
# func pool_free(pool: ptr, obj_ptr: ptr) -> void
# Input:  %rdi = pool
#         %rsi = obj_ptr
# Returns silently on invalid input (safe behavior)
# ------------------------------------------------------------------------------
pool_free:
    pushq %rbp
    movq %rsp, %rbp

    # 0. Validate pool pointer
    testq %rdi, %rdi
    jz .free_invalid

    # 1. Validate obj_ptr
    testq %rsi, %rsi
    jz .free_invalid

    # 2. Validate Magic (MORFPOOL) - prevent cross-domain corruption
    movq 40(%rdi), %rax
    cmpq pool_magic_sig(%rip), %rax
    jne .free_invalid        # Not a valid pool

    # 3. Bounds Check: obj_ptr must be within [Start, End)
    movq 0(%rdi), %rax       # Start
    cmpq %rax, %rsi
    jb .free_invalid         # obj_ptr < Start

    movq 16(%rdi), %rax      # End
    cmpq %rax, %rsi
    jae .free_invalid        # obj_ptr >= End

    # 4. Alignment Check: (obj_ptr - Start) % obj_size == 0
    movq %rsi, %rax
    subq 0(%rdi), %rax       # offset = obj_ptr - Start
    xorq %rdx, %rdx
    divq 24(%rdi)            # offset / obj_size
    testq %rdx, %rdx         # check remainder
    jnz .free_invalid        # Not aligned to obj_size

    # 5. Double-free Detection: check if obj_ptr already in free list
    #    Simple check: if *obj_ptr points within pool bounds, might be in list
    #    (Heuristic - not perfect but catches common cases)
    movq (%rsi), %rax
    testq %rax, %rax
    jz .free_ok              # NULL is fine (fresh alloc)
    cmpq 0(%rdi), %rax       # Compare with Start
    jb .free_ok              # Points outside pool - OK
    cmpq 16(%rdi), %rax      # Compare with End
    jae .free_ok             # Points outside pool - OK
    # Points inside pool - possible double free, skip silently
    jmp .free_invalid

.free_ok:
    # 6. Ambil Current Free List Head
    movq 32(%rdi), %rax

    # 7. Store Old Head into *obj_ptr
    movq %rax, (%rsi)

    # 8. Update Head = obj_ptr
    movq %rsi, 32(%rdi)

.free_invalid:
    leave
    ret

# ------------------------------------------------------------------------------
# func pool_validate(pool: ptr) -> i64
# Input:  %rdi = pool
# Output: %rax = 1 if valid, 0 if invalid
# Validates pool structure integrity
# ------------------------------------------------------------------------------
pool_validate:
    pushq %rbp
    movq %rsp, %rbp

    # 0. NULL check
    testq %rdi, %rdi
    jz .validate_fail

    # 1. Magic check
    movq 40(%rdi), %rax
    cmpq pool_magic_sig(%rip), %rax
    jne .validate_fail

    # 2. Pointer sanity: Start < End
    movq 0(%rdi), %rax       # Start
    movq 16(%rdi), %rcx      # End
    cmpq %rcx, %rax
    jae .validate_fail       # Start >= End is invalid

    # 3. Current within bounds: Start <= Current <= End
    movq 8(%rdi), %rdx       # Current
    cmpq %rax, %rdx
    jb .validate_fail        # Current < Start
    cmpq %rcx, %rdx
    ja .validate_fail        # Current > End

    # 4. Object size > 0
    movq 24(%rdi), %rax
    testq %rax, %rax
    jz .validate_fail

    # All checks passed
    movq $1, %rax
    leave
    ret

.validate_fail:
    xorq %rax, %rax
    leave
    ret
