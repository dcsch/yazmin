//
//  StoryViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/16/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "StoryViewController.h"
#import "AbbreviationsController.h"
#import "Blorb.h"
#import "DebugController.h"
#import "GridStoryFacet.h"
#import "IFBibliographic.h"
#import "IFStory.h"
#import "IFictionMetadata.h"
#import "ObjectBrowserController.h"
#import "Preferences.h"
#import "Story.h"
#import "StoryFacet.h"
#import "StoryTextView.h"
#import "ZMachine.h"

typedef NS_ENUM(NSUInteger, SpeakingHistoryState) {
  SpeakMove,
  SpeakAtFirst,
  SpeakAtLast
};

@interface StoryViewController () {
  IBOutlet NSTextView *upperView;
  IBOutlet StoryTextView *lowerView;
  IBOutlet NSScrollView *lowerScrollView;
  IBOutlet NSLayoutConstraint *upperHeightConstraint;
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
  NSSpeechSynthesizer *_speechSynthesizer;
  NSMutableArray<NSMutableString *> *_moveStrings;
  SpeakingHistoryState _speakingHistoryState;
  NSInteger _lastSpokenMove;
  CGFloat _viewedHeight;
  BOOL _storyHasStarted;
}

- (int)calculateScreenWidthInColumns;
- (int)calculateLowerWindowHeightinLines;
- (void)calculateStoryFacetDimensions;
- (void)resizeUpperWindow:(int)lines;
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
- (IBAction)repeatMostRecentMove:(id)sender;
- (IBAction)speakPreviousMove:(id)sender;
- (IBAction)speakNextMove:(id)sender;
- (IBAction)speakStatus:(id)sender;
- (IBAction)showDebuggerWindow:(id)sender;
- (IBAction)showObjectBrowserWindow:(id)sender;
- (IBAction)showAbbreviationsWindow:(id)sender;
- (void)updateViews;
- (void)resolveStatusHeight;

@end

@implementation StoryViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  curheight = 0;
  maxheight = 0;
  seenheight = 0;

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
           object:self.view.window];

  // Lower Window
  lowerView.textContainerInset = NSMakeSize(20.0, 20.0);
  lowerView.storyInput = self;
  lowerView.inputView = YES;

  // Upper Window (initially zero height)
  upperView.textContainerInset = NSMakeSize(20.0, 10.0);
  upperView.textContainer.widthTracksTextView = YES;
  upperView.textContainer.heightTracksTextView = NO;
  upperView.textContainer.maximumNumberOfLines = 0;
  upperHeightConstraint.constant = 0.0;

  // Speech
  _speechSynthesizer = [[NSSpeechSynthesizer alloc] init];
  _moveStrings = [NSMutableArray array];
  _lastSpokenMove = -1;
  _speakingHistoryState = SpeakAtLast;
}

- (void)viewDidAppear {
  [super viewDidAppear];

  [self calculateStoryFacetDimensions];

  if (!_storyHasStarted) {
    // Kick off the story
    [self executeStory];
    _storyHasStarted = YES;
  }
}

- (void)setRepresentedObject:(id)representedObject {
  [super setRepresentedObject:representedObject];

  if (representedObject) {
    Story *story = self.representedObject;
    story.facets[0].textStorage = lowerView.textStorage;
    story.facets[1].textStorage = upperView.textStorage;
  }
}

- (int)calculateScreenWidthInColumns {
  Story *story = self.representedObject;
  NSFont *font = [story.facets[0] fontForStyle:8];
  float lineWidth = upperView.textContainer.size.width;
  float charWidth = [font advancementForGlyph:0].width;
  return lineWidth / charWidth;
}

- (int)calculateLowerWindowHeightinLines {
  // TODO: This is using frame height rather than layout height as the layout
  // height was coming through as some rediculously large number. Needs to be
  // checked as frame height won't account for the text container inset
  // (does NSTextContainer size do that?)
  CGFloat frameHeight = lowerView.frame.size.height;
  Story *story = self.representedObject;
  NSFont *font = [story.facets[0] fontForStyle:0];
  CGFloat lineHeight = [upperView.layoutManager defaultLineHeightForFont:font];
  return MIN((int)(frameHeight / lineHeight), 255);
}

- (void)calculateStoryFacetDimensions {
  int screenWidthInChars = [self calculateScreenWidthInColumns];
  Story *story = self.representedObject;
  story.facets[0].widthInCharacters = screenWidthInChars;
  story.facets[1].widthInCharacters = screenWidthInChars;
  story.facets[1].heightInLines = [self calculateLowerWindowHeightinLines];
  [story.zMachine updateScreenSize];
  NSLog(@"Set screen size as: %d x %d", screenWidthInChars,
        story.facets[1].heightInLines);
}

