//
//  StoryTests.m
//  YazminTests
//
//  Created by David Schweinsberg on 3/26/20.
//  Copyright © 2020 David Schweinsberg. All rights reserved.
//

#import "../Yazmin/Story.h"
#import "../Yazmin/StoryFacet.h"
#import "../Yazmin/ZMachine.h"
#import <XCTest/XCTest.h>

@interface StoryTests : XCTestCase {
  NSBundle *testBundle;
}
@end

@implementation StoryTests

- (void)setUp {
  testBundle = [NSBundle bundleForClass:StoryTests.class];
}

- (void)tearDown {
}

- (void)testHelloWorld {
  NSURL *url = [testBundle URLForResource:@"hello"
                            withExtension:@"z5"
                             subdirectory:nil];
  NSData *data = [NSData dataWithContentsOfURL:url];
  Story *story = [[Story alloc] init];
  [story readFromData:data ofType:@"" error:nil];
  [story.zMachine executeUntilHalt];
  XCTAssertEqualObjects(story.facets[0].textStorage.string, @"Hello, world!");
  [story close];
}

@end
