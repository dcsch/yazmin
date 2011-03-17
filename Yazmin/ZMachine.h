/*
 *  ZMachine.h
 *  yazmin
 *
 *  Created by David Schweinsberg on 10/12/06.
 *  Copyright 2006-2007 David Schweinsberg. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class Story;
struct MachineParts;

@interface ZMachine : NSObject
{
    Story *story;
    struct MachineParts *parts;
}

- (id)initWithStory:(Story *)aStory;
- (NSString *)ifid;
- (unsigned char *)memory;
- (int)memorySize;
- (BOOL)hasQuit;
- (BOOL)executeUntilHalt;
//- (void)restart;

- (int)numberOfChildrenOfObject:(int)objNumber;
- (int)child:(int)index ofObject:(int)objNumber;
- (NSString *)nameOfObject:(int)objNumber;
- (int)numberOfPropertiesOfObject:(int)objNumber;
- (int)property:(int)index ofObject:(int)objNumber;
- (NSString *)propertyData:(int)index ofObject:(int)objNumber;
- (NSArray *)abbreviations;
- (int)numberOfFrames;
- (unsigned int)routineAddressForFrame:(int)frame;
- (unsigned int)localAtIndex:(unsigned int)index forFrame:(int)frame;
- (unsigned int)baseHighMemory;

- (unsigned int)globalAtIndex:(unsigned int)index;
- (BOOL)isTimeGame;
- (unsigned int)screenWidth;
- (void)setScreenWidth:(unsigned int)width;
- (unsigned int)screenHeight;
- (void)setScreenHeight:(unsigned int)height;

@end
