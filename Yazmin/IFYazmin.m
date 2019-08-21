//
//  IFYazmin.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/20/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "IFYazmin.h"

@implementation IFYazmin

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
  self = [super init];
  if (self) {
    NSEnumerator *enumChildren = [element.children objectEnumerator];
    NSXMLNode *node;
    while ((node = [enumChildren nextObject])) {
      if ([node.name compare:@"story"] == 0) {
        _story = [NSURL URLWithString:node.stringValue];
      } else if ([node.name compare:@"graphics"] == 0) {
        _graphics = [NSURL URLWithString:node.stringValue];
      } else if ([node.name compare:@"sound"] == 0) {
        _sound = [NSURL URLWithString:node.stringValue];
      }
    }
  }
  return self;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _story = [NSURL URLWithString:@""];
  }
  return self;
}

- (NSString *)xmlString {
  NSMutableString *string = [NSMutableString string];
  [string appendString:@"<yazmin>\n"];
  [string appendFormat:@"<story>%@</story>\n", _story];
  if (_graphics)
    [string appendFormat:@"<graphics>%@</graphics>\n", _graphics];
  if (_sound)
    [string appendFormat:@"<sound>%@</sound>\n", _sound];
  [string appendString:@"</yazmin>\n"];
  return string;
}

@end
