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

ZMStack::ZMStack() : _entries(), _fp(0), _caughtFrames() {}

void ZMStack::push(uint16_t value) { _entries.push_back(value); }

uint16_t ZMStack::pop() {
  uint16_t entry = _entries.back();
  _entries.pop_back();
  return entry;
}

uint16_t ZMStack::getTop() { return _entries.back(); }

void ZMStack::setTop(uint16_t value) { _entries.back() = value; }

void ZMStack::pushFrame(uint32_t returnAddr, int argCount, int localCount,
                        uint16_t returnStore) {
  // Set the frame pointer to the new frame
  int prevFp = _fp;
  _fp = static_cast<int>(_entries.size());

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
                        uint16_t evalCount, const uint8_t *varsAndEval) {

  uint16_t argCount = 0;
  for (int i = 0; i < 7; ++i)
    if (argsSupplied & (1 << i))
      ++argCount;
  uint16_t localCount = flags & 0x0f;
  uint16_t returnStore = (flags & 0x10) ? 0xffff : resultVariable;

  pushFrame(returnAddr, argCount, localCount, returnStore);

  // Set the local variables
  for (int i = 0; i < localCount; ++i) {
    int index = 2 * i;
    uint16_t value =
        static_cast<uint16_t>(varsAndEval[index]) << 8 | varsAndEval[index + 1];
    setLocal(i, value);
  }

  // Push the evaluation stack
  for (int i = 0; i < evalCount; ++i) {
    int index = 2 * (localCount + i);
    uint16_t value =
        static_cast<uint16_t>(varsAndEval[index]) << 8 | varsAndEval[index + 1];
    push(value);
  }
}

uint32_t ZMStack::popFrame(uint16_t *returnStore) {

  // Move the stack pointer to just above the previous frame pointer location
  _entries.erase(_entries.begin() + _fp + 4, _entries.end());

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
  for (size_t i = _entries.size() - 1; i >= 0; --i)
    printf("%02lx: %04x\n", i, _entries[i]);
}

uint16_t ZMStack::getEntry(int index) const { return _entries[index]; }

int ZMStack::getFrameCount() const {
  auto pointers = getFramePointers();
  return static_cast<int>(pointers.size());
}

std::vector<int> ZMStack::getFramePointers() const {
  std::vector<int> pointers;
  if (!_entries.empty()) {
    int fp = _fp;
    while (fp > 0) {
      pointers.insert(pointers.begin(), fp);
      fp = _entries[fp + 3];
    }
    pointers.insert(pointers.begin(), fp);
  }
  return pointers;
}

uint16_t ZMStack::getFrameLocal(int frame, int index) const {
  auto pointers = getFramePointers();
  int fp = pointers[frame];
  return _entries[fp + index + 6];
}

int ZMStack::getStackPointer() const {
  return static_cast<int>(_entries.size());
}

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
  _caughtFrames[getFrameCount()] = frame;
  return getFrameCount();
}

void ZMStack::throwFrame(int frame) {

  // Pop frames until we're back to this frame
  uint16_t dummy;
  while (getFrameCount() > frame)
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
  _entries.clear();
  _fp = 0;
}
