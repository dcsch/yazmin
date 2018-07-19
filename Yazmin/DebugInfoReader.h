//
//  DebugInfoReader.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/12/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DebugInfo;
@class RoutineDebugRecord;

@interface DebugInfoReader : NSObject
{
    NSData *debugData;
    unsigned char *ptr;
    DebugInfo *debugInfo;
    RoutineDebugRecord *currentRoutine;
}

- (instancetype)initWithData:(NSData *)data NS_DESIGNATED_INITIALIZER;
@property (readonly, strong) DebugInfo *debugInfo;

@end
