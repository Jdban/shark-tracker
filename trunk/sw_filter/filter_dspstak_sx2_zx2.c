#include "filter_dspstak_sx2_zx2.h"

#include <filter.h>

#define TAPS 10

float pm coeffs[TAPS];
float state[TAPS+1];

void init_dsp_filter()
{
    int i;

    // Initialize the state array
    for (i = 0; i < TAPS+1; i++)
        state[i] = 0;
}

float dsp_filter(float in)
{
    float out;
    fir(&in, &out, coeffs, state, 1, TAPS);
    return out;
}