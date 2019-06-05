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

class ZMMemory;
class ZMStack;

class ZMQuetzal {
public:
  ZMQuetzal(ZMMemory &memory, ZMStack &stack);

  void pushSnapshot(uint32_t pc);

private:
  ZMMemory &_memory;
  ZMStack &_stack;
};

#endif // ZM_QUETZAL_H__
