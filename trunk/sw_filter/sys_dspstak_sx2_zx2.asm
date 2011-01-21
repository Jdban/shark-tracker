/////////////////////////////////////////////////////////////////////////
//
// File:	sys_dspstak_sx2_zx2.asm
// Version:	1.01
// Build 	1.00
// Tools:	Visual DSP 4.5
//
// System Library
//
// Date:	September 2006
//
// Author:	Danville Signal Processing, Inc.
//
// http://www.danvillesignal.com
//
/////////////////////////////////////////////////////////////////////////

#if defined(__ADSP21375__)
#include <def21375.h>
#elif defined(__ADSP21369__)
#include <def21369.h>
#endif	

#include <SRU.h>
#include "sys_dspstak_sx2_zx2.h";
#include "signal_dspstak_sx2_zx2.h";

// global functions
.GLOBAL _init_ext_port;
.GLOBAL _sys_set_coreclock;
.GLOBAL _sys_assign_pins;

.GLOBAL _write_io_control_register;
.GLOBAL _set_io_control_register_bit;
.GLOBAL _clr_io_control_register_bit;

.GLOBAL _read_io_control_register;
.GLOBAL _read_sys_mode;
.GLOBAL _read_cts_value;

.GLOBAL _sys_force_delay;

.GLOBAL	_timer_isr;
.GLOBAL	_init_timer;
.GLOBAL _timer_1s;
.GLOBAL _timer_5us;

// global variables
.GLOBAL	_timer_ticks;						
.GLOBAL _io_control_register_A;					
.GLOBAL _io_control_register_B;					

.GLOBAL _sys_mode;
.GLOBAL _uart_cts_status;
.GLOBAL _uart_rts_status;

.GLOBAL _gp_io_0_dir;
.GLOBAL _gp_io_0_val;

.GLOBAL _gp_io_1_dir;
.GLOBAL _gp_io_1_val;

.GLOBAL _uart_rts_bit_status;
.GLOBAL _uart_cts_bit_status;

.GLOBAL _hi_speed_usb_reset_bit_status;
.GLOBAL _io_reset_bit_status;
.GLOBAL _clock_bank_switch_bit_status;

.GLOBAL _peripheral_control_status;		
.GLOBAL _spi_miso_enable_status;
.GLOBAL _declared_expansion_spi_ss;			

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	This code library incorporates majority of the support needed to manage a basic dspstak
//	engine specifically for the sx2 and zx2 family.  This library includes timer support,
//	sdram support and support for the external port.  The external port is a new feautre found
//	in the ADSP SHARC family and it is essentially a parallel bus interface and as an interface
//	it also part which manages the SDRAM controller.  In the dspstak design, it utilizes the
//	external port to control other devices and interfaces in the dspstak platform namely, the
//	DIN IO connections and in addition some bit control based pins connected to the control
//	mode configuration, usb, clock generator and the uart interfaces.  The functions to 
//	support these features are in this library.
//
//	Just as mentioned, the external port is used to control some bit based pins in the 
//	dspstak baseboard design.  There are primarily two registers associated with this feature.
//	The following macros have been provided and these macros are associated in handling 
//	bit control for system registers A and B.  The bit definitions for these two registers are
//	discussed in _init_ext_port.  For user to use the following macros, just copy the macro
//	and append a semicolon (;) after.  Further explanation of the control of these two
//	registers are discussed in the supporting subrotines.
//
//	For example, if I want to raise the reset line for the high speed usb chip do the following.
//	
//		SET_HI_SPEED_RESET_PIN;				
//
//	MACRO LIST
//
//   SET_DIN_IO_RESET	 			
//   CLR_DIN_IO_RESET				
//
//   SET_HI_SPEED_RESET_PIN 			
//   CLR_HI_SPEED_RESET_PIN 			
//				
//   SET_CLK_BANK_SWITCH				
//   CLR_CLK_BANK_SWITCH				
//
//   SET_RTS_BIT						
//   CLR_RTS_BIT						
//
//   SET_GP0_VAL_BIT					
//   CLR_GP0_VAL_BIT					
//					
//   SET_GP1_VAL_BIT					
//   CLR_GP1_VAL_BIT					
//							
//   SET_GP0_DIR_BIT					
//   CLR_GP0_DIR_BIT					
//		
//   SET_GP1_DIR_BIT					
//   CLR_GP1_DIR_BIT					
//
//   SET_SS0_MISO_ENA_BIT				
//   CLR_SS0_MISO_ENA_BIT				
//											
//   SET_SS1_MISO_ENA_BIT				
//   CLR_SS1_MISO_ENA_BIT				
//					
//   SET_SS2_MISO_ENA_BIT				
//   CLR_SS2_MISO_ENA_BIT				
//					
//   SET_SS3_MISO_ENA_BIT				
//   CLR_SS3_MISO_ENA_BIT				
//
//   SET_SS4_MISO_ENA_BIT				
//   CLR_SS4_MISO_ENA_BIT				
//										
//   SET_SS5_MISO_ENA_BIT				
//   CLR_SS5_MISO_ENA_BIT				
//
//   CLR_ALL_MISO_ENA_BITS
//
///////////////////////////////////////////////////////////////////////////////////////////////////////


