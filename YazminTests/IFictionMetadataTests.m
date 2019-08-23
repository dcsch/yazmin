//
//  IFictionMetadataTests.m
//  YazminTests
//
//  Created by David Schweinsberg on 8/22/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "../Yazmin/IFictionMetadata.h"
#import "../Yazmin/IFAnnotation.h"
#import "../Yazmin/IFBibliographic.h"
#import "../Yazmin/IFColophon.h"
#import "../Yazmin/IFIdentification.h"
#import "../Yazmin/IFStory.h"
#import <XCTest/XCTest.h>

@interface IFictionMetadataTests : XCTestCase

@end

@implementation IFictionMetadataTests

- (void)setUp {
}

- (void)tearDown {
}

- (void)testEmptyRecordXML {
  IFictionMetadata *metadata = [[IFictionMetadata alloc] initWithStories:@[]];
  NSString *emptyIFiction =
      @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      @"<ifindex version=\"1.0\" "
      @"xmlns=\"http://babel.ifarchive.org/protocol/iFiction/\">\n"
      @"</ifindex>\n";
  XCTAssertEqualObjects(metadata.xmlString, emptyIFiction);
}

- (void)testMinimalRecord {
  IFStory *story =
      [[IFStory alloc] initWithIFID:@"TEST-IFID-0123456789"
                           storyURL:[NSURL fileURLWithPath:@"/filename"]];
  IFictionMetadata *metadata =
      [[IFictionMetadata alloc] initWithStories:@[ story ]];
  XCTAssertNotNil(metadata.stories);
  XCTAssertEqual(metadata.stories.count, 1);
  XCTAssertNotNil(metadata.stories[0].identification);
  XCTAssertNotNil(metadata.stories[0].identification.ifids);
  XCTAssertEqual(metadata.stories[0].identification.ifids.count, 1);
  XCTAssertEqualObjects(metadata.stories[0].identification.ifids[0],
                        @"TEST-IFID-0123456789");
  XCTAssertEqualObjects(metadata.stories[0].identification.format, @"zcode");
  XCTAssertNotNil(metadata.stories[0].bibliographic);
  XCTAssertNil(metadata.stories[0].bibliographic.title);
  XCTAssertNil(metadata.stories[0].bibliographic.author);
  XCTAssertNotNil(metadata.stories[0].colophon);
  XCTAssertNotNil(metadata.stories[0].colophon.generator);
  XCTAssertNotNil(metadata.stories[0].annotation);
  XCTAssertNotNil(metadata.stories[0].annotation.yazmin);
  XCTAssertNil(metadata.stories[0].ifdb);
}

- (void)testMinimalRecordXML {
  IFStory *story =
      [[IFStory alloc] initWithIFID:@"TEST-IFID-0123456789"
                           storyURL:[NSURL fileURLWithPath:@"/filename"]];
  IFictionMetadata *metadata =
      [[IFictionMetadata alloc] initWithStories:@[ story ]];
  NSString *minimalIFiction =
      @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
      @"<ifindex version=\"1.0\" "
      @"xmlns=\"http://babel.ifarchive.org/protocol/iFiction/\">\n"
      @"<story>\n"
      @"<identification>\n"
      @"<ifid>TEST-IFID-0123456789</ifid>\n"
      @"<format>zcode</format>\n"
      @"</identification>\n"
      @"<bibliographic>\n"
      @"<title></title>\n"
      @"<author></author>\n"
      @"</bibliographic>\n"
      @"<colophon>\n"
      @"<generator>Yazmin</generator>\n"
      @"<generatorversion>1.0</generatorversion>\n"
      @"<originated>2019-08-22</originated>\n"
      @"</colophon>\n"
      @"<annotation>\n"
      @"<yazmin>\n"
      @"<story>file:///filename</story>\n"
      @"</yazmin>\n"
      @"</annotation>\n"
      @"</story>\n"
      @"</ifindex>\n";
  XCTAssertEqualObjects(metadata.xmlString, minimalIFiction);
}

- (void)testUpdateStory {
  IFStory *story1 =
      [[IFStory alloc] initWithIFID:@"TEST-IFID-0123456789"
                           storyURL:[NSURL fileURLWithPath:@"/filename"]];
  story1.bibliographic.title = @"A Tale of Two Cities";
  story1.bibliographic.headline = @"An Interactive Classic";
  story1.bibliographic.genre = @"A";
  story1.bibliographic.group = @"User-defined Group";

  IFStory *story2 =
      [[IFStory alloc] initWithIFID:@"TEST-IFID-9999999999"
                           storyURL:[NSURL fileURLWithPath:@"/filename"]];
  story2.bibliographic.author = @"Charles Dickens";
  story2.bibliographic.genre = @"B";
  story2.bibliographic.group = @"Default Group";

  [story1 updateFromStory:story2];

  XCTAssertEqualObjects(story1.bibliographic.title, @"A Tale of Two Cities");
  XCTAssertEqualObjects(story1.bibliographic.author, @"Charles Dickens");
  XCTAssertEqualObjects(story1.bibliographic.headline,
                        @"An Interactive Classic");
  XCTAssertEqualObjects(story1.bibliographic.genre, @"B");
  XCTAssertEqualObjects(story1.bibliographic.group, @"User-defined Group");

  story1.bibliographic.group = nil;
  [story1 updateFromStory:story2];

  XCTAssertEqualObjects(story1.bibliographic.group, @"Default Group");
}

@end
