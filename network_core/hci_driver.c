/*
 * Copyright (c) 2018 - 2020 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <sdc.h>
#include <sdc_soc.h>
#include <sdc_hci.h>
#include <sdc_hci_vs.h>
#include "sdc_hci_cmd_controller_baseband.h"
#include "sdc_hci_cmd_info_params.h"
#include "sdc_hci_cmd_le.h"
#include "sdc_hci_cmd_link_control.h"
#include "sdc_hci_cmd_status_params.h"
#include "hci_internal.h"
#include "rng_helper.h"
#include "mpsl.h"
#include "hci.h"
/** Data size needed for HCI Event RX buffers */
#define BT_BUF_EVT_RX_SIZE BT_BUF_EVT_SIZE(68)
#define BT_BUF_RX_SIZE BT_BUF_EVT_SIZE(68)
#define MPSL_SWI SWI0_IRQn
volatile uint8_t rng = 0;
static __aligned(8) uint8_t sdc_mempool[2000];

void check_error(int32_t ret_code)
{
    // NRFX_LOG("Response: %d", ret_code);
    if (ret_code == -NRF_EINVAL || ret_code == -NRF_EPERM || ret_code == -NRF_EOPNOTSUPP || ret_code == -NRF_ENOMEM)
    {
        app_err(ret_code);
    }
    return;
}

void sdc_assertion_handler(const char *file, const uint32_t line)
{
    // NRFX_LOG("SoftDevice Controller fault: file=%s, line=%lu\n", file, line);
    // for (;;)
    // {
    // }
}

// static int cmd_handle(struct net_buf cmd)
// {
//     int errcode = hci_internal_cmd_put(cmd.data);
//     if (errcode)
//     {
//         return errcode;
//     }

//     hci_driver_receive_process();

//     return 0;
// }

// static int acl_handle(struct net_buf *acl)
// {

//      int32_t   errcode = sdc_hci_data_put(acl->data);

//     if (errcode)
//     {
//         /* Likely buffer overflow event */
//         hci_driver_receive_process();
//     }

//     return errcode;
// }
void bt_hci_receive(uint8_t *buf)
{
    uint8_t event = buf[0];
    if (event == 0x05)
    {
        ble_advertise();
    }
    // for (size_t i = 0; i < sizeof(buf); i++)
    // {
    //     SEGGER_RTT_printf(0, "0x%02x ", buf[i]); // Print the elements of buf
    // }
}

static void data_packet_process(uint8_t *hci_buf)
{
    // for (size_t i = 0; i < sizeof(hci_buf); i++)
    // {
    //     SEGGER_RTT_printf(0, "0x%02x ", hci_buf[i]); // Print the elements of buf
    // }
    // struct net_buf *data_buf = bt_buf_get_rx(BT_BUF_ACL_IN, K_FOREVER);
    // struct bt_hci_acl_hdr *hdr = (void *)hci_buf;
    // uint16_t hf, handle, len;
    // uint8_t flags, pb, bc;
    // TODO  proceess and return data

    // if (!data_buf)
    // {
    //     NRFX_LOG("No data buffer available");
    //     return;
    // }

    // len = hdr->len;
    // hf = hdr->handle;
    // handle = bt_acl_handle(hf);
    // flags = bt_acl_flags(hf);
    // pb = bt_acl_flags_pb(flags);
    // bc = bt_acl_flags_bc(flags);

    // NRFX_LOG("Data: handle (0x%02x), PB(%01d), BC(%01d), len(%u)", handle, pb, bc, len);

    // net_buf_add_mem(data_buf, &hci_buf[0], len + sizeof(*hdr));
    // bt_recv(data_buf);
}

// static bool event_packet_is_discardable(const uint8_t *hci_buf)
// {
//     struct bt_hci_evt_hdr *hdr = (void *)hci_buf;

//     switch (hdr->evt)
//     {
//     case BT_HCI_EVT_LE_META_EVENT:
//     {
//         struct bt_hci_evt_le_meta_event *me = (void *)&hci_buf[2];

//         switch (me->subevent)
//         {
//         case BT_HCI_EVT_LE_ADVERTISING_REPORT:
//             return true;
// #if defined(CONFIG_BT_EXT_ADV)
//         case BT_HCI_EVT_LE_EXT_ADVERTISING_REPORT:
//         {
//             const struct bt_hci_evt_le_ext_advertising_report *ext_adv =
//                 (void *)&hci_buf[3];

