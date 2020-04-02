//
//  Story.m
//  Yazmin
//
//  Created by David Schweinsberg on 2/07/07.
//  Copyright David Schweinsberg 2007. All rights reserved.
//

#import "Story.h"
#import "AppController.h"
#import "Blorb.h"
#import "BlorbResource.h"
#import "DebugInfo.h"
#import "DebugInfoReader.h"
#import "GridStoryFacet.h"
#import "IFAnnotation.h"
#import "IFIdentification.h"
#import "IFStory.h"
#import "IFYazmin.h"
#import "IFictionMetadata.h"
#import "InformationWindowController.h"
#import "Library.h"
#import "LibraryEntry.h"
#import "Preferences.h"
#import "SoundEffect.h"
#import "StoryFacet.h"
#import "StoryViewController.h"
#import "ZMachine.h"

const NSPasteboardType PasteboardTypeZcodeStory = @"public.zcode";
const NSPasteboardType PasteboardTypeZcodeBlorb = @"public.blorb.zcode";
const NSArray<NSString *> *AllowedFileTypes;

@interface Story () {
  NSArray<StoryFacet *> *_facets;
  NSColor *_foregroundColor;
  NSColor *_backgroundColor;
  BOOL _justSetTextStyle;
  NSUInteger _upperWindowSeenHeight;
  StoryFacet *_storyFacet;
  NSSound *_lowSound;
  NSSound *_highSound;
  NSDictionary<NSNumber *, SoundEffect *> *_soundEffects;
  NSTimer *_timer;
}

@property BOOL screenEnabled;

- (void)handleBackgroundColorChange:(NSNotification *)note;
- (void)handleForegroundColorChange:(NSNotification *)note;
- (void)handleFontChange:(NSNotification *)note;
- (void)handleCoverImageChange:(NSNotification *)note;

- (void)createZMachine;
- (NSColor *)colorFromCode:(int)colorCode
              currentColor:(NSColor *)currentColor
              defaultColor:(NSColor *)defaultColor;
- (NSColor *)colorFromTrueColor:(int)trueColor
                   currentColor:(NSColor *)currentColor
                   defaultColor:(NSColor *)defaultColor;

@end

@implementation Story

+ (void)initialize {
  AllowedFileTypes = @[ @"z3", @"z4", @"z5", @"z7", @"z8", @"zblorb" ];
}

- (instancetype)init {
  self = [super init];
  if (self) {

    // Create two facets (lower and upper), with the upper one being
    // a text grid
    StoryFacet *lowerFacet = [[StoryFacet alloc] initWithStory:self];
    GridStoryFacet *upperFacet = [[GridStoryFacet alloc] initWithStory:self];
    _facets = @[ lowerFacet, upperFacet ];

    self.screenEnabled = YES;

    // Default to the first facet (Z-machine window 0)
    self.window = 0;

    // Default colors
    [self setColorForeground:1 background:1];

    // Text style attributes
    [self setTextStyle:0];

    _lowSound = [NSSound soundNamed:@"Bottle"];
    _highSound = [NSSound soundNamed:@"Hero"];

    [self setHasUndoManager:NO];

    // Listen to notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(handleBackgroundColorChange:)
               name:SMBackgroundColorChangedNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleForegroundColorChange:)
               name:SMForegroundColorChangedNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleFontChange:)
               name:SMProportionalFontFamilyChangedNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleFontChange:)
               name:SMMonospacedFontFamilyChangedNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleFontChange:)
               name:SMFontSizeChangedNotification
             object:nil];
    [nc addObserver:self
           selector:@selector(handleCoverImageChange:)
               name:SMCoverImageChangedNotification
             object:nil];
  }
  return self;
}

- (void)close {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
  [super close];
}

- (void)makeWindowControllers {
  NSStoryboard *storyboard = NSStoryboard.mainStoryboard;
  NSWindowController *windowController =
      [storyboard instantiateControllerWithIdentifier:@"StoryWindow"];
  [self addWindowController:windowController];

  _storyViewController =
      (StoryViewController *)windowController.contentViewController;
}

