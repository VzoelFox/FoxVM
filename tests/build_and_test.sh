#!/bin/bash
set -e

mkdir -p obj

echo "Compiling CoreLib (GAS)..."
as corelib/memory/alloc.s -o obj/alloc.o
as corelib/memory/arena.s -o obj/arena.o
as corelib/memory/pool.s -o obj/pool.o
as corelib/runtime/daemon_cleaner.s -o obj/daemon.o

echo "Compiling Test Harness..."
as tests/test_robust_memory.s -o obj/test.o

echo "Linking..."
ld -o tests/runner obj/test.o obj/alloc.o obj/arena.o obj/pool.o obj/daemon.o

echo "Running Tests..."
./tests/runner
EXIT_CODE=$?

# Cleanup
rm -f tests/runner

if [ $EXIT_CODE -eq 0 ]; then
    echo "SUCCESS: Robust Memory System Verified."
    echo "  - Allocator (VZOELFOX) OK"
    echo "  - Arena OK"
    echo "  - Pool (MORFPOOL) OK"
    echo "  - Daemon Start OK"
else
    echo "FAILURE: Test exited with code $EXIT_CODE"
    exit 1
fi
