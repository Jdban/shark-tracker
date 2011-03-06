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
#include <math.h>

//#define DEBUG_PRINT_SAMPLE_RATE

#define ANGLE_WEIGHT 		0.1f
#define ZERO_THRESHOLD		1000
#define RATIO_THRESHOLD 	0.01f
#define VOLTAGE_OFFSET 		0.20f
#define MAXIMUM_DIFFERENCE  5000

#define SAMPLES 			2000
#define TAPS 				139

float pm b[TAPS] = {
  -9.32567491e-05,0.0001085503827,-0.0001635746594,0.0002287772513,-0.0003012443194,
  0.0003762119159,-0.0004469726409,0.0005049775355,-0.000540103938,0.0005410810118,
  -0.000496123801,0.0003937807342,-0.0002239727619,-2.089864574e-05,0.0003448851639,
  -0.0007474409649, 0.001222472405,-0.001757695922, 0.002334409393,-0.002927644644,
   0.003506724257,-0.004036439117, 0.004478837363,-0.004795285407, 0.004948899616,
   -0.00490751164, 0.004646400455,-0.004150854424, 0.003419017419,-0.002463246696,
   0.001311667496,-8.108512702e-06,-0.001388544217, 0.002806326374,-0.004163203295,
   0.005371117964,-0.006340879947, 0.006987752393,-0.007237356156, 0.007031562272,
  -0.006334027275, 0.005134962033,-0.003454744816, 0.001346054487, 0.001105711912,
  -0.003783921711, 0.006544223987,-0.009219956584,  0.01162926387, -0.01358376164,
    0.01489820052, -0.01540064532,  0.01494273823, -0.01340929884,  0.01072673313,
  -0.006869805511, 0.001866059843, 0.004202140961, -0.01119851787,  0.01893656515,
   -0.02718601562,  0.03568184003, -0.04413538054,  0.05224699154, -0.05971966684,
     0.0662728548, -0.07165574282,  0.07565932721, -0.07812654972,  0.07895995677,
   -0.07812654972,  0.07565932721, -0.07165574282,   0.0662728548, -0.05971966684,
    0.05224699154, -0.04413538054,  0.03568184003, -0.02718601562,  0.01893656515,
   -0.01119851787, 0.004202140961, 0.001866059843,-0.006869805511,  0.01072673313,
   -0.01340929884,  0.01494273823, -0.01540064532,  0.01489820052, -0.01358376164,
    0.01162926387,-0.009219956584, 0.006544223987,-0.003783921711, 0.001105711912,
   0.001346054487,-0.003454744816, 0.005134962033,-0.006334027275, 0.007031562272,
  -0.007237356156, 0.006987752393,-0.006340879947, 0.005371117964,-0.004163203295,
   0.002806326374,-0.001388544217,-8.108512702e-06, 0.001311667496,-0.002463246696,
   0.003419017419,-0.004150854424, 0.004646400455, -0.00490751164, 0.004948899616,
  -0.004795285407, 0.004478837363,-0.004036439117, 0.003506724257,-0.002927644644,
   0.002334409393,-0.001757695922, 0.001222472405,-0.0007474409649,0.0003448851639,
  -2.089864574e-05,-0.0002239727619,0.0003937807342,-0.000496123801,0.0005410810118,
  -0.000540103938,0.0005049775355,-0.0004469726409,0.0003762119159,-0.0003012443194,
  0.0002287772513,-0.0001635746594,0.0001085503827,-9.32567491e-05
};

float dm h1_in[SAMPLES], h1_out[SAMPLES], h2_in[SAMPLES], h2_out[SAMPLES];
float dm h1_state[TAPS+1], h2_state[TAPS+1];
uint32_t dm adc_voltage1, adc_voltage2;
uint32_t dm counter = 0;
uint32_t samplesTaken = 0;
int i;
char buf[256];

// Flips an array
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

// Initialezes the FIR filter
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

