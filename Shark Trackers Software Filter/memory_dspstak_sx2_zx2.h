/////////////////////////////////////////////////////////////////////////
//
// File:	memory_dspstak_sx2_zx2.h
// Version:	1.00
// Build 	1.00
// Tools:	Visual DSP 4.0
//
// dspstak sx2 zx2 User Memory Library Header
//
// Date:	15 July 06
//
// Author:	Danville Signal Processing, Inc.
//
// http://www.danvillesignal.com
//
/////////////////////////////////////////////////////////////////////////

//- - - - - - - -   FLASH SECTION START

// The following definitions are used to determine what flash devices are detected
// by the system

#define FL_MISMATCH					-1
#define FL_INVALID_DEVICE			0			
#define FL_ATMEL_AT26F004			1
#define FL_STMICRO_25VF040			2
// Note: Later Flash devices can be added here.
#define FL_DECLARED_DEVICE			FL_ATMEL_AT26F004


#define FL_RD_ID_STMICRO	0xAB
#define FL_STMICRO_MANF_ID	0xBF
#define FL_STMICRO_DEV_ID	0x44

#define FL_RD_ID_ATMEL		0x9F
#define FL_ATMEL_MANF_ID	0x1F
#define FL_ATMEL_DEV_ID		0x04


// FL low level commands ST 25VF040
#if FL_DECLARED_DEVICE == FL_STMICRO_25VF040
#define FL_WRSR				0x01
#define FL_WR_BYTE			0x02
#define FL_RD_BYTE			0x03
#define FL_WRDI				0x04
#define FL_RDSR				0x05
#define FL_WREN				0x06
#define FL_SECTOR_ERASE		0x20
#define FL_EWSR				0x50
#define FL_BLOCK_ERASE		0x52
#define FL_WR_AAI			0xAF 

// FL USER COMMANDS FOR SST FLASH

#define FL_CMD_STATUS			0x0
#define FL_CMD_PROTECT			0x1
#define FL_CMD_UNPROTECT		0x2
#define FL_CMD_ERASE_SECTOR		0x3
#define FL_CMD_WRITE32			0x4
#define FL_CMD_READ32			0x5
#define FL_CMD_WRITE_SECTOR		0x6
#define FL_CMD_READ_SECTOR		0x7
#define FL_INVALID_CMD			0x8		// this should always be the highest number

#elif FL_DECLARED_DEVICE == FL_ATMEL_AT26F004
// FL low level commands ATMEL AT26F004
#define FL_WRSR					0x01
#define FL_WR_BYTE				0x02
#define FL_RD_BYTE				0x03
#define FL_WRDI					0x04
#define FL_RDSR					0x05
#define FL_WREN					0x06
#define FL_SECTOR_ERASE			0x20		// This erases a 4 KB Sector
// Note: This part has a 64 KB erase function but not included in the library
// because user only has 32 KB only.
#define FL_EWSR					0x06
#define FL_WR_AAI				0xAF
// Note the following three flash low level commands are related to the new
// protection features for the ATMEL spi flash memory chip.
#define FL_PROTECT_SECTION		0x36		
#define FL_UNPROTECT_SECTION	0x39
#define FL_RD_PROT_REG			0x3C


#define FL_CMD_STATUS				0x0
#define FL_CMD_PROTECT				0x1
#define FL_CMD_UNPROTECT			0x2
#define FL_CMD_ERASE_SECTOR			0x3
#define FL_CMD_WRITE32				0x4
#define FL_CMD_READ32				0x5
#define FL_CMD_WRITE_SECTOR			0x6
#define FL_CMD_READ_SECTOR			0x7
#define FL_CMD_PROTECT_SECTION		0x8
#define FL_CMD_UNPROTECT_SECTION	0x9
#define FL_CMD_READ_PROTECT_REG		0xA
#define FL_INVALID_CMD				0xB		// this should always be the highest number

#endif

#define FL_QUEUE_SKIP			0x4		// used to maintain four word boundary

// FL - SPI definitions
#define FL_MSG_LOG_SIZE			100
#define FL_QUEUE_SIZE			100

// FL-SPI transfer basic BIT states
// STEPx states are only involved when there has to be more
// than one spi transfers to accomplish a complex flash command

#define FL_SPI_INIT				0x1
#define FL_SPI_WAIT				0x2
#define FL_SPI_STEP1			0x4
#define FL_SPI_STEP2			0x8
#define FL_SPI_STEP3			0x10
#define FL_SPI_STEP4			0x20
#define FL_SPI_STEP5			0x40
#define FL_SPI_SECTOR_INIT		0x80		// only used in sector commands
#define FL_SPI_SECTOR_SETUP		0x100
#define FL_SPI_DONE				0x200

// defining a command is on a word transfer or a sector transfer
#define FL_SECTOR_CMD			0x1
#define FL_WORD_CMD				0x0

// FL Memory boundary definitions
#define FL_BLOCK_SIZE			32768
#define FL_USER_BLOCK_NUM		15
#define FL_USER_START_ADDR		0x78000

// FL 8 bit user context
#define FL_BASE_ADDR			0x78000
#define FL_MAX_ADDR				0x7FFFF

#define FL_ADDR_INC32			0x4
#define FL_BYTE_MASK			0xFF

#define FL_SECTOR_INIT_MASK		0x70000
#define FL_SECTOR_END_MASK		0x7FF00

// FL 32 bit user context
#define FL_USER_START32			0x0
#define FL_USER_END32			0x1FFF

// FL Basic byte transfer spi locations
#define FL_MSADDR				0x2
#define FL_MIDADDR				0x3
#define FL_LSADDR				0x4
#define FL_DATA_LOCATION		0x5

