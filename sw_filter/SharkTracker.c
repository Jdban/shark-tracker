#include <filter.h>
#include <signal.h>
#include <stdio.h>
#include <processor_include.h>
#include <stdint.h>
#include "init.h"
#include "uart.h"
#include "sharc.h"
 
char buf[256];

#define SAMPLES 100
#define TAPS_A 102
float pm a[TAPS_A];
#define TAPS_B 103
float pm b[TAPS_B];
float dm h1_in[SAMPLES], h1_out_a[SAMPLES], h1_out_b[SAMPLES];
float dm h1_state_a[TAPS_A+1];
float dm h1_state_b[TAPS_B+1];
uint32_t dm adc_voltage;
uint32_t dm counter = 0;
uint32_t process_signal_ready = 0;
uint32_t samplesTaken = 0;
int i;
float lastVoltage = 0.0f;

void initialize_fir(void)
{
	int i;
	
	// Initialize the state arrays
	for (i = 0; i < TAPS_A+1; i++)
	{
		h1_state_a[i] = 0;
	}	

	// Initialize the state arrays
	for (i = 0; i < TAPS_B+1; i++)
	{
		h1_state_b[i] = 0;
	}	
		
	// Initialize the coefficients
	// NOTE: This is a BPF that has a passband from 0.35 to 0.38 
	//       of the sampling rate and a 40 dB attenuation
	a[101-0] =	-0.003949529949260579;
	a[101-1] =	9.063321479532866E-4;
	a[101-2] =	3.430678094466732E-5;
	a[101-3] =	-0.0014103540166716525;
	a[101-4] =	0.0026483919722704087;
	a[101-5] =	-0.003129622790617796;
	a[101-6] =	0.0024925015873516077;
	a[101-7] =	-8.613870708594591E-4;
	a[101-8] =	-0.0011330843682145835;
	a[101-9] =	0.0025905000042891323;
	a[101-10] =	-0.0027442426346766437;
	a[101-11] =	0.0013494970210977675;
	a[101-12] =	0.0011119055843492442;
	a[101-13] =	-0.0035396217593571125;
	a[101-14] =	0.0047244977045385605;
	a[101-15] =	-0.003873789013917849;
	a[101-16] =	0.001105463950091876;
	a[101-17] =	0.0025040933803162843;
	a[101-18] =	-0.005309333092311813;
	a[101-19] =	0.005831539073872703;
	a[101-20] =	-0.0035103676723049135;
	a[101-21] =	-8.99062210288403E-4;
	a[101-22] =	0.005517994233531143;
	a[101-23] =	-0.008107374681329294;
	a[101-24] =	0.007118187102644674;
	a[101-25] =	-0.0025435537977909566;
	a[101-26] =	-0.003881658982864398;
	a[101-27] =	0.009272901164263506;
	a[101-28] =	-0.010856955511650397;
	a[101-29] =	0.007323731785886395;
	a[101-30] =	3.286636708283319E-4;
	a[101-31] =	-0.008956034205806332;
	a[101-32] =	0.014482338241214697;
	a[101-33] =	-0.013728775211785957;
	a[101-34] =	0.006078459122185327;
	a[101-35] =	0.0058354175995759695;
	a[101-36] =	-0.01688496012414332;
	a[101-37] =	0.021490450711536702;
	a[101-38] =	-0.016191594875255122;
	a[101-39] =	0.0016623183460352487;
	a[101-40] =	0.016854966062898217;
	a[101-41] =	-0.031092521386937418;
	a[101-42] =	0.03292997137208981;
	a[101-43] =	-0.01806106113324075;
	a[101-44] =	-0.011265858770354992;
	a[101-45] =	0.0455964249656109;
	a[101-46] =	-0.07001915333675053;
	a[101-47] =	0.06729299665659903;
	a[101-48] =	-0.01904713224732471;
	a[101-49] =	-0.10862114404997612;
	a[101-50] =	0.5991941959704615;
	a[101-51] =	0.5991941959704615;
	a[101-52] =	-0.10862114404997612;
	a[101-53] =	-0.01904713224732471;
	a[101-54] =	0.06729299665659903;
	a[101-55] =	-0.07001915333675053;
	a[101-56] =	0.0455964249656109;
	a[101-57] =	-0.011265858770354992;
	a[101-58] =	-0.01806106113324075;
	a[101-59] =	0.03292997137208981;
	a[101-60] =	-0.031092521386937418;
	a[101-61] =	0.016854966062898217;
	a[101-62] =	0.0016623183460352487;
	a[101-63] =	-0.016191594875255122;
	a[101-64] =	0.021490450711536702;
	a[101-65] =	-0.01688496012414332;
	a[101-66] =	0.0058354175995759695;
	a[101-67] =	0.006078459122185327;
	a[101-68] =	-0.013728775211785957;
	a[101-69] =	0.014482338241214697;
	a[101-70] =	-0.008956034205806332;
	a[101-71] =	3.286636708283319E-4;
	a[101-72] =	0.007323731785886395;
	a[101-73] =	-0.010856955511650397;
	a[101-74] =	0.009272901164263506;
	a[101-75] =	-0.003881658982864398;
	a[101-76] =	-0.0025435537977909566;
	a[101-77] =	0.007118187102644674;
	a[101-78] =	-0.008107374681329294;
	a[101-79] =	0.005517994233531143;
	a[101-80] =	-8.99062210288403E-4;
	a[101-81] =	-0.0035103676723049135;
	a[101-82] =	0.005831539073872703;
	a[101-83] =	-0.005309333092311813;
	a[101-84] =	0.0025040933803162843;
	a[101-85] =	0.001105463950091876;
	a[101-86] =	-0.003873789013917849;
	a[101-87] =	0.0047244977045385605;
	a[101-88] =	-0.0035396217593571125;
	a[101-89] =	0.0011119055843492442;
	a[101-90] =	0.0013494970210977675;
	a[101-91] =	-0.0027442426346766437;
	a[101-92] =	0.0025905000042891323;
	a[101-93] =	-0.0011330843682145835;
	a[101-94] =	-8.613870708594591E-4;
	a[101-95] =	0.0024925015873516077;
	a[101-96] =	-0.003129622790617796;
	a[101-97] =	0.0026483919722704087;
	a[101-98] =	-0.0014103540166716525;
	a[101-99] =	3.430678094466732E-5;
	a[101-100] =	9.063321479532866E-4;
	a[101-101] =	-0.003949529949260579;
	
b[102-0] =	-5.593057662395021E-4;
b[102-1] =	0.006054421039674022;
b[102-2] =	-0.012631139663265623;
b[102-3] =	0.011358790935317034;
b[102-4] =	-7.93011970797486E-4;
b[102-5] =	-0.006312069487132646;
b[102-6] =	0.0015166265316598696;
b[102-7] =	0.004814580506683035;
b[102-8] =	-0.0012299088435649252;
b[102-9] =	-0.004499766123185603;
b[102-10] =	8.887448860103445E-4;
b[102-11] =	0.004598256636371413;
b[102-12] =	-5.083261527392578E-4;
b[102-13] =	-0.00492544266133056;
b[102-14] =	1.067176888483451E-4;
b[102-15] =	0.005361729001144299;
b[102-16] =	3.658313280971507E-4;
b[102-17] =	-0.0058747288145364705;
b[102-18] =	-9.392099823812407E-4;
b[102-19] =	0.0064576078080182675;
b[102-20] =	0.0016156236556619306;
b[102-21] =	-0.007080017187181952;
b[102-22] =	-0.0024256418154174606;
b[102-23] =	0.0077252937072849045;
b[102-24] =	0.003400718373512724;
b[102-25] =	-0.008386612844386852;
b[102-26] =	-0.004571757398121003;
b[102-27] =	0.00905136677046629;
b[102-28] =	0.005980055845051059;
b[102-29] =	-0.009714517074777048;
b[102-30] =	-0.007671487736361272;
b[102-31] =	0.01036539872506644;
b[102-32] =	0.009711305623467238;
b[102-33] =	-0.010991520684429457;
b[102-34] =	-0.012199963430207692;
b[102-35] =	0.011586301017590929;
b[102-36] =	0.015282100830711765;
b[102-37] =	-0.012139678548952756;
b[102-38] =	-0.019194435479033937;
b[102-39] =	0.012639859401652555;
b[102-40] =	0.024351859130100552;
b[102-41] =	-0.01307856320848423;
b[102-42] =	-0.03153883636785499;
b[102-43] =	0.013447344111489654;
b[102-44] =	0.04244512711506894;
b[102-45] =	-0.013739833474675807;
b[102-46] =	-0.0614724026514487;
b[102-47] =	0.013952468890233735;
b[102-48] =	0.10477831517932516;
b[102-49] =	-0.014080826329550503;
b[102-50] =	-0.31786611962923483;
b[102-51] =	0.5141234842782053;
b[102-52] =	-0.31786611962923483;
b[102-53] =	-0.014080826329550503;
b[102-54] =	0.10477831517932516;
b[102-55] =	0.013952468890233735;
b[102-56] =	-0.0614724026514487;
b[102-57] =	-0.013739833474675807;
b[102-58] =	0.04244512711506894;
b[102-59] =	0.013447344111489654;
b[102-60] =	-0.03153883636785499;
b[102-61] =	-0.01307856320848423;
b[102-62] =	0.024351859130100552;
b[102-63] =	0.012639859401652555;
b[102-64] =	-0.019194435479033937;
b[102-65] =	-0.012139678548952756;
b[102-66] =	0.015282100830711765;
b[102-67] =	0.011586301017590929;
b[102-68] =	-0.012199963430207692;
b[102-69] =	-0.010991520684429457;
b[102-70] =	0.009711305623467238;
b[102-71] =	0.01036539872506644;
b[102-72] =	-0.007671487736361272;
b[102-73] =	-0.009714517074777048;
b[102-74] =	0.005980055845051059;
b[102-75] =	0.00905136677046629;
b[102-76] =	-0.004571757398121003;
b[102-77] =	-0.008386612844386852;
b[102-78] =	0.003400718373512724;
b[102-79] =	0.0077252937072849045;
b[102-80] =	-0.0024256418154174606;
b[102-81] =	-0.007080017187181952;
b[102-82] =	0.0016156236556619306;
b[102-83] =	0.0064576078080182675;
b[102-84] =	-9.392099823812407E-4;
b[102-85] =	-0.0058747288145364705;
b[102-86] =	3.658313280971507E-4;
b[102-87] =	0.005361729001144299;
b[102-88] =	1.067176888483451E-4;
b[102-89] =	-0.00492544266133056;
b[102-90] =	-5.083261527392578E-4;
b[102-91] =	0.004598256636371413;
b[102-92] =	8.887448860103445E-4;
b[102-93] =	-0.004499766123185603;
b[102-94] =	-0.0012299088435649252;
b[102-95] =	0.004814580506683035;
b[102-96] =	0.0015166265316598696;
b[102-97] =	-0.006312069487132646;
b[102-98] =	-7.93011970797486E-4;
b[102-99] =	0.011358790935317034;
b[102-100] =	-0.012631139663265623;
b[102-101] =	0.006054421039674022;
b[102-102] =	-5.593057662395021E-4;
}

