//
//  DebugInfo.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/12/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface DebugInfo : NSObject
{
    NSMutableDictionary *propertyNames;
    NSMutableDictionary *objectNames;
    NSMutableDictionary *routines;
}

- (NSMutableDictionary *)propertyNames;
- (NSMutableDictionary *)objectNames;
- (NSMutableDictionary *)routines;

@end
