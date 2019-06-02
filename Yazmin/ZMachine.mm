/*
 *  ZMachine.mm
 *  yazmin
 *
 *  Created by David Schweinsberg on 10/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#import "ZMachine.h"
#import "Story.h"
#import "ZMErrorAdapter.h"
#include "ZMMemory.h"
#include "ZMObject.h"
#include "ZMProcessor.h"
#include "ZMStack.h"
#import "ZMStoryAdapter.h"
#include "ZMText.h"
#include <stdint.h>
#include <stdio.h>

struct MachineParts {
  MachineParts() {
    _memory = 0;
    _io = 0;
    _error = 0;
    _stack = 0;
    _proc = 0;
  }
  ZMMemory *_memory;
  ZMStoryAdapter *_io;
  ZMErrorAdapter *_error;
  ZMStack *_stack;
  ZMProcessor *_proc;
};

@interface ZMachine () {
  Story *story;
  struct MachineParts *parts;
}

@end

@implementation ZMachine

static const size_t kMaxStorySize = 0x8ffff;

- (instancetype)initWithStory:(Story *)aStory {
  if ((self = [super init])) {
    story = aStory;
    parts = new MachineParts;

    NSData *data = [story zcodeData];

    if (data != nil) {
      // If it is a legal size, load the whole thing into memory
      NSUInteger len = data.length;
      if (0 < len && len <= kMaxStorySize) {
        parts->_memory = new ZMMemory((const uint8_t *)data.bytes, len);

        // parts->_memory->getHeader().dump();
        // parts->_memory->dump();
      }

      parts->_io = new ZMStoryAdapter(story);
      parts->_error = new ZMErrorAdapter(story);
      parts->_stack = new ZMStack(1024);
      parts->_proc = new ZMProcessor(*parts->_memory, *parts->_stack,
                                     *parts->_io, *parts->_error);
    }
  }
  return self;
}

- (void)dealloc {
  delete parts->_proc;
  delete parts->_stack;
  delete parts->_io;
  delete parts->_memory;
  delete parts;
}

- (NSString *)ifid {
  unsigned char *begin = 0;
  unsigned char *end = 0;

  // Scan memory looking for a 'UUID://..//' section in memory
  for (unsigned int i = 0; i < parts->_memory->getSize() - 7; ++i) {
    unsigned char *ptr = parts->_memory->getData() + i;
    if (ptr[0] == 'U' && ptr[1] == 'U' && ptr[2] == 'I' && ptr[3] == 'D' &&
        ptr[4] == ':' && ptr[5] == '/' && ptr[6] == '/') {
      begin = ptr + 7;
      break;
    }
  }

  if (begin) {
    // We've found the beginning, so find the end
    unsigned char *ptr = begin + 1;
    for (int j = 0; j < 48; ++j) {
      if (ptr[j] == '/' && ptr[j + 1] == '/') {
        end = ptr + j;
        break;
      }
    }

    if (end) {
      // We have both a beginning and an ending, so go with this
      return [[NSString alloc] initWithBytes:begin
                                      length:end - begin
                                    encoding:[NSString defaultCStringEncoding]];
    }
  }

  // No branded UUID, so we'll generate it from header data
  NSMutableString *ifidString = [NSMutableString stringWithCapacity:48];
  [ifidString
      appendFormat:@"ZCODE-%d-", parts->_memory->getHeader().getRelease()];
  std::string serial = parts->_memory->getHeader().getSerialCode();
  NSString *serialString =
      [NSString stringWithCString:serial.c_str()
                         encoding:[NSString defaultCStringEncoding]];
  [ifidString appendString:serialString];

  if (([serialString characterAtIndex:0] != '8') &&
      ([serialString compare:@"000000"] != 0)) {
    NSString *checksumString = [NSString
        stringWithFormat:@"-%02X",
                         parts->_memory->getHeader().getFileChecksum()];
    [ifidString appendString:checksumString];
  }

  return ifidString;
}

- (unsigned char *)memory {
  return parts->_memory->getData();
}

- (size_t)memorySize {
  return parts->_memory->getSize();
}

- (BOOL)hasQuit {
  return parts->_proc->hasQuit() ? YES : NO;
}

- (BOOL)executeUntilHalt {
  if (parts->_proc->executeUntilHalt())
    return YES;
  else
    return NO;
}

- (BOOL)callRoutine:(int)routine {
  return parts->_proc->callRoutine(routine);
}

//- (void)restart
//{
//    NSData *data = [story zcodeData];
//    if (data != nil)
//    {
//        [data getBytes:parts->_memory->getData()];
//        parts->_memory->initHeader();
//        parts->_stack->
//    }
//}

- (int)numberOfChildrenOfObject:(int)objNumber {
  uint16_t objectCount = parts->_memory->getObjectCount();
  int childCount = 0;
  if (objNumber == 0) {
    for (int i = 1; i <= objectCount; ++i) {
      ZMObject &obj = parts->_memory->getObject(i);
      if (obj.getParent() == 0)
        ++childCount;
    }
  } else {
    ZMObject &obj = parts->_memory->getObject(objNumber);
    uint16_t child = obj.getChild();
    while (child != 0) {
      ++childCount;
      child = parts->_memory->getObject(child).getSibling();
    }
  }
  return childCount;
}

- (int)child:(int)index ofObject:(int)objNumber {
  uint16_t objectCount = parts->_memory->getObjectCount();
  int childCount = 0;
  if (objNumber == 0) {
    for (int i = 1; i <= objectCount; ++i) {
      ZMObject &obj = parts->_memory->getObject(i);
      if (obj.getParent() == 0)
        ++childCount;
      if (childCount == index + 1)
        return i;
    }
  } else {
    ZMObject &obj = parts->_memory->getObject(objNumber);
    uint16_t child = obj.getChild();
    while (child != 0) {
      ++childCount;
      if (childCount == index + 1)
        return child;
      child = parts->_memory->getObject(child).getSibling();
    }
  }
  return 0;
}

- (NSString *)nameOfObject:(int)objNumber {
  ZMObject &obj = parts->_memory->getObject(objNumber);
  if (obj.getShortName().empty())
    return nil;
  return [NSString stringWithCString:obj.getShortName().c_str()
                            encoding:[NSString defaultCStringEncoding]];
}

- (int)numberOfPropertiesOfObject:(int)objNumber {
  ZMObject &obj = parts->_memory->getObject(objNumber);
  int prop = 0;
  int count = 0;
  while ((prop = obj.getNextProperty(prop)) != 0)
    ++count;
  return count;
}

- (int)property:(int)index ofObject:(int)objNumber {
  ZMObject &obj = parts->_memory->getObject(objNumber);
  int prop = 0;
  int count = 0;
  while ((prop = obj.getNextProperty(prop)) != 0) {
    if (count == index)
      return prop;
    ++count;
  }
  // return nil;
  return -1;
}

- (NSString *)propertyData:(int)index ofObject:(int)objNumber {
  ZMObject &obj = parts->_memory->getObject(objNumber);
  int prop = 0;
  int count = 0;
  while ((prop = obj.getNextProperty(prop)) != 0) {
    if (count == index) {
      uint16_t addr;
      int size = obj.getPropertyAddressAndSize(prop, &addr);
      char propDump[1024] = {0};
      for (int i = 0; i < size; ++i)
        sprintf(propDump + 3 * i, "%02x ", parts->_memory->getByte(addr++));
      return [NSString stringWithCString:propDump
                                encoding:[NSString defaultCStringEncoding]];
    }
    ++count;
  }
  return nil;
}

- (NSArray *)abbreviations {
  NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:96];
  ZMText text(parts->_memory->getData());
  char buf[256];
  for (int i = 0; i < 96; ++i) {
    text.abbreviation(i, buf, 255);
    [array addObject:[NSString
                         stringWithCString:buf
                                  encoding:[NSString defaultCStringEncoding]]];
  }
  return array;
}

- (int)numberOfFrames {
  return parts->_stack->frameCount();
}

- (NSUInteger)routineAddressForFrame:(NSInteger)frame {
  return parts->_stack->getCallEntry(parts->_stack->frameCount() - (int)frame -
                                     1);
}

- (NSUInteger)localAtIndex:(NSUInteger)index forFrame:(NSInteger)frame {
  return parts->_stack->getFrameLocal(
      parts->_stack->frameCount() - (int)frame - 1, (int)index);
}

- (unsigned int)baseHighMemory {
  return parts->_memory->getHeader().getBaseHighMemory();
}

- (unsigned int)globalAtIndex:(unsigned int)index {
  return parts->_memory->getGlobal(index);
}

- (BOOL)isTimeGame {
  return (parts->_memory->getHeader().getFlags1() & 0x02) ? YES : NO;
}

- (unsigned int)screenWidth {
  return parts->_memory->getHeader().getScreenWidth();
}

- (void)setScreenWidth:(unsigned int)width {
  if (width > 255)
    width = 255;
  parts->_memory->getHeader().setScreenWidth(width);
}

- (unsigned int)screenHeight {
  return parts->_memory->getHeader().getScreenHeight();
}

- (void)setScreenHeight:(unsigned int)height {
  if (height > 255)
    height = 255;
  parts->_memory->getHeader().setScreenHeight(height);
}

- (BOOL)needsRedraw {
  return parts->_memory->getHeader().getRequestScreenRedraw();
}

- (void)setNeedsRedraw:(BOOL)needsRedraw {
  parts->_memory->getHeader().setRequestScreenRedraw(needsRedraw);
}

@end
