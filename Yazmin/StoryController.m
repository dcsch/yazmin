//
//  StoryController.m
//  Yazmin
//
//  Created by David Schweinsberg on 22/08/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "StoryController.h"
#import "AbbreviationsController.h"
#import "Blorb.h"
#import "DebugController.h"
#import "GridStoryFacet.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "IFictionMetadata.h"
#import "LayoutView.h"
#import "ObjectBrowserController.h"
#import "Preferences.h"
#import "Story.h"
#import "StoryFacet.h"
#import "StoryFacetView.h"
#import "StoryInformationController.h"
#import "ZMachine.h"

@interface StoryController ()

//- (void)openPanelDidEnd:(NSOpenPanel *)openPanel
//             returnCode:(int)returnCode
//            contextInfo:(void *)contextInfo;

//- (void)savePanelDidEnd:(NSSavePanel *)savePanel
//             returnCode:(int)returnCode
//            contextInfo:(void *)contextInfo;

@end

@implementation StoryController

- (instancetype)init {
  self = [super initWithWindowNibName:@"Story"];
  if (self) {
    inputLocation = 0;

    // Listen to some notifications
    NSNotificationCenter *nc;
    nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(handleViewFrameChange:)
               name:NSViewFrameDidChangeNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleBackgroundColorChange:)
               name:@"SMBackgroundColorChanged"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleForegroundColorChange:)
               name:@"SMForegroundColorChanged"
             object:nil];

    // When the user closes the story window, we want all other windows
    // attached to the story (debuggers, etc) to close also
    self.shouldCloseDocument = YES;
  }
  return self;
}

- (void)dealloc {
  NSLog(@"StoryController dealloc");

  NSNotificationCenter *nc;
  nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}

- (NSString *)windowTitleForDocumentDisplayName:(NSString *)displayName {
  // Retrieve the title from metadata, if present.  Otherwise use the
  // default display name.
  Story *story = self.document;
  if (story.metadata)
    return story.metadata.bibliographic.title;
  return [super windowTitleForDocumentDisplayName:displayName];
}

- (void)windowDidLoad {
  [super windowDidLoad];

  Story *story = self.document;

  // Retrieve defaults
  //    NSColor *backgroundColor =
  //        [Preferences sharedPreferences].backgroundColor;

  //    // Create layout managers
  //    NSTextStorage *textStorage;
  //
  //    NSLayoutManager *lowerLayoutManager = [[NSLayoutManager alloc] init];
  //    [lowerLayoutManager setUsesScreenFonts:NO];
  //    textStorage = [[[story facets] objectAtIndex:0] textStorage];
  //    [textStorage addLayoutManager:lowerLayoutManager];
  //    [lowerLayoutManager release];

  //    NSLayoutManager *upperLayoutManager = [[NSLayoutManager alloc] init];
  //    [upperLayoutManager setUsesScreenFonts:NO];
  //    textStorage = [[[story facets] objectAtIndex:1] textStorage];
  //    [textStorage addLayoutManager:upperLayoutManager];
  //    [upperLayoutManager release];

  NSRect frame = layoutView.lowerScrollView.contentView.frame;

  //    // Create the NSTextContainers and NSTextFrames to handle the document
  //    NSSize lowerContainerSize = NSMakeSize(frame.size.width, 1000000000);
  //    NSTextContainer *container =
  //        [[NSTextContainer alloc] initWithContainerSize:lowerContainerSize];
  //    [container setWidthTracksTextView:YES];
  //    [lowerLayoutManager addTextContainer:container];
  //    [container release];

  //    StoryFacetView *textView = [[StoryFacetView alloc] initWithFrame:frame
  //                                                       textContainer:container];
  //    [textView setBackgroundColor:backgroundColor];
  //    [textView setAutoresizingMask:NSViewWidthSizable];
  //    [textView setVerticallyResizable:YES];
  //    [textView setStoryInput:(StoryInput *)self];
  //    [textView setInputView:YES];
  //    [layoutView setLowerWindow:textView];
  //    [textView release];

  // TESTING a different way of creating the text view
  StoryFacetView *textView = [[StoryFacetView alloc] initWithFrame:frame];
  //    textView.backgroundColor = backgroundColor;
  textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  [(story.facets)[0] setTextStorage:textView.textStorage];
  textView.storyInput = self;
  [textView setInputView:YES];
  layoutView.lowerWindow = textView;
  textView.layoutManager.delegate = self;

  // Upper Window
  NSRect upperFrame = NSMakeRect(0, 0, frame.size.width, 0);
  //    container = [[NSTextContainer alloc]
  //    initWithContainerSize:upperFrame.size];
  //    [container setWidthTracksTextView:YES];
  //    [container setHeightTracksTextView:YES];
  //    [upperLayoutManager addTextContainer:container];
  //    [container release];
  //
  //    textView = [[StoryFacetView alloc] initWithFrame:upperFrame
  //                                       textContainer:container];
  //    [textView setBackgroundColor:backgroundColor];
  //    [textView setAutoresizingMask:NSViewWidthSizable];
  //    [layoutView setUpperWindow:textView];
  //    [textView release];

  // TESTING a different way of creating the text view
  textView = [[StoryFacetView alloc] initWithFrame:upperFrame];
  //    textView.backgroundColor = backgroundColor;
  //[textView setAutoresizingMask:NSViewWidthSizable];
  textView.autoresizingMask = 0;
  //[[textView textContainer] setWidthTracksTextView:NO];
  [textView.textContainer setHeightTracksTextView:NO];
  [[story facets][1] setTextStorage:textView.textStorage];
  [layoutView setUpperWindow:textView];

  // TESTING
  [[story zMachine] setScreenHeight:0xff];
  [[story zMachine] setScreenWidth:[self calculateScreenWidth]];
  [[story zMachine] executeUntilHalt];
}

