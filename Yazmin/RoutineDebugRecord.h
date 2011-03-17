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

- (id)initWithNumber:(unsigned int)number
               start:(NSString *)start
             pcStart:(unsigned int)aPCStart
                name:(NSString *)aName;

- (unsigned int)routineNumber;
- (NSString *)defnStart;
- (unsigned int)pcStart;
- (NSString *)name;
- (NSMutableArray *)localNames;

@end
