/////////////////////////////////////////////////////////////////////////
//
// File:	uart_dspstak_sx2_zx2.h	
// Version:	1.01
// Build 	1.00
// Tools:	Visual DSP 4.0
//
// UART Library Header
//
// Date:	September 2006
//
// Author:	Danville Signal Processing, Inc.
//
// http://www.danvillesignal.com
//
/////////////////////////////////////////////////////////////////////////

// external functions
.EXTERN _init_uart_port;
.EXTERN _uart_port_manager;
.EXTERN _uart_char_loopback;
.EXTERN _puts_uart;
.EXTERN _flush_uart_tx_buffer;

// external variables
.EXTERN _uart_tx_buffer;
.EXTERN _uart_tx_buffer_head_ptr;
.EXTERN _uart_tx_buffer_tail_ptr;

.EXTERN _uart_rx_buffer;
.EXTERN _uart_rx_buffer_head_ptr;
.EXTERN _uart_rx_buffer_tail_ptr;


/////////////////////////////////////////////////////////////////////////
//
//	Note for C users
//
// 	If the functions for the uart library is used with some C
//	coding the user should use the following external declarations so
//	that the C code can call the uart functions and utilize the uart 
//	variables.  
/*
// external functions
extern void init_uart_port(void);
extern void uart_port_manager;
extern void uart_char_loopback;
extern void puts_uart(string_variable);

// external variables
extern void uart_tx_buffer;
extern void uart_tx_buffer_head_ptr;
extern void uart_tx_buffer_tail_ptr;

extern void uart_rx_buffer;
extern void uart_rx_buffer_head_ptr;
extern void uart_rx_buffer_tail_ptr;
*/
/////////////////////////////////////////////////////////////////////////

#define UART_TX_BUFF_SIZE	300
#define UART_RX_BUFF_SIZE	300

#if defined(__ADSP21375__)
// TBD: The values for dll and dlh for dspstak 21375 sx2 board
// for the other buad rates will be determined later.
#define UART0DLL_VAL_19200	0x9E
#define UART0DLH_VAL_19200	0x01

#define UART0DLL_VAL		UART0DLL_VAL_19200
#define UART0DLH_VAL		UART0DLH_VAL_19200

#elif defined(__ADSP21369__)

#define UART0DLL_VAL_2400	0xE0
#define UART0DLL_VAL_4800	0x70
#define UART0DLL_VAL_9600	0x38
#define UART0DLL_VAL_19200	0x1C
#define UART0DLL_VAL_38400	0x0E
#define UART0DLL_VAL_57600	0xB4
#define UART0DLL_VAL_115200	0x5A

#define UART0DLH_VAL_2400	0x10
#define UART0DLH_VAL_4800	0x08
#define UART0DLH_VAL_9600	0x04
#define UART0DLH_VAL_19200	0x02
#define UART0DLH_VAL_38400	0x01
#define UART0DLH_VAL_57600	0x00
#define UART0DLH_VAL_115200	0x00

#define UART0DLL_VAL		UART0DLL_VAL_115200
#define UART0DLH_VAL		UART0DLH_VAL_115200

#endif	



