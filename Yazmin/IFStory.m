//
//  IFStory.m
//  Yazmin
//
//  Created by David Schweinsberg on 26/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFStory.h"
#import "IFBibliographic.h"
#import "IFIdentification.h"

@implementation IFStory

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
  self = [super init];
  if (self) {
    NSXMLElement *idElement = [element elementsForName:@"identification"][0];
    _identification = [[IFIdentification alloc] initWithXMLElement:idElement];

    NSXMLElement *biblioElement = [element elementsForName:@"bibliographic"][0];
    _bibliographic = [[IFBibliographic alloc] initWithXMLElement:biblioElement];
  }
  return self;
}

- (NSString *)xmlString {
  NSMutableString *string = [NSMutableString string];
  [string appendString:@"<story>\n"];
  [string appendString:_identification.xmlString];
  [string appendString:_bibliographic.xmlString];
  [string appendString:@"</story>\n"];
  return string;
}

@end
