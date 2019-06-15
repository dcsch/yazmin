//
//  StoryController.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/08/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryInput.h"
#import <Cocoa/Cocoa.h>

@interface StoryController
    : NSWindowController <StoryInput, NSLayoutManagerDelegate>

- (void)prepareInputWithOffset:(NSInteger)offset;
- (void)prepareInputChar;
- (void)restoreSession;
- (void)saveSessionData:(NSData *)data;
- (void)showError:(NSString *)errorMessage;
- (void)updateWindowLayout;
- (void)updateTextAttributes;
- (void)executeStory;

@end
