/////////////////////////////////////////////////////////////////////////
//
// File:	spi_dspstak_sx2_zx2.asm
// Version:	1.01
// Build 	1.00
// Tools:	Visual DSP 4.5
//
// SPI low level driver
//
// Date:	September 2006
//
// Author:	Danville Signal Processing, Inc.
//
// http://www.danvillesignal.com
//
/////////////////////////////////////////////////////////////////////////


#include <SRU.h>
#if defined(__ADSP21375__)
#include <def21375.h>
#elif defined(__ADSP21369__)
#include <def21369.h>
#endif	


#include "spi_dspstak_sx2_zx2.h"
#include "sys_dspstak_sx2_zx2.h"


// global functions accessible by other assembly code
.GLOBAL _init_spi_port;
.GLOBAL _init_spi_device;	// Assign SPI parameters to one of 16 devices
.GLOBAL _spi_disable;		// disable the spi port
.GLOBAL _spi_add_queue;		// add a spi transfer object to be serviced
.GLOBAL _spi_manager;		// executes spi transfers from the spi queue

.GLOBAL _spi_queue;			
.GLOBAL _spi_queue_head_ptr;
.GLOBAL _spi_queue_tail_ptr;
.GLOBAL _spi_error_msg;


////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Overview:
//
//	SPI is a control and data bus for the dspstak platform. The following devices use SPI for
//	their data channels:
//
//		Flash Memory
//		EEPROM Memory
//		General Purpose SPI (Devices connected to the DIN Interconnect Port)
//
//	In addition, many peripherals also use SPI for control and data. The Interconnect Port has 6 
//	lines that can specifically be set as SPI Slave Select (SS) lines. These SS lines are either 
//	automatically controlled by the SPI port (specifically SPI_SS) or manually controlled via 
//	software (for SS1 to SS5).  The user should be aware that the DIN Interconnect pins should
//	be declared first whether pins are used as spi slave select lines or general purpose IO.
//
//	In most cases, the SPI low level driver is abstracted by higher level drivers that support 
//	specific functions. The most common need for calling the SPI driver directly are for custom 
//	I/O drivers.
//
//	Here are some of the specific implementation details of this driver:
//
//		The DSP is always the Master
//		SPI FLAG 0 -- Flash Memory 
//		SPI FLAG 1 -- EEProm Memoery
//      SPI FLAG 3 -- SPI_SS Din Connection 13a
//
//		SPI Data Widths of 8 and 16 bits are supported. 32 bit data widths are not supported. 
//
//	DSP applications do not generally have the luxury of starting an SPI operation and waiting 
//	for that operation to finish, therefore the SPI driver acts as a big state machine. Transmit 
//	packets are placed on a queue and executed sequentially. Since, SPI is bidirectional, there 
//	is always data coming in and going out at the same time. In some cases, the receive data will
//	just be ignored. Transmit packets can be 1 - 256 words (8 or 16 bits), Receive packets are 
//	the same size as the transmit packet. The are also transmit only packets, where the receive 
//	data is ignored.
//
//	The address of a transmit packet is placed on the spi_queue. This packet has the following 
//	structure:
//		
//		Minimum Size (2 - 16 bit words)
//		1 = True
//		
//		First Word (Header)			
//			Bit 15		Special Extension Bit - This is a hook for special situations.
//						For the dspstak sx this is user defined.
//
//			Bit 14		Handshaking - Used to insure that transactions are complete before starting
//						another transfer to the same device. The first element of the receive buffer
//						must be TRUE or spi_manager will stall.
//
//			Bit 13		TR - Transmit/Receive packet = 1. Transmit Only = 0
//
//			Bits 12..8	Device Address - 32 SPI devices with adjustable parameters
//
//			Bits 7..0	Packet Size - 1 (1-256)
//		  		
//		1 -256 subsequent words based on Header 7..0
//
//	Each device has a receive buffer assigned, The first word of the receive buffer is a packet 
//	ready register, therefore the receive buffer must be large enough to handle a packet size as 
//	defined by Header [7..0] + 1. A receive buffer has a maximum size of 257. A transmit only 
//	packet (TR = 0) requires a receive buffer of only 1 word since there is no receive data.					 
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Revision Improvements and Additions
//	
//	1.  Addition of variable spi_error_msg.  For the dspstak zx2, the external spi expansion pins
//		SPI_SS1 to SPI_SS5 are connected to the DSPs Flags and the spi library cross checks the 
//		declaration for these pins as declared in sys_assign_pins routine in sys_dspstak_sx2_zx2.asm.
//		The addition of this variable only enables the user to have way to determine when a particular
//		SSx/ IOx pin is used as a spi slave select but declared as an IOx pins.  In hardware, this will
//		translate to having spi transfer that will not occur or will not have effect because the improper
//		slave select line is not declared.  Future error message codes can be declared in the header file.
//
//	2.  Reviewed and adjusted all the subroutines so that only the user scratch registers as dictated
//		by the SHARC C Manual are used.  The scratch user registers are as follows:
//
//		r0, r1, r2, r4, r8, r12, b4, i1, m4, b12, i12, m12, b13, i13, ustat1, ustat2, px
//
//		Also implemented a temporary variable used for saving and restoring in cases where
//		more registers and/or DAG resources are needed in a subroutine.
//
//
////////////////////////////////////////////////////////////////////////////////////////////////////

