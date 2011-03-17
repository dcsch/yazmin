//
//  PreferenceController.m
//  Yazmin
//
//  Created by David Schweinsberg on 8/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "PreferenceController.h"
#import "Preferences.h"

@implementation PreferenceController

- (id)init
{
    self = [super initWithWindowNibName:@"Preferences"];
    if (self)
    {
    }
    return self;
}

- (NSColor *)backgroundColour
{
    return [[Preferences sharedPreferences] backgroundColour];
}

- (NSColor *)foregroundColour
{
    return [[Preferences sharedPreferences] foregroundColour];
}

- (NSString *)proportionalFontFamily
{
    return [[Preferences sharedPreferences] proportionalFontFamily];
}

- (NSString *)monospacedFontFamily
{
    return [[Preferences sharedPreferences] monospacedFontFamily];
}

- (float)fontSize
{
    return [[Preferences sharedPreferences] fontSize];
}

- (void)windowDidLoad
{
    [backgroundColourWell setColor:[self backgroundColour]];
    [foregroundColourWell setColor:[self foregroundColour]];
    
    // Clear out the pop-up list
    [proportionalFontPopUpButton removeAllItems];

    // Generate an alphabetically ordered array of font families
    NSFontManager *fm = [NSFontManager sharedFontManager];
    NSArray *fontNames = [fm availableFontFamilies];
//    NSArray *fontNames = [fm availableFonts];
    NSSortDescriptor *sortDescriptor =
        [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedFontNames =
        [fontNames sortedArrayUsingDescriptors:sortDescriptors];
    
    // Stick all of these into the list
    NSString *fontName;
    for (fontName in sortedFontNames)
        [proportionalFontPopUpButton addItemWithTitle:fontName];
    
    // Select the one that we're using
    [proportionalFontPopUpButton selectItemWithTitle:[self proportionalFontFamily]];

    // Now build our list of monospaced fonts
    [monospacedFontPopUpButton removeAllItems];
    for (fontName in sortedFontNames)
        //if ([fm fontNamed:fontName hasTraits:NSFixedPitchFontMask])
            [monospacedFontPopUpButton addItemWithTitle:fontName];
    [monospacedFontPopUpButton selectItemWithTitle:[self monospacedFontFamily]];

    // Font size
    [fontSizeTextField setFloatValue:[self fontSize]];
}

- (IBAction)changeBackgroundColour:(id)sender
{
    [[Preferences sharedPreferences] setBackgroundColour:[sender color]];
}

- (IBAction)changeForegroundColour:(id)sender
{
    [[Preferences sharedPreferences] setForegroundColour:[sender color]];
}

- (IBAction)changeProportionalFont:(id)sender
{
    [[Preferences sharedPreferences] setProportionalFontFamily:
        [sender titleOfSelectedItem]];
}

- (IBAction)changeMonospacedFont:(id)sender
{
    [[Preferences sharedPreferences] setMonospacedFontFamily:
        [sender titleOfSelectedItem]];
}

- (IBAction)changeFontSize:(id)sender
{
    [[Preferences sharedPreferences] setFontSize:[sender floatValue]];
}

@end
