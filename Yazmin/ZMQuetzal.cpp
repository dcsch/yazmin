//
//  ZMQuetzal.cpp
//  Yazmin
//
//  Created by David Schweinsberg on 6/4/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "ZMQuetzal.h"
#include "ZMMemory.h"
#include "ZMStack.h"

ZMQuetzal::ZMQuetzal(ZMMemory &memory, ZMStack &stack)
    : _memory(memory), _stack(stack) {}

void ZMQuetzal::pushSnapshot(uint32_t pc) {
  uint8_t *cmemBuf;
  size_t cmemLen;
  _memory.createCMemChunk(&cmemBuf, &cmemLen);

  uint8_t *stksBuf;
  size_t stksLen;
  _stack.createStksChunk(&stksBuf, &stksLen);

  uint8_t *ihhdBuf;
  size_t ifhdLen;
  _memory.createIFhdChunk(&ihhdBuf, &ifhdLen, pc);

  delete[] ihhdBuf;
  delete[] stksBuf;
  delete[] cmemBuf;
}
