/////////////////////////////////////////////////////////////////////////
//
// File:	uart_dspstak_sx2_zx2.asm
// Version:	1.01
// Build 	1.00
// Tools:	Visual DSP 4.5
//
// UART dsptak sx2 and dspstak zx2 library
//
// Date:	September 2006
//
// Author:	Danville Signal Processing, Inc.
//
// http://www.danvillesignal.com
//
/////////////////////////////////////////////////////////////////////////

// CODE UNDER C COMPLIANCE REVIEW SEPT 26 2006

#if defined(__ADSP21375__)
#include <def21375.h>
#elif defined(__ADSP21369__)
#include <def21369.h>
#endif	

#include <SRU.h>
#include <asm_sprt.h>
#include "sys_dspstak_sx2_zx2.h"
#include "uart_dspstak_sx2_zx2.h"

.GLOBAL _init_uart_port;
.GLOBAL _uart_port_manager;
.GLOBAL _uart_char_loopback;
.GLOBAL _puts_uart;

.GLOBAL _uart_update;
.GLOBAL _uart_write;

/////////////////////////////////////////////////////////////////////////
//
//	This code library includes subroutines that support the uart 
//	peripheral present with the SHARC DSPs that have the DPI interface.
//	The library incorporates the initialization routines, as well as
//	a uart character manager, which in part manages the transmit
//	and receiv uart buffers.  In addition, a uart character loopback
//	subroutine is added and is a good routine for test purposes.
//
/////////////////////////////////////////////////////////////////////////




.SECTION/DM seg_dmda;

.VAR _uart_tx_buffer[UART_TX_BUFF_SIZE];
.VAR _uart_tx_buffer_head_ptr = _uart_tx_buffer;
.VAR _uart_tx_buffer_tail_ptr = _uart_tx_buffer;

.VAR _uart_rx_buffer[UART_RX_BUFF_SIZE];
.VAR _uart_rx_buffer_head_ptr = _uart_rx_buffer;
.VAR _uart_rx_buffer_tail_ptr = _uart_rx_buffer;

.VAR uart_temporary_storage[5];						// this is a local variable			

.SECTION/PM seg_pmda;

.SECTION/PM seg_pmco;


///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_init_uart_port	
//
//	Notes:  Configure DPI connected to dspstak sx2 and dspstak zx2 UART pins
//			Configure line control register; set byte transfer 
//			Configure divider registers related to baud(DLL and DLH)
//			The DLL and DLH registers should be changed in uart_dspstak_sx2_zx2.h
//			dependent on the desired baud rate.
//			Enable UART TX and RX --> note the ADI manual gives the impression that this is only
//			significant for dma transfers, also needed for core transfers
//
//	Revision:  Adjusted the register usage in order to be C rule compliant.
//
//	Written by Danville Signal Processing
//
//	Date:   				September 2006
//
//	Calling parameters: 	none
//	
//	Return values: 			none
//
//	Altered registers:		r4, ustat1
//
///////////////////////////////////////////////////////////////////////////////////////////////////
_init_uart_port:

// connect dpi pins to uart port

	SRU(UART0_TX_O, DPI_PB09_I);	// dpi pin 9 to uart 0 tx
	SRU(HIGH, DPI_PBEN09_I);		// dpi pin 9 to uart 0 tx
	
	SRU(DPI_PB10_O, UART0_RX_I );	// dpi pin 10 to uart 0 rx
	SRU(LOW, DPI_PBEN10_I);			// dpi pin 10 to uart 0 rx
	
	r4 = UARTWLS8;				// declare byte transfers
	DM(UART0LCR) = r4;

// set the baud related registers		
	ustat1 = DM(UART0LCR);
	BIT SET ustat1 UARTDLAB;
	DM(UART0LCR) = ustat1;

//	ALERT: User should changed the desired value for UART0DLL_VAL and
//	UART0DLH_VAL according to the desired baud rate.  The default value
//  is set for Baud 19200.  The baud rate values could be changed in
//  uart_dspstak_sx2_zx2.h

	r4 = UART0DLL_VAL;				
	DM(UART0DLL) = r4;
	
	r4 = UART0DLH_VAL;
	DM(UART0DLH) = r4;				
		
	ustat1 = DM(UART0LCR);
	BIT CLR ustat1 UARTDLAB;		// clear this bit to have access to thr and rbr status bits
	DM(UART0LCR) = ustat1;

