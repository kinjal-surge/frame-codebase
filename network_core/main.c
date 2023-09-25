/*
 * This file is a part https://github.com/brilliantlabsAR/frame-micropython
 *
 * Authored by: Raj Nakarja / Brilliant Labs Ltd. (raj@brilliant.xyz)
 *              Rohit Rathnam / Silicon Witchery AB (rohit@siliconwitchery.com)
 *              Uma S. Gupta / Techno Exponent (umasankar@technoexponent.com)
 *
 * ISC Licence
 *
 * Copyright © 2023 Brilliant Labs Ltd.
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
 * REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
 * INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
 * LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
 * OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
 * PERFORMANCE OF THIS SOFTWARE.
 */

#include "camera_configuration.h"
#include "display_configuration.h"
#include "error_helpers.h"
#include "interprocessor_messaging.h"
#include "mphalport.h"
#include "nrf.h"
#include "nrfx_log.h"
#include "nrfx_rtc.h"
#include "nrfx_spim.h"
#include "nrfx_twim.h"
#include "pinout.h"
// for bluetooth
#include "sdc.h"
#include "sdc_hci.h"
#include "sdc_soc.h"
#include "rng_helper.h"
#include "sdc_soc.h"
#include "sdc_hci_cmd_controller_baseband.h"
#include "sdc_hci_cmd_info_params.h"
#include "sdc_hci_cmd_le.h"
#include "sdc_hci_cmd_link_control.h"
#include "sdc_hci_cmd_status_params.h"
#include "nrfx_systick.h"
#include "mpsl.h"
#include "nrf_errno.h"
#define LOW_PRIORITY 0x0f
static const nrfx_rtc_t rtc_instance = NRFX_RTC_INSTANCE(0);
static const nrfx_spim_t spi_instance = NRFX_SPIM_INSTANCE(0);
static const nrfx_twim_t i2c_instance = NRFX_TWIM_INSTANCE(0);

// static const uint8_t ACCELEROMETER_I2C_ADDRESS = 0x4C;
static const uint8_t CAMERA_I2C_ADDRESS = 0x6C;
static const uint8_t MAGNETOMETER_I2C_ADDRESS = 0x0C;
static const uint8_t PMIC_I2C_ADDRESS = 0x48;

static bool not_real_hardware = false;

static bool prevent_sleep = true;
void setup_bluetooth(void);
static void unused_rtc_event_handler(nrfx_rtc_int_type_t int_type) {}
volatile bool mpsl_event_pending = false;
volatile uint8_t rng = 0;
static __aligned(8) uint8_t sdc_mem[2000];
typedef struct i2c_response_t
{
    bool fail;
    uint8_t value;
} i2c_response_t;

i2c_response_t i2c_read(uint8_t device_address_7bit,
                        uint16_t register_address,
                        uint8_t register_mask)
{
    if (not_real_hardware)
    {
        return (i2c_response_t){.fail = false, .value = 0x00};
    }

    // Populate the default response in case of failure
    i2c_response_t i2c_response = {
        .fail = true,
        .value = 0x00,
    };

    // Create the tx payload, bus handle and transfer descriptors
    uint8_t tx_payload[2] = {(uint8_t)(register_address), 0};

    nrfx_twim_xfer_desc_t i2c_tx = NRFX_TWIM_XFER_DESC_TX(device_address_7bit,
                                                          tx_payload,
                                                          1);

    // Switch bus and use 16-bit addressing if the camera is requested
    if (device_address_7bit == CAMERA_I2C_ADDRESS)
    {
        tx_payload[0] = (uint8_t)(register_address >> 8);
        tx_payload[1] = (uint8_t)register_address;
        i2c_tx.primary_length = 2;
    }

    nrfx_twim_xfer_desc_t i2c_rx = NRFX_TWIM_XFER_DESC_RX(device_address_7bit,
                                                          &i2c_response.value,
                                                          1);

    // Try several times
    for (uint8_t i = 0; i < 3; i++)
    {
        nrfx_err_t tx_err = nrfx_twim_xfer(&i2c_instance, &i2c_tx, 0);

        if (tx_err == NRFX_ERROR_NOT_SUPPORTED ||
            tx_err == NRFX_ERROR_INTERNAL ||
            tx_err == NRFX_ERROR_INVALID_ADDR ||
            tx_err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            app_err(tx_err);
        }

        nrfx_err_t rx_err = nrfx_twim_xfer(&i2c_instance, &i2c_rx, 0);

        if (rx_err == NRFX_ERROR_NOT_SUPPORTED ||
            rx_err == NRFX_ERROR_INTERNAL ||
            rx_err == NRFX_ERROR_INVALID_ADDR ||
            rx_err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            app_err(rx_err);
        }

        if (tx_err == NRFX_SUCCESS && rx_err == NRFX_SUCCESS)
        {
            i2c_response.fail = false;
            break;
        }
    }

    i2c_response.value &= register_mask;

    return i2c_response;
}

