//
//  AppController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/07/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "AppController.h"
#import "Library.h"
#import "LibraryController.h"
#import "Preferences.h"
#import "StoryDocumentController.h"

@interface AppController ()

- (IBAction)showLibraryWindow:(id)sender;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotification;

@end

@implementation AppController

+ (void)initialize {
  // Create a dictionary
  NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];

  // Archive the color objects
  NSData *backgroundColorAsData =
      [NSKeyedArchiver archivedDataWithRootObject:[NSColor textBackgroundColor]
                            requiringSecureCoding:NO
                                            error:nil];
  NSData *foregroundColorAsData =
      [NSKeyedArchiver archivedDataWithRootObject:[NSColor textColor]
                            requiringSecureCoding:NO
                                            error:nil];

  // Put the defaults in the dictionary
  defaultValues[SMBackgroundColorKey] = backgroundColorAsData;
  defaultValues[SMForegroundColorKey] = foregroundColorAsData;
  defaultValues[SMMonospacedFontKey] = @"Menlo";
  defaultValues[SMProportionalFontKey] = @"Helvetica Neue";
  defaultValues[SMCharacterGraphicsFontKey] = @"Zork";
  defaultValues[SMFontSizeKey] = @14.0f;
  defaultValues[SMShowLibraryOnStartupKey] = @1;
  defaultValues[SMInterpreterNumberKey] = @3;
  defaultValues[SMInterpreterVersionKey] = @'Z';

  // Register the dictionary of defaults
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];

  // These days we have to get in really early with the creation
  // of our custom document controller
  StoryDocumentController *storyDocumentController =
      [[StoryDocumentController alloc] init];
  if (storyDocumentController) {
  }
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _library = [[Library alloc] init];
    [_library syncMetadata]; // This might be a little heavy handed
    _libraryController = [[LibraryController alloc] initWithLibrary:_library];
  }
  return self;
}

- (IBAction)showLibraryWindow:(id)sender {
  [_libraryController showWindow:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // We've finished launching, so should we show the library window?
  if ([[Preferences sharedPreferences] showsLibraryOnStartup])
    [self showLibraryWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Make sure we've saved our library
  [_library save];
}

@end
