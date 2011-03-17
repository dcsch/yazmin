//
//  DebugInfo.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/12/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "DebugInfo.h"

@implementation DebugInfo

- (id)init
{
    self = [super init];
    if (self)
    {
        propertyNames = [[NSMutableDictionary alloc] init];
        objectNames = [[NSMutableDictionary alloc] init];
        routines = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [propertyNames release];
    [objectNames release];
    [routines release];
    [super dealloc];
}

- (NSMutableDictionary *)propertyNames
{
    return propertyNames;
}

- (NSMutableDictionary *)objectNames
{
    return objectNames;
}

- (NSMutableDictionary *)routines
{
    return routines;
}

@end
