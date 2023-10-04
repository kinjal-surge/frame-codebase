/*
 * Copyright (c) 2020 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

/** @file
 *  @brief Internal HCI interface
 */

#include <sdc_hci.h>
#include <sdc_hci_cmd_controller_baseband.h>
#include <sdc_hci_cmd_info_params.h>
#include <sdc_hci_cmd_le.h>
#include <sdc_hci_cmd_link_control.h>
#include <sdc_hci_cmd_status_params.h>
#include <sdc_hci_vs.h>
#include "nrf.h"
#include "nrfx_log.h"
#include <stdint.h>
#include <stdbool.h>
#include "nrf_errno.h"
#define BIT(n) (1UL << (n))
#define BIT_MASK(n) (BIT(n) - 1UL)
#define BT_ADDR_SIZE 6
#define BT_HCI_CMD_HDR_SIZE 3
#define BT_HCI_EVT_HDR_SIZE 2
#define BT_HCI_EVT_CMD_COMPLETE 0x0e
#define BT_HCI_EVT_CMD_STATUS 0x0f
#define BT_HCI_ERR_UNKNOWN_CMD 0x01
#define BT_HCI_ERR_CMD_DISALLOWED 0x0c
#define BT_HCI_EVT_LE_META_EVENT 0x3e
#define BT_HCI_EVT_VENDOR 0xff

#define BT_HCI_EVT_INQUIRY_COMPLETE 0x01
#define BT_HCI_EVT_LE_ADVERTISING_REPORT 0x02
/* HCI BR/EDR link types */
#define BT_HCI_SCO 0x00
#define BT_HCI_ACL 0x01
#define BT_HCI_ESCO 0x02

/* OpCode Group Fields */
#define BT_OGF_LINK_CTRL 0x01
#define BT_OGF_BASEBAND 0x03
#define BT_OGF_INFO 0x04
#define BT_OGF_STATUS 0x05
#define BT_OGF_LE 0x08
#define BT_OGF_VS 0x3f

/* Construct OpCode from OGF and OCF */
#define BT_OP(ogf, ocf) ((ocf) | ((ogf) << 10))

/* Invalid opcode */
#define BT_OP_NOP 0x0000

/* Obtain OGF from OpCode */
#define BT_OGF(opcode) (((opcode) >> 10) & BIT_MASK(6))
/* Obtain OCF from OpCode */
#define BT_OCF(opcode) ((opcode)&BIT_MASK(10))
// #define __net_buf_align __aligned(sizeof(void *))
static inline uint16_t sys_get_le16(const uint8_t src[2])
{
    return ((uint16_t)src[1] << 8) | src[0];
}
struct bt_buf_data
{
    uint8_t type;
};
struct net_buf_simple
{
    /** Pointer to the start of data in the buffer. */
    uint8_t *data;

    /**
     * Length of the data behind the data pointer.
     *
     * To determine the max length, use net_buf_simple_max_len(), not #size!
     */
    uint16_t len;

    /** Amount of data that net_buf_simple#__buf can store. */
    uint16_t size;

    /** Start of the data storage. Not to be accessed directly
     *  (the data pointer should be used instead).
     */
    uint8_t *__buf;
};
struct net_buf
{
    /** Fragments associated with this buffer. */
    struct net_buf *frags;

    /** Reference count. */
    uint8_t ref;

    /** Bit-field of buffer flags. */
    uint8_t flags;

    /** Where the buffer should go when freed up. */
    uint8_t pool_id;

    /* Size of user data on this buffer */
    uint8_t user_data_size;

    /* Union for convenience access to the net_buf_simple members, also
     * preserving the old API.
     */
    union
    {
        /* The ABI of this struct must match net_buf_simple */
        struct
        {
            /** Pointer to the start of data in the buffer. */
            uint8_t *data;

            /** Length of the data behind the data pointer. */
            uint16_t len;

            /** Amount of data that this buffer can store. */
            uint16_t size;

            /** Start of the data storage. Not to be accessed
             *  directly (the data pointer should be used
             *  instead).
             */
            uint8_t *__buf;
        };
        struct net_buf_simple b;
    };
    /** System metadata for this buffer. */
};
struct bt_hci_evt_hdr
{
    uint8_t evt;
    uint8_t len;
};

struct bt_hci_evt_cmd_status
{
    uint8_t status;
    uint8_t ncmd;
    uint16_t opcode;
};

struct bt_hci_evt_cmd_complete
{
    uint8_t ncmd;
    uint16_t opcode;
};

