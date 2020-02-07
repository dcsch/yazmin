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

- (void)testDecode {
  uint8_t buf[36] = {3};
  ZMText text(buf);

  //  --first byte-------   --second byte---
  //  7    6 5 4 3 2  1 0   7 6 5  4 3 2 1 0
  //  bit  --first--  --second---  --third--

  const uint8_t data[] = {0b10011000, 0b11101000}; // 'abc'
  size_t encodedLen;
  std::string str = text.decodeZCharsToZscii(data, encodedLen);
  NSString *objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"abc");
  XCTAssertEqual(encodedLen, 2);

  const uint8_t data2[] = {0b00011000, 0b11101000, 0b10100101,
                           0b01001011}; // 'abcdef'
  str = text.decodeZCharsToZscii(data2, encodedLen);
  objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"abcdef");
  XCTAssertEqual(encodedLen, 4);

  const uint8_t data3[] = {0b00011000, 0b11100101, 0b10011101,
                           0b01001011}; // 'ab\nef'
  str = text.decodeZCharsToZscii(data3, encodedLen);
  objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"ab\nef");
  XCTAssertEqual(encodedLen, 4);
}

- (void)testEncode {
  uint8_t buf[36] = {3};
  ZMText text(buf);

  uint8_t encodedData[255];
  memset(encodedData, 0xff, 255);
  text.encodeZsciiToZchars(encodedData, "abc", 3, 6);
  XCTAssertEqual(encodedData[0], 0b00011000); // 'a','b...'
  XCTAssertEqual(encodedData[1], 0b11101000); // '...b','c'
  XCTAssertEqual(encodedData[2], 0b00010100); // 5,5...
  XCTAssertEqual(encodedData[3], 0b10100101); // ...5,5
  XCTAssertEqual(encodedData[4], 0b10010100); // end-of-string,5,5...
  XCTAssertEqual(encodedData[5], 0b10100101); // ...5,5
  XCTAssertEqual(encodedData[6], 0xff);

  memset(encodedData, 0xff, 255);
  text.encodeZsciiToZchars(encodedData, "abcdef", 6, 6);
  XCTAssertEqual(encodedData[0], 0b00011000); // 'a','b...'
  XCTAssertEqual(encodedData[1], 0b11101000); // '...b','c'
  XCTAssertEqual(encodedData[2], 0b00100101); // 'd','e...'
  XCTAssertEqual(encodedData[3], 0b01001011); // '...e','f'
  XCTAssertEqual(encodedData[4], 0b10010100); // end-of-string,5,5...
  XCTAssertEqual(encodedData[5], 0b10100101); // ...5,5
  XCTAssertEqual(encodedData[6], 0xff);
}

- (void)testAbbreviations {
  uint8_t buf[36 + 4 + 8] = {3};

  // Set the abbreviations table location
  buf[0x19] = 36;

  buf[36] = 0;
  buf[37] = 20; // word address (40 / 2)
  buf[38] = 0;
  buf[39] = 22; // word address (44 / 2)

  // 'abcdef'
  buf[40] = 0b00011000;
  buf[41] = 0b11101000;
  buf[42] = 0b10100101;
  buf[43] = 0b01001011;

  // 'ab\nef'
  buf[44] = 0b00011000;
  buf[45] = 0b11100101;
  buf[46] = 0b10011101;
  buf[47] = 0b01001011;

  ZMText text(buf);
  auto str = text.abbreviation(0);
  NSString *objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"abcdef");

  str = text.abbreviation(1);
  objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"ab\nef");
}

- (void)testZCharToZscii_v3 {
  uint8_t buf[36 + 4 + 8] = {3};

  // Set the abbreviations table location
  buf[0x19] = 36;

  buf[36] = 0;
  buf[37] = 20; // word address (40 / 2)
  buf[38] = 0;
  buf[39] = 22; // word address (44 / 2)

  // 'abcdef'
  buf[40] = 0b00011000;
  buf[41] = 0b11101000;
  buf[42] = 0b10100101;
  buf[43] = 0b01001011;

  // 'ab\nef'
  buf[44] = 0b00011000;
  buf[45] = 0b11100101;
  buf[46] = 0b10011101;
  buf[47] = 0b01001011;

  ZMText text(buf);
  std::string str;

  // Abbreviations (3.3)
  str.clear();
  text.zCharToZscii(1, str);
  text.zCharToZscii(0, str);
  NSString *objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"abcdef");

  str.clear();
  text.zCharToZscii(1, str);
  text.zCharToZscii(1, str);
  objcstr = [NSString stringWithUTF8String:str.c_str()];
  XCTAssertEqualObjects(objcstr, @"ab\nef");

  // 3.5.1
  str.clear();
  text.zCharToZscii(0, str);
  XCTAssertEqual(str.length(), 1);
  XCTAssertEqual(str[0], ' ');

  // 3.5.3
  std::string A0 = "abcdefghijklmnopqrstuvwxyz";
  for (int i = 0; i < 26; ++i) {
    str.clear();
    text.zCharToZscii(i + 6, str);
    XCTAssertEqual(str.length(), 1);
    XCTAssertEqual(str[0], A0[i]);
  }

  std::string A1 = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  for (int i = 0; i < 26; ++i) {
    str.clear();
    text.zCharToZscii(4, str);
    text.zCharToZscii(i + 6, str);
    XCTAssertEqual(str.length(), 1);
    XCTAssertEqual(str[0], A1[i]);
  }

  std::string A2 = " \n0123456789.,!?_#'\"/\\-:()";
  for (int i = 1; i < 26; ++i) {
    str.clear();
    text.zCharToZscii(5, str);
    text.zCharToZscii(i + 6, str);
    XCTAssertEqual(str.length(), 1);
    XCTAssertEqual(str[0], A2[i]);
  }
}

- (void)testZsciiToZChar_v3 {
  uint8_t buf[36] = {3};
  ZMText text(buf);
  uint8_t zchar[2];
  int len;

  len = text.zsciiToZChar('a', zchar);
  XCTAssertEqual(len, 1);
  XCTAssertEqual(zchar[0], 6);

  len = text.zsciiToZChar('b', zchar);
  XCTAssertEqual(len, 1);
  XCTAssertEqual(zchar[0], 7);

  len = text.zsciiToZChar('c', zchar);
  XCTAssertEqual(len, 1);
  XCTAssertEqual(zchar[0], 8);

  len = text.zsciiToZChar('A', zchar);
  XCTAssertEqual(len, 2);
  XCTAssertEqual(zchar[0], 4);
  XCTAssertEqual(zchar[1], 6);

  len = text.zsciiToZChar('B', zchar);
  XCTAssertEqual(len, 2);
  XCTAssertEqual(zchar[0], 4);
  XCTAssertEqual(zchar[1], 7);

  len = text.zsciiToZChar('C', zchar);
  XCTAssertEqual(len, 2);
  XCTAssertEqual(zchar[0], 4);
  XCTAssertEqual(zchar[1], 8);

  len = text.zsciiToZChar('\n', zchar);
  XCTAssertEqual(len, 2);
  XCTAssertEqual(zchar[0], 5);
  XCTAssertEqual(zchar[1], 7);

  len = text.zsciiToZChar('0', zchar);
  XCTAssertEqual(len, 2);
  XCTAssertEqual(zchar[0], 5);
  XCTAssertEqual(zchar[1], 8);

  len = text.zsciiToZChar('1', zchar);
  XCTAssertEqual(len, 2);
  XCTAssertEqual(zchar[0], 5);
  XCTAssertEqual(zchar[1], 9);
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
