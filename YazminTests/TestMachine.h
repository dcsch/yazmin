//
//  TestMachine.hpp
//  YazminTests
//
//  Created by David Schweinsberg on 11/29/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#ifndef TestMachine_hpp
#define TestMachine_hpp

#include <cstddef>
#include <cstdint>

class ZMMemory;
class ZMIO;
class ZMError;
class ZMStack;
class ZMProcessor;
class ZMQuetzal;

class TestMachine {
public:
  TestMachine(const uint8_t *storyData, size_t length, ZMIO &io,
              ZMError &error);
  virtual ~TestMachine();

  ZMProcessor &getProcessor() { return *_proc; }

private:
  ZMIO &_io;
  ZMError &_error;
  ZMMemory *_memory;
  ZMStack *_stack;
  ZMProcessor *_proc;
  ZMQuetzal *_quetzal;
};

#endif /* TestMachine_hpp */