//             return (ext_adv->num_reports == 1) &&
//                    ((ext_adv->adv_info->evt_type & BT_HCI_LE_ADV_EVT_TYPE_LEGACY) != 0);
//         }
// #endif
//         default:
//             return false;
//         }
//     }
//     case BT_HCI_EVT_VENDOR:
//     {
//         uint8_t subevent = hci_buf[2];

//         switch (subevent)
//         {
//         case SDC_HCI_SUBEVENT_VS_QOS_CONN_EVENT_REPORT:
//             return true;
//         default:
//             return false;
//         }
//     }
//     default:
//         return false;
//     }
// }
static void ble_conn(uint8_t *buff)
{
    struct bt_hci_evt_le_enh_conn_complete *evt = (void *)buff;
    uint16_t handle = evt->handle;
    // bool is_disconnected = conn_handle_is_disconnected(handle);
    // bt_addr_le_t peer_addr, id_addr;
    // struct bt_conn *conn;
    // uint8_t id;

    NRFX_LOG("status 0x%02x handle %u role %u", evt->status, handle,
             evt->role);
    // LOG_DBG("local RPA %s", bt_addr_str(&evt->local_rpa));
}
static void handle_meta_events(uint8_t *evt)
{
    struct bt_hci_evt_le_meta_event *me = (void *)&evt[2];

    NRFX_LOG("LE Meta Event (0x%02x)", me->subevent);
    switch (me->subevent)
    {
    case BT_HCI_EVT_LE_ENH_CONN_COMPLETE:
        ble_conn(evt);
        break;

    default:
        break;
    }
}
static void event_packet_process(uint8_t *hci_buf)
{
    struct bt_hci_evt_hdr *hdr = (void *)hci_buf;
    if (hdr->evt == BT_HCI_EVT_LE_META_EVENT)
    {

        handle_meta_events(hci_buf);
    }
    else if (hdr->evt == BT_HCI_EVT_CMD_COMPLETE)
    {
        // struct bt_hci_evt_cmd_complete *cc = (void *)&hci_buf[2];
        // struct bt_hci_evt_cc_status *ccs = (void *)&hci_buf[5];
        // uint16_t opcode = sys_le16_to_cpu(cc->opcode);

        NRFX_LOG("Command Complete");
        //          " ncmd: %u, len %u",
        //          opcode, ccs->status, cc->ncmd, hdr->len);
    }
    else if (hdr->evt == BT_HCI_EVT_CMD_STATUS)
    {
        // struct bt_hci_evt_cmd_status *cs = (void *)&hci_buf[2];
        // uint16_t opcode = sys_le16_to_cpu(cs->opcode);

        NRFX_LOG("Command Status ");
    }
    else
    {
        NRFX_LOG("Event (0x%02x) len %u", hdr->evt, hdr->len);
    }
    //  TODO call receive with ble event
    uint8_t evt_buf[hdr->len + sizeof(*hdr)];
    memcpy(evt_buf, &hci_buf[0], hdr->len + sizeof(*hdr));
    bt_hci_receive(&evt_buf[0]);
}

static bool fetch_and_process_hci_msg(uint8_t *p_hci_buffer)
{
    int errcode;
    sdc_hci_msg_type_t msg_type = 0;

    errcode = sdc_hci_get(p_hci_buffer, &msg_type);

    if (errcode)
    {
        return false;
    }
    NRFX_LOG("================= Receive ========================");
    NRFX_LOG("error: %d, msg_type: %u", errcode, msg_type);
    // for (int i = 0; i < sizeof(p_hci_buffer); i++) {
    // 	SEGGER_RTT_printf("%02x ", p_hci_buffer[i]);
    // }
    for (size_t i = 0; i < sizeof(p_hci_buffer); i++)
    {
        SEGGER_RTT_printf(0, "0x%02x ", p_hci_buffer[i]); // Print the elements of buf
    }
    NRFX_LOG("");
    NRFX_LOG("================= Receive End ========================");
    if (msg_type == SDC_HCI_MSG_TYPE_EVT)
    {
        event_packet_process(p_hci_buffer);
    }
    else if (msg_type == SDC_HCI_MSG_TYPE_DATA)
    {
        data_packet_process(p_hci_buffer);
    }
    else
    {
        NRFX_LOG("Unexpected msg_type: %u. This if-else needs a new branch", msg_type);
    }
    hci_driver_receive_process();
    return true;
}

