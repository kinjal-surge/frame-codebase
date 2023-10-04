/*
 * Copyright (c) 2020 Nordic Semiconductor ASA
 *
 * SPDX-License-Identifier: LicenseRef-Nordic-5-Clause
 */
#include "hci_internal.h"
#include <string.h>
#define CMD_COMPLETE_MIN_SIZE (BT_HCI_EVT_HDR_SIZE + sizeof(struct bt_hci_evt_cmd_complete) + sizeof(struct bt_hci_evt_cc_status))

static struct
{
    bool occurred; /**< Set in only one execution context */
    uint8_t raw_event[68];
} cmd_complete_or_status;

static hci_internal_user_cmd_handler_t user_cmd_handler;

static bool command_generates_command_complete_event(uint16_t hci_opcode)
{
    switch (hci_opcode)
    {
    case SDC_HCI_OPCODE_CMD_LC_DISCONNECT:
    case SDC_HCI_OPCODE_CMD_LE_SET_PHY:
    case SDC_HCI_OPCODE_CMD_LC_READ_REMOTE_VERSION_INFORMATION:
    case SDC_HCI_OPCODE_CMD_LE_CREATE_CONN:
    case SDC_HCI_OPCODE_CMD_LE_CONN_UPDATE:
    case SDC_HCI_OPCODE_CMD_LE_READ_REMOTE_FEATURES:
    case SDC_HCI_OPCODE_CMD_LE_ENABLE_ENCRYPTION:
    case SDC_HCI_OPCODE_CMD_LE_EXT_CREATE_CONN:
    case SDC_HCI_OPCODE_CMD_LE_EXT_CREATE_CONN_V2:
    case SDC_HCI_OPCODE_CMD_LE_PERIODIC_ADV_CREATE_SYNC:
    case SDC_HCI_OPCODE_CMD_LE_REQUEST_PEER_SCA:
    case SDC_HCI_OPCODE_CMD_LE_READ_REMOTE_TRANSMIT_POWER_LEVEL:
    case SDC_HCI_OPCODE_CMD_VS_CONN_UPDATE:
    case SDC_HCI_OPCODE_CMD_VS_WRITE_REMOTE_TX_POWER:
        // case BT_HCI_OP_LE_P256_PUBLIC_KEY:
        // case BT_HCI_OP_LE_GENERATE_DHKEY:
        return false;
    default:
        return true;
    }
}

/* Return true if the host has been using both legacy and extended HCI commands
 * since last HCI reset.
 */
// static bool is_host_using_legacy_and_extended_commands(uint16_t hci_opcode)
// {
// #if defined(CONFIG_BT_HCI_HOST)
//     /* For a combined host and controller build, we know that the zephyr
//      * host is used. For this case we know that the host is not
//      * combining legacy and extended commands. Therefore we can
//      * simplify this validation. */
//     return false;
// #else
//     /* A host is not allowed to use both legacy and extended HCI commands.
//      * See Core v5.1, Vol2, Part E, 3.1.1 Legacy and extended advertising
//      */
//     static enum {
//         ADV_COMMAND_TYPE_NONE,
//         ADV_COMMAND_TYPE_LEGACY,
//         ADV_COMMAND_TYPE_EXTENDED,
//     } type_of_adv_cmd_used_since_reset;