.SECTION /DM seg_dmda;

// Anything related to the _spi_queue is global so it should have some leading underscore.
.VAR _spi_queue[SPI_QUEUE_LENGTH];		// spi transmit queue
.VAR _spi_queue_head_ptr = _spi_queue;	// head pointer for the queue.  head always get serviced first
.VAR _spi_queue_tail_ptr = _spi_queue;	// tail pointer of the queue

// All the rest of the variables are local to the spi management code.
.VAR spi_header;						// header of an object
.VAR spi_device;						// The current spi device being serviced (0x0 - 0xF)
.VAR spi_previous_device;	
.VAR spi_payload;						// number of data words to be transferred
.VAR spi_packet_not_ready_ptr;			// used in handshaking modes  	
.VAR spi_stall;							// Queue stalled due to handshaking
.VAR spi_task_complete_flags;			// indicates how deep in the spi transfer TASK has be accomplished
										// variable used to verify the previous spi settings  
.VAR spi_tx_data_ptr;					// data pointer for the data fields of the spi object
.VAR spi_rx_data_ptr;					// current pointer for the receive buffer


.VAR spi_error_msg;						// variable that reflects the last error message (if any)
				

.VAR device_spiflg;						// holds the ASSERTED (active low) of the current spi device
.VAR device_dpiflg;						// Saves the value that needs to be manipulated via the DPI (and FLAGS register)
										// in order to treat a FLAG/ext DIN pin as a SPI slave select.								

.VAR device_spictl;						// holds spi control value of current spi device

.VAR spi_device_type;					// This variable dictates whether the active spi device is a flag based
										// device (FLASH, EEPROM, SS0) or an bit bang based
										// specifically for SS1 to SS5;
										

//////////////////////////////////////////////////////////////////////////////////////
//
//	DEVICE VARIABLE DECLARATIONS 
//
//	There are 32 SPI dspstak sx2 / zx2 devices supported for by this protocol. 
//	
//	Device 		0: Null Device (just sets SPI port)
//	Devioe 		1: SPI Flash
//	Device 		2: SPI EEProm
//	(It should be noted that for the dspstak sx / zx family Device 2 was a peripheral
//	 microcontroller and not an eeprom).
//	Devices 3 - F: Reserved
//  Devices 10-1F: User SPI devices
//
//	Each device must be declared with the following format:
//
//	.VAR spi_device_x_set[3] =
//
//		SPI baud register value  
//		SPI flag register value
//		SPI control register value
//
//	USER based SPI flag register values are	SPI_SEL_SS0	- SPI_SEL_SS5.
//
//////////////////////////////////////////////////////////////////////////////////////

.VAR spi_device_default_set[3]=	// Null SPI Device - Sets SPI Registers but no data is transmitted
	SPI_BAUD_1MHZ,		// BAUD
	SPI_FLAG_NULL,		// FLAG
	SPIMS| 				// Master mode (internal SPICLK) 
	SPIEN| 				// Enable SPI port 
	TIMOD1|				// transfer mode 1
	CLKPL|				// need to change clock phase to comply to clock diagram of codec
	CPHASE|				// need this to able to control select line manually
	MSBF|				// send MSB first
	SENDZ; 				// send zero if transmission buffer is empty

	
.VAR spi_device_set_ptr[32]=	// Devices should be initialized with the _init_spi_device function	
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set,	
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set,
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set,	
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set,
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set,	
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set,
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set,	
	spi_device_default_set, spi_device_default_set, spi_device_default_set, spi_device_default_set;
	

.VAR spi_rx_buffer_default[257];	
				// receive queue buffers are a maxmium of 1 + 256 words  
			 	// the length may be changed to reduce memory requirements	
				// as long as the payload is < the buffer
				// if a device is transmit only, the length may be 1

