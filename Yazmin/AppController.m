//
//  AppController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/07/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "AppController.h"
#import "LibraryController.h"
#import "PreferenceController.h"
#import "Preferences.h"
#import "Library.h"

@implementation AppController

+ (void)initialize
{
    // Create a dictionary
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionary];
    
    // Archive the color objects
    NSData *backgroundColorAsData = [NSKeyedArchiver archivedDataWithRootObject:
        [NSColor textBackgroundColor]];
    NSData *foregroundColorAsData = [NSKeyedArchiver archivedDataWithRootObject:
        [NSColor textColor]];

    // Put the defaults in the dictionary
    defaultValues[SMBackgroundColorKey] = backgroundColorAsData;
    defaultValues[SMForegroundColorKey] = foregroundColorAsData;
    defaultValues[SMMonospacedFontKey] = @"Courier";
    defaultValues[SMProportionalFontKey] = @"Helvetica";
    defaultValues[SMFontSizeKey] = @12.0f;
    defaultValues[SMShowLibraryOnStartupKey] = @1;
    
    // Register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    
//    NSLog(@"registered defaults: %@", defaultValues);
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        library = [[Library alloc] init];
        libraryController = nil;
        preferenceController = nil;
    }
    return self;
}


- (Library *)library
{
    return library;
}

- (LibraryController *)libraryController
{
    return libraryController;
}

- (IBAction)showLibraryWindow:(id)sender
{
    if (!libraryController)
        libraryController = [[LibraryController alloc] init];
    [libraryController showWindow:self];
}

- (IBAction)showPreferencePanel:(id)sender
{
    if (!preferenceController)
        preferenceController = [[PreferenceController alloc] init];
    [preferenceController showWindow:self];
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // We've finished launching, so should we show the library window?
    if ([[Preferences sharedPreferences] showsLibraryOnStartup])
        [self showLibraryWindow:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
    // Make sure we've saved our library
    [library save];
}

@end
