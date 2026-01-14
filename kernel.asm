; kernel.asm
; Core logic for Quartenary System
; Demonstrates the "Proof of Quo" concept

%include "quartenary.inc"

section .data
    Q_ALIGN_16
    ; This is our Quo Block. It starts in the Q_QUO state.
    my_quo_block:
        istruc QuoBlock
            at QuoBlock.header, dq Q_QUO
            at QuoBlock.meta,   dq 0
        iend

section .text
    global _start

_start:
    ; Load the address of the block into RAX
    lea rax, [my_quo_block]

    ; Check current state (it should be 4)
    mov rbx, [rax + QuoBlock.header]

    ; Logic: If it is Q_QUO, we must "prove" it.
    cmp rbx, Q_QUO
    je  .attempt_proof
    jmp .exit_program

.attempt_proof:
    ; Call the proof routine
    ; Input: RAX = address of the block
    call prove_quo

    ; After return, the block header should be updated to Q_CERT or Q_NULL
    ; Load the new value into RDI for exit code
    mov rdi, [rax + QuoBlock.header]
    jmp .do_exit

.exit_program:
    mov rdi, rbx ; Use existing value

.do_exit:
    ; sys_exit(rdi)
    mov rax, 60
    syscall

; -----------------------------------------------------------
; Routine: prove_quo
; Purpose: Resolves a Q_QUO (4) state into Q_CERT (8) or Q_NULL (0)
; Input: RAX = Address of the QuoBlock
; Logic: Checks if the address in RAX is 16-byte aligned.
;        (User requirement: "allignment kelipatan 16")
; -----------------------------------------------------------
prove_quo:
    ; Check alignment: (Address & 0xF) should be 0
    test rax, 0xF
    jz  .proven_valid

    ; Case: Invalid / Unproven -> Collapse to Q_NULL (0)
    mov qword [rax + QuoBlock.header], Q_NULL
    ret

.proven_valid:
    ; Case: Proven -> Evolve to Q_CERT (8)
    mov qword [rax + QuoBlock.header], Q_CERT
    ret