//     switch (hci_opcode)
//     {
// #if defined(CONFIG_BT_BROADCASTER)
//     case SDC_HCI_OPCODE_CMD_LE_SET_EXT_ADV_PARAMS:
//     case SDC_HCI_OPCODE_CMD_LE_SET_EXT_ADV_DATA:
//     case SDC_HCI_OPCODE_CMD_LE_SET_EXT_SCAN_RESPONSE_DATA:
//     case SDC_HCI_OPCODE_CMD_LE_SET_EXT_ADV_ENABLE:
//     case SDC_HCI_OPCODE_CMD_LE_READ_MAX_ADV_DATA_LENGTH:
//     case SDC_HCI_OPCODE_CMD_LE_READ_NUMBER_OF_SUPPORTED_ADV_SETS:
//     case SDC_HCI_OPCODE_CMD_LE_REMOVE_ADV_SET:
//     case SDC_HCI_OPCODE_CMD_LE_CLEAR_ADV_SETS:
// #if defined(CONFIG_BT_PER_ADV)
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_PARAMS:
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_DATA:
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_ENABLE:
// #endif /* CONFIG_BT_PER_ADV */
// #if defined(CONFIG_BT_CTLR_SDC_PAWR_ADV)
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_PARAMS_V2:
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_SUBEVENT_DATA:
// #endif /* CONFIG_BT_CTLR_SDC_PAWR_ADV */
// #endif /* CONFIG_BT_BROADCASTER */
// #if defined(CONFIG_BT_OBSERVER)
//     case SDC_HCI_OPCODE_CMD_LE_SET_EXT_SCAN_PARAMS:
//     case SDC_HCI_OPCODE_CMD_LE_SET_EXT_SCAN_ENABLE:
// #endif /* CONFIG_BT_OBSERVER */
// #if defined(CONFIG_BT_CENTRAL)
//     case SDC_HCI_OPCODE_CMD_LE_EXT_CREATE_CONN:
// #if defined(CONFIG_BT_CTLR_SDC_PAWR_ADV)
//     case SDC_HCI_OPCODE_CMD_LE_EXT_CREATE_CONN_V2:
// #endif /* CONFIG_BT_CTLR_SDC_PAWR_ADV */
// #endif /* CONFIG_BT_CENTRAL */
// #if defined(CONFIG_BT_PER_ADV_SYNC)
//     case SDC_HCI_OPCODE_CMD_LE_PERIODIC_ADV_CREATE_SYNC:
//     case SDC_HCI_OPCODE_CMD_LE_PERIODIC_ADV_CREATE_SYNC_CANCEL:
//     case SDC_HCI_OPCODE_CMD_LE_PERIODIC_ADV_TERMINATE_SYNC:
//     case SDC_HCI_OPCODE_CMD_LE_ADD_DEVICE_TO_PERIODIC_ADV_LIST:
//     case SDC_HCI_OPCODE_CMD_LE_REMOVE_DEVICE_FROM_PERIODIC_ADV_LIST:
//     case SDC_HCI_OPCODE_CMD_LE_CLEAR_PERIODIC_ADV_LIST:
//     case SDC_HCI_OPCODE_CMD_LE_READ_PERIODIC_ADV_LIST_SIZE:
// #endif
// #if defined(CONFIG_BT_CTLR_SDC_PAWR_SYNC)
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_SYNC_SUBEVENT:
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_RESPONSE_DATA:
// #endif
// #if defined(CONFIG_BT_PER_ADV_SYNC_TRANSFER_RECEIVER)
//     case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_SYNC_TRANSFER_PARAMS:
//     case SDC_HCI_OPCODE_CMD_LE_SET_DEFAULT_PERIODIC_ADV_SYNC_TRANSFER_PARAMS:
// #endif /* CONFIG_BT_PER_ADV_SYNC_TRANSFER_RECEIVER */
//         if (type_of_adv_cmd_used_since_reset == ADV_COMMAND_TYPE_NONE)
//         {
//             type_of_adv_cmd_used_since_reset = ADV_COMMAND_TYPE_EXTENDED;
//             return false;
//         }
//         return type_of_adv_cmd_used_since_reset == ADV_COMMAND_TYPE_LEGACY;

// #if defined(CONFIG_BT_OBSERVER)
//     case SDC_HCI_OPCODE_CMD_LE_SET_ADV_PARAMS:
//     case SDC_HCI_OPCODE_CMD_LE_READ_ADV_PHYSICAL_CHANNEL_TX_POWER:
//     case SDC_HCI_OPCODE_CMD_LE_SET_ADV_DATA:
//     case SDC_HCI_OPCODE_CMD_LE_SET_SCAN_RESPONSE_DATA:
//     case SDC_HCI_OPCODE_CMD_LE_SET_ADV_ENABLE:
// #endif /* CONFIG_BT_OBSERVER */
// #if defined(CONFIG_BT_OBSERVER)
//     case SDC_HCI_OPCODE_CMD_LE_SET_SCAN_PARAMS:
//     case SDC_HCI_OPCODE_CMD_LE_SET_SCAN_ENABLE:
// #endif /* CONFIG_BT_OBSERVER */
// #if defined(CONFIG_BT_CENTRAL)
//     case SDC_HCI_OPCODE_CMD_LE_CREATE_CONN:
// #endif /* CONFIG_BT_CENTRAL */
//         if (type_of_adv_cmd_used_since_reset == ADV_COMMAND_TYPE_NONE)
//         {
//             type_of_adv_cmd_used_since_reset = ADV_COMMAND_TYPE_LEGACY;
//             return false;
//         }
//         return type_of_adv_cmd_used_since_reset == ADV_COMMAND_TYPE_EXTENDED;
//     case SDC_HCI_OPCODE_CMD_CB_RESET:
//         type_of_adv_cmd_used_since_reset = ADV_COMMAND_TYPE_NONE;
//         break;
//     default:
//         /* Ignore command */
//         break;
//     }

