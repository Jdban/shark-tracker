/////////////////////////////////////////////////////////////////////////
//
// File:	spi_dspstak_sx2_zx2.h
// Version:	1.01
// Build 	1.00
// Tools:	Visual DSP 4.5
//
// SPI Library Header
//
// Date:	September 2006
//
// Author:	Danville Signal Processing, Inc.
//
// http://www.danvillesignal.com
//
/////////////////////////////////////////////////////////////////////////

.EXTERN _init_spi_port;
.EXTERN	_init_spi_device;				// declare spi device variables
.EXTERN _spi_disable;					// disable the spi port
.EXTERN _spi_add_queue;					// add a spi transfer entity to be serviced
.EXTERN _spi_manager;					// executes spi transfers from the spi queue

.EXTERN _spi_queue;			
.EXTERN _spi_queue_head_ptr;			// head pointer for the queue.  head always get serviced first
.EXTERN _spi_queue_tail_ptr;			// tail pointer of the queue
.EXTERN _spi_error_msg;					// this variable can be externally viewed in 
										// case user tried to use an invalid chip select
										// value. This error msg mechanism can be expanded.		
										
										
///////////////////////////////////////////////////////////////////////////////////
//
//	The following are C prototypes that the user can use in order to use the 
//	same assembly routines so as it can be called from a C environment.	
//	User may have to comment out the assembly .EXTERN declarations depending on the
//	code setup.
//
/*

extern void init_spi_port(void);
extern void init_spi_device(spi_dev_num, ptr_spi_setup, ptr_spi_rcv_buffer);				
extern void spi_disable(void);					
extern void spi_add_queue(spi_packet);					
extern void spi_manager(void);					

extern int spi_queue;			
extern int spi_queue_head_ptr;			
extern int spi_queue_tail_ptr;			
extern int spi_error_msg;				

*/
///////////////////////////////////////////////////////////////////////////////////										
										

///////////////////////////////////////////////////////////////////////////////////
//
// SPI Header
// Header dictates the following
//
//	BIT 15 		--> Provision for further or user SPI protocol functions
//	BIT 14 		--> Handshake bit for end of spi transfer
//	BIT 13 		--> Determines if spi transfer is full tx or tx-rx 
//  BITS 12 - 8 --> SPI device number
//  BITS 7 - 0 	--> Size of SPI transfer
//
///////////////////////////////////////////////////////////////////////////////////

// reminder: the data width in this protocol is 16 bit wide words

// first word definitions
#define SPI_SPECIAL			0x8000		// special instructions or settings are attached
#define SPI_HS				0x4000		// handshaking 1 is TRUE
#define SPI_TR				0x2000		// transmit/receive = 1, transmit only = 0 

#define SPI_DEVICE_MASK		0x1F00		// 5 bits are needed to define 32 devices

// devices
#define SPI_DEVICE_NULL 	0x0000		// just used to setup spi registers
#define SPI_DEVICE_FLASH	0x0100		// assigned to flash memory
#define SPI_DEVICE_EE		0x0200		// assigned to the spi eeprom for the 
										// dspstak sx2/zx2 (based on ADSP-21369)
										
										// legacy note:	 DEVICE_2 (0x0200)
										// assigned to peripheral microcontroller for 
										// the dspstak sx / zx (based on ADSP-21262)

// RESERVED SPI DEVICE assignments for future use (SPI DEVICE Rx)
#define SPI_DEVICE_3		0x0300
#define SPI_DEVICE_4		0x0400
#define SPI_DEVICE_5		0x0500
#define SPI_DEVICE_6		0x0600
#define SPI_DEVICE_7		0x0700
#define SPI_DEVICE_8		0x0800
#define SPI_DEVICE_9		0x0900
#define SPI_DEVICE_A		0x0A00		
#define SPI_DEVICE_B		0x0B00		
#define SPI_DEVICE_C		0x0C00		
#define SPI_DEVICE_D		0x0D00		
#define SPI_DEVICE_E		0x0E00		
#define SPI_DEVICE_F		0x0F00		


