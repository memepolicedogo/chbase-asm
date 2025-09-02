section .data 
	noArgsTxt:	db 'Too few args were passed, use -h for help',10
	noArgsLen:	equ $-noArgsTxt
	extraArgsTxt:	db 'Too many args were passed, use -h for help',10
	extraArgsLen:	equ $-extraArgsTxt
	badArgsTxt:	db 'Invalid option(s), use -h for help',10
	badArgsLen:	equ $-badArgsTxt
	badInputTxt:	db 'Invalid input, use -h for help',10
	badInputLen:	equ $-badInputTxt
	tooLargeTxt:	db 'Input is larger than 64 bit max int',10
	tooLargeLen:	equ $-tooLargeTxt
	badCustomTxt:	db 'Custom bases must be decimal integers between 2-36',10
	badCustomLen:	equ $-badCustomTxt
	helpTxt:
		db 'Standard usage: chbase -<bases> input',10
		db 'Custom usage: chbase <input_base> <output_base> input',10
		db 'Converts a number into a different number system',10
		db 'Given number must be an unsigned interger between 0-2^64',10
		db 10
		db 'Options:',10
		db 9,'D',9,'Decimal input',10
		db 9,'d',9,'Decimal output',10
		db 9,'B',9,'Binary input',10
		db 9,'b',9,'Binary output',10
		db 9,'H',9,'Hexadecimal input',10
		db 9,'h',9,'Hexadecimal output',10
		db 9,'T',9,'Trinary input',10
		db 9,'t',9,'Trinary output',10
		db 9,'O',9,'Octal input',10
		db 9,'o',9,'Octal output',10
		db 10
		db 9,'-h',9,'Display this help message and exit',10
		db 'Custom bases must be decimal integers between 0-36',10
		db 10
	helpLen:	equ $-helpTxt
	newline:	db 10
section .bss
	argc		resq 1
	argv		resq 1
	input		resb 1
	output		resb 1
	inputBase	resq 1
	outputBase	resq 1
	buffer		resb 64
	
section .text

global _start
_start:
; Parse args, chbase [options] input
; -d: decimal output
; -D: decimal input
; -b: binary output
; -B: binary input
; -h: hex output
; -H: hex input
; -t trinary output
; -T trinary input
; -o octal output
; -O octal input
; e.g. chbase -Ot 6
; 20
; chbase -Db 1024
; 10000000000

;---ARGS---;
	pop	rax	; get arg count off the stack
	cmp	rax, 1	; check if only one arg is passed
	je	errNoArgs	; if so, error
	cmp	rax, 2
	je	printHelp
	cmp	rax, 3	; check if less than three args are passed
	jl	errBadArgs	; if so, error
	mov	[argc], rax	; store arg count for later
	pop	rax		; get arg address off the stack
	mov	[argv], rax	; store for later
firstArgItr:	; get to the options
	inc	rax		; get next char of the arg
	cmp	byte [rax], 0		; check if it is null seperator
	jne	firstArgItr	; if not, repeat

parseArgs:
	cmp	qword [argc], 3	; Check if 3 args are passed
	je	stdArgs		; Parse the standard way
	cmp	qword [argc], 4	; Check if 4 args are passed
	je	customArgs	; Parse with custom base
	jne	errExtraArgs

customArgs:
	inc	rax	; pass the null seperator
	; Check if the input is a valid int
	cmp	byte [rax], 48
	jl	errBadCustom
	cmp	byte [rax], 57
	jg	errBadCustom

	mov	r10b, [rax]	; Get the first place
	sub	r10b, 48	; Convert ascii to int
	inc	rax		; Get the next char
	mov	qword [inputBase], r10; Store our base as it stands
	cmp	byte [rax], 0	; Check if input is one char
	je	customOutput

	; Check if next char is a valid number
	cmp	byte [rax], 48
	jl	errBadCustom
	cmp	byte [rax], 57
	jg	errBadCustom

	mov	r11b, [rax]	; Get the second place
	sub	r11b, 48	; Convert ascii to int
	mov	[argv], rax	; Store our place in memory
	mov	rax, r10	; Move 10s place to RAX for multiplication
	mov	rbx, 10		; Store multiplier
	mul	rbx		; Multiply rax by 10
	add	rax, r11	; add 1s place to 10s place
	; Clear our temp registers
	xor	r10, r10
	xor	r11, r11
	; Check that the base is ok for printing
	cmp	rax, 1
	jl	errBadCustom
	cmp	rax, 36
	jg	errBadCustom
	; Store base for conversion
	mov	qword [inputBase], rax
	mov	rax, [argv]
	inc	rax