i2c_response_t i2c_write(uint8_t device_address_7bit,
                         uint16_t register_address,
                         uint8_t register_mask,
                         uint8_t set_value)
{
    i2c_response_t resp = {.fail = false, .value = 0x00};

    if (not_real_hardware)
    {
        return resp;
    }

    if (register_mask != 0xFF)
    {
        resp = i2c_read(device_address_7bit, register_address, 0xFF);

        if (resp.fail)
        {
            return resp;
        }
    }

    // Create a combined value with the existing data and the new value
    uint8_t updated_value = (resp.value & ~register_mask) |
                            (set_value & register_mask);

    // Create the tx payload, bus handle and transfer descriptor
    uint8_t tx_payload[3] = {(uint8_t)register_address, updated_value, 0};

    nrfx_twim_xfer_desc_t i2c_tx = NRFX_TWIM_XFER_DESC_TX(device_address_7bit,
                                                          tx_payload,
                                                          2);

    // Switch bus and use 16-bit addressing if the camera is requested
    if (device_address_7bit == CAMERA_I2C_ADDRESS)
    {
        tx_payload[0] = (uint8_t)(register_address >> 8);
        tx_payload[1] = (uint8_t)register_address;
        tx_payload[2] = updated_value;
        i2c_tx.primary_length = 3;
    }

    // Try several times
    for (uint8_t i = 0; i < 3; i++)
    {
        nrfx_err_t err = nrfx_twim_xfer(&i2c_instance, &i2c_tx, 0);

        if (err == NRFX_ERROR_BUSY ||
            err == NRFX_ERROR_NOT_SUPPORTED ||
            err == NRFX_ERROR_INTERNAL ||
            err == NRFX_ERROR_INVALID_ADDR ||
            err == NRFX_ERROR_DRV_TWI_ERR_OVERRUN)
        {
            app_err(err);
        }

        if (err == NRFX_SUCCESS)
        {
            break;
        }

        // If the last try failed. Don't continue
        if (i == 2)
        {
            resp.fail = true;
            return resp;
        }
    }

    return resp;
}

void spi_read(uint8_t *data, size_t length, uint32_t cs_pin, bool hold_down_cs)
{
    nrf_gpio_pin_clear(cs_pin);

    nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_RX(data, length);
    app_err(nrfx_spim_xfer(&spi_instance, &xfer, 0));

    if (!hold_down_cs)
    {
        nrf_gpio_pin_set(cs_pin);
    }
}

void spi_write(uint8_t *data, size_t length, uint32_t cs_pin, bool hold_down_cs)
{
    nrf_gpio_pin_clear(cs_pin);

    if (!nrfx_is_in_ram(data))
    {
        uint8_t *m_data = malloc(length);
        memcpy(m_data, data, length);
        nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_TX(m_data, length);
        app_err(nrfx_spim_xfer(&spi_instance, &xfer, 0));
        free(m_data);
    }
    else
    {
        nrfx_spim_xfer_desc_t xfer = NRFX_SPIM_XFER_TX(data, length);
        app_err(nrfx_spim_xfer(&spi_instance, &xfer, 0));
    }

    if (!hold_down_cs)
    {
        nrf_gpio_pin_set(cs_pin);
    }
}

static void power_down_network_core(void)
{
    if (prevent_sleep)
    {
        message_t response = MESSAGE_WITHOUT_PAYLOAD(SLEEP_PREVENTED);
        push_message(response);
        return;
    }

    message_t response = MESSAGE_WITHOUT_PAYLOAD(READY_TO_SLEEP);
    push_message(response);
}

