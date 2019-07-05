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
  StoryInformationController *informationController;
  DebugController *debugController;
  ObjectBrowserController *objectBrowserController;
  AbbreviationsController *abbreviationsController;
  int curheight;
  int maxheight;
  int seenheight;
  NSURL *_transcriptURL;
  NSURL *_commandURL;
  NSOutputStream *_transcriptOutputStream;
  NSOutputStream *_commandOutputStream;
  NSInputStream *_commandInputStream;
  CGFloat _viewedHeight;
}

- (int)calculateScreenWidthInColumns;
- (int)calculateLowerWindowHeightinLines;
- (void)calculateStoryFacetDimensions;
- (void)handleViewFrameChange:(NSNotification *)note;
- (void)handleBackgroundColorChange:(NSNotification *)note;
- (void)handleForegroundColorChange:(NSNotification *)note;
- (NSString *)playbackInputString;
- (void)printCharToOutputStreams:(unichar)c;
- (void)printToOutputStreams:(NSString *)text;
- (void)characterInput:(unichar)c;
- (void)stringInput:(NSString *)string;
- (void)update;
- (IBAction)reload:(id)sender;
- (IBAction)showStoryInfo:(id)sender;
- (IBAction)showDebuggerWindow:(id)sender;
- (IBAction)showObjectBrowserWindow:(id)sender;
- (IBAction)showAbbreviationsWindow:(id)sender;
- (void)updateViews;
- (void)resolveStatusHeight;

@end

@implementation StoryController

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

  curheight = 0;
  maxheight = 0;
  seenheight = 0;

  Story *story = self.document;
  [self setWindowFrameAutosaveName:story.ifid];

  // When the user closes the story window, we want all other windows
  // attached to the story (debuggers, etc) to close also
  self.shouldCloseDocument = YES;

  // Listen to some notifications
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
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
  [nc addObserver:self
         selector:@selector(handleWindowWillClose:)
             name:NSWindowWillCloseNotification
           object:self.window];

  // Lower Window (initially full frame)
  NSRect frame = layoutView.lowerScrollView.contentView.frame;
  StoryFacetView *textView = [[StoryFacetView alloc] initWithFrame:frame];
  textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  textView.textContainerInset = NSMakeSize(20.0, 20.0);
  textView.storyInput = self;
  textView.inputView = YES;

  story.facets[0].textStorage = textView.textStorage;
  layoutView.lowerWindow = textView;

  // Upper Window (initially zero height)
  NSRect upperFrame = NSMakeRect(0, 0, frame.size.width, 0);
  textView = [[StoryFacetView alloc] initWithFrame:upperFrame];
  textView.verticallyResizable = NO;
  textView.horizontallyResizable = NO;
  textView.autoresizingMask = NSViewWidthSizable;
  textView.textContainerInset = NSMakeSize(20.0, 10.0);

  textView.textContainer.widthTracksTextView = YES;
  textView.textContainer.heightTracksTextView = NO;
  textView.textContainer.maximumNumberOfLines = 0;

  story.facets[1].textStorage = textView.textStorage;
  layoutView.upperWindow = textView;

  [self calculateStoryFacetDimensions];

  // Kick off the story
  [self executeStory];
}

- (int)calculateScreenWidthInColumns {
  float lineWidth = layoutView.upperWindow.textContainer.size.width;
  float charWidth = [[Preferences sharedPreferences] monospacedCharacterWidth];
  return lineWidth / charWidth;
}

- (int)calculateLowerWindowHeightinLines {
  // TODO: This is using frame height rather than layout height as the layout
  // height was coming through as some rediculously large number. Needs to be
  // checked as frame height won't account for the text container inset
  // (does NSTextContainer size do that?)
  CGFloat frameHeight = layoutView.lowerWindow.frame.size.height;
  NSFont *font = [[Preferences sharedPreferences] fontForStyle:0];
  CGFloat lineHeight =
      [layoutView.lowerWindow.layoutManager defaultLineHeightForFont:font];
  return MIN((int)(frameHeight / lineHeight), 255);
}

- (void)calculateStoryFacetDimensions {
  int screenWidthInChars = [self calculateScreenWidthInColumns];
  Story *story = self.document;
  story.facets[0].widthInCharacters = screenWidthInChars;
  story.facets[1].widthInCharacters = screenWidthInChars;
  story.facets[1].heightInLines = [self calculateLowerWindowHeightinLines];
  [story.zMachine updateScreenSize];
  NSLog(@"Set screen size as: %d x %d", screenWidthInChars,
        story.facets[1].heightInLines);
}

