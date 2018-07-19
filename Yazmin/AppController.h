//
//  AppController.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/07/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class Library;
@class LibraryController;
@class PreferenceController;

@interface AppController : NSObject
{
    Library *library;
    LibraryController *libraryController;
    PreferenceController *preferenceController;
}

@property (readonly, strong) Library *library;
@property (readonly, strong) LibraryController *libraryController;
- (IBAction)showLibraryWindow:(id)sender;
- (IBAction)showPreferencePanel:(id)sender;
- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender;
- (void)applicationWillTerminate:(NSNotification *)aNotification;

@end
