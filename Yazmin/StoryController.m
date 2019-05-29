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

@interface StoryController () {
  IBOutlet LayoutView *layoutView;
  unsigned int inputLocation;
  StoryInformationController *informationController;
  DebugController *debugController;
  ObjectBrowserController *objectBrowserController;
  AbbreviationsController *abbreviationsController;
  int curheight;
  int maxheight;
  int seenheight;
}

- (int)calculateScreenWidthInColumns;
- (void)handleViewFrameChange:(NSNotification *)note;
- (void)handleBackgroundColorChange:(NSNotification *)note;
- (void)handleForegroundColorChange:(NSNotification *)note;
- (void)layoutManager:(NSLayoutManager *)aLayoutManager
    didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainer
                                atEnd:(BOOL)flag;
- (void)characterInput:(char)c;
- (void)stringInput:(NSString *)string;
- (void)update;
- (IBAction)showInformationPanel:(id)sender;
- (IBAction)showDebuggerWindow:(id)sender;
- (IBAction)showObjectBrowserWindow:(id)sender;
- (IBAction)showAbbreviationsWindow:(id)sender;
- (void)updateViews;
- (void)resolveStatusHeight;
- (void)executeStory;

@end

@implementation StoryController

- (instancetype)init {
  self = [super initWithWindowNibName:@"Story"];
  if (self) {
    inputLocation = 0;
    curheight = 0;
    maxheight = 0;
    seenheight = 0;

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
  NSString *title;
  if (story.metadata)
    title = story.metadata.bibliographic.title;
  else
    title = [super windowTitleForDocumentDisplayName:displayName];

  if (story.hasEnded)
    title = [title stringByAppendingString:@" — Ended"];

  return title;
}

- (void)windowDidLoad {
  [super windowDidLoad];

  Story *story = self.document;

  // Lower Window (initially full frame)
  NSRect frame = layoutView.lowerScrollView.contentView.frame;
  StoryFacetView *textView = [[StoryFacetView alloc] initWithFrame:frame];
  textView.automaticQuoteSubstitutionEnabled = YES;
  textView.automaticDashSubstitutionEnabled = YES;
  textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  textView.textContainerInset = NSMakeSize(20.0, 20.0);
  textView.layoutManager.delegate = self;
  textView.storyInput = self;
  textView.inputView = YES;

  story.facets[0].textStorage = textView.textStorage;
  layoutView.lowerWindow = textView;

  // Upper Window (initially zero height)
  NSRect upperFrame = NSMakeRect(0, 0, frame.size.width, 0);
  textView = [[StoryFacetView alloc] initWithFrame:upperFrame];
  textView.automaticQuoteSubstitutionEnabled = YES;
  textView.automaticDashSubstitutionEnabled = YES;
  textView.verticallyResizable = NO;
  textView.horizontallyResizable = NO;
  textView.autoresizingMask = NSViewWidthSizable;
  textView.textContainerInset = NSMakeSize(20.0, 10.0);

  textView.textContainer.widthTracksTextView = YES;
  textView.textContainer.heightTracksTextView = NO;
  textView.textContainer.maximumNumberOfLines = 0;

  story.facets[1].textStorage = textView.textStorage;
  layoutView.upperWindow = textView;

  // Kick off the story
  story.zMachine.screenHeight = 0xff;
  story.zMachine.screenWidth = [self calculateScreenWidthInColumns];
  [self executeStory];
}

- (int)calculateScreenWidthInColumns {
  float lineWidth = layoutView.upperWindow.textContainer.size.width;
  float charWidth = [[Preferences sharedPreferences] monospacedCharacterWidth];
  return lineWidth / charWidth;
}

- (void)handleViewFrameChange:(NSNotification *)note {
  if (note.object == layoutView) {
    // Adjust to the new width in terms of the character count in the
    // top window.  Note that this won't become visible until the next
    // update to the top window.
    int screenWidthInChars = [self calculateScreenWidthInColumns];
    Story *story = self.document;
    story.zMachine.screenWidth = (unsigned int)screenWidthInChars;

    GridStoryFacet *facet = (GridStoryFacet *)story.facets[1];
    facet.numberOfColumns = screenWidthInChars;
  }
}

- (void)handleBackgroundColorChange:(NSNotification *)note {
  Preferences *prefs = note.object;
  NSColor *newColor = prefs.backgroundColor;
  layoutView.lowerWindow.backgroundColor = newColor;
  layoutView.upperWindow.backgroundColor = newColor;
  layoutView.needsDisplay = YES;
}

- (void)handleForegroundColorChange:(NSNotification *)note {
  NSLog(@"handleForegroundColorChange:");
}

- (void)scrollLowerWindowToEnd {
  NSScrollView *scrollView = layoutView.lowerScrollView;
  NSPoint p = NSMakePoint(0, NSMaxY(scrollView.documentView.frame) -
                                 NSHeight(scrollView.contentView.bounds));
  [layoutView.lowerWindow scrollPoint:p];
}

- (void)layoutManager:(NSLayoutManager *)aLayoutManager
    didCompleteLayoutForTextContainer:(NSTextContainer *)aTextContainer
                                atEnd:(BOOL)flag {
  // Ensure the scroll position is at the bottom of the transcript
  // (Note: all this scrolling to the end seems a little
  // excessive just at the moment)
  [self scrollLowerWindowToEnd];
}

- (void)prepareInput {
  //  NSLog(@"prepareInput");
  Story *story = self.document;
  NSUInteger len = story.facets[0].textStorage.length;
  [layoutView.lowerWindow setInputLocation:(unsigned int)len];
  [layoutView.lowerWindow setInputState:kStringInputState];
  [self scrollLowerWindowToEnd];
}

- (void)prepareInputChar {
  //    NSLog(@"prepareInputChar");
  [layoutView.lowerWindow setInputState:kCharacterInputState];
  [self scrollLowerWindowToEnd];
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
                    story.lastRestoreOrSaveResult = 1;
                  } else
                    story.lastRestoreOrSaveResult = 0;
                  [self executeStory];
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
  Story *story = self.document;
  StoryFacet *facet = story.facets[1];

  // Implement zarf's fix to the quote box problem
  // (https://eblong.com/zarf/glk/quote-box.html)
  int oldheight = curheight;
  curheight = facet.numberOfLines;

  // We do not decrease the height at this time -- it can only
  // increase.
  if (curheight > maxheight)
    maxheight = curheight;

  // However, if the VM thinks it's increasing the height, we must be
  // careful to clear the "newly created" space.
  if (curheight > oldheight) {
    // blank out all lines from oldheight to the bottom of the window
  }

  [layoutView resizeUpperWindow:maxheight];
  layoutView.needsDisplay = YES;
}