customOutput:
	inc	rax
	; Check if the input is a valid int
	cmp	byte [rax], 48
	jl	errBadCustom
	cmp	byte [rax], 57
	jg	errBadCustom

	mov	r10b, [rax]	; Get the first place
	sub	r10b, 48	; Convert ascii to int
	inc	rax		; Get the next char
	mov	qword [outputBase], r10; Store out base as it stands
	cmp	byte [rax], 0	; Check if input is one char
	je	customEnd

	; Check if next char is a valid number
	cmp	byte [rax], 48
	jl	errBadCustom
	cmp	byte [rax], 57
	jg	errBadCustom

	mov	r11b, [rax]	; Get the second place
	sub	r11b, 48	; Convert ascii to int
	mov	[argv], rax	; Store our place in memory
	mov	rax, r10	; Move 10s place to RAX for multiplication
	mov	rbx, 10		; Store multiplier
	mul	rbx		; Multiply rax by 10
	add	rax, r11	; add 1s place to 10s place
	; Clear our temp registers
	xor	r10, r10
	xor	r11, r11
	; Check that the base is ok for printing
	cmp	rax, 1
	jl	errBadCustom
	cmp	rax, 36
	jg	errBadCustom
	; Store base for conversion
	mov	qword [outputBase], rax
	mov	rax, [argv]	; Get back to our place
	inc	rax
	; Ensure that our output base is only 2 chars long
	cmp	byte [rax], 0
	jne	errBadCustom
	jmp	customEnd	; Call the function and let it all work
customEnd:
	dec	rax
	jmp	strToInt

	
stdArgs:	; parse standard options
	inc	rax	; get to the first char of the options
	cmp	byte [rax], 45	; check if it is a dash
	jne	errBadArgs
	inc	rax	; get first option
	cmp	byte [rax], 97	; check if lowercase or capital
	jge	outFirst
	jl	inFirst

outFirst:
	inc	rax
	cmp	byte [rax], 0
	je	printHelp
	dec	rax
	cmp	byte [rax], 122	; check if out of uppercase letter range
	jg	errBadArgs
	mov	r10b, [rax]
	mov	[output], r10b	; store output type
	inc	rax	; get next value
	cmp	byte [rax], 65	; check if in lowercase letter range
	jl	errBadArgs
	cmp	byte [rax], 90
	jg	errBadArgs
	mov	r10b, [rax]
	mov	[input], r10b
	jmp	convert

inFirst:
	cmp	byte [rax], 65	; check if in lowercase letter range
	jl	errBadArgs
	cmp	byte [rax], 90
	jg	errBadArgs
	mov	r10b, [rax]
	mov	[input], r10b
	inc	rax	; get next value
	cmp	byte [rax], 122	; check if out of uppercase letter range
	jg	errBadArgs
	cmp	byte [rax], 97
	jl	errBadArgs
	mov	r10b, [rax]
	mov	[output], r10b	; store output type
	jmp	convert

convert:	; choose which input to use
	mov	bl, [input]
	cmp	bl, 68
	je	decimalI
	cmp	bl, 66
	je	binaryI
	cmp	bl, 84
	je	trinaryI
	cmp	bl, 72
	je	hexI
	cmp	bl, 79
	je	octalI


decimalI:
	mov	qword [inputBase], 10
	jmp	outputCheck
binaryI:
	mov	qword [inputBase], 2
	jmp	outputCheck
trinaryI:
	mov	qword [inputBase], 3
	jmp	outputCheck
hexI:
	mov	qword [inputBase], 16
	jmp	outputCheck
octalI:
	mov	qword [inputBase], 8
	jmp	outputCheck


outputCheck:
	mov	bl, [output]
	cmp	bl, 100
	je	decimalO
	cmp	bl, 98
	je	binaryO
	cmp	bl, 116
	je	trinaryO
	cmp	bl, 104
	je	hexO
	cmp	bl, 111
	je	octalO


