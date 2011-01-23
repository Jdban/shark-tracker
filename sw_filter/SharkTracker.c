#include <filter.h>
#include "init.h"
#include "uart.h"
#include "signal.h"
#include "sys.h"
 
#define TAPS 10
float pm coeffs[TAPS];
float h1_in[1], h1_out[1];
float h1_state[TAPS+1];

void initialize_fir(void)
{
	int i;
	
	// Initialize the state arrays
	for (i = 0; i < TAPS+1; i++)
	{
		h1_state[i] = 0;
	}	
	
	// Initialize the coefficients
	// TODO
}

void main(void)
{
	int adc_voltage;
	
	initialize();
	initialize_fir();
	
	for(;;)
	{
		// Check the UART buffer and push out any buffered chars
		uart_port_manager();
		
		// Check if we are ready to sample
		if (process_signal_ready)
		{
			// Get Hydrophone 1 Voltage
			process_signal_ready = 0;
			adc_voltage = get_adc1_ch0();
			h1_in[0] = adc_voltage * 3.3f / 1024.0f;
			
			// Filter
			fir (h1_in, h1_out, coeffs, h1_state, 1, TAPS);
			
			// Output high or low
			if (h1_out[0] < 1.0f)
			{
				puts_uart("0\n");
			}
			else
			{
				puts_uart("1\n");
			}
		}
	}
}
