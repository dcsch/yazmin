/*
 *  ZMStack.cpp
 *  yazmin
 *
 *  Created by David Schweinsberg on 13/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#include "ZMStack.h"
#include <stdio.h>
#include <string.h>

ZMStack::ZMStack(size_t size)
    : //_maxSize(size),
      //_entries(new uint16_t[size]),
      _sp(0),
      _fp(0), _calls(), _frames(), _frameCount(0) {}

ZMStack::~ZMStack() {
  // delete [] _entries;
}

void ZMStack::push(uint16_t value) {
  _entries[_sp] = value;
  ++_sp;
}

uint16_t ZMStack::pop() {
  --_sp;
  return _entries[_sp];
}

uint16_t ZMStack::getTop() { return _entries[_sp - 1]; }

void ZMStack::setTop(uint16_t value) { _entries[_sp - 1] = value; }

void ZMStack::pushFrame(uint32_t callAddr, uint32_t returnAddr, int argCount,
                        int localCount, uint16_t returnStore) {
  // Set the frame pointer to the new frame
  int prevFp = _fp;
  _fp = _sp;

  // Note the calling address (for the z-code debugger)
  _calls[_frameCount] = callAddr;
  _frames[_frameCount] = _fp;
  ++_frameCount;

  // Push the return address (MSW, LSW) to the stack
  push(returnAddr >> 16);
  push(returnAddr);

  // Now the store location for the return value
  push(returnStore);

  // Now the previous frame pointer
  push(prevFp);

  // Now the argument count
  push(argCount);

  // Now the local variable count
  push(localCount);

  // And finally the local variables
  for (int i = 0; i < localCount; ++i)
    push(0);
}

uint32_t ZMStack::popFrame(uint16_t *returnStore) {
  --_frameCount;

  // Move the stack pointer to just above the previous frame pointer location
  _sp = _fp + 4;

  // Pop the previous frame pointer
  _fp = pop();

  // Pop the store location for the return value
  *returnStore = pop();

  // Pop the return address
  uint32_t retAddrLSW = pop();
  uint32_t retAddr = pop() << 16 | retAddrLSW;

  return retAddr;
}

uint16_t ZMStack::getLocal(int index) const {
  return _entries[_fp + index + 6];
}

void ZMStack::setLocal(int index, uint16_t value) {
  _entries[_fp + index + 6] = value;
}

uint16_t ZMStack::getArgCount() const { return _entries[_fp + 4]; }

void ZMStack::createStksChunk(uint8_t **buf, size_t *len) {
  int framePointers[256];
  int count = framePointerArray(framePointers, 256);

  *len = 0;
  *buf = new uint8_t[2 * _sp];
  uint8_t *ptr = *buf;

  // Go through the frame pointers, copying each frame into the
  // supplied buffer
  for (int i = 0; i < count; ++i) {
    int fp = framePointers[i];
    int localCount = 0;

    // return PC (byte address)
    ptr[0] = static_cast<uint8_t>(_entries[fp]);
    ptr[1] = static_cast<uint8_t>(_entries[fp + 1] >> 8);
    ptr[2] = static_cast<uint8_t>(_entries[fp + 1]);

    // flags
    ptr[3] = 0;
    if (_entries[fp + 2] == 0xffff) // RETURN_STORE
    {
      ptr[3] |= 0x10;

      // variable number to store result
      ptr[4] = 0;
    } else
      ptr[4] = static_cast<uint8_t>(_entries[fp + 2]);

    // arguments supplied
    switch (_entries[fp + 4]) {
    case 0:
      ptr[5] = 0;
      break;
    case 1:
      ptr[5] = 0x01;
      break;
    case 2:
      ptr[5] = 0x03;
      break;
    case 3:
      ptr[5] = 0x07;
      break;
    case 4:
      ptr[5] = 0x0f;
      break;
    case 5:
      ptr[5] = 0x1f;
      break;
    case 6:
      ptr[5] = 0x3f;
      break;
    case 7:
      ptr[5] = 0x7f;
      break;
    }

    localCount = _entries[fp + 5];

    // number of words of evaluations stack used by this call
    int totalEntryCount = 0;
    if (i == count - 1) {
      // This is the last frame, so calculate the evaluation stack size
      // using the stack pointer
      totalEntryCount = _sp - framePointers[i];
    } else {
      // Calculate the evaluation stack size by looking at the
      // frame pointers
      totalEntryCount = framePointers[i + 1] - framePointers[i];
    }
    int evalCount = totalEntryCount - localCount - 6;
    ptr[6] = static_cast<uint8_t>(evalCount >> 8);
    ptr[7] = static_cast<uint8_t>(evalCount);

    // local variables
    ptr[3] |= static_cast<uint8_t>(localCount & 0x0f);
    uint8_t *p = &ptr[8];
    int entryIndex = fp + 6;
    for (int j = 0; j < localCount; ++j) {
      p[0] = static_cast<uint8_t>(_entries[entryIndex] >> 8);
      p[1] = static_cast<uint8_t>(_entries[entryIndex]);
      p += 2;
      ++entryIndex;
    }

    // evaluation stack for this call
    for (int j = 0; j < evalCount; ++j) {
      p[0] = static_cast<uint8_t>(_entries[entryIndex] >> 8);
      p[1] = static_cast<uint8_t>(_entries[entryIndex]);
      p += 2;
      ++entryIndex;
    }

    // Move on to the next frame
    int byteLen = 2 * (localCount + evalCount) + 8;
    ptr += byteLen;
    *len += byteLen;
  }
}

void ZMStack::dump() const {
  printf("Stack:\n");
  for (int i = _sp - 1; i >= 0; --i)
    printf("%02x: %04x\n", i, _entries[i]);
}

uint16_t ZMStack::getEntry(int index) const { return _entries[index]; }

int ZMStack::frameCount() {
  //    // Count back through the frame pointers
  //    int count = 1;
  //    int fp = _fp;
  //    while (fp)
  //    {
  //        fp = _entries[fp + 3];
  //        ++count;
  //    }
  //    return count;

  return _frameCount;
}

int ZMStack::framePointerArray(int *array, int maxCount) {
  int count = frameCount();
  if (count <= maxCount) {
    int fp = _fp;
    for (int i = count - 1; i >= 0; --i) {
      array[i] = fp;
      if (fp > 0)
        fp = _entries[fp + 3];
    }
  }
  return count;
}

uint32_t ZMStack::getCallEntry(int index) const { return _calls[index]; }

uint16_t ZMStack::getFrameLocal(int frame, int index) const {
  int fp = _frames[frame];
  return _entries[fp + index + 6];
}

int ZMStack::getStackPointer() const { return _sp; }
