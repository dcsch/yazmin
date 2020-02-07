/*
 *  ZMObject.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 16/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMObject.h"
#include "ZMMemory.h"
#include "ZMText.h"
#include <assert.h>

ZMObject::ZMObject(ZMMemory &memory, int objectNumber)
    : _memory(memory), _objectData(getObjectDataLocation(memory, objectNumber)),
      _number(objectNumber) {}

uint16_t ZMObject::getParent() const {
  if (_memory.getHeader().getVersion() <= 3)
    return _memory.getByte(_objectData + 4);
  else
    return _memory.getWord(_objectData + 6);
}

void ZMObject::setParent(uint16_t n) {
  if (_memory.getHeader().getVersion() <= 3)
    _memory.setByte(_objectData + 4, n);
  else
    _memory.setWord(_objectData + 6, n);
}

uint16_t ZMObject::getSibling() const {
  if (_memory.getHeader().getVersion() <= 3)
    return _memory.getByte(_objectData + 5);
  else
    return _memory.getWord(_objectData + 8);
}

void ZMObject::setSibling(uint16_t n) {
  if (_memory.getHeader().getVersion() <= 3)
    _memory.setByte(_objectData + 5, n);
  else
    _memory.setWord(_objectData + 8, n);
}

uint16_t ZMObject::getChild() const {
  if (_memory.getHeader().getVersion() <= 3)
    return _memory.getByte(_objectData + 6);
  else
    return _memory.getWord(_objectData + 10);
}

void ZMObject::setChild(uint16_t n) {
  if (_memory.getHeader().getVersion() <= 3)
    _memory.setByte(_objectData + 6, n);
  else
    _memory.setWord(_objectData + 10, n);
}

bool ZMObject::getAttribute(int attribute) const {
  // TODO Throw an exception if accessing an out-of-range attribute
  int byte = attribute / 8;
  int bit = attribute % 8;
  return (_memory.getByte(_objectData + byte) & (1 << (7 - bit))) ? true
                                                                  : false;
}

void ZMObject::setAttribute(int attribute, bool b) {
  // TODO Throw an exception if accessing an out-of-range attribute
  int byte = attribute / 8;
  int bit = attribute % 8;
  if (b)
    _memory.setByte(_objectData + byte,
                    _memory.getByte(_objectData + byte) | (1 << (7 - bit)));
  else
    _memory.setByte(_objectData + byte,
                    _memory.getByte(_objectData + byte) & ~(1 << (7 - bit)));
}

std::string ZMObject::getShortName() const {
  uint16_t addr = getPropertyTableAddress();
  size_t len = _memory.getByte(addr);
  if (len > 0) {
    ZMText text(_memory.getData());
    size_t encLen;
    return text.decodeZCharsToZscii(_memory.getData() + addr + 1, encLen);
  }
  return "";
}

uint16_t ZMObject::getProperty(int property) const {
  assert(property > 0);

  uint16_t addr;
  int size = getPropertyAddressAndSize(property, &addr);
  if (size == 2)
    return _memory.getWord(addr);
  else if (size == 1)
    return _memory.getByte(addr);
  else
    return _memory.getWord(_memory.getHeader().getObjectTableLocation() +
                           2 * (property - 1));
}

uint16_t ZMObject::getNextProperty(int property) const {
  int nextProp;
  uint16_t addr;
  uint8_t nextSize;
  uint16_t propAddr;
  uint16_t nextAddr;
  if (property == 0) {
    // Get the first property
    addr = getPropertyTableAddress();
    addr += 2 * _memory.getByte(addr) + 1; // Skip over name
    nextProp = getPropertyAtAddress(addr, &nextSize, &propAddr, &nextAddr);
  } else {
    int size = getPropertyAddressAndSize(property, &addr);
    nextProp =
        getPropertyAtAddress(addr + size, &nextSize, &propAddr, &nextAddr);
  }
  return nextProp;
}

// void ZMObject::setProperty(int property, uint8_t value)
//{
//    uint16_t addr;
//    int size = getPropertyAddressAndSize(property, &addr);
//}

void ZMObject::setProperty(int property, uint16_t value) {
  uint16_t addr;
  int size = getPropertyAddressAndSize(property, &addr);
  if (size == 2)
    _memory.setWord(addr, value);
  else if (size == 1)
    _memory.setByte(addr, static_cast<uint8_t>(value));
}

uint16_t ZMObject::getPropertyAddress(int property) const {
  assert(property > 0);

  uint16_t addr;
  getPropertyAddressAndSize(property, &addr);
  return addr;
}

uint16_t ZMObject::getPropertyLength(int property) const {
  assert(property > 0);

  uint16_t addr;
  return static_cast<uint16_t>(getPropertyAddressAndSize(property, &addr));
}

uint16_t ZMObject::getPropertyTableAddress() const {
  return getPropertyTableAddress(_memory, _objectData);
  //    if (_memory.getHeader().getVersion() <= 3)
  //        return _memory.getWord(_objectData + 7);
  //    else
  //        return _memory.getWord(_objectData + 12);
}

int ZMObject::getPropertyAddressAndSize(int property, uint16_t *addr) const {
  *addr = 0;
  uint16_t currAddr = getPropertyTableAddress();

  // Skip over name
  currAddr += 2 * _memory.getByte(currAddr) + 1;

  // Iterate through properties until we have the desired number
  int currNumber;
  uint8_t size;
  uint16_t propertyAddr;
  uint16_t nextAddr;

  uint8_t maxSize;
  if (_memory.getHeader().getVersion() <= 3)
    maxSize = 8;
  else
    maxSize = 64;

  while (true) {
    currNumber =
        getPropertyAtAddress(currAddr, &size, &propertyAddr, &nextAddr);
    if (currNumber == property) {
      // We have it
      *addr = propertyAddr;
      return size;
    } else if (currNumber == 0)
      return 0; // We're at the end of the list
    else if (currNumber < property || size > maxSize)
      return 0; // We've gone past the desired property number
    else if (nextAddr > currAddr)
      currAddr = nextAddr; // Advance to the next property
    else
      return 0;
  }

  //    if (_memory.getHeader().getVersion() <= 3)
  //    {
  //        while (true)
  //        {
  //            currNumber = _memory.getByte(currAddr);
  //            size = (currNumber >> 5) + 1;
  //            currNumber &= 0x1f;
  //            if (currNumber == property)
  //            {
  //                // We have it
  //                *addr = currAddr + 1;
  //                return size;
  //            }
  //            else if (currNumber < property || size > 8)
  //                return 0;
  //            else
  //                currAddr += size + 1;
  //        }
  //    }
  //    else
  //    {
  //        while (true)
  //        {
  //            int sizeSize;
  //            currNumber = _memory.getByte(currAddr);
  //            if (currNumber & 0x80)
  //            {
  //                size = _memory.getByte(currAddr + 1) & 0x3f;
  //                sizeSize = 2;
  //            }
  //            else if (currNumber & 0x40)
  //            {
  //                size = 2;
  //                sizeSize = 1;
  //            }
  //            else
  //            {
  //                size = 1;
  //                sizeSize = 1;
  //            }
  //            currNumber &= 0x3f;
  //            if (currNumber == property)
  //            {
  //                // We have it
  //                *addr = currAddr + sizeSize;
  //                return size;
  //            }
  //            else if (currNumber < property || size > 64)
  //                return 0;
  //            else
  //                currAddr += size + sizeSize;
  //        }
  //    }

  return 0;
}

int ZMObject::getPropertyAtAddress(uint16_t addr, uint8_t *size,
                                   uint16_t *propertyAddr,
                                   uint16_t *nextAddr) const {
  int number;

  if (_memory.getHeader().getVersion() <= 3) {
    number = _memory.getByte(addr);
    *size = (number >> 5) + 1;
    number &= 0x1f;
    *propertyAddr = addr + 1;
    *nextAddr = addr + *size + 1;
  } else {
    int sizeSize;
    number = _memory.getByte(addr);
    if (number & 0x80) {
      *size = _memory.getByte(addr + 1) & 0x3f;
      if (*size == 0)
        *size = 64;
      sizeSize = 2;
    } else if (number & 0x40) {
      *size = 2;
      sizeSize = 1;
    } else {
      *size = 1;
      sizeSize = 1;
    }
    number &= 0x3f;
    *propertyAddr = addr + sizeSize;
    *nextAddr = addr + *size + sizeSize;
  }
  return number;
}

int ZMObject::getPropertyAtAddress(const ZMMemory &memory, uint16_t addr,
                                   uint8_t *size, uint16_t *propertyAddr,
                                   uint16_t *nextAddr) {
  int number;

  if (memory.getHeader().getVersion() <= 3) {
    number = memory.getByte(addr);
    *size = (number >> 5) + 1;
    number &= 0x1f;
    *propertyAddr = addr + 1;
    *nextAddr = addr + *size + 1;
  } else {
    int sizeSize;
    number = memory.getByte(addr);
    if (number & 0x80) {
      *size = memory.getByte(addr + 1) & 0x3f;
      if (*size == 0)
        *size = 64;
      sizeSize = 2;
    } else if (number & 0x40) {
      *size = 2;
      sizeSize = 1;
    } else {
      *size = 1;
      sizeSize = 1;
    }
    number &= 0x3f;
    *propertyAddr = addr + sizeSize;
    *nextAddr = addr + *size + sizeSize;
  }
  return number;
}

void ZMObject::insert(uint16_t parent) {
  assert(parent > 0);

  remove();
  setParent(parent);
  ZMObject &obj = _memory.getObject(parent);
  setSibling(obj.getChild());
  obj.setChild(_number);
}

void ZMObject::remove() {
  // Remove from parent or chain of siblings
  if (getParent() != 0) {
    ZMObject &obj = _memory.getObject(getParent());
    uint16_t nextObjNumber = obj.getChild();
    if (nextObjNumber == _number) {
      // This object is a first child, so break the parent's child
      // relationship
      obj.setChild(getSibling());
    } else {
      while (nextObjNumber != 0) {
        ZMObject &obj = _memory.getObject(nextObjNumber);
        nextObjNumber = obj.getSibling();
        if (nextObjNumber == _number) {
          // This object is a later sibling, so break the sibling
          // relationship by skipping over us to the next sibling
          obj.setSibling(getSibling());
          break;
        }
      }
    }
  }

  // Now we have no parent and no siblings
  setParent(0);
  setSibling(0);
}

size_t ZMObject::getObjectSize(ZMMemory &memory) {
  return (memory.getHeader().getVersion() <= 3) ? 9 : 14;
}

size_t ZMObject::getDefaultPropSize(ZMMemory &memory) {
  return (memory.getHeader().getVersion() <= 3) ? 62 : 126;
}

uint16_t ZMObject::getObjectDataLocation(ZMMemory &memory, int objectNumber) {
  size_t objectSize = getObjectSize(memory);
  size_t defaultPropSize = getDefaultPropSize(memory);
  return memory.getHeader().getObjectTableLocation() + defaultPropSize +
         (objectNumber - 1) * objectSize;
}

uint16_t ZMObject::getPropertyTableAddress(ZMMemory &memory,
                                           uint16_t objectDataLocation) {
  if (memory.getHeader().getVersion() <= 3)
    return memory.getWord(objectDataLocation + 7);
  else
    return memory.getWord(objectDataLocation + 12);
}
