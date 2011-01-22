/////////////////////////////////////////////////////////////////////////
//
// File:	signal_dspstak_sx2_zx2.asm
// Version:	1.00
// Build 	1.00
// Tools:	Visual DSP 4.5
//
// Signal Processing Library for Shark Tracker
//
// Date:	January 2010
//
// Author:	Greg Eddington
//
/////////////////////////////////////////////////////////////////////////

#include <def21369.h>
#include "spi_dspstak_sx2_zx2.h"
#include "uart_dspstak_sx2_zx2.h"

#define SIGNAL_READ_BUFF			4

.GLOBAL _signal_processing;
.GLOBAL _init_signal_processing;
.GLOBAL _parse_data;

.SECTION /DM seg_dmda;

.VAR zero_str[] = '0',13,10,0;
.VAR one_str[] = '1',13,10,0;

// SPI Signal Settings
.VAR signal_device_settings[3] =
	SPI_BAUD_5MHZ,						// SPI baud for flash
	SPI_SEL_SS0,						// slave select flag
	SPIMS | 							// Master mode (internal SPICLK) 
	SPIEN| 								// Enable SPI port 
	TIMOD1|								// transfer mode 1
	MSBF|								// send MSB first
	CPHASE|								// control CS manually
	CLKPL |								
	WL8 |								// 8 bit transfer
	SENDZ; 								// send zero if transmission buffer is empty

// SPI Signal Receive Buffer
.VAR signal_receive_buffer[SIGNAL_READ_BUFF];

// SPI Message
.VAR signal_start_adc_ch1[4]=
	SPI_DEVICE_11 | SPI_TR  | 0x02, // Device, Transmit/Receive, # bytes -1
	0x01,							// Start Bit
	0x80,						 	// Signal = 1, 00 = CH0
	0x00;						
				
.SECTION/PM seg_pmco;

/////////////////////////////////////////////////////////////////////////
//
//  _init_signal_processing
//
//  Initialize signal processing
//
/////////////////////////////////////////////////////////////////////////
_init_signal_processing:

    r4  = SPI_DEVICE_11;				// SPI Device Number	
	r8  = signal_device_settings;		// SPI device parameters
	r12 = signal_receive_buffer;	    // Buffer used for each individual byte 
	
	CALL _init_spi_device;				// declare device parameters for flash in
										// spi protocol
										
	RTS;
	
_init_signal_processing.end:

///////////////////////////////////////////////////////////////////////////////////
//
//	_complete_mem_spi_transfer
//
//	Notes:
//			Forces a completion of spi transfers.  Basically flushes spi queue. 
//			This is good for static device testing and initialization purposes.
//			
//	Written by Danville Signal Processing
//
//	Date:					28 May 05
//
//	Calling parameters: 	NONE
//
// 	Return value:			NONE
//			
//	Modified register:  	r14, r15
//
//////////////////////////////////////////////////////////////////////////////////
_complete_mem_spi_transfer:

force_mem_spi_loop:
	CALL _spi_manager;		
	r15 = DM(_spi_queue_head_ptr);		// check if spi queue is flushed	
	r14 = DM(_spi_queue_tail_ptr);		// it is flushed if head and tail are equal
	COMP(r14, r15);
	IF NE JUMP force_mem_spi_loop;
	
	RTS;	
	
_complete_mem_spi_transfer.end:

/////////////////////////////////////////////////////////////////////////
//
//	_signal_processing
//
//	Signal processing routines
//
//	Calling parameters: 	NONE
//
// 	Return value:			NONE
//			
//	Modified register:  	r4
//
/////////////////////////////////////////////////////////////////////////
_signal_processing:

    r4 = signal_start_adc_ch1;	 	// send the get channel 1 command
	CALL _spi_add_queue;
	CALL _complete_mem_spi_transfer;
	
	CALL _parse_data;				// parse the data

	RTS;
	
_signal_processing.end:

_parse_data:

	// Send received data over RS-232
/**
test_b0:
	r15 = 0;
	r14 = DM(signal_receive_buffer);
	COMP(r14, r15);
	IF EQ JUMP zero_b0;
one_b0:
	r4 = one_str;
	CALL _puts_uart;
	JUMP test_b1;
zero_b0:
	r4 = zero_str;
	CALL _puts_uart;

test_b1:
	r15 = 0;
	r14 = DM(signal_receive_buffer+1);
	COMP(r14, r15);
	IF EQ JUMP zero_b1;
one_b1:
	r4 = one_str;
	CALL _puts_uart;
	JUMP test_b2;
zero_b1:
	r4 = zero_str;
	CALL _puts_uart;

test_b2:
	r15 = 0;
	r14 = DM(signal_receive_buffer+2);
	COMP(r14, r15);
	IF EQ JUMP zero_b2;
one_b2:
	r4 = one_str;
	CALL _puts_uart;
	JUMP test_b3;
zero_b2:
	r4 = zero_str;
	CALL _puts_uart;
**/
test_b3:
	r15 = 0x3F;
	r14 = DM(signal_receive_buffer+3);
	COMP(r14, r15);
	IF LT JUMP zero_b3;
one_b3:
	r4 = one_str;
	CALL _puts_uart;
	JUMP finish;
zero_b3:
	r4 = zero_str;
	CALL _puts_uart;
	
finish:
	RTS;

_parse_data.end: