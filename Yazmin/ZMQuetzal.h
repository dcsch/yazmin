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
#include <vector>

class ZMIO;
class ZMMemory;
class ZMStack;

class ZMQuetzal {
public:
  ZMQuetzal(ZMMemory &memory, ZMStack &stack);

  void save(const ZMIO &zmio, uint32_t pc) const;

  uint32_t restore(const ZMIO &zmio);

  void saveUndo(uint32_t pc);

  uint32_t restoreUndo();

  void createCMemChunk(uint8_t **rleBuf, size_t *rleLen) const;

  void extractCMemChunk(const uint8_t *rleBuf, size_t rleLen);

  void extractCMemChunk(const std::vector<uint8_t> cmem);

  void createIFhdChunk(uint8_t **buf, size_t *len, uint32_t pc) const;

  bool compareIFhdChunk(uint8_t *buf, size_t len, uint32_t *pc) const;

  static void extractStksChunk(const uint8_t *buf, size_t len, ZMStack &stack);

  void createStksChunk(uint8_t **buf, size_t *len) const;

  void extractStksChunk(const uint8_t *buf, size_t len);

  void extractStksChunk(const std::vector<uint8_t> stks);

private:
  ZMMemory &_memory;
  ZMStack &_stack;

  struct Snapshot {
    std::vector<uint8_t> cmem;
    std::vector<uint8_t> stks;
    uint32_t pc;
  };

  std::vector<std::shared_ptr<Snapshot>> undoStack;
};

#endif // ZM_QUETZAL_H__
