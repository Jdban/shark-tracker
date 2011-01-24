#include <filter.h>
#include <signal.h>
#include <stdio.h>
#include <processor_include.h>
#include "init.h"
#include "uart.h"
#include "sharc.h"
#include "sys.h"
 
char buf[256];

#define TAPS 68
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
	// NOTE: This is a BPF that has a passband from 0.35 to 0.38 
	//       of the sampling rate and a 40 dB attenuation

}

void timer_handler(int signal)
{
	process_signal_ready = 1;
}

void main(void)
{
	int adc_voltage;
	
	initialize();
	initialize_fir();
	
	interrupt(SIG_TMZ, timer_handler);
	timer_set((unsigned int)16160000, (unsigned int)16160000);
	timer_on();
	
	for(;;)
	{
		// Update the UART driver
		uart_update();
		
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
			if (h1_out[0] >= 0.6f)
			{
				snprintf(buf, 256, "%f\r\n", h1_out[0]);
				uart_write(buf);
			}
			else
			{
				uart_write("0\r\n");
			}
		}
	}
}
