#!/bin/bash
set -e

# Create obj directory if not exists
mkdir -p obj

# Assemble
echo "Assembling..."
nasm -f elf64 -I corelib/ corelib/runtime/start.asm -o obj/start.o
nasm -f elf64 -I corelib/ corelib/runtime/io.asm -o obj/io.o
# Use the new alloc.asm
nasm -f elf64 -I corelib/ corelib/memory/alloc.asm -o obj/mem.o
nasm -f elf64 -I corelib/ corelib/runtime/daemon.asm -o obj/daemon.o
nasm -f elf64 -I corelib/ corelib/debug/debugger.asm -o obj/debug.o
nasm -f elf64 src/main.asm -o obj/main.o

# Link
echo "Linking..."
ld -o morph obj/start.o obj/io.o obj/mem.o obj/daemon.o obj/debug.o obj/main.o

echo "Build complete."
