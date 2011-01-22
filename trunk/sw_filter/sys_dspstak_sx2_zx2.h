/////////////////////////////////////////////////////////////////////////
//
// File:	sys_dspstak_sx2_zx2.h
// Version:	1.01
// Build 	1.00 
// Tools:	Visual DSP 4.5
//
// System Library Header
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
#define PLL_DIV_MAX		PLLD2
#define PLL_MUL_MAX		PLLM23		

#elif defined(__ADSP21369__)
#include <def21369.h>
#define PLL_DIV_MAX		PLLD2
#define PLL_MUL_MAX		PLLM30		
#endif	


#define AMI_PORT2_SETTING AMIEN | BW32 | PKDIS | WS31 |  IC7 | HC2 | RHC2

// global functions
.EXTERN _init_ext_port;
.EXTERN	_init_timer;
.EXTERN _timer_1s;
.EXTERN _timer_5us;

.EXTERN _sys_set_coreclock;
.EXTERN _sys_assign_pins;

.EXTERN _write_io_control_register;
.EXTERN _set_io_control_register_bit;
.EXTERN _clr_io_control_register_bit;

.EXTERN _read_io_control_register;
.EXTERN _read_sys_mode;
.EXTERN _read_cts_value;
.EXTERN _sys_force_delay;

// global variables
.EXTERN	_timer_ticks;						
.EXTERN _io_control_register_A;					
.EXTERN _io_control_register_B;					

.EXTERN _sys_mode;
.EXTERN _uart_cts_status;
.EXTERN _uart_rts_status;

.EXTERN _gp_io_0_dir;
.EXTERN _gp_io_0_val;

.EXTERN _gp_io_1_dir;
.EXTERN _gp_io_1_val;

.EXTERN _uart_rts_bit_status;
.EXTERN _uart_cts_bit_status;

.EXTERN _hi_speed_usb_reset_bit_status;
.EXTERN _io_reset_bit_status;
.EXTERN _clock_bank_switch_bit_status;

.EXTERN _peripheral_control_status;		
.EXTERN _spi_miso_enable_status;
.EXTERN _declared_expansion_spi_ss;	

.EXTERN _process_signal_ready;	

/////////////////////////////////////////////////////////////////////////
//
//	Note for C users
//
// 	If the functions for the sys library is used with some C
//	coding the user should use the following external declarations so
//	that the C code can call the sys functions and utilize the uart 
//	variables.  
/*

// global functions
extern void init_ext_port(void);
extern void	init_timer(void);
extern void timer_1s(void);

extern void sys_set_coreclock(multiplier, divider);
extern void sys_assign_pins(type, direction);

extern void write_io_control_register(reg_addr,byte_val);
extern void set_io_control_register_bit(reg_addr,bit_location);
extern void clr_io_control_register_bit(reg_addr,bit_location);;

extern int read_io_control_register(reg_addr);
extern int read_sys_mode(void);
extern int read_cts_value(void);
extern void sys_force_delay(delay_val);

// global variables
extern void	timer_ticks;						
extern void io_control_register_A;					
extern void io_control_register_B;					
extern void sys_mode;
extern void uart_cts_status;
extern void uart_rts_status;

extern void gp_io_0_dir;
extern void gp_io_0_val;
extern void gp_io_1_dir;
extern void gp_io_1_val;
extern void uart_rts_bit_status;
extern void uart_cts_bit_status;

extern void hi_speed_usb_reset_bit_status;
extern void io_reset_bit_status;
extern void clock_bank_switch_bit_status;
extern void peripheral_control_status;		
extern void spi_miso_enable_status;
extern void declared_expansion_spi_ss;		

*/
/////////////////////////////////////////////////////////////////////////


#define TICK_SYS		_timer_ticks	
#define TICK_PM			_timer_ticks + 1
#define TICK_WD			_timer_ticks + 2
#define TICK_1S			_timer_ticks + 3
#define TICK_USER1		_timer_ticks + 4
#define TICK_USER2		_timer_ticks + 5
#define TICK_USER3		_timer_ticks + 6
#define TICK_USER4		_timer_ticks + 7

