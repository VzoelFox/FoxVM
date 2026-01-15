#!/bin/bash
set -e

# Create obj directory
mkdir -p obj

# Compile CoreLib components
nasm -f elf64 corelib/memory/alloc.asm -o obj/alloc.o
nasm -f elf64 corelib/runtime/daemon.asm -o obj/daemon.o

# Compile Test Runner
nasm -f elf64 tests/runner.asm -o obj/runner.o

# Link
ld -o tests/runner obj/runner.o obj/alloc.o obj/daemon.o

# Run
echo "Running Memory System Test..."
./tests/runner
EXIT_CODE=$?

# Cleanup
rm -f tests/runner

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: Memory Allocation & Daemon Spawn Verified."
    echo "  - Allocator returned valid pointer"
    echo "  - Magic Header 'VZOELFOX' confirmed"
    echo "  - Snapshot Header 'MORPHSNP' confirmed"
    echo "  - Daemon process spawned successfully"
else
    echo "FAILURE: Test exited with code $EXIT_CODE"
    if [ $EXIT_CODE -eq 1 ]; then echo "  Reason: Allocation Failed"; fi
    if [ $EXIT_CODE -eq 2 ]; then echo "  Reason: Header Mismatch"; fi
    if [ $EXIT_CODE -eq 3 ]; then echo "  Reason: Daemon Spawn Failed"; fi
    if [ $EXIT_CODE -eq 4 ]; then echo "  Reason: Snapshot Failed"; fi
    if [ $EXIT_CODE -eq 5 ]; then echo "  Reason: Snapshot Header Mismatch"; fi
    exit 1
fi