// If the status height is too large because of last turn's quote box,
// shrink it down now.
// This must be called immediately before any input event. (That is,
// the beginning of the @read and @read_char opcodes.)
- (void)resolveStatusHeight {

  // If the player has seen the entire window, we can shrink it.
  if (seenheight == maxheight)
    maxheight = curheight;

  [layoutView resizeUpperWindow:maxheight];
  layoutView.needsDisplay = YES;

  seenheight = maxheight;
  maxheight = curheight;
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
  Story *story = self.document;
  StoryFacet *facet = story.facets[0];
  layoutView.lowerWindow.typingAttributes = facet.currentAttributes;
}

- (void)characterInput:(char)c {
  [self resolveStatusHeight];

  //  NSLog(@"characterInput: %c", c);
  Story *story = self.document;

  NSString *str = [[NSString alloc] initWithBytes:&c
                                           length:1
                                         encoding:NSASCIIStringEncoding];
  [story setInputString:str];
  [self executeStory];
}

- (void)stringInput:(NSString *)string {
  [self resolveStatusHeight];

  //  NSLog(@"stringInput: %@", string);
  Story *story = self.document;
  [story setInputString:string];
  [self executeStory];
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

- (void)executeStory {
  Story *story = self.document;
  [story.zMachine executeUntilHalt];
  if (story.hasEnded) {
    [layoutView.lowerWindow setInputState:kNoInputState];
  }
  [self synchronizeWindowTitleWithDocumentName];
  [self updateViews];
}

@end
