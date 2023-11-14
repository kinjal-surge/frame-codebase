/*
 * This file is a part of: https://github.com/brilliantlabsAR/frame-codebase
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

#pragma once
#include <stdint.h>

typedef struct camera_config_t
{
    uint16_t address;
    uint8_t value;
} camera_config_t;

static const camera_config_t camera_config[] = {
    {0x0103, 0x01},
    {0x0100, 0x00},
    {0x3001, 0x00},
    {0x3002, 0x00},
    {0x3007, 0x00},
    {0x3010, 0x00},
    {0x3011, 0x08},
    {0x3014, 0x22},
    {0x301e, 0x15},
    {0x3030, 0x19},
    {0x3080, 0x02},
    {0x3081, 0x3c},
    {0x3082, 0x04},
    {0x3083, 0x00},
    {0x3084, 0x02},
    {0x3085, 0x01},
    {0x3086, 0x01},
    {0x3089, 0x01},
    {0x308a, 0x00},
    {0x3103, 0x01},
    {0x3600, 0x55},
    {0x3601, 0x02},
    {0x3605, 0x22},
    {0x3611, 0xe7},
    {0x3654, 0x10},
    {0x3655, 0x77},
    {0x3656, 0x77},
    {0x3657, 0x07},
    {0x3658, 0x22},
    {0x3659, 0x22},
    {0x365a, 0x02},
    {0x3784, 0x05},
    {0x3785, 0x55},
    {0x37c0, 0x07},
    {0x3800, 0x00},
    {0x3801, 0x04},
    {0x3802, 0x00},
    {0x3803, 0x04},
    {0x3804, 0x05},
    {0x3805, 0x0b},
    {0x3806, 0x02},
    {0x3807, 0xdb},
    {0x3808, 0x05},
    {0x3809, 0x00},
    {0x380a, 0x02},
    {0x380b, 0xd0},
    {0x380c, 0x05},
    {0x380d, 0xc6},
    {0x380e, 0x03},
    {0x380f, 0x22},
    {0x3810, 0x00},
    {0x3811, 0x04},
    {0x3812, 0x00},
    {0x3813, 0x04},
    {0x3814, 0x00},
    {0x3815, 0x10},
    {0x3816, 0x00},
    {0x3817, 0x00},
    {0x3818, 0x06},
    {0x3819, 0x50},
    {0x381c, 0x24},
    {0x3820, 0x18},
    {0x3821, 0x00},
    {0x3822, 0x00},
    {0x3823, 0x10},
    {0x3824, 0x06},
    {0x3825, 0x50},
    {0x382c, 0x06},
    {0x3500, 0x00},
    {0x3501, 0x31},
    {0x3502, 0x00},
    {0x3503, 0x03},
    {0x3504, 0x00},
    {0x3505, 0x00},
    {0x3509, 0x10},
    {0x350a, 0x00},
    {0x350b, 0x40},
    {0x3d00, 0x00},
    {0x3d01, 0x00},
    {0x3d02, 0x00},
    {0x3d03, 0x00},
    {0x3d04, 0x00},
    {0x3d05, 0x00},
    {0x3d06, 0x00},
    {0x3d07, 0x00},
    {0x3d08, 0x00},
    {0x3d09, 0x00},
    {0x3d0a, 0x00},
    {0x3d0b, 0x00},
    {0x3d0c, 0x00},
    {0x3d0d, 0x00},
    {0x3d0e, 0x00},
    {0x3d0f, 0x00},
    {0x3d80, 0x00},
    {0x3d81, 0x00},
    {0x3d82, 0x38},
    {0x3d83, 0xa4},
    {0x3d84, 0x00},
    {0x3d85, 0x00},
    {0x3d86, 0x1f},
    {0x3d87, 0x03},
    {0x3d8b, 0x00},
    {0x3d8f, 0x00},
    {0x4001, 0xe0},
    {0x4009, 0x0b},
    {0x4300, 0x03},
    {0x4301, 0xff},
    {0x4304, 0x00},
    {0x4305, 0x00},
    {0x4309, 0x00},
    {0x4600, 0x00},
    {0x4601, 0x80},
    {0x4800, 0x00},
    {0x4805, 0x00},
    {0x4821, 0x50},
    {0x4823, 0x50},
    {0x4837, 0x2d},
    {0x4a00, 0x00},
    {0x4f00, 0x80},
    {0x4f01, 0x10},
    {0x4f02, 0x00},
    {0x4f03, 0x00},
    {0x4f04, 0x00},
    {0x4f05, 0x00},
    {0x4f06, 0x00},
    {0x4f07, 0x00},
    {0x4f08, 0x00},
    {0x4f09, 0x00},
    {0x5000, 0x3f},
    {0x500c, 0x00},
    {0x500d, 0x00},
    {0x500e, 0x00},
    {0x500f, 0x00},
    {0x5010, 0x00},
    {0x5011, 0x00},
    {0x5012, 0x00},
    {0x5013, 0x00},
    {0x5014, 0x00},
    {0x5015, 0x00},
    {0x5016, 0x00},
    {0x5017, 0x00},
    {0x5080, 0x00}, // flat color bar 0x80
    {0x5180, 0x01},
    {0x5181, 0x00},
    {0x5182, 0x01},
    {0x5183, 0x00},
    {0x5184, 0x01},
    {0x5185, 0x00},
    {0x5708, 0x06},
    {0x380f, 0x2a},
    {0x5780, 0x3e},
    {0x5781, 0x0f},
    {0x5782, 0x44},
    {0x5783, 0x02},
    {0x5784, 0x01},
    {0x5785, 0x01},
    {0x5786, 0x00},
    {0x5787, 0x04},
    {0x5788, 0x02},
    {0x5789, 0x0f},
    {0x578a, 0xfd},
    {0x578b, 0xf5},
    {0x578c, 0xf5},
    {0x578d, 0x03},
    {0x578e, 0x08},
    {0x578f, 0x0c},
    {0x5790, 0x08},
    {0x5791, 0x04},
    {0x5792, 0x00},
    {0x5793, 0x52},
    {0x5794, 0xa3},
    {0x0100, 0x00},
    {0x3801, 0x00},
    {0x3803, 0x00},
    {0x3805, 0x0f},
    {0x3807, 0xdf},
    {0x3809, 0x08},
    {0x380b, 0xd8},
    {0x3811, 0x04},
    {0x3813, 0x04},
    {0x0100, 0x01},
};