// FL user sector assignments		
#define FL_SECTOR0				0x80		// mid byte address for sectors
#define FL_SECTOR1				0x90
#define FL_SECTOR2				0xA0
#define FL_SECTOR3				0xB0
#define FL_SECTOR4				0xC0
#define FL_SECTOR5				0xD0
#define FL_SECTOR6				0xE0
#define FL_SECTOR7				0xF0

#define FL_SECTOR_SIZE			1024		// 1 K words in a sector

// FL section assignments (only applicable for AT26F004)
#define FL_ATMEL_SECTION1			0x80		// section from 0x78000 - 0x79FFF
#define FL_ATMEL_SECTION2			0xA0		// section from 0x7A000 - 0x7BFFF
#define FL_ATMEL_SECTION3			0xC0		// section from 0x7C000 - 0x7FFFF


#define FL_ATMEL_SECTION_PROTECTED		0xFF	// value of section protection register if protected
#define FL_ATMEL_SECTION_UNPROTECTED	0x00	// value of section protection register if unprotected

// Common FL spi length	used in defining spi packets
#define FL_SEND2				0x01
#define FL_SEND3				0x02
#define FL_SEND4				0x03
#define FL_SEND5				0x04
#define FL_SEND6				0x05
#define FL_SEND7				0x06
#define FL_SEND8				0x07

// FL status bits for the STMICRO 25VF040
#define FL_BUSY_BIT				0x01
#define FL_WEL_BIT				0x02
#define FL_BP0_BIT				0x04
#define FL_BP1_BIT				0x08
#define FL_AAI_BIT				0x40
#define FL_BPL_BIT				0x80

// FL status bits for the ATMEL AT26F004
#define FL_SWP_BIT0				0x04
#define FL_SWP_BIT1				0x08
#define FL_WP_PIN_STAT			0x10
#define FL_SPRL_BIT				0x80
// Note: Bits FL_BUSY_BIT, FL_WEL_BIT and FL_AAI_BIT have the same bit location
// with the STMICRO part


// Global Flash routines
.EXTERN _init_user_flash;			// initialization for user flash
.EXTERN _flash_add_queue;			// adding a flash command to the queue
.EXTERN _flash_manager;				// flash command manager, works with spi manager

// GLOBAL Flash variables
.EXTERN flash_dev_id;				// device id	
.EXTERN flash_manf_id;				// manufacturer id

.EXTERN flash_queue;				// buffer where flash commands are stored
.EXTERN flash_queue_head_ptr;
.EXTERN flash_queue_tail_ptr;

.EXTERN flash_msg_log;				// buffer where users can keep track what flash commands have been serviced
.EXTERN flash_msg_log_head_ptr;		// each entry is 4 word
.EXTERN flash_msg_log_tail_ptr;

//- - - - - - - -   FLASH SECTION END


//- - - - - - - -   EEPROM SECTION START

// EEPROM write type
#define EE_STATUS_TYPE			0x00
#define EE_DATA_TYPE			0x01

// EEPROM status bit locations
#define EE_STATUS_WPEN			0x80	
#define EE_STATUS_BP1			0x08		// bit protection bit
#define EE_STATUS_BP0			0x04
#define EE_STATUS_WEL			0x02		// write enable latch
#define EE_STATUS_WIP			0x01		// write in progress

// EEPROM address boundaries
#define EE_MIN_ADDR				0x0000
#define EE_MAX_ADDR				0x1FFF

// EEPROM commands
#define EE_WRSR					0x01		// write status register
#define EE_WRITE				0x02		// write data 
#define EE_READ					0x03		// read data
#define EE_WRDI					0x04		// disable write operations
#define EE_RDSR					0x05		// read status register
#define EE_WREN					0x06		// enable write operations

// EE spi length	used in defining spi packets
#define EE_SEND2				0x01
#define EE_SEND3				0x02
#define EE_SEND4				0x03
#define EE_SEND5				0x04
#define EE_SEND6				0x05
#define EE_SEND7				0x06
#define EE_SEND8				0x07

#define EE_QUEUE_SIZE			60
#define EE_MSG_LOG_SIZE			60

// EEPROM USER commands
#define EE_CMD_STATUS			0x0
#define EE_CMD_PROTECT			0x1
#define EE_CMD_UNPROTECT		0x2
#define EE_CMD_READ8			0x3
#define EE_CMD_READ16			0x4
#define EE_CMD_READ32			0x5
#define EE_CMD_WRITE8			0x6
#define EE_CMD_WRITE16			0x7
#define EE_CMD_WRITE32			0x8
#define EE_INVALID_CMD			0x9			// this should always be the highest

#define EE_QUEUE_SKIP			0x3


// EEPROM state machine bits
#define EE_SPI_INIT				0x1
#define EE_SPI_STEP1			0x2
#define EE_SPI_STEP2			0x4
#define EE_SPI_STEP3			0x8
#define EE_SPI_WAIT				0x10
#define EE_SPI_DONE				0x20


// GLOBAL eeprom functions
.EXTERN _init_user_eeprom;
.EXTERN _eeprom_add_queue;
.EXTERN _eeprom_manager;

// GLOBAL eeprom variables
.EXTERN eeprom_queue;
.EXTERN eeprom_queue_head_ptr;
.EXTERN eeprom_queue_tail_ptr;

.EXTERN eeprom_msg_log;
.EXTERN eeprom_msg_log_head_ptr;
.EXTERN eeprom_msg_log_tail_ptr;

.EXTERN eeprom_receive_buffer;

//- - - - - - - -   EEPROM SECTION END


.EXTERN _complete_mem_spi_transfer;



