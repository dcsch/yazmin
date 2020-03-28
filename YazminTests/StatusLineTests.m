//
//  StatusLineTests.m
//  YazminTests
//
//  Created by David Schweinsberg on 3/27/20.
//  Copyright © 2020 David Schweinsberg. All rights reserved.
//

#import "../Yazmin/Story.h"
#import "../Yazmin/StoryFacet.h"
#import "../Yazmin/ZMachine.h"
#import <XCTest/XCTest.h>

@interface StatusLineTests : XCTestCase {
  NSData *data;
}
@end

@implementation StatusLineTests

- (void)setUp {
  uint8_t buf[0x200] = {3, 2}; // v3, time game
  // Location of object table
  buf[0x0a] = 0x01;
  buf[0x0b] = 0x10;
  // Location of globals
  buf[0x0c] = 0x01;
  buf[0x0d] = 0x00;

  // Globals
  // Object 1
  buf[0x100] = 0x00;
  buf[0x101] = 0x01;
  // 02:03 AM
  buf[0x102] = 0x00;
  buf[0x103] = 0x02;
  buf[0x104] = 0x00;
  buf[0x105] = 0x03;

  // Object table
  // Property Defaults Table
  // 0x110 - 0x14E (62 bytes)
  // Attributes
  buf[0x14E] = 0;
  buf[0x14F] = 0;
  buf[0x150] = 0;
  buf[0x151] = 0;
  // Parent
  buf[0x152] = 0;
  // Sibling
  buf[0x153] = 0;
  // Child
  buf[0x154] = 0;
  // Properties address
  buf[0x155] = 0x01;
  buf[0x156] = 0x60;

  // Properties (foo)
  buf[0x160] = 2;
  buf[0x161] = 0b10101110;
  buf[0x162] = 0b10010100;

  data = [NSData dataWithBytes:buf length:0x200];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
}

- (void)testTimeStatus {
  Story *story = [[Story alloc] init];
  [story readFromData:data ofType:@"" error:nil];
  story.facets[1].widthInCharacters = 40;
  story.facets[1].heightInLines = 1;
  [story showStatus];
  XCTAssertEqualObjects(story.facets[1].textStorage.string,
                        @" foo                           2:03 AM  ");

  [story.zMachine setGlobal:8 atIndex:1];
  [story.zMachine setGlobal:0 atIndex:2];
  [story showStatus];
  XCTAssertEqualObjects(story.facets[1].textStorage.string,
                        @" foo                           8:00 AM  ");

  [story.zMachine setGlobal:0 atIndex:1];
  [story.zMachine setGlobal:11 atIndex:2];
  [story showStatus];
  XCTAssertEqualObjects(story.facets[1].textStorage.string,
                        @" foo                           12:11 AM ");

  [story.zMachine setGlobal:12 atIndex:1];
  [story.zMachine setGlobal:11 atIndex:2];
  [story showStatus];
  XCTAssertEqualObjects(story.facets[1].textStorage.string,
                        @" foo                           12:11 PM ");

  [story.zMachine setGlobal:111 atIndex:1];
  [story.zMachine setGlobal:99 atIndex:2];
  [story showStatus];
  XCTAssertEqualObjects(story.facets[1].textStorage.string,
                        @" foo                           99:99 PM ");

  [story close];
}

@end