decimalO:
	mov	byte [outputBase], 10
	jmp	strToInt
binaryO:
	mov	byte [outputBase], 2
	jmp	strToInt
trinaryO:
	mov	byte [outputBase], 3
	jmp	strToInt
hexO:
	mov	byte [outputBase], 16
	jmp	strToInt
octalO:
	mov	byte [outputBase], 8
	jmp	strToInt



strToInt:
	; r8:  argv
	; r9b: char
	; rax: sum
	; rbx: base
	; rdx: overflow
	; Set all of our working registers to the proper value
	mov	r8, rax
	inc	r8
	xor	r9, r9
	xor	rax, rax
	mov	rbx, [inputBase]
	xor	rdx, rdx
convertItr:
	inc	r8		; Get next char
	mov	r9b, [r8]	; store char
	cmp	r9b, 0		; check if null end of args
	je	intToStr	; if so we have the int
	mul	rbx		; multipy by our base
	cmp	rdx, 0		; If the result is larger than 2^64, return an error
	jne	errBadInput
	cmp	r9b, 48
	jl	errBadInput
	cmp	r9b, 57		; is a char  '0-9'
	jle	convertDigit
	cmp	r9b, 65
	jl	errBadInput
	cmp	r9b, 90		; is a char 'A-Z'
	jl	convertUpper
	cmp	r9b, 97
	jl	errBadInput
	cmp	r9b, 122
	jg	errBadInput
	jmp	convertLower	; is a char 'a-z'

convertDigit:
	sub	r9b, 48
	cmp	r9, rbx
	jge	errBadInput
	add	rax, r9
	jmp	convertItr

convertLower:
	sub	r9b, 87
	cmp	r9, rbx
	jge	errBadInput
	add	rax, r9
	jmp	convertItr

convertUpper:
	sub	r9b, 55
	cmp	r9, rbx
	jge	errBadInput
	add	rax, r9
	jmp	convertItr


intToStr:
	; improvement
	; divide by base, store remainder, continue
	
	mov	r9b, [outputBase]; store the base we need to output
	mov	r10, buffer+64	; last byte of the buffer
loop:
	dec	r10
	div	r9
	mov	[r10], dl
	xor	rdx, rdx
	cmp	rax, 0
	jne	loop
	jmp	print


print:
	xor	r8, r8
	xor	r11, r11
printItr:
	cmp	r11, 64
	je	printExit
	mov	rax, buffer
	add	rax, r11
	mov	r8b, [rax]
	inc	r11
	cmp	r8w, 0
	je	printItr
	cmp	r8b, 10
	jl	printDigit
	jge	printChar
printDigit:
	mov	r8w, 256
	add	byte [rax], 48
	jmp	printItr

printChar:
	mov	r8w, 256
	add	byte [rax], 55
	jmp	printItr



printExit:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, buffer
	mov	rdx, 64
	syscall

	mov	rax, 1
	mov	rdi, 1
	mov	rsi, newline
	mov	rdx, 1
	syscall

	jmp	exit

;---ERROR--;
errNoArgs:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, noArgsTxt
	mov	rdx, noArgsLen
	syscall

	jmp exit
errExtraArgs:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, extraArgsTxt
	mov	rdx, extraArgsLen
	syscall


	jmp exit
errBadArgs:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, badArgsTxt
	mov	rdx, badArgsLen
	syscall


	jmp exit
errBadInput:
	cmp	rbx, 16
	jne	awql
	cmp	byte [r8], 120
	je	convertItr
awql:	
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, badInputTxt
	mov	rdx, badInputLen
	syscall


	jmp exit
errTooLarge:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, tooLargeTxt
	mov	rdx, tooLargeLen
	syscall


	jmp exit

errBadCustom:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, badCustomTxt
	mov	rdx, badCustomLen
	syscall

	
	jmp exit

printHelp:
	mov	rax, 1
	mov	rdi, 1
	mov	rsi, helpTxt
	mov	rdx, helpLen
	syscall
	jmp exit

exit:
	mov	rax, 60
	mov	rdi, 0
	syscall