void hci_driver_receive_process(void)
{
    static uint8_t hci_buf[HCI_MSG_BUFFER_MAX_SIZE];

    fetch_and_process_hci_msg(&hci_buf[0]);
}

static int configure_supported_features(void)
{
    check_error(sdc_support_adv());
    check_error(sdc_support_peripheral());
    check_error(sdc_support_dle_peripheral());
    check_error(sdc_support_le_2m_phy());
    check_error(sdc_support_le_coded_phy());
    check_error(sdc_support_phy_update_peripheral());
    return 0;
}

static int configure_memory_usage(void)
{
    int required_memory;
    sdc_cfg_t cfg;

    cfg.central_count.count = 0;
    required_memory = sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_CENTRAL_COUNT, &cfg);

    cfg.peripheral_count.count = 1;
    required_memory = sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_PERIPHERAL_COUNT, &cfg);

    cfg.fal_size = 8;
    required_memory = sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_FAL_SIZE, &cfg);

    cfg.buffer_cfg.rx_packet_size = 27;
    cfg.buffer_cfg.tx_packet_size = 27;
    cfg.buffer_cfg.rx_packet_count = 2;
    cfg.buffer_cfg.tx_packet_count = 3;
    required_memory = sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_BUFFER_CFG, &cfg);

    cfg.event_length.event_length_us = 7500;
    required_memory = sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_EVENT_LENGTH, &cfg);

    cfg.adv_count.count = 1;
    required_memory = sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_ADV_COUNT, &cfg);

    cfg.adv_buffer_cfg.max_adv_data = 31;
    required_memory = sdc_cfg_set(SDC_DEFAULT_RESOURCE_CFG_TAG, SDC_CFG_TYPE_ADV_BUFFER_CFG, &cfg);

    NRFX_LOG("BT mempool size: %u, required: %u", sizeof(sdc_mempool), required_memory);

    if (required_memory > sizeof(sdc_mempool))
    {
        NRFX_LOG("Allocated memory too low: %u < %u", sizeof(sdc_mempool), required_memory);
    }

    return 0;
}

// int hci_driver_close(void)
// {
//     int err;

//     err = sdc_disable();
//     if (err)
//     {
//         return err;
//     }

//     mpsl_uninit();

//     return err;
// }
static void mpsl_assert_handler(const char *const file, const uint32_t line)
{
    NRFX_LOG("mpsl_assert_error: %s:%d", file, line);
};
void mpsl_low_priority_handler()
{
    // NRFX_LOG("in SWI0_IRQHandler");
    mpsl_low_priority_process();
    // NRFX_IRQ_PENDING_CLEAR(MPSL_SWI);
}

int clock_irq_handler_wrapper()
{
    // NRFX_LOG("in clock_irq_handler_wrapper");
    MPSL_IRQ_CLOCK_Handler();
    return 0;
}

void radio_irq_handler_wrapper()
{
    // NRFX_LOG("in radio_irq_handler_wrapper");
    MPSL_IRQ_RADIO_Handler();
}

void rtc_0_irq_handler_wrapper()
{
    // NRFX_LOG("in RTC_IRQHandler")
    MPSL_IRQ_RTC0_Handler();
}