void timer_handler(int signal)
{
	process_signal_ready = 1;
}

void main(void)
{	
	initialize();
	initialize_fir();
	
	//interrupt(SIG_TMZ, timer_handler);
	//timer_set((unsigned int)1704, (unsigned int)1704);
	//timer_on();
	
	for (i = 0; i < 200; i++)
	{	
		uart_update();
	}
	
	for(;;)
	{	
		uart_update();
		// Check if we are ready to sample
		//if (process_signal_ready)
		{
			// Get Hydrophone 1 Voltage
			process_signal_ready = 0;
			get_adc1_ch0();
			adc_voltage = adc1_ch0_msb;
			adc_voltage <<= 8;
			adc_voltage |= adc1_ch0_lsb;
			adc_voltage &= 0x000003FF;
			h1_in[samplesTaken++] = adc_voltage * 3.3f / 2048.0f;
			
			if (samplesTaken >= SAMPLES)
			{
				samplesTaken = 0;
				
				/** Filter
				 *	float *fir (const float dm input[],
				 *				float dm output[],
				 *				const float pm coeffs[],
				 *				float dm state[],
				 *				int samples,
				 *				int taps);
				 **/
				//fir (h1_in, h1_out_a, a, h1_state_a, SAMPLES, TAPS_A);
				fir (h1_in, h1_out_b, b, h1_state_b, SAMPLES, TAPS_B);
				
				for (i = 0; i < SAMPLES; i++)
				{
					if (h1_out_b[i] > 0.6f)
					{
						uart_write("1");
						uart_update();
						break;
					}
					else
					{
						snprintf(buf, 256, "Values are : %f ,%f\r\n", h1_in[i], h1_out_b[i]);
						uart_write(buf);
						uart_update();
					}
				}
			}
		}
	}
}
