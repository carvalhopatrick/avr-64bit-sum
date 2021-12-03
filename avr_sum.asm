/*
 * AVR 64-bit sum
 *
 * Created: 31/05/2021
 * Author: Patrick Carvalho (carvalhopatrick)
 *
 * Program to sum or subtract two 64-bit integers,
 * with positive and negative overflow detection.
 *
 * p.s.: the comments in this source code refers to 
 * MSB as the most significant BYTE (not bit). Same for LSB.
 *
 */ 

.nolist			
.include "m328pdef.inc"
.list		

; 1st operand addr. (A): 	$1100
; 2nd operand addr. (B): 	$1200
; Result addr. (C):			$1300
; Operation selector addr.: $1000
	; (0x04 for sum and 0x02 for subtraction)
.equ AddrA  = 0x1100
.equ AddrB  = 0x1200
.equ AddrC  = 0x1300
.equ AddrOp = 0x1000

.dseg				; data segment

; reserves space for operands, operation and result
.org $1000
Operation:
    .byte 1 

.org $1100
OperandA:
    .byte 8 

.org $1200
OperandB:
    .byte 8 

.org $1300
OperandC:
    .byte 8 


.cseg				; code segment
.org	$0000		
rjmp main		


; start of the main program
main:
    cli     ; disables interrupt
    ; stack init
    ldi		R16,High(RAMEND)
    out		SPH,R16 ; MSB stack pointer
    ldi		R16,Low(RAMEND)
    out		SPL,R16 ; LSB stack pointer

    ; SRAM init

    ; loads 0x00 00 12 13 14 15 as A operand in R1-R8 (little endian)
    ldi		R16, 0xB8
    mov		R1, R16
    ldi		R16, 0xB7
    mov		R2, R16
    ldi		R16, 0xB6
    mov		R3, R16
    ldi		R16, 0xB5
    mov		R4, R16
    ldi		R16, 0x12
    mov		R5, R16
    ldi		R16, 0x13
    mov		R6, R16
    ldi		R16, 0x14
    mov		R7, R16
    ldi		R16, 0x15
    mov		R8, R16

    ; calls subroutine to store in SRAM
    ldi		XH, High(AddrA)
    ldi		XL, Low(AddrA)
    ldi 	YL,0x01		; R1 address (starting register)
    ldi 	YH,0x00		
    push 	YL
    push 	YH
    push 	XL
    push 	XH
    call 	copy_sram_regs

    ; loads 0xB1 B2 B3 B4 B5 B6 B7 B8 as B operand in R1-R8 (little endian)
    ldi		R16, 0xB8
    mov		R1, R16
    ldi		R16, 0xB7
    mov		R2, R16
    ldi		R16, 0xB6
    mov		R3, R16
    ldi		R16, 0xB5
    mov		R4, R16
    ldi		R16, 0xB4
    mov		R5, R16
    ldi		R16, 0xB3
    mov		R6, R16
    ldi		R16, 0xB2
    mov		R7, R16
    ldi		R16, 0xB1
    mov		R8, R16

    ; calls subroutine to store in SRAM
    ldi		XH, High(AddrB)
    ldi		XL, Low(AddrB)
    ldi 	YL,0x01		; R1 address (starting register)
    ldi 	YH,0x00		
    push 	YL
    push 	YH
    push 	XL
    push 	XH
    call 	copy_sram_regs

    ; stores operation selector for sum (0x04) or subtraction (0x02) into memory
    ldi		XH, High(AddrOp)
    ldi		XL, Low(AddrOp)
    ldi		R16, 0x04
    st		X, R16

    ; push arguments into stack and calls the main calculation subroutine
    push	R16 	; operation selector
    ldi		R16, Low(AddrC)		
    push	R16
    ldi		R16, High(AddrC)		
    push	R16
    ldi		R16, Low(AddrB)		
    push	R16
    ldi		R16, High(AddrB)		
    push	R16
    ldi		R16, Low(AddrA)		
    push	R16
    ldi		R16, High(AddrA)		
    push	R16
    call calculate

    ; end of the program
    end:
        rjmp end

