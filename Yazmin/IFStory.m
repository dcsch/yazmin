//
//  IFStory.m
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFStory.h"
#import "IFBibliographic.h"
#import "IFColophon.h"
#import "IFIdentification.h"

@implementation IFStory

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
  self = [super init];
  if (self) {
    NSXMLElement *idElement = [element elementsForName:@"identification"][0];
    _identification = [[IFIdentification alloc] initWithXMLElement:idElement];

    NSXMLElement *biblioElement = [element elementsForName:@"bibliographic"][0];
    _bibliographic = [[IFBibliographic alloc] initWithXMLElement:biblioElement];

    NSArray<NSXMLElement *> *elements = [element elementsForName:@"colophon"];
    if (elements.count > 0) {
      NSXMLElement *colophonElement = elements[0];
      _colophon = [[IFColophon alloc] initWithXMLElement:colophonElement];
    }
  }
  return self;
}

- (instancetype)initWithIFID:(NSString *)ifid {
  self = [super init];
  if (self) {
    _identification = [[IFIdentification alloc] initWithIFID:ifid];
    _bibliographic = [[IFBibliographic alloc] init];
    _colophon = [[IFColophon alloc] init];
  }
  return self;
}

- (void)updateFromStory:(IFStory *)story {
  _identification = story.identification;
  _bibliographic = story.bibliographic;
  _colophon = story.colophon;
}

- (NSString *)xmlString {
  NSMutableString *string = [NSMutableString string];
  [string appendString:@"<story>\n"];
  [string appendString:_identification.xmlString];
  [string appendString:_bibliographic.xmlString];
  if (_colophon)
    [string appendString:_colophon.xmlString];
  [string appendString:@"</story>\n"];
  return string;
}

@end