- (void)resizeUpperWindow:(int)lines {
  Story *story = self.representedObject;
  GridStoryFacet *facet = (GridStoryFacet *)story.facets[1];
  NSFont *font = [facet fontForStyle:8];
  CGFloat lineHeight = [upperView.layoutManager defaultLineHeightForFont:font];
  CGFloat upperHeight =
      lines > 0 ? lineHeight * lines + 2.0 * upperView.textContainerInset.height
                : 0;
  upperHeightConstraint.constant = upperHeight;
  upperView.textContainer.maximumNumberOfLines = lines;

  // Scroll the lower window to compensate for the shift in position
  // (we're keeping this simple for now: just scroll to the bottom)
  [lowerView scrollPoint:NSMakePoint(0, lowerView.frame.size.height)];
}

- (void)handleWindowWillClose:(NSNotification *)note {
  [_transcriptOutputStream close];
  [_commandOutputStream close];
  [_commandInputStream close];

  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}

- (void)handleViewFrameChange:(NSNotification *)note {
  //  if (note.object == layoutView) {
  //    [self calculateStoryFacetDimensions];
  //    Story *story = self.representedObject;
  //    story.zMachine.needsRedraw = YES;
  //  }
}

- (void)handleBackgroundColorChange:(NSNotification *)note {
  Preferences *prefs = note.object;
  NSColor *newColor = prefs.backgroundColor;
  lowerView.backgroundColor = newColor;
  upperView.backgroundColor = newColor;
  self.view.needsDisplay = YES;
}

- (void)handleForegroundColorChange:(NSNotification *)note {
  NSLog(@"handleForegroundColorChange:");
}

