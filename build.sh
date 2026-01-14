#!/bin/bash
set -e

echo "Assembling..."
nasm -f elf64 kernel.asm -o kernel.o

echo "Linking..."
ld kernel.o -o kernel

echo "Running Kernel..."
set +e # Disable exit-on-error temporarily because we expect a non-zero exit code (8)
./kernel
EXIT_CODE=$?
set -e # Re-enable exit-on-error

echo "Kernel finished with Exit Code: $EXIT_CODE"

if [ $EXIT_CODE -eq 8 ]; then
    echo "SUCCESS: Quo (4) was proven and became Certain (8)."
elif [ $EXIT_CODE -eq 0 ]; then
    echo "FAILURE: Quo (4) was NOT proven and became Null (0)."
else
    echo "UNKNOWN: Unexpected result: $EXIT_CODE"
fi