#define TICK_4us_BIT	0
#define TICK_8us_BIT	1
#define TICK_16us_BIT	2
#define TICK_31us_BIT	3
#define TICK_62us_BIT	4
#define TICK_125us_BIT	5
#define TICK_250us_BIT	6
#define TICK_500us_BIT	7
#define TICK_1ms_BIT	8
#define TICK_2ms_BIT	9
#define TICK_4ms_BIT	10
#define TICK_8ms_BIT	11
#define TICK_16ms_BIT	12
#define TICK_32ms_BIT	13
#define TICK_64ms_BIT	14
#define TICK_128ms_BIT	15
#define TICK_256ms_BIT	16
#define TICK_512ms_BIT	17
#define TICK_1024ms_BIT	18
#define TICK_2048ms_BIT	19




#if defined(__ADSP21375__)

#define TPERIOD_VAL		995
#define TCOUNT_VAL		995
#elif defined(__ADSP21369__)

// 1293 = 4us           (base)
// 1616 = 5us	200ksps (73khz hydrophone)
// 6465 = 20us	 50ksps (test)
#define TPERIOD_VAL		64650
#define TCOUNT_VAL		64650
#endif	

#define NO_SDRAM		0
#define SDRAM			1


#define SYS_REG_ADDR_A 	DM(0x08000000)
#define SYS_REG_ADDR_B 	DM(0x08000001)


// System Register A Bit Definitions
// Write Bit Locations
#define IO_RESET_BIT		0x00
#define HI_SPD_USB_BIT		0x01
#define CYC_S2_PIN_BIT		0x02
#define EXT_DEV_CTRL_MASK	0x07

#define UART_RTS_BIT		0x03
#define GP0_VAL_BIT			0x04
#define GP1_VAL_BIT			0x05
#define GP0_DIR_BIT			0x06
#define GP1_DIR_BIT			0x07

#define GP0_DIR_OUT			0x20
#define GP1_DIR_OUT			0x80

// Read Bit Definitions
#define SYS_MODE_MASK		0x07
#define UART_CTS_BIT		0x08


// System Register B Bit Definitions
// Write Bit Definitions
#define SS0_MISO_ENA_BIT	0x00
#define SS1_MISO_ENA_BIT	0x01
#define SS2_MISO_ENA_BIT	0x02
#define SS3_MISO_ENA_BIT	0x03
#define SS4_MISO_ENA_BIT	0x04
#define SS5_MISO_ENA_BIT	0x05
#define SSx_MISO_MASK		0x07


// The following bit definitions are used to declare the pin use for SS1/IO0 to SS5/IO4
// All five pins are connected to the dpi interface and each pin can be used as a bidirectional
// IO pin or a spi chip select.  When a pin is used as a spi slave select this pin will be
// always driven.  At reset, the default state of these pins are inputs with a weak pull up.
// So at reset, the trivial value for the state of the SSx/IOx pins are 
//
//	pin type TYPE_IO0	| 	TYPE_IO1 	| 	TYPE_IO2		|	TYPE_IO3 	|	TYPE_IO4											
//	IO type  IO0_DIR_IN	|	IO1_DIR_IN	| 	IO2_DIR_IN		|	IO3_DIR_IN	|	IO4_DIR_IN

#define SYS_ASSIGN_MASK		0xFF03		// only covers bit definitions for flags 0 and 4 to 7
#define SPI_EXP_VAL_MASK	FLG0  | FLG4  | FLG5  | FLG6  | FLG7 
#define SPI_EXP_DIR_MASK	FLG0O | FLG4O | FLG5O | FLG6O | FLG7O 
#define FLAG_EXP_DIR_MASK	FLG0O | FLG4O | FLG5O | FLG6O | FLG7O 

#define IO4_SS5_FLAG_DIR	FLG0O
#define IO3_SS4_FLAG_DIR	FLG7O
#define IO2_SS3_FLAG_DIR	FLG6O
#define IO1_SS2_FLAG_DIR	FLG5O
#define IO0_SS1_FLAG_DIR	FLG4O

#define TYPE_SPI5	   	FLG0O
#define TYPE_SPI4   	FLG7O
#define TYPE_SPI3	   	FLG6O
#define TYPE_SPI2	   	FLG5O
#define TYPE_SPI1	   	FLG4O

#define SPI_SS5_ACTIVE  0x00
#define SPI_SS4_ACTIVE  0x00
#define SPI_SS3_ACTIVE  0x00
#define SPI_SS2_ACTIVE  0x00
#define SPI_SS1_ACTIVE  0x00

#define TYPE_IO4	   	0x00
#define TYPE_IO3   		0x00
#define TYPE_IO2	   	0x00
#define TYPE_IO1	   	0x00
#define TYPE_IO0	   	0x00

#define IO0_DIR_IN		0x00
#define IO1_DIR_IN		0x00
#define IO2_DIR_IN		0x00
#define IO3_DIR_IN		0x00
#define IO4_DIR_IN		0x00

#define IO4_DIR_OUT		FLG0O
#define IO3_DIR_OUT		FLG7O
#define IO2_DIR_OUT		FLG6O
#define IO1_DIR_OUT		FLG5O
#define IO0_DIR_OUT		FLG4O

// The following are macros associated to writing bit values for sys registers A and B

#define SET_DIN_IO_RESET	 			\
					r4 = 0;				\
					r8 = IO_RESET_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_DIN_IO_RESET				\
					r4 = 0;				\
					r8 = IO_RESET_BIT;	\
					CALL _clr_io_control_register_bit;

#define SET_HI_SPEED_RESET_PIN 			\
					r4 = 0;				\
					r8 = HI_SPD_USB_BIT;\
					CALL _set_io_control_register_bit;


#define CLR_HI_SPEED_RESET_PIN 			\
					r4 = 0;				\
					r8 = HI_SPD_USB_BIT;\
					CALL _clr_io_control_register_bit;

					
#define SET_CLK_BANK_SWITCH				\
					r4 = 0;				\
					r8 = CYC_S2_PIN_BIT;\
					CALL _set_io_control_register_bit;


#define CLR_CLK_BANK_SWITCH				\
					r4 = 0;				\
					r8 = CYC_S2_PIN_BIT;\
					CALL _clr_io_control_register_bit;



#define SET_RTS_BIT						\
					r4 = 0;				\
					r8 = UART_RTS_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_RTS_BIT						\
					r4 = 0;				\
					r8 = UART_RTS_BIT;	\
					CALL _clr_io_control_register_bit;
										

#define SET_GP0_VAL_BIT					\
					r4 = 0;				\
					r8 = GP0_VAL_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_GP0_VAL_BIT					\
					r4 = 0;				\
					r8 = GP0_VAL_BIT;	\
					CALL _clr_io_control_register_bit;
					

#define SET_GP1_VAL_BIT					\
					r4 = 0;				\
					r8 = GP1_VAL_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_GP1_VAL_BIT					\
					r4 = 0;				\
					r8 = GP1_VAL_BIT;	\
					CALL _clr_io_control_register_bit;
										

#define SET_GP0_DIR_BIT					\
					r4 = 0;				\
					r8 = GP0_DIR_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_GP0_DIR_BIT					\
					r4 = 0;				\
					r8 = GP0_DIR_BIT;	\
					CALL _clr_io_control_register_bit;
					

#define SET_GP1_DIR_BIT					\
					r4 = 0;				\
					r8 = GP1_DIR_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_GP1_DIR_BIT					\
					r4 = 0;				\
					r8 = GP1_DIR_BIT;	\
					CALL _clr_io_control_register_bit;
										
					
/////

#define SET_SS0_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS0_MISO_ENA_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_SS0_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS0_MISO_ENA_BIT;	\
					CALL _clr_io_control_register_bit;
										
					
#define SET_SS1_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS1_MISO_ENA_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_SS1_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS1_MISO_ENA_BIT;	\
					CALL _clr_io_control_register_bit;
					
#define SET_SS2_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS2_MISO_ENA_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_SS2_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS2_MISO_ENA_BIT;	\
					CALL _clr_io_control_register_bit;
					
#define SET_SS3_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS3_MISO_ENA_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_SS3_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS3_MISO_ENA_BIT;	\
					CALL _clr_io_control_register_bit;

#define SET_SS4_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS4_MISO_ENA_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_SS4_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS4_MISO_ENA_BIT;	\
					CALL _clr_io_control_register_bit;
										
#define SET_SS5_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS5_MISO_ENA_BIT;	\
					CALL _set_io_control_register_bit;


#define CLR_SS5_MISO_ENA_BIT				\
					r4 = 1;					\
					r8 = SS5_MISO_ENA_BIT;	\
					CALL _clr_io_control_register_bit;
					

#define CLR_ALL_MISO_ENA_BITS				\
					r4 = 1;					\
					r8 = 0;					\
					CALL _write_io_control_register;				
				
					
									