.SECTION/DM seg_dmda;

.VAR	_timer_ticks[8];				// variable that is incremented by timer_isr	
										// user can use this as an independent timer variable

.VAR _io_control_register_A;			// contains the last transmitted value for reg A
.VAR _io_control_register_B;			// contains the last transmitted value for reg B

.VAR _sys_mode;
.VAR _uart_cts_status;
.VAR _uart_rts_status;

.VAR _gp_io_0_dir;
.VAR _gp_io_0_val;

.VAR _gp_io_1_dir;
.VAR _gp_io_1_val;

.VAR _uart_rts_bit_status;
.VAR _uart_cts_bit_status;

.VAR _hi_speed_usb_reset_bit_status;
.VAR _io_reset_bit_status;
.VAR _clock_bank_switch_bit_status;

.VAR _peripheral_control_status;		// This contains the 3 bits for the 
										// io_reset, hi_speed_usb_reset and clock_bank_switch
										// value the last time they are updated.
										// 	This is important to keep track so as not to have
										// any inadvertent toggling.

.VAR _spi_miso_enable_status;

.VAR _declared_expansion_spi_ss;		// will contain the value of which of the SSx/IOx
										// bits will be selected for spi slave selects

											
.SECTION/PM seg_pmda;

.SECTION/PM seg_pmco;


									

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_timer_isr
//
//	Notes:  Updates 8 timers approximately every 4 us (256kHz) 
//
//		_timer_ticks[0] = tick_sys	System tick - should be read but not reset
//		_timer_ticks[1] = tick_pm	Used by pm_21262sx	
//		_timer_ticks[2] = tick_wd	Used by watchdog
//		_timer_ticks[3] = tick_1s	1 second Timer	
//
//		_timer_ticks[4] = user_tick_1	These are useful as oneshot kernels
//		_timer_ticks[5] = user_tick_2
//		_timer_ticks[6] = user_tick_3
//		_timer_ticks[7] = user_tick_4	
//
//		Bit masks are useful for creating timers in binary sequences ( 4ms, 2ms, 1ms, 500us, 250us, 125us, etc)
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006
//
//	Calling parameters: 	_timer_ticks[8]
//
// 	Return value:			_timer_ticks[8]
//			
//	Modified registers:	i2, i3, r1, r2	(in the secondary register set)	
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_timer_isr:

	PUSH STS;
	BIT SET MODE1 SRD1L | SRD1H | SRD2L | SRD2H | SRRFL | SRRFH;
	NOP;
	
	i2 = _timer_ticks;
	i3 = _timer_ticks + 1;
	r1 = DM(i2,m5);
	r1 = r1 + 1 		,	r2 = DM(i3,m6);
	r2 = r2 + 1			, 	DM(i2,m6) = r1;
	r1 = DM(i3,m6);
	r1 = r1 + 1			, 	DM(i2,m6) = r2;
	r2 = DM(i3,m6);
	r2 = r2 + 1			,	DM(i2,m6) = r1;
	r1 = DM(i3,m6);
	r1 = r1 + 1			,	DM(i2,m6) = r2;
	r2 = DM(i3,m6);
	r2 = r2 + 1			,	DM(i2,m6) = r1;
	r1 = DM(i3,m6);
	r1 = r1 + 1			,	DM(i2,m6) = r2;
	r2 = DM(i3,m5);
	r2 = r2 + 1			,	DM(i2,m6) = r1;
	DM(i3,m5) = r2;
		
	POP STS;
	RTI;
	
