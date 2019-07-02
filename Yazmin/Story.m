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
#import "DebugInfo.h"
#import "DebugInfoReader.h"
#import "GridStoryFacet.h"
#import "IFIdentification.h"
#import "IFStory.h"
#import "IFictionMetadata.h"
#import "Preferences.h"
#import "StoryController.h"
#import "StoryFacet.h"
#import "ZMachine.h"

@interface Story () {
  NSMutableArray *_facets;
  NSColor *_foregroundColor;
  NSColor *_backgroundColor;
  BOOL _justSetTextStyle;
}

- (void)createZMachine;
- (NSColor *)colorFromCode:(int)colorCode
              currentColor:(NSColor *)currentColor
              defaultColor:(NSColor *)defaultColor;
- (NSColor *)colorFromTrueColor:(int)trueColor
                   currentColor:(NSColor *)currentColor
                   defaultColor:(NSColor *)defaultColor;

@end

@implementation Story

- (instancetype)init {
  self = [super init];
  if (self) {
    // Create two facets (lower and upper), with the upper one being
    // a text grid
    _facets = [[NSMutableArray alloc] init];
    StoryFacet *facet = [[StoryFacet alloc] initWithStory:self];
    [_facets addObject:facet];

    facet = [[GridStoryFacet alloc] initWithStory:self];
    [_facets addObject:facet];

    // Default colors
    [self setColorForeground:1 background:1];

    // Text style attributes
    [self setTextStyle:0];

    [self setHasUndoManager:NO];

    // Listen to notifications
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self
           selector:@selector(handleBackgroundColorChange:)
               name:@"SMBackgroundColorChanged"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleForegroundColorChange:)
               name:@"SMForegroundColorChanged"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleFontChange:)
               name:@"SMProportionalFontFamilyChanged"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleFontChange:)
               name:@"SMMonospacedFontFamilyChanged"
             object:nil];
    [nc addObserver:self
           selector:@selector(handleFontChange:)
               name:@"SMFontSizeChanged"
             object:nil];
  }
  return self;
}

- (void)dealloc {
  NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
  [nc removeObserver:self];
}

- (void)makeWindowControllers {
  _storyController = [[StoryController alloc] init];
  [self addWindowController:_storyController];

  // Make sure the controller knows the score with text attributes
  // TODO: This is pointless, as the views don't exist yet
  [_storyController updateTextAttributes];
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
    return
        [super readFromFileWrapper:fileWrapper ofType:typeName error:outError];
}

- (BOOL)readFromData:(NSData *)data
              ofType:(NSString *)typeName
               error:(NSError **)outError {
  _blorb = nil;

  if ([typeName compare:@"ZCode Blorb"] == 0) {
    // This is a blorb, so we need to unwrap
    if ([Blorb isBlorbData:data]) {
      _blorb = [[Blorb alloc] initWithData:data];
      NSData *mddata = _blorb.metaData;
      if (mddata) {
        IFictionMetadata *ifmd = [[IFictionMetadata alloc] initWithData:mddata];
        if (ifmd.stories.count > 0) {
          _metadata = ifmd.stories[0];
          if (_metadata.identification.ifids.count > 0)
            _ifid = _metadata.identification.ifids[0];
        }
      }
      _zcodeData = _blorb.zcodeData;
    }
  } else {
    // Treat this data as executable z-code story data
    _zcodeData = data;
  }

  if (_zcodeData) {
    [self createZMachine];

    // Is there any debug information to load?
    NSString *path = self.fileURL.path;
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
  [_storyController restoreSession];
}

- (void)saveSessionData:(NSData *)data {
  [_storyController saveSessionData:data];
}

- (void)error:(NSString *)errorMessage {
  [_storyController showError:errorMessage];
}

- (void)updateWindowLayout {
  [_storyController updateWindowLayout];
}

- (void)updateWindowBackgroundColor {
  [_storyController updateWindowBackgroundColor];
}

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
  NSLog(@"Font change");

  //  Preferences *prefs = [Preferences sharedPreferences];
  //  StoryFacet *facet;
  //  for (facet in _facets) {
  //    // Adjust the current font attribute
  //    NSFont *font = [prefs fontForStyle:[facet currentStyle]];
  //    [facet currentAttributes][NSFontAttributeName] = font;
  //
  //    // Scan all the text and convert the fonts found within
  //    unsigned int index = 0;
  //    while (index < [facet textStorage].length) {
  //      NSRange range;
  //      NSFont *oldFont = [[facet textStorage] attribute:NSFontAttributeName
  //                                               atIndex:index
  //                                        effectiveRange:&range];
  //      if (oldFont) {
  //        NSLog(@"Old font: %@ (%f)", oldFont.fontName, oldFont.pointSize);
  //        NSFont *newFont = [prefs convertFont:oldFont forceFixedPitch:NO];
  //        NSLog(@"New font: %@ (%f)", newFont.fontName, newFont.pointSize);
  //        [[facet textStorage] addAttribute:NSFontAttributeName
  //                                    value:newFont
  //                                    range:range];
  //      }
  //      index += range.length;
  //    }
  //  }
  [_storyController updateTextAttributes];
  [_storyController updateWindowLayout];
}

- (void)beginInputWithOffset:(NSInteger)offset {
  [_storyController prepareInputWithOffset:offset];
}

- (NSString *)endInput {
  // 'input' consumes the input string
  NSString *retString = _inputString;
  _inputString = nil;
  return retString;
}

- (void)beginInputChar {
  [_storyController prepareInputChar];
}

- (unichar)endInputChar {
  return _inputCharacter;
}

- (NSOutputStream *)transcriptOutputStream {
  return [_storyController transcriptOutputStream];
}

- (NSOutputStream *)commandOutputStream {
  return [_storyController commandOutputStream];
}

- (void)commandInputStream:(int)number {
  [_storyController commandInputStream:number];
}

- (int)closestColorCodeToColor:(NSColor *)color {
  color = [color colorUsingColorSpace:NSColorSpace.genericRGBColorSpace];
  CGFloat r1, g1, b1, a1;
  [color getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
  int closestCode = 0;
  CGFloat closestDistance = 2.0;
  for (int i = 2; i <= 9; ++i) {
    NSColor *paletteColor =
        [[self colorFromCode:i currentColor:nil defaultColor:nil]
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

@end
