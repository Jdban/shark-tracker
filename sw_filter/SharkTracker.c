#include <filter.h>
#include "init.h"
#include "uart.h"
#include "signal.h"
#include "sys.h"
 
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
	coeffs[67-0] =	-0.005486136116844148;
	coeffs[67-1] =	-0.009602607346449701;
	coeffs[67-2] =	0.00845747403313754;
	coeffs[67-3] =	-0.005430882672359224;
	coeffs[67-4] =	-2.2168604946012522E-4;
	coeffs[67-5] =	0.005319902132482797;
	coeffs[67-6] =	-0.006302894571475608;
	coeffs[67-7] =	0.0028398443932207153;
	coeffs[67-8] =	0.001658431184374241;
	coeffs[67-9] =	-0.003263089969290434;
	coeffs[67-10] =	0.001510300151155242;
	coeffs[67-11] =	8.331911580857637E-5;
	coeffs[67-12] =	0.0020484530364143837;
	coeffs[67-13] =	-0.006731303624501391;
	coeffs[67-14] =	0.007768456742517323;
	coeffs[67-15] =	2.5162537861197587E-4;
	coeffs[67-16] =	-0.014763366153652539;
	coeffs[67-17] =	0.024200835083052916;
	coeffs[67-18] =	-0.01639084971076349;
	coeffs[67-19] =	-0.009316929257047923;
	coeffs[67-20] =	0.03704214757604846;
	coeffs[67-21] =	-0.04363677930574867;
	coeffs[67-22] =	0.017277744373902237;
	coeffs[67-23] =	0.029230252367691754;
	coeffs[67-24] =	-0.06349673156937105;
	coeffs[67-25] =	0.05632984601144442;
	coeffs[67-26] =	-0.005981223212313597;
	coeffs[67-27] =	-0.055854423054179196;
	coeffs[67-28] =	0.08446909919884021;
	coeffs[67-29] =	-0.05519464523600864;
	coeffs[67-30] =	-0.015649143441257257;
	coeffs[67-31] =	0.07974209464435833;
	coeffs[67-32] =	-0.09090496251163571;
	coeffs[67-33] =	0.039465683522209055;
	coeffs[67-34] =	0.039465683522209055;
	coeffs[67-35] =	-0.09090496251163571;
	coeffs[67-36] =	0.07974209464435833;
	coeffs[67-37] =	-0.015649143441257257;
	coeffs[67-38] =	-0.05519464523600864;
	coeffs[67-39] =	0.08446909919884021;
	coeffs[67-40] =	-0.055854423054179196;
	coeffs[67-41] =	-0.005981223212313597;
	coeffs[67-42] =	0.05632984601144442;
	coeffs[67-43] =	-0.06349673156937105;
	coeffs[67-44] =	0.029230252367691754;
	coeffs[67-45] =	0.017277744373902237;
	coeffs[67-46] =	-0.04363677930574867;
	coeffs[67-47] =	0.03704214757604846;
	coeffs[67-48] =	-0.009316929257047923;
	coeffs[67-49] =	-0.01639084971076349;
	coeffs[67-50] =	0.024200835083052916;
	coeffs[67-51] =	-0.014763366153652539;
	coeffs[67-52] =	2.5162537861197587E-4;
	coeffs[67-53] =	0.007768456742517323;
	coeffs[67-54] =	-0.006731303624501391;
	coeffs[67-55] =	0.0020484530364143837;
	coeffs[67-56] =	8.331911580857637E-5;
	coeffs[67-57] =	0.001510300151155242;
	coeffs[67-58] =	-0.003263089969290434;
	coeffs[67-59] =	0.001658431184374241;
	coeffs[67-60] =	0.0028398443932207153;
	coeffs[67-61] =	-0.006302894571475608;
	coeffs[67-62] =	0.005319902132482797;
	coeffs[67-63] =	-2.2168604946012522E-4;
	coeffs[67-64] =	-0.005430882672359224;
	coeffs[67-65] =	0.00845747403313754;
	coeffs[67-66] =	-0.009602607346449701;
	coeffs[67-67] =	-0.005486136116844148;
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