_timer_isr.end:	

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_init_timer
//
//	Notes:  Initializes user timers which will interrupt every 4 us (256kHz).  The interrupt handler for 
//			the timer is _timer_isr. 
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006
//
//	Calling parameters: 	None
//
// 	Return value:			None
//			
//	Modified registers	:	TPERIOD, TCOUNT, IMASK, MODE2
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_init_timer:

	BIT SET IMASK TMZHI;				// Enable hi priority timer interrupt

	
	// The values for TPERIOD_VAL and TCOUNT_VAL have been calibrated with respect to the 
	// maximum value for the system core clock.  The values are used to have a 
	// 256 kHz clock/timer.
	
	TPERIOD = TPERIOD_VAL;		
	TCOUNT  = TCOUNT_VAL;				// The timer freq = 256kHz
		
	BIT SET MODE2 TIMEN;				// Enable timer 	
	
	RTS;
	
_init_timer.end:	
	

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_timer_1s
//
//	Notes:  Uses _timer_ticks[3] as a one shot 
//
//	If this function is called and 1 sec has elapsed, the timer is reset and r0
//	returns 1, else r0 returns 0, Status may also me checked (IF EQ or NE)
//
//	Written by Danville Signal Processing
//
//	Date:			    	September 2006 	
//
//	Calling parameters: 	None
//
// 	Return value:			r0
//			
//	Modified registers:		r0, r1;	
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_timer_1s:
	
	r1 = DM(TICK_1S);
	r1 = PASS r1;
	IF LT JUMP timer_1s_expired;	// tick has wrapped, therefore it has expired

	r0 = 0x0003E800;	
	
	COMP(r1,r0);
	IF GE JUMP timer_1s_expired;  		

timer_1s_still_counting:

	r0 = 0;
	r0 = PASS r0;
	RTS;	
	
timer_1s_expired:

	DM(TICK_1S) = m5;				// Set to 0
	r0 = 1;
	r0 = PASS r0;
	RTS;	

_timer_1s.end:	


///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_sys_set_coreclock
//
//	Notes:  
//		Modifies the core clock settings. 
//		For the dspstak sx2 and dspstak zx2, the DSP processors wakes up to 6 times the input clock.
//		Dependent on the values of r4 and r8, the  core clock speed is changed.
//	
//	Written by Danville Signal Processing
//
//	Date:		September 2006
//
//	Calling parameters: 	
//				r4 = PLLD	(Divisor. 
//				r8 = PLLM	(Multiplier)
//		
//				ADSP-21369 Settings: r4,r8 = 2,30 since 22.1184 * 15 
//				ADSP-21375 Settings: r4,r8 = 2,23 since 22.1184 * 11.5
//
// 	Return value:		None
//			
//	Modified registers:	ustat1, r0, lcntr
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_sys_set_coreclock:


	ustat1 = DM(PMCTL);
	BIT CLR ustat1 PLLM63;			// clear all multiplier and 
	BIT CLR ustat1 PLLD8;			// divider bits
	BIT CLR ustat1 INDIV;			// clear input divider
	BIT SET ustat1 DIVEN;			// setting divider
	

// Set the Core clock (CCLK) to SDRAM clock (SDCLK) ratio to 2.5
#if defined(__ADSP21369__)

// Danville dspstak zx2 has the ADSP-21369 interfaced to a SDRAM;
// thus the two lines have to be inserted in the process.
	BIT CLR ustat1 SDCKR2 | SDCKR2_5 | SDCKR3 | SDCKR3_5 | SDCKR4;
 	BIT SET ustat1 SDCKR2_5;
 	
#endif

   	r0 = ustat1;
	r0 = r0 OR r4;					// set PLL divisor
	r0 = r0 OR r8;					// set PLL multiplier
	DM(PMCTL) = r0;				  	// write to PMCTL control register

	// Setup Core Clock PLL
	ustat1 = DM(PMCTL);
	BIT SET ustat1 PLLBP;			// put PLL in Bypass
	BIT CLR ustat1 DIVEN;			// turn off divider
	DM(PMCTL) = ustat1;				// reference ADI appnote EE-290
	
	r0 = 5000; 						// wait for PLL to lock at new rate
	LCNTR = r0, DO _pllwait until LCE;
_pllwait:	NOP;
	  

	ustat1 = DM(PMCTL);				// take PLL out of Bypass
	BIT CLR ustat1 PLLBP;
	DM(PMCTL) = ustat1;
	
	RTS;