static void interprocessor_message_handler(void)
{
    while (pending_message_length() > 0)
    {
        message_t *message = new_message(pending_message_length());

        pop_message(message);

        switch (message->instruction)
        {
        case PREPARE_FOR_SLEEP:
            power_down_network_core();
            break;

        case LOG_FROM_APPLICATION_CORE:
            NRFX_LOG("%s", message->payload);
            break;

        default:
            app_err(UNHANDLED_MESSAGE_INSTRUCTION);
            break;
        }

        free_message(message);
    }
}

static void setup_network_core(void)
{
    // Configure the RTC
    {
        nrfx_rtc_config_t config = NRFX_RTC_DEFAULT_CONFIG;

        // 1024Hz = >1ms resolution
        config.prescaler = NRF_RTC_FREQ_TO_PRESCALER(1024);

        app_err(nrfx_rtc_init(&rtc_instance, &config, unused_rtc_event_handler));
        nrfx_rtc_enable(&rtc_instance);

        // Call tick interrupt every ms to wake up the core
        nrfx_rtc_tick_enable(&rtc_instance, true);
    }

    // Configure the I2C driver
    {
        nrfx_twim_config_t i2c_config = {
            .scl_pin = I2C_SCL_PIN,
            .sda_pin = I2C_SDA_PIN,
            .frequency = NRF_TWIM_FREQ_100K,
            .interrupt_priority = NRFX_TWIM_DEFAULT_CONFIG_IRQ_PRIORITY,
            .hold_bus_uninit = false,
        };

        app_err(nrfx_twim_init(&i2c_instance, &i2c_config, NULL, NULL));

        nrfx_twim_enable(&i2c_instance);
    }

    // Scan the PMIC & IMU for their chip IDs. Camera is checked later
    {
        i2c_response_t magnetometer_response =
            i2c_read(MAGNETOMETER_I2C_ADDRESS, 0x0F, 0xFF);

        i2c_response_t pmic_response =
            i2c_read(PMIC_I2C_ADDRESS, 0x14, 0x0F);

        // If both chips fail to respond, it likely that we're using a devkit
        if (magnetometer_response.fail && pmic_response.fail)
        {
            NRFX_LOG("Running on nRF5340-DK");
            not_real_hardware = true;
        }

        if (not_real_hardware == false)
        {
            if (magnetometer_response.value != 0x49)
            {
                app_err(HARDWARE_ERROR);
            }

            if (pmic_response.value != 0x02)
            {
                app_err(HARDWARE_ERROR);
            }
        }
    }

    // Configure the PMIC registers
    {
        // Set the SBB drive strength
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2F, 0x03, 0x01).fail);

        // Set SBB0 to 1.0V
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x29, 0x7F, 0x04).fail);

        // Set SBB2 to 2.7V
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2D, 0x7F, 0x26).fail);

        // Set LDO0 to 1.2V
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x38, 0x7F, 0x10).fail);

        // Turn on SBB0 (1.0V rail) with 500mA limit
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2A, 0x37, 0x26).fail);

        // Turn on LDO0 (1.2V rail)
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x39, 0x07, 0x06).fail);

        // Turn on SBB2 (2.7V rail) with 333mA limit
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x2E, 0x37, 0x36).fail);

        // Vhot & Vwarm = 45 degrees. Vcool = 15 degrees. Vcold = 0 degrees
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x20, 0xFF, 0x2E).fail);

        // Set CHGIN limit to 475mA
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x21, 0x1C, 0x10).fail);

        // Charge termination current to 5%, and top-off timer to 30mins
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x22, 0x1F, 0x06).fail);

        // Set junction regulation temperature to 70 degrees
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x23, 0xE0, 0x20).fail);

        // Set the fast charge current value to 225mA
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x24, 0xFC, 0x74).fail);

        // Set the Vcool & Vwarm current to 112.5mA, and enable the thermistor
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x25, 0xFE, 0x3A).fail);

        // Set constant voltage to 4.3V for both fast charge and JEITA
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x26, 0xFC, 0x70).fail);
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x27, 0xFC, 0x70).fail);

        // Connect AMUX to battery voltage
        app_err(i2c_write(PMIC_I2C_ADDRESS, 0x28, 0x0F, 0x03).fail);
    }

    // Initialize the SPI and configure the display
    {
        nrf_gpio_cfg_output(DISPLAY_SPI_SELECT_PIN);
        nrf_gpio_pin_set(DISPLAY_SPI_SELECT_PIN);

        nrfx_twim_disable(&i2c_instance);

        nrfx_spim_config_t spi_config = NRFX_SPIM_DEFAULT_CONFIG(
            DISPLAY_SPI_CLOCK_PIN,
            DISPLAY_SPI_DATA_PIN,
            NRF_SPIM_PIN_NOT_CONNECTED,
            NRF_SPIM_PIN_NOT_CONNECTED);

        spi_config.mode = NRF_SPIM_MODE_3;
        spi_config.bit_order = NRF_SPIM_BIT_ORDER_LSB_FIRST;

        app_err(nrfx_spim_init(&spi_instance, &spi_config, NULL, NULL));

        for (size_t i = 0;
             i < sizeof(display_config) / sizeof(display_config_t);
             i++)
        {
            uint8_t command[2] = {display_config[i].address,
                                  display_config[i].value};

            spi_write(command, sizeof(command), DISPLAY_SPI_SELECT_PIN, false);
        }
    }

    // Re-initialize the I2C and configure the camera
    {
        nrfx_spim_uninit(&spi_instance);

        nrfx_twim_enable(&i2c_instance);

        // Wake up the camera
        nrf_gpio_pin_write(CAMERA_SLEEP_PIN, false);

        // Check the chip ID
        i2c_response_t camera_response =
            i2c_read(CAMERA_I2C_ADDRESS, 0x300A, 0xFF);

        if (not_real_hardware == false)
        {
            if (camera_response.value != 0x97)
            {
                app_err(HARDWARE_ERROR);
            }
        }

        // Program the configuration
        for (size_t i = 0;
             i < sizeof(camera_config) / sizeof(camera_config_t);
             i++)
        {
            i2c_write(CAMERA_I2C_ADDRESS,
                      camera_config[i].address,
                      0xFF,
                      camera_config[i].value);
        }

        // Put the camera to sleep
        nrf_gpio_pin_write(CAMERA_SLEEP_PIN, true);
    }

    // Initialize the inter-processor communication
    {
        setup_messaging(interprocessor_message_handler);
    }

    // Inform the application processor that the hardware is configured
    {
        message_t message = MESSAGE_WITHOUT_PAYLOAD(NETWORK_CORE_READY);
        push_message(message);
    }

    // If not real hardware, inform the application processor
    if (not_real_hardware)
    {
        message_t message = MESSAGE_WITHOUT_PAYLOAD(NOT_REAL_HARDWARE);
        push_message(message);
    }

    NRFX_LOG("Network core configured");
}

