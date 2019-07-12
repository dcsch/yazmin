//
//  VersionFormatter.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/11/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "VersionFormatter.h"

@implementation VersionFormatter

- (NSString *)stringForObjectValue:(id)obj {
  NSNumber *number = obj;
  unichar uc = number.charValue;
  return [NSString stringWithCharacters:&uc length:1];
}

- (BOOL)getObjectValue:(out id _Nullable *)obj
             forString:(NSString *)string
      errorDescription:(out NSString * _Nullable *)error {
  if (string.length == 1) {
    NSNumber *number = [NSNumber numberWithChar:[string characterAtIndex:0]];
    if ('A' <= number.charValue && number.charValue <= 'Z') {
      *obj = number;
      return YES;
    }
  }
  return NO;
}

@end
