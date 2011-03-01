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

#undef  DEBUG
//#define DEBUG

#define FILTER_THRESHOLD 	1.70f
#define RATIO_THRESHOLD 	0.01f
#define ZERO_THRESHOLD 		1000
#define ONE_THRESHOLD 		10
#define MAXIMUM_DIFFERENCE  100000
#define SAMPLE_PERIOD		6.25E-06
#define SPEED_OF_SOUND		1497

#define SAMPLES 100
#define TAPS 135

float pm b[TAPS] = {
  0.0006397355464,-0.0006236342597,0.0009049641085,-0.001238437137,  0.00160371745,
  -0.001964485738, 0.002269221935,-0.002455495531, 0.002457565628,-0.002216652036,
   0.001692693448,-0.0008755652816,-0.0002062538988, 0.001482094289,-0.002842135495,
   0.004147579893,-0.005247440189, 0.006000367459,-0.006298542488, 0.006090119481,
  -0.005395025015, 0.004310478456,-0.003004352795, 0.001695766579,-0.0006237258203,
  7.086298865e-06,-3.869106422e-06,0.0006768550375,-0.001969086239, 0.003698579036,
  -0.005577423144, 0.007245122455,-0.008327092044, 0.008495834656,-0.007535508834,
   0.005391953047,-0.002201033989,-0.001713528181, 0.005875640083,-0.009723293595,
    0.01269758679,  -0.0143413581,  0.01439098641, -0.01284493599, 0.009994459338,
  -0.006406978704, 0.002859473927,-0.000228725854,-0.0006490037777,-0.0008723504143,
   0.005112454295, -0.01196618844,  0.02086211368, -0.03078956902,  0.04039767757,
     -0.048156064,  0.05255782232, -0.05233883485,  0.04668034986, -0.03536406532,
    0.01885560155, 0.001702796784, -0.02459068783,  0.04769232869, -0.06873958558,
    0.08558472246, -0.09646554291,   0.1002265736, -0.09646554291,  0.08558472246,
   -0.06873958558,  0.04769232869, -0.02459068783, 0.001702796784,  0.01885560155,
   -0.03536406532,  0.04668034986, -0.05233883485,  0.05255782232,   -0.048156064,
    0.04039767757, -0.03078956902,  0.02086211368, -0.01196618844, 0.005112454295,
  -0.0008723504143,-0.0006490037777,-0.000228725854, 0.002859473927,-0.006406978704,
   0.009994459338, -0.01284493599,  0.01439098641,  -0.0143413581,  0.01269758679,
  -0.009723293595, 0.005875640083,-0.001713528181,-0.002201033989, 0.005391953047,
  -0.007535508834, 0.008495834656,-0.008327092044, 0.007245122455,-0.005577423144,
   0.003698579036,-0.001969086239,0.0006768550375,-3.869106422e-06,7.086298865e-06,
  -0.0006237258203, 0.001695766579,-0.003004352795, 0.004310478456,-0.005395025015,
   0.006090119481,-0.006298542488, 0.006000367459,-0.005247440189, 0.004147579893,
  -0.002842135495, 0.001482094289,-0.0002062538988,-0.0008755652816, 0.001692693448,
  -0.002216652036, 0.002457565628,-0.002455495531, 0.002269221935,-0.001964485738,
    0.00160371745,-0.001238437137,0.0009049641085,-0.0006236342597,0.0006397355464
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

void nofir (float *in, float *out, void *f, void *s, int samples, int taps)
{
	int i;
	
	for (i = 0; i < samples; i++)
	{
		out[i] = in[i];	
	}	
}

void main(void)
{	
	cycle_t start_count;				
	cycle_t final_count;
	double secs = 0;
	uint32_t zeroCount1 = 0, zeroCount2 = 0;
	uint32_t oneCount = 0;
	int32_t h1_start, h2_start, h1 = 0, h2 = 0, count = 0;
	
	initialize();
	initialize_fir();
	
	interrupt(SIG_TMZ, timer_handler);
	timer_set((unsigned int) 2128, (unsigned int)2128);
	//timer_on();
	
	for (i = 0; i < 200; i++)
	{	
		uart_update();
	}
	
	for(;;)
	{
		// Check if we are ready to sample
		//if (process_signal_ready)
		{
			// Get Hydrophone 1 Voltage
			process_signal_ready = 0;
			
			// Get voltages
			get_adc1_ch0();
			adc_voltage1 = adc1_ch0_msb;
			adc_voltage1 <<= 8;
			adc_voltage1 |= adc1_ch0_lsb;
			adc_voltage1 &= 0x00007FFF;
			h1_in[samplesTaken] = adc_voltage1 * 5.0f / 32768.0f;
			
			get_adc2_ch0();
			adc_voltage2 = adc2_ch0_msb;
			adc_voltage2 <<= 8;
			adc_voltage2 |= adc2_ch0_lsb;
			adc_voltage2 &= 0x00007FFF;
			h2_in[samplesTaken] = adc_voltage2 * 5.0f / 32768.0f;		
			++samplesTaken;
			
			// Filter
			if (samplesTaken >= SAMPLES)
			{
                samplesTaken = 0;
                
                nofir (h1_in, h1_out, b, h1_state, SAMPLES, TAPS);
                nofir (h2_in, h2_out, b, h2_state, SAMPLES, TAPS);

                oneCount = 0;
                for (i = 0; i < SAMPLES; i++)
                {       
                    if (h1_out[i] > FILTER_THRESHOLD && h1_in[i] * RATIO_THRESHOLD < h1_out[i])
                    {
                    									    uart_write("A");
								    for (i = 0; i < 20; i++) { uart_update(); }
                        if (zeroCount1 < ZERO_THRESHOLD) 
                        {
							zeroCount1 = 0;
                        }
                        else 
                        {
                            oneCount++;
                            if (oneCount > ONE_THRESHOLD)
                            {
	                            h1 = count + i;
	                            if (h1-h2 < MAXIMUM_DIFFERENCE && h2-h1 < MAXIMUM_DIFFERENCE)
	                            {
									snprintf(buf, 256, "1: %f\r\n", (h1-h2) * SAMPLE_PERIOD * SPEED_OF_SOUND);
								    uart_write(buf);
								    for (i = 0; i < 20; i++) { uart_update(); }
	                            }
                        
	                            zeroCount1 = 0;
	                            oneCount = 0;
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
	                            h2 = count + i;
	                            if (h1-h2 < MAXIMUM_DIFFERENCE && h2-h1 < MAXIMUM_DIFFERENCE)
	                            {
									snprintf(buf, 256, "2: %f\r\n", (h1-h2) * SAMPLE_PERIOD * SPEED_OF_SOUND);
								    uart_write(buf);
								    for (i = 0; i < 20; i++) { uart_update(); }
	                            }
	                            
                                zeroCount2 = 0;
                                oneCount = 0;
                                break;
                          	}
                        }
                  	}
                    else
                    {
                    	zeroCount2++;
					}
                }
                
                count += SAMPLES;
			}
		}
	}
}

			/**	
            STOP_CYCLE_COUNT(final_count, start_count);
            START_CYCLE_COUNT(start_count);
            secs += ((double) final_count) / CLOCKS_PER_SEC ;
            if(functionruns > 100000)
            {
                    snprintf(buf, 256, "%lf\r\n", 1 / secs * 100000);
                    uart_write(buf);
                    for (i = 0; i < 20; i++) { uart_update(); } 
                    secs = 0;
                    functionruns = 0;

            }
            **/
			/**
			//Debug
			functionruns++;
			if(functionruns > 1 && h1_in[samplesTaken] > 1.39f)
            {
			   snprintf(buf, 256, "%f, %f\r\n", adc_voltage1 * 5.0f / 32768.0f,adc_voltage2 * 5.0f / 32768.0f);
			   uart_write(buf);
			   for (i = 0; i < 20; i++) { uart_update(); }
            }
			**/
			/**
			snprintf(buf, 256, "I: %f O: %f\r\n", h1_in[i], h1_out_b[i] * 100);
			uart_write(buf);
			uart_update();
			**/
