#include <filter.h>
#include <signal.h>
#include <stdio.h>
#include <processor_include.h>
#include <stdint.h>
#include "init.h"
#include "uart.h"
#include "sharc.h"
 
char buf[256];

#define TAPS 14
float pm a[TAPS];
float dm h1_in[1], h1_out[1];
float dm h1_state[TAPS+1];
uint32_t dm adc_voltage;
uint32_t dm counter = 0;
uint32_t process_signal_ready = 0;

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
	a[13-0] =	-0.04159025868126048;
	a[13-1] =	0.03437803608088014;
	a[13-2] =	-0.032489477830945114;
	a[13-3] =	0.01178776838931864;
	a[13-4] =	0.03926901746669507;
	a[13-5] =	-0.15260708968419273;
	a[13-6] =	0.615569131581661;
	a[13-7] =	0.615569131581661;
	a[13-8] =	-0.15260708968419273;
	a[13-9] =	0.03926901746669507;
	a[13-10] =	0.01178776838931864;
	a[13-11] =	-0.032489477830945114;
	a[13-12] =	0.03437803608088014;
	a[13-13] =	-0.04159025868126048;
}

void timer_handler(int signal)
{
	process_signal_ready = 1;
}

void main(void)
{	
	initialize();
	initialize_fir();
	
	interrupt(SIG_TMZ, timer_handler);
	timer_set((unsigned int)15652, (unsigned int)15652);
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
			get_adc1_ch0();
			adc_voltage = adc1_ch0_msb;
			adc_voltage <<= 8;
			adc_voltage |= adc1_ch0_lsb;
			adc_voltage &= 0x000003FF;
			h1_in[0] = adc_voltage * 3.3f / 2048.0f;
			
			/** Filter
			 *	float *fir (const float dm input[],
			 *				float dm output[],
			 *				const float pm coeffs[],
			 *				float dm state[],
			 *				int samples,
			 *				int taps);
			 **/
			fir (h1_in, h1_out, a, h1_state, 1, TAPS);
			
			// snprintf(buf, 256, "%d: %d %f\r\n", counter, adc_voltage, h1_in[0] );
			// uart_write(buf);
			// counter++;

			//snprintf(buf, 256, "%f\r\n", h1_out[0]);
			//uart_write(buf);
			
			if (h1_out[0] > 0.6f)
			{
				uart_write("0 ");
			}
		}
	}
}
