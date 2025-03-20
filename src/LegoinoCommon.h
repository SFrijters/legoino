/*
 * LegoinoCommon.h - Arduino Library for converting values with different types
 *
 * (c) Copyright 2020 - Cornelius Munz
 * Released under MIT License
 *
*/

#if defined(ESP32)

#ifndef LegoinoCommon_h
#define LegoinoCommon_h

#include "Arduino.h"
#include "Lpf2HubConst.h"
#include <string>

class LegoinoCommon
{
public:
  static byte MapSpeed(int speed);
  static byte *Int16ToByteArray(int16_t x);
  static byte *Int32ToByteArray(int32_t x);
  static uint8_t ReadUInt8(uint8_t *data, int offset);
  static int8_t ReadInt8(uint8_t *data, int offset);
  static uint16_t ReadUInt16LE(uint8_t *data, int offset);
  static int16_t ReadInt16LE(uint8_t *data, int offset);
  static uint32_t ReadUInt32LE(uint8_t *data, int offset);
  static int32_t ReadInt32LE(uint8_t *data, int offset);
  static std::string ColorStringFromColor(Color color);
  static std::string ColorStringFromColor(int color);
};

#endif // LegoinoCommon_h

#endif // ESP32