- (LayoutView *)view {
  return layoutView;
}

- (float)calculateScreenWidth {
  NSSize frameSize = layoutView.frame.size;
  float linePadding =
      [layoutView upperWindow].textContainer.lineFragmentPadding;
  float lineWidth = frameSize.width - 2 * linePadding;
  float charWidth = [[Preferences sharedPreferences] monospacedCharacterWidth];
  return lineWidth / charWidth;
}

- (void)handleViewFrameChange:(NSNotification *)note {
  if (note.object == layoutView) {
    // Adjust to the new width in terms of the character count in the
    // top window.  Note that this won't become visible until the next
    // update to the top window.
    float screenWidthInChars = [self calculateScreenWidth];
    Story *story = self.document;
    [[story zMachine] setScreenWidth:(unsigned int)screenWidthInChars];

    GridStoryFacet *facet = [self.document facets][1];
    [facet setNumberOfColumns:(int)screenWidthInChars];
  }
}

- (void)handleBackgroundColorChange:(NSNotification *)note {
  Preferences *sender = note.object;
  NSColor *newColor = [sender backgroundColor];
  [layoutView lowerWindow].backgroundColor = newColor;
  [layoutView upperWindow].backgroundColor = newColor;
  [layoutView setNeedsDisplay:YES];
}

- (void)handleForegroundColorChange:(NSNotification *)note {
  NSLog(@"handleForegroundColorChange:");
}

- (void)layoutManager:(NSLayoutManager *)aLayoutManager
    didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainerre
                                atEnd:(BOOL)flag {
  // Ensure the scroll position is at the bottom of the transcript
  NSScrollView *scrollView = [layoutView lowerScrollView];
  NSPoint p = NSMakePoint(0, NSMaxY(scrollView.documentView.frame) -
                                 NSHeight(scrollView.contentView.bounds));
  [[layoutView lowerWindow] scrollPoint:p];
}

- (void)prepareInput {
  NSLog(@"prepareInput");
  Story *story = self.document;
  NSUInteger len = [[story facets][0] textStorage].length;
  [[layoutView lowerWindow] setInputLocation:(unsigned int)len];
  [[layoutView lowerWindow] setInputState:kStringInputState];
}

- (void)prepareInputChar {
  NSLog(@"prepareInputChar");
  [[layoutView lowerWindow] setInputState:kCharacterInputState];
}

- (void)restoreSession {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[ @"qut" ];
  [panel beginSheetModalForWindow:self.window
                completionHandler:^(NSInteger result) {
                  NSURL *url;

                  if (result == NSModalResponseOK) {
                    url = panel.URL;
                  }
                }];
}