.VAR spi_rx_buffer_ptr[32] = 	// The ptrs are initialized to a buffer that is always safe
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default,
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default,
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default,
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default,
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default,
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default,
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default,
	spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default, spi_rx_buffer_default;

.VAR spi_temporary_storage[5];	// These five (5) temporary word storage is used in order
								// to save temporary registers and this is related to 
								// the movement to make this library C language compliant.
	
	
								
.SECTION/PM seg_pmco;


///////////////////////////////////////////////////////////////////////////
//
//	_init_spi_port
//
//	Notes:  	Initializes the spi port for the dspstak platform.  For the
//				dspstak sx2/zx2, the necessary dpi pins are also connected.
//
//	Revision:   Modified register usage for C language compliance.
//
//	Date:				September 2006
//
//	Calling parameters: NONE
//	
//	Return value:		NONE
//			
//	Modified register:  r4, ustat1
//
///////////////////////////////////////////////////////////////////////////
_init_spi_port:

	DM(spi_task_complete_flags) = m5;
	DM(SPIDMAC) = m5;					// Clear spi dma register
	
	ustat1 = DM(SPICTL);
	BIT CLR ustat1 SPIEN;				// disable spi port
	DM(SPICTL) = ustat1;

	r4 = FIFOFLSH;						// flush spi fifo
	DM(SPIDMAC) = r4;
	
	DM(IISPI) 	= m5; 					// Clear all spi dma based registers			
	DM(CSPI) 	= m5; 
	DM(IMSPI) 	= m5; 
	
	// Clear write-1 bits in status register
	r4 = 0xFF;	
	DM(SPISTAT) = r4;

	ustat1 = DM(SPICTL);
	BIT CLR ustat1  SPIMS;
	DM(SPICTL) = ustat1;
	

// Configure the DPI for SPI lines		
	SRU(SPI_MOSI_O, DPI_PB01_I);
	SRU(DPI_PB02_O, SPI_MISO_I);
	SRU(SPI_CLK_O, DPI_PB03_I);
	
//  Assign the following flags for spi chip selects	
//	For boot loader piece only flash and eeprom are significant
//  SS0 - SS5 are external based (DIN) chip selects
	SRU(HIGH, DPI_PBEN05_I);			// FLASH
	SRU(HIGH, DPI_PBEN06_I);			// EEPROM
	SRU(HIGH, DPI_PBEN07_I);			// SS0 == SPI_SS
	
	SRU(SPI_FLG0_O, DPI_PB05_I);		// FLASH
	SRU(SPI_FLG1_O, DPI_PB06_I);		// EEPROM
	SRU(SPI_FLG3_O, DPI_PB07_I);		// SS0 == SPI_SS
	
// reset the spi port via the spictl register.	
	ustat1 = DM(SPICTL);					
	BIT SET ustat1 SPIEN | SPIMS;		// enable as spi master
	DM(SPICTL) = ustat1;
	
	r4 = SPI_BAUD_DEFAULT;				// declare spi default baud rate
	DM(SPIBAUD) = r4;

	r4 = 0x0F0F;						// raise all spi flags	
	DM(SPIFLG) = r4;						

	RTS;

_init_spi_port.end:


///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_init_spi_device
//
//	Notes:  Initializes the SPI parameters for spi_devices.
//
//		Device 0 just writes the SPI port
//		Device 1 is reserved for the Flash Memory
//		Device 2 is reserved fot the EEProm Memory
//		Device 10-1F is generally used by an I/O Data Converter driver
//
//		Each device provides a pointer to a spi_device_set and a pointer to a receive_buffer for 
//		the device .
//
//		The first word in the receive buffer is a packet ready register. It must be present in all 
//		transfers. The receive buffer length must be at least 1 + maximum data payload size for 
//		transmit/receive (TR) transfers. For transmit only packets (T), the receive buffer length 
//		can be only 1 word since there is no receive data.		
//	
//	Revision:  Adjusted the register usage in order to be C compliant.
//
//	Written by Danville Signal Processing
//
//	Date:					September 2006
//
//	Calling parameters: 	r4 = Device Number in form 0x??00 (see device list in spi header file)
//							r8 = ptr to an spi device setup structure
//							r12 = ptr to an spi receive buffer
//
//	spi_device_x_set[3] =
//
//		SPI baud register value  
//		SPI flag register value
//		SPI control register value
//
// 	Return value:			NONE
//			
//	Modified register:  	r4, i4, l4 ,m4
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
_init_spi_device:

	r4 = LSHIFT r4 BY -8;				// Align device to LSB

	i4 = spi_device_set_ptr;
	l4 = 0;
	m4 = r4;
	DM(m4,i4) = r8;						// save contents to spi device set ptr;
										// proportional to buffer jump
	
	i4 = spi_rx_buffer_ptr;				// save contents to spi rx buffer ptr
	DM(m4, i4) = r12;					// with the same jump
	