// turn on tx and rx connection	
	r4 = UARTEN;					// enable tx
	DM(UART0TXCTL) =  r4;
	
	r4 = UARTEN;					// enable rx
	DM(UART0RXCTL) =  r4;
	NOP;
	NOP;
	
	RTS;

_init_uart_port.end:

///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_uart_port_manager
//
//	Notes:  This subroutine has two (2) sections: the uart receive section and the 
//			uart transmit section.
//		uart receive section
//			Tests the line status register(UART0LSR) of uart port 0 to see if there 
//			is received new data. 
//			New received data is saved to receive buffer.
//			If there is no new received data code goes straight to the uart transmit section.
//		uart transmit section
//			Check if line status register if transmit port is ready.
//			Place transmit data toward the uart tx physical register.
//			Wait for transfer buffer is empty to ensure that data is transmitted correctly.
//
//	Revision:  Adjusted the register usage in order to be C rule compliant.
//
//	Written by Danville Signal Processing
//
//	Date:   				September 2006
//
//	Calling parameters: 	none
//	
//	Return values: 			none
//
//	Altered registers:		r4, r8, ustat1, DAG4 (b4,i4,l4)
//
///////////////////////////////////////////////////////////////////////////////////////////////////
_uart_port_manager:

	
uart_receive_handler:

	ustat1 = DM(UART0LSR);						// read the line status register
	BIT TST ustat1 UARTDR;						// check if there is received data ready (DR)
	IF NOT TF JUMP uart_transmit_handler;		// if no data exit out
	
	
wait_for_uart_tx_buff_empty:

	ustat1 = DM(UART0LSR);
	BIT TST ustat1 UARTTEMT;					// wait this uart transfer is empty (EMT)
	IF NOT TF JUMP wait_for_uart_tx_buff_empty;
	

	r4 = DM(UART0RBR);							// get read value from uart port
	
	b4 = _uart_rx_buffer;						// save value to uart rx buffer
	i4 = DM(_uart_rx_buffer_tail_ptr);			
	l4 = LENGTH(_uart_rx_buffer);			
	DM(i4, m6) = r4;
	DM(_uart_rx_buffer_tail_ptr) = i4;			// update tail pointer after saving
	
uart_transmit_handler:

	r4 = DM(_uart_tx_buffer_head_ptr);			// check if there are any characters to be 
	r8 = DM(_uart_tx_buffer_tail_ptr);			// transmitted by comparing tx buffer head and
	COMP(r4, r8);								// tail pointers
	IF EQ JUMP _uart_port_manager_exit;

	b4 = _uart_tx_buffer;
	i4 = DM(_uart_tx_buffer_head_ptr);
	l4 = LENGTH(_uart_tx_buffer);
	r4 = DM(i4,m6);
	DM(_uart_tx_buffer_head_ptr) = i4;

wait_for_uart_tx_ready:							// making sure that transmit side is ready to 

	ustat1 = DM(UART0LSR);						// accept new data
	BIT TST ustat1 UARTTHRE;					// THRE -- transmit ready
	IF NOT TF JUMP wait_for_uart_tx_ready;	
	DM(UART0THR) = r4;							// place read data to transmit register (THR)
	
_uart_port_manager_exit:

	l4 = 0;										// comply to C rules for L registers == 0
	
	RTS;
_uart_port_manager.end:

_uart_update:
	entry;
	CALL _uart_port_manager;
	exit;
_uart_update.end:

_uart_write:
	entry;
	CALL _puts_uart;
	exit;
_uart_write.end:

///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_puts_uart
//
//	Notes:  Writes the rs232_transmit_buffer. Strings must end with 0. 
//
//	Revision Notes:	
//		Changed calling parameter from i4 to r4 to comply to C calling rules 
//		9-26-06 EE
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006
//
//	Calling parameters: 	r4 => String, DAG 4 should not be circular
//
// 	Return value:			None 
//			
//	Modified register:		r8,  DAG1 (b1,i1,l1), i4, l4
//
///////////////////////////////////////////////////////////////////////////////////////////////////////
_puts_uart:
	
	i4 = r4;						// save r4 to i4 for memory traversing later

