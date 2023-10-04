/*
 * Copyright (c) 2018 - 2020 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

#include <sdc.h>
#include <sdc_soc.h>
#include <sdc_hci.h>
#include <sdc_hci_vs.h>
#include "hci_internal.h"
#include "rng_helper.h"
#include "mpsl.h"
/** Data size needed for HCI Event RX buffers */
#define BT_BUF_EVT_RX_SIZE BT_BUF_EVT_SIZE(68)
#define BT_BUF_RX_SIZE BT_BUF_EVT_SIZE(68)
#define MPSL_SWI SWI0_IRQn
#if defined(CONFIG_BT_CONN) && defined(CONFIG_BT_CENTRAL)

/** Data size needed for HCI ACL, HCI ISO or Event RX buffers */

#if CONFIG_BT_MAX_CONN > 1
#define SDC_CENTRAL_COUNT (CONFIG_BT_MAX_CONN - CONFIG_BT_CTLR_SDC_PERIPHERAL_COUNT)
#else
/* Allow the case where BT_MAX_CONN, central and peripheral counts are 1. This
 * way we avoid wasting memory in the host if the device will only use one role
 * at a time.
 */
#define SDC_CENTRAL_COUNT 1
#endif /* CONFIG_BT_MAX_CONN > 1 */

#else
#define SDC_CENTRAL_COUNT 0
#endif /* defined(CONFIG_BT_CONN) && defined(CONFIG_BT_CENTRAL) */
#if defined(CONFIG_BT_BROADCASTER)
#if defined(CONFIG_BT_CTLR_ADV_EXT)
#define SDC_ADV_SET_COUNT CONFIG_BT_CTLR_ADV_SET
#define SDC_ADV_BUF_SIZE CONFIG_BT_CTLR_ADV_DATA_LEN_MAX
#else
#define SDC_ADV_SET_COUNT 1
#define SDC_ADV_BUF_SIZE SDC_DEFAULT_ADV_BUF_SIZE
#endif
#define SDC_ADV_SET_MEM_SIZE (SDC_ADV_SET_COUNT * SDC_MEM_PER_ADV_SET(SDC_ADV_BUF_SIZE))
#else
#define SDC_ADV_SET_COUNT 0
#define SDC_ADV_SET_MEM_SIZE 0
#endif

#if defined(CONFIG_BT_PER_ADV)
#if defined(CONFIG_BT_CTLR_SDC_PAWR_ADV)
#define SDC_PERIODIC_ADV_COUNT (CONFIG_BT_EXT_ADV_MAX_ADV_SET - CONFIG_BT_CTLR_SDC_PAWR_ADV_COUNT)
#else
#define SDC_PERIODIC_ADV_COUNT CONFIG_BT_EXT_ADV_MAX_ADV_SET
#endif
#define SDC_PERIODIC_ADV_MEM_SIZE \
    (SDC_PERIODIC_ADV_COUNT * SDC_MEM_PER_PERIODIC_ADV_SET(CONFIG_BT_CTLR_ADV_DATA_LEN_MAX))
#else
#define SDC_PERIODIC_ADV_COUNT 0
#define SDC_PERIODIC_ADV_MEM_SIZE 0
#endif

#if defined(CONFIG_BT_CTLR_SDC_PAWR_ADV)
#define PERIODIC_ADV_RSP_ENABLE_FAILURE_REPORTING \
    IS_ENABLED(CONFIG_BT_CTLR_SDC_PERIODIC_ADV_RSP_RX_FAILURE_REPORTING)
#define SDC_PERIODIC_ADV_RSP_MEM_SIZE                                                       \
    (CONFIG_BT_CTLR_SDC_PAWR_ADV_COUNT *                                                    \
     SDC_MEM_PER_PERIODIC_ADV_RSP_SET(CONFIG_BT_CTLR_ADV_DATA_LEN_MAX,                      \
                                      CONFIG_BT_CTLR_SDC_PERIODIC_ADV_RSP_TX_BUFFER_COUNT,  \
                                      CONFIG_BT_CTLR_SDC_PERIODIC_ADV_RSP_RX_BUFFER_COUNT,  \
                                      CONFIG_BT_CTLR_SDC_PERIODIC_ADV_RSP_TX_MAX_DATA_SIZE, \
                                      PERIODIC_ADV_RSP_ENABLE_FAILURE_REPORTING))
