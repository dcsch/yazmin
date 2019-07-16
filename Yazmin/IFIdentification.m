//
//  IFIdentification.m
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFIdentification.h"

@implementation IFIdentification

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
  self = [super init];
  if (self) {
    NSMutableArray<NSString *> *ifids = [[NSMutableArray alloc] init];
    _format = @"";

    NSEnumerator *enumChildren = [element.children objectEnumerator];
    NSXMLNode *node;
    while ((node = [enumChildren nextObject])) {
      if ([node.name compare:@"ifid"] == 0)
        [ifids addObject:node.stringValue];
      else if ([node.name compare:@"format"] == 0) {
        _format = node.stringValue;
      } else if ([node.name compare:@"bafn"] == 0)
        _bafn = node.stringValue.intValue;
    }
    _ifids = ifids;
  }
  return self;
}

@end
