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
NSString *SMTextBoxFadeCount = @"TextBoxFadeCount";

NSString *SMBackgroundColorChangedNotification = @"SMBackgroundColorChanged";
NSString *SMForegroundColorChangedNotification = @"SMForegroundColorChanged";
NSString *SMProportionalFontFamilyChangedNotification =
    @"SMProportionalFontFamilyChanged";
NSString *SMMonospacedFontFamilyChangedNotification =
    @"SMMonospacedFontFamilyChanged";
NSString *SMCharacterGraphicsFontChangedNotification =
    @"SMCharacterGraphicsFontChanged";
NSString *SMFontSizeChangedNotification = @"SMFontSizeChanged";

static void *AppearanceContext = &AppearanceContext;
static void *FontSizeContext = &FontSizeContext;

@interface Preferences ()

- (void)applyAppearance;
- (void)notifyFontSizeChange;

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
    SMSpeakTextKey : @0,
    SMTextBoxFadeCount : @0
  };

  // Register the dictionary of defaults
  [NSUserDefaults.standardUserDefaults registerDefaults:defaultValues];
}

- (instancetype)init {
  self = [super init];
  if (self) {
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    [defaults
        addObserver:self
         forKeyPath:SMAppearanceKey
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
            context:AppearanceContext];
    [defaults
        addObserver:self
         forKeyPath:SMFontSizeKey
            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
            context:FontSizeContext];
  }
  return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

  if (context == AppearanceContext) {
    [self applyAppearance];
  } else if (context == FontSizeContext) {
    [self notifyFontSizeChange];
  } else {
    [super observeValueForKeyPath:keyPath
                         ofObject:object
                           change:change
                          context:context];
  }
}

- (void)applyAppPreferences {
  [self applyAppearance];
}

- (void)applyAppearance {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
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

- (void)notifyFontSizeChange {
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [nc postNotificationName:SMFontSizeChangedNotification object:self];
}

- (NSColor *)backgroundColor {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSData *colorAsData = [defaults objectForKey:SMBackgroundColorKey];
  return [NSKeyedUnarchiver unarchivedObjectOfClass:NSColor.class
                                           fromData:colorAsData
                                              error:nil];
}

- (void)setBackgroundColor:(NSColor *)color {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color
                                              requiringSecureCoding:NO
                                                              error:nil];
  [defaults setObject:colorAsData forKey:SMBackgroundColorKey];
  [nc postNotificationName:SMBackgroundColorChangedNotification object:self];
}

- (NSColor *)foregroundColor {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSData *colorAsData = [defaults objectForKey:SMForegroundColorKey];
  return [NSKeyedUnarchiver unarchivedObjectOfClass:NSColor.class
                                           fromData:colorAsData
                                              error:nil];
}

- (void)setForegroundColor:(NSColor *)color {
  NSData *colorAsData = [NSKeyedArchiver archivedDataWithRootObject:color
                                              requiringSecureCoding:NO
                                                              error:nil];
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [defaults setObject:colorAsData forKey:SMForegroundColorKey];
  [nc postNotificationName:SMForegroundColorChangedNotification object:self];
}

- (NSString *)proportionalFontFamily {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [defaults objectForKey:SMProportionalFontKey];
}

- (void)setProportionalFontFamily:(NSString *)family {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [defaults setObject:family forKey:SMProportionalFontKey];
  [nc postNotificationName:SMProportionalFontFamilyChangedNotification
                    object:self];
}

- (NSString *)monospacedFontFamily {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [defaults objectForKey:SMMonospacedFontKey];
}

- (void)setMonospacedFontFamily:(NSString *)family {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [defaults setObject:family forKey:SMMonospacedFontKey];
  [nc postNotificationName:SMMonospacedFontFamilyChangedNotification
                    object:self];
}

- (NSString *)characterGraphicsFontFamily {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [defaults objectForKey:SMCharacterGraphicsFontKey];
}

- (void)setCharacterGraphicsFontFamily:(NSString *)family {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [defaults setObject:family forKey:SMCharacterGraphicsFontKey];
  [nc postNotificationName:SMCharacterGraphicsFontChangedNotification
                    object:self];
}

- (float)fontSize {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [[defaults objectForKey:SMFontSizeKey] floatValue];
}

- (void)setFontSize:(float)size {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
  [defaults setObject:@(size) forKey:SMFontSizeKey];
  [nc postNotificationName:SMFontSizeChangedNotification object:self];
}

- (BOOL)showsLibraryOnStartup {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [[defaults objectForKey:SMShowLibraryOnStartupKey] intValue];
}

- (void)setShowsLibraryOnStartup:(BOOL)show {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  [defaults setObject:@(show) forKey:SMShowLibraryOnStartupKey];
}

- (int)interpreterNumber {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [[defaults objectForKey:SMInterpreterNumberKey] intValue];
}

- (char)interpreterVersion {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [[defaults objectForKey:SMInterpreterVersionKey] charValue];
}

- (BOOL)speakText {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [[defaults objectForKey:SMSpeakTextKey] intValue];
}

- (int)textBoxFadeCount {
  NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
  return [[defaults objectForKey:SMTextBoxFadeCount] intValue];
}

@end
