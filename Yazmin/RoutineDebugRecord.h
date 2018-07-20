//
//  RoutineDebugRecord.h
//  Yazmin
//
//  Created by David Schweinsberg on 28/12/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DebugInfo;

@interface RoutineDebugRecord : NSObject
{
    unsigned int routineNumber;
    NSString *defnStart;
    unsigned int pcStart;
    NSString *name;
    NSMutableArray *localNames;
}

- (instancetype)initWithNumber:(unsigned int)number
               start:(NSString *)start
             pcStart:(unsigned int)aPCStart
                name:(NSString *)aName NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));

@property (readonly) unsigned int routineNumber;
@property (readonly, copy) NSString *defnStart;
@property (readonly) unsigned int pcStart;
@property (readonly, copy) NSString *name;
@property (readonly, copy) NSMutableArray *localNames;

@end