copy_regs_sram:
    ; copies a 64 bit (8 bytes) value from memory into a set of 8 consecutive registers:
        
    ; input arguments: 
    ;	- initial address of the data in SRAM
    ;	- address of initial destination register

    ; *initial register must be below or equal to R17

    pop		R20		; pops PC (program counter) from stack
    pop		R19	
    pop		XH		; MSB of initial SRAM data address
    pop		XL		; LSB of initial SRAM data address
    pop		YH		; MSB of initial destination register address
    pop		YL		; LSB of initial destination register address
    push 	R19		; pushes PC back to stack
    push	R20	

    ld	R25, X+		; loads the last byte (little endian) of the data into R25 
    st	Y+, R25		; stores the first byte in the register pointed by Y
    ; repeats the process for the 7th, 6th, 5th, 4th, 3th, 2th and 1st byte:
    ld	R25, X+		; 7th
    st	Y+, R25
    ld	R25, X+		; 6
    st	Y+, R25	
    ld	R25, X+		; 5
    st	Y+, R25
    ld	R25, X+		; 4
    st	Y+, R25	
    ld	R25, X+		; 3
    st	Y+, R25
    ld	R25, X+		; 2
    st	Y+, R25	
    ld	R25, X+		; 1st
    st	Y+, R25

    ret             ; returns to the PC stored in stack

copy_sram_regs:
    ; copies a 64 bit (8 bytes) value from a set of consecutive registers to memory:
    
    ; input arguments: 
    ;	- initial source register address
    ;	- first destination memory address

    ; *initial register must be below or equal to R17

    pop		R20		; pops PC (program counter) from stack
    pop		R19	
    pop		XH		; MSB of initial destination SRAM data address
    pop		XL		; LSB of initial destination SRAM data address
    pop		YH		; MSB of initial source register address
    pop		YL		; LSB of initial source register address
    push 	R19		; pushes PC back to stack
    push	R20	

    ld	R25, Y+		; loads the last byte (little endian) of the data into R25 
    st	X+, R25		; stores the first byte in the register pointed by X
    ; repeats the process for the 7th, 6th, 5th, 4th, 3th, 2th and 1st byte:
    ld	R25, Y+		; 7th
    st	X+, R25	
    ld	R25, Y+		; 6
    st	X+, R25	
    ld	R25, Y+		; 5
    st	X+, R25	
    ld	R25, Y+		; 4
    st	X+, R25	
    ld	R25, Y+		; 3
    st	X+, R25	
    ld	R25, Y+		; 2
    st	X+, R25	
    ld	R25, Y+		; 1st
    st	X+, R25	

    ret             ; returns to the PC stored in stack