- (IBAction)showStoryInfo:(id)sender {

  // Is it already being displayed?
  for (NSWindowController *windowController in self.windowControllers) {
    if ([windowController isKindOfClass:InformationWindowController.class]) {
      [windowController.window makeKeyAndOrderFront:self];
      return;
    }
  }

  NSStoryboard *storyboard = NSStoryboard.mainStoryboard;
  NSWindowController *windowController =
      [storyboard instantiateControllerWithIdentifier:@"InformationWindow"];
  [self addWindowController:windowController];
  [self showWindows];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
  return nil;
}

- (void)createZMachine {
  _zMachine = [[ZMachine alloc] initWithStory:self];

  // Do we have an IFID?  If not, find one
  if (_ifid == nil)
    _ifid = _zMachine.ifid;
}

- (BOOL)readFromFileWrapper:(NSFileWrapper *)fileWrapper
                     ofType:(NSString *)typeName
                      error:(NSError **)outError {
  if ([typeName compare:@"Inform Project"] == 0) {
    NSFileWrapper *zcodeWrapper = nil;
    NSFileWrapper *debugWrapper = nil;

    // Pick out the 'Build' directory
    NSFileWrapper *buildDir = fileWrapper.fileWrappers[@"Build"];
    if (buildDir) {
      NSDictionary *filesInDirectory = buildDir.fileWrappers;
      NSEnumerator *fileEnum = [filesInDirectory keyEnumerator];
      NSString *filePath;
      while ((filePath = [fileEnum nextObject])) {
        NSString *pathExtension = filePath.pathExtension;

        // Likely to be 'output.z5' or 'output.z8', so we'll just look
        // for the initial 'z' and go with that
        if ([pathExtension characterAtIndex:0] == 'z')
          zcodeWrapper = filesInDirectory[filePath];
        else if ([pathExtension compare:@"dbg"] == 0)
          debugWrapper = filesInDirectory[filePath];
      }
    } else {
      *outError = [NSError
          errorWithDomain:@"No build directory found within project bundle"
                     code:666
                 userInfo:nil];
      return NO;
    }

    if (zcodeWrapper) {
      _zcodeData = zcodeWrapper.regularFileContents;
      [self createZMachine];
      if (debugWrapper) {
        NSData *debugData = debugWrapper.regularFileContents;
        DebugInfoReader *reader =
            [[DebugInfoReader alloc] initWithData:debugData];
        _debugInfo = [reader debugInfo];
      }
      return YES;
    } else {
      *outError = [NSError
          errorWithDomain:@"No z-code output file found within project bundle"
                     code:666
                 userInfo:nil];
      return NO;
    }
  } else
    return [super readFromFileWrapper:fileWrapper
                               ofType:typeName
                                error:outError];
}

- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError {
  _blorb = nil;
  IFStory *blorbMetadata = nil;

  if ([typeName compare:@"Z-code Blorb"] == 0) {
    // This is a blorb, so we need to unwrap
    if ([Blorb isBlorbData:data]) {
      _blorb = [[Blorb alloc] initWithData:data];
      NSData *mddata = _blorb.metaData;
      if (mddata) {
        IFictionMetadata *ifmd = [[IFictionMetadata alloc] initWithData:mddata];
        if (ifmd.stories.count > 0) {
          blorbMetadata = ifmd.stories[0];
          if (blorbMetadata.identification.ifids.count > 0)
            _ifid = blorbMetadata.identification.ifids[0];
        }
      }
      NSData *imageData = _blorb.pictureData;
      if (imageData)
        _coverImage = [[NSImage alloc] initWithData:imageData];
      _zcodeData = _blorb.zcodeData;
    }
  } else {
    // Treat this data as executable z-code story data
    _zcodeData = data;
  }

  if (_zcodeData) {
    [self createZMachine];

    AppController *appController = NSApp.delegate;

    // Retrieve metadata from the library, now that we have an IFID
    _metadata = [appController.library metadataForIFID:_ifid];
    if (!_metadata) {

      // Not available?
      // - Generate empty metadata
      // - Use any Blorb metadata
      // - Look for default metadata
      _metadata = [[IFStory alloc] initWithIFID:_ifid storyURL:self.fileURL];
      if (blorbMetadata)
        [_metadata updateFromStory:blorbMetadata];
      else {
        IFStory *metadata =
            [appController.library defaultMetadataForIFID:_ifid];
        if (metadata)
          [_metadata updateFromStory:metadata];
      }
    }

    NSMutableDictionary<NSNumber *, SoundEffect *> *soundEffects =
        [NSMutableDictionary dictionary];
    soundEffects[@1] = [[SoundEffect alloc] initWithSound:_lowSound];
    soundEffects[@2] = [[SoundEffect alloc] initWithSound:_highSound];
    soundEffects[@0] = soundEffects[@1];

    // Load any resource blorb
    NSURL *resourceURL = _metadata.annotation.yazmin.blorbURL;
    if (resourceURL) {
      NSData *data = [NSData dataWithContentsOfURL:resourceURL];
      Blorb *blorb = [[Blorb alloc] initWithData:data];

      // Assign sounds
      NSArray<BlorbResource *> *soundResources =
          [blorb resourcesForUsage:SoundResource];
      for (BlorbResource *soundResource in soundResources) {
        NSData *soundData = [blorb dataForResource:soundResource];
        NSSound *sound = [[NSSound alloc] initWithData:soundData];
        SoundEffect *se = [[SoundEffect alloc] initWithSound:sound];
        soundEffects[@(soundResource.number)] = se;
      }
    }
    _soundEffects = soundEffects;

    // Retrieve any cover art that may have been assigned to this story
    if (!_coverImage) {
      AppController *appController = NSApp.delegate;
      _coverImage = [appController.library imageForIFID:_ifid];
    }

    // Is there any debug information to load?
    NSString *path = self.fileURL.path;
    if (path) {
      NSString *folderPath = path.stringByDeletingLastPathComponent;
      NSString *debugInfoPath =
          [folderPath stringByAppendingPathComponent:@"gameinfo.dbg"];
      NSURL *debugInfoURL = [NSURL fileURLWithPath:debugInfoPath];
      NSData *debugData = [NSData dataWithContentsOfURL:debugInfoURL];
      if (debugData) {
        DebugInfoReader *reader =
            [[DebugInfoReader alloc] initWithData:debugData];
        _debugInfo = [reader debugInfo];
      }
    }

    return YES;
  } else {
    *outError = [NSError errorWithDomain:@"Unsupported file format"
                                    code:666
                                userInfo:nil];
    return NO;
  }
}

- (BOOL)hasEnded {
  return [_zMachine hasQuit];
}

- (void)restoreSession {
  [_storyViewController restoreSession];
}

- (void)saveSessionData:(NSData *)data {
  [_storyViewController saveSessionData:data];
}

- (void)error:(NSString *)errorMessage {
  [_storyViewController showError:errorMessage];
}

- (void)updateWindowBackgroundColor {
  [_storyViewController updateWindowBackgroundColor];
}

#pragma mark - Notifications

- (void)handleBackgroundColorChange:(NSNotification *)note {
  //    Preferences *sender = [note object];
  //    NSColor *newColor = [sender backgroundColor];
  //    [[layoutView lowerWindow] setBackgroundColor:newColor];
  //    [[layoutView upperWindow] setBackgroundColor:newColor];
  //    [layoutView setNeedsDisplay:YES];
}

- (void)handleForegroundColorChange:(NSNotification *)note {
  NSLog(@"handleForegroundColorChange:");
}

- (void)handleFontChange:(NSNotification *)note {
  for (StoryFacet *facet in _facets)
    [facet updateFontPreferences];
  [_storyViewController updateTextAttributes];
  //[_storyViewController updateWindowLayout];
}

- (void)handleCoverImageChange:(NSNotification *)note {
  AppController *appController = NSApp.delegate;
  _coverImage = [appController.library imageForIFID:_ifid];
}

