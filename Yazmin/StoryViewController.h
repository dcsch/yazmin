//
//  StoryViewController.h
//  Yazmin
//
//  Created by David Schweinsberg on 7/16/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "StoryInput.h"
#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface StoryViewController : NSViewController <StoryInput>

- (void)prepareInputWithOffset:(NSInteger)offset;
- (void)prepareInputChar;
- (void)restoreSession;
- (void)saveSessionData:(NSData *)data;
- (void)outputStream:(int)number;
- (void)inputStream:(int)number;
- (void)showError:(NSString *)errorMessage;
- (void)updateWindowBackgroundColor;
- (void)updateTextAttributes;
- (void)executeStory;
- (BOOL)executeRoutine:(int)routine;

- (void)setWindow:(int)window;
- (void)splitWindow:(int)lines;
- (void)eraseWindow:(int)window;
- (void)setCursorLine:(int)line column:(int)column;
- (void)print:(NSString *)text;
- (void)printNumber:(int)number;
- (void)newLine;
- (void)printBox:(NSAttributedString *)text;

@end

NS_ASSUME_NONNULL_END
