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
}

- (void)createZMachine;

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

  Preferences *prefs = [Preferences sharedPreferences];
  StoryFacet *facet;
  for (facet in _facets) {
    // Adjust the current font attribute
    NSFont *font = [prefs fontForStyle:[facet currentStyle]];
    [facet currentAttributes][NSFontAttributeName] = font;

    // Scan all the text and convert the fonts found within
    unsigned int index = 0;
    while (index < [facet textStorage].length) {
      NSRange range;
      NSFont *oldFont = [[facet textStorage] attribute:NSFontAttributeName
                                               atIndex:index
                                        effectiveRange:&range];
      if (oldFont) {
        NSLog(@"Old font: %@ (%f)", oldFont.fontName, oldFont.pointSize);
        NSFont *newFont = [prefs convertFont:oldFont forceFixedPitch:NO];
        NSLog(@"New font: %@ (%f)", newFont.fontName, newFont.pointSize);
        [[facet textStorage] addAttribute:NSFontAttributeName
                                    value:newFont
                                    range:range];
      }
      index += range.length;
    }
  }
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

@end
