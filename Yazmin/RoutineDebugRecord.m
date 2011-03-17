//
//  RoutineDebugRecord.m
//  Yazmin
//
//  Created by David Schweinsberg on 28/12/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "RoutineDebugRecord.h"
#import "DebugInfo.h"

@implementation RoutineDebugRecord

- (id)initWithNumber:(unsigned int)number
               start:(NSString *)start
             pcStart:(unsigned int)aPCStart
                name:(NSString *)aName
{
    self = [super init];
    if (self)
    {
        routineNumber = number;
        defnStart = [start copy];
        pcStart = aPCStart;
        name = [aName copy];
        localNames = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [defnStart release];
    [name release];
    [localNames release];
    [super dealloc];
}

- (unsigned int)routineNumber
{
    return routineNumber;
}

- (NSString *)defnStart
{
    return defnStart;
}

- (unsigned int)pcStart
{
    return pcStart;
}

- (NSString *)name
{
    return name;
}

- (NSMutableArray *)localNames
{
    return localNames;
}

@end
