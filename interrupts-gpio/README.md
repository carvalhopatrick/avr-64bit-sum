# interrupts-gpio
An 8-bit AVR assembler program made as an exercise to learn to use external interrupts in assembly.
Targets the ATMega328P MCU.

- when an **rising edge** is detected in **PD3**, **INT1** interrupt will be triggered and a 50ms pulse will be outputted to **PB5**. 
- when and any change is detected in **PB1**, **PCINT1** interrupt will be triggered. The handler checks if it was a **falling edge**, and if true, a 100ms pulse will be outputted to **PB5**.


The program was compilled with Microchip's XC8.