// Prints the sample rate if defined in
void debug_print_sample_rate(void)
{
#ifdef DEBUG_PRINT_SAMPLE_RATE
	static uint32_t functionruns = 0;
	static cycle_t start_count;				
	static cycle_t final_count;
	static double secs = 0;
	
    STOP_CYCLE_COUNT(final_count, start_count);
    START_CYCLE_COUNT(start_count);
    secs += ((double) final_count) / CLOCKS_PER_SEC;              
  		
    if(functionruns++ > 100000)
    {
        snprintf(buf, 256, "%lf\r\n", 1 / secs * 100000);
        uart_write(buf);
        for (i = 0; i < 20; i++) { uart_update(); } 
        secs = 0;
        functionruns = 0;
    }
#endif
}

// Entry point
void main(void)
{	
	int ui;
	uint32_t h1_high = 0, h2_high = 0;
	int32_t h1_start, h1_stop=0, h2_start, h2_stop=0, counter = 0;
	int32_t angle = 0;
	
	// Initialize DSP and FIR filter
	initialize();
	initialize_fir();

	// Flush the UART buffer
	for (i = 0; i < 200; i++)
	{	
		uart_update();
	}
	
	// Go "full speed" on sample rate
	for(;;)
	{   
		// Print sample rate
		debug_print_sample_rate();
		
		// Get voltages
		get_adc1_ch0();
		adc_voltage1 = adc1_ch0_msb;
		adc_voltage1 <<= 8;
		adc_voltage1 |= adc1_ch0_lsb;
		adc_voltage1 &= 0x00007FFF;
		h1_in[samplesTaken] = (adc_voltage1 * 5.0f / 32768.0f) - 0.20f;
		
		get_adc2_ch0();
		adc_voltage2 = adc2_ch0_msb;
		adc_voltage2 <<= 8;
		adc_voltage2 |= adc2_ch0_lsb;
		adc_voltage2 &= 0x00007FFF;
		h2_in[samplesTaken] = (adc_voltage2 * 5.0f / 32768.0f) - 0.20f;			
		
		++samplesTaken;
		
		// Filter
		if (samplesTaken >= SAMPLES)
		{
			fir (h1_in, h1_out, b, h1_state, SAMPLES, TAPS);
			fir (h2_in, h2_out, b, h2_state, SAMPLES, TAPS);
			
			samplesTaken = 0;

			for (i = 0; i < SAMPLES; i++)
			{	
				if (fabs(h1_in[i]) * RATIO_THRESHOLD < fabs(h1_out[i]))
	            {
	            	if (!h1_high)
	            	{ 
						h1_start = counter + i;
	            	}

	            	h1_high = ZERO_THRESHOLD;
	            }
	            else
	            {
	            	if (h1_high)
	            	{
	            		--h1_high;
	            		
	            		if (!h1_high)
	            		{
							h1_stop = counter + i;
							h1_stop = h1_start + h1_stop - h1_start;
				            
							if (h1_stop - h2_stop < MAXIMUM_DIFFERENCE)
							{
								angle = (h1_stop-h2_stop)*ANGLE_WEIGHT + angle*ANGLE_WEIGHT;
								snprintf(buf, 256, "%d\r\n", angle);
								uart_write(buf);
								for (ui = 0; ui < 14; ui++) { uart_update(); }
							}
	            		}
	            	}
	            }
	            
	            if (fabs(h2_in[i]) * RATIO_THRESHOLD < fabs(h2_out[i]))
	            {
	            	if (!h2_high)
	            	{
						h2_start = counter + i;
	            	}
	            	
	            	h2_high = ZERO_THRESHOLD;
	            }
	            else
	            {
	            	if (h2_high)
	            	{
	            		--h2_high;
	            		
	            		if (!h2_high)
	            		{
							h2_stop = counter + i;
							h2_stop = h2_start + h2_stop - h2_start;
				            
							if (h2_stop - h1_stop < MAXIMUM_DIFFERENCE)
							{
								angle = (h1_stop-h2_stop)*ANGLE_WEIGHT + angle*ANGLE_WEIGHT;
								snprintf(buf, 256, "%d\r\n", angle);
								uart_write(buf);
								for (ui = 0; ui < 13; ui++) { uart_update(); }
							}
	            		}
	            	}
	            }
			}
			
			counter += SAMPLES;
		}
	}
}
