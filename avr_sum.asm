; Programa para soma/subtração de dois inteiros de 64 bits
; EA869
; Patrick Penacho Carvalho

.nolist			
.include "m328pdef.inc"
.list		

; End. do parâmetro A: $1100
; End. do parâmetro B: $1200
; End. do parâmetro C: $1300   (resultado)
; End. da operação: $1000
.equ EndA = 0x1100
.equ EndB = 0x1200
.equ EndC = 0x1300
.equ EndOp = 0x1000

.dseg				; indica segmento de dados

.org $05C0 ; exemplo que deve ser adaptado para seu RA
Operacao:
	.byte 1 ; byte com o parâmetro de operação

.org $05D0 ; exemplo que deve ser adaptado para seu RA
ParamA:
	.byte 8 ; bytes do parâmetro A -> RA precedido de zeros

.org $05E0 ; exemplo que deve ser adaptado para seu RA
ParamB:
	.byte 8 ; bytes do parâmetro B 

.org $05F0 ; exemplo que deve ser adaptado para seu RA
ParamC:
	.byte 8 ; reserva bytes para o parâmetro C (resultado)


.cseg				; indica segmento de código
.org	$0000		; indica o endereço onde começará o seg. de código
rjmp Principal		; primeiro endereço deve ter jump para início do código


; início do programa principal
Principal:
	cli
	ldi		R16,High(RAMEND)
	out		SPH,R16 ; inicie o MSB do stack pointer
	ldi		R16,Low(RAMEND)
	out		SPL,R16 ; inicie o LSB do stack pointer

	; inicialização da SRAM

	; carrega 0x0000000000178460 como parametro A, em little endian, nos regs R1-R8
	ldi		R16, 0x00
	mov		R1, R16
	ldi		R16, 0x00
	mov		R2, R16
	ldi		R16, 0x00
	mov		R3, R16
	ldi		R16, 0x00
	mov		R4, R16
	ldi		R16, 0x00
	mov		R5, R16
	ldi		R16, 0x17
	mov		R6, R16
	ldi		R16, 0x84
	mov		R7, R16
	ldi		R16, 0x60
	mov		R8, R16

	; coloca na memoria usando subrotina
	ldi		XH, High(EndA)
	ldi		XL, Low(EndA)
	ldi 	YL,0x01		; coloca endereço de R1 em Y
	ldi 	YH,0x00		
	push 	YL
	push 	YH
	push 	XL
	push 	XH
	call 	copiar_mem_regs

	; carrega 0xB1B2B3B4B5B6B7B8 como parametro B, em little endian, nos regs R1-R8
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

	; coloca na memoria usando subrotina
	ldi		XH, High(EndB)
	ldi		XL, Low(EndB)
	ldi 	YL,0x01		; coloca endereço de R1 em Y
	ldi 	YH,0x00		
	push 	YL
	push 	YH
	push 	XL
	push 	XH
	call 	copiar_mem_regs

	; carrega código de soma (0x04) ou subtracao (0x02) e coloca na memoria
	ldi		XH, High(EndOp)
	ldi		XL, Low(EndOp)
	ldi		R16, 0x04
	st		X, R16

	; prepara pilha e chama rotina de calculo de soma/subtração
	push	R16 	; código de operacao
	ldi		R16, Low(EndC)		
	push	R16
	ldi		R16, High(EndC)		
	push	R16
	ldi		R16, Low(EndB)		
	push	R16
	ldi		R16, High(EndB)		
	push	R16
	ldi		R16, Low(EndA)		
	push	R16
	ldi		R16, High(EndA)		
	push	R16
	call calcula

	; fim do programa
	loop:
		rjmp loop

copiar_regs_mem:
	; subrotina para copiar um valor de 64 bits a partir da memória para um conjunto de registradores consecutivos:
		
	; . parâmetros de entrada: 
	;	- endereço inicial dos dados na memória de dados 
	;	- endereço do registrador inicial onde os dados serão copiados

	; *registrador inicial deve ser abaixo ou igual a R17, para não interferir no funcionamento desta própria subrotina

	pop		R20		; recupera PC, guardando em R20 e R19
	pop		R19	
	pop		XH		; MSB do endereço inicial dos dados na memoria de dados
	pop		XL		; LSB do endereço inicial dos dados na memoria de dados
	pop		YH		; MSB do endereço do registrador inicial destino na memoria de dados
	pop		YL		; LSB do endereço do registrador inicial destino na memoria de dados
	push 	R19		; salva endereço de retorno na pilha
	push	R20	

	ld	R25, X+		; carrega em R25 o ultimo byte (little endian) do valor
	st	Y+, R25		; guarda no reg. apontado por Y o primeiro byte
	; repete processo para 7º, 6º, 5º, 4º, 3º, 2º e 1º byte:
	ld	R25, X+		; 7º
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
	ld	R25, X+		; 1º
	st	Y+, R25

	ret

copiar_mem_regs:
	; subrotina para copiar um valor de 64 bits a partir de um conjunto de 
	; registradores consecutivos do microcontrolador para uma posição de memória:
	
	; . parâmetros de entrada: 
	;	- endereço do registrador inicial de origem dos dados
	;	- endereço da memória para onde os conteúdos serão copiados

	; *registrador inicial deve ser abaixo ou igual a R17, para não interferir no funcionamento desta própria subrotina

	pop		R20		; recupera PC, guardando em R20 e R19
	pop		R19	
	pop		XH		; MSB do endereço inicial destino na memoria de dados
	pop		XL		; LSB do endereço inicial destino na memoria de dados
	pop		YH		; MSB do endereço do registrador inicial origem na memoria de dados
	pop		YL		; LSB do endereço do registrador inicial origem na memoria de dados
	push 	R19		; salva endereço de retorno na pilha
	push	R20	

	ld	R25, Y+		; carrega byte do registrador inicial apontado por Y (ultimo byte do valor little endian)
	st	X+, R25		; guarda em end. de memoria apontado por X o byte carregado
	; repete para bytes restantes
	ld	R25, Y+		; 7º
	st	X+, R25	
	ld	R25, Y+		; 6º
	st	X+, R25	
	ld	R25, Y+		; 5º
	st	X+, R25	
	ld	R25, Y+		; 4º
	st	X+, R25	
	ld	R25, Y+		; 3º
	st	X+, R25	
	ld	R25, Y+		; 2º
	st	X+, R25	
	ld	R25, Y+		; 1º
	st	X+, R25	

	ret