//  b1, i1 , and l1 are all compiler registers so temporarily save these values
// 	in local temporary storage
	DM(uart_temporary_storage + 0) = b1;	
	DM(uart_temporary_storage + 1) = i1;	
	DM(uart_temporary_storage + 2) = l1;	
	
// Use DAG 1 to point to uart transmit buffer	
	b1 = _uart_tx_buffer;
	i1 = DM(_uart_tx_buffer_tail_ptr);
	l1 = LENGTH(_uart_tx_buffer);
	l4 = 0;							// make sure that DAG 4 is non - circular
		
_puts_uart_loop:
	r8 = DM(i4,m6);					// Get Character from memory
	
	r8 = PASS r8;
	IF EQ JUMP _puts_uart_exit;		// If it's a null, the string is done
	
	DM(i1,m6) = r8;					// If character is non-zero, transfer to tx buffer
	JUMP _puts_uart_loop;			// and continue to next character
	
_puts_uart_exit:
	
	DM(_uart_tx_buffer_tail_ptr) = i1;

// Restore the registers upon exit	
	b1 = DM(uart_temporary_storage + 0);	
	i1 = DM(uart_temporary_storage + 1);	
	l1 = DM(uart_temporary_storage + 2);	// by rules l1 should be zero upon entry anyway	
	l4 = 0;							// just written for C compliance

	RTS; 
		
_puts_uart.end:	
	


///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_uart_char_loopback
//
//	Notes:  This subroutine performs a uart character loopback. This is done
//			by re-routing the characters found in the uart received buffer and 
//			transferring them toward the uart transmit buffer. If there are no
//			new received characters, subroutine basically exits.
//
//	Written by Danville Signal Processing
//
//	Date:   				September 2006
//
//	Calling parameters: 	none
//	
//	Return values: 			none
//
//	Altered registers:		r4, r8, DAG4 (b4,i4,l4)
//
///////////////////////////////////////////////////////////////////////////////////////////////////
_uart_char_loopback:

	r4 = DM(_uart_rx_buffer_head_ptr);			// check if there are any characters received
	r8 = DM(_uart_rx_buffer_tail_ptr);			// by comparing the rx buffer head and tail pointers
	COMP(r4, r8);								
	IF EQ JUMP _uart_char_loopback_exit;		// if there are no new characters just exit
	
	b4 = _uart_rx_buffer;						// get value from uart rx buffer
	i4 = DM(_uart_rx_buffer_head_ptr);			
	l4 = LENGTH(_uart_rx_buffer);			
	r4 = DM(i4, m6);
	DM(_uart_rx_buffer_head_ptr) = i4;			// update head pointer grabbing value from rx buffer

	b4 = _uart_tx_buffer;						
	i4 = DM(_uart_tx_buffer_tail_ptr);			// loop value from uart rx buffer towards
	l4 = LENGTH(_uart_tx_buffer);				// uart tx buffer
	DM(i4,m6) = r4;
	DM(_uart_tx_buffer_tail_ptr) = i4;			// update tail pointer of transmit buffer

_uart_char_loopback_exit:

	l4 = 0;										// comply to C rules for L registers == 0
	
	RTS;

_uart_char_loopback.end:




///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_flush_uart_tx_buffer
//
//	Notes:  Forces a UART transmit buffer 
//
//	Written by Danville Signal Processing
//
//	Date:   				May 2008
//
//	Calling parameters: 	none
//	
//	Return values: 			none
//
//	Altered registers:		r4, r8, 
//
///////////////////////////////////////////////////////////////////////////////////////////////////


_flush_uart_tx_buffer:

	r4 = DM(_uart_tx_buffer_head_ptr);
	r8 = DM(_uart_tx_buffer_tail_ptr);
	COMP(r4, r8);
	IF EQ JUMP _flush_uart_tx_buffer_exit;

		
	
	CALL _uart_port_manager;

	JUMP _flush_uart_tx_buffer;
	
_flush_uart_tx_buffer_exit:

	RTS;
_flush_uart_tx_buffer.end:
