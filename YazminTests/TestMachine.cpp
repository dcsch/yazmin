//
//  TestMachine.cpp
//  YazminTests
//
//  Created by David Schweinsberg on 11/29/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "TestMachine.h"
#include "../Yazmin/ZMError.h"
#include "../Yazmin/ZMIO.h"
#include "../Yazmin/ZMMemory.h"
#include "../Yazmin/ZMProcessor.h"
#include "../Yazmin/ZMQuetzal.h"
#include "../Yazmin/ZMStack.h"

TestMachine::TestMachine(const uint8_t *storyData, size_t length, ZMIO &io,
                         ZMError &error)
    : _io(io), _error(error) {
  _memory = new ZMMemory(storyData, length, _io);
  _stack = new ZMStack();
  _quetzal = new ZMQuetzal(*_memory, *_stack);
  _proc = new ZMProcessor(*_memory, *_stack, _io, _error, *_quetzal);
}

TestMachine::~TestMachine() {
  delete _proc;
  delete _stack;
  delete _quetzal;
  delete _memory;
}
