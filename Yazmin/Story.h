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
@property unichar inputCharacter;
@property(readonly, copy) NSData *zcodeData;
@property(readonly, strong) Blorb *blorb;
@property(readonly, strong) IFStory *metadata;
@property(readonly, copy) NSString *ifid;
@property(readonly, strong) ZMachine *zMachine;
@property(readonly, strong) DebugInfo *debugInfo;
@property(readonly) BOOL hasEnded;
@property unsigned int lastRestoreOrSaveResult;
@property NSData *restoreData;

@property(readonly) NSColor *foregroundColor;
@property(readonly) NSColor *backgroundColor;
@property(readonly) int foregroundColorCode;
@property(readonly) int backgroundColorCode;
@property(readonly) int currentStyle;
@property BOOL forceFixedPitchFont;

- (void)restoreSession;
- (void)saveSessionData:(NSData *)data;
- (void)error:(NSString *)errorMessage;
- (void)updateWindowLayout;
- (void)updateWindowBackgroundColor;
- (void)handleBackgroundColorChange:(NSNotification *)note;
- (void)handleForegroundColorChange:(NSNotification *)note;
- (void)handleFontChange:(NSNotification *)note;
- (void)beginInputWithOffset:(NSInteger)offset;
- (NSString *)endInput;
- (void)beginInputChar;
- (unichar)endInputChar;
- (void)outputStream:(int)number;
- (void)inputStream:(int)number;
- (void)setColorForeground:(int)fg background:(int)bg;
- (void)setTrueColorForeground:(int)fg background:(int)bg;
- (void)setTextStyle:(int)style;
- (void)hackyDidntSetTextStyle;

@property(readonly) int screenWidth;
@property(readonly) int screenHeight;
@property int window;
@property(readonly) int line;
@property(readonly) int column;
@property int fontId;

- (void)splitWindow:(int)lines;
- (void)eraseWindow:(int)window;
- (void)setCursorLine:(int)line column:(int)column;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;
- (void)showStatus;
- (void)soundEffectNumber:(int)number
                   effect:(int)effect
                   repeat:(int)repeat
                   volume:(int)volume;

@end
