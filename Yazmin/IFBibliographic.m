//
//  IFBibliographic.m
//  Yazmin
//
//  Created by David Schweinsberg on 25/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "IFBibliographic.h"

@implementation IFBibliographic

- (instancetype)initWithXMLElement:(NSXMLElement *)element {
  self = [super init];
  if (self) {
    NSEnumerator *enumChildren = [element.children objectEnumerator];
    NSXMLNode *node;
    while ((node = [enumChildren nextObject])) {
      if ([node.name compare:@"title"] == 0) {
        _title = node.stringValue;
      } else if ([node.name compare:@"author"] == 0) {
        _author = node.stringValue;
      } else if ([node.name compare:@"language"] == 0) {
        _language = node.stringValue;
      } else if ([node.name compare:@"headline"] == 0) {
        _headline = node.stringValue;
      } else if ([node.name compare:@"firstpublished"] == 0) {
        _firstPublished = node.stringValue;
      } else if ([node.name compare:@"genre"] == 0) {
        _genre = node.stringValue;
      } else if ([node.name compare:@"group"] == 0) {
        _group = node.stringValue;
      } else if ([node.name compare:@"description"] == 0) {
        _storyDescription = node.stringValue;
      } else if ([node.name compare:@"series"] == 0) {
        _series = node.stringValue;
      } else if ([node.name compare:@"seriesnumber"] == 0) {
        _seriesNumber = node.stringValue.intValue;
      } else if ([node.name compare:@"forgiveness"] == 0) {
        _forgiveness = node.stringValue;
      }
    }
  }
  return self;
}

- (instancetype)initWithTitle:(NSString *)title {
  self = [super init];
  if (self) {
    _title = title;
  }
  return self;
}

@end
