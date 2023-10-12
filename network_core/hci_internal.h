/*
 * Copyright (c) 2020 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */

/** @file
 *  @brief Internal HCI interface
 */
#pragma once
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
void bt_hci_receive(uint8_t *buff);
/**
 * Initialize softdevice controller with MPSL and do a reset
 */
int32_t ble_init(void);
/**
 * Start ble advertise
 */
void ble_advertise(void);