#pragma mark -

- (void)beginInputWithOffset:(NSInteger)offset {
  _upperWindowSeenHeight = _facets[1].numberOfLines;
  [_storyViewController prepareInputWithOffset:offset];
}

- (NSString *)endInput {
  // 'input' consumes the input string
  NSString *retString = _inputString;
  _inputString = nil;
  return retString;
}

- (void)beginInputChar {
  _inputCharacter = 0;
  _upperWindowSeenHeight = _facets[1].numberOfLines;
  [_storyViewController prepareInputChar];
}

- (unichar)endInputChar {
  return _inputCharacter;
}

- (void)outputStream:(int)number {
  [_storyViewController outputStream:number];
  switch (number) {
  case 1:
    _screenEnabled = true;
    break;
  case -1:
    _screenEnabled = false;
    break;
  }
}

- (void)inputStream:(int)number {
  [_storyViewController inputStream:number];
}

- (int)closestColorCodeToColor:(NSColor *)color {
  color = [color colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
  CGFloat r1, g1, b1, a1;
  [color getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
  int closestCode = 0;
  CGFloat closestDistance = 2.0;
  for (int i = 2; i <= 9; ++i) {
    NSColor *paletteColor = [[self colorFromCode:i
                                    currentColor:nil
                                    defaultColor:nil]
        colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
    CGFloat r2, g2, b2, a2;
    [paletteColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

    CGFloat dr = fabs(r2 - r1);
    CGFloat dg = fabs(g2 - g1);
    CGFloat db = fabs(b2 - b1);
    CGFloat distance = sqrt(dr * dr + dg * dg + db * db);

    if (closestDistance > distance) {
      closestDistance = distance;
      closestCode = i;
    }
  }
  return closestCode;
}

- (int)foregroundColorCode {
  return [self closestColorCodeToColor:_foregroundColor];
}

- (int)backgroundColorCode {
  return [self closestColorCodeToColor:_backgroundColor];
}

// From the Z-machine standard 1.1 (8.3.1):
// 0 = current     (true -2)
// 1 = default     (true -1)
// 2 = black       (true $0000, $$0000000000000000)
// 3 = red         (true $001D, $$0000000000011101)
// 4 = green       (true $0340, $$0000001101000000)
// 5 = yellow      (true $03BD, $$0000001110111101)
// 6 = blue        (true $59A0, $$0101100110100000)
// 7 = magenta     (true $7C1F, $$0111110000011111)
// 8 = cyan        (true $77A0, $$0111011110100000)
// 9 = white       (true $7FFF, $$0111111111111111)
- (NSColor *)colorFromCode:(int)colorCode
              currentColor:(NSColor *)currentColor
              defaultColor:(NSColor *)defaultColor {
  switch (colorCode) {
  case 0:
    return currentColor;
  case 1:
    return defaultColor;
  case 2:
    return [NSColor blackColor];
  case 3:
    return [NSColor redColor];
  case 4:
    return [NSColor greenColor];
  case 5:
    return [NSColor yellowColor];
  case 6:
    return [NSColor blueColor];
  case 7:
    return [NSColor magentaColor];
  case 8:
    return [NSColor cyanColor];
  case 9:
    return [NSColor whiteColor];
  }
  return currentColor;
}

- (void)setColorForeground:(int)fg background:(int)bg {
  _foregroundColor = [self colorFromCode:fg
                            currentColor:_foregroundColor
                            defaultColor:[NSColor textColor]];
  _backgroundColor = [self colorFromCode:bg
                            currentColor:_backgroundColor
                            defaultColor:[NSColor textBackgroundColor]];
}

- (NSColor *)colorFromTrueColor:(int)trueColor
                   currentColor:(NSColor *)currentColor
                   defaultColor:(NSColor *)defaultColor {
  if (trueColor == -2)
    return currentColor;
  else if (trueColor == -1)
    return defaultColor;
  uint8 r = trueColor & 0x1f;
  uint8 g = (trueColor >> 5) & 0x1f;
  uint8 b = (trueColor >> 10) & 0x1f;
  return [NSColor colorWithRed:r / 31.0 green:g / 31.0 blue:b / 31.0 alpha:1.0];
}

- (void)setTrueColorForeground:(int)fg background:(int)bg {
  _foregroundColor = [self colorFromTrueColor:fg
                                 currentColor:_foregroundColor
                                 defaultColor:[NSColor textColor]];
  _backgroundColor = [self colorFromTrueColor:bg
                                 currentColor:_backgroundColor
                                 defaultColor:[NSColor textBackgroundColor]];
}

- (void)setTextStyle:(int)style {

  // If multiple style commands are sent in a sequence, we'll
  // OR together the values, otherwise we'll just use the value
  // directly.
  if (style == 0)
    _currentStyle = style;
  else if (_justSetTextStyle)
    _currentStyle |= style;
  else
    _currentStyle = style;
  _justSetTextStyle = YES;
}

- (void)hackyDidntSetTextStyle {
  _justSetTextStyle = NO;
}

- (int)screenWidth {
  return _facets[1].widthInCharacters;
}

- (int)screenHeight {
  return _facets[1].heightInLines;
}

- (int)window {
  if (_storyFacet == _facets[1])
    return 1;
  else
    return 0;
}

- (void)setWindow:(int)window {
  _storyFacet = _facets[window];
  [_storyViewController setWindow:window];
}

- (void)splitWindow:(int)lines {
  GridStoryFacet *storyFacet = (GridStoryFacet *)_facets[1];

  // If upper window is being shrunk down after being expanded within
  // a single move, then this is a box quote, so grab a copy of the
  // box quote text and imprint on to the lower window.
  if (storyFacet.numberOfLines > _upperWindowSeenHeight &&
      storyFacet.numberOfLines > lines) {
    NSAttributedString *str =
        [storyFacet attributedStringFromLine:(int)_upperWindowSeenHeight + 1];
    [_storyViewController printBox:str];
  }

  if (_zMachine.version == 3 && lines > 1) {
    // Make room for v3 status line
    lines++;
  }

  [storyFacet eraseFromLine:lines + 1];
  storyFacet.numberOfLines = lines;
  if (lines == 0)
    _storyFacet = _facets[0];
  [_storyViewController splitWindow:lines];
}

- (void)eraseWindow:(int)window {

  // -1 unsplits the screen and clears
  // -2 clears all windows without unsplitting
  if (window < 0) {
    if (window == -1)
      [self splitWindow:0];
    [self eraseWindow:0];
    [self eraseWindow:1];
  } else {
    [_facets[window] erase];
    [_storyViewController eraseWindow:window];
  }
}

- (void)eraseLine {
  [_storyFacet eraseLine];
}

- (int)line {
  return _storyFacet.line;
}

- (int)column {
  return _storyFacet.column;
}

- (void)setCursorLine:(int)line column:(int)column {
  [_storyFacet setCursorLine:line column:column];
  [_storyViewController setCursorLine:line column:column];
}

- (int)fontId {
  return _storyFacet.fontID;
}

- (void)setFontId:(int)fontId {
  _storyFacet.fontID = fontId;
}

- (void)print:(NSString *)text {
  _forceFixedPitchFont = _zMachine.forcedFixedPitchFont;
  if (_screenEnabled)
    [_storyFacet print:text];
  [_storyViewController print:text];
}

- (void)printNumber:(int)number {
  _forceFixedPitchFont = _zMachine.forcedFixedPitchFont;
  if (_screenEnabled)
    [_storyFacet printNumber:number];
  [_storyViewController printNumber:number];
}

- (void)newLine {
  if (_screenEnabled)
    [_storyFacet newLine];
  [_storyViewController newLine];
}

- (void)showStatus {

  // Check that there is a current object
  unsigned int objectNumber = [_zMachine globalAtIndex:0];
  if (objectNumber == 0)
    return;

  // Generate a version 1-3 status line
  StoryFacet *storyFacet = _facets[1];
  if (storyFacet.numberOfLines == 0)
    [self splitWindow:1];
  self.window = 1;

  // Display an inverse video bar
  int screenWidth = self.screenWidth;
  [storyFacet setCursorLine:1 column:1];
  [self setTextStyle:1];
  for (unsigned int i = 0; i < screenWidth; ++i)
    [storyFacet print:@" "];

  // Overlay with text
  [storyFacet setCursorLine:1 column:2];

  // From the spec:
  // Section 8.2.2
  // The short name of the object whose number is in the first global variable
  // should be printed on the left hand side of the line.
  unsigned int scoreAndMovesLen;
  bool shortDisplay;
  if (screenWidth >= 72) {
    scoreAndMovesLen = 23;
    shortDisplay = false;
  } else {
    scoreAndMovesLen = 8;
    shortDisplay = true;
  }
  unsigned int maxNameLen = MAX(0, screenWidth - scoreAndMovesLen);
  NSString *name = [_zMachine nameOfObject:objectNumber];
  if (name.length <= maxNameLen) {
    [storyFacet print:name];
  } else {
    // TODO: Put an ellipsis at the last space that fits in the available line
    [storyFacet print:name];
  }
  [storyFacet setCursorLine:1 column:screenWidth - scoreAndMovesLen];

  if (_zMachine.isTimeGame) {
    unsigned int hour = [_zMachine globalAtIndex:1];
    unsigned int min = [_zMachine globalAtIndex:2];
    BOOL isAM = hour < 12;
    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }
    if (!shortDisplay)
      [storyFacet print:@"Time:  "];
    [storyFacet printNumber:hour];
    [storyFacet print:@":"];
    if (min < 10)
      [storyFacet printNumber:0];
    [storyFacet printNumber:min];
    [storyFacet print:isAM ? @" AM" : @" PM"];
  } else {
    if (!shortDisplay)
      [storyFacet print:@"Score: "];
    [storyFacet printNumber:(int)[_zMachine globalAtIndex:1]];
    if (!shortDisplay)
      [storyFacet print:@"  Moves: "];
    else
      [storyFacet print:@"/"];
    [storyFacet printNumber:[_zMachine globalAtIndex:2]];
  }

  // Prepare to display Seastalker sonarscope
  if (storyFacet.numberOfLines > 1)
    [storyFacet setCursorLine:2 column:1];

  [self setTextStyle:0];
  self.window = 0;
}

- (void)soundEffectNumber:(int)number
                   effect:(int)effect
                   repeat:(int)repeat
                   volume:(int)volume {
  if (effect == 0)
    effect = 2;

  if (effect == 2) {
    SoundEffect *soundEffect = _soundEffects[@(number)];
    if (repeat == 0)
      repeat = 1;
    soundEffect.repeat = repeat;
    if (volume == 255)
      soundEffect.sound.volume = 1.0;
    else
      soundEffect.sound.volume = volume / 8.0;
    [soundEffect.sound play];
  } else if (effect == 3 || effect == 4) {
    if (number == 0) {
      // Stop all sound effects
      for (SoundEffect *soundEffect in _soundEffects.allValues)
        [soundEffect.sound stop];
    }
  }
}

- (void)startTime:(int)time routine:(int)routine {
  NSTimeInterval interval = time / 10.0;
  _timer = [NSTimer
      scheduledTimerWithTimeInterval:interval
                             repeats:YES
                               block:^(NSTimer *_Nonnull timer) {
                                 BOOL retVal = [self->_storyViewController
                                     executeRoutine:routine];
                                 if (retVal) {
                                   [timer invalidate];
                                   [self->_storyViewController stringInput:nil];
                                 }
                               }];
}

- (void)stopTimedRoutine {
  [_timer invalidate];
  _timer = nil;
}

- (BOOL)supportedCharacter:(unichar)c {
  NSFont *font = [_storyFacet fontForStyle:0];
  NSCharacterSet *charSet = font.coveredCharacterSet;
  //  NSLog(@"checkUnicode: font name: %@", font.displayName);
  return [charSet characterIsMember:c];
}

@end
