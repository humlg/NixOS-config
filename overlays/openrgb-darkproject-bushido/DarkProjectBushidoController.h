/*---------------------------------------------------------*\
| DarkProjectBushidoController.h                             |
|                                                           |
|   Driver for Dark Project Bushido 87 keyboard             |
|                                                           |
|   This file is part of the OpenRGB project                |
|   SPDX-License-Identifier: GPL-2.0-or-later               |
\*---------------------------------------------------------*/

#pragma once

#include <string>
#include <hidapi.h>
#include "RGBController.h"

#define DARKPROJECTBUSHIDO_PACKET_SIZE      257
#define DARKPROJECTBUSHIDO_RED_BYTE         59
#define DARKPROJECTBUSHIDO_GREEN_BYTE       67
#define DARKPROJECTBUSHIDO_BLUE_BYTE        75

enum
{
    DARKPROJECTBUSHIDO_MODE_DIRECT     = 0x01,   /* Whole-keyboard solid color */
};

class DarkProjectBushidoController
{
public:
    DarkProjectBushidoController(hid_device* dev_handle, const char* path, std::string dev_name);
    ~DarkProjectBushidoController();

    std::string     GetLocation();
    std::string     GetName();
    std::string     GetSerial();

    void            SetColor(RGBColor color);

private:
    hid_device*     dev;
    std::string     location;
    std::string     name;
};
