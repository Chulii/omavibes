#ifndef DEVICE_H
#define DEVICE_H

#include <string>

// Find available keyboard devices.
std::string findKeyboardDevices();

// Get the input device path from the configuration directory.
std::string getInputDevicePath(std::string &configDir);

// Save the selected input device path.
void saveInputDevice(std::string &configDir);

#endif // DEVICE_H
