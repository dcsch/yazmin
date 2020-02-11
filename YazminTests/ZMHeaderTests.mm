//
//  ZMHeaderTests.m
//  YazminTests
//
//  Created by David Schweinsberg on 6/1/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "../Yazmin/ZMHeader.h"
#import <XCTest/XCTest.h>

@interface ZMHeaderTests : XCTestCase

@end

@implementation ZMHeaderTests

- (void)setUp {
  // Put setup code here. This method is called before the invocation of each
  // test method in the class.
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
}

- (void)testRequestScreenRedraw {
  uint8_t buf[36] = {0};
  ZMHeader header(buf);

  XCTAssertFalse(header.getRequestScreenRedraw());
  header.setRequestScreenRedraw(true);
  XCTAssertTrue(header.getRequestScreenRedraw());
  header.setRequestScreenRedraw(false);
  XCTAssertFalse(header.getRequestScreenRedraw());
}

- (void)testExtendedHeader {
  uint8_t buf[0x200] = {5};
  buf[0x36] = 0x01;
  buf[0x37] = 0x00;
  buf[0x100] = 0x12;
  buf[0x101] = 0x34;

  ZMHeader header(buf);
  uint16_t addr = header.getHeaderExtensionTableAddress();
  XCTAssertEqual(addr, 0x100);

  uint16_t len = header.getExtensionLength();
  XCTAssertEqual(len, 0x1234);
}

@end
