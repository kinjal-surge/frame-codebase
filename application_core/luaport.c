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

#include <string.h>
#include "error_helpers.h"
#include "lauxlib.h"
#include "lua.h"
#include "lualib.h"
#include "microphone.h"
#include "nrfx_log.h"

#include "i2c.h"
#include "spi.h"
#include "nrfx_systick.h"

// static lua_State *globalL = NULL;

static volatile struct repl_t
{
    char buffer[253];
    bool new_data;
} repl = {
    .new_data = false,
};

bool lua_write_to_repl(uint8_t *buffer, uint8_t length)
{
    if (length >= sizeof(repl.buffer))
    {
        return false;
    }

    if (repl.new_data)
    {
        return false;
    }

    // Naive copy because memcpy isn't compatible with volatile
    for (size_t buffer_index = 0; buffer_index < length; buffer_index++)
    {
        repl.buffer[buffer_index] = buffer[buffer_index];
    }

    // Null terminate the string
    repl.buffer[length] = 0;

    repl.new_data = true;

    return true;
}

/*
** Hook set by signal function to stop the interpreter.
*/
// static void lstop(lua_State *L, lua_Debug *ar)
// {
//     (void)ar;                   /* unused arg. */
//     lua_sethook(L, NULL, 0, 0); /* reset hook */
//     luaL_error(L, "interrupted!");
// }

// void lua_interrupt(void)
// {
//     int flag = LUA_MASKCALL | LUA_MASKRET | LUA_MASKLINE | LUA_MASKCOUNT;
//     lua_sethook(globalL, lstop, flag, 1);
// }

void run_lua(void)
{
    lua_State *L = luaL_newstate();

    if (L == NULL)
    {
        error_with_message("Cannot create lua state: not enough memory");
    }

    // luaL_openlibs(L);
    // microphone_open_library(L);

    char *version_string = LUA_RELEASE " on Brilliant Frame";
    lua_writestring((uint8_t *)version_string, strlen(version_string));
    lua_writeline();

    // TODO attempt to run main.lua

    while (true)
    {
        lua_writestring(">>> ", 5);

        // Wait for input
        while (repl.new_data == false)
        {
        }

        // If we get a reset command
        if (repl.buffer[0] == 0x04)
        {
            repl.new_data = false;
            break;
        }

        /////////////////////// TESTING

        // int status = luaL_dostring(L, "function fib(x) if x<=1 then return x end return fib(x-1)+fib(x-2) end print(fib(20)) print(fib(20)) print(fib(20)) print(fib(20)) print(fib(20))");

        i2c_response_t frame_count;
        uint8_t txbuf[3];
        uint8_t rxbuf[16000];
        uint32_t i;
        uint8_t j;
        uint32_t pix_block;
        uint16_t r, g, b;
        uint16_t color_code = 0;

        switch (repl.buffer[0])
        {
        case (uint8_t)('p'):
            txbuf[0] = 0xbb;
            spi_write(FPGA, &txbuf[0], 1, true);
            spi_read(FPGA, &rxbuf[0], 640*4, false);
            i = 0;
            LOG("Frame data R G B:");
            while (i<640*4) {
                pix_block = (uint32_t) ((rxbuf[i] << 24) + (rxbuf[i+1] << 16) + (rxbuf[i+2] << 8) + rxbuf[i+3]);
                r = (uint16_t)((pix_block & 0x3FF00000) >> 20);
                g = (uint16_t)((pix_block & 0x000ffc00) >> 10);
                b = (uint16_t)((pix_block & 0x000003ff)      );
                LOG("%d\t%d\t%d", r, g, b);
                i = i+4;
                nrfx_systick_delay_ms(1);
            }
            break;
        case (uint8_t)('t'):
            txbuf[0] = 0xbc;
            LOG("Frame data R G B:");
            spi_write(FPGA, &txbuf[0], 1, true);

            for (i = 0; i<40000; i++) {
                if (i==39999)
                    spi_read(FPGA, &rxbuf[0], 1, false);
                else
                    spi_read(FPGA, &rxbuf[0], 1, true);
                
                LOG("%d", rxbuf[0]);
                nrfx_systick_delay_ms(1);
            }
            break;

        case (uint8_t)('f'):
            frame_count = i2c_read(CAMERA, 0x4A00, 0xFF);
            txbuf[0] = 0xb8;
            spi_write(FPGA, &txbuf[0], 1, true);
            spi_read(FPGA, &rxbuf[0], 1, false);
            
            LOG("Frame count came => %u", frame_count.value);
            LOG("Frame count fpga => %d", rxbuf[0]);
            break;

        case (uint8_t)('D'):
            txbuf[0] = 0xb9;
            spi_write(FPGA, &txbuf[0], 1, true);
            spi_read(FPGA, &rxbuf[0], 4, false);
            pix_block = (uint32_t) ((rxbuf[0] << 24) + (rxbuf[1] << 16) + (rxbuf[2] << 8) + rxbuf[3]);
            LOG("debug32 => %d", pix_block);
            break;

        case (uint8_t)('x'):
            color_code = 1552;
            txbuf[0] = 0xcc; txbuf[1] = (color_code & 0xff00) >> 8; txbuf[2] = color_code & 0xff;
            spi_write(FPGA, &txbuf[0], 3, false);
            break;
        
        case (uint8_t)('v'):
            txbuf[0] = 0xb5;
            spi_write(FPGA, &txbuf[0], 1, true);
            spi_read(FPGA, &rxbuf[0], 4, false);
            for(i=0; i<4; i++) {
                LOG("%c", rxbuf[i]);
            }
        default:
            break;
        }

        ///////////////////////

        int status = luaL_dostring(L, (char *)repl.buffer);

        repl.new_data = false;

        if (status == LUA_OK)
        {
            int printables = lua_gettop(L);

            if (printables > 0)
            {
                luaL_checkstack(L, LUA_MINSTACK, "too many results to print");

                lua_getglobal(L, "print");
                lua_insert(L, 1);

                if (lua_pcall(L, printables, 0, 0) != LUA_OK)
                {
                    // const char *msg = lua_pushfstring(
                    //     L,
                    //     "error calling 'print' (%s)",
                    //     lua_tostring(L, -1));

                    // lua_writestringerror("%s\n", msg);
                }
            }
        }

        else
        {
            const char *msg = lua_tostring(L, -1);
            lua_writestringerror("%s\n", msg);
            lua_pop(L, 1);
        }
    }

    lua_close(L);
}