// At this point l4 == 0 so no need to re-write this line. For code to be 
// abiding with the C rules, all L registers should be zero (0) at exit.		
	
	RTS;
				
_init_spi_device.end:


///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_spi_disable 	
//
//	Notes:  Disables spi interface by clearing the spi enable bit 
//			and clearing the spi status register.
//
//	Revision:  Adjusted the register usage in order to be C compliant.
//
//	Written by Danville Signal Processing
//
//	Date:   				September 2006
//
//	Calling parameters: 	None
//	
//	Return values: 			None
//
//	Altered registers:		r0, ustat1
//
///////////////////////////////////////////////////////////////////////////////////////////////////
_spi_disable:

	ustat1 = DM(SPICTL);
	BIT CLR ustat1 SPIEN;	// disables the spi interface
	DM(SPICTL) = ustat1;
	
	r0 = 0xFF;
	DM(SPISTAT) = r0;		// Write 1 BITs to spi status register to clear
	RTS;

_spi_disable.end:


///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_spi_select_device
//
//	Notes:  This sub routine is done prior to making a spi transfer.  It is called primarily
//			by spi_manager.  It takes an offset value and point to the parameters set at 
//			spi_device_set_ptr. Parameters such as the spi baud and spi control values are 
//			configured as well as the flag assignments.  
//
//			For the dspstak sx2 and zx2, spi chip selects are divided into two classes one is 
//			spi flag based and the other is dpi based. The spi flag based chip selects are controled
//			by placing a value at the SPIFLG register; this only applies for the flash, eeprom and 
//			the generic SPI_SS din line.  The dpi based chip selects are controlled by manually 
//			setting the logic value of a particular dpi pin used as a chip select.
//
//			It is important to note that prior to using the spi library, the user should call the 
//			_sys_assign_pins subroutine written at the sys_dspstak_sx2_zx2.asm file. This subroutine
//			declares whether the SSx/IOx pins at the dspstak DIN connector are spi chip selects
//			or general IO pins. If a pin is declared to be an IO pin and a piece of code calls for
//			the use of the particular pin as a slave select, the spi transfer will not be valid since
//			_spi_manager will not control the non-declared slave properly.  In addition, once a pin
//			is declared as spi slave select, this pin is always driven and is not open drain.
//
//	Revision:  	Adjusted the register usage in order to be C compliant.
//				It is important to note that this routine is called by spi_manager
//				and no register preservation is needed since spi_manager has already
//				done the preservation.
//
// 	Written by Danville Signal Processing
//
//	Date:   				September 2006
//
//	Calling parameters: 	r4 = offset;		// offset is of value DEV_kk
//	
//	Return values: 			None
//
//	Altered registers:		r4, r8, i1, m4 
//
///////////////////////////////////////////////////////////////////////////////////////////////////
_spi_select_device:	

	i1 = spi_device_set_ptr;			// point to base of all device set ptr variables
	m4 = r4;							// get offset
	r4 = DM(m4, i1);					// and retrieve the variable corresponding to offset
	i1 = r4;							// now point to variable containing 3 word set
	
spi_set_regs:
	
	r4 = DM(i1,m6);						// get first word and
	DM(SPIBAUD) = r4;					// set spi baud rate
	
	r4 = SPI_FLAG_NULL;					// raise all flags and disable all flags
	DM(SPIFLG) = r4;					// spi is inactive at this point
	
	r4 = DM(i1,m6);						// get second word
	r8 = SPI_TYPE_COMPARE;				// check whether slave select is spi based or dpi based		
	COMP(r4, r8);
	IF GT JUMP spi_chip_select_spi_flag_based;

spi_chip_select_dpi_flag_based:		
	r8 = SPI_TYPE_DPI_FLAG;  	
	DM(spi_device_type) = r8;			// saves a value of 1 to si_device_type , to be used later
	DM(device_dpiflg) = r4;
	JUMP spi_set_spi_control_register;
	
spi_chip_select_spi_flag_based:	
	r8 = SPI_TYPE_SPI_FLAG;  	
	DM(spi_device_type) = r8;			// saves a value of 0 to si_device_type, to be used later
	DM(device_spiflg) = r4;
	