void timer_0_irq_handler_wrapper()
{

    MPSL_IRQ_TIMER0_Handler();
}
static void mpsl_lib_init(void)
{

    mpsl_clock_lfclk_cfg_t mpsl_clock_config = {
        .source = MPSL_CLOCK_LF_SRC_SYNTH,
        .accuracy_ppm = 50,
        .rc_ctiv = 0,
        .rc_temp_ctiv = 0,
        .skip_wait_lfclk_started = false};

    NRFX_IRQ_PRIORITY_SET(RTC0_IRQn, MPSL_HIGH_IRQ_PRIORITY);
    NRFX_IRQ_PRIORITY_SET(RADIO_IRQn, MPSL_HIGH_IRQ_PRIORITY);
    NRFX_IRQ_PRIORITY_SET(TIMER0_IRQn, MPSL_HIGH_IRQ_PRIORITY);
    NRFX_IRQ_PRIORITY_SET(TIMER1_IRQn, MPSL_HIGH_IRQ_PRIORITY);
    check_error(mpsl_init(&mpsl_clock_config, MPSL_SWI, mpsl_assert_handler));
    NRFX_IRQ_PRIORITY_SET(MPSL_SWI, 4);
    NRFX_IRQ_ENABLE(MPSL_SWI);
}
void ble_advertise()
{
    // sdc_hci_cmd_le_read_buffer_size_return_t buff_size;
    // check_error(sdc_hci_cmd_le_read_buffer_size(&buff_size));
    // NRFX_LOG("0x%04x, 0x%02x", buff_size.le_acl_data_packet_length, buff_size.total_num_le_acl_data_packets);
    sdc_hci_cmd_vs_zephyr_read_static_addresses_return_t static_address;
    check_error(sdc_hci_cmd_vs_zephyr_read_static_addresses(&static_address));
    sdc_hci_cmd_le_set_random_address_t rand_address = {.random_address = {0, 0, 0, 0, 0, 0}};

    for (size_t i = 0; i < static_address.num_addresses; i++)
    {
        for (size_t j = 0; j < 6; j++)
        {
            rand_address.random_address[j] = static_address.addresses[i].address[j];
            // SEGGER_RTT_printf(0, "0x%02x ", static_address.addresses[i].address[j]); // Print the elements of buf
        }
        // NRFX_LOG("");
    }

    check_error(sdc_hci_cmd_le_set_random_address(&rand_address));

    sdc_hci_cmd_le_set_event_mask_t event_mask_le = {
        .raw = {0xDE, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00}};
    check_error(sdc_hci_cmd_le_set_event_mask(&event_mask_le));

    sdc_hci_cmd_cb_set_event_mask_t event_mask = {
        .raw = {0x90, 0x88, 0x00, 0x02, 0x00, 0x80, 0x00, 0x20}};
    check_error(sdc_hci_cmd_cb_set_event_mask(&event_mask));
    hci_driver_receive_process();
    sdc_hci_cmd_le_set_adv_params_t adv_param = {
        .adv_interval_min = 0x00a0,
        .adv_interval_max = 0x00f0,
        .adv_type = 0x00,
        .own_address_type = 0x01,
        .peer_address_type = 0x00,
        .peer_address = {0, 0, 0, 0, 0, 0},
        .adv_channel_map = 0x07,
        .adv_filter_policy = 0x00};
    check_error(sdc_hci_cmd_le_set_adv_params(&adv_param));
    hci_driver_receive_process();
    sdc_hci_cmd_le_set_adv_data_t adv_data = {
        .adv_data = {
            //  Len   type  data
            0x02, 0x01, 0x06,
            0x06, 0x09, 'f', 'r', 'a', 'm', 'e',
            0x11, 0x07, 0x9E, 0xCA, 0xDC, 0x24, 0x0E, 0xE5, 0xA9, 0xE0, 0x93, 0xF3, 0xA3, 0xB5, 0x01, 0x00, 0x40, 0x6E},
        .adv_data_length = 28};
    check_error(sdc_hci_cmd_le_set_adv_data(&adv_data));
    hci_driver_receive_process();
    // sdc_hci_cmd_le_set_scan_response_data_t scan_response = {
    //     .scan_response_data = {
    //         0x19, 0x18, 0x09, 0x5a, 0x65, 0x70, 0x68, 0x79,
    //         0x72, 0x20, 0x48, 0x65, 0x61, 0x72, 0x74, 0x72,
    //         0x61, 0x74, 0x65, 0x20, 0x53, 0x00, 0x00, 0x00,
    //         0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00},
    //     .scan_response_data_length = 31};
    // NRFX_LOG("BLE  set scan data");
    // check_error(sdc_hci_cmd_le_set_scan_response_data(&scan_response));
    // hci_driver_receive_process();
    sdc_hci_cmd_le_set_adv_enable_t adv_enable = {.adv_enable = 0x01};
    // NRFX_LOG("BLE  ad enable");
    check_error(sdc_hci_cmd_le_set_adv_enable(&adv_enable));
    hci_driver_receive_process();
}
int32_t ble_init(void)
{

    nrfx_rng_config_t rng_config = NRFX_RNG_DEFAULT_CONFIG;
    app_err(nrfx_rng_init(&rng_config, rng_evt_handler));
    int err = 0;
    sdc_rand_source_t rand_functions = {.rand_prio_low_get = rand_get,
                                        .rand_prio_high_get = rand_get,
                                        .rand_poll = rand_poll};
    mpsl_lib_init();
    err = sdc_init(sdc_assertion_handler);

    err = configure_supported_features();

    err = configure_memory_usage();

    err = sdc_rand_source_register(&rand_functions);

    err = sdc_enable(hci_driver_receive_process, sdc_mempool);
    err = sdc_hci_cmd_cb_reset();
    return err;
}
