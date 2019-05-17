//
//  PreferenceController.h
//  Yazmin
//
//  Created by David Schweinsberg on 8/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferenceController : NSWindowController {
  IBOutlet NSColorWell *backgroundColorWell;
  IBOutlet NSColorWell *foregroundColorWell;
  IBOutlet NSPopUpButton *proportionalFontPopUpButton;
  IBOutlet NSPopUpButton *monospacedFontPopUpButton;
  IBOutlet NSTextField *fontSizeTextField;
}

@property(readonly, copy) NSColor *backgroundColor;
@property(readonly, copy) NSColor *foregroundColor;
@property(readonly, copy) NSString *proportionalFontFamily;
@property(readonly, copy) NSString *monospacedFontFamily;
@property(readonly) float fontSize;
- (IBAction)changeBackgroundColor:(id)sender;
- (IBAction)changeForegroundColor:(id)sender;
- (IBAction)changeProportionalFont:(id)sender;
- (IBAction)changeMonospacedFont:(id)sender;
- (IBAction)changeFontSize:(id)sender;

@end
