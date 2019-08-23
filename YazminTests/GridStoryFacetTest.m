//
//  GridStoryFacetTest.m
//  YazminTests
//
//  Created by David Schweinsberg on 5/20/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "../Yazmin/GridStoryFacet.h"
#import <XCTest/XCTest.h>

@interface GridStoryFacetTest : XCTestCase {
  GridStoryFacet *facet;
}
@end

@implementation GridStoryFacetTest

- (void)setUp {
  facet = [[GridStoryFacet alloc] initWithStory:nil];
  facet.widthInCharacters = 80;
  facet.heightInLines = 25;
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each
  // test method in the class.
}

- (void)testStartOfBuffer {
  [facet print:@"This is a test"];
  XCTAssertTrue([facet.textStorage.string isEqualToString:@"This is a test"]);
}

- (void)testOneLineDown {
  [facet setCursorLine:2 column:1];
  [facet print:@"This is a test"];
  XCTAssertTrue([facet.textStorage.string isEqualToString:@"\nThis is a test"]);
}

- (void)testTwoLinesDown {
  [facet setCursorLine:3 column:1];
  [facet print:@"This is a test"];
  XCTAssertTrue(
      [facet.textStorage.string isEqualToString:@"\n\nThis is a test"]);
}

- (void)testTwoLinesDownThreeAcross {
  [facet setCursorLine:3 column:4];
  [facet print:@"This is a test"];
  XCTAssertTrue(
      [facet.textStorage.string isEqualToString:@"\n\n   This is a test"]);
}

- (void)testAppendToExistingLine {
  [facet.textStorage.mutableString appendString:@"\n\nThird Line"];
  [facet print:@"First Line"];
  XCTAssertTrue(
      [facet.textStorage.string isEqualToString:@"First Line\n\nThird Line"]);
}

- (void)testInsertToExistingLine {
  [facet.textStorage.mutableString
      appendString:@"\n\n                    Third Line"];
  [facet setCursorLine:3 column:1];
  [facet print:@"Still in Third Line"];
  XCTAssertTrue([facet.textStorage.string
      isEqualToString:@"\n\nStill in Third Line Third Line"]);
}

- (void)testInsertIntoShortLine {
  [facet.textStorage.mutableString appendString:@"\n\nExisting Line"];
  [facet setCursorLine:3 column:10];
  [facet print:@"Line is now longer"];
  XCTAssertTrue([facet.textStorage.string
      isEqualToString:@"\n\nExisting Line is now longer"]);
}

- (void)testInsertIntoLongLine {
  [facet.textStorage.mutableString
      appendString:@"\n\nExisting Line is long enough"];
  [facet setCursorLine:3 column:9];
  [facet print:@"x"];
  [facet setCursorLine:3 column:14];
  [facet print:@"x"];
  [facet setCursorLine:3 column:17];
  [facet print:@"x"];
  [facet setCursorLine:3 column:22];
  [facet print:@"x"];
  XCTAssertTrue([facet.textStorage.string
      isEqualToString:@"\n\nExistingxLinexisxlongxenough"]);
}

- (void)testExtendLine {
  [facet.textStorage.mutableString appendString:@"\n\nExisting Line"];
  [facet setCursorLine:3 column:15];
  [facet print:@"is now longer"];
  XCTAssertTrue([facet.textStorage.string
      isEqualToString:@"\n\nExisting Line is now longer"]);
}

- (void)testUpdateCursorPosition {
  [facet print:@"First"];
  [facet print:@"Second"];
  [facet print:@"Third"];
  XCTAssertTrue([facet.textStorage.string isEqualToString:@"FirstSecondThird"]);
}

- (void)testMixedOutput {
  [facet print:@"One: "];
  [facet printNumber:1];
  [facet print:@", Two: "];
  [facet printNumber:2];
  XCTAssertTrue([facet.textStorage.string isEqualToString:@"One: 1, Two: 2"]);
}

- (void)testLineWrap {
  facet.widthInCharacters = 30;
  [facet setCursorLine:2 column:28];
  [facet print:@"Thisshouldbesplit"];
  [facet print:@"Another line"];
  XCTAssertTrue([facet.textStorage.string
      isEqualToString:
          @"\n                           Thi\nsshouldbesplitAnother line"]);
}

- (void)testMultipleLines {
  facet = [[GridStoryFacet alloc] initWithStory:nil];
  facet.widthInCharacters = 80;
  facet.heightInLines = 25;
  [facet setCursorLine:1 column:1];
  [facet print:@"Information is available on the following subjects:\n\n"
               @"Instructions    giving some basic information\n"
               @"Commands        detailing some common commands\n"
               @"Credits         game credits\n"
               @"Release         release notes\n"
               @"Legal           legal disclaimers\n"
               @"Inform          advertising the compiler Inform\n"
               @"Archive         and the interactive fiction archive\n"];
  XCTAssertTrue([facet.textStorage.string
      isEqualToString:
          @"Information is available on the following subjects:\n\n"
          @"Instructions    giving some basic information\n"
          @"Commands        detailing some common commands\n"
          @"Credits         game credits\n"
          @"Release         release notes\n"
          @"Legal           legal disclaimers\n"
          @"Inform          advertising the compiler Inform\n"
          @"Archive         and the interactive fiction archive\n"]);
}

@end
