ASM=nasm
A_OPTS=-f elf64
ASSEMBLE=$(ASM) $(A_OPTS)
LINK=ld

all: chbase

debug: A_OPTS+=-g -F dwarf -dDEBUG
debug: chbase

.PHONY: test
test:


chbase: src.o
	$(LINK) $^ -o $@
	@rm -f *.o


src.o: src.asm
	$(ASSEMBLE) $< -o $@