//     return false;
// #endif /* CONFIG_BT_HCI */
// }

static void encode_command_status(uint8_t *const event,
                                  uint16_t hci_opcode,
                                  uint8_t status_code)
{

    struct bt_hci_evt_hdr *evt_hdr = (struct bt_hci_evt_hdr *)event;
    struct bt_hci_evt_cmd_status *evt_data =
        (struct bt_hci_evt_cmd_status *)&event[BT_HCI_EVT_HDR_SIZE];

    evt_hdr->evt = BT_HCI_EVT_CMD_STATUS;
    evt_hdr->len = sizeof(struct bt_hci_evt_cmd_status);

    evt_data->status = status_code;
    evt_data->ncmd = 1;
    evt_data->opcode = hci_opcode;
}

static void encode_command_complete_header(uint8_t *const event,
                                           uint16_t hci_opcode,
                                           uint8_t param_length,
                                           uint8_t status)
{
    struct bt_hci_evt_hdr *evt_hdr = (struct bt_hci_evt_hdr *)event;
    struct bt_hci_evt_cmd_complete *evt_data =
        (struct bt_hci_evt_cmd_complete *)&event[BT_HCI_EVT_HDR_SIZE];

    evt_hdr->evt = BT_HCI_EVT_CMD_COMPLETE;
    evt_hdr->len = param_length;
    evt_data->ncmd = 1;
    evt_data->opcode = hci_opcode;
    event[BT_HCI_EVT_HDR_SIZE + sizeof(struct bt_hci_evt_cmd_complete)] = status;
}

int hci_internal_user_cmd_handler_register(const hci_internal_user_cmd_handler_t handler)
{
    if (user_cmd_handler)
    {
        return -NRF_EAGAIN;
    }

    user_cmd_handler = handler;
    return 0;
}