spi_set_spi_control_register:	
	r4 = DM(i1,m6);						// set control reg third word
	DM(SPICTL) = r4;
	DM(device_spictl) = r4;

	RTS;

_spi_select_device.end:
   


///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_spi_manager		
//
//	Notes:  Checks if SPI port needs service. Manages the spi state sequence.
//			If a condition is not satisfied within the spi sequence it returns to main loop 
//			Status is tracked by setting and tracking a state variable. 
//
//	Revision:  Adjusted the register usage in order to be C compliant.
//
// 	Written by Danville Signal Processing
//
//	Date:   				September 2006
//
//	Calling parameters: 	none
//	
//	Return values: 			none
//
//	Altered registers:		r4, r8, r12, b4, i4, m4, l4, i1, l1, ustat1
//
///////////////////////////////////////////////////////////////////////////////////////////////////
_spi_manager:

// 	Temporarily save the following two registers in order to comply to C rules
// 	DAG 4 will be primarily used for circular buffer purposes and 
//	DAG 1 will be for linear memory movement.
	DM(spi_temporary_storage + 0) = b1;
	DM(spi_temporary_storage + 1) = i1;

	r8 = DM(_spi_queue_head_ptr);			// check whether spi head and tail pointers
	r4 = DM(_spi_queue_tail_ptr);			// are equal, if not there are spi packets
	COMP(r4,r8);							// to be serviced
	IF EQ JUMP spi_manager_exit;			// Nothing so JUMP to exit
	
	ustat1 = DM(spi_task_complete_flags);	// check where in the spi state machine has
	BIT TST ustat1 SPI_EVAL_HEADER_TASK;	// been serviced
	IF TF JUMP spi_status_tests;			// an existing SPI object already is being serviced
	
spi_evaluate_header:						// SPI_EVAL_HEADER_TASK
	
	b4 = _spi_queue;						// Circ buffer DAG 4 is used for indexing head 
	i4 = DM(_spi_queue_head_ptr);			// and tail pointers
	l4 = LENGTH(_spi_queue);

	r8 = DM(i4,m5);							// get the address of the new spi object
	i1 = r8;					

	r8 = DM(i1,m6);							// current SPI header
	DM(spi_header) = r8;					// save spi object header
	DM(spi_tx_data_ptr)= i1;				// points to first data word at this point

	r12 = SPI_DEVICE_MASK;					// Device Mask
	r8 = r8 AND r12;						// Just the Device part
	r8 = LSHIFT r8 BY -8;					// right align SPI DEVICE number
	DM(spi_device) = r8;	
	
	r4 = DM(spi_previous_device);	  
	COMP (r4, r8);
	IF EQ JUMP spi_get_payload;				// SPI device is same as last time so move on
	
spi_reset_spi_parameters:					// Device has changed from last device

	r4 = r8;
	DM(spi_previous_device) = r4;			// new spi device is now the previous device

	CALL _spi_disable;						// disable all spi variables 
	CALL _spi_select_device;				// select device among 32 possible ones

spi_get_payload:
	
	r8 = DM(spi_header);					// refresh header value 
	r4 = SPI_PAYLOAD_MASK;					// get payload value
	r8 = r8 AND r4;							// payload value is in the last byte of the header
	DM(spi_payload) = r8;		

spi_special_instructions_test:
		
	ustat1 = DM(spi_header);	
	BIT TST ustat1 SPI_SPECIAL; 		
	IF TF CALL _spi_special_instructions;	// test for special instructions

spi_get_receive_buffer_address:	
	r4 = DM(spi_device);		

	i1 = spi_rx_buffer_ptr;
	m4 = r4;
 	r8 = DM(m4,i1);							// r15 contains the pointer to the receive buffer
 											// corresponding to device number
 											
	DM(spi_packet_not_ready_ptr) = r8;		// the first element of the receive packet
	
	r8 = r8 + 1;
	DM(spi_rx_data_ptr) = r8;				// Points to first receive data word (spi_rx_buffer_x[1])		
		
spi_hs_test:				

	ustat1 = DM(spi_header);
	BIT TST ustat1 SPI_HS;					// Checking to see if handshaking is on
					// If TRUE, the packet_ready register for the device must be 0
					// or the transmit will stall. This insures that received packets
					// are not overwritten. Generally, TR packets should use handshaking
					// whereas T packets will often ignore handshaking
					
	IF NOT TF JUMP spi_ss_go_lo;

