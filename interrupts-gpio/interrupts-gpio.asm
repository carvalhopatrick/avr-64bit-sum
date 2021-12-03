/*
 * interrupts-gpio
 *
 * Created: 02/12/2021
 * Author: Patrick Carvalho (carvalhopatrick)
 *
 */ 


#define __SFR_OFFSET 0
#include <avr/io.h>

	; Função main
	.org 0x00
	jmp main

	; ISR INT1 (relacionada ao PD3)
	.org 0x08
	jmp ISR_INT1

	; ISR PCI0 (relacionada ao PB1)
	.org 0x0C
	jmp ISR_PCI0

	; parâmetros de entrada para contagem do loop interno de delay
	.equ inner_val, 4999
	.equ outer_val, 41

main:
	cli 	; desativa interrupçoes

	; Inicialização da stack
	; útimo enderço da SRAM -> 0x08FF
	ldi R16, lo8(RAMEND) 
	out SPL, R16
	ldi R16, hi8(RAMEND)
	out SPH, R16

	; seta PB5 como saída
	sbi DDRB, 5
	;; registradores DDR já são configurados como entrada por padrão
	;; assim, não é preciso configurar PB1 e PD3

	; Configuração INT1 (PD3)
	;; seta bits 2 e 3 de EICRA, para selecionar interrupção na borda de subida
	ldi R16, (1<<2) | (1<<3)
	sts EICRA, R16
	;; seta bit 1 de EIMSK, para ativar interrupção INT1
	ldi R16, (1<<1)
	out EIMSK, R16


	; Configuração PCINT1 (PB1)
	;; seta bit 0 para ligar interrupção PCI0
	ldi R16, (1<<0)
	sts PCICR, R16
	;; seta bit 1 para ligar interrupção no PB1 (PCINT1)
	ldi R16, (1<<1)
	sts PCMSK0, R16 

	sei 	; ativa interrupções globalmente

; laço principal do programa (não faz nada, apenas aguarda interrupçoes)
loop:
	rjmp loop

; ISR da INT1 (PD3)
	; ativa ao detectar borda de subida em PD3
	; deve criar um pulso de 50ms em PB5
ISR_INT1:
	; guarda na pilha SREG
	; neste programa, não é necessário guardar demais registradores,
	; pois não usamos eles no loop principal. Assim, não é um problema
	; sobrescreve-los na subrotina.
	in R16, SREG
	push R16

	; ativa saída PB5 (nivel alto)
	sbi PORTC, 5
	; in R16, PORTB
	; ori PORTB, (1<<5)
	; out PORTC, R16

	; chama rotina de atraso
	rcall delay_50ms

	; após atraso, desativa saída PB5 (nível baixo)
	cbi PORTC, 5
	; in R16, PORTB
	; andi PORTB, ~(1<<5)
	; out PORTC, R16

	; retira SREG da pilha
	pop R16
	out SREG, R16

	; retorna para execução do programa (PC guardado na stack)
	reti
	

; ISR da PCI0 (PCINT1 -> PB1)
	; ativa ao detectar uma mudança na entrada de PB1
	; deve checar se a mudança é borda de descida
		; se sim, deve gerar um pulso de 100ms em PB5
ISR_PCI0:
	; guarda na pilha SREG
	; neste programa, não é necessário guardar demais registradores,
	; pois não usamos eles no loop principal. Assim, não é um problema
	; sobrescreve-los na subrotina.
	in R16, SREG
	push R16

	; checa se PB1 está em nivel baixo, indicando que de fato foi uma 
	; borda de descida.
	sbic PINB, 1	; pula próxima instrução se PB1 está cleared
	rjmp end_ISR_PCI0	; se PB1 está setada, a interrupção foi dada por uma 
						; borda de subida. Pula para o fim da rotina.

	; ativa saída PB5 (nivel alto)
	sbi PORTC, 5
	; in R16, PORTB
	; ori PORTB, (1<<5)
	; out PORTC, R16

	; chama rotina de atraso 2 vezes (para completar 100ms)
	rcall delay_50ms
	rcall delay_50ms

	; após atraso, desativa saída PB5 (nível baixo)
	cbi PORTC, 5
	; in R16, PORTB
	; andi PORTB, ~(1<<5)
	; out PORTC, R16

end_ISR_PCI0:
	; retira SREG da pilha
	pop R16
	out SREG, R16

	; retorna para execução do programa (PC guardado na stack)
	reti



; rotina para criar atraso de 50ms
; com 16 MHz, serão necessários aprox. 800.000 ciclos para tal atraso
delay_50ms:
	; valor para contagem do loop externo
	ldi R16, outer_val			; 1 ciclo
outer_loop:
	; decrementa contagem do loop externo
	dec R16						; 1 ciclo
	; pula para fim do loop caso contagem externa atingiu 0
	breq end_loop				; 2 ciclos se houver branch / 1 se não houver
	; carrega valor para contagem do loop interno (16 bits)
	ldi XL, lo8(inner_val)		; 1 ciclo
	ldi XH, hi8(inner_val)		; 1 ciclo
inner_loop:
	; decrementa 1 da contagem do loop interno
	sbiw XL, 1					; 2 ciclos
	; volta ao rótulo inner_loop se o operando não chegou em zero
	brne inner_loop				; 2 ciclos se houver branch / 1 se não houver
	; volta ao laço externo se contagem interna já zerou
	rjmp outer_loop				; 1 ciclo

end_loop:
	; fim da rotina, retorna ao PC guardado na stack
	reti						; 4 ciclos
	;;; total de ciclos medido pelo MPLAB X 
		; Stopwatch cycle count = 800051 (50,003187 ms)