_sys_set_coreclock.end:


///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_init_ext_port
//
//	Notes:  Initializes the external port connections.  The external port for the ADSP-21369 and 
//			ADSP-21375 can be used to inteface to parallel data based devices.  This port is also
//			used to inteface to SDRAM devices.  
//	
//			Both dspstak sx2 and zx2 engines utilizes the AMI (asynchronous memory interface) bank 2
//			to interface to two (2) registers corresponding to io_control_registers A and B discussed below.
//
//			For the zx2 DSP engines, a SDRAM is also initialized.  This SDRAM interface is assigned to
//			to bank 0.
//
//	Notes for io_control_registers A and B
//
//	The pld, where the registers A and B is mapped to /MS2,
//	which corresponds to Bank 2.  
//
//	Bank 2 according to the ADI manual has an address range from 
//	0x08000000 - 0x08FFFFFF.  It does not really matter what address you 
// 	use since there are only two registers in the pld and they are only 
// 	separated by A0.  All read writes are only 8 bit significant
//
//	Register A A0 = 0
//  Writes
//		D0 - status of IO Reset DIN 15 b
//		D1 - status of high speed usb reset pin
//		D2 - status of S2 pin for cypress clock generator
//		D3 - RTS line at uart interface
//		D4 - GP0 value
//		D5 - GP0 tri-tate enable value
//		D6 - GP1 value
//		D7 - GP1 tri-state enable value
//
//	Reads
//		D0 - MODE 0 
//		D1 - MODE 1
//		D2 - MODE 2
//		D3 - CTS line at uart interface
//		D4 - GP0 value
//		D5 - GP0 tri-tate enable value
//		D6 - GP1 value
//		D7 - GP1 tri-state enable value
//
//	Register B A0 = 1
//  Writes
//		D0 - SS0 enable for MISO return 
//		D1 - SS1 enable for MISO return 
//		D2 - SS2 enable for MISO return 
//		D3 - SS3 enable for MISO return 
//		D4 - SS4 enable for MISO return 
//		D5 - SS5 enable for MISO return 
//		D6 - NC
//		D7 - NC
//
//	Reads
//		D0 - status of SS0 enable for MISO return 
//		D1 - status of SS1 enable for MISO return 
//		D2 - status of SS2 enable for MISO return 
//		D3 - status of SS3 enable for MISO return 
//		D4 - status of SS4 enable for MISO return 
//		D5 - status of SS5 enable for MISO return 
//		D6 - LOW
//		D7 - LOW
//
//	Revision:  Modified register usage in order to comply to C rules.
//
//	Written by Danville Signal Processing
//
//	Date:			    	September 2006
//
//	Calling parameters: 	none
//
// 	Return value:			none
//			
//	Modified registers:		r4, ustat1, ustat2
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_init_ext_port:
	
// Clear all bits significant registers associated to the ext port of the dspstak
	DM(EPCTL) = m5;
	DM(AMICTL2) = m5;
	DM(SDCTL) = m5;
    DM(SDRRC) = m5;

init_pld_register_connection:
// configure bank 2 which is connected to the pld
// settings are done with the slowest settings
//
//	AMIEN -- Asynchronous memory interface enable
//	BW32 -- Bus width 32 bit
//	PKDIS -- data packing disabled
//	WS31 -- wait states 31, I think we can go lower with this value
//	IC7  -- 7 bus idle cyle
//	HC2  -- 2 hold cycle 
//	RHC2 -- read hold cycle
//
//  Values used are subject to change until other external port based
//	peripherals are tested.  These peripherals are namely the SDRAM (@ bank 0)
//  and the high speed USB (@ bank 3).

	r4 = AMIEN | BW32 | PKDIS | WS31 |  IC7 | HC2 | RHC2;	// real slow
	DM(AMICTL2) = r4;
	
// Do not configure other banks
// This is subject to change
	DM(AMICTL0) = m5;
	DM(AMICTL1) = m5;
	DM(AMICTL3) = m5;
	
#if defined(__ADSP21369__)

//  Only the dspstak zx2 (with a dspblok) has the SDRAM feature interfaced with a ADSP-21369

	r4 = B0SD  | 	EPBRCORE ;	// declare that only bank 0 is sdram and bus priority is from core
	DM(EPCTL) = r4;
	
// Programming SDRAM control registers.
// RDIV = ((f SDCLK X t REF )/NRA) - (tRAS + tRP )

