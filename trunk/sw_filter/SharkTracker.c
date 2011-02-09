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

#define FILTER_THRESHOLD 0.0001f
#define RATIO_THRESHOLD 0.001f

#define SAMPLES 100
#define TAPS 170

#define ZERO_THRESHOLD 1
#define ONE_THRESHOLD 1

float pm b[170] = {
  0.0003095621942,0.0005279468605,-0.0002953880175,-8.825003533e-006,0.0003792401403,
  -0.0005839442019,0.0003824750311,0.0002175050322,-0.0008596457774, 0.001021481818,
  -0.0004059193307,-0.0007338736905, 0.001635133638,-0.001504796441,0.0001596090588,
   0.001661026152,-0.002652302152, 0.001846278086,0.0005430759047,-0.003025990212,
   0.003732128302,-0.001786674722,-0.001826856285, 0.004690705333,-0.004557589535,
     0.0010826129, 0.003638214897,-0.006310523953, 0.004753366113,0.0003500714665,
   -0.00565837929, 0.007385738194,-0.004045753274,-0.002295147628, 0.007303969003,
  -0.007420942187, 0.002460003365, 0.004166749306,-0.007865049876, 0.006166498177,
  -0.0004682240251,-0.005094523542, 0.006762956735,-0.003853495233,-0.001005526632,
   0.004170601256,-0.003868121654, 0.001308784238,0.0007837367011,-0.0008192622918,
  -0.0002616890415,0.0001461625798, 0.002181913704,-0.004841210321, 0.004347134382,
  0.0009589472902,-0.008350171149,   0.0118031716,-0.006638131104, -0.00572856795,
    0.01722709835, -0.01827091724, 0.005421254784,  0.01438882574,   -0.027275078,
    0.02208879031,0.0003625900135, -0.02598363906,  0.03619032726, -0.02139660344,
   -0.01061075833,    0.038442377, -0.04151141271,  0.01529840101,  0.02387876995,
   -0.04905183986,  0.04137937352,-0.004295039922, -0.03763984889,   0.0552155748,
   -0.03518672287,-0.009709739126,  0.04894061014, -0.05525049567,  0.02386905439,
    0.02386905439, -0.05525049567,  0.04894061014,-0.009709739126, -0.03518672287,
     0.0552155748, -0.03763984889,-0.004295039922,  0.04137937352, -0.04905183986,
    0.02387876995,  0.01529840101, -0.04151141271,    0.038442377, -0.01061075833,
   -0.02139660344,  0.03619032726, -0.02598363906,0.0003625900135,  0.02208879031,
     -0.027275078,  0.01438882574, 0.005421254784, -0.01827091724,  0.01722709835,
   -0.00572856795,-0.006638131104,   0.0118031716,-0.008350171149,0.0009589472902,
   0.004347134382,-0.004841210321, 0.002181913704,0.0001461625798,-0.0002616890415,
  -0.0008192622918,0.0007837367011, 0.001308784238,-0.003868121654, 0.004170601256,
  -0.001005526632,-0.003853495233, 0.006762956735,-0.005094523542,-0.0004682240251,
   0.006166498177,-0.007865049876, 0.004166749306, 0.002460003365,-0.007420942187,
   0.007303969003,-0.002295147628,-0.004045753274, 0.007385738194, -0.00565837929,
  0.0003500714665, 0.004753366113,-0.006310523953, 0.003638214897,   0.0010826129,
  -0.004557589535, 0.004690705333,-0.001826856285,-0.001786674722, 0.003732128302,
  -0.003025990212,0.0005430759047, 0.001846278086,-0.002652302152, 0.001661026152,
  0.0001596090588,-0.001504796441, 0.001635133638,-0.0007338736905,-0.0004059193307,
   0.001021481818,-0.0008596457774,0.0002175050322,0.0003824750311,-0.0005839442019,
  0.0003792401403,-8.825003533e-006,-0.0002953880175,0.0005279468605,0.0003095621942
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

void main(void)
{	
	cycle_t start_count;				
	cycle_t final_count;
	double secs = 0;
	uint32_t zeroCount1 = 0, zeroCount2 = 0;
	uint32_t oneCount = 0;
	
	initialize();
	initialize_fir();
	
	interrupt(SIG_TMZ, timer_handler);
	timer_set((unsigned int)1702, (unsigned int)1702);
	timer_on();
	
	for (i = 0; i < 200; i++)
	{	
		uart_update();
	}
	
	for(;;)
	{
                        STOP_CYCLE_COUNT(final_count, start_count);
                        START_CYCLE_COUNT(start_count);
                        secs += ((double) final_count) / CLOCKS_PER_SEC ;           
                
                if(functionruns > 10000)
                {
                   /**
                        snprintf(buf, 256, "%lf\r\n", 1 / secs * 10000);
                        uart_write(buf);
                        uart_update();
                        uart_update();
                        uart_update();
                        uart_update();
                        secs = 0;
                        functionruns = 0;
                   **/
                }


		// Check if we are ready to sample
		if (process_signal_ready)
		{
			functionruns++;
			
			// Get Hydrophone 1 Voltage
			process_signal_ready = 0;
			
			// Get voltages
			get_adc1_ch0();
			adc_voltage1 = adc1_ch0_msb;
			adc_voltage1 <<= 8;
			adc_voltage1 |= adc1_ch0_lsb;
			adc_voltage1 &= 0x000003FF;
			h1_in[samplesTaken] = adc_voltage1 * 5.0f / 2048.0f;
			
//			get_adc2_ch0();
			adc_voltage2 = adc2_ch0_msb;
			adc_voltage2 <<= 8;
			adc_voltage2 |= adc2_ch0_lsb;
			adc_voltage2 &= 0x000003FF;
			h2_in[samplesTaken] = adc_voltage2 * 5.0f / 2048.0f;
			
			++samplesTaken;
			// Filter
			if (samplesTaken >= SAMPLES)
			{
				samplesTaken = 0;
				
				fir (h1_in, h1_out, b, h1_state, SAMPLES, TAPS);
				fir (h2_in, h2_out, b, h2_state, SAMPLES, TAPS);

				oneCount = 0;
				for (i = 0; i < SAMPLES; i++)
				{	
					if (h1_out[i] > FILTER_THRESHOLD && h1_in[i] * RATIO_THRESHOLD < h1_out[i])
					{
						if (zeroCount1 != 0)
							zeroCount1 = ZERO_THRESHOLD;
						
						if (++oneCount > ONE_THRESHOLD && zeroCount1 == 0)
						{
							zeroCount1 = ZERO_THRESHOLD;
							uart_write("p\r\n");
							uart_update();
							uart_update();
							uart_update();
							break;
						}
					}
					else
					{
						if (zeroCount1 != 0)
							zeroCount1--;
					}
				}
				
				oneCount = 0;
				for (i = 0; i < SAMPLES; i++)
				{
					if (h2_out[i] > FILTER_THRESHOLD && h2_in[i] * RATIO_THRESHOLD < h2_out[i])
					{
						if (zeroCount2 != 0)
							zeroCount2 = ZERO_THRESHOLD;
						
						if (++oneCount > ONE_THRESHOLD && zeroCount2 == 0)
						{
							zeroCount2 = ZERO_THRESHOLD;
							uart_write("2\r\n");
							uart_update();
							uart_update();
							uart_update();
							break;
						}
					}
					else
					{
						if (zeroCount2 != 0)
							zeroCount2--;
					}
				}
			}
			
		}
	}
}
					/**snprintf(buf, 256, "I: %f O: %f\r\n", h1_in[i], h1_out_b[i] * 100);
						uart_write(buf);
						uart_update();
					**/
