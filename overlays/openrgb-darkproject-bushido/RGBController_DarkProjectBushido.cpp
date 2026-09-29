/*---------------------------------------------------------*\
| RGBController_DarkProjectBushido.cpp                      |
|                                                           |
|   RGBController for Dark Project Bushido 87 keyboard      |
|                                                           |
|   This file is part of the OpenRGB project                |
|   SPDX-License-Identifier: GPL-2.0-or-later               |
\*---------------------------------------------------------*/

#include "RGBController_DarkProjectBushido.h"

/**------------------------------------------------------------------*\
    @name Dark Project Bushido 87
    @category Keyboard
    @type USB
    @save :o:
    @direct :white_check_mark:
    @effects :o:
    @detectors DetectDarkProjectBushidoControllers
    @comment  Only whole-keyboard "Direct" solid color is implemented. This board's other
              lighting effects, and any per-key addressing, were not reverse-engineered -
              the vendor's own web configurator doesn't expose per-key control on this
              board either.
\*-------------------------------------------------------------------*/

RGBController_DarkProjectBushido::RGBController_DarkProjectBushido(DarkProjectBushidoController* controller_ptr)
{
    controller                      = controller_ptr;

    name                            = controller->GetName();
    vendor                          = "Dark Project";
    type                            = DEVICE_TYPE_KEYBOARD;
    description                     = "Dark Project Bushido 87 Keyboard";
    location                        = controller->GetLocation();
    serial                          = controller->GetSerial();

    mode Direct;
    Direct.name                     = "Direct";
    Direct.value                    = DARKPROJECTBUSHIDO_MODE_DIRECT;
    Direct.flags                    = MODE_FLAG_HAS_PER_LED_COLOR;
    Direct.color_mode               = MODE_COLORS_PER_LED;
    modes.push_back(Direct);

    SetupZones();
}

RGBController_DarkProjectBushido::~RGBController_DarkProjectBushido()
{
    Shutdown();

    delete controller;
}

void RGBController_DarkProjectBushido::SetupZones()
{
    zone whole_keyboard_zone;
    whole_keyboard_zone.name       = "Whole Keyboard";
    whole_keyboard_zone.type       = ZONE_TYPE_SINGLE;
    whole_keyboard_zone.leds_min   = 1;
    whole_keyboard_zone.leds_max   = 1;
    whole_keyboard_zone.leds_count = 1;
    zones.push_back(whole_keyboard_zone);

    led whole_keyboard_led;
    whole_keyboard_led.name        = "Whole Keyboard";
    leds.push_back(whole_keyboard_led);

    SetupColors();
}

void RGBController_DarkProjectBushido::DeviceUpdateLEDs()
{
    controller->SetColor(colors[0]);
}

void RGBController_DarkProjectBushido::DeviceUpdateZoneLEDs(int /*zone*/)
{
    DeviceUpdateLEDs();
}

void RGBController_DarkProjectBushido::DeviceUpdateSingleLED(int /*led*/)
{
    DeviceUpdateLEDs();
}

void RGBController_DarkProjectBushido::DeviceUpdateMode()
{
    DeviceUpdateLEDs();
}
