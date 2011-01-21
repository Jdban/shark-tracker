/////////////////////////////////////////////////////////////////////////
//
// File:	ivt_dspstak_sx2_zx2.asm
// Version:	1.00
// Build:	1.00
// Tools:	Visual DSP 4.0
//
//
// Date:	July 2006
//
// Author:	Danville Signal Processing, Inc.
//
// http://www.danvillesignal.com
//
/////////////////////////////////////////////////////////////////////////

//
// 21368 / 21369 Interrupt Vector Table
//
.extern _main;
.extern _timer_isr;


.section/pm seg_rth;



__EMUI:       // 0x00: Emulator interrupt (highest priority, read-only, non-maskable)
        nop;
        nop;
        nop;
        nop;
__RSTI:         // 0x04: Reset (read-only, non-maskable)
        nop;    // <-- (this line is not executed)
       jump _main;
        nop;
        nop;
__IICDI:        // 0x08: Illegal Input Condition Detected
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SOVFI:        // 0x0C: Status loop or mode stack overflow or PC stack full
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__TMZHI:        // 0x10: Core timer interrupt (higher priority option)
        nop;    // <-- (this line is not executed)
       jump _timer_isr;
        nop;
        nop;

__SPERRI:         // 0x14:
        jump (pc,0); jump (pc,0); jump (pc,0); jump (pc,0);

__BKPI:         // 0x18: Hardware breakpoint interrupt
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__res1I:         // 0x1C: (reserved)
        jump (pc,0); jump (pc,0); jump (pc,0); jump (pc,0);


__IRQ2I:        // 0x20: IRQ2 is asserted
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__IRQ1I:        // 0x24: IRQ1 is asserted
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__IRQ0I:        // 0x28: IRQ0 is asserted
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__DAIHI:        // 0x2C: DAI interrupt (higher priority option)
__P0I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SPIHI:
__P1I :          // 0x30: SPI transmit or receive (higher priority option)
__SPII :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__GPTMR0I:      // 0x34: General Purpose timer 0 interrupt
__P2I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SP1I:         // 0x38: SPORT 1 interrupt
__P3I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SP3I:         // 0x3C: SPORT 3 interrupt
__P4I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SP5I:         // 0x40: SPORT 5 interrupt
__P5I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SP0I:         // 0x44: SPORT 0 interrupt
__P6I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SP2I:         // 0x48: SPORT 2 interrupt
__P7I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SP4I:         // 0x4C: SPORT 4 interrupt
__P8I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__EP0I:     // 0x50: External port0 interrupt. Thats the only label we're using here
__P9I :

        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__GPTMR1I:      // 0x54: General Purpose timer 1 interrupt
__P10I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SP7I:         // 0x58: serial port 7 interrupt
__P11I :
        jump (pc,0); jump (pc,0); jump (pc,0); jump (pc,0);

__DAILI:        // 0x5C: DAI interrupt (lower priority option)
__P12I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__EP1I:         // 0x60: External port1 interrupt
__P13I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__DPII:         // 0x64: DPI interrupt
__P14I :
        jump (pc,0); jump (pc,0); jump (pc,0); jump (pc,0);

__MTMI:         // 0x68: Memory to Memory interface interrupt
__P15I :
        jump (pc,0); jump (pc,0); jump (pc,0); jump (pc,0);

__SP6I:         // 0x6C: serial port 6 interrupt
__P16I :
        jump (pc,0); jump (pc,0); jump (pc,0); jump (pc,0);

__GPTMR2I:      // 0x70: General Purpose timer 2 interrupt
__P17I :
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SPILI:        // 0x74: SPI transmit or receive (lower priority option)
__P18I :
__SPIBI:
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__CB7I:         // 0x78: Circular buffer 7 overflow exception
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__CB15I:        // 0x7C: Circular buffer 15 overflow exception
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__TMZLI:        // 0x80: Core timer interrupt (lower priority option)
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__FIXI:         // 0x84: Fixed-point overflow exception
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__FLTOI:        // 0x88: Floating-point overflow exception
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__FLTUI:        // 0x8C: Floating-point underflow exception
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);


__FLTII:        // 0x90: Floating-point invalid exception
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__EMULI:        // 0x94: Emulator low priority interrupt
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SFT0I:        // 0x98: User software interrupt 0
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SFT1I:        // 0x9C: User software interrupt 1
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SFT2I:        // 0xA0: User software interrupt 2
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);

__SFT3I:        // 0xA4: User software interrupt 3 (lowest priority)
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);
        jump (pc,0);