- (void)handleWindowWillClose:(NSNotification *)note {
  [_transcriptOutputStream close];
  [_commandOutputStream close];
  [_commandInputStream close];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}

- (void)handleViewFrameChange:(NSNotification *)note {
  if (note.object == layoutView) {
    [self calculateStoryFacetDimensions];
    Story *story = self.document;
    story.zMachine.needsRedraw = YES;
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
  NSTextView *textView = layoutView.lowerWindow;
  [textView.layoutManager ensureLayoutForTextContainer:textView.textContainer];

  NSRect rect =
      [textView.layoutManager usedRectForTextContainer:textView.textContainer];
  CGFloat heightOfContent = rect.size.height;
  CGFloat heightOfWindow = layoutView.lowerScrollView.frame.size.height;

  CGFloat blockHeight = heightOfContent - _viewedHeight;

  NSLog(@"block height: %f", blockHeight);

  if (blockHeight > heightOfWindow) {

    // TODO: There is more text than can be shown in the window, so we must
    // present a "more" prompt
    NSLog(@"[MORE]");

    _viewedHeight += heightOfWindow;
    [layoutView.lowerWindow
        scrollPoint:NSMakePoint(0, _viewedHeight - heightOfWindow)];
  } else {

    // This block will fit within the window, so just scroll to the
    // end of it
    [layoutView.lowerWindow scrollPoint:NSMakePoint(0, heightOfContent)];
    _viewedHeight = heightOfContent;
  }
}

- (NSString *)playbackInputString {
  NSMutableString *str = [NSMutableString string];
  uint8_t c;
  while ([_commandInputStream read:&c maxLength:1] > 0) {
    if (c == '\n')
      break;
    [str appendFormat:@"%c", c];
  }
  return str;
}

- (void)prepareInputWithOffset:(NSInteger)offset {
  [self resolveStatusHeight];
  Story *story = self.document;
  NSUInteger len = story.facets[0].textStorage.length;
  [layoutView.lowerWindow setInputLocation:len + offset];
  if (_commandInputStream) {
    NSString *inputString = [self playbackInputString];
    [layoutView.lowerWindow enterString:inputString];
    if (inputString.length > 0) {
      [self executeStory];
      return;
    } else {
      [_commandInputStream close];
      _commandInputStream = nil;
    }
  }
  [layoutView.lowerWindow setInputState:kStringInputState];
  [self scrollLowerWindowToEnd];
}

- (void)prepareInputChar {
  [self resolveStatusHeight];
  [layoutView.lowerWindow setInputState:kCharacterInputState];
  [self scrollLowerWindowToEnd];
}

- (void)restoreSession {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[ @"qut" ];
  [panel beginSheetModalForWindow:self.window
                completionHandler:^(NSInteger result) {
                  Story *story = self.document;
                  if (result == NSModalResponseOK) {

                    // Hand restore data to the story, to be picked up when
                    // the story starts executing again
                    story.restoreData =
                        [NSData dataWithContentsOfURL:panel.URL];
                    story.lastRestoreOrSaveResult = 2;
                  } else
                    story.lastRestoreOrSaveResult = 0;
                  [self executeStory];
                }];
}

- (void)saveSessionData:(NSData *)data {

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

- (void)createTranscriptOutputStream {
  if (!_transcriptURL) {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedFileTypes = @[ @"txt" ];
    Story *story = self.document;
    panel.nameFieldStringValue = [NSString
        stringWithFormat:@"%@ Transcript (%@)", story.displayName,
                         [NSDate.date
                             descriptionWithLocale:NSLocale.currentLocale]];
    [panel beginSheetModalForWindow:self.window
                  completionHandler:^(NSInteger result) {
                    if (result == NSModalResponseOK) {
                      self->_transcriptURL = panel.URL;
                      self->_transcriptOutputStream = [NSOutputStream
                          outputStreamWithURL:self->_transcriptURL
                                       append:NO];
                      [self->_transcriptOutputStream open];
                      [self executeStory];
                    }
                  }];
  } else {
    _transcriptOutputStream =
        [NSOutputStream outputStreamWithURL:_transcriptURL append:YES];
    [_transcriptOutputStream open];
    [self executeStory];
  }
}

- (void)createCommandOutputStream {
  if (!_commandURL) {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.allowedFileTypes = @[ @"txt" ];
    Story *story = self.document;
    panel.nameFieldStringValue = [NSString
        stringWithFormat:@"%@ Commands (%@)", story.displayName,
                         [NSDate.date
                             descriptionWithLocale:NSLocale.currentLocale]];
    [panel beginSheetModalForWindow:self.window
                  completionHandler:^(NSInteger result) {
                    if (result == NSModalResponseOK) {
                      self->_commandURL = panel.URL;
                      self->_commandOutputStream =
                          [NSOutputStream outputStreamWithURL:self->_commandURL
                                                       append:NO];
                      [self->_commandOutputStream open];
                      [self executeStory];
                    }
                  }];
  } else {
    _commandOutputStream =
        [NSOutputStream outputStreamWithURL:_commandURL append:YES];
    [self->_commandOutputStream open];
    [self executeStory];
  }
}

- (void)outputStream:(int)number {
  if (number == -2) {
    [_transcriptOutputStream close];
    _transcriptOutputStream = nil;
  } else if (number == -4) {
    [_commandOutputStream close];
    _commandOutputStream = nil;
  } else if (number == 2) {
    [self createTranscriptOutputStream];
  } else if (number == 4) {
    [self createCommandOutputStream];
  }
}

- (void)inputStream:(int)number {
  if (number == 0) {
    [_commandInputStream close];
    _commandInputStream = nil;
  } else if (number == 1) {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[ @"txt" ];
    [panel beginSheetModalForWindow:self.window
                  completionHandler:^(NSInteger result) {
                    if (result == NSModalResponseOK) {
                      self->_commandInputStream =
                          [NSInputStream inputStreamWithURL:panel.URL];
                      [self->_commandInputStream open];
                    } else {
                      self->_commandInputStream = nil;
                    }
                    [self executeStory];
                  }];
  }
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
  GridStoryFacet *facet = (GridStoryFacet *)story.facets[1];

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
    [facet eraseFromLine:oldheight + 1];
  }

  [layoutView resizeUpperWindow:maxheight];
  layoutView.needsDisplay = YES;
}

- (void)updateWindowBackgroundColor {
  Story *story = self.document;
  layoutView.lowerWindow.backgroundColor = story.backgroundColor;
  layoutView.upperWindow.backgroundColor = story.backgroundColor;
  layoutView.lowerWindow.insertionPointColor = story.foregroundColor;
}

// If the status height is too large because of last turn's quote box,
// shrink it down now.
// This must be called immediately before any input event. (That is,
// the beginning of the @read and @read_char opcodes.)
- (void)resolveStatusHeight {

  // If the player has seen the entire window, we can shrink it.
  if (seenheight == maxheight)
    maxheight = curheight;

  if (layoutView.upperWindow.textContainer.maximumNumberOfLines != maxheight) {
    [layoutView resizeUpperWindow:maxheight];
    layoutView.needsDisplay = YES;
  }

  seenheight = maxheight;
  maxheight = curheight;
}

- (void)updateTextAttributes {
  // Set the typing attributes of the lower window so they reflect the change
  Story *story = self.document;
  StoryFacet *facet = story.facets[0];

  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  [facet applyColorsOfStyle:story.currentStyle toAttributes:attributes];
  [facet applyFontOfStyle:story.currentStyle toAttributes:attributes];
  [facet applyLowerWindowAttributes:attributes];
  layoutView.lowerWindow.typingAttributes = attributes;
}

- (void)printCharToOutputStreams:(unichar)c {
  if (32 <= c && c <= 126) {
    uint8_t c8 = (uint8_t)c;
    [_commandOutputStream write:&c8 maxLength:1];
  } else {
    char buf[32];
    int len = snprintf(buf, 32, "[%d]", c);
    [_commandOutputStream write:(const uint8_t *)buf maxLength:len];
  }
  [_commandOutputStream write:(const uint8_t *)"\n" maxLength:1];
}

- (void)printToOutputStreams:(NSString *)text {
  if (_transcriptOutputStream || _commandOutputStream) {
    Story *story = self.document;
    const char *utf8String = text.UTF8String;
    size_t len = strlen(utf8String);
    if (_transcriptOutputStream && story.window == 0) {
      [_transcriptOutputStream write:(const uint8_t *)utf8String maxLength:len];
      [_transcriptOutputStream write:(const uint8_t *)"\n" maxLength:1];
    }
    if (_commandOutputStream) {
      const char *utf8String = text.UTF8String;
      [_commandOutputStream write:(const uint8_t *)utf8String maxLength:len];
      [_commandOutputStream write:(const uint8_t *)"\n" maxLength:1];
    }
  }
}

- (void)characterInput:(unichar)c {
  layoutView.lowerWindow.inputState = kNoInputState;
  Story *story = self.document;
  story.inputCharacter = c;
  [self printCharToOutputStreams:c];
  [self executeStory];
}

- (void)stringInput:(NSString *)string {
  layoutView.lowerWindow.inputState = kNoInputState;
  Story *story = self.document;
  story.inputString = string;
  [self printToOutputStreams:string];
  [self executeStory];
}

- (IBAction)reload:(id)sender {
  Story *story = self.document;
  [story revertDocumentToSaved:sender];
  [story.facets[0].textStorage
      deleteCharactersInRange:NSMakeRange(0,
                                          story.facets[0].textStorage.length)];
  [story.facets[1].textStorage
      deleteCharactersInRange:NSMakeRange(0,
                                          story.facets[1].textStorage.length)];
  [story.facets[1] setNumberOfLines:0];
  [self calculateStoryFacetDimensions];
  [self executeStory];
}

- (IBAction)showStoryInfo:(id)sender {
  if (!informationController) {
    Story *story = self.document;
    NSData *metaData = story.blorb.metaData;
    if (metaData) {
      NSData *pictureData = story.blorb.pictureData;
      IFictionMetadata *ifmd = [[IFictionMetadata alloc] initWithData:metaData];
      if (ifmd.stories.count > 0) {
        informationController = [[StoryInformationController alloc]
            initWithStoryMetadata:ifmd.stories[0]
                      pictureData:pictureData];
        [self.document addWindowController:informationController];
      }
    }
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
  [NSTimer
      scheduledTimerWithTimeInterval:0.0
                             repeats:NO
                               block:^(NSTimer *_Nonnull timer) {
                                 Story *story = self.document;
                                 [story.zMachine executeUntilHalt];
                                 if (story.hasEnded) {
                                   [self->layoutView.lowerWindow
                                       setInputState:kNoInputState];
                                   [self->_transcriptOutputStream close];
                                   [self->_commandOutputStream close];
                                   [self->_commandInputStream close];
                                 }
                                 [self synchronizeWindowTitleWithDocumentName];
                                 [self updateViews];
                               }];
}

- (BOOL)executeRoutine:(int)routine {
  Story *story = self.document;
  NSUInteger inputLoc = layoutView.lowerWindow.inputLocation;
  NSUInteger totalLen = story.facets[0].textStorage.length;
  NSUInteger inputLen = totalLen - inputLoc;
  NSAttributedString *inputSoFar = nil;

  if (totalLen > 0 && layoutView.lowerWindow.inputState == kStringInputState) {
    if (inputLen > 0) {
      inputSoFar = [story.facets[0].textStorage
          attributedSubstringFromRange:NSMakeRange(inputLoc, inputLen)];
    }
  }

  BOOL retVal = [story.zMachine callRoutine:routine];

  // If total text length is longer after the called routine, then text has been
  // printed to the output. The input location must be moved forward by that
  // amount, plus the length of the input we're leaving behind.
  // If any text had previously been entered, then that must now be appended
  // after the newly printed output.
  NSUInteger addedLen = story.facets[0].textStorage.length - totalLen;
  if (addedLen > 0) {
    layoutView.lowerWindow.inputLocation += addedLen + inputLen;
    if (inputSoFar)
      [story.facets[0].textStorage appendAttributedString:inputSoFar];
  }
  return retVal;
}

- (void)splitWindow:(int)lines {

  // Keep track of what the player has viewed after a split window
  NSTextView *textView = layoutView.lowerWindow;
  NSRect rect =
      [textView.layoutManager usedRectForTextContainer:textView.textContainer];
  CGFloat heightOfContent = rect.size.height;
  _viewedHeight = heightOfContent;
}

- (void)eraseWindow:(int)window {
  if (window == 0)
    _viewedHeight = 0.0;
}

- (void)print:(NSString *)text {
  Story *story = self.document;
  if (_transcriptOutputStream && story.window == 0) {
    const char *utf8String = text.UTF8String;
    [_transcriptOutputStream write:(const uint8_t *)utf8String
                         maxLength:strlen(utf8String)];
  }
}

- (void)printNumber:(int)number {
  [self print:(@(number)).stringValue];
}

- (void)newLine {
  [self print:@"\n"];
}

@end
