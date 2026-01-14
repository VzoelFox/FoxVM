#!/bin/bash
set -e

# Create obj directory if not exists
mkdir -p obj

# Assemble CoreLib
echo "Assembling CoreLib..."
nasm -f elf64 core/start.asm -o obj/start.o
nasm -f elf64 core/io.asm -o obj/io.o
nasm -f elf64 core/memory.asm -o obj/memory.o

# Assemble VM
echo "Assembling VM..."
nasm -f elf64 vm/main.asm -o obj/main.o

# Link
echo "Linking..."
ld -o main obj/start.o obj/io.o obj/memory.o obj/main.o

echo "Build complete. Executable is './main'"