int main(void)
{
    NRFX_LOG(RTT_CTRL_RESET RTT_CTRL_CLEAR);
    NRFX_LOG("MicroPython on Frame - " BUILD_VERSION " (" GIT_COMMIT ")");

    setup_network_core();

    nrfx_systick_init();
    sdc_cfg_t cfg;

    // MPSL initialization

    NRFX_IRQ_PRIORITY_SET(SWI1_IRQn, LOW_PRIORITY);
    NRFX_IRQ_ENABLE(SWI1_IRQn);
    NRFX_IRQ_PRIORITY_SET(RTC0_IRQn, 0);
    NRFX_IRQ_ENABLE(RTC0_IRQn);
    NRFX_IRQ_PRIORITY_SET(RADIO_IRQn, 0);
    NRFX_IRQ_ENABLE(RADIO_IRQn);
    NRFX_IRQ_PRIORITY_SET(TIMER0_IRQn, 0);
    NRFX_IRQ_ENABLE(TIMER0_IRQn);
    NRFX_IRQ_PRIORITY_SET(TIMER1_IRQn, 0);

    NRFX_IRQ_ENABLE(TIMER1_IRQn);
    mpsl_clock_lfclk_cfg_t mpsl_clock_config = {
        .source = MPSL_CLOCK_LF_SRC_SYNTH,
        .accuracy_ppm = MPSL_DEFAULT_CLOCK_ACCURACY_PPM,
        .rc_ctiv = 0,
        .rc_temp_ctiv = 0,
        .skip_wait_lfclk_started = MPSL_DEFAULT_SKIP_WAIT_LFCLK_STARTED};

    checkError(mpsl_init(&mpsl_clock_config, SWI1_IRQn, mpsl_assert_handler));

    nrfx_rng_config_t rng_config = NRFX_RNG_DEFAULT_CONFIG;
    app_err(nrfx_rng_init(&rng_config, rng_evt_handler));

    nrfx_rng_start();
    while (1)
    {
        run_micropython();
    }
}

