/**
 * This is an example of how to code your ESP32 (mine is ESP-32-WROOM-32) to emulate a lego Control Plus hub, with ports A, B, C, D (4 ports).
 * It shows up on BrickController2 as "BrickHub" and shows up as a Lego Technic Hub, working on the Powered Up! system, but dont worry about that,
 * it can work with Power Functions too, just do some GPIO magic to your electricity/motor driver controllers, since all that power functions needs
 * is specific voltage control across C1, C2, and in some cases, 9V, and GND (0V)
 * I will add an image of the lego power functions pinout to what function it does under this repo, in "resources" as a png, feel free to refer :)
 *
 *
 * All this example does, is take commands from (for example, BrickController2), and print them out into Serial Monitor, at baud 115200, for you to see,
 * it outputs like this:
 * Port X: ± Y%,
 * negative (-) percentage means the motor/device is trying to go in reverse direction
 * positive (+) percentage means the motor/device is trying to go in forward direction
 * this code only outputs, in the percentage, the power each port is recieving/sending
 *
 *
 * (c) Copyright 2020 - Cornelius Munz
 * Released under MIT License
 *
 * THIS EXAMPLE IS MADE BY YOURS TRULY, EVIL.EXE
 *
 */
#include "Lpf2HubEmulation.h"
#include "LegoinoCommon.h"

Lpf2HubEmulation myEmulatedHub("BrickHub", HubType::CONTROL_PLUS_HUB);
byte portA = (byte)ControlPlusHubPort::A;
byte portB = (byte)ControlPlusHubPort::B;
byte portC = (byte)ControlPlusHubPort::C;
byte portD = (byte)ControlPlusHubPort::D;

int lastValueA = 0; // Init as 0
int lastValueB = 0;
int lastValueC = 0;
int lastValueD = 0;

const int buttonPin = 26;
int buttonState = HIGH;
int lastButtonState = HIGH;

/* UNCOMMENT IF YOU ARE CHECKING FOR RAW DATA
// For raw data debouncing
std::string lastRawData = "";
*/

void writeValueCallback(byte portId, byte value) {
  char portLabel = (portId == 0) ? 'A' : (portId == 1) ? 'B' : (portId == 2) ? 'C' : (portId == 3) ? 'D' : '?';
  int percentage;
  bool isDeadzone = (value > 100 && value < 155);

  if (value <= 100) {
    // Reverse: 0-100 -> 0% to -100%
    percentage = map(value, 0, 100, 0, -100);
  } else if (value >= 155) {
    // Forward: 250-155 -> 0% to +100%
    percentage = map(value, 250, 155, 0, 100);
  } else {
    percentage = 0; // Deadzone handled below
  }

  if (portId == 0 && percentage != lastValueA) {
    Serial.print("Port ");
    Serial.print(portLabel);
    Serial.print(": ");
    if (isDeadzone) {
      Serial.println("deadzone");
    } else {
      if (percentage > 0) Serial.print("+");
      Serial.print(percentage);
      Serial.println("%");
    }
    lastValueA = percentage;
  } else if (portId == 1 && percentage != lastValueB) {
    Serial.print("Port ");
    Serial.print(portLabel);
    Serial.print(": ");
    if (isDeadzone) {
      Serial.println("deadzone");
    } else {
      if (percentage > 0) Serial.print("+");
      Serial.print(percentage);
      Serial.println("%");
    }
    lastValueB = percentage;
  } else if (portId == 2 && percentage != lastValueC) {
    Serial.print("Port ");
    Serial.print(portLabel);
    Serial.print(": ");
    if (isDeadzone) {
      Serial.println("deadzone");
    } else {
      if (percentage > 0) Serial.print("+");
      Serial.print(percentage);
      Serial.println("%");
    }
    lastValueC = percentage;
  } else if (portId == 3 && percentage != lastValueD) {
    Serial.print("Port ");
    Serial.print(portLabel);
    Serial.print(": ");
    if (isDeadzone) {
      Serial.println("deadzone");
    } else {
      if (percentage > 0) Serial.print("+");
      Serial.print(percentage);
      Serial.println("%");
    }
    lastValueD = percentage;
  }
}

void restorePCharacteristic() {
  NimBLEServer* pServer = myEmulatedHub.getServer();
  if (pServer == nullptr) {
    Serial.println("❌ BLE server not available.");
    return;
  }

  BLEService* pService = pServer->getServiceByUUID("00001623-1212-efde-1623-785feabcd123");
  if (pService == nullptr) {
    Serial.println("❌ LPF2 service not found.");
    return;
  }

  BLECharacteristic* pChar = pService->getCharacteristic("00001624-1212-efde-1623-785feabcd123");
  if (pChar == nullptr) {
    pChar = pService->createCharacteristic(
      myEmulatedHub.getCharacteristicUUID(),
      NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::NOTIFY
    );
    Serial.println("⚠️ Characteristic recreated.");
  }

  myEmulatedHub.pCharacteristic = pChar;
  Serial.println("✅ pCharacteristic set.");
}

void restartHub() {
  Serial.println("Restarting hub...");
  myEmulatedHub.start();  // Required per your note
  Serial.print("pCharacteristic after start: ");
  Serial.println(myEmulatedHub.pCharacteristic == nullptr ? "nullptr" : "not null");
  restorePCharacteristic();  // Ensure pCharacteristic is valid
  myEmulatedHub.setWritePortCallback(&writeValueCallback);  // Reattach callback
}

void setup() {
  Serial.begin(115200);
  //BUTTON
  pinMode(buttonPin, INPUT_PULLUP);
  //HUB
  delay(1000);
  Serial.println("1. Starting ESP32...");
  Serial.println("2. Setting callback...");
  myEmulatedHub.setWritePortCallback(&writeValueCallback);
  Serial.println("3. Starting BLE...");
  myEmulatedHub.start();
  Serial.println("4. Attaching motors...");
  myEmulatedHub.attachDevice(portA, DeviceType::MEDIUM_LINEAR_MOTOR);
  myEmulatedHub.attachDevice(portB, DeviceType::MEDIUM_LINEAR_MOTOR);
  myEmulatedHub.attachDevice(portC, DeviceType::MEDIUM_LINEAR_MOTOR);
  myEmulatedHub.attachDevice(portD, DeviceType::MEDIUM_LINEAR_MOTOR);
  Serial.println("5. Setup complete!");
}

void loop() {
  buttonState = digitalRead(buttonPin);
  if (buttonState != lastButtonState && buttonState == LOW) {
    restartHub();
    delay(100);
  }
  lastButtonState = buttonState;

  if (myEmulatedHub.pCharacteristic != nullptr) {
    std::string value = myEmulatedHub.pCharacteristic->getValue();
    if (!value.empty() && value.length() >= 8) {
      /* RAW VALUE PRINTER, USE ONLY FOR DEBUGGING
      if (value != lastRawData) { // Prevent getting spammed by the same thing over and over
        Serial.print("Raw: ");
        for (size_t i = 0; i < value.length(); i++) {
          Serial.print((byte)value[i], HEX);
          Serial.print(" ");
        }
        Serial.println();
        lastRawData = value;  // Update last raw data
      }
      */
      byte portId = (byte)value[3];
      byte power = (byte)value[7];
      if ((byte)value[2] == 0x81) {
        //Serial.println("Calling writeValueCallback...");
        writeValueCallback(portId, power);
      } else {
        // DO NOTHING
      }
    }
  }
  delay(50);
}
