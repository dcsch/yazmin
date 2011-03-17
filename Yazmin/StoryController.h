//
//  StoryController.h
//  Yazmin
//
//  Created by David Schweinsberg on 22/08/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "StoryInput.h"

@class LayoutView;
@class StoryInformationController;
@class DebugController;
@class ObjectBrowserController;
@class AbbreviationsController;

@interface StoryController : NSWindowController <StoryInput, NSLayoutManagerDelegate>
{
    IBOutlet LayoutView *layoutView;
    unsigned int inputLocation;
    StoryInformationController *informationController;
    DebugController *debugController;
    ObjectBrowserController *objectBrowserController;
    AbbreviationsController *abbreviationsController;
}

- (LayoutView *)view;
- (float)calculateScreenWidth;
- (void)handleViewFrameChange:(NSNotification *)note;
- (void)handleBackgroundColourChange:(NSNotification *)note;
- (void)handleForegroundColourChange:(NSNotification *)note;
- (void)layoutManager:(NSLayoutManager *)aLayoutManager
didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainer
                atEnd:(BOOL)flag;
- (void)prepareInput;
- (void)prepareInputChar;
- (void)restoreSession;
- (void)saveSessionData:(NSData *)data;
- (void)showError:(NSString *)errorMessage;
- (void)update;
- (void)updateWindowLayout;
- (void)updateWindowWidth;
- (void)updateTextAttributes;
- (void)characterInput:(char)c;
- (void)stringInput:(NSString *)string;
- (IBAction)showInformationPanel:(id)sender;
- (IBAction)showDebuggerWindow:(id)sender;
- (IBAction)showObjectBrowserWindow:(id)sender;
- (IBAction)showAbbreviationsWindow:(id)sender;
- (void)updateViews;

@end
