/////////////////////////////////////////////////////////////////////////
//
// Program:	Shark Tracker
// File:	m_dspstak_sx2_zx2.asm
// Version:	1.02
// Build 	1.00
// Tools:	Visual DSP 4.5
//
// Main Program
//
// Date:	January 2010
//
// Author:  Greg Eddington - Implemented _signal_processing
// 
// Initialization based on code from Danville Signal Processing, Inc.
// (http://www.danvillesignal.com)
//
/////////////////////////////////////////////////////////////////////////

///////////////////////// DECLARATIONS //////////////////////////////////


#include <SRU.h>

#if defined(__ADSP21375__)

#include <def21375.h>

#elif defined(__ADSP21369__)

#include <def21369.h>	

#endif	

#include <asm_sprt.h>
#include "spi_dspstak_sx2_zx2.h"
#include "sys_dspstak_sx2_zx2.h"
#include "uart_dspstak_sx2_zx2.h"
#include "memory_dspstak_sx2_zx2.h"
#include "signal_dspstak_sx2_zx2.h"

#define SDRAM_STAT 		SDRAM

.GLOBAL _initialize;

.SECTION/DM seg_dmda;

.VAR hello_str[] = 'Shark Tracker Software Filter',13,10,13,10,0;
.VAR dspstak_str[] = 'dspstak dspstak_sx2_zx2 ver 1.02', 13,10,0;
.VAR date_str[] = 'January 2010', 13, 10, 0;
.VAR company_str[] = 'Shark Trackers, Cal Poly San Luis Obispo', 13, 10, 0;
.VAR copyright_str[] = '(c) Copyright 2011', 13, 10, 0;
.VAR rights_str[] = 'All Rights Reserved', 13, 10, 13, 10, 0;

.SECTION/PM seg_pmda;


.SECTION/PM seg_pmco;

_initialize:
	entry;

//  Changinge core clock to maximum possible value.
// 	Value of r4 and r8 are adjusted according to the declared processor
// 	Input clock is 22.1184 MHz. 
//	If processor is ADSP-21368/ADSP-21369 , core clock is set to 331.776  MHz (22.1184 * 15). 
//	If processor is ADSP-21375 , core clock is set to 265.4208  MHz (22.1184 * 12). 
	r4 = PLL_DIV_MAX;				
	r8 = PLL_MUL_MAX;			
	CALL _sys_set_coreclock;
	

// The following code follows the assumed assembly language rules for the 
// libraries writted by Danville Signal Processing, Inc.
	
// Enable Secondary DAGs & Registers
	BIT SET MODE1 SRD1L | SRD1H | SRD2L | SRD2H | SRRFL | SRRFH;
	NOP;						// 1 cycle latency				
			
	m5 = 0;						// These defaults are assumed 
	m6 = 1;						// throughout the program
	m7 = -1;
	m13 = 0;
	m14 = 1;
	m15 = -1;

	l0 = 0;
	l2 = 0;
	l3 = 0;
	l5 = 0;
	l8 = 0;
	l9 = 0;
	l10 = 0;
	l11 = 0;
	l14 = 0;
	l15 = 0;

// Enable Primary DAGs & Registers
	BIT CLR MODE1 SRD1L | SRD1H | SRD2L | SRD2H | SRRFL | SRRFH;
	NOP;							// 1 cycle latency				
	 
 	m5 = 0;							// These defaults are assumed 
	m6 = 1;							// throughout the program
	m7 = -1;
	m13 = 0;
	m14 = 1;
	m15 = -1;

	l0 = 0;
	l2 = 0;
	l3 = 0;
	l5 = 0;
	l8 = 0;
	l9 = 0;
	l10 = 0;
	l11 = 0;
	l14 = 0;
	l15 = 0;

	BIT CLR MODE1 NESTM;			// Disable Nested Interrupts
	BIT SET MODE1 CBUFEN;			// Enable Circular Buffering

initialize_all_peripherals: 
	
	CALL _init_uart_port;			// initialize dspstak sx2/zx2 uart port connection 		
	CALL _init_ext_port;			// initialize external AMI port and sdram controller registers 
	CALL _init_spi_port;			// initialize spi port
	CALL _init_signal_processing;
//	CALL _init_timer;
	
// Here is the section where user declare the functionality of the 
// IOx/SSx pins with respect to the din connection.		
// At reset, these pins are input pins.
	r4 = TYPE_IO0	| 	TYPE_IO1 	| 	TYPE_IO2		|	TYPE_IO3 	|	TYPE_IO4;											
	r8 = IO0_DIR_IN	|	IO1_DIR_IN	| 	IO2_DIR_IN		|	IO3_DIR_IN	|	IO4_DIR_IN;
	CALL _sys_assign_pins;

send_system_opening_strings:		
	
	r4 = hello_str;
	CALL _puts_uart;
	
	r4 = dspstak_str;
	CALL _puts_uart;
	
	r4 = date_str;
	CALL _puts_uart;
	
	r4 = company_str;
	CALL _puts_uart;
	
	r4 = copyright_str;
	CALL _puts_uart;
	
	r4 = rights_str;
	CALL _puts_uart;
	
initialize_other_hardware_pins:
		
	SET_GP0_DIR_BIT;				// dictate the direction of GP0 to be an output pin
	SET_GP1_DIR_BIT;				// dictate the direction of GP1 to be an output	pin

	exit;
	
_initialize.end:
