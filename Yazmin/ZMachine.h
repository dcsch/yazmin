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

@interface ZMachine : NSObject

- (instancetype)initWithStory:(Story *)aStory NS_DESIGNATED_INITIALIZER;
- (instancetype)init __attribute__((unavailable));
@property(readonly, copy) NSString *ifid;
@property(readonly) const unsigned char *memory;
@property(readonly) size_t memorySize;
@property(readonly) BOOL hasQuit;
- (BOOL)executeUntilHalt;
- (BOOL)callRoutine:(int)routine;
//- (void)restart;

- (int)numberOfChildrenOfObject:(int)objNumber;
- (int)child:(int)index ofObject:(int)objNumber;
- (NSString *)nameOfObject:(int)objNumber;
- (int)numberOfPropertiesOfObject:(int)objNumber;
- (int)property:(int)index ofObject:(int)objNumber;
- (NSString *)propertyData:(int)index ofObject:(int)objNumber;
@property(readonly, copy) NSArray *abbreviations;
@property(readonly) int numberOfFrames;
- (NSUInteger)routineAddressForFrame:(NSInteger)frame;
- (NSUInteger)localAtIndex:(NSUInteger)index forFrame:(NSInteger)frame;
@property(readonly) unsigned int baseHighMemory;

- (unsigned int)globalAtIndex:(unsigned int)index;
@property(getter=isTimeGame, readonly) BOOL timeGame;
@property BOOL needsRedraw;
@property(readonly) BOOL forcedFixedPitchFont;
- (void)updateScreenSize;

@end
