#include <filter.h>
#include <signal.h>
#include <stdio.h>
#include <processor_include.h>
#include <stdint.h>
#include "init.h"
#include "uart.h"
#include "sharc.h"
#include <cycles.h>
#include <cycle_count.h>
#include <time.h>

char buf[256];

#define FILTER_THRESHOLD 0.0005f
#define RATIO_THRESHOLD 0.005f
#define ZERO_THRESHOLD 150
#define ONE_THRESHOLD 5

#define SAMPLES 100
#define TAPS 95

float pm b[95] = {
  3.728714364e-005,-0.0003015170805, 0.000762636133,-0.001547353226, 0.002608923009,
  -0.003803665517, 0.004858806264,-0.005426875316, 0.005185044371,-0.003963616211,
   0.001858470845,0.0007234527147,-0.003124273848, 0.004606754985,-0.004599264823,
   0.002936388366,-1.021946971e-007,-0.003315590322, 0.005840599537,-0.006514717825,
   0.004803691525,-0.0009899938013,-0.003797732992, 0.007874809206,-0.009554263204,
   0.007795650512,-0.002714154078,-0.004269921221,  0.01075909566, -0.01413696166,
    0.01253827568, -0.00569606619,-0.004674210679,  0.01517358236, -0.02170065045,
    0.02086577564, -0.01139506232,-0.004975264892,  0.02350098081, -0.03745311126,
    0.03995287046, -0.02611402236,-0.005164818373,  0.05035929009,  -0.1017748713,
     0.1492569149,  -0.1827179641,   0.1947734207,  -0.1827179641,   0.1492569149,
    -0.1017748713,  0.05035929009,-0.005164818373, -0.02611402236,  0.03995287046,
   -0.03745311126,  0.02350098081,-0.004975264892, -0.01139506232,  0.02086577564,
   -0.02170065045,  0.01517358236,-0.004674210679, -0.00569606619,  0.01253827568,
   -0.01413696166,  0.01075909566,-0.004269921221,-0.002714154078, 0.007795650512,
  -0.009554263204, 0.007874809206,-0.003797732992,-0.0009899938013, 0.004803691525,
  -0.006514717825, 0.005840599537,-0.003315590322,-1.021946971e-007, 0.002936388366,
  -0.004599264823, 0.004606754985,-0.003124273848,0.0007234527147, 0.001858470845,
  -0.003963616211, 0.005185044371,-0.005426875316, 0.004858806264,-0.003803665517,
   0.002608923009,-0.001547353226, 0.000762636133,-0.0003015170805,3.728714364e-005
};

float dm h1_in[SAMPLES], h1_out[SAMPLES], h2_in[SAMPLES], h2_out[SAMPLES];
float dm h1_state[TAPS+1], h2_state[TAPS+1];
uint32_t dm adc_voltage1, adc_voltage2;
uint32_t dm counter = 0;
uint32_t process_signal_ready = 0;
uint32_t samplesTaken = 0;
uint32_t dm functionruns = 0;
int i;

void flipArray(float *arr, int size)
{
	int i;
	float temp;
	
	for (i = 0; i < size/2; i++)
	{
		temp = arr[i];
		arr[size-1-i] = arr[i];
		arr[i] = temp;
	}
}

void initialize_fir(void)
{
	int i;
	
	// Initialize the state arrays
	for (i = 0; i < TAPS+1; i++)
	{
		h1_state[i] = 0;
		h2_state[i] = 0;
	}	
	
	// Flip coefficiants
	flipArray(b, TAPS);
}

void timer_handler(int signal)
{
	process_signal_ready = 1;
}

#define stopCount() \
				STOP_CYCLE_COUNT(final_count, start_count); \
                secs = ((double) final_count) / CLOCKS_PER_SEC ; \
				functionruns++; \
						snprintf(buf, 256, "%lf\r\n", secs); \
                        uart_write(buf); \
				        uart_update(); \
                        uart_update(); \
                        uart_update(); \
                        uart_update(); \
						uart_update(); \
                        uart_update(); \
                        uart_update(); \
                        uart_update(); \
                        uart_update(); \
                        uart_update(); \
                        uart_update(); \
                        secs = 0; 