spi_rx_buffer_packet_ready_test:

	i1 = DM(spi_packet_not_ready_ptr);
	r8 = DM(i1,m5);
	r8 = PASS r8;							// Checking packet ready register since handshaking is on
	IF NE JUMP spi_ss_go_lo;
	
spi_queue_stall_condition:

	DM(spi_stall) = m6;						// Sticky variable, must be reset by error handler 	

	b4 = _spi_queue;						// Must reset head to current since 
	i4 = DM(_spi_queue_head_ptr);			// this ptr now points to next item
	l4 = LENGTH(_spi_queue);
	MODIFY(i4,m7);							// Decrement by 1
	DM(_spi_queue_head_ptr) = i4;		
		
	JUMP spi_manager_exit;					// Can't continue without overwriting data, so must wait for  
											// handshake from external device handler	

spi_ss_go_lo:							

	r8 = DM(spi_device_type);				// Determine wheter spi slave select is spi flag based or dpi flag based
	r4 = SPI_TYPE_SPI_FLAG;				
	COMP(r4, r8);
	IF NE JUMP 	spi_ss_go_lo_dpi_flag;
	
spi_ss_go_lo_spi_flag:
//  For spi flag based transfers, SPIFLG is directly manipulated.
// 	Note that spi flags and FLAGS are totally orthogonal hardware entities.
	r8 = DM(device_spiflg);
	DM(SPIFLG) = r8 ;						// toggle spi flag with active low flag value
	NOP;
	NOP;
	
// At this point, the slave select is brought low.  We do need to determine wheter
// the MISO line should be enabled for this transfer	
	r4 = SPI_SEL_SS0;						// for the spi flag set, only SPI_SS0 is the external 
											// slave select that can have a miso read back
	COMP(r4, r8);							// If the slave select is other than SPI_SS0
	IF NE JUMP spi_eval_header_finished;	// there is no need to enable the MISO line.
	
	ustat1 = DM(spi_header);
	BIT TST ustat1 SPI_TR;
	IF NOT TF JUMP spi_eval_header_finished;// if transfer is transmit only we don't write
											// the system register B that enables the miso line
											
	SET_SS0_MISO_ENA_BIT;					// This macro writes sys register B to enable the miso line
											// initiated by SPI_SS0.
	
	JUMP spi_eval_header_finished;
	
spi_ss_go_lo_dpi_flag:												
//  For dpi flag based transfers, FLAGS is directly manipulated.
//  Note that at this point _sys_assign_pins have already configured the flag pins running via the dpi
//  as ouptuts so we only need to bit set or clear the appropriate values.

	
	
	r8 = DM(device_dpiflg);					// Get bit position where FLAG bit should go low
	r4 = DM(_declared_expansion_spi_ss);	// Check whether declared ext spi slave selects	
	r4 = r8 AND r4;							// have been proper initialized in _sys_assign_pins
	r4 = pass r4;							// If The result of the AND operation is zero
	IF EQ JUMP spi_check_ext_dpi_flg_error; // there is an error in the assignment of pins	
	
// Arriving in this section, only signifies that declared spi slave selects have been initialized
// correctly.
	r8 = NOT r8;							// Invert Bit value
	
	r4 = FLAGS;								// Get current FLAGs value
	r8 = r8 AND r4;							// Bit location of interest is cleared
	FLAGS = r8;								// FLAGs value is updated

	
// At this point, the SSx (SS1 to SS5) has been lowered, we need to determine wheter
// the spi transfer will involve a miso read line.			
	ustat1 = DM(spi_header);
	BIT TST ustat1 SPI_TR;
	IF NOT TF JUMP spi_eval_header_finished;// if transfer is transmit only we don't write
											// system regiter B
											
// Check if dpi flag corresponds to SS1
	r8 = DM(device_dpiflg);					// Get bit position 
	r4 = SPI_SEL_SS1;
	COMP(r4, r8);							// and check if this the dpi spi chip select to be used.
	IF NE JUMP spi_check_ext_dpi_flg_ss2;	// if not equal check other possbile dpi_flag_ssx values.
	
	SET_SS1_MISO_ENA_BIT;					// Macro that writes sys register B to enable miso line
	JUMP spi_eval_header_finished;			// in response to SS1 spi chip select
	

