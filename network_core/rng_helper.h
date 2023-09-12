#pragma once
#include "nrf.h"
#include "nrfx_log.h"
#include "nrfx_rng.h"

#define RNG_BUF_SIZE 1024

void rng_evt_handler(uint8_t rng_data);
uint8_t rand_get(uint8_t *p_buff, uint8_t length);
void rand_poll(uint8_t *p_buff, uint8_t length);
