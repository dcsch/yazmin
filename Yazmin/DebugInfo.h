//
//  DebugInfo.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/12/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DebugInfo : NSObject {
  NSMutableDictionary *propertyNames;
  NSMutableDictionary *objectNames;
  NSMutableDictionary *routines;
}

@property(readonly, copy) NSMutableDictionary *propertyNames;
@property(readonly, copy) NSMutableDictionary *objectNames;
@property(readonly, copy) NSMutableDictionary *routines;

@end
