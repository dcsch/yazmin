/*
 *  ZMStack.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 13/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */
#ifndef ZM_STACK_H__
#define ZM_STACK_H__

#include <map>
#include <stdint.h>
#include <stdlib.h>
#include <vector>

/*!
 The Yazmin stack is made up of frames that look like the following (before
 anything is pushed onto the evaluation stack):
 _fp -> RETURN_ADDR_MSW
        RETURN_ADDR_LSW
        RETURN_STORE
        PREV_FRAME_POINTER
        ARG_COUNT
        LOCAL_VARIABLE_COUNT
        LOCAL_VARIABLE_1
        ...
        LOCAL_VARIABLE_N
 _sp -> (Evaluation Stack)
 */
class ZMStack {
public:
  ZMStack();

  ~ZMStack();

  void push(uint16_t value);

  uint16_t pop();

  uint16_t getTop();

  void setTop(uint16_t value);

  void pushFrame(uint32_t returnAddr, int argCount,
                 int localCount, uint16_t returnStore);

  // Quetzal-compatible frame
  void pushFrame(uint32_t returnAddr, uint8_t flags,
                 uint8_t resultVariable, uint8_t argsSupplied,
                 uint16_t evalCount, uint16_t *varsAndEval);

  uint32_t popFrame(uint16_t *returnStore);

  uint16_t getLocal(int index) const;

  void setLocal(int index, uint16_t value);

  uint16_t getLocalCount() const;

  uint16_t getArgCount() const;

  void dump() const;

  uint16_t getEntry(int index) const;

  int getFrameCount() const;

  int framePointerArray(int *array, int maxCount);

  uint16_t getFrameLocal(int frame, int index) const;

  int getStackPointer() const;

  int getFramePointer() const;

  int catchFrame();

  void throwFrame(int frame);

  void reset();

private:
  uint16_t _entries[0xffff];
  int _sp;
  int _fp;
  int _frames[0xffff];
  uint32_t _frameCount;
  std::map<int, std::vector<uint16_t>> _caughtFrames;
};

#endif // ZM_STACK_H__