struct bt_hci_evt_cc_status
{
    uint8_t status;
};

struct bt_hci_cmd_hdr
{
    uint16_t opcode;
    uint8_t param_len;
};

struct bt_hci_evt_le_meta_event
{
    uint8_t subevent;
};
struct bt_hci_evt_inquiry_complete
{
    uint8_t status;
};
/** Bluetooth LE Device Address */
typedef struct
{
    uint8_t val[BT_ADDR_SIZE];
} bt_addr_t;
typedef struct
{
    uint8_t type;
    bt_addr_t a;
} bt_addr_le_t;

struct bt_hci_evt_le_advertising_info
{
    uint8_t evt_type;
    bt_addr_le_t addr;
    uint8_t length;
    uint8_t data[0];
};
/** Possible types of buffers passed around the Bluetooth stack */
enum bt_buf_type
{
    /** HCI command */
    BT_BUF_CMD,
    /** HCI event */
    BT_BUF_EVT,
    /** Outgoing ACL data */
    BT_BUF_ACL_OUT,
    /** Incoming ACL data */
    BT_BUF_ACL_IN,
    /** Outgoing ISO data */
    BT_BUF_ISO_OUT,
    /** Incoming ISO data */
    BT_BUF_ISO_IN,
    /** H:4 data */
    BT_BUF_H4,
};
/** @brief Send an HCI command packet to the SoftDevice Controller.
 *
 * If the application has provided a user handler, this handler get precedence
 * above the default HCI command handlers. See @ref hci_internal_user_cmd_handler_register.
 *
 * @param[in] cmd_in  HCI Command packet. The first byte in the buffer should correspond to
 *                    OpCode, as specified by the Bluetooth Core Specification.
 *
 * @return Zero on success or (negative) error code otherwise.
 */
int hci_internal_cmd_put(uint8_t *cmd_in);

/** A user implementable HCI command handler
 *
 * What is done in the command handler is up to the user.
 * Parameters can be returned to the host through the raw_event_out output parameter.
 *
 * When the command handler returns, a Command Complete or Command Status event is generated.
 *
 * @param[in]  cmd               The HCI command itself. The first byte in the buffer corresponds
 *                               to OpCode, as specified by the Bluetooth Core Specification.
 * @param[out] raw_event_out     Parameters to be returned from the event as return parameters in
 *                               the Command Complete event.
 *                               Parameters can only be returned if the generated event is
 *                               a Command Complete event.
 * @param[out] param_length_out  Length of parameters to be returned.
 * @param[out] gives_cmd_status  Set to true if the command is returning a Command Status event.
 *
 * @return Bluetooth status code. BT_HCI_ERR_UNKNOWN_CMD if unknown.
 */
typedef uint8_t (*hci_internal_user_cmd_handler_t)(uint8_t const *cmd,
                                                   uint8_t *raw_event_out,
                                                   uint8_t *param_length_out,
                                                   bool *gives_cmd_status);

/** @brief Register a user handler for HCI commands.
 *
 * The user handler can be used to handle custom HCI commands.
 *
 * The user handler will have precedence over all other command handling.
 * Therefore, the application needs to ensure it is not using opcodes that
 * are used for other Bluetooth or vendor specific HCI commands.
 * See sdc_hci_vs.h for the opcodes that are reserved.
 *
 * @note Only one handler can be registered.
 *
 * @param[in] handler
 * @return Zero on success or (negative) error code otherwise
 */
int hci_internal_user_cmd_handler_register(const hci_internal_user_cmd_handler_t handler);

/** @brief Retrieve an HCI packet from the SoftDevice Controller.
 *
 * This API is non-blocking.
 *
 * @note The application should ensure that the size of the provided buffer is at least
 *       @ref HCI_EVENT_PACKET_MAX_SIZE bytes.
 *
 * @param[in,out] msg_out Buffer where the HCI packet will be stored.
 *                        If an event is retrieved, the first byte corresponds to Event Code,
 *                        as specified by the Bluetooth Core Specification.
 * @param[out] msg_type_out Indicates the type of hci message received.
 *
 * @return Zero on success or (negative) error code otherwise.
 */
int hci_internal_msg_get(uint8_t *msg_out, sdc_hci_msg_type_t *msg_type_out);
void hci_driver_receive_process(void);

/**
 * Initialize softdevice controller with MPSL and do a reset
 */
int32_t ble_init(void);
/**
 * Start ble advertise
 */
void ble_advertise(void);