// CCLK_SDCLK_RATIO==2.5 for 333Mhz core with 166 SDRAM
//    ustat1 = 0xA17; // (166*(10^6)*64*(10^-3)/4096) - (7+3) = 2583
    
    
// CCLK_SDCLK_RATIO==2.5 for 333Mhz core with 143 SDRAM
    ustat1 = 0x8B1; // (143*(10^6)*64*(10^-3)/4096) - (6+3) = 2225

    //===================================================================
    //
    // Configure SDRAM Control Register (SDCTL) for the Micron MT48LC2M32
    //
    //  SDCL3  : SDRAM CAS Latency= 3 cycles
    //  DSDCLK1: Disable SDRAM Clock 1
    //  SDPSS  : Start SDRAM Power up Sequence
    //  SDCAW8 : SDRAM Bank Column Address Width= 8 bits 	--> 2^8 = 256
    //  SDRAW12: SDRAM Row Address Width= 11 bits			--> 2^11 = 2096
    //  SDTRAS6: SDRAM tRAS Specification. Active Command delay = 6 cycles
    //  SDTRP3 : SDRAM tRP Specification. Precharge delay = 3 cycles.
    //  SDTWR2 : SDRAM tWR Specification. tWR = 2 cycles.
    //  SDTRCD3: SDRAM tRCD Specification. tRCD = 3 cycles.
    //
    //--------------------------------------------------------------------

  	ustat2 = SDCL3|DSDCLK1|SDPSS|SDCAW8|SDRAW11|SDTRAS6|SDTRP3|SDTWR2|SDTRCD3;

    DM(SDCTL) = ustat2;
  
    DM(SDRRC) = ustat1;
  
#endif	

// After initialization clear out sys registers A and B
	SYS_REG_ADDR_A = m5; 
	SYS_REG_ADDR_B = m5;
	
	RTS;

_init_ext_port.end:


///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_sys_assign_pins
//
//	Notes:  Configures the SSx/IOx pins located in the dspstak sx2 zx2 DIN connector
//			These pins are located as follows with respect to the dspstak engine schematic.
//
//	possible pin combinations and din connections: 
//        SS5 or IO4 - select TYPE_SPI5 or TYPE_IO4  pin 11 A/C
//        SS4 or IO3 - select TYPE_SPI4 or TYPE_IO3  pin 10 B
//        SS3 or IO2 - select TYPE_SPI3 or TYPE_IO2  pin 10 A/C
//        SS2 or IO1 - select TYPE_SPI2 or TYPE_IO1  pin 9  B
//        SS1 or IO0 - select TYPE_SPI1 or TYPE_IO0  pin 9  A/C
//		
//			Do also keep in mind that the SS1 - SS5 are referred to the spi expansion 
//			spi slave selects.  There are other primary spi devices interfaced already
//			to the spi port / dspstak model namely for the flash, eeprom and the SPI_SS line.
//
//			If the din pins are used are as slave selects, they are assign as flags.
//			SS1 to SS4 are mapped to flags 4 to 7 via the dpi and SS5 is mapped to flag 0.
//			SS5/IO4 cannot be compromised because this is a hardwired and not software
//			configurable unlike the ones connected to the dpi.
//
//			It is important to note that flags 4 to 7 and flag 0 are used as the resources
//			to manipulate the IOx/SSx pins.
//
//	Revision: Modified regsiter usage in order to comply to C rules
//	
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	r4 = SPI or IO declaration	, if set pin is spi slave select
//														, if clear pin is IO
//							r8 = IO direction (only applicable to declared IO pins)					
//							(Use definitions declared at sys_dspstak_sx2_zx2.h)
//														, if set IO pin is output
//														, if clr IO pin is input
//
//	e.g. form 
//  	r4 = TYPE_SPI5 | TYPE_IO3  | TYPE_SPI3 | TYPE_IO1 | TYPE_IO0;
//		     11A -spi    10B -io     10A - spi   9B - io     9A - io
//
//		r8 = IO3_DIR_OUT   | IO1_DIR_IN   	| IO0_DIR_OUT;
//			 10B output      9B input          9A output
//
// 	Return value:			None
//			
//	Modified registers:		r0, r4 , r8 , r12, ustat1, FLAGS
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_sys_assign_pins:


    r12 = SYS_ASSIGN_MASK;        // a value that covers only necessary bits related to flag 0 and flags 4 to 7
    r12 = r12 AND r4;            // at this point r15 has a value that dictates the FLAGS output bits
                                // spi flags are naturally masters according to the dspstak model.
                           
    r0 = FLAGS;                    // get current    value of flag register
    r0 = r12 OR r0;                // bit set the direction bits
    r12 = LSHIFT r12 by -1;        // if spi slave selects also set flag value
                                // user can review the structure of
    r0 = r12 OR r0;                // bit set the value bits as default for the spi ss state

    DM(_declared_expansion_spi_ss) = r0;
   
   
    r12 = SYS_ASSIGN_MASK;        // a value that covers only necessary bits related to flag 0 and flags 4 to 7   
    r12 = r12 AND r8;            // r8 contains the flag direction bit mask
    r0 = r0 OR r12;           
   
    FLAGS = r0;                    // update flags register

