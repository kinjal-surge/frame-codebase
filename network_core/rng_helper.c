#include "rng_helper.h"
static struct rng_ring_buffer_t
{
    uint8_t buffer[RNG_BUF_SIZE];
    uint16_t head; // write location
    uint16_t tail; // read location
} rng_rb = {
    .buffer = "",
    .head = 0,
    .tail = 0,
};

typedef struct rng_value_t
{
    uint8_t rng_val;
    bool success;
} rng_value_t;

static void rb_push(uint8_t val)
{
    if (rng_rb.tail - rng_rb.head == -1 || rng_rb.tail - rng_rb.head == RNG_BUF_SIZE - 1)
    {
        // buffer full
        nrfx_rng_stop();
        return;
    }

    rng_rb.buffer[rng_rb.tail] = val;
    rng_rb.tail = (rng_rb.tail + 1) % RNG_BUF_SIZE;
}

static rng_value_t rb_pop()
{
    rng_value_t ret_val = {0};

    if ((rng_rb.head + 1) % RNG_BUF_SIZE == rng_rb.tail)
    {
        // buffer empty
        nrfx_rng_start();
        ret_val.success = false;
        ret_val.rng_val = 0;
        return ret_val;
    }

    ret_val.success = true;
    ret_val.rng_val = rng_rb.buffer[rng_rb.head];
    rng_rb.head = (rng_rb.head + 1) % RNG_BUF_SIZE;
    return ret_val;
}

void rng_evt_handler(uint8_t rng_data)
{
    // NRFX_LOG("it works");
    rb_push(rng_data);
}

uint8_t rand_get(uint8_t *p_buff, uint8_t length)
{
    uint8_t idx = 0;
    rng_value_t rng_val;
    while (idx < length)
    {
        rng_val = rb_pop();
        if (!rng_val.success)
            break;
        p_buff[idx] = rng_val.rng_val;
        idx++;
    }
    return idx;
}

void rand_poll(uint8_t *p_buff, uint8_t length)
{
    uint8_t idx = 0;
    rng_value_t rng_val;
    while (idx < length)
    {
        rng_val = rb_pop();
        if (rng_val.success)
        {
            p_buff[idx] = rng_val.rng_val;
            idx++;
        }
    }
}