// USER SPI devices start @ SPI DEVICE 10
#define SPI_DEVICE_10		0x1000		
#define SPI_DEVICE_11		0x1100		
#define SPI_DEVICE_12		0x1200		
#define SPI_DEVICE_13		0x1300		
#define SPI_DEVICE_14		0x1400		
#define SPI_DEVICE_15		0x1500		
#define SPI_DEVICE_16		0x1600		
#define SPI_DEVICE_17		0x1700		
#define SPI_DEVICE_18		0x1800		
#define SPI_DEVICE_19		0x1900		
#define SPI_DEVICE_1A		0x1A00		
#define SPI_DEVICE_1B		0x1B00		
#define SPI_DEVICE_1C		0x1C00		
#define SPI_DEVICE_1D		0x1D00		
#define SPI_DEVICE_1E		0x1E00		
#define SPI_DEVICE_1F		0x1F00		

#define SPI_PAYLOAD_MASK	0x00FF



#if defined(__ADSP21375__)
#define SPI_BAUD_500KHZ		0xFA
#define SPI_BAUD_1MHZ 		0x7D
#define SPI_BAUD_2MHZ 		0x3E
#define SPI_BAUD_4MHZ		0x1B		
#define SPI_BAUD_5MHZ		0x19
#define SPI_BAUD_10MHZ		0x0C
#define SPI_BAUD_15MHZ		0x0A
#define SPI_BAUD_20MHZ		0x08
#define SPI_BAUD_25MHZ		0x05

#elif defined(__ADSP21369__)
#define SPI_BAUD_500KHZ 	0xC8
#define SPI_BAUD_1MHZ 		0x64
#define SPI_BAUD_2MHZ 		0x32
#define SPI_BAUD_4MHZ		0x16		
#define SPI_BAUD_5MHZ		0x14
#define SPI_BAUD_10MHZ		0x0A
#define SPI_BAUD_15MHZ		0x08
#define SPI_BAUD_20MHZ		0x06
#define SPI_BAUD_25MHZ		0x04
#endif	


#define SPI_BAUD_DEFAULT 		SPI_BAUD_1MHZ

// definitions for the TASK flag variable
#define SPI_EVAL_HEADER_TASK	0x0001
#define SPI_TXS_TASK			0x0002
#define SPI_SPIF_TASK			0x0004

#define SPI_QUEUE_LENGTH		768			// length of the spi service queue
#define SPI_TR_LENGTH			257			// Maximum length of receive buffers
#define SPI_T_LENGTH			1			// Length of transmit only buffer


// spi flag definitions
#define SPI_FLAG_NULL		0xFF0F
#define SPI_FLASH_SS		0xFE0F	
#define SPI_EE_SS			0xFD0F			// This feature is new for the sx2 and zx2	

#define SPI_SEL_SS0			0xF70F			// For the sx2 and zx2 this corresponds to SPI_SS / SS0
											// SPI_SS0 = SPI_SS
// Flag Definitions
// The values for the external expansion spi chip selects are used as jumps.
#define SPI_SEL_SS1			FLG4
#define SPI_SEL_SS2			FLG5
#define SPI_SEL_SS3			FLG6
#define SPI_SEL_SS4			FLG7
#define SPI_SEL_SS5			FLG0


#define SPI_TYPE_COMPARE	0xF000			// used to compare flag based and expansion
											// the spi based ones all have values greater than xF000
											// as oppose to the external ones

#define SPI_TYPE_SPI_FLAG		0x0			// applies to flash, eeprom and spi_ss0
#define SPI_TYPE_DPI_FLAG		0x1			// applies to ss1 - ss5


// SPI ERROR MESSAGE CODES
#define ILLEGAL_SPI_SS_USE	0x01			
