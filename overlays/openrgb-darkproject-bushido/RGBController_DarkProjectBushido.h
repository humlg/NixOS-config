/*---------------------------------------------------------*\
| RGBController_DarkProjectBushido.h                        |
|                                                           |
|   RGBController for Dark Project Bushido 87 keyboard      |
|                                                           |
|   This file is part of the OpenRGB project                |
|   SPDX-License-Identifier: GPL-2.0-or-later               |
\*---------------------------------------------------------*/

#pragma once

#include "RGBController.h"
#include "DarkProjectBushidoController.h"

class RGBController_DarkProjectBushido : public RGBController
{
public:
    RGBController_DarkProjectBushido(DarkProjectBushidoController* controller_ptr);
    ~RGBController_DarkProjectBushido();

    void        SetupZones();

    void        DeviceUpdateLEDs();
    void        DeviceUpdateZoneLEDs(int zone);
    void        DeviceUpdateSingleLED(int led);

    void        DeviceUpdateMode();

private:
    DarkProjectBushidoController* controller;
};
