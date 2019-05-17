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
    identification = [[IFIdentification alloc] initWithXMLElement:idElement];

    NSXMLElement *biblioElement = [element elementsForName:@"bibliographic"][0];
    bibliographic = [[IFBibliographic alloc] initWithXMLElement:biblioElement];
  }
  return self;
}

- (IFIdentification *)identification {
  return identification;
}

- (IFBibliographic *)bibliographic {
  return bibliographic;
}

@end
