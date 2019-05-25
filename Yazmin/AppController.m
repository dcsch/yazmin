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
#import "PreferenceController.h"
#import "Preferences.h"

@interface AppController () {
  PreferenceController *preferenceController;
}

@property(readonly, strong) LibraryController *libraryController;

- (IBAction)showLibraryWindow:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;
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
  defaultValues[SMFontSizeKey] = @12.0f;
  defaultValues[SMShowLibraryOnStartupKey] = @1;

  // Register the dictionary of defaults
  [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _library = [[Library alloc] init];
    _libraryController = nil;
    preferenceController = nil;
  }
  return self;
}

- (IBAction)showLibraryWindow:(id)sender {
  if (!_libraryController)
    _libraryController = [[LibraryController alloc] init];
  [_libraryController showWindow:self];
}

- (IBAction)showPreferencePanel:(id)sender {
  if (!preferenceController)
    preferenceController = [[PreferenceController alloc] init];
  [preferenceController showWindow:self];
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
