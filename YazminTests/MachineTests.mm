//
//  MachineTests.mm
//  YazminTests
//
//  Created by David Schweinsberg on 11/29/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "../Yazmin/ZMError.h"
#include "../Yazmin/ZMProcessor.h"
#include "TestIO.h"
#include "TestMachine.h"
#import <XCTest/XCTest.h>

class MachineTestIO : public TestIO {
public:
  NSMutableString *buffer;
  uint16_t restoreOrSaveResult;

  MachineTestIO() : buffer([NSMutableString string]) {}

  void print(const std::string &str) override {
    [buffer appendString:[NSString stringWithUTF8String:str.c_str()]];
  }

  void printNumber(int number) override {
    [buffer appendString:[NSString stringWithFormat:@"%d", number]];
  }

  uint16_t endRestore(const uint8_t **data, size_t *length) const override {
    return restoreOrSaveResult;
  }

  uint16_t getRestoreOrSaveResult() override { return restoreOrSaveResult; }
};

class MachineTestError : public ZMError {
public:
  std::string buffer;

  void error(const std::string &message) override { buffer += message; }
};

@interface MachineTests : XCTestCase {
  NSBundle *testBundle;
}
@end

@implementation MachineTests

- (void)setUp {
  testBundle = [NSBundle bundleForClass:MachineTests.class];
}

- (void)tearDown {
}

- (void)testHelloWorld {
  NSURL *url = [testBundle URLForResource:@"hello"
                            withExtension:@"z5"
                             subdirectory:nil];
  NSData *data = [NSData dataWithContentsOfURL:url];
  MachineTestIO io;
  MachineTestError err;
  TestMachine machine((const uint8_t *)data.bytes, data.length, io, err);
  machine.getProcessor().executeUntilHalt();
  XCTAssertEqualObjects(io.buffer, @"Hello, world!");
}

- (void)testRestoreCanceled {
  NSURL *url = [testBundle URLForResource:@"restore_v5"
                            withExtension:@"z5"
                             subdirectory:nil];
  NSData *data = [NSData dataWithContentsOfURL:url];
  MachineTestIO io;
  MachineTestError err;
  TestMachine machine((const uint8_t *)data.bytes, data.length, io, err);
  machine.getProcessor().executeUntilHalt();
  io.restoreOrSaveResult = 0;
  machine.getProcessor().executeUntilHalt();
  XCTAssertEqualObjects(io.buffer, @"123");
}

@end
