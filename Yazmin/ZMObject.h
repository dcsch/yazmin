/*
 *  ZMObject.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 16/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_OBJECT_H__
#define ZM_OBJECT_H__

#include <stdint.h>
#include <string>

class ZMMemory;

class ZMObject {
public:
  ZMObject(ZMMemory &memory, int objectNumber);

  uint16_t getParent() const;

  void setParent(uint16_t n);

  uint16_t getSibling() const;

  void setSibling(uint16_t n);

  uint16_t getChild() const;

  void setChild(uint16_t n);

  bool getAttribute(int attribute) const;

  void setAttribute(int attribute, bool b);

  std::string getShortName() const;

  uint16_t getProperty(int property) const;

  uint16_t getNextProperty(int property) const;

  // void setProperty(int property, uint8_t value);

  void setProperty(int property, uint16_t value);

  uint16_t getPropertyAddress(int property) const;

  uint16_t getPropertyLength(int property) const;

  int getPropertyAddressAndSize(int property, uint16_t *addr) const;

  static int getPropertyAtAddress(const ZMMemory &memory, uint16_t addr,
                                  uint8_t *size, uint16_t *propertyAddr,
                                  uint16_t *nextAddr);

  void insert(uint16_t parent);

  void remove();

  static size_t getObjectSize(ZMMemory &memory);

  static size_t getDefaultPropSize(ZMMemory &memory);

  static uint16_t getObjectDataLocation(ZMMemory &memory, int objectNumber);

  static uint16_t getPropertyTableAddress(ZMMemory &memory,
                                          uint16_t objectDataLocation);

private:
  ZMMemory &_memory;
  uint16_t _objectData;
  int _number;

  uint16_t getPropertyTableAddress() const;

  int getPropertyAtAddress(uint16_t addr, uint8_t *size, uint16_t *propertyAddr,
                           uint16_t *nextAddr) const;
};

#endif // ZM_OBJECT_H__
