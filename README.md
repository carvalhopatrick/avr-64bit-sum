# avr_64bit_sum
An 8-bit AVR assembly program to sum or subtract two 64 bit integers stored memory. Made as an exercise to practice subroutines calling with parameters passed via stack.
Targets the ATMega328P MCU.

### Addresses and operands
- The **first operand** is stored at the 8 consecutive addresses starting at **$1100**.
- The **second operand** is stored at the 8 consecutive addresses starting at **$1200**.
- The **result** is stored at the 8 consecutive addresses starting at **$1300**.
- The **operation** byte is stored at **$1000**. It should be a 0x04 for sum and 0x02 for subtraction.

[Gerd's AVR Simulator](http://www.avr-asm-tutorial.net/avr_sim/index_en.html#download) was used to test the program.