spi_check_ext_dpi_flg_ss2:		
// Check if dpi flag corresponds to SS2
	r8 = DM(device_dpiflg);					// Get bit position 
	r4 = SPI_SEL_SS2;		
	COMP(r4, r8);							// and check if this the dpi spi chip select to be used.
	IF NE JUMP spi_check_ext_dpi_flg_ss3;	// if not equal check other possbile dpi_flag_ssx values.
	
	SET_SS2_MISO_ENA_BIT;					// Macro that writes sys register B to enable miso line
	JUMP spi_eval_header_finished;			// in response to SS2 spi chip select

spi_check_ext_dpi_flg_ss3:
// Check if dpi flag corresponds to SS3
	r8 = DM(device_dpiflg);					// Get bit position 
	r4 = SPI_SEL_SS3;	
	COMP(r4, r8);							// and check if this the dpi spi chip select to be used.
	IF NE JUMP spi_check_ext_dpi_flg_ss4;   // if not equal check other possbile dpi_flag_ssx values
	
	SET_SS3_MISO_ENA_BIT;					// Macro that writes sys register B to enable miso line
	JUMP spi_eval_header_finished;			// in response to SS2 spi chip select

spi_check_ext_dpi_flg_ss4:
// Check if dpi flag corresponds to SS4
	r8 = DM(device_dpiflg);					// Get bit position 
	r4 = SPI_SEL_SS4;	
	COMP(r4, r8);							// and check if this the dpi spi chip select to be used.
	IF NE JUMP spi_check_ext_dpi_flg_ss5;	// if not equal check other possbile dpi_flag_ssx values.
	
	SET_SS4_MISO_ENA_BIT;					// Macro that writes sys register B to enable miso line
	JUMP spi_eval_header_finished;			// in response to SS4 spi chip select
	
spi_check_ext_dpi_flg_ss5:
// Check if dpi flag corresponds to SS5
	r8 = DM(device_dpiflg);					// Get bit position 
	r4 = SPI_SEL_SS5;	
	COMP(r4, r8);							// and check if this the dpi spi chip select to be used.
	IF NE JUMP spi_check_ext_dpi_flg_error;

	SET_SS5_MISO_ENA_BIT;					// Macro that writes sys register B to enable miso line
	JUMP spi_eval_header_finished;			// in response to SS5 spi chip select
	
spi_check_ext_dpi_flg_error:
	
	r8 = ILLEGAL_SPI_SS_USE;				// At this point there is not a valid
	DM(spi_error_msg) = r8;					// spi chip select value declared. 
											// In effect no further spi transfers are executed till fixed.
	JUMP spi_manager_exit;
																						
spi_eval_header_finished:

	r8 = SPI_EVAL_HEADER_TASK;				// At this point the baud, spi control and spi flag registers
	DM(spi_task_complete_flags) = r8;		// are set.  Next step is to be ready for actual spi transfer.

spi_write_data:

	i1 = DM(spi_tx_data_ptr);				// Write a word from the current tx buffer	
	r8 =DM(i1,m6);							// Get word and spi transmit.
	DM(spi_tx_data_ptr) = i1;					
	DM(TXSPI) = r8;							
	
spi_status_tests:
		
spi_txstest:								
   	
	ustat1 = DM(spi_task_complete_flags);	// check if this TASK is done
	BIT TST ustat1 SPI_TXS_TASK;
	IF TF JUMP spi_spif_test;				// if yes go to next TASK

	ustat1 = DM(SPISTAT);		
	BIT TST ustat1 TXS;						// check if TX buffer is still full
	IF TF JUMP spi_manager_exit;			

spi_txs_okay:    				

	r8 =  SPI_TXS_TASK | SPI_EVAL_HEADER_TASK;
	DM(spi_task_complete_flags) = r8;	 

spi_spif_test:	

	ustat1 = DM(spi_task_complete_flags);	// check if TASK is done
	BIT TST ustat1 SPI_SPIF_TASK;
	IF TF JUMP spi_rxs_okay;
						
	ustat1 = DM(SPISTAT);		
	BIT TST ustat1 SPIF;					// check if spi finish flag is set
	IF NOT TF JUMP spi_manager_exit;		// if not set exit spi manager 	
			
spi_spif_okay:
				
	r4 = SPI_SPIF_TASK | SPI_TXS_TASK | SPI_EVAL_HEADER_TASK;
	DM(spi_task_complete_flags) = r4;	 
			
spi_rxs_okay:
					
	r4 = DM(RXSPI);					 		// read from spi receive buffer 

	ustat1 = DM(spi_header);				// check if this transfer is transmit AND receive
	BIT TST ustat1 SPI_TR;
	IF NOT TF JUMP spi_check_count;			// if transfer is transmit only we don't write
											// to the receive buffer.
	
	i1 = DM(spi_rx_data_ptr);
	DM(i1,m6) = r4;		
	DM(spi_rx_data_ptr) = i1;
		
