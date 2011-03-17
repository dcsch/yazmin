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
    
    // Archive the colour objects
    NSData *backgroundColourAsData = [NSKeyedArchiver archivedDataWithRootObject:
        [NSColor yellowColor]];
    NSData *foregroundColourAsData = [NSKeyedArchiver archivedDataWithRootObject:
        [NSColor blackColor]];

    // Put the defaults in the dictionary
    [defaultValues setObject:backgroundColourAsData forKey:SMBackgroundColourKey];
    [defaultValues setObject:foregroundColourAsData forKey:SMForegroundColourKey];
    [defaultValues setObject:@"Courier" forKey:SMMonospacedFontKey];
    [defaultValues setObject:@"Helvetica" forKey:SMProportionalFontKey];
    [defaultValues setObject:[NSNumber numberWithFloat:12.0] forKey:SMFontSizeKey];
    [defaultValues setObject:[NSNumber numberWithInt:1]
                      forKey:SMShowLibraryOnStartupKey];
    
    // Register the dictionary of defaults
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    
    NSLog(@"registered defaults: %@", defaultValues);
}

- (id)init
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

- (void)dealloc
{
    [libraryController release];
    [preferenceController release];
    [library release];
    [super dealloc];
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
