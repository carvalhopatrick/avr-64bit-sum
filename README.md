# avr-64bit-sum
An AVR assembler program to sum or subtract two 64 bit integers stored in memory. Made as an exercise mainly to practice calling subroutines with parameters passed via stack, and loading/storing to SRAM.
Targets the ATMega328P MCU.

### Addresses and operands
- The **first operand** is stored in the 8 consecutive addresses starting at **$1100**.
- The **second operand** is stored in the 8 consecutive addresses starting at **$1200**.
- The **result** is stored in the 8 consecutive addresses starting at **$1300**.
- The **operation** byte is stored at **$1000**. It should be a 0x04 for sum and 0x02 for subtraction.

[Gerd's AVR Simulator](http://www.avr-asm-tutorial.net/avr_sim/index_en.html#download) was used to test the program.

---

# interrupts-gpio
An AVR assembler program made as an exercise to learn to use external interrupts and read/write to GPIO in assembly.
Targets the ATMega328P MCU.

- when a **rising edge** is detected in **PD3**, **INT1** interrupt will be triggered and a 50ms pulse will be output to **PB5**. 
- when and any change is detected in **PB1**, **PCINT1** interrupt will be triggered. The handler checks if it was a **falling edge**, and if true, a 100ms pulse will be output to **PB5**.



