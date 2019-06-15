//
//  Story.h
//  Yazmin
//
//  Created by David Schweinsberg on 2/07/07.
//  Copyright David Schweinsberg 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StoryFacet;
@class StoryController;
@class Blorb;
@class IFStory;
@class ZMachine;
@class DebugInfo;

@interface Story : NSDocument

@property(readonly, copy) NSArray<StoryFacet *> *facets;
@property(readonly) StoryController *storyController;
@property(copy) NSString *inputString;
@property(readonly, copy) NSData *zcodeData;
@property(readonly, strong) Blorb *blorb;
@property(readonly, strong) IFStory *metadata;
@property(readonly, copy) NSString *ifid;
@property(readonly, strong) ZMachine *zMachine;
@property(readonly, strong) DebugInfo *debugInfo;
@property(readonly) BOOL hasEnded;
@property unsigned int lastRestoreOrSaveResult;
@property NSData *restoreData;

- (void)restoreSession;
- (void)saveSessionData:(NSData *)data;
- (void)error:(NSString *)errorMessage;
- (void)updateWindowLayout;
- (void)handleBackgroundColorChange:(NSNotification *)note;
- (void)handleForegroundColorChange:(NSNotification *)note;
- (void)handleFontChange:(NSNotification *)note;
- (void)beginInputWithOffset:(NSInteger)offset;
- (NSString *)endInput;
- (void)beginInputChar;
- (unichar)endInputChar;

@end
