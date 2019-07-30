//
//  AppController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/07/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "AppController.h"
#import "Library.h"
#import "Preferences.h"
#import "StoryDocumentController.h"

@interface AppController ()

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotification;

@end

@implementation AppController

+ (void)initialize {

  [Preferences registerDefaults];

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
    [Preferences.sharedPreferences applyAppPreferences];
  }
  return self;
}

- (IBAction)showLibraryWindow:(id)sender {
  [_libraryWindowController.window makeKeyAndOrderFront:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender {
  return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  NSWindowController *windowController = [NSStoryboard.mainStoryboard
      instantiateControllerWithIdentifier:@"LibraryWindow"];
  _libraryWindowController = windowController;

  // We've finished launching, so should we show the library window?
  if ([[Preferences sharedPreferences] showsLibraryOnStartup])
    [self showLibraryWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Make sure we've saved our library
  [_library save];
}

@end