// A fault handler function that prints the error code and halts the execution
static void my_fault_handler(const char *file, const uint32_t line)
{
    NRFX_LOG("SoftDevice Controller fault: file=%s, line=%lu\n", file, line);
    for (;;)
    {
    }
}

static void mpsl_assert_handler(const char *const file, const uint32_t line)
{
    NRFX_LOG("mpsl_assert_error: %s:%d", file, line);
};

static inline void sdc_callback()
{
    uint8_t hci_buffer[HCI_MSG_BUFFER_MAX_SIZE];
    sdc_hci_msg_type_t msg_type;
    int32_t err_code;
    msg_type = SDC_HCI_MSG_TYPE_EVT;
    err_code = sdc_hci_get(hci_buffer, &msg_type);
    NRFX_LOG("sdc_get: %d", err_code);
    if (err_code == 0)
    {
        // A packet was retrieved successfully
        switch (hci_buffer[0])
        {
        case 0x01:
            // Handle HCI Command packet
            break;
        case 0x02:
            // Handle HCI ACL Data packet
            break;
        case 0x03:
            // Handle HCI Synchronous Data packet
            break;
        case 0x04:
            // Handle HCI Event packet
            break;
        case 0x05:
            // Handle HCI ISO Data packet
            break;
        default:
            // Invalid PI field
            break;
        }
    }
    else if (err_code == -NRF_EAGAIN)
    {
        // No packets available
    }
    else if (err_code == -NRF_EINVAL)
    {
        // Invalid argument provided
    }
    else
    {
        // Unexpected error code
    }
    NRFX_LOG("sdc_callback called %d", err_code);
}
void checkError(int32_t ret_code)
{
    NRFX_LOG("Response: %d", ret_code);
    if (ret_code == -NRF_EINVAL || ret_code == -NRF_EPERM || ret_code == -NRF_EOPNOTSUPP || ret_code == -NRF_ENOMEM)
    {
        app_err(ret_code);
    }
    return;
}

