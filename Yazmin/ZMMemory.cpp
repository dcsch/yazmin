/*
 *  ZMMemory.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 14/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMMemory.h"
#include "ZMIO.h"
#include "ZMObject.h"
#include "ZMText.h"
#include <assert.h>
#include <stdio.h>

ZMMemory::ZMMemory(const uint8_t *data, size_t length, const ZMIO &io)
    : _data(new uint8_t[length]), _originalDynamicData(0), _size(length),
      _header(_data), _dict(_data), _io(io), _objectMap(), _checksum(0) {
  // Copy the data into memory
  memcpy(_data, data, length);

  // Calculate checksum on the initial memory state
  for (uint32_t i = 0x40; i < _header.getFileLength(); ++i)
    _checksum += _data[i];

  // Create a copy of the original dynamic memory
  _originalDynamicData = new uint8_t[_header.getBaseStaticMemory()];
  memcpy(_originalDynamicData, data, _header.getBaseStaticMemory());

  // Prepare the header bytes
  initHeader();
}

ZMMemory::~ZMMemory() {
  std::map<int, ZMObject *>::iterator pos;
  for (pos = _objectMap.begin(); pos != _objectMap.end(); ++pos)
    delete pos->second;
  delete[] _data;
  delete[] _originalDynamicData;
}

void ZMMemory::initHeader() {
  int fgColor;
  int bgColor;
  _io.getColor(fgColor, bgColor);
  uint8_t screenWidth = _io.getScreenWidth();
  uint8_t screenHeight = _io.getScreenHeight();
  if (_header.getVersion() < 4) {
    _data[1] |= 0x60; // Variable-pitch font is the default
                      // Screen-splitting available
  } else {
    // V4
    _data[1] |= 0x01; // Colours are available
    _data[1] |= 0x04; // Boldface available
    _data[1] |= 0x08; // Italic available
    _data[1] |= 0x10; // Fixed-space font available
    _data[1] |= 0x80; // Timed keyboard input available

    _data[0x1e] = 2;            // Interpreter number
    _data[0x1f] = 'Z';          // Interpreter version
    _data[0x20] = screenWidth;  // Screen height
    _data[0x21] = screenHeight; // Screen width

    if (_header.getVersion() >= 5) {
      // V5
      setWord(0x22, _data[0x21]); // Screen width in units
      setWord(0x24, _data[0x20]); // Screen height in units
      setByte(0x26, 1);           // Font width in units
      setByte(0x27, 1);           // Font height in units
      setByte(0x2c, bgColor);     // Default background colour
      setByte(0x2d, fgColor);     // Default foreground colour
    }
  }

  _data[0x32] = 1; // Standard revision number (major)
  _data[0x33] = 1; // Standard revision number (minor)
}

void ZMMemory::reset() {

  // Copy original memory state
  memcpy(_data, _originalDynamicData, _header.getBaseStaticMemory());

  // Prepare the header bytes
  initHeader();
}

uint16_t ZMMemory::getGlobal(int index) const {
  return readWordFromData(_data + _header.getGlobalVariableTableLocation() +
                          2 * index);
}

void ZMMemory::setGlobal(int index, uint16_t value) {
  writeWordToData(_data + _header.getGlobalVariableTableLocation() + 2 * index,
                  value);
}

ZMObject &ZMMemory::getObject(int objectNumber) {
  assert(objectNumber > 0);

  // Is the object already in memory?
  ZMObject *obj = _objectMap[objectNumber];
  if (obj == 0) {
    obj = new ZMObject(*this, objectNumber);
    _objectMap[objectNumber] = obj;

    // TESTING
    // std::string name = obj->getShortName();
    // printf("Object: %s\n", name.c_str());
  }
  return *obj;
}

uint16_t ZMMemory::getObjectCount() {
  // The algorithm we'll use is based on the 'infodump' one as referenced in
  // the z-spec10 document.  Quoting from that:
  // "The largest valid object number is not directly stored anywhere in the
  // Z-machine. Utility programs like Infodump deduce this number by assuming
  // that, initially, the object entries end where the first property table
  // begins."
  uint16_t objLoc = 0;
  uint16_t lowestPropLoc = 0xffff;
  uint16_t count = 0;
  while (objLoc < lowestPropLoc) {
    ++count;
    objLoc = ZMObject::getObjectDataLocation(*this, count);
    lowestPropLoc = std::min(lowestPropLoc,
                             ZMObject::getPropertyTableAddress(*this, objLoc));
  }
  return count - 1;
}

void ZMMemory::dump() const {
  // Dump global memory values
  printf("Global variables:");
  uint8_t *ptr = _data + _header.getGlobalVariableTableLocation();
  for (int i = 0; i < 240; ++i) {
    if (i % 8 == 0)
      printf("\n%02x: ", i);
    printf("%04x ", readWordFromData(ptr));
    ptr += 2;
  }
  printf("\n");
}

uint16_t ZMMemory::readWordFromData(const uint8_t *data) {
  return (data[0] << 8) | data[1];
}

void ZMMemory::writeWordToData(uint8_t *data, uint16_t value) {
  data[0] = static_cast<uint8_t>(value >> 8);
  data[1] = static_cast<uint8_t>(value);
}
