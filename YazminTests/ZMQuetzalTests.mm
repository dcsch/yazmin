//
//  ZMQuetzalTests.m
//  YazminTests
//
//  Created by David Schweinsberg on 6/7/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "../Yazmin/ZMQuetzal.h"
#include "../Yazmin/ZMMemory.h"
#include "../Yazmin/ZMStack.h"
#import <XCTest/XCTest.h>

@interface ZMQuetzalTests : XCTestCase

@end

@implementation ZMQuetzalTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testFrame {
  ZMStack stack;

  XCTAssertEqual(stack.getFramePointer(), 0);
  XCTAssertEqual(stack.getStackPointer(), 0);
  XCTAssertEqual(stack.getFrameCount(), 0);

  // void pushFrame(uint32_t returnAddr,
  //                uint8_t flags,
  //                uint8_t resultVariable,
  //                uint8_t argsSupplied,
  //                uint16_t evalCount,
  //                uint8_t *varsAndEval);

  uint8_t dummyEval[] = {0x01, 0x23, 0x04, 0x56, 0x07, 0x89};

  // 0 argument, 0 locals, 3 eval
  stack.pushFrame(123456, 0x00, 0, 0, 3, dummyEval);

  XCTAssertEqual(stack.getFramePointer(), 0);
  XCTAssertEqual(stack.getStackPointer(), 9); // 6 frame + 3 eval
  XCTAssertEqual(stack.getFrameCount(), 1);

  XCTAssertEqual(stack.getArgCount(), 0);
  XCTAssertEqual(stack.getLocalCount(), 0);

  XCTAssertEqual(stack.pop(), 0x0789);
  XCTAssertEqual(stack.pop(), 0x0456);

  uint8_t dummyEval2[] = {0x01, 0x11, 0x02, 0x22, 0x03, 0x33,
                          0x04, 0x44, 0x06, 0x66, 0x09, 0x99};

  // 2 argument, 3 locals, 3 eval, no return
  stack.pushFrame(234567, 0x13, 0, 0b00000011, 3, dummyEval2);

  XCTAssertEqual(stack.getFramePointer(), 7);
  XCTAssertEqual(stack.getStackPointer(), 19);
  XCTAssertEqual(stack.getFrameCount(), 2);

  XCTAssertEqual(stack.getArgCount(), 2);
  XCTAssertEqual(stack.getLocalCount(), 3);

  XCTAssertEqual(stack.getLocal(0), 0x0111);
  XCTAssertEqual(stack.getLocal(1), 0x0222);
  XCTAssertEqual(stack.getLocal(2), 0x0333);

  XCTAssertEqual(stack.pop(), 0x0999);
  XCTAssertEqual(stack.pop(), 0x0666);

  uint16_t resultStore;
  uint32_t addr = stack.popFrame(&resultStore);
  XCTAssertEqual(addr, 234567);
  XCTAssertEqual(resultStore, 0xffff);

  XCTAssertEqual(stack.pop(), 0x0123);

  addr = stack.popFrame(&resultStore);
  XCTAssertEqual(addr, 123456);
  XCTAssertEqual(resultStore, 0);
}

- (void)testCreateCMemChunk {

  const size_t dataLen = 0x1000;
  uint8_t data[dataLen];
  memset(data, 0, dataLen);

  // Set up a header
  data[0] = 5;

  data[0x0e] = 0x10; // base static memory (limit of dynamic memory)
  data[0x0f] = 0x00;

  data[0x1a] = 0x04; // file length / 4
  data[0x1b] = 0x00;

  // Set the test memory into some initial state
  for (size_t i = 0x40; i < dataLen; i += 2) {
    data[i] = 0xee;
    data[i + 1] = 0xff;
  }

  ZMStack stack;
  ZMMemory memory(data, dataLen);

  ZMQuetzal quetzal(memory, stack);

  uint8_t *rleBuf;
  size_t rleLen;
  quetzal.createCMemChunk(&rleBuf, &rleLen);

  uint8_t rle[] = {0x00, 0x00, 0x9d, 0x00, 0x1b, 0x03, 0x5a, 0x21, 0x5e,
                   0x00, 0x00, 0x5e, 0x00, 0x00, 0x21, 0x01, 0x01, 0x00,
                   0x03, 0x09, 0x02, 0x00, 0x03, 0x01, 0x01};

  XCTAssertEqual(rleLen, sizeof rle);
  for (size_t i = 0; i < rleLen; ++i)
    XCTAssertEqual(rleBuf[i], rle[i]);

  // Grab a snapshot of the data as it stands
  uint8_t dataCopy[dataLen];
  memcpy(dataCopy, memory.getData(), dataLen);

  // Now mess with the data - this should be erased when we restore
  // with the extraction
  memory.setByte(100, 0);
  memory.setByte(200, 0);
  memory.setByte(300, 0);

  // Restore the data
  quetzal.extractCMemChunk(rleBuf, rleLen);

  for (uint32_t i = 0; i < dataLen; ++i)
    XCTAssertEqual(memory.getByte(i), dataCopy[i]);
}

@end