void setup_bluetooth(void)
{
    nrfx_systick_init();
    sdc_cfg_t cfg;

    // MPSL initialization

    NRFX_IRQ_PRIORITY_SET(SWI1_IRQn, LOW_PRIORITY);
    NRFX_IRQ_ENABLE(SWI1_IRQn);
    NRFX_IRQ_PRIORITY_SET(RTC0_IRQn, 0);
    NRFX_IRQ_ENABLE(RTC0_IRQn);
    NRFX_IRQ_PRIORITY_SET(RADIO_IRQn, 0);
    NRFX_IRQ_ENABLE(RADIO_IRQn);
    NRFX_IRQ_PRIORITY_SET(TIMER0_IRQn, 0);
    NRFX_IRQ_ENABLE(TIMER0_IRQn);
    NRFX_IRQ_PRIORITY_SET(TIMER1_IRQn, 0);

    NRFX_IRQ_ENABLE(TIMER1_IRQn);
    mpsl_clock_lfclk_cfg_t mpsl_clock_config = {
        .source = MPSL_CLOCK_LF_SRC_SYNTH,
        .accuracy_ppm = MPSL_DEFAULT_CLOCK_ACCURACY_PPM,
        .rc_ctiv = 0,
        .rc_temp_ctiv = 0,
        .skip_wait_lfclk_started = MPSL_DEFAULT_SKIP_WAIT_LFCLK_STARTED};

    checkError(mpsl_init(&mpsl_clock_config, SWI1_IRQn, mpsl_assert_handler));

    nrfx_rng_config_t rng_config = NRFX_RNG_DEFAULT_CONFIG;
    app_err(nrfx_rng_init(&rng_config, rng_evt_handler));

    nrfx_rng_start();
    sdc_rand_source_t my_rand_source = {
        .rand_prio_low_get = rand_get,
        .rand_prio_high_get = rand_get,
        .rand_poll = rand_poll};

    checkError(sdc_init(&my_fault_handler));
    sdc_rand_source_register(&my_rand_source);
    sdc_default_tx_power_set(0);
    checkError(sdc_support_adv());
    checkError(sdc_support_peripheral());
    checkError(sdc_support_dle_peripheral());
    checkError(sdc_support_phy_update_peripheral());
    checkError(sdc_support_le_2m_phy());

    cfg.central_count.count = 0;
    checkError(sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_CENTRAL_COUNT, &cfg));
    cfg.adv_count.count = SDC_DEFAULT_ADV_COUNT;
    checkError(sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_ADV_COUNT, &cfg));
    cfg.peripheral_count.count = SDC_DEFAULT_PERIPHERAL_COUNT;
    checkError(sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_PERIPHERAL_COUNT, &cfg));
    cfg.event_length.event_length_us = SDC_DEFAULT_EVENT_LENGTH_US;
    checkError(sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_EVENT_LENGTH, &cfg));
    cfg.buffer_cfg.tx_packet_size = SDC_DEFAULT_TX_PACKET_SIZE;
    cfg.buffer_cfg.rx_packet_size = SDC_DEFAULT_RX_PACKET_SIZE;
    cfg.buffer_cfg.tx_packet_count = SDC_DEFAULT_TX_PACKET_COUNT;
    cfg.buffer_cfg.rx_packet_count = SDC_DEFAULT_RX_PACKET_COUNT;

    checkError(sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_BUFFER_CFG, &cfg));
    cfg.adv_buffer_cfg.max_adv_data = SDC_DEFAULT_ADV_BUF_SIZE;
    checkError(sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_ADV_BUFFER_CFG, &cfg));

    checkError(sdc_enable(sdc_callback, sdc_mem));
    checkError(sdc_hci_cmd_cb_reset());
    sdc_callback();
    sdc_hci_cmd_cb_set_event_mask_t evt_mask = {.raw = {0xde, 0x0b, 0x00, 0x00, 0x00, 0x80, 0x00, 0x00}};
    checkError(sdc_hci_cmd_cb_set_event_mask(&evt_mask));
    sdc_callback();
    sdc_hci_cmd_le_set_random_address_t rand_address = {.random_address = {0xad, 0x4b, 0xe2, 0x43, 0x2d, 0xc0}};
    checkError(sdc_hci_cmd_le_set_random_address(&rand_address));
    sdc_callback();
    sdc_hci_cmd_le_set_adv_params_t adv_param = {
        .adv_interval_min = 0x00a0,
        .adv_interval_max = 0x00f0,
        .adv_type = 0x00,
        .own_address_type = 0x01,
        .peer_address_type = 0x00,
        .peer_address = {0, 0, 0, 0, 0, 0},
        .adv_channel_map = 0x07,
        .adv_filter_policy = 0x00};
    checkError(sdc_hci_cmd_le_set_adv_params(&adv_param));
    sdc_callback();
    sdc_hci_cmd_le_set_adv_data_t adv_data = {
        .adv_data = {
            0x0b, 0x02, 0x01, 0x06, 0x07, 0x03, 0x0d, 0x18,
            0x0f, 0x18, 0x0a, 0x18, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
        .adv_data_length = 31};
    checkError(sdc_hci_cmd_le_set_adv_data(&adv_data));
    sdc_callback();
    sdc_hci_cmd_le_set_scan_response_data_t scan_response = {
        .scan_response_data = {
            0x19, 0x18, 0x09, 0x5a, 0x65, 0x70, 0x68, 0x79,
            0x72, 0x20, 0x48, 0x65, 0x61, 0x72, 0x74, 0x72,
            0x61, 0x74, 0x65, 0x20, 0x53, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
        .scan_response_data_length = 31};
    checkError(sdc_hci_cmd_le_set_scan_response_data(&scan_response));
    sdc_callback();
    sdc_hci_cmd_le_set_adv_enable_t adv_enable = {.adv_enable = 0x01};

    checkError(sdc_hci_cmd_le_set_adv_enable(&adv_enable));
    sdc_callback();
    NRFX_LOG("BLE  setup done");
    return;
}
