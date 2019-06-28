/*
 *  ZMMemory.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 14/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_MEMORY_H__
#define ZM_MEMORY_H__

#include "ZMDictionary.h"
#include "ZMHeader.h"
#include <map>
#include <stdint.h>
#include <stdlib.h>

class ZMObject;
class ZMIO;

class ZMMemory {
public:
  ZMMemory(const uint8_t *data, size_t length, const ZMIO &io);

  ~ZMMemory();

  const ZMHeader &getHeader() const;

  ZMHeader &getHeader();

  uint16_t getGlobal(int index) const;

  void setGlobal(int index, uint16_t value);

  ZMObject &getObject(int objectNumber);

  uint16_t getObjectCount();

  const uint8_t *getData() const;

  uint8_t *getData(uint32_t address);

  const uint8_t *getOriginalDynamicData() const;

  size_t getSize() const;

  uint8_t getByte(uint32_t address) const;

  void setByte(uint32_t address, uint8_t value);

  uint16_t getWord(uint32_t address) const;

  void setWord(uint32_t address, uint16_t value);

  uint16_t getChecksum() const;

  uint8_t operator[](int index) const;

  void reset();

  void dump() const;

  static uint16_t readWordFromData(const uint8_t *data);

  static void writeWordToData(uint8_t *data, uint16_t value);

private:
  uint8_t *_data;
  uint8_t *_originalDynamicData;
  size_t _size;
  ZMHeader _header;
  ZMDictionary _dict;
  const ZMIO &_io;
  std::map<int, ZMObject *> _objectMap;
  uint16_t _checksum;

  void initHeader();

  ZMMemory(const ZMMemory &);
  void operator=(const ZMMemory &);
};

inline const ZMHeader &ZMMemory::getHeader() const { return _header; }

inline ZMHeader &ZMMemory::getHeader() { return _header; }

inline const uint8_t *ZMMemory::getData() const { return _data; }

inline uint8_t *ZMMemory::getData(uint32_t address) {
  if (address > _header.getBaseHighMemory()) {
    printf("warning: writing to high memory\n");
  }
  return _data + address;
}

inline const uint8_t *ZMMemory::getOriginalDynamicData() const {
  return _originalDynamicData;
}

inline size_t ZMMemory::getSize() const { return _size; }

inline uint8_t ZMMemory::getByte(uint32_t address) const {
  return _data[address];
}

inline void ZMMemory::setByte(uint32_t address, uint8_t value) {
  if (address > _header.getBaseHighMemory()) {
    printf("warning: writing to high memory\n");
  }
  _data[address] = value;
}

inline uint16_t ZMMemory::getWord(uint32_t address) const {
  return readWordFromData(_data + address);
}

inline void ZMMemory::setWord(uint32_t address, uint16_t value) {
  if (address > _header.getBaseHighMemory()) {
    printf("warning: writing to high memory\n");
  }
  writeWordToData(_data + address, value);
}

inline uint16_t ZMMemory::getChecksum() const { return _checksum; }

inline uint8_t ZMMemory::operator[](int index) const { return _data[index]; }

#endif // ZM_MEMORY_H__
