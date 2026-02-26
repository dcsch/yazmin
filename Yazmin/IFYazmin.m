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
        _storyURL = [NSURL URLWithString:node.stringValue];
      } else if ([node.name compare:@"bookmark"] == 0) {
        NSData *decoded = [[NSData alloc] initWithBase64EncodedString:node.stringValue
                                                              options:0];
        if (decoded)
          _storyBookmarkData = decoded;
        else
          NSLog(@"Warning: failed to decode bookmark base64 data");
      } else if ([node.name compare:@"blorb"] == 0) {
        _blorbURL = [NSURL URLWithString:node.stringValue];
      } else if ([node.name compare:@"graphics"] == 0) {
        _graphicsURL = [NSURL URLWithString:node.stringValue];
      } else if ([node.name compare:@"sound"] == 0) {
        _soundURL = [NSURL URLWithString:node.stringValue];
      }
    }
  }
  return self;
}

- (NSString *)xmlString {
  NSMutableString *string = [NSMutableString string];
  [string appendString:@"<yazmin>\n"];
  if (_storyURL)
    [string appendFormat:@"<story>%@</story>\n", _storyURL.URLByStandardizingPath];
  if (_storyBookmarkData)
    [string appendFormat:@"<bookmark>%@</bookmark>\n",
     [_storyBookmarkData base64EncodedStringWithOptions:0]];
  if (_blorbURL)
    [string appendFormat:@"<blorb>%@</blorb>\n", _blorbURL.URLByStandardizingPath];
  if (_graphicsURL)
    [string appendFormat:@"<graphics>%@</graphics>\n", _graphicsURL.URLByStandardizingPath];
  if (_soundURL)
    [string appendFormat:@"<sound>%@</sound>\n", _soundURL.URLByStandardizingPath];
  [string appendString:@"</yazmin>\n"];
  return string;
}

@end