- (void)saveSessionData:(NSData *)data;
{
  // Ask the user for a save file name
  NSSavePanel *panel = [NSSavePanel savePanel];
  panel.allowedFileTypes = @[ @"qut" ];
  [panel beginSheetModalForWindow:self.window
                completionHandler:^(NSInteger result) {
                  Story *story = self.document;
                  if (result == NSModalResponseOK) {
                    [data writeToURL:panel.URL atomically:YES];
                    [story setLastRestoreOrSaveResult:1];
                  } else
                    [story setLastRestoreOrSaveResult:0];

                  // TESTING
                  //[[story zMachine] executeUntilHalt];
                }];
}

- (void)showError:(NSString *)errorMessage {
  NSAlert *alert = [[NSAlert alloc] init];
  alert.messageText = @"Error";
  alert.informativeText = errorMessage;
  [alert beginSheetModalForWindow:self.window
                completionHandler:^(NSModalResponse returnCode) {
                  NSLog(@"sheetDidEnd");
                }];
}

- (void)update {
  NSLog(@"StoryController updated");
  //    Story *story = [self document];
  //    unsigned int len = [[[[story facets] objectAtIndex:0] textStorage]
  //    length];
  //    [[layoutView lowerWindow] setInputLocation:len];
}

- (void)updateWindowLayout {
  // Retrieve the height of the upper window
  StoryFacet *facet = [self.document facets][1];
  [layoutView resizeUpperWindow:[facet numberOfLines]];
  [layoutView setNeedsDisplay:YES];
}

- (void)updateWindowWidth {
  // Adjust the width of the upper text view
  NSRect layoutFrameRect = layoutView.frame;
  NSRect upperFrameRect = layoutView.upperWindow.frame;
  upperFrameRect.size.width = layoutFrameRect.size.width;
  layoutView.upperWindow.frame = upperFrameRect;
}

- (void)updateTextAttributes {
  // Set the typing attributes of the lower window so they reflect the change
  StoryFacet *facet = [self.document facets][0];
  (layoutView.lowerWindow).typingAttributes = facet.currentAttributes;
}

- (void)characterInput:(char)c {
  NSLog(@"characterInput: %c", c);
  Story *story = self.document;

  NSString *str = [[NSString alloc] initWithBytes:&c
                                           length:1
                                         encoding:NSASCIIStringEncoding];
  [story setInputString:str];

  // TESTING
  [story.zMachine executeUntilHalt];
  [self updateViews];

  if (story.hasEnded) {
    NSMutableString *windowTitle =
        [NSMutableString stringWithString:self.window.title];
    [windowTitle appendString:@" - Ended"];
    self.window.title = windowTitle;
  }
}

- (void)stringInput:(NSString *)string {
  NSLog(@"stringInput: %@", string);
  Story *story = self.document;
  [story setInputString:string];

  // TESTING
  [story.zMachine executeUntilHalt];
  [self updateViews];

  if (story.hasEnded) {
    NSMutableString *windowTitle =
        [NSMutableString stringWithString:self.window.title];
    [windowTitle appendString:@" - Ended"];
    self.window.title = windowTitle;
  }
}

- (IBAction)showInformationPanel:(id)sender {
  if (!informationController) {
    Story *story = self.document;
    informationController =
        [[StoryInformationController alloc] initWithBlorb:story.blorb];
    [self.document addWindowController:informationController];
  }
  [informationController showWindow:self];
}

- (IBAction)showDebuggerWindow:(id)sender {
  if (!debugController) {
    debugController = [[DebugController alloc] init];
    [self.document addWindowController:debugController];
  }
  [debugController showWindow:self];
}

- (IBAction)showObjectBrowserWindow:(id)sender {
  if (!objectBrowserController) {
    objectBrowserController = [[ObjectBrowserController alloc] init];
    [self.document addWindowController:objectBrowserController];
  }
  [objectBrowserController showWindow:self];
}

- (IBAction)showAbbreviationsWindow:(id)sender {
  if (!abbreviationsController) {
    abbreviationsController = [[AbbreviationsController alloc] init];
    [self.document addWindowController:abbreviationsController];
  }
  [abbreviationsController showWindow:self];
}

- (void)updateViews {
  [objectBrowserController update];
}

@end