static uint8_t controller_and_baseband_cmd_put(uint8_t const *const cmd,
                                               uint8_t *const raw_event_out,
                                               uint8_t *param_length_out)
{
    uint8_t const *cmd_params = &cmd[BT_HCI_CMD_HDR_SIZE];
    uint16_t opcode = sys_get_le16(cmd);
    uint8_t *const event_out_params = &raw_event_out[CMD_COMPLETE_MIN_SIZE];
    switch (opcode)
    {
    case SDC_HCI_OPCODE_CMD_CB_SET_EVENT_MASK:
        return sdc_hci_cmd_cb_set_event_mask((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_CB_RESET:
        return sdc_hci_cmd_cb_reset();

    case SDC_HCI_OPCODE_CMD_CB_READ_TRANSMIT_POWER_LEVEL:
        *param_length_out += sizeof(sdc_hci_cmd_cb_read_transmit_power_level_return_t);
        return sdc_hci_cmd_cb_read_transmit_power_level((void *)cmd_params,
                                                        (void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_CB_SET_CONTROLLER_TO_HOST_FLOW_CONTROL:
        return sdc_hci_cmd_cb_set_controller_to_host_flow_control((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_CB_HOST_BUFFER_SIZE:
        return sdc_hci_cmd_cb_host_buffer_size((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_CB_HOST_NUMBER_OF_COMPLETED_PACKETS:
        return sdc_hci_cmd_cb_host_number_of_completed_packets((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_CB_SET_EVENT_MASK_PAGE_2:
        return sdc_hci_cmd_cb_set_event_mask_page_2((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_CB_READ_AUTHENTICATED_PAYLOAD_TIMEOUT:
        *param_length_out +=
            sizeof(sdc_hci_cmd_cb_read_authenticated_payload_timeout_return_t);
        return sdc_hci_cmd_cb_read_authenticated_payload_timeout((void *)cmd_params,
                                                                 (void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_CB_WRITE_AUTHENTICATED_PAYLOAD_TIMEOUT:
        *param_length_out +=
            sizeof(sdc_hci_cmd_cb_write_authenticated_payload_timeout_return_t);
        return sdc_hci_cmd_cb_write_authenticated_payload_timeout((void *)cmd_params,
                                                                  (void *)event_out_params);
    default:
        return BT_HCI_ERR_UNKNOWN_CMD;
    }
}

static uint8_t info_param_cmd_put(uint8_t const *const cmd,
                                  uint8_t *const raw_event_out,
                                  uint8_t *param_length_out)
{
    uint8_t *const event_out_params = &raw_event_out[CMD_COMPLETE_MIN_SIZE];
    uint16_t opcode = sys_get_le16(cmd);

    switch (opcode)
    {
    case SDC_HCI_OPCODE_CMD_IP_READ_LOCAL_VERSION_INFORMATION:
        *param_length_out += sizeof(sdc_hci_cmd_ip_read_local_version_information_return_t);
        return sdc_hci_cmd_ip_read_local_version_information((void *)event_out_params);
        return 0;
    case SDC_HCI_OPCODE_CMD_IP_READ_BD_ADDR:
        *param_length_out += sizeof(sdc_hci_cmd_ip_read_bd_addr_return_t);
        return sdc_hci_cmd_ip_read_bd_addr((void *)event_out_params);
    default:
        return BT_HCI_ERR_UNKNOWN_CMD;
    }
}

static uint8_t status_param_cmd_put(uint8_t const *const cmd,
                                    uint8_t *const raw_event_out,
                                    uint8_t *param_length_out)
{
    uint8_t const *cmd_params = &cmd[BT_HCI_CMD_HDR_SIZE];
    uint8_t *const event_out_params = &raw_event_out[CMD_COMPLETE_MIN_SIZE];
    uint16_t opcode = sys_get_le16(cmd);

    switch (opcode)
    {
    case SDC_HCI_OPCODE_CMD_SP_READ_RSSI:
        *param_length_out += sizeof(sdc_hci_cmd_sp_read_rssi_return_t);
        return sdc_hci_cmd_sp_read_rssi((void *)cmd_params,
                                        (void *)event_out_params);
    default:
        return BT_HCI_ERR_UNKNOWN_CMD;
    }
}

static uint8_t le_controller_cmd_put(uint8_t const *const cmd,
                                     uint8_t *const raw_event_out,
                                     uint8_t *param_length_out)
{
    uint8_t const *cmd_params = &cmd[BT_HCI_CMD_HDR_SIZE];
    uint8_t *const event_out_params = &raw_event_out[CMD_COMPLETE_MIN_SIZE];
    uint16_t opcode = sys_get_le16(cmd);

    switch (opcode)
    {
    case SDC_HCI_OPCODE_CMD_LE_SET_EVENT_MASK:
        return sdc_hci_cmd_le_set_event_mask((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_BUFFER_SIZE:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_buffer_size_return_t);
        return sdc_hci_cmd_le_read_buffer_size((void *)event_out_params);

        // case SDC_HCI_OPCODE_CMD_LE_READ_LOCAL_SUPPORTED_FEATURES:
        //     *param_length_out += sizeof(sdc_hci_cmd_le_read_local_supported_features_return_t);
        //     le_supported_features((void *)event_out_params);
        //     return 0;

    case SDC_HCI_OPCODE_CMD_LE_SET_RANDOM_ADDRESS:
        return sdc_hci_cmd_le_set_random_address((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_SET_ADV_PARAMS:
        return sdc_hci_cmd_le_set_adv_params((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_ADV_PHYSICAL_CHANNEL_TX_POWER:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_read_adv_physical_channel_tx_power_return_t);
        return sdc_hci_cmd_le_read_adv_physical_channel_tx_power((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_ADV_DATA:
        return sdc_hci_cmd_le_set_adv_data((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_SCAN_RESPONSE_DATA:
        return sdc_hci_cmd_le_set_scan_response_data((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_ADV_ENABLE:
        return sdc_hci_cmd_le_set_adv_enable((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_DATA_RELATED_ADDRESS_CHANGES:
        return sdc_hci_cmd_le_set_data_related_address_changes((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_READ_FILTER_ACCEPT_LIST_SIZE:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_filter_accept_list_size_return_t);
        return sdc_hci_cmd_le_read_filter_accept_list_size((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_CLEAR_FILTER_ACCEPT_LIST:
        return sdc_hci_cmd_le_clear_filter_accept_list();

    case SDC_HCI_OPCODE_CMD_LE_ADD_DEVICE_TO_FILTER_ACCEPT_LIST:
        return sdc_hci_cmd_le_add_device_to_filter_accept_list((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_REMOVE_DEVICE_FROM_FILTER_ACCEPT_LIST:
        return sdc_hci_cmd_le_remove_device_from_filter_accept_list((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_CHANNEL_MAP:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_channel_map_return_t);
        return sdc_hci_cmd_le_read_channel_map((void *)cmd_params,
                                               (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_REMOTE_FEATURES:
        return sdc_hci_cmd_le_read_remote_features((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_ENCRYPT:
        *param_length_out += sizeof(sdc_hci_cmd_le_encrypt_return_t);
        return sdc_hci_cmd_le_encrypt((void *)cmd_params, (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_RAND:
        *param_length_out += sizeof(sdc_hci_cmd_le_rand_return_t);
        return sdc_hci_cmd_le_rand((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_LONG_TERM_KEY_REQUEST_REPLY:
        *param_length_out += sizeof(sdc_hci_cmd_le_long_term_key_request_reply_return_t);
        return sdc_hci_cmd_le_long_term_key_request_reply((void *)cmd_params,
                                                          (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_LONG_TERM_KEY_REQUEST_NEGATIVE_REPLY:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_long_term_key_request_negative_reply_return_t);
        return sdc_hci_cmd_le_long_term_key_request_negative_reply(
            (void *)cmd_params,
            (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_DATA_LENGTH:
        *param_length_out += sizeof(sdc_hci_cmd_le_set_data_length_return_t);
        return sdc_hci_cmd_le_set_data_length((void *)cmd_params, (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_SUGGESTED_DEFAULT_DATA_LENGTH:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_read_suggested_default_data_length_return_t);
        return sdc_hci_cmd_le_read_suggested_default_data_length((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_WRITE_SUGGESTED_DEFAULT_DATA_LENGTH:
        return sdc_hci_cmd_le_write_suggested_default_data_length((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_ADD_DEVICE_TO_RESOLVING_LIST:
        return sdc_hci_cmd_le_add_device_to_resolving_list((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_REMOVE_DEVICE_FROM_RESOLVING_LIST:
        return sdc_hci_cmd_le_remove_device_from_resolving_list((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_CLEAR_RESOLVING_LIST:
        return sdc_hci_cmd_le_clear_resolving_list();

    case SDC_HCI_OPCODE_CMD_LE_READ_RESOLVING_LIST_SIZE:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_resolving_list_size_return_t);
        return sdc_hci_cmd_le_read_resolving_list_size((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_ADDRESS_RESOLUTION_ENABLE:
        return sdc_hci_cmd_le_set_address_resolution_enable((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_RESOLVABLE_PRIVATE_ADDRESS_TIMEOUT:
        return sdc_hci_cmd_le_set_resolvable_private_address_timeout((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_READ_MAX_DATA_LENGTH:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_max_data_length_return_t);
        return sdc_hci_cmd_le_read_max_data_length((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_LE_READ_PHY:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_phy_return_t);
        return sdc_hci_cmd_le_read_phy((void *)cmd_params, (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_DEFAULT_PHY:
        return sdc_hci_cmd_le_set_default_phy((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_PHY:
        return sdc_hci_cmd_le_set_phy((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_SET_ADV_SET_RANDOM_ADDRESS:
        return sdc_hci_cmd_le_set_adv_set_random_address((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_EXT_ADV_PARAMS:
        *param_length_out += sizeof(sdc_hci_cmd_le_set_ext_adv_params_return_t);
        return sdc_hci_cmd_le_set_ext_adv_params((void *)cmd_params,
                                                 (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_EXT_ADV_DATA:
        return sdc_hci_cmd_le_set_ext_adv_data((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_EXT_SCAN_RESPONSE_DATA:
        return sdc_hci_cmd_le_set_ext_scan_response_data((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_EXT_ADV_ENABLE:
        return sdc_hci_cmd_le_set_ext_adv_enable((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_MAX_ADV_DATA_LENGTH:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_max_adv_data_length_return_t);
        return sdc_hci_cmd_le_read_max_adv_data_length((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_NUMBER_OF_SUPPORTED_ADV_SETS:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_read_number_of_supported_adv_sets_return_t);
        return sdc_hci_cmd_le_read_number_of_supported_adv_sets((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_REMOVE_ADV_SET:
        return sdc_hci_cmd_le_remove_adv_set((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_CLEAR_ADV_SETS:
        return sdc_hci_cmd_le_clear_adv_sets();

    case SDC_HCI_OPCODE_CMD_LE_READ_TRANSMIT_POWER:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_transmit_power_return_t);
        return sdc_hci_cmd_le_read_transmit_power((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_LE_SET_PRIVACY_MODE:
        return sdc_hci_cmd_le_set_privacy_mode((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_RECEIVE_ENABLE:
        return sdc_hci_cmd_le_set_periodic_adv_receive_enable((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_SET_CONNLESS_CTE_TRANSMIT_PARAMS:
        return sdc_hci_cmd_le_set_connless_cte_transmit_params((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_CONNLESS_CTE_TRANSMIT_ENABLE:
        return sdc_hci_cmd_le_set_connless_cte_transmit_enable((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LE_SET_CONN_CTE_TRANSMIT_PARAMS:
        *param_length_out += sizeof(sdc_hci_cmd_le_set_conn_cte_transmit_params_return_t);
        return sdc_hci_cmd_le_set_conn_cte_transmit_params((void *)cmd_params,
                                                           (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_CONN_CTE_RESPONSE_ENABLE:
        *param_length_out += sizeof(sdc_hci_cmd_le_conn_cte_response_enable_return_t);
        return sdc_hci_cmd_le_conn_cte_response_enable((void *)cmd_params,
                                                       (void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_LE_READ_ANTENNA_INFORMATION:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_antenna_information_return_t);
        return sdc_hci_cmd_le_read_antenna_information((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_LE_ENHANCED_READ_TRANSMIT_POWER_LEVEL:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_enhanced_read_transmit_power_level_return_t);
        return sdc_hci_cmd_le_enhanced_read_transmit_power_level((void *)cmd_params,
                                                                 (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_REMOTE_TRANSMIT_POWER_LEVEL:
        return sdc_hci_cmd_le_read_remote_transmit_power_level((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_TRANSMIT_POWER_REPORTING_ENABLE:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_set_transmit_power_reporting_enable_return_t);
        return sdc_hci_cmd_le_set_transmit_power_reporting_enable((void *)cmd_params,
                                                                  (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_READ_RF_PATH_COMPENSATION:
        *param_length_out += sizeof(sdc_hci_cmd_le_read_rf_path_compensation_return_t);
        return sdc_hci_cmd_le_read_rf_path_compensation((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_WRITE_RF_PATH_COMPENSATION:
        return sdc_hci_cmd_le_write_rf_path_compensation((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_PERIODIC_ADV_SYNC_TRANSFER:
        *param_length_out += sizeof(sdc_hci_cmd_le_periodic_adv_sync_transfer_return_t);
        return sdc_hci_cmd_le_periodic_adv_sync_transfer((void *)cmd_params,
                                                         (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_PERIODIC_ADV_SET_INFO_TRANSFER:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_periodic_adv_set_info_transfer_return_t);
        return sdc_hci_cmd_le_periodic_adv_set_info_transfer((void *)cmd_params,
                                                             (void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_LE_SET_PERIODIC_ADV_SYNC_TRANSFER_PARAMS:
        *param_length_out +=
            sizeof(sdc_hci_cmd_le_set_periodic_adv_sync_transfer_params_return_t);
        return sdc_hci_cmd_le_set_periodic_adv_sync_transfer_params(
            (void *)cmd_params, (void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_LE_SET_DEFAULT_PERIODIC_ADV_SYNC_TRANSFER_PARAMS:
        return sdc_hci_cmd_le_set_default_periodic_adv_sync_transfer_params(
            (void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_LE_REQUEST_PEER_SCA:
        return sdc_hci_cmd_le_request_peer_sca((void *)cmd_params);
    default:
        return BT_HCI_ERR_UNKNOWN_CMD;
    }
}

#if defined(CONFIG_BT_HCI_VS)
static uint8_t vs_cmd_put(uint8_t const *const cmd,
                          uint8_t *const raw_event_out,
                          uint8_t *param_length_out)
{
    uint8_t const *cmd_params = &cmd[BT_HCI_CMD_HDR_SIZE];
    uint8_t *const event_out_params = &raw_event_out[CMD_COMPLETE_MIN_SIZE];
    uint16_t opcode = sys_get_le16(cmd);

    switch (opcode)
    {
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_VERSION_INFO:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_version_info_return_t);
        return sdc_hci_cmd_vs_zephyr_read_version_info((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_SUPPORTED_COMMANDS:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_supported_commands_return_t);
        vs_zephyr_supported_commands((void *)event_out_params);
        return 0;

#if defined(CONFIG_BT_HCI_VS_EXT)
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_STATIC_ADDRESSES:
        /* We always return one entry */
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_static_addresses_return_t);
        *param_length_out += sizeof(sdc_hci_vs_zephyr_static_address_t);
        return sdc_hci_cmd_vs_zephyr_read_static_addresses((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_KEY_HIERARCHY_ROOTS:
        *param_length_out +=
            sizeof(sdc_hci_cmd_vs_zephyr_read_key_hierarchy_roots_return_t);
        return sdc_hci_cmd_vs_zephyr_read_key_hierarchy_roots((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_WRITE_BD_ADDR:
        return sdc_hci_cmd_vs_zephyr_write_bd_addr((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_CHIP_TEMP:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_chip_temp_return_t);
        return sdc_hci_cmd_vs_zephyr_read_chip_temp((void *)event_out_params);

#if defined(CONFIG_BT_CTLR_TX_PWR_DYNAMIC_CONTROL)
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_WRITE_TX_POWER:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_write_tx_power_return_t);
        return sdc_hci_cmd_vs_zephyr_write_tx_power((void *)cmd_params,
                                                    (void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_TX_POWER:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_tx_power_return_t);
        return sdc_hci_cmd_vs_zephyr_read_tx_power((void *)cmd_params,
                                                   (void *)event_out_params);
#endif /* CONFIG_BT_CTLR_TX_PWR_DYNAMIC_CONTROL */
#endif /* CONFIG_BT_HCI_VS_EXT */
    case SDC_HCI_OPCODE_CMD_VS_READ_SUPPORTED_VS_COMMANDS:
        *param_length_out += sizeof(sdc_hci_cmd_vs_read_supported_vs_commands_return_t);
        vs_supported_commands((void *)event_out_params);
        return 0;
    case SDC_HCI_OPCODE_CMD_VS_LLPM_MODE_SET:
        return sdc_hci_cmd_vs_llpm_mode_set((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_CONN_UPDATE:
        return sdc_hci_cmd_vs_conn_update((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_CONN_EVENT_EXTEND:
        return sdc_hci_cmd_vs_conn_event_extend((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_QOS_CONN_EVENT_REPORT_ENABLE:
        return sdc_hci_cmd_vs_qos_conn_event_report_enable((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_EVENT_LENGTH_SET:
        return sdc_hci_cmd_vs_event_length_set((void *)cmd_params);
#ifdef CONFIG_BT_PERIPHERAL
    case SDC_HCI_OPCODE_CMD_VS_PERIPHERAL_LATENCY_MODE_SET:
        return sdc_hci_cmd_vs_peripheral_latency_mode_set((void *)cmd_params);
#endif
#if defined(CONFIG_BT_BROADCASTER)
    case SDC_HCI_OPCODE_CMD_VS_SET_ADV_RANDOMNESS:
        return sdc_hci_cmd_vs_set_adv_randomness((void *)cmd_params);
#endif
#if defined(CONFIG_BT_CTLR_LE_POWER_CONTROL)
    case SDC_HCI_OPCODE_CMD_VS_WRITE_REMOTE_TX_POWER:
        return sdc_hci_cmd_vs_write_remote_tx_power((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_SET_AUTO_POWER_CONTROL_REQUEST_PARAM:
        return sdc_hci_cmd_vs_set_auto_power_control_request_param((void *)cmd_params);
#endif
    default:
        return BT_HCI_ERR_UNKNOWN_CMD;
    }
}
#endif /* CONFIG_BT_HCI_VS */
static uint8_t link_control_cmd_put(uint8_t const *const cmd)
{
    uint16_t opcode = sys_get_le16(cmd);
    uint8_t const *cmd_params = &cmd[BT_HCI_CMD_HDR_SIZE];

    switch (opcode)
    {
    case SDC_HCI_OPCODE_CMD_LC_DISCONNECT:
        return sdc_hci_cmd_lc_disconnect((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_LC_READ_REMOTE_VERSION_INFORMATION:
        return sdc_hci_cmd_lc_read_remote_version_information((void *)cmd_params);
    default:
        return BT_HCI_ERR_UNKNOWN_CMD;
    }
}
static uint8_t vs_cmd_put(uint8_t const *const cmd, uint8_t *const raw_event_out,
                          uint8_t *param_length_out)
{
    uint8_t const *cmd_params = &cmd[BT_HCI_CMD_HDR_SIZE];
    uint8_t *const event_out_params = &raw_event_out[CMD_COMPLETE_MIN_SIZE];
    uint16_t opcode = sys_get_le16(cmd);
    NRFX_LOG("vs_cmd_put final opcode (0x%04x) buffer:", opcode);
    // for (int i = 0; i < sizeof(cmd_params); i++) {
    // 	SEGGER_RTT_printf("%02x ", cmd_params[i]);
    // }
    switch (opcode)
    {
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_VERSION_INFO:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_version_info_return_t);
        return sdc_hci_cmd_vs_zephyr_read_version_info((void *)event_out_params);

    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_STATIC_ADDRESSES:
        /* We always return one entry */
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_static_addresses_return_t);
        *param_length_out += sizeof(sdc_hci_vs_zephyr_static_address_t);
        return sdc_hci_cmd_vs_zephyr_read_static_addresses((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_KEY_HIERARCHY_ROOTS:
        *param_length_out +=
            sizeof(sdc_hci_cmd_vs_zephyr_read_key_hierarchy_roots_return_t);
        return sdc_hci_cmd_vs_zephyr_read_key_hierarchy_roots((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_WRITE_BD_ADDR:
        return sdc_hci_cmd_vs_zephyr_write_bd_addr((void *)cmd_params);

    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_CHIP_TEMP:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_chip_temp_return_t);
        return sdc_hci_cmd_vs_zephyr_read_chip_temp((void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_WRITE_TX_POWER:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_write_tx_power_return_t);
        return sdc_hci_cmd_vs_zephyr_write_tx_power((void *)cmd_params,
                                                    (void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_ZEPHYR_READ_TX_POWER:
        *param_length_out += sizeof(sdc_hci_cmd_vs_zephyr_read_tx_power_return_t);
        return sdc_hci_cmd_vs_zephyr_read_tx_power((void *)cmd_params,
                                                   (void *)event_out_params);
    case SDC_HCI_OPCODE_CMD_VS_LLPM_MODE_SET:
        return sdc_hci_cmd_vs_llpm_mode_set((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_CONN_UPDATE:
        return sdc_hci_cmd_vs_conn_update((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_CONN_EVENT_EXTEND:
        return sdc_hci_cmd_vs_conn_event_extend((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_QOS_CONN_EVENT_REPORT_ENABLE:
        return sdc_hci_cmd_vs_qos_conn_event_report_enable((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_EVENT_LENGTH_SET:
        return sdc_hci_cmd_vs_event_length_set((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_PERIPHERAL_LATENCY_MODE_SET:
        return sdc_hci_cmd_vs_peripheral_latency_mode_set((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_SET_ADV_RANDOMNESS:
        return sdc_hci_cmd_vs_set_adv_randomness((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_WRITE_REMOTE_TX_POWER:
        return sdc_hci_cmd_vs_write_remote_tx_power((void *)cmd_params);
    case SDC_HCI_OPCODE_CMD_VS_SET_AUTO_POWER_CONTROL_REQUEST_PARAM:
        return sdc_hci_cmd_vs_set_auto_power_control_request_param((void *)cmd_params);
    default:
        return BT_HCI_ERR_UNKNOWN_CMD;
    }
}
static void cmd_put(uint8_t *cmd_in, uint8_t *const raw_event_out)
{
    uint8_t status = BT_HCI_ERR_UNKNOWN_CMD;
    uint16_t opcode = sys_get_le16(cmd_in);
    bool generate_command_status_event;

    /* Assume command complete */
    uint8_t return_param_length = sizeof(struct bt_hci_evt_cmd_complete) + sizeof(struct bt_hci_evt_cc_status);

    if (status == BT_HCI_ERR_UNKNOWN_CMD)
    {

        switch (BT_OGF(opcode))
        {
        case BT_OGF_LINK_CTRL:
            status = link_control_cmd_put(cmd_in);
            break;
        case BT_OGF_BASEBAND:
            status = controller_and_baseband_cmd_put(cmd_in,
                                                     raw_event_out,
                                                     &return_param_length);
            break;
        case BT_OGF_INFO:
            status = info_param_cmd_put(cmd_in,
                                        raw_event_out,
                                        &return_param_length);
            break;
        case BT_OGF_STATUS:
            status = status_param_cmd_put(cmd_in,
                                          raw_event_out,
                                          &return_param_length);
            break;
        case BT_OGF_LE:
            status = le_controller_cmd_put(cmd_in,
                                           raw_event_out,
                                           &return_param_length);
            break;
        case BT_OGF_VS:
            status = vs_cmd_put(cmd_in,
                                raw_event_out,
                                &return_param_length);
            break;
        default:
            status = BT_HCI_ERR_UNKNOWN_CMD;
            break;
        }

        generate_command_status_event = !command_generates_command_complete_event(opcode);
    }

    if (generate_command_status_event ||
        (status == BT_HCI_ERR_UNKNOWN_CMD))
    {
        encode_command_status(raw_event_out, opcode, status);
    }
    else
    {
        encode_command_complete_header(raw_event_out, opcode, return_param_length, status);
    }
}

int hci_internal_cmd_put(uint8_t *cmd_in)
{

    if (cmd_complete_or_status.occurred)
    {
        return -NRF_EPERM;
    }
    cmd_put(cmd_in, &cmd_complete_or_status.raw_event[0]);

    cmd_complete_or_status.occurred = true;

    return 0;
}

int hci_internal_msg_get(uint8_t *msg_out, sdc_hci_msg_type_t *msg_type_out)
{
    if (cmd_complete_or_status.occurred)
    {
        struct bt_hci_evt_hdr *evt_hdr = (void *)&cmd_complete_or_status.raw_event[0];

        memcpy(msg_out, &cmd_complete_or_status.raw_event[0],
               evt_hdr->len + BT_HCI_EVT_HDR_SIZE);
        cmd_complete_or_status.occurred = false;

        *msg_type_out = SDC_HCI_MSG_TYPE_EVT;

        return 0;
    }
    return sdc_hci_get(msg_out, msg_type_out);
}