- (void)scrollLowerWindowToEnd {
  if (lowerView.textStorage.length == 0)
    return;

  [lowerView.layoutManager
      ensureLayoutForTextContainer:lowerView.textContainer];

  NSRect rect = [lowerView.layoutManager
      usedRectForTextContainer:lowerView.textContainer];
  NSSize inset = lowerView.textContainerInset;
  CGFloat heightOfContent = rect.size.height + 2.0 * inset.height;
  CGFloat heightOfWindow = lowerScrollView.frame.size.height;

  CGFloat blockHeight = heightOfContent - _viewedHeight;

  // TODO: Should we round blockHeight down to a multiple of line height?

  //  NSLog(@"block height: %f", blockHeight);

  if (blockHeight > heightOfWindow) {

    // TODO: There is more text than can be shown in the window, so we must
    // present a "more" prompt
    NSLog(@"[MORE]");

    _viewedHeight += heightOfWindow;
    [lowerView scrollPoint:NSMakePoint(0, _viewedHeight - heightOfWindow)];
    lowerView.moreToDisplay = YES;
  } else {

    // This block will fit within the window, so just scroll to the
    // end of it
    [lowerView scrollPoint:NSMakePoint(0, heightOfContent)];
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
  Story *story = self.representedObject;
  NSUInteger len = story.facets[0].textStorage.length;
  [lowerView setInputLocation:len + offset];
  if (_commandInputStream) {
    NSString *inputString = [self playbackInputString];
    [lowerView enterString:inputString];
    if (inputString.length > 0) {
      [self executeStory];
      return;
    } else {
      [_commandInputStream close];
      _commandInputStream = nil;
    }
  }
  [lowerView setInputState:kStringInputState];
  [self scrollLowerWindowToEnd];
}

- (void)prepareInputChar {
  [self resolveStatusHeight];
  [lowerView setInputState:kCharacterInputState];
  [self scrollLowerWindowToEnd];
}

- (void)restoreSession {
  NSOpenPanel *panel = [NSOpenPanel openPanel];
  panel.allowedFileTypes = @[ @"qut" ];
  [panel beginSheetModalForWindow:self.view.window
                completionHandler:^(NSInteger result) {
                  Story *story = self.representedObject;
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
  [panel beginSheetModalForWindow:self.view.window
                completionHandler:^(NSInteger result) {
                  Story *story = self.representedObject;
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
    Story *story = self.representedObject;
    panel.nameFieldStringValue = [NSString
        stringWithFormat:@"%@ Transcript (%@)", story.displayName,
                         [NSDate.date
                             descriptionWithLocale:NSLocale.currentLocale]];
    [panel beginSheetModalForWindow:self.view.window
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
    Story *story = self.representedObject;
    panel.nameFieldStringValue = [NSString
        stringWithFormat:@"%@ Commands (%@)", story.displayName,
                         [NSDate.date
                             descriptionWithLocale:NSLocale.currentLocale]];
    [panel beginSheetModalForWindow:self.view.window
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
    [panel beginSheetModalForWindow:self.view.window
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
  [alert beginSheetModalForWindow:self.view.window
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
  Story *story = self.representedObject;
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

  [self resizeUpperWindow:maxheight];
  self.view.needsLayout = YES;
}

- (void)updateWindowBackgroundColor {
  Story *story = self.representedObject;
  lowerView.backgroundColor = story.backgroundColor;
  upperView.backgroundColor = story.backgroundColor;
  lowerView.insertionPointColor = story.foregroundColor;
}

// If the status height is too large because of last turn's quote box,
// shrink it down now.
// This must be called immediately before any input event. (That is,
// the beginning of the @read and @read_char opcodes.)
- (void)resolveStatusHeight {

  // If the player has seen the entire window, we can shrink it.
  if (seenheight == maxheight)
    maxheight = curheight;

  if (upperView.textContainer.maximumNumberOfLines != maxheight) {
    [self resizeUpperWindow:maxheight];
    self.view.needsLayout = YES;
  }

  seenheight = maxheight;
  maxheight = curheight;
}

- (void)updateTextAttributes {
  // Set the typing attributes of the lower window so they reflect the change
  Story *story = self.representedObject;
  StoryFacet *facet = story.facets[0];

  NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
  [facet applyColorsOfStyle:story.currentStyle toAttributes:attributes];
  [facet applyFontOfStyle:story.currentStyle toAttributes:attributes];
  [facet applyLowerWindowAttributes:attributes];
  lowerView.typingAttributes = attributes;
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
    Story *story = self.representedObject;
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
  lowerView.inputState = kNoInputState;
  Story *story = self.representedObject;
  story.inputCharacter = c;
  [self printCharToOutputStreams:c];
  [self executeStory];
}

- (void)stringInput:(NSString *)string {
  lowerView.inputState = kNoInputState;
  Story *story = self.representedObject;
  story.inputString = string;
  [self printToOutputStreams:string];
  [self executeStory];
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender {
  Story *story = self.representedObject;
  [story addWindowController:segue.destinationController];
}

// TODO: Internationalzation of these strings

- (NSString *)speakingStringForMove:(NSUInteger)move
                    includePosition:(BOOL)includePosition {
  NSString *string = _moveStrings[move];
  NSMutableString *speakingString = [NSMutableString string];
  if (includePosition) {
    if (move == 0)
      [speakingString appendString:@"Start. "];
    else if (move == _moveStrings.count - 1)
      [speakingString appendString:@"Most recent move. "];
    else {
      NSUInteger movesFromEnd = _moveStrings.count - move;
      [speakingString appendFormat:@"%lu moves ago. ", (unsigned long)movesFromEnd];
    }
  }

  __block BOOL previousLineNotEmpty = NO;
  __block BOOL previousLineEndedWithoutPeriod = NO;
  [string enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
    if (previousLineNotEmpty && previousLineEndedWithoutPeriod)
      [speakingString appendString:@"."];

    if (line.length > 0) {
      if (speakingString.length > 0)
        [speakingString appendString:@" "];
      [speakingString appendString:line];
    }

    previousLineNotEmpty = line.length > 0;
    previousLineEndedWithoutPeriod = ![line hasSuffix:@"."];
  }];
  return speakingString;
}

#pragma mark - Actions

- (IBAction)reload:(id)sender {
  Story *story = self.representedObject;
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

- (IBAction)repeatMostRecentMove:(id)sender {
  NSUInteger move = _moveStrings.count - 1;
  NSString *speakingString = [self speakingStringForMove:move includePosition:NO];
  [_speechSynthesizer startSpeakingString:speakingString];
}

- (IBAction)speakPreviousMove:(id)sender {

  if (_speakingHistoryState == SpeakAtFirst) {
    NSLog(@"Speak no previous moves");
    return;
  }

  if (_lastSpokenMove == -1)
    _lastSpokenMove = _moveStrings.count - 1;

  if (_lastSpokenMove == 0)
    _speakingHistoryState = SpeakAtFirst;
  else {
    _speakingHistoryState = SpeakMove;
    --_lastSpokenMove;
  }

  NSLog(@"Speak move: %ld", (long)_lastSpokenMove);

  //  NSInteger move = -1;
//  if (_lastSpokenMove == -1) {
//    move = _moveStrings.count - 1;
//    _lastSpokenMove = move;
//  } else {
//    move = _lastSpokenMove - 1;
//  }
//  if (move >= 0) {
//    NSString *speakingString = [self speakingStringForMove:move includePosition:YES];
//    [_speechSynthesizer startSpeakingString:speakingString];
//    NSLog(@"Speaking move %lu", move);
//  } else {
//    [_speechSynthesizer startSpeakingString:@"No previous moves"];
//  }
}

- (IBAction)speakNextMove:(id)sender {

  if (_lastSpokenMove == -1) {
    _speakingHistoryState = SpeakMove;
    _lastSpokenMove = _moveStrings.count - 1;
  }

  if (_speakingHistoryState == SpeakAtLast) {
    NSLog(@"Speak no further moves");
    return;
  }

  if (_speakingHistoryState == SpeakAtFirst) {
    _speakingHistoryState = SpeakMove;
    _lastSpokenMove = 0;
  } else {
    ++_lastSpokenMove;
  }

  if (_lastSpokenMove == _moveStrings.count - 1) {
    _speakingHistoryState = SpeakAtLast;
  }

  NSLog(@"Speak move: %ld", (long)_lastSpokenMove);

//  NSInteger move = -1;
//  if (_lastSpokenMove == -1) {
//    move = _moveStrings.count - 1;
//    _lastSpokenMove = move;
//  } else {
//    move = _lastSpokenMove + 1;
//  }
//  if (move > _moveStrings.count - 1) {
//    NSString *speakingString = [self speakingStringForMove:move includePosition:YES];
//    [_speechSynthesizer startSpeakingString:speakingString];
//    NSLog(@"Speaking move %lu", move);
//  } else {
//    [_speechSynthesizer startSpeakingString:@"No further moves"];
//  }
}

- (IBAction)speakStatus:(id)sender {
  _lastSpokenMove = -1;
  [_speechSynthesizer stopSpeaking];
}

- (IBAction)showDebuggerWindow:(id)sender {
  if (!debugController) {
    debugController = [[DebugController alloc] init];
    [self.representedObject addWindowController:debugController];
  }
  [debugController showWindow:self];
}

- (IBAction)showObjectBrowserWindow:(id)sender {
  if (!objectBrowserController) {
    objectBrowserController = [[ObjectBrowserController alloc] init];
    [self.representedObject addWindowController:objectBrowserController];
  }
  [objectBrowserController showWindow:self];
}

- (IBAction)showAbbreviationsWindow:(id)sender {
  if (!abbreviationsController) {
    abbreviationsController = [[AbbreviationsController alloc] init];
    [self.representedObject addWindowController:abbreviationsController];
  }
  [abbreviationsController showWindow:self];
}

#pragma mark -

- (void)updateViews {
  [objectBrowserController update];
}

- (void)executeStory {
  [_moveStrings addObject:[NSMutableString string]];
  _lastSpokenMove = -1;
  _speakingHistoryState = SpeakAtLast;
  [NSTimer
      scheduledTimerWithTimeInterval:0.0
                             repeats:NO
                               block:^(NSTimer *_Nonnull timer) {
                                 Story *story = self.representedObject;
                                 [story.zMachine executeUntilHalt];
                                 if (story.hasEnded) {
                                   [self->lowerView
                                       setInputState:kNoInputState];
                                   [self->_transcriptOutputStream close];
                                   [self->_commandOutputStream close];
                                   [self->_commandInputStream close];
                                 }
                                 [story.windowControllers[0]
                                     synchronizeWindowTitleWithDocumentName];
                                 [self updateViews];
                               }];
}

- (BOOL)executeRoutine:(int)routine {
  Story *story = self.representedObject;
  NSUInteger inputLoc = lowerView.inputLocation;
  NSUInteger totalLen = story.facets[0].textStorage.length;
  NSUInteger inputLen = totalLen - inputLoc;
  NSAttributedString *inputSoFar = nil;

  if (totalLen > 0 && lowerView.inputState == kStringInputState) {
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
    lowerView.inputLocation += addedLen + inputLen;
    if (inputSoFar)
      [story.facets[0].textStorage appendAttributedString:inputSoFar];
  }
  return retVal;
}

- (void)splitWindow:(int)lines {

  // Keep track of what the player has viewed after a split window
  NSTextView *textView = lowerView;
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
  Story *story = self.representedObject;
  if (story.window == 0) {
    [_moveStrings.lastObject appendString:text];
    if (_transcriptOutputStream) {
      const char *utf8String = text.UTF8String;
      [_transcriptOutputStream write:(const uint8_t *)utf8String
                           maxLength:strlen(utf8String)];
    }
  }
}

- (void)printNumber:(int)number {
  [self print:(@(number)).stringValue];
}

- (void)newLine {
  [self print:@"\n"];
}

@end
