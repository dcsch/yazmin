//
//  PreferenceController.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferenceController : NSWindowController
{
    IBOutlet NSColorWell *backgroundColourWell;
    IBOutlet NSColorWell *foregroundColourWell;
    IBOutlet NSPopUpButton *proportionalFontPopUpButton;
    IBOutlet NSPopUpButton *monospacedFontPopUpButton;
    IBOutlet NSTextField *fontSizeTextField;
}

@property (readonly, copy) NSColor *backgroundColour;
@property (readonly, copy) NSColor *foregroundColour;
@property (readonly, copy) NSString *proportionalFontFamily;
@property (readonly, copy) NSString *monospacedFontFamily;
@property (readonly) float fontSize;
- (IBAction)changeBackgroundColour:(id)sender;
- (IBAction)changeForegroundColour:(id)sender;
- (IBAction)changeProportionalFont:(id)sender;
- (IBAction)changeMonospacedFont:(id)sender;
- (IBAction)changeFontSize:(id)sender;

@end
