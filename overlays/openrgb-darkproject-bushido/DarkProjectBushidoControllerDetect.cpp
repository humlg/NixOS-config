/*---------------------------------------------------------*\
| DarkProjectBushidoControllerDetect.cpp                    |
|                                                           |
|   Detector for Dark Project Bushido 87 keyboard           |
|                                                           |
|   This file is part of the OpenRGB project                |
|   SPDX-License-Identifier: GPL-2.0-or-later               |
\*---------------------------------------------------------*/

#include "DetectionManager.h"
#include "RGBController_DarkProjectBushido.h"

/*---------------------------------------------------------*\
| Dark Project (GSKY-branded PCB generation) vendor ID       |
\*---------------------------------------------------------*/
#define DARKPROJECT_GSKY_VID                           0x342D

/*---------------------------------------------------------*\
| Product IDs                                               |
\*---------------------------------------------------------*/
#define BUSHIDO_87_PID                                  0xE40F

DetectedControllers DetectDarkProjectBushidoControllers(hid_device_info* info, const std::string& name)
{
    DetectedControllers detected_controllers;
    hid_device*         dev;

    dev = hid_open_path(info->path);

    if(dev)
    {
        DarkProjectBushidoController*     controller     = new DarkProjectBushidoController(dev, info->path, name);
        RGBController_DarkProjectBushido* rgb_controller = new RGBController_DarkProjectBushido(controller);

        detected_controllers.push_back(rgb_controller);
    }

    return(detected_controllers);
}

/*---------------------------------------------------------------------------------------------*\
| This keyboard exposes three HID interfaces (boot keyboard, a mixed vendor/mouse/keyboard       |
| interface, and this one). Only interface 2 (usage page 0xFF01, usage 0x01) carries the vendor  |
| Feature-report command channel used for lighting control - see DarkProjectBushidoController.cpp |
| for how that was determined.                                                                     |
\*---------------------------------------------------------------------------------------------*/
REGISTER_HID_DETECTOR_IPU("Dark Project Bushido 87", DetectDarkProjectBushidoControllers, DARKPROJECT_GSKY_VID, BUSHIDO_87_PID, 2, 0xFF01, 0x01);
