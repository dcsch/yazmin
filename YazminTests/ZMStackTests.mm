//
//  ZMStackTests.m
//  YazminTests
//
//  Created by David Schweinsberg on 6/7/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "../Yazmin/ZMStack.h"
#import <XCTest/XCTest.h>

@interface ZMStackTests : XCTestCase

@end

@implementation ZMStackTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testBasics {
  ZMStack stack;
  stack.push(1);
  stack.push(2);
  stack.push(3);
  XCTAssertEqual(stack.getStackPointer(), 3);
  XCTAssertEqual(stack.getEntry(0), 1);
  XCTAssertEqual(stack.getEntry(1), 2);
  XCTAssertEqual(stack.getEntry(2), 3);
  XCTAssertEqual(stack.getTop(), 3);

  XCTAssertEqual(stack.pop(), 3);
  XCTAssertEqual(stack.getStackPointer(), 2);

  XCTAssertEqual(stack.pop(), 2);
  XCTAssertEqual(stack.getStackPointer(), 1);

  XCTAssertEqual(stack.pop(), 1);
  XCTAssertEqual(stack.getStackPointer(), 0);
}

// The Yazmin stack is made up of frames that look like the following
// (before anything is pushed onto the evaluation stack):
// _fp -> RETURN_ADDR_MSW
//        RETURN_ADDR_LSW
//        RETURN_STORE
//        PREV_FRAME_POINTER
//        ARG_COUNT
//        LOCAL_VARIABLE_COUNT
//        LOCAL_VARIABLE_1
//        ...
//        LOCAL_VARIABLE_N
// _sp -> (Evaluation Stack)

- (void)testFrame {
  ZMStack stack;

  XCTAssertEqual(stack.getFramePointer(), 0);
  XCTAssertEqual(stack.getStackPointer(), 0);
  XCTAssertEqual(stack.getFrameCount(), 0);

  // void pushFrame(uint32_t returnAddr,
  //                int argCount,
  //                int localCount,
  //                uint16_t returnStore);

  // 0 argument, 0 locals
  stack.pushFrame(123456, 0, 0, 1);

  XCTAssertEqual(stack.getFramePointer(), 0);
  XCTAssertEqual(stack.getStackPointer(), 6);
  XCTAssertEqual(stack.getFrameCount(), 1);

  XCTAssertEqual(stack.getArgCount(), 0);
  XCTAssertEqual(stack.getLocalCount(), 0);

  // 2 argument, 3 locals (which incorporates the 2 args)
  stack.pushFrame(234567, 2, 3, 4);

  XCTAssertEqual(stack.getFramePointer(), 6);
  XCTAssertEqual(stack.getStackPointer(), 15);
  XCTAssertEqual(stack.getFrameCount(), 2);

  XCTAssertEqual(stack.getArgCount(), 2);
  XCTAssertEqual(stack.getLocalCount(), 3);

  XCTAssertEqual(stack.getLocal(0), 0);
  XCTAssertEqual(stack.getLocal(1), 0);
  XCTAssertEqual(stack.getLocal(2), 0);

  stack.setLocal(0, 5);
  stack.setLocal(1, 6);
  stack.setLocal(2, 7);

  XCTAssertEqual(stack.getLocal(0), 5);
  XCTAssertEqual(stack.getLocal(1), 6);
  XCTAssertEqual(stack.getLocal(2), 7);

  uint16_t resultStore;
  uint32_t addr = stack.popFrame(&resultStore);
  XCTAssertEqual(addr, 234567);
  XCTAssertEqual(resultStore, 4);

  XCTAssertEqual(stack.getFramePointer(), 0);
  XCTAssertEqual(stack.getStackPointer(), 6);
  XCTAssertEqual(stack.getFrameCount(), 1);

  XCTAssertEqual(stack.getArgCount(), 0);
  XCTAssertEqual(stack.getLocalCount(), 0);

  addr = stack.popFrame(&resultStore);
  XCTAssertEqual(addr, 123456);
  XCTAssertEqual(resultStore, 1);

  XCTAssertEqual(stack.getFramePointer(), 0);
  XCTAssertEqual(stack.getStackPointer(), 0);
  XCTAssertEqual(stack.getFrameCount(), 0);
}

- (void)testFramePointers {
  ZMStack stack;

  // 0 argument, 0 locals
  stack.pushFrame(123456, 0, 0, 1);

  // 2 argument, 3 locals (which incorporates the 2 args)
  stack.pushFrame(234567, 2, 3, 4);

  // 1 argument, 1 local
  stack.pushFrame(345678, 1, 1, 1);

  // 0 argument, 0 locals
  stack.pushFrame(123456, 0, 0, 1);

  XCTAssertEqual(stack.getFrameCount(), 4);

  auto framePointers = stack.getFramePointers();
  XCTAssertEqual(framePointers[0], 0);
  XCTAssertEqual(framePointers[1], 6);
  XCTAssertEqual(framePointers[2], 15);
  XCTAssertEqual(framePointers[3], 22);
}

@end
