//
//  Preferences.m
//  Yazmin
//
//  Created by David Schweinsberg on 14/11/07.
//  Copyright 2007 David Schweinsberg. All rights reserved.
//

#import "Preferences.h"

NSString *SMAppearanceKey = @"Appearance";
NSString *SMBackgroundColorKey = @"BackgroundColor";
NSString *SMForegroundColorKey = @"ForegroundColor";
NSString *SMMonospacedFontKey = @"MonospacedFont";
NSString *SMProportionalFontKey = @"ProportionalFont";
NSString *SMCharacterGraphicsFontKey = @"CharacterGraphicsFont";
NSString *SMFontSizeKey = @"FontSize";
NSString *SMShowLibraryOnStartupKey = @"ShowLibraryOnStartup";
NSString *SMInterpreterNumberKey = @"InterpreterNumber";
NSString *SMInterpreterVersionKey = @"InterpreterVersion";
NSString *SMSpeakTextKey = @"SpeakText";

static void *AppearanceContext = &AppearanceContext;

@interface Preferences () {
  NSUserDefaults *defaults;
  NSNotificationCenter *nc;
}

@end

@implementation Preferences

+ (Preferences *)sharedPreferences {
  // This is never deallocated, so what is a better way of doing this?
  static Preferences *preferences = nil;
  if (!preferences)
    preferences = [[Preferences alloc] init];
  return preferences;
}

+ (void)registerDefaults {

  // Archive the color objects
  NSData *backgroundColorAsData =
      [NSKeyedArchiver archivedDataWithRootObject:[NSColor textBackgroundColor]
                            requiringSecureCoding:NO
                                            error:nil];
  NSData *foregroundColorAsData =
      [NSKeyedArchiver archivedDataWithRootObject:[NSColor textColor]
                            requiringSecureCoding:NO
                                            error:nil];

  // Put the defaults in a dictionary
  NSDictionary *defaultValues = @{
    SMAppearanceKey : @0,
    SMBackgroundColorKey : backgroundColorAsData,
    SMForegroundColorKey : foregroundColorAsData,
    SMMonospacedFontKey : @"Menlo",
    SMProportionalFontKey : @"Helvetica Neue",
    SMCharacterGraphicsFontKey : @"Zork",
    SMFontSizeKey : @14.0f,
    SMShowLibraryOnStartupKey : @1,
    SMInterpreterNumberKey : @3,
    SMInterpreterVersionKey : @'Z',
    SMSpeakTextKey : @0
  };

  // Register the dictionary of defaults
  [NSUserDefaults.standardUserDefaults registerDefaults:defaultValues];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    defaults = [NSUserDefaults standardUserDefaults];
    nc = [NSNotificationCenter defaultCenter];

    [defaults
        addObserver:self
         forKeyPath:SMAppearanceKey
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
            context:AppearanceContext];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

  if (context == AppearanceContext) {
    [self applyAppPreferences];
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

- (void)applyAppPreferences {
  switch ([defaults integerForKey:SMAppearanceKey]) {
  case 0:
    NSApp.appearance = nil;
    break;
  case 1:
    NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    break;
  case 2:
    NSApp.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    break;
  }
}

- (NSColor *)backgroundColor {
  NSData *colorAsData = [defaults objectForKey:SMBackgroundColorKey];
  return [NSKeyedUnarchiver unarchivedObjectOfClass:NSColor.class
                                           fromData:colorAsData
                                              error:nil];
}

- (void)setBackgroundColor:(NSColor *)color {
  NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color
                                              requiringSecureCoding:NO
                                                              error:nil];
  [defaults setObject:colorAsData forKey:SMBackgroundColorKey];
  [nc postNotificationName:@"SMBackgroundColorChanged" object:self];
}

- (NSColor *)foregroundColor {
  NSData *colorAsData = [defaults objectForKey:SMForegroundColorKey];
  return [NSKeyedUnarchiver unarchivedObjectOfClass:NSColor.class
                                           fromData:colorAsData
                                              error:nil];
}

- (void)setForegroundColor:(NSColor *)color {
  NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color
                                              requiringSecureCoding:NO
                                                              error:nil];
  [defaults setObject:colorAsData forKey:SMForegroundColorKey];
  [nc postNotificationName:@"SMForegroundColorChanged" object:self];
}

- (NSString *)proportionalFontFamily {
  return [defaults objectForKey:SMProportionalFontKey];
}

- (void)setProportionalFontFamily:(NSString *)family {
  [defaults setObject:family forKey:SMProportionalFontKey];
  [nc postNotificationName:@"SMProportionalFontFamilyChanged" object:self];
}

- (NSString *)monospacedFontFamily {
  return [defaults objectForKey:SMMonospacedFontKey];
}

- (void)setMonospacedFontFamily:(NSString *)family {
  [defaults setObject:family forKey:SMMonospacedFontKey];
  [nc postNotificationName:@"SMMonospacedFontFamilyChanged" object:self];
}

- (NSString *)characterGraphicsFontFamily {
  return [defaults objectForKey:SMCharacterGraphicsFontKey];
}

- (void)setCharacterGraphicsFontFamily:(NSString *)family {
  [defaults setObject:family forKey:SMCharacterGraphicsFontKey];
  [nc postNotificationName:@"SMCharacterGraphicsFontKeyChanged" object:self];
}

- (float)fontSize {
  return [[defaults objectForKey:SMFontSizeKey] floatValue];
}

- (void)setFontSize:(float)size {
  [defaults setObject:@(size) forKey:SMFontSizeKey];
  [nc postNotificationName:@"SMFontSizeChanged" object:self];
}

- (BOOL)showsLibraryOnStartup {
  return [[defaults objectForKey:SMShowLibraryOnStartupKey] intValue];
}

- (void)setShowsLibraryOnStartup:(BOOL)show {
  [defaults setObject:@(show) forKey:SMShowLibraryOnStartupKey];
}

- (int)interpreterNumber {
  return [[defaults objectForKey:SMInterpreterNumberKey] intValue];
}

- (char)interpreterVersion {
  return [[defaults objectForKey:SMInterpreterVersionKey] charValue];
}

- (BOOL)speakText {
  return [[defaults objectForKey:SMSpeakTextKey] intValue];
}

@end
