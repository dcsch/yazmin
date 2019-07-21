//
//  Story.h
//  Yazmin
//
//  Created by David Schweinsberg on 2/07/07.
//  Copyright David Schweinsberg 2007. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class StoryFacet;
@class StoryViewController;
@class Blorb;
@class IFStory;
@class ZMachine;
@class DebugInfo;

@interface Story : NSDocument

@property(readonly) NSArray<StoryFacet *> *facets;
@property(readonly) StoryViewController *storyViewController;
@property NSString *inputString;
@property unichar inputCharacter;
@property(readonly) NSData *zcodeData;
@property(readonly) Blorb *blorb;
@property(readonly) IFStory *metadata;
@property(readonly) NSImage *coverImage;
@property(readonly) NSString *ifid;
@property(readonly) ZMachine *zMachine;
@property(readonly) DebugInfo *debugInfo;
@property(readonly) BOOL hasEnded;
@property unsigned int lastRestoreOrSaveResult;
@property NSData *restoreData;

@property(readonly) NSColor *foregroundColor;
@property(readonly) NSColor *backgroundColor;
@property(readonly) int foregroundColorCode;
@property(readonly) int backgroundColorCode;
@property(readonly) int currentStyle;
@property BOOL forceFixedPitchFont;

- (IBAction)showStoryInfo:(id)sender;

- (void)restoreSession;
- (void)saveSessionData:(NSData *)data;
- (void)error:(NSString *)errorMessage;
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
- (void)eraseLine;
- (void)setCursorLine:(int)line column:(int)column;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;
- (void)showStatus;
- (void)soundEffectNumber:(int)number
                   effect:(int)effect
                   repeat:(int)repeat
                   volume:(int)volume;
- (void)startTime:(int)time routine:(int)routine;
- (void)stopTimedRoutine;
- (BOOL)supportedCharacter:(unichar)c;

@end