spi_check_count:

	r8 = DM(spi_payload); 
	r8 = r8 - 1;							// decrement payload counter
	DM(spi_payload) = r8;
	IF  LT JUMP spi_ss_go_hi;				// if number of exchanges is zero lift SS line if needed

spi_more_data:

	r8 = SPI_EVAL_HEADER_TASK;				// We've already started the packet	
	DM(spi_task_complete_flags) = r8;					

	JUMP spi_write_data;					// Write the next word 

spi_ss_go_hi:				

	r8 = DM(spi_device_type);				// Determine whether spi slave select is spi flag based or dpi flag based
	r4 = SPI_TYPE_SPI_FLAG;				
	COMP(r4, r8);
	IF NE JUMP spi_ss_go_hi_dpi_flag;

spi_ss_go_hi_spi_flag:

	r8 = SPI_FLAG_NULL;
	DM(SPIFLG)  = r8;						// disable all flags
	
	JUMP spi_clear_ext_spi_miso_enable;
	
spi_ss_go_hi_dpi_flag:	
	
	r8 = DM(device_dpiflg);					// Get bit position where FLAG bit should go low
	r4 = FLAGS;								// Get current FLAGs value
	r8 = r8 OR r4;							// Bit location of interest as slave select is set
	FLAGS = r8;								// FLAGs value is updated

spi_clear_ext_spi_miso_enable:

	ustat1 = DM(spi_header);
	BIT TST ustat1 SPI_TR;
	IF NOT TF JUMP spi_end_transfer;		// if transfer is transmit only we don't write
											// the io control register that enables the external 
											// miso line		

	CLR_ALL_MISO_ENA_BITS;					// Macro clears the register that enables the external miso line.
											// This covers SS0 through SS5.	Written in sys_dspstak_sx2_zx2.h
spi_end_transfer: 	
	b4 = _spi_queue;						// Circ buffer i4 is used for indexing head and tail pointers
	i4 = DM(_spi_queue_head_ptr);	
	l4 = LENGTH(_spi_queue);

	MODIFY(i4,m6);							// increment head pointer 
	DM(_spi_queue_head_ptr) = i4;			// save  and update
	

	DM(spi_task_complete_flags) = m5; 		// clear all TASK flags
	i1 = DM(spi_packet_not_ready_ptr);
	
	r4 = m5;
	DM(i1,m5) = r4;							// clear first word to signify end of spi transfer
				
spi_manager_exit:

	b1 = DM(spi_temporary_storage + 0);		// Restore the b1 and i1 registers upon exit
	i1 = DM(spi_temporary_storage + 1);		// for C language compliance
	
	l1 = 0;									// Ensure that all used L registers are set to zero.
	l4 = 0;
	
	RTS;
	
_spi_manager.end:	


///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_spi_add_queue		
//
//	Notes:  Adds a spi packet to the SPI service queue.   
//
// 	Written by Danville Signal Processing
//
//	Revision:  Adjusted the register usage in order to be C compliant.
//
//	Date:   				September 2006
//
//	Calling parameters: 	r4 <-- address of the SPI object
//	
//	Return values: 			none
//
//	Altered registers:		DAG 4 (b4, i4, l4)
//
///////////////////////////////////////////////////////////////////////////////////////////////////

_spi_add_queue:

	b4 = _spi_queue;						// Circ buffer DAG 4 is used for indexing head and tail pointers
	l4 = LENGTH(_spi_queue);
	i4 = DM(_spi_queue_tail_ptr);

	DM(i4,m6) = r4;							// Place a new spi packet (address) on the queue 
	DM(_spi_queue_tail_ptr) = i4;			// Save new value for tail pointer
	
	l4 = 0;									// Set L register to zero to abide to C rules;
	
	RTS;

_spi_add_queue.end:


///////////////////////////////////////////////////////////////////////////////////////////////////
//
//	_spi_special_instructions	USER defined
//
//	Notes:  This code allows the user to have additional settings for any other possible situation
//			that the SPI protocol does not cover. This can be invoked by BIT 15 definition
//
//	Date:   				8 May 04
//
//	Calling parameters: 	USER defined
//	
//	Return values: 			USER defined
//
//	Altered registers:		USER defined,take precaution
//
///////////////////////////////////////////////////////////////////////////////////////////////////

_spi_special_instructions:
	
	RTS;

_spi_special_instructions.end:


