#include "init.h"
#include "uart.h"
#include "signal.h"
#include "sys.h"
 
void main(void)
{
	initialize();
	
	for(;;)
	{
		uart_port_manager();
		
		if (process_signal_ready)
		{
			process_signal_ready = 0;
			get_adc1_ch0();
		}
	}
}