// Now the flag register is set, it is necessary to connect the flags towards the dpi pins       

// First figure out the direction for each of the pin. Read bit from the
// flags register and then configure the dpi direction accordingly.
   
    ustat1 = FLAGS;   

config_io0_ss1_dpi_pin:

    SRU(LOW,DPI_PBEN08_I);                // assume dpi direction is input first
    SRU(DPI_PB08_O,FLAG4_I );
    BIT TST ustat1 IO0_SS1_FLAG_DIR;    // but if read bit is an output
    IF NOT TF JUMP config_io1_ss2_dpi_pin;
    SRU(HIGH,DPI_PBEN08_I);                // configure the dpi pin as output
    SRU(FLAG4_O, DPI_PB08_I);            // SS1 / IO0    dpi to din pin


config_io1_ss2_dpi_pin:

    SRU(LOW,DPI_PBEN04_I);                // assume dpi direction is input first
    SRU( DPI_PB04_O,FLAG5_I);    // SS2 / IO1    dpi to din pin

    BIT TST ustat1 IO1_SS2_FLAG_DIR;    // but if read bit is an output
    IF NOT TF JUMP config_io2_ss3_dpi_pin;
    SRU(HIGH,DPI_PBEN04_I);                // configure the dpi pin as output
    SRU(FLAG5_O, DPI_PB04_I);    // SS2 / IO1    dpi to din pin

config_io2_ss3_dpi_pin:
   
    SRU(LOW,DPI_PBEN13_I);                // assume dpi direction is input first
    SRU(DPI_PB13_O, FLAG6_I);
    BIT TST ustat1 IO2_SS3_FLAG_DIR;    // but if read bit is an output
    IF NOT TF JUMP config_io3_ss4_dpi_pin;   
    SRU(HIGH,DPI_PBEN13_I);                // configure the dpi pin as output
    SRU(FLAG6_O, DPI_PB13_I);    // SS3 / IO2    dpi to din pin


config_io3_ss4_dpi_pin:

    SRU(LOW,DPI_PBEN14_I);                // assume dpi direction is input first
   SRU( DPI_PB14_O, FLAG7_I);    			// SS4 / IO3    dpi to din pin
    BIT TST ustat1 IO3_SS4_FLAG_DIR;    // but if read bit is an output
    IF NOT TF JUMP connect_flag_pin_values;
    SRU(HIGH,DPI_PBEN14_I);                // configure the dpi pin as output
   SRU(FLAG7_O, DPI_PB14_I);    // SS4 / IO3    dpi to din pin

connect_flag_pin_values:



 

// After all the necessary dpi pins have been initialized update FLAGS
    r4 = DM(_declared_expansion_spi_ss) ;
    FLAGS = r4;                            // update flags register

    RTS;
	
_sys_assign_pins.end:

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_sys_force_delay
//
//	Notes:  Inserts a loop delay proportional to the value of r4. This subroutine is handy for inserting
//			delay during initialization routines.
//	
//	Written by Danville Signal Processing
//
//	Date:					September 2006
//
//	Calling parameters: 	r4 = number of loop cycle delays
//
// 	Return value:			None
//			
//	Modified registers:		lcntr
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_sys_force_delay:

	LCNTR = r4;
	DO forced_delay_loop UNTIL LCE;
forced_delay_loop: NOP;

	RTS;
_sys_force_delay.end:


