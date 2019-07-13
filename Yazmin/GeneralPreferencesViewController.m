//
//  GeneralPreferencesViewController.m
//  Yazmin
//
//  Created by David Schweinsberg on 7/12/19.
//  Copyright © 2019 David Schweinsberg. All rights reserved.
//

#import "GeneralPreferencesViewController.h"
#import "Preferences.h"

@interface GeneralPreferencesViewController () {
  IBOutlet NSColorWell *backgroundColorWell;
  IBOutlet NSColorWell *foregroundColorWell;
  IBOutlet NSPopUpButton *proportionalFontPopUpButton;
  IBOutlet NSPopUpButton *monospacedFontPopUpButton;
  IBOutlet NSTextField *fontSizeTextField;
}

@end

@implementation GeneralPreferencesViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  // Clear out the pop-up list
  [proportionalFontPopUpButton removeAllItems];
  [monospacedFontPopUpButton removeAllItems];

  // Generate an alphabetically ordered array of font families
  NSFontManager *fm = NSFontManager.sharedFontManager;
  NSArray *fontNames = fm.availableFontFamilies;
  NSSortDescriptor *sortDescriptor =
      [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
  NSArray *sortDescriptors = @[ sortDescriptor ];
  NSArray *sortedFontNames =
      [fontNames sortedArrayUsingDescriptors:sortDescriptors];

  // Stick all of these into the list
  for (NSString *fontName in sortedFontNames)
    if ([fm fontNamed:fontName hasTraits:NSFixedPitchFontMask])
      [monospacedFontPopUpButton addItemWithTitle:fontName];
    else
      [proportionalFontPopUpButton addItemWithTitle:fontName];

  // Select the ones that we're using
  [proportionalFontPopUpButton
      selectItemWithTitle:Preferences.sharedPreferences.proportionalFontFamily];
  [monospacedFontPopUpButton
      selectItemWithTitle:Preferences.sharedPreferences.monospacedFontFamily];
}

- (IBAction)changeProportionalFont:(id)sender {
  [Preferences.sharedPreferences
      setProportionalFontFamily:[sender titleOfSelectedItem]];
}

- (IBAction)changeMonospacedFont:(id)sender {
  [Preferences.sharedPreferences
      setMonospacedFontFamily:[sender titleOfSelectedItem]];
}

@end