#else
#define SDC_PERIODIC_ADV_RSP_MEM_SIZE 0
#endif

#if defined(CONFIG_BT_CTLR_SDC_PAWR_SYNC) || defined(CONFIG_BT_PER_ADV_SYNC)
#define SDC_PERIODIC_ADV_SYNC_COUNT CONFIG_BT_PER_ADV_SYNC_MAX
#define SDC_PERIODIC_ADV_LIST_MEM_SIZE \
    SDC_MEM_PERIODIC_ADV_LIST(CONFIG_BT_CTLR_SYNC_PERIODIC_ADV_LIST_SIZE)
#else
#define SDC_PERIODIC_ADV_SYNC_COUNT 0
#define SDC_PERIODIC_ADV_LIST_MEM_SIZE 0
#endif

#if defined(CONFIG_BT_CTLR_SDC_PAWR_SYNC)
#define SDC_PERIODIC_SYNC_MEM_SIZE                                                       \
    (SDC_PERIODIC_ADV_SYNC_COUNT *                                                       \
     SDC_MEM_PER_PERIODIC_SYNC_RSP(CONFIG_BT_CTLR_SDC_PERIODIC_SYNC_RSP_TX_BUFFER_COUNT, \
                                   CONFIG_BT_CTLR_SDC_PERIODIC_SYNC_BUFFER_COUNT))
#elif defined(CONFIG_BT_PER_ADV_SYNC)
#define SDC_PERIODIC_SYNC_MEM_SIZE \
    (SDC_PERIODIC_ADV_SYNC_COUNT * \
     SDC_MEM_PER_PERIODIC_SYNC(CONFIG_BT_CTLR_SDC_PERIODIC_SYNC_BUFFER_COUNT))
#else
#define SDC_PERIODIC_SYNC_MEM_SIZE 0
#endif

#if defined(CONFIG_BT_OBSERVER)
#if defined(CONFIG_BT_CTLR_ADV_EXT)
#define SDC_SCAN_BUF_SIZE SDC_MEM_SCAN_BUFFER_EXT(CONFIG_BT_CTLR_SDC_SCAN_BUFFER_COUNT)
#else
#define SDC_SCAN_BUF_SIZE SDC_MEM_SCAN_BUFFER(CONFIG_BT_CTLR_SDC_SCAN_BUFFER_COUNT)
#endif
#else
#define SDC_SCAN_BUF_SIZE 0
#endif

#ifdef CONFIG_BT_CTLR_DATA_LENGTH_MAX
#define MAX_TX_PACKET_SIZE CONFIG_BT_CTLR_DATA_LENGTH_MAX
#define MAX_RX_PACKET_SIZE CONFIG_BT_CTLR_DATA_LENGTH_MAX
#else
#define MAX_TX_PACKET_SIZE SDC_DEFAULT_TX_PACKET_SIZE
#define MAX_RX_PACKET_SIZE SDC_DEFAULT_RX_PACKET_SIZE
#endif

#define CENTRAL_MEM_SIZE                                              \
    (SDC_MEM_PER_CENTRAL_LINK(MAX_TX_PACKET_SIZE, MAX_RX_PACKET_SIZE, \
                              CONFIG_BT_CTLR_SDC_TX_PACKET_COUNT,     \
                              CONFIG_BT_CTLR_SDC_RX_PACKET_COUNT) +   \
     SDC_MEM_CENTRAL_LINKS_SHARED)

#define PERIPHERAL_MEM_SIZE                                              \
    (SDC_MEM_PER_PERIPHERAL_LINK(MAX_TX_PACKET_SIZE, MAX_RX_PACKET_SIZE, \
                                 CONFIG_BT_CTLR_SDC_TX_PACKET_COUNT,     \
                                 CONFIG_BT_CTLR_SDC_RX_PACKET_COUNT) +   \
     SDC_MEM_PERIPHERAL_LINKS_SHARED)