///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_write_io_control_register
//
//	Notes:  Performs an external port write to one of two memory mapped registers found in bank 2 of 
//			AMI port.  The bit definitions for the two registers are discussed in the comment section
//			for _init_ext_port. After writing the value to the physical register a set of shadow variables
//			are updated for tracking.
//
//	Revision:  Modified register usage to comply to C rules
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	r4 = 0 for reg A or 1 for reg B
//							r8 = new byte value for register
//
// 	Return value:			Set of updated bit status and word status
//							variables that can be used to keep track of
//							transfers to reg A and B.
//						
//							Reg A
//								_io_reset_bit_status
//								_hi_speed_usb_reset_bit_status
//								_clock_bank_switch_bit_status
//								_peripheral_control_status  (combination of 
//															_io_reset_bit_status
//															_hi_speed_usb_reset_bit_status
//															_clock_bank_switch_bit_status)
//								_uart_rts_status
//								_gp_io_0_dir
//								_gp_io_0_val
//								_gp_io_1_dir
//								_gp_io_1_val
//
//							Reg B
//								_spi_miso_enable_status
//		
//	Modified registers:		r12
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_write_io_control_register:
	
	r4 = pass r4;
	IF NE JUMP write_io_control_reg_B;

write_io_control_reg_A:

	SYS_REG_ADDR_A = r8;					// System register A is updated with value of r8
											// in hardware
	DM(_io_control_register_A) = r8;				// and all the other 'shadow' tracking variables	
											// are also updated.	
	r12 = FEXT r8 by 0:1;
	DM(_io_reset_bit_status) = r12;
											// All of the bit values are right justified using
	r12 = FEXT r8 by 1:1;					// FEXT
	DM(_hi_speed_usb_reset_bit_status) = r12;
	
	r12 = FEXT r8 by 2:1;
	DM(_clock_bank_switch_bit_status) = r12;
	
	r12= FEXT r8 by 0:3;
	DM(_peripheral_control_status) = r12;
	
	r12 = FEXT r8 by 3:1;
	DM(_uart_rts_bit_status) = r12;
	
	r12 = FEXT r8 by 4:1;
	DM(_gp_io_0_val) = r12;	
	
	r12 = FEXT r8 by 5:1;
	DM(_gp_io_0_dir) = r12;
		
	r12 = FEXT r8 by 6:1;
	DM(_gp_io_1_val) = r12;
	
	r12 = FEXT r8 by 7:1;
	DM(_gp_io_1_dir) = r12;	
	
	JUMP _write_io_control_register_exit;
	
write_io_control_reg_B:


	SYS_REG_ADDR_B = r8;					// System Register B is only related to the 
											// miso enable function.
	DM(_io_control_register_B) = r8;
	
	r12 = FEXT r8 by 0:6;					// Again the value is right justified
	DM(_spi_miso_enable_status) = r12;	
	
	
_write_io_control_register_exit:	
	
	RTS;
_write_io_control_register.end:

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_set_io_control_register_bit
//
//	Notes:  Takes the last current value of the register of interest and then sets the bit of 
//			interest and transfers control to _write_io_control_register.
//
//	Revision:  Modified register usage to comply to C rules
//	
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	r4 = 0 for reg A or 1 for reg B
//							r8 = Bit Location	, definitions located at sys_dspstak_sx2_zx2.h
//
// 	Return value:			None
//			
//	Modified registers:		r8, r12
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_set_io_control_register_bit:
	
	r4 = pass r4;
	IF NE JUMP set_io_control_register_B;
	
set_io_control_register_A:	

	r12 = DM(_io_control_register_A);			// Gets the last value of system register A
	r12 = BSET r12 by r8;				
	r8 = r12;		
	JUMP _set_io_control_register_bit_exit;	

set_io_control_register_B:

	r12 = DM(_io_control_register_B);			// Gets the last value of system register B
	r12 = BSET r12 by r8;
	r8 = r12;

_set_io_control_register_bit_exit:		
		
	JUMP _write_io_control_register;			// Updates system register A or B with new bit values
	
_set_io_control_register_bit.end:


///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_clear_io_control_register_bit
//
//	Notes:  Takes the last current value of the register of interest and then clears the bit of 
//			interest and transfers control to _write_io_control_register.
//
//	Revision:  Modified register usage to comply to C rules
//	
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	r4 = 0 for reg A or 1 for reg B
//							r8 = Bit Location	, definitions located at sys_dspstak_sx2_zx2.h
//
// 	Return value:			None
//			
//	Modified registers:		r8, r12
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_clr_io_control_register_bit:
	
	r4 = pass r4;
	IF NE JUMP clr_io_control_register_B;
	
