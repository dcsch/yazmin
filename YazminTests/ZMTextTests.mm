//
//  ZMTextTests.m
//  YazminTests
//
//  Created by David Schweinsberg on 6/11/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#include "../Yazmin/ZMText.h"
#import <XCTest/XCTest.h>

@interface ZMTextTests : XCTestCase

@end

@implementation ZMTextTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testAppendAsUTF8 {
  std::string str;
  ZMText::appendAsUTF8(str, L'a');
  ZMText::appendAsUTF8(str, L'b');
  ZMText::appendAsUTF8(str, L'c');
  ZMText::appendAsUTF8(str, L'€');
  ZMText::appendAsUTF8(str, L'¢');
  ZMText::appendAsUTF8(str, L'£');
  ZMText::appendAsUTF8(str, L'x');
  ZMText::appendAsUTF8(str, L'y');
  ZMText::appendAsUTF8(str, L'z');

  NSString *objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"abc€¢£xyz");
}

@end
