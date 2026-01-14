#!/bin/bash
set -e

# Create obj directory if not exists
mkdir -p obj

# Assemble
echo "Assembling..."
nasm -f elf64 src/runtime/start.asm -o obj/start.o
nasm -f elf64 src/runtime/io.asm -o obj/io.o
nasm -f elf64 src/allocator/mem.asm -o obj/mem.o
nasm -f elf64 src/main.asm -o obj/main.o

# Link
echo "Linking..."
ld -o main obj/start.o obj/io.o obj/mem.o obj/main.o

echo "Build complete."