void main(void)
{	
	cycle_t start_count;				
	cycle_t final_count;
	double secs = 0;
	uint32_t zeroCount1 = 0, zeroCount2 = 0;
	uint32_t oneCount = 0;
	char firstHit = 0, secondHit = 0;
	
	initialize();
	initialize_fir();
	
	interrupt(SIG_TMZ, timer_handler);
	timer_set((unsigned int)1702, (unsigned int)1702);
//	timer_on();
	
	for (i = 0; i < 200; i++)
	{	
		uart_update();
	}
	
	for(;;)
	{
                   /**
                STOP_CYCLE_COUNT(final_count, start_count);
                START_CYCLE_COUNT(start_count);
                secs += ((double) final_count) / CLOCKS_PER_SEC ;           
                
                if(functionruns > 10000)
                {
                        snprintf(buf, 256, "%lf\r\n", 1 / secs * 10000);
                        uart_write(buf);
                        uart_update();
                        uart_update();
                        uart_update();
                        uart_update();
                        secs = 0;
                        functionruns = 0;
                }
                   **/

		// Check if we are ready to sample
//		if (process_signal_ready)
		{
			// Get Hydrophone 1 Voltage
			process_signal_ready = 0;
			
			// Get voltages
			get_adc1_ch0();
			adc_voltage1 = adc1_ch0_msb;
			adc_voltage1 <<= 8;
			adc_voltage1 |= adc1_ch0_lsb;
			adc_voltage1 &= 0x000003FF;
			h1_in[samplesTaken] = adc_voltage1 * 5.0f / 2048.0f;
			
			get_adc2_ch0();
			adc_voltage2 = adc2_ch0_msb;
			adc_voltage2 <<= 8;
			adc_voltage2 |= adc2_ch0_lsb;
			adc_voltage2 &= 0x000003FF;
			h2_in[samplesTaken] = adc_voltage2 * 5.0f / 2048.0f;
			
			++samplesTaken;
			
			// Filter
			if (samplesTaken >= SAMPLES)
			{
				/**
				STOP_CYCLE_COUNT(final_count, start_count);
                secs += ((double) final_count) / CLOCKS_PER_SEC ;
				functionruns++;
				if(functionruns > 10000)
                {      
						snprintf(buf, 256, "\r\n%lf\r\n", secs / SAMPLES);
                        uart_write(buf);
				        uart_update();
                        uart_update();
                        uart_update();
                        uart_update();
						uart_update();
                        uart_update();
                        uart_update();
                        uart_update();
                        secs = 0;
                        functionruns = 0;
                }**/

				samplesTaken = 0;
				
				fir (h1_in, h1_out, b, h1_state, SAMPLES, TAPS);
				fir (h2_in, h2_out, b, h2_state, SAMPLES, TAPS);

				oneCount = 0;
				for (i = 0; i < SAMPLES; i++)
				{	
					if (h1_out[i] > FILTER_THRESHOLD && h1_in[i] * RATIO_THRESHOLD < h1_out[i])
                    {
                    	if (zeroCount1 < ZERO_THRESHOLD) 
                    	{
                    		zeroCount1 = 0;
                    	}
                    	else 
                    	{
	                    	oneCount++;
                    		if (oneCount > ONE_THRESHOLD)
                    		{
		                    	//uart_write("1");
		                    	//uart_update(); 
		                    	zeroCount1 = 0;
		                    	oneCount = 0;
		                    	
		                    	firstHit = 1;
		                    	if (secondHit)
		                    	{
		                    		firstHit = 0;
		                    		secondHit = 0;
									stopCount();
		                    	}
		                    	else
		                    	{
		                    		START_CYCLE_COUNT(start_count);	
		                    	}
		                    	
		                    	break;
                    		}
                    	}
                   	}
                   	else
                   	{
						zeroCount1++;
                   	}
				}
				
				oneCount = 0;
				for (i = 0; i < SAMPLES; i++)
				{
					if (h2_out[i] > FILTER_THRESHOLD && h2_in[i] * RATIO_THRESHOLD < h2_out[i])
                    {
                    	if (zeroCount2 < ZERO_THRESHOLD) 
                    	{
                    		zeroCount2 = 0;
                    	}
                    	else 
                    	{
	                    	oneCount++;
                    		if (oneCount > ONE_THRESHOLD)
                    		{
		                    	//uart_write("2");
		                    	//uart_update(); uart_update(); uart_update(); 
		                    	zeroCount2 = 0;
		                    	oneCount = 0;
		                    	
		                    	secondHit = 1;
		                    	if (firstHit)
		                    	{
		                    		firstHit = 0;
		                    		secondHit = 0;
									stopCount();
		                    	}
		                    	else
		                    	{
		                    		START_CYCLE_COUNT(start_count);	
		                    	}
		                    	
		                    	break;
                    		}
                    	}
                   	}
                   	else
                   	{
						zeroCount2++;
                   	}
				}
				
                //START_CYCLE_COUNT(start_count);
			}
			
		}
	}
}
					/**snprintf(buf, 256, "I: %f O: %f\r\n", h1_in[i], h1_out_b[i] * 100);
						uart_write(buf);
						uart_update();
					**/
