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

- (void)prepareInput;
- (void)prepareInputChar;
- (void)restoreSession;
- (void)saveSessionData:(NSData *)data;
- (void)showError:(NSString *)errorMessage;
- (void)updateWindowLayout;
- (void)updateWindowWidth;
- (void)updateTextAttributes;

@end
