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

- (instancetype)initWithTitle:(NSString *)title {
  self = [super init];
  if (self) {
    _bibliographic = [[IFBibliographic alloc] initWithTitle:title];
  }
  return self;
}

@end