#define PERIPHERAL_COUNT CONFIG_BT_CTLR_SDC_PERIPHERAL_COUNT

#define SDC_FAL_MEM_SIZE SDC_MEM_FAL(CONFIG_BT_CTLR_FAL_SIZE)

#define SDC_EXTRA_MEMORY CONFIG_BT_SDC_ADDITIONAL_MEMORY

#define MEMPOOL_SIZE                                                                          \
    ((PERIPHERAL_COUNT * PERIPHERAL_MEM_SIZE) + (SDC_CENTRAL_COUNT * CENTRAL_MEM_SIZE) +      \
     (SDC_ADV_SET_MEM_SIZE) + (SDC_PERIODIC_ADV_MEM_SIZE) + (SDC_PERIODIC_ADV_RSP_MEM_SIZE) + \
     (SDC_PERIODIC_SYNC_MEM_SIZE) + (SDC_PERIODIC_ADV_LIST_MEM_SIZE) + (SDC_SCAN_BUF_SIZE) +  \
     (SDC_FAL_MEM_SIZE) + (SDC_EXTRA_MEMORY))

static __aligned(8) uint8_t sdc_mempool[2000];

void sdc_assertion_handler(const char *file, const uint32_t line)
{
    // NRFX_LOG("SoftDevice Controller fault: file=%s, line=%lu\n", file, line);
    // for (;;)
    // {
    // }
}

static int cmd_handle(struct net_buf cmd)
{
    int errcode = hci_internal_cmd_put(cmd.data);
    if (errcode)
    {
        return errcode;
    }

    hci_driver_receive_process();

    return 0;
}

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

static void data_packet_process(uint8_t *hci_buf)
{
    // struct net_buf *data_buf = bt_buf_get_rx(BT_BUF_ACL_IN, K_FOREVER);
    struct bt_hci_acl_hdr *hdr = (void *)hci_buf;
    uint16_t hf, handle, len;
    uint8_t flags, pb, bc;
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

static void event_packet_process(uint8_t *hci_buf)
{
    struct bt_hci_evt_hdr *hdr = (void *)hci_buf;
    if (hdr->evt == BT_HCI_EVT_LE_META_EVENT)
    {
        struct bt_hci_evt_le_meta_event *me = (void *)&hci_buf[2];

        NRFX_LOG("LE Meta Event (0x%02x), len (%u)", me->subevent, hdr->len);
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
        struct bt_hci_evt_cmd_status *cs = (void *)&hci_buf[2];
        // uint16_t opcode = sys_le16_to_cpu(cs->opcode);

        NRFX_LOG("Command Status ");
    }
    else
    {
        NRFX_LOG("Event (0x%02x) len %u", hdr->evt, hdr->len);
    }
    //  TODO call receive with ble event
    // evt_buf = bt_buf_get_evt(hdr->evt, discardable, discardable ? K_NO_WAIT : K_FOREVER);

    // if (!evt_buf)
    // {
    //     if (discardable)
    //     {
    //         NRFX_LOG("Discarding event");
    //         return;
    //     }

    //     NRFX_LOG("No event buffer available");
    //     return;
    // }

    // net_buf_add_mem(evt_buf, &hci_buf[0], hdr->len + sizeof(*hdr));
    // bt_recv(evt_buf);
}

static bool fetch_and_process_hci_msg(uint8_t *p_hci_buffer)
{
    int errcode;
    sdc_hci_msg_type_t msg_type;
    errcode = hci_internal_msg_get(p_hci_buffer, &msg_type);
    if (errcode)
    {
        return false;
    }

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
        // k_panic();
        /* No return from k_panic(). */
        return -NRF_ENOMEM;
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
    checkError(mpsl_init(&mpsl_clock_config, MPSL_SWI, mpsl_assert_handler));
    NRFX_IRQ_PRIORITY_SET(MPSL_SWI, 4);
    NRFX_IRQ_ENABLE(MPSL_SWI);
}
void advertise()
{
}
int32_t ble_init(void)
{

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