calcula:
	; subrotina para somar ou subtrair dois valores inteiros de 64 bits com sinal:
	
	; . parâmetros de entrada (em ordem de saída da pilha): 
	;	- endereço do operando A
	; 	- endereço do operando B
	;	- endereço C onde o resultado deverá ser guardado
	; 	- código que indica é para fazer soma (código 4) ou subtração (código 2);

	; . caso a operação resulte em overflow positivo, o valor inteiro 8 deve ser escrito em uma posição 
	; de memória imediatamente após o local onde o resultado for guardado;

	; . caso a operação resulte em overflow negativo, o valor inteiro 0xFF deve ser escrito em uma 
	; posição de memória imediatamente após o local onde o resultado for guardado;

	pop		R20		; recupera PC, guardando em R20 e R19
	pop		R19	
	pop		XH		; MSB do endereço do operando A
	pop		XL		; LSB do endereço do operando A
	pop		YH		; MSB do endereço do operando B
	pop		YL		; LSB do endereço do operando B
	pop		R25		; MSB do endereço destino do resultado
	pop		R24		; LSB do endereço destino do resultado
	pop		R23		; codigo de soma/subtração
	push 	R19		; salva endereço de retorno na pilha
	push	R20	

	; algoritmo do restante desta rotina:
		; verificar se é soma ou subtração
		; chamar rotina de complemento caso subtração
		; carregar operandos (com a rotina copiar_mem_regs)
		; fazer a soma
		; verificar overflow
		; guardar resultado (com rotina copiar_regs_mem)
		; guardar codigo overflow (se houver)

	; verificação de soma/subtração
	cpi		R23, 0x02
	brne	soma		; se R23 != 2, pula direto para operação de soma

	push 	R23			; guarda registradores em uso na pilha
	push	R24
	push	R25
	push	YL
	push	YH
	push	XL
	push	XH
	push	YL			; guarda Y (endereço do operando B) na pilha para uso na rotina
	push	YH
	call    complementa2	; pula para rotina de complemento de 2 para o operando B
	pop		XH			; recupera registradores salvos na pilha
	pop		XL
	pop 	YH
	pop		YL			
	pop		R25
	pop		R24
	pop		R23

	soma:
	; prepara operando A
	ldi 	R16, 0x00	; carrega endereço do R0 (que será o registrador inicial do operando A)
	ldi 	R17, 0x00
	push 	R23			; guarda registradores em uso na pilha
	push	R24
	push	R25
	push	YL
	push	YH
	push	XL
	push	XH
	push	R16
	push 	R17			; endereço do reg destino inicial
	push 	XL		; endereço do operando
	push	XH
	call copiar_regs_mem

	pop		XH			; recupera registradores salvos na pilha
	pop		XL
	pop 	YH
	pop		YL			
	pop		R25
	pop		R24
	pop		R23

	; prepara operando B (mesmo processo)
	ldi 	R16, 0x08	; carrega endereço do R8 (que será o registrador inicial do operando B)
	ldi 	R17, 0x00
	push 	R23			; guarda registradores em uso na pilha
	push	R24
	push	R25
	push	YL
	push	YH
	push	XL
	push	XH
	push	R16
	push 	R17			; endereço do reg destino inicial
	push 	YL		; endereço do operando
	push	YH
	call copiar_regs_mem

	pop		XH			; recupera registradores salvos na pilha
	pop		XL
	pop 	YH
	pop		YL			
	pop		R25
	pop		R24
	pop		R23

	; antes de somar, copiaremos os sinais dos operandos para verificação de overflow
	mov		R30, R7		; msbA
	andi	R30, 0x80	; R30 = 0x80 (A negativo) ou 0x00 (A positivo)
	mov		R31, R15	; msbB
	andi	R31, 0x80	; R30 = 0x80 (B negativo) ou 0x00 (B positivo)

	; agora temos A em R0-R7 e B em R8-R15, faremos a soma (em little-endian)
	add 	r0, r8
	adc 	r1, r9		; soma com carry da operação anterior (se houver)
	adc 	r2, r10
	adc 	r3, r11
	adc 	r4, r12
	adc 	r5, r13
	adc 	r6, r14
	adc 	r7, r15
	; resultado em R0-R7

	; verificação de overflow
	ldi 	R19, 0x00	; inicia R19 para ser nosso codigo de overflow positivo ou negativo
	mov		R18, R7		; copia MSB do resultado para R18
	andi	R18, 0x80	; R18 == 0x80 (result negativo) ou 0x00 (result positivo)

		; se sinal_A != sinal_B nunca haverá overflow
	cp 		R31, R30
	brne 	guarda
	
		; se sinais dos operandos sao iguais ao do resultado, nao houve overflow
	cp		R31, R18
	breq 	guarda
	
		; a partir daqui, é certo que houve overflow.
		; se sinal do resultado for positivo, houve overflow negativo
	cpi		R18, 0x00
	brne	over_positivo
	ldi		R19, 0xFF	; codigo de overflow negativo
	jmp		guarda

	over_positivo:
	ldi		R19, 0x08	; codigo de overflow positivo

	; guarda resultado em endereço C
	guarda:
	push 	R19		; guarda codigo de overflow na pilha
	push 	R24		; guarda LSB endereço C
	push 	R25		; guarda MSB endereço C

	ldi 	R20, 0x00 ; MSB e também LSB do endereço do registrador inicial R0 (0x00)
	push	R20
	push	R20
	push	R24		; LSB do endereço destino do resultado
	push	R25		; MSB do endereço destino do resultado
	call copiar_mem_regs

	pop		YH		; recupera LSB do endereço C
	pop		YL		; recupera MSB do endereço C
	pop		R19		; recupera codigo de overflow
	std		Y+8, R19	; guarda codigo de overflow logo após o resultado (endereço C+8)

	ret

complementa2: 
	; subrotina para calcular o complemento de dois de um valor inteiro de 64 bits com sinal;
	
	; parâmetro de entrada: endereço onde está o dado a ser convertido; 
	; este também será o endereço onde será guardado o resultado da conversão;

	pop 	R20		; recupera PC, guardando em R20 e R19
	pop 	R19
	pop		YH		; recupera endereço do operando a ser complementado
	pop 	YL
	push 	R19
	push 	R20

	ldi 	XH, 0x00	; coloca endereço de R1 em X, para carregar o operando em R1-R8
	ldi 	XL, 0x01
	push 	YL			; guarda Y na pilha
	push 	YH

	push 	XL			; prepara entrada para rotina de copia
	push 	XH
	push 	YL
	push 	YH
	call 	copiar_regs_mem
	pop		YH			; recupera Y
	pop 	YL

	; complementa todo o operando
	com 	R1
	com 	R2
	com 	R3
	com 	R4
	com 	R5
	com 	R6
	com 	R7
	com 	R8

	; soma 1 ao operando 
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

	; guarda operando complementado no seu endereço original com subrotina
	ldi		XH, 0x00	; entrada: endereço do reg inicial
	ldi		XL, 0x01
	push	XL
	push	XH
	push	YL
	push	YH
	call copiar_mem_regs

	ret