calculate:
    ; subroutine to sum or subtract two 64 bit integer values
    
    ; input arguments (in stack exit order): 
    ;	- A operand address
    ; 	- B operand address
    ;	- C address (where the result will be stored)
    ; 	- operation selection code (4 for sum // 2 for subtraction)

    ; in case there is a postive overflow, the value 0x08 will be written in the immeadiate memory position 
    ; after the result (C).

    ; in case there is a postive overflow, the value 0xFF will be written in the immeadiate memory position 
    ; after the result (C).

    pop		R20		; recovers PC, storing in R20 and R19
    pop		R19	
    pop		XH		; MSB address of operand A
    pop		XL		; LSB address of operand A
    pop		YH		; MSB address of operand B
    pop		YL		; LSB address of operand B
    pop		R25		; MSB address of result (C)
    pop		R24		; LSB address of result (C)
    pop		R23		; sum/subtraction selector code
    push 	R19		; pushes the return PC back to stack
    push	R20	

    ; algorithm:
        ; 1. checks if it should be a sum or subtraction
        ; 2. if subtraction, calls the two complement subroutine for operand B
        ; 3. load all operands (with copy_sram_regs)
        ; 4. do the sum
        ; 5. checks for overflow
        ; 6. stores the result (with copy_regs_sram)
        ; 7. storages overflow flag (if there is)

    ; 1. checks if it should be a sum or subtraction
    cpi		R23, 0x02
    brne	sum		; if R23 != 2, skips to the 4th step (sum)

    push 	R23			; stores the register in use into the stack
    push	R24
    push	R25
    push	YL
    push	YH
    push	XL
    push	XH
    push	YL			; stores Y (holding B operand address) into the stack as an input argument for complement2
    push	YH
    call    complement2	; calls the two complement subroutine for operand B
    pop		XH			; restores the registers saved into the stack
    pop		XL
    pop 	YH
    pop		YL			
    pop		R25
    pop		R24
    pop		R23

    sum:
    ; prepares operand A
    ldi 	R16, 0x00	; loads R0 address (which will be the initial register for operand A)
    ldi 	R17, 0x00
    push 	R23			; stores the registers in use into the stack
    push	R24
    push	R25
    push	YL
    push	YH
    push	XL
    push	XH
    push	R16
    push 	R17			; 1st input argument - initial destination register address
    push 	XL		    ; initial source memory address (operand A)
    push	XH
    call copy_regs_sram

    pop		XH			; restores the registers saved in the stack
    pop		XL
    pop 	YH
    pop		YL			
    pop		R25
    pop		R24
    pop		R23

    ; prepares B operand (same process)
    ldi 	R16, 0x08	; loads R8 address (which will be the initial register for operand B)
    ldi 	R17, 0x00
    push 	R23			; stores the registers in use into the stack
    push	R24
    push	R25
    push	YL
    push	YH
    push	XL
    push	XH
    push	R16
    push 	R17			; 1st input argument - initial destination register address
    push 	YL		    ; initial source memory address (operand B)
    push	YH
    call copy_regs_sram

    pop		XH			; restores the registers saved in the stack
    pop		XL
    pop 	YH
    pop		YL			
    pop		R25
    pop		R24
    pop		R23

    ; before the sum, the operands' signals should be stored, so we can check for overflow later.
    mov		R30, R7		; msbA
    andi	R30, 0x80	; R30 = 0x80 (negative A) or 0x00 (positive A)
    mov		R31, R15	; msbB
    andi	R31, 0x80	; R30 = 0x80 (negative B) or 0x00 (positive B)

    ; we now have A in R0-R8, and B in R8-R15 agora temos A em R0-R7 e B em R8-R15 (little endian). Let's sum!
    add 	r0, r8
    adc 	r1, r9		; adc is used so the carry from the last operation is also summed (if there is one)
    adc 	r2, r10
    adc 	r3, r11
    adc 	r4, r12
    adc 	r5, r13
    adc 	r6, r14
    adc 	r7, r15
    ; result is now in R0-R7

    ; 5. checks for overflow
    ldi 	R19, 0x00	; R19 will be the overflow flag
    mov		R18, R7		; copies the result's MSB to R18
    andi	R18, 0x80	; R18 == 0x80 (negative result) or 0x00 (positive result)

        ; if signal_A != sinal_B, there will never be overflow.
        ; skips to the result store label
    cp 		R31, R30
    brne 	store
    
        ; if the operands' signals are the same as the result, there was no overflow
    cp		R31, R18
    breq 	store
    
        ; from now on, it's certain that there was overflow.
        ; if the result's signal is postive, there was negative overflow
    cpi		R18, 0x00
    brne	over_positive   ; if not, skips to positive overflow label.
    ldi		R19, 0xFF	    ; negative overflow code = 0xFF
    jmp		store           ; skips to the result store label

    over_positive:
    ldi		R19, 0x08	    ; positive overflow code = 0x08

    ; stores the result in the C address
    store:
    push 	R19		; pushes the overflow code into the stack
    push 	R24		; LSB of the result destination address (C)
    push 	R25		; MSB of the result destination address (C)

    ldi 	R20, 0x00 ; LSB and also MSB of the initial register R0 (0x00)
    push	R20
    push	R20
    push	R24		; LSB result destination address (C)
    push	R25		; MSB result destination address (C)
    call copy_sram_regs

    pop		YH		; restores LSB of C
    pop		YL		; restores MSB of C
    pop		R19		; restores overflow code
    std		Y+8, R19	; stors overflow code after the result (address C+0x08)

    ret

complement2: 
    ; calculates the two's complement of a 64 bit signed integer
    
    ; input argument: memory address where the value is stored
    ; the complemented result will stored in the same address, overwriting the original value!

    pop 	R20		; pops PC
    pop 	R19
    pop		YH		; pop the address of the value to be complemented
    pop 	YL
    push 	R19
    push 	R20

    ldi 	XH, 0x00	; address of R1, which will be the initial register the operand will be loaded
    ldi 	XL, 0x01
    push 	YL			; stores Y into stack
    push 	YH

    push 	XL			; prepares arguments for the copy subroutine
    push 	XH
    push 	YL
    push 	YH
    call 	copy_regs_sram
    pop		YH			; restores Y
    pop 	YL

    ; complement every byte of the operand
    com 	R1
    com 	R2
    com 	R3
    com 	R4
    com 	R5
    com 	R6
    com 	R7
    com 	R8

    ; adds 1 to the operand
    ldi		R21, 1
    ldi		R22, 0
    add		R1, R21
    adc		R2, R22
    adc		R3, R22
    adc		R4, R22
    adc		R5, R22
    adc		R6, R22
    adc		R7, R22
    adc		R8, R22

    ; stores the complemented operand in its original address
    ldi		XH, 0x00	; input: initial register address
    ldi		XL, 0x01
    push	XL
    push	XH
    push	YL
    push	YH
    call copy_sram_regs

    ret    
