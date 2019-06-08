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

ZMStack::ZMStack()
    : _sp(0), _fp(0), _frames(), _frameCount(0) {}

ZMStack::~ZMStack() {}

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

void ZMStack::pushFrame(uint32_t returnAddr, int argCount,
                        int localCount, uint16_t returnStore) {
  // Set the frame pointer to the new frame
  int prevFp = _fp;
  _fp = _sp;

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

void ZMStack::pushFrame(uint32_t returnAddr, uint8_t flags,
               uint8_t resultVariable, uint8_t argsSupplied,
               uint16_t evalCount, uint16_t *varsAndEval) {

  uint16_t argCount = 0;
  for (int i = 0; i < 7; ++i)
    if (argsSupplied & (1 << i))
      ++argCount;
  uint16_t localCount = flags & 0x0f;
  uint16_t returnStore = (flags & 0x10) ? 0xffff : resultVariable;

  pushFrame(returnAddr, argCount, localCount, returnStore);

  // Set the local variables
  for (int i = 0; i < localCount; ++i)
    setLocal(i, varsAndEval[i]);

  // Push the evaluation stack
  for (int i = 0; i < evalCount; ++i)
    push(varsAndEval[localCount + i]);
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

uint16_t ZMStack::getLocalCount() const { return _entries[_fp + 5]; }

uint16_t ZMStack::getArgCount() const { return _entries[_fp + 4]; }

void ZMStack::dump() const {
  printf("Stack:\n");
  for (int i = _sp - 1; i >= 0; --i)
    printf("%02x: %04x\n", i, _entries[i]);
}

uint16_t ZMStack::getEntry(int index) const { return _entries[index]; }

int ZMStack::getFrameCount() const { return _frameCount; }

int ZMStack::framePointerArray(int *array, int maxCount) {
  int count = getFrameCount();
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

uint16_t ZMStack::getFrameLocal(int frame, int index) const {
  int fp = _frames[frame];
  return _entries[fp + index + 6];
}

int ZMStack::getStackPointer() const { return _sp; }

int ZMStack::getFramePointer() const { return _fp; }

int ZMStack::catchFrame() {
  std::vector<uint16_t> frame;
  uint16_t localCount = _entries[_fp + 5];
  for (uint16_t i = 0; i < 6 + localCount; ++i)
    frame.push_back(_entries[_fp + i]);

  // From Quetzal 1.4, Section 6.2:
  // "For greatest independence of internal interpreter implementation, catch is
  // hereby specified to return the number of frames currently on the system
  // stack.
  _caughtFrames[_frameCount] = frame;
  return _frameCount;
}

void ZMStack::throwFrame(int frame) {

  // Pop frames until we're back to this frame
  uint16_t dummy;
  while (_frameCount > frame)
    popFrame(&dummy);

  // Restore the state of the caught frame
  auto pos = _caughtFrames.find(frame);
  if (pos != _caughtFrames.end()) {
    std::vector<uint16_t> frameVect = pos->second;
    uint16_t i = 0;
    for (auto value : frameVect)
      _entries[_fp + i++] = value;
    _caughtFrames.erase(pos);
  }
}

void ZMStack::reset() {
  _sp = 0;
  _fp = 0;
  _frameCount = 0;
}