clr_io_control_register_A:	

	r12 = DM(_io_control_register_A);			// Gets the last value of system register A
	r12 = BCLR r12 by r8;
	r8 = r12;
	JUMP _clr_io_control_register_bit_exit;

clr_io_control_register_B:

	r12 = DM(_io_control_register_B);			// Gets the last value of system register B
	r12 = BCLR r12 by r8;
	r8 = r12;

_clr_io_control_register_bit_exit:		
		
	JUMP _write_io_control_register;			// Updates system register A or B with new bit values
	
	RTS;
	
_clr_io_control_register_bit.end:

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_read_io_control_register
//
//	Notes: 	Performs an external port read to one of two memory mapped registers found in bank 2 of 
//			AMI port.  The bit definitions for the two registers are discussed in the comment section
//			for _init_ext_port. After reading the value to the physical register a set of shadow variables
//			are updated for tracking.
//
//	Revision:  Modified register usage to comply to C rules
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	r4 = 0 for reg A or 1 for reg B
//
// 	Return value:			
//							Reg A
//								_sys_mode	
//								_uart_cts_status
//								_gp_io_0_dir
//								_gp_io_0_val
//								_gp_io_1_dir
//								_gp_io_1_val
//
//							Reg B
//								_spi_miso_enable_status
//							
//			
//	Modified registers:		r8, r12
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_read_io_control_register:

	r4 = pass r4;
	IF NE JUMP read_sys_reg_B;

read_sys_reg_A:

	r8 = SYS_REG_ADDR_A ;				// Reads current hardware value for system register A
	
	r12 = FEXT r8 by 0:3;				// All the shadow variables are updated and the bit wide
	DM(_sys_mode) = r12;					// variables are right justified.
	
	r12 = FEXT r8 by 3:1;				
	DM(_uart_cts_bit_status) = r12;
	
	r12 = FEXT r8 by 4:1;
	DM(_gp_io_0_val) = r12;	
	
	r12 = FEXT r8 by 5:1;
	DM(_gp_io_0_dir) = r12;
		
	r12 = FEXT r8 by 6:1;
	DM(_gp_io_1_val) = r12;
	
	r12 = FEXT r8 by 7:1;
	DM(_gp_io_1_dir) = r12;	
	
	JUMP _read_io_control_register_exit;
	
read_sys_reg_B:


	r8 = SYS_REG_ADDR_B ;				// Reads current hardware value for system register B

	r12 = FEXT r8 by 0:6;				// For register B only the variable _spi_miso_enable_status
	DM(_spi_miso_enable_status) = r12;	// is updated.	
	
	
	
_read_io_control_register_exit:
	
	RTS;
	
_read_io_control_register.end:


///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_read_sys_mode
//
//	Notes:  	Calls read_io_control_register accessing register A and returns the _sys_mode value.
//
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	None
//
// 	Return value:			r0 = 3 bit value corresponding to _sys_mode
//			
//	Modified registers:		r0, r4
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_read_sys_mode:
	
	r4 = 0;
	CALL _read_io_control_register;
	
	r0 = DM(_sys_mode);
	
	RTS;
	
_read_sys_mode.end:

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_read_sys_mode
//
//	Notes:  	Calls read_io_control_register accessing register A and returns the _sys_mode value.
//
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	None
//
// 	Return value:			r0 = bit value corresponding for uart cts line
//			
//	Modified registers:		r0, r4
//
////////////////////////////////////////////////////////////////////////////////////////////////////////

_read_cts_value:
	
	r4 = 0;
	CALL _read_io_control_register;
	
	r0 = DM(_uart_cts_bit_status);
	
	RTS;
	
_read_cts_value.end:

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_read_spi_miso_enable_status
//
//	Notes:  	Calls read_io_control_register accessing register B and returns the 
//				_spi_miso_enable_status value.
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006 	
//
//	Calling parameters: 	None
//
// 	Return value:			r0 = word value corresponding to _spi_miso_enable_status
//			
//	Modified registers:		r0, r4
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_read_spi_miso_enable_status:
	
	r4 = 1;
	CALL _read_io_control_register;
	
	r0 = DM(_spi_miso_enable_status);
	
	RTS;
	
_read_spi_miso_enable_status.end:


