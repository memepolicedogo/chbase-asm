#!/bin/bash
nasm -f elf64 -g -F dwarf chbase.asm && ld -o chbase chbase.o
rm chbase.o
