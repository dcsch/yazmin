//
//  ZMQuetzal.h
//  Yazmin
//
//  Created by David Schweinsberg on 6/4/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#ifndef ZM_QUETZAL_H__
#define ZM_QUETZAL_H__

#include <cstdint>
#include <cstdlib>

class ZMIO;
class ZMMemory;
class ZMStack;

class ZMQuetzal {
public:
  ZMQuetzal(ZMMemory &memory, ZMStack &stack);

  void save(const ZMIO &zmio, uint32_t pc) const;

  uint32_t restore(const ZMIO &zmio);

  void pushSnapshot(uint32_t pc);

//private:
  ZMMemory &_memory;
  ZMStack &_stack;

  void createCMemChunk(uint8_t **rleBuf, size_t *rleLen) const;

  void extractCMemChunk(uint8_t *rleBuf, size_t rleLen);

  void createIFhdChunk(uint8_t **buf, size_t *len, uint32_t pc) const;

  bool compareIFhdChunk(uint8_t *buf, size_t len, uint32_t *pc) const;

  void createStksChunk(uint8_t **buf, size_t *len) const;

  void extractStksChunk(uint8_t *buf, size_t len);
};

#endif // ZM_QUETZAL_H__